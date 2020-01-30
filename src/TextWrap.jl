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

ansi_length(s) = length(replace(s, r"\e\[[0-9]+(?:;[0-9]+)*m" => ""))

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

mutable struct State
    cln::Int    # current line number
    cll::Int    # current line length
    bol::Bool   # beginning of line?
    lcise::Bool # last chunk is sentence ending
    soh::String # space on hold

    State() = new(1, 0, true, false, "")
end

struct Params
    width::Int
    iind::String    # initial indent
    sind::String    # subsequent indent
    exp_tabs::Bool  # expand tabs
    rep_white::Bool # replace whitespace
    fix_end::Bool   # fix sentence endings
    brk_hyp::Bool   # break on hyphens
    brk_long::Bool  # break long words
    rec_esc::Bool   # recognize escapes

    function Params(width::Integer,
                    initial_indent::Union{Integer,AbstractString},
                    subsequent_indent::Union{Integer,AbstractString},
                    expand_tabs::Bool,
                    replace_whitespace::Bool,
                    fix_sentence_endings::Bool,
                    break_on_hyphens::Bool,
                    break_long_words::Bool,
                    recognize_escapes::Bool
                    )
        check_width(width)
        check_indent(initial_indent, width)
        check_indent(subsequent_indent, width)

        iind::String = initial_indent isa Integer ? " "^initial_indent : initial_indent
        sind::String = subsequent_indent isa Integer ? " "^subsequent_indent : subsequent_indent

        return new(width, iind, sind, expand_tabs, replace_whitespace, fix_sentence_endings,
                   break_on_hyphens, break_long_words, recognize_escapes)
    end
end

# This function just performs breaks-on-hyphens and passes individual chunks to put_chunk!
function put_chunks!(out_str::IOBuffer, chunk::AbstractString,
                     s::State, p::Params)

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
                  #        the ?> avoids backtracking as soon as a \p{N} or \p{L} is found
                  #        the ?= is a lookahead

                  ^(?:(?>(?&w)\p{N})(?&w)-)*?   # possible prefix
                      (?>(?&w)\p{L})(?&w)-      # main body
                   (?=(?>(?&w)\p{L})(?&w) )     # rest of the word
                 "x

    while p.brk_hyp
        m = match(hyphen_re, chunk)
        m ≡ nothing && break
        c = m.match
        put_chunk!(out_str, c, s, p)
        s.soh = ""
        chunk = chunk[m.offset+lastindex(c):end]
    end

    put_chunk!(out_str, chunk, s, p)
end

