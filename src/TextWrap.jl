module TextWrap

using Compat

export
    wrap,
    print_wrapped,
    println_wrapped

function _expand_tabs(text::AbstractString, i0::Int)
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

function _check_width(width::Integer)
    if width <= 0
        error("invalid width $width (must be > 0)")
    end
    return true
end
function _check_indent(indent::Integer, width::Integer)
    if indent < 0 || indent >= width
        error("invalid intent $indent (must be an integer between 0 and width-1, or an AbstractString)")
    end
    return true
end
function _check_indent(indent::AbstractString, width::Integer)
    if length(indent) >= width
        error("invalid intent (must be shorter than width-1)")
    end
end


function _put_chunks(chunk::AbstractString, out_str,
                    cln, cll, bol, soh,
                    width, initial_indent, subsequent_indent,
                    break_on_hyphens, break_long_words)

    # This function just performs breaks-on-hyphens and passes
    # individual chunks to _put_chunk

    _hyphen_re = r"^(\w+-)*?\w+[^0-9\W]+-(?=\w+[^0-9\W])"

    while break_on_hyphens
        m = match(_hyphen_re, chunk)
        if m === nothing
            break
        end
        c = m.match
        cln, cll, bol, lcise = _put_chunk(c, out_str,
                    cln, cll, bol, soh,
                    width, initial_indent, subsequent_indent,
                    break_long_words)
        soh = ""
        chunk = chunk[m.offset+endof(c):end]
    end

    cln, cll, bol, lcise = _put_chunk(chunk, out_str,
                cln, cll, bol, soh,
                width, initial_indent, subsequent_indent,
                break_long_words)
    return cln, cll, bol, lcise
end

function _put_chunk(chunk::AbstractString, out_str,
                    cln, cll, bol, soh,
                    width, initial_indent, subsequent_indent,
                    break_long_words)

    # Writes a chunk to out_str, based on the current position
    # as encoded in (cln, cll, bol) = (current_line_number,
    # current_line_length, beginning_of_line), and returns the
    # updated position (plus a flag to signal that an end-of-sentence
    # was detected).
    # The argument soh (=space_on_hold) is the spacing which should
    # go in front of chunk, and it may or may not be printed.
    # The rest are options.

    liindent = length(initial_indent)
    lsindent = length(subsequent_indent)
    lchunk = length(chunk)
    lsoh = length(soh)

    if cll + lsoh > width
        soh = ""
        lsoh = 0
        print(out_str, "\n")
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
    if cll + lsoh + lchunk <= width ||
            (cln == 1 && bol && !break_long_words)
        print(out_str, soh, chunk)
        cll += lchunk + lsoh
        bol = false
    # does the chunk fit into next line? or are we
    # forced to put it there?
    elseif lchunk <= width - lsindent || !break_long_words
        print(out_str, bol?"":"\n", subsequent_indent, chunk)
        cll = lsindent + lchunk
        cln += 1
        bol = false
    # break it until it fits
    else
        while cll + lsoh + lchunk > width
            if width - cll - lsoh > 0
                print(out_str, soh, chunk[1:chr2ind(chunk, width-cll-lsoh)], "\n",
                        subsequent_indent)
                chunk = chunk[chr2ind(chunk, width-cll-lsoh+1):end]
                lchunk = length(chunk)
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
    _sentence_end_re = r"\w([\.\!\?…]|\.\.\.)[\"\'´„]?\Z"
    lcise = ismatch(_sentence_end_re, chunk)

    return cln, cll, bol, lcise
end

 function wrap(text::AbstractString;
               width::Int = 70,
               initial_indent::Union{Integer,AbstractString} = "",
               subsequent_indent::Union{Integer,AbstractString} = "",
               expand_tabs::Bool = true,
               replace_whitespace::Bool = true,
               fix_sentence_endings::Bool = false,
               break_long_words::Bool = true,
               break_on_hyphens::Bool = true)

    # Reformat the single paragraph in 'text' so it fits in lines of
    # no more than 'opts.width' columns, and return an AbstractString.

    # Sanity checks
    _check_width(width)
    _check_indent(initial_indent, width)
    _check_indent(subsequent_indent, width)

    if isa(initial_indent, Integer)
        initial_indent = " "^initial_indent
    end
    if isa(subsequent_indent, Integer)
        subsequent_indent = " "^subsequent_indent
    end

    # State variables initialization
    cln = 1 # current line number
    cll = 0 # current line length
    bol = true # beginning of line
    lcise = false # last chunk is sentence ending
    soh = "" # space on hold

    # We iterate over the text, looking for whitespace
    # where to split.
    i = start(text)
    l = endof(text)
    out_str = IOBuffer()

    wsrng = search(text, r"\s+", i)
    j = first(wsrng)
    k = last(wsrng) + 1
    while 0 < j <= l
        if i < k
            if i < j
                # This is non-whitespace. We write it out according
                # to the current cursor position and the leading space.
                chunk = text[i:j-1]

                cln, cll, bol, lcise = _put_chunks(chunk, out_str,
                            cln, cll, bol, soh,
                            width, initial_indent, subsequent_indent,
                            break_on_hyphens, break_long_words)
            end
            i = k
        end

        # This is whitespace. We mangle it (expand tabs, fix
        # sentence endings, replace it with single spaces) and
        # then we keep it on hold.
        soh = text[j:k-1]
        if expand_tabs && ismatch(r"\t", soh)
            soh = _expand_tabs(soh, cll)
        end
        if fix_sentence_endings && lcise && soh == " "
            soh = "  "
        end
        if replace_whitespace
            soh = " "^length(soh)
        end

        # Continue the search

        if k <= j; k = nextind(text,j) end
        wsrng = search(text, r"\s+", k)
        j = first(wsrng)
        k = last(wsrng) + 1
    end
    if !done(text,i)
        # Some non-whitespace is left at the end.
        chunk = text[i:end]
        cln, cll, bol = _put_chunks(chunk, out_str,
                    cln, cll, bol, soh,
                    width, initial_indent, subsequent_indent,
                    break_on_hyphens, break_long_words)
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
    if !isempty(args) && isa(args[1], IO)
        io = args[1]
        args = args[2:end]
    else
        io = STDOUT
    end

    if !isempty(args)
        ws = wrap(string(args...); kwargs...)
    else
        ws = ""
    end

    if newline
        println(io, ws)
    else
        print(io, ws)
    end
end
print_wrapped(args...; kwargs...) = _print_wrapped(false, args...; kwargs...)
println_wrapped(args...; kwargs...) = _print_wrapped(true, args...; kwargs...)

end # module TextWrap
