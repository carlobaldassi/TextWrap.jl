"""
    TextWrap

This module provides the function [`wrap`](@ref) which parses an input text and reorganizes its
white space so that it can be printed with a fixed screen width, optionally indenting it. It also
provides the two convenience functions [`print_wrapped`](@ref) and [`println_wrapped`](@ref).
"""
module TextWrap

export
    wrap,
    print_wrapped,
    println_wrapped

ansi_length(s) = length(replace(s, r"\e\[[0-9]+m" => ""))

function apply_expand_tabs(text::AbstractString, i0::Int)
    out_buf = IOBuffer()
    i = i0 % 8
    for c in text
        if c == '\t'
            while i < 8
                print(out_buf, ' ')
                i += 1
            end
            i = 0
        elseif c == '\n' || c == '\r'
            print(out_buf, c)
            i = 0
        else
            print(out_buf, c)
            i = (i + 1) % 8
        end
    end
    return String(take!(out_buf))
end

function check_width(width::Integer)
    width ≤ 0 && throw(ArgumentError("invalid width $width (must be > 0)"))
    return true
end
function check_indent(indent::Integer, width::Integer)
    0 ≤ indent < width ||
        throw(ArgumentError("invalid intent $indent (must be an integer between 0 and width-1, " *
                            "or an AbstractString)"))
    return true
end
function check_indent(indent::AbstractString, width::Integer)
    length(indent) ≥ width && throw(ArgumentError("invalid intent (must be shorter than width-1)"))
    return true
end