# Writes a chunk to out_str, based on the current state, and updates the state.
# Besides the current position, encoded in (cln, cll, bol) = (current_line_number,
# current_line_length, beginning_of_line), which gets updated, it also sets a flag
# to signal that an end-of-sentence was detected.
# The field s.soh (=space_on_hold) is the spacing which should go in front of chunk,
# and it may be discarded when we're between lines.
function put_chunk!(out_str::IOBuffer, chunk::AbstractString,
                    s::State, p::Params)

    # This is written as a new function rather than a function reference
    # to help type inference
    elength(x)::Int = p.rec_esc ? ansi_length(x) : length(x)

    liind = elength(p.iind)
    lsind = elength(p.sind)
    lchunk = elength(chunk)
    lsoh = length(s.soh)

    if s.cll + lsoh > p.width
        s.soh = ""
        lsoh = 0
        s.cll > 0 && print(out_str, "\n")
        s.cln += 1
        s.cll = 0
        s.bol = true
    end

    if s.bol
        ind, lind = s.cln == 1 ? (p.iind, liind) : (p.sind, lsind)
        print(out_str, ind)
        s.cll += lind
        s.soh = ""
        lsoh = 0
    end

    # Is there enough room for the chunk? or is this the
    # beginning of the text and we cannot break words?
    if s.cll + lsoh + lchunk ≤ p.width || (s.cln == 1 && s.bol && !p.brk_long)
        print(out_str, s.soh, chunk)
        s.cll += lchunk + lsoh
        s.bol = false
    # Does the chunk fit into the next line? or are we
    # forced to put it there?
    elseif lchunk ≤ p.width - lsind || !p.brk_long
        print(out_str, s.bol ? "" : "\n", p.sind, chunk)
        s.cll = lsind + lchunk
        s.cln += 1
        s.bol = false
    # Break it until it fits
    else
        while s.cll + lsoh + lchunk > p.width
            if p.width - s.cll - lsoh > 0
                print(out_str, s.soh, chunk[1:nextind(chunk, 0, p.width-s.cll-lsoh)], "\n", p.sind)
                chunk = chunk[nextind(chunk, 0, p.width-s.cll-lsoh+1):end]
                lchunk = elength(chunk)
            else
                print(out_str, "\n", p.sind)
            end
            s.cll = lsind
            s.cln += 1
            s.soh = ""
            lsoh = 0
        end
        print(out_str, chunk)
        s.cll += lchunk
        s.bol = false
    end

    # Detect end-of-sentences
    s.lcise = occursin(r"\w([\.\!\?…]|\.\.\.)[\"\'´„]?\Z", chunk)

    return out_str, s
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
  original text (including newlines) will be replaced by spaces. Otherwise, they'll be preserved,
  except at the beginning or end of a line.
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

    p = Params(width, initial_indent, subsequent_indent, expand_tabs, replace_whitespace,
               fix_sentence_endings, break_on_hyphens, break_long_words, recognize_escapes)

    # A regex to match any sequence of spaces except non-breakable spaces (\xA0)
    spaceregex = r"((?!\xA0)\s)+"

    # Whitespace-only case
    occursin(r"^\s*$", text) && return p.iind

    s = State()

    # We iterate over the text, looking for whitespace where to split.
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

                put_chunks!(out_str, chunk, s, p)
            end
            i = k
        end

        # This is whitespace. We mangle it (expand tabs, fix
        # sentence endings, replace it with single spaces) and
        # then we keep it on hold.
        soh = text[j:prevind(text,k)]
        @assert !isempty(soh)
        if expand_tabs && occursin(r"\t", soh)
            soh = apply_expand_tabs(soh, s.cll)
        end
        if p.fix_end && s.lcise && soh == " "
            soh = "  "
        end
        if p.rep_white
            soh = replace(soh, r"\r?\n"=>"")
            soh = isempty(soh) ? " " : " "^length(soh)
        else
            while (fnl = findfirst(==('\n'), soh)) ≢ nothing # using the `==` form to support julia 1.0-1.2
                ind = s.cln == 1 ? p.iind : p.sind
                print(out_str, ind, '\n')
                s.cll = 0
                s.cln += 1
                s.bol = true
                soh = soh[nextind(soh, fnl):end]
            end
        end
        s.soh = soh

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
        put_chunks!(out_str, chunk, s, p)
    end
    return String(take!(out_str))
end

"""
    print_wrapped([io,] text...; keywords...)

This is just like the standard `print` function (it prints multiple arguments and accepts an
optional `IO` first argument), except that it wraps the result, and accepts keyword arguments to
pass to [`wrap`](@ref).
"""
print_wrapped(io::IO, text::AbstractString; kwargs...) = print(io, wrap(text; kwargs...))
print_wrapped(args...; kwargs...) = print_wrapped(stdout, args...; kwargs...)
print_wrapped(io::IO; kwargs...) = print_wrapped(io, ""; kwargs...)
print_wrapped(io::IO, args...; kwargs...) = print_wrapped(io, string(args...); kwargs...)

"""
    println_wrapped([io,] text...; keywords...)

Like [`print_wrapped`](@ref), but adds a newline at the end.
"""
function println_wrapped(io::IO, args...; kwargs...)
    print_wrapped(io, args...; kwargs...)
    print(io, "\n")
end
println_wrapped(args...; kwargs...) = println_wrapped(stdout, args...; kwargs...)

end # module TextWrap
