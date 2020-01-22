var documenterSearchIndex = {"docs":
[{"location":"#TextWrap.jl-documentation-1","page":"Home","title":"TextWrap.jl documentation","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"CurrentModule = TextWrap","category":"page"},{"location":"#","page":"Home","title":"Home","text":"This Julia package provides the function wrap which parses an input text and reorganizes its white space so that it can be printed with a fixed screen width, optionally indenting it. It also provides the two convenience functions print_wrapped and println_wrapped.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Here is a quick example:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> using TextWrap\n\njulia> text = \"This text is going to be wrapped around in lines no longer than 20 characters.\";\n\njulia> println_wrapped(text, width=20)\nThis text is going\nto be wrapped around\nin lines no longer\nthan 20 characters.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"It's very similar to Python's textwrap module, but the interface is slightly different.","category":"page"},{"location":"#Installation-and-usage-1","page":"Home","title":"Installation and usage","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"To install the module, use Julia's package manager: start pkg mode by pressing ] and then enter:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"(v1.3) pkg> add TextWrap","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Dependencies will be installed automatically. The module can then be loaded like any other Julia module:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> using TextWrap","category":"page"},{"location":"#Functions-reference-1","page":"Home","title":"Functions reference","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"wrap","category":"page"},{"location":"#TextWrap.wrap","page":"Home","title":"TextWrap.wrap","text":"wrap(string; keywords...)\n\nParses string and returns a new string in which newlines are inserted as appropriate in order for each line to fit within a specified width.\n\nThe behaviour can be controlled via optional keyword arguments:\n\nwidth (deafult=70): the maximum width of the wrapped text, including indentation.\ninitial_indent (default=\"\"): indentation of the first line. This can  be any string (shorter than width), or it can be an integer number (smaller than width).\nsubsequent_indent (default=\"\"): indentation of all lines except the first. Works the same as  initial_indent.\nbreak_on_hyphens (default=true): this flag determines whether words can be broken on hyphens, e.g. whether \"high-precision\" can be split into \"high-\" and \"precision\".\nbreak_long_words (default=true): this flag determines what to do when a word is too long to fit in any line. If true, the word will be broken, otherwise it will go beyond the desired text width.\nreplace_whitespace (default=true): if this flag is true, all whitespace characters in the original text (including newlines) will be replaced by spaces.\nexpand_tabs (default=true): if this flag is true, tabs will be expanded in-place into spaces. Otherwise a tab is counted as a single character. The expansion happens before whitespace replacement.\nfix_sentence_endings (default=false): if this flag is true, the wrapper will try to recognize sentence endings in the middle of a paragraph and put two spaces before the next sentence in case only one is present.\nrecognize_escapes (default=true): if true, compute all lengths ignoring ANSI escape codes (special character sequences used e.g. to modify the text color or other properties; they look e.g. like \"\\e[94m\")\n\n\n\n\n\n","category":"function"},{"location":"#","page":"Home","title":"Home","text":"print_wrapped","category":"page"},{"location":"#TextWrap.print_wrapped","page":"Home","title":"TextWrap.print_wrapped","text":"print_wrapped([io,] text...; keywords...)\n\nThis is just like the standard print function (it prints multiple arguments and accepts an optional IO first argument), except that it wraps the result, and accepts keyword arguments to pass to wrap.\n\n\n\n\n\n","category":"function"},{"location":"#","page":"Home","title":"Home","text":"println_wrapped","category":"page"},{"location":"#TextWrap.println_wrapped","page":"Home","title":"TextWrap.println_wrapped","text":"println_wrapped([io,] text...; keywords...)\n\nLike print_wrapped, but adds a newline at the end.\n\n\n\n\n\n","category":"function"}]
}