function put_chunks!(out_str::IOBuffer, chunk::AbstractString,
                     cln, cll, bol, soh,
                     width, initial_indent, subsequent_indent,
                     break_on_hyphens, break_long_words,
                     recognize_escapes)

    # This function just performs breaks-on-hyphens and passes
    # individual chunks to put_chunk!

    hyphen_re = r"# define a class that matches sequences of word characters
                  # and escape codes, arbitrarily mixed. It's then invoked
                  # with the syntax (?&w)
                  (?(DEFINE)
                      (?<w> (?:\w|\e\[[0-9]+m)*)
                  )

                  # breakdown: 1) possible prefix (can consist of number-only words followed
                  #               by a dash, possibly more than one);
                  #            2) main body: requires at least a letter, includes the dash
                  #            3) rest of the word: also requires at least a letter
                  # notes: the ?: avoids group capturing
                  #        the ?> avoids backtracking as soon as a \w or \p{L} is found
                  #        the ?= is a lookahead

                  ^(?:(?>(?&w)\p{N})(?&w)-)*?   # possible prefix
                      (?>(?&w)\p{L})(?&w)-      # main body
                   (?=(?>(?&w)\p{L})(?&w) )     # rest of the word
                 "x

    while break_on_hyphens
        m = match(hyphen_re, chunk)
        m ≡ nothing && break
        c = m.match
        cln, cll, bol, lcise = put_chunk!(out_str, c,
                    cln, cll, bol, soh,
                    width, initial_indent, subsequent_indent,
                    break_long_words, recognize_escapes)
        soh = ""
        chunk = chunk[m.offset+lastindex(c):end]
    end

    cln, cll, bol, lcise = put_chunk!(out_str, chunk,
                cln, cll, bol, soh,
                width, initial_indent, subsequent_indent,
                break_long_words, recognize_escapes)
    return cln, cll, bol, lcise
end

function put_chunk!(out_str::IOBuffer, chunk::AbstractString,
                    cln, cll, bol, soh,
                    width, initial_indent, subsequent_indent,
                    break_long_words, recognize_escapes)

    # Writes a chunk to out_str, based on the current position
    # as encoded in (cln, cll, bol) = (current_line_number,
    # current_line_length, beginning_of_line), and returns the
    # updated position (plus a flag to signal that an end-of-sentence
    # was detected).
    # The argument soh (=space_on_hold) is the spacing which should
    # go in front of chunk, and it may or may not be printed.
    # The rest are options.

    # This is written as a new function rather than a function reference
    # to help type inference
    elength(s)::Int = recognize_escapes ? ansi_length(s) : length(s)

    liindent = elength(initial_indent)
    lsindent = elength(subsequent_indent)
    lchunk = elength(chunk)
    lsoh = length(soh)

    if cll + lsoh > width
        soh = ""
        lsoh = 0
        cll > 0 && print(out_str, "\n")
        cln += 1
        cll = 0
        bol = true
    end

    if bol
        if cln == 1
            indent = initial_indent
            lindent = liindent
        else
            indent = subsequent_indent
            lindent = lsindent
        end

        print(out_str, indent)
        cll += lindent

        soh = ""
        lsoh = 0
    end

    # is there enough room for the chunk? or is this the
    # beginning of the text and we cannot break words?
    if cll + lsoh + lchunk ≤ width || (cln == 1 && bol && !break_long_words)
        print(out_str, soh, chunk)
        cll += lchunk + lsoh
        bol = false
    # does the chunk fit into the next line? or are we
    # forced to put it there?
    elseif lchunk ≤ width - lsindent || !break_long_words
        print(out_str, bol ? "" : "\n", subsequent_indent, chunk)
        cll = lsindent + lchunk
        cln += 1
        bol = false
    # break it until it fits
    else
        while cll + lsoh + lchunk > width
            if width - cll - lsoh > 0
                print(out_str, soh, chunk[1:nextind(chunk, 0, width-cll-lsoh)], "\n",
                        subsequent_indent)
                chunk = chunk[nextind(chunk, 0, width-cll-lsoh+1):end]
                lchunk = elength(chunk)
            else
                print(out_str, "\n", subsequent_indent)
            end
            cll = lsindent
            cln += 1
            soh = ""
            lsoh = 0
        end
        print(out_str, chunk)
        cll += lchunk
        bol = false
    end

    # detect end-of-sentences
    lcise = occursin(r"\w([\.\!\?…]|\.\.\.)[\"\'´„]?\Z", chunk)

    return cln, cll, bol, lcise
end

"""
    wrap(string; keywords...)

Parses `string` and returns a new string in which newlines are inserted as appropriate in order
for each line to fit within a specified width.

The behaviour can be controlled via optional keyword arguments:

* `width` (deafult=`70`): the maximum width of the wrapped text, including indentation.
* `initial_indent` (default=`""`): indentation of the first line. This can
   be any string (shorter than `width`), or it can be an integer number (smaller than `width`).
* `subsequent_indent` (default=`""`): indentation of all lines except the first. Works the same as
   `initial_indent`.
* `break_on_hyphens` (default=`true`): this flag determines whether words can be broken on hyphens,
  e.g. whether "high-precision" can be split into "high-" and "precision".
* `break_long_words` (default=`true`): this flag determines what to do when a word is too long to
  fit in any line. If `true`, the word will be broken, otherwise it will go beyond the desired text
  width.
* `replace_whitespace` (default=`true`): if this flag is `true`, all whitespace characters in the
  original text (including newlines) will be replaced by spaces.
* `expand_tabs` (default=`true`): if this flag is `true`, tabs will be expanded in-place into
  spaces. Otherwise a tab is counted as a single character. The expansion happens before whitespace
  replacement.
* `fix_sentence_endings` (default=`false`): if this flag is `true`, the wrapper will try to
  recognize sentence endings in the middle of a paragraph and put two spaces before the next
  sentence in case only one is present.
* `recognize_escapes` (default=`true`): if `true`, compute all lengths ignoring ANSI escape codes
  (special character sequences used e.g. to modify the text color or other properties; they look
  e.g. like `\"\\e[94m\"`)
"""
function wrap(text::AbstractString;
              width::Int = 70,
              initial_indent::Union{Integer,AbstractString} = "",
              subsequent_indent::Union{Integer,AbstractString} = "",
              expand_tabs::Bool = true,
              replace_whitespace::Bool = true,
              fix_sentence_endings::Bool = false,
              break_long_words::Bool = true,
              break_on_hyphens::Bool = true,
              recognize_escapes::Bool = true)

    # Reformat the single paragraph in `text` so it fits in lines of
    # no more than `width` columns, and return an AbstractString.

    # Sanity checks
    check_width(width)
    check_indent(initial_indent, width)
    check_indent(subsequent_indent, width)

    iind::String = initial_indent isa Integer ? " "^initial_indent : initial_indent
    sind::String = subsequent_indent isa Integer ? " "^subsequent_indent : subsequent_indent

    # A regex to match any sequence of spaces except non-breakable spaces (\xA0)
    spaceregex = r"((?!\xA0)\s)+"

    # whitespace-only case
    occursin(r"^\s*$", text) && return iind

    # State variables initialization
    cln = 1 # current line number
    cll = 0 # current line length
    bol = true # beginning of line
    lcise = false # last chunk is sentence ending
    soh = "" # space on hold

    # We iterate over the text, looking for whitespace
    # where to split.
    i = firstindex(text)
    l = lastindex(text)
    out_str = IOBuffer()

    wsrng = findnext(spaceregex, text, i)
    j, k = wsrng ≢ nothing ?
        (first(wsrng), nextind(text, last(wsrng))) :
        (0, -1)

    while 0 < j ≤ l
        if i < k
            if i < j
                # This is non-whitespace. We write it out according
                # to the current cursor position and the leading space.
                chunk = text[i:prevind(text,j)]

                cln, cll, bol, lcise = put_chunks!(out_str, chunk,
                            cln, cll, bol, soh,
                            width, iind, sind,
                            break_on_hyphens, break_long_words,
                            recognize_escapes)
            end
            i = k
        end

        # This is whitespace. We mangle it (expand tabs, fix
        # sentence endings, replace it with single spaces) and
        # then we keep it on hold.
        soh = text[j:prevind(text,k)]
        @assert !isempty(soh)
        if expand_tabs && occursin(r"\t", soh)
            soh = apply_expand_tabs(soh, cll)
        end
        if fix_sentence_endings && lcise && soh == " "
            soh = "  "
        end
        if replace_whitespace
            soh = replace(soh, "\n"=>"")
            soh = isempty(soh) ? " " : " "^length(soh)
        end

        # Continue the search

        k ≤ j && (k = nextind(text,j))
        wsrng = findnext(spaceregex, text, k)
        j, k = wsrng ≢ nothing ?
            (first(wsrng), nextind(text, last(wsrng))) :
            (0, -1)
    end
    if i ≤ ncodeunits(text)
        # Some non-whitespace is left at the end.
        chunk = text[i:end]
        cln, cll, bol = put_chunks!(out_str, chunk,
                    cln, cll, bol, soh,
                    width, iind, sind,
                    break_on_hyphens, break_long_words,
                    recognize_escapes)
    end
    return String(take!(out_str))
end

# print functions signature:
#   first arg: IO
#   last arg: Options
#   inbetween: anything printable
#
#   all arguments are optional
#
function _print_wrapped(newline::Bool, args...; kwargs...)
    if !isempty(args) && (args[1] isa IO)
        io = args[1]
        args = args[2:end]
    else
        io = stdout
    end

    if !isempty(args)
        ws = wrap(string(args...); kwargs...)
    else
        ws = wrap(""; kwargs...)
    end

    if newline
        println(io, ws)
    else
        print(io, ws)
    end
end

"""
    print_wrapped([io,] text...; keywords...)

This is just like the standard `print` function (it prints multiple arguments and accepts an
optional `IO` first argument), except that it wraps the result, and accepts keyword arguments to
pass to [`wrap`](@ref).
"""
print_wrapped(args...; kwargs...) = _print_wrapped(false, args...; kwargs...)

"""
    println_wrapped([io,] text...; keywords...)

Like [`print_wrapped`](@ref), but adds a newline at the end.
"""
println_wrapped(args...; kwargs...) = _print_wrapped(true, args...; kwargs...)

end # module TextWrap
