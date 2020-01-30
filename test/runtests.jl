module TextWrapTest

using TextWrap
using Test

@testset "empty" begin

@test wrap("") == ""
@test wrap("  \n") == ""
@test wrap("\n  ") == ""
@test wrap("\t\n\t\n") == ""
@test wrap("", initial_indent=2) == "  "

end # testset

@testset "plain" begin

@test wrap("a b") == "a b"
@test wrap("a\n\nb\n\n") == "a b"
@test wrap("\n\na\n\nb\n\n") == "a b"
@test wrap(" a  ", initial_indent=3) == "   a"
@test wrap(" a  ", initial_indent=">  ") == ">  a"

global text = """
    Julia is a high-level, high-performance dynamic programming language
    for technical computing, with syntax that is familiar to users of
    other technical computing environments. It provides a sophisticated
    compiler, distributed parallel execution, numerical accuracy, and an
    extensive mathematical function library."""

@test wrap(text) == """
    Julia is a high-level, high-performance dynamic programming language
    for technical computing, with syntax that is familiar to users of
    other technical computing environments. It provides a sophisticated
    compiler, distributed parallel execution, numerical accuracy, and an
    extensive mathematical function library."""

@test wrap(text, width=30) == """
    Julia is a high-level, high-
    performance dynamic
    programming language for
    technical computing, with
    syntax that is familiar to
    users of other technical
    computing environments. It
    provides a sophisticated
    compiler, distributed parallel
    execution, numerical accuracy,
    and an extensive mathematical
    function library."""

@test wrap(text, width=30, fix_sentence_endings=true, break_on_hyphens=false) == """
    Julia is a high-level,
    high-performance dynamic
    programming language for
    technical computing, with
    syntax that is familiar to
    users of other technical
    computing environments.  It
    provides a sophisticated
    compiler, distributed parallel
    execution, numerical accuracy,
    and an extensive mathematical
    function library."""

@test wrap(text, width=30, initial_indent=2, subsequent_indent=0) == """
      Julia is a high-level, high-
    performance dynamic
    programming language for
    technical computing, with
    syntax that is familiar to
    users of other technical
    computing environments. It
    provides a sophisticated
    compiler, distributed parallel
    execution, numerical accuracy,
    and an extensive mathematical
    function library."""

@test wrap(text, width=32, initial_indent=">   ", subsequent_indent="> ") == """
    >   Julia is a high-level, high-
    > performance dynamic
    > programming language for
    > technical computing, with
    > syntax that is familiar to
    > users of other technical
    > computing environments. It
    > provides a sophisticated
    > compiler, distributed parallel
    > execution, numerical accuracy,
    > and an extensive mathematical
    > function library."""

end # testset

@testset "whitespace" begin

tabtext = "aaaaaaa\tbbbbbbb\t\ncccccc\tddddd\teeee  \tfff\tgg\th\n"

@test wrap(tabtext, width=20, replace_whitespace=true,  expand_tabs=true) ==
    "aaaaaaa bbbbbbb\ncccccc  ddddd   eeee\nfff     gg      h"
@test wrap(tabtext, width=20, replace_whitespace=false, expand_tabs=true) ==
    "aaaaaaa bbbbbbb\ncccccc  ddddd   eeee\nfff     gg      h\n"
@test wrap(tabtext, width=20, replace_whitespace=true,  expand_tabs=false) ==
    "aaaaaaa bbbbbbb\ncccccc ddddd eeee\nfff gg h"
@test wrap(tabtext, width=20, replace_whitespace=false, expand_tabs=false) ==
    "aaaaaaa\tbbbbbbb\ncccccc\tddddd\teeee\nfff\tgg\th\n"

@test wrap("abc\ndefg h i j k", width=8, replace_whitespace=false) ==
           "abc\ndefg h i\nj k"
@test wrap("abc\ndefg h i j k", width=8, replace_whitespace=true) ==
           "abc defg\nh i j k"

@test wrap("\t.\n\t\n") == "."
@test wrap("\t..\n\t\n", fix_sentence_endings=true) == ".."
@test wrap("\tabc\n\t\n", width=2, expand_tabs=false) == "ab\nc"
@test wrap("\t \tabc\n\t\n", width=2) == "ab\nc"
@test wrap("\ta.\n\t\n", width=1, fix_sentence_endings=false) == "a\n."
@test wrap("\ta.\n\t\n", width=1, replace_whitespace=false) == "a\n.\n\n"
@test wrap("\ta.\tb\n", width=8, expand_tabs=true, replace_whitespace=true) == "a.\nb"
@test wrap("\ta.\tb\n", width=8, expand_tabs=true, replace_whitespace=false) == "a.\nb\n"
@test wrap("\ta.\tb\n", width=8, expand_tabs=false, replace_whitespace=false) == "a.\tb\n"
@test wrap("\ta.\tb\n", width=9, expand_tabs=false, replace_whitespace=false) == "a.\tb\n"
@test wrap("\ta.\tb\n", width=9, expand_tabs=true, replace_whitespace=false) == "a.      b\n"
@test wrap("\ta.\tb\n", width=9, expand_tabs=false, replace_whitespace=false, fix_sentence_endings=true) == "a.\tb\n"
@test wrap("\ta.\tb\n", width=9, expand_tabs=true, replace_whitespace=false, fix_sentence_endings=true) == "a.      b\n"

end # testset

@testset "long words" begin

longwordstext = """
    The 45-letter word pneumonoultramicroscopicsilicovolcanoconiosis is the longest English word that appears in a major dictionary. A 79 letter word,
    Donaudampfschiffahrtselektrizitätenhauptbetriebswerkbauunterbeamtengesellschaft, was named the longest published word in the German language by the 1996 Guinness Book of
    World Records, but longer words are possible. In his comedy Assemblywomen (c. 392 BC) Aristophanes coined the 171-letter word
    λοπαδοτεμαχοσελαχογαλεοκρανιολειψανοδριμυποτριμματοσιλφιοκαραβομελιτοκατακεχυμενοκιχλεπικοσσυφοφαττοπεριστεραλεκτρυονοπτοκεφαλλιοκιγκλοπελειολαγῳοσιραιοβαφητραγανοπτερύγων.
    The longest Hebrew word is the 25-letter-long (including vowels) וכשלאנציקלופדיותינו (u'chshelentsiklopedioténu), which means 'and when our encyclopedias will have....'"""

@test wrap(longwordstext, width=172) == """
    The 45-letter word pneumonoultramicroscopicsilicovolcanoconiosis is the longest English word that appears in a major dictionary. A 79 letter word,
    Donaudampfschiffahrtselektrizitätenhauptbetriebswerkbauunterbeamtengesellschaft, was named the longest published word in the German language by the 1996 Guinness Book of
    World Records, but longer words are possible. In his comedy Assemblywomen (c. 392 BC) Aristophanes coined the 171-letter word
    λοπαδοτεμαχοσελαχογαλεοκρανιολειψανοδριμυποτριμματοσιλφιοκαραβομελιτοκατακεχυμενοκιχλεπικοσσυφοφαττοπεριστεραλεκτρυονοπτοκεφαλλιοκιγκλοπελειολαγῳοσιραιοβαφητραγανοπτερύγων.
    The longest Hebrew word is the 25-letter-long (including vowels) וכשלאנציקלופדיותינו (u'chshelentsiklopedioténu), which means 'and when our encyclopedias will have....'"""

@test wrap(longwordstext, width=171) == """
    The 45-letter word pneumonoultramicroscopicsilicovolcanoconiosis is the longest English word that appears in a major dictionary. A 79 letter word,
    Donaudampfschiffahrtselektrizitätenhauptbetriebswerkbauunterbeamtengesellschaft, was named the longest published word in the German language by the 1996 Guinness Book of
    World Records, but longer words are possible. In his comedy Assemblywomen (c. 392 BC) Aristophanes coined the 171-letter word λοπαδοτεμαχοσελαχογαλεοκρανιολειψανοδριμυποτρ
    ιμματοσιλφιοκαραβομελιτοκατακεχυμενοκιχλεπικοσσυφοφαττοπεριστεραλεκτρυονοπτοκεφαλλιοκιγκλοπελειολαγῳοσιραιοβαφητραγανοπτερύγων. The longest Hebrew word is the 25-letter-
    long (including vowels) וכשלאנציקלופדיותינו (u'chshelentsiklopedioténu), which means 'and when our encyclopedias will have....'"""

@test wrap(longwordstext, width=80) == """
    The 45-letter word pneumonoultramicroscopicsilicovolcanoconiosis is the longest
    English word that appears in a major dictionary. A 79 letter word,
    Donaudampfschiffahrtselektrizitätenhauptbetriebswerkbauunterbeamtengesellschaft,
    was named the longest published word in the German language by the 1996 Guinness
    Book of World Records, but longer words are possible. In his comedy
    Assemblywomen (c. 392 BC) Aristophanes coined the 171-letter word λοπαδοτεμαχοσε
    λαχογαλεοκρανιολειψανοδριμυποτριμματοσιλφιοκαραβομελιτοκατακεχυμενοκιχλεπικοσσυφ
    οφαττοπεριστεραλεκτρυονοπτοκεφαλλιοκιγκλοπελειολαγῳοσιραιοβαφητραγανοπτερύγων.
    The longest Hebrew word is the 25-letter-long (including vowels)
    וכשלאנציקלופדיותינו (u'chshelentsiklopedioténu), which means 'and when our
    encyclopedias will have....'"""

@test wrap(longwordstext, width=79) == """
    The 45-letter word pneumonoultramicroscopicsilicovolcanoconiosis is the longest
    English word that appears in a major dictionary. A 79 letter word, Donaudampfsc
    hiffahrtselektrizitätenhauptbetriebswerkbauunterbeamtengesellschaft, was named
    the longest published word in the German language by the 1996 Guinness Book of
    World Records, but longer words are possible. In his comedy Assemblywomen (c.
    392 BC) Aristophanes coined the 171-letter word λοπαδοτεμαχοσελαχογαλεοκρανιολε
    ιψανοδριμυποτριμματοσιλφιοκαραβομελιτοκατακεχυμενοκιχλεπικοσσυφοφαττοπεριστεραλ
    εκτρυονοπτοκεφαλλιοκιγκλοπελειολαγῳοσιραιοβαφητραγανοπτερύγων. The longest
    Hebrew word is the 25-letter-long (including vowels) וכשלאנציקלופדיותינו
    (u'chshelentsiklopedioténu), which means 'and when our encyclopedias will
    have....'"""

@test wrap(longwordstext, width=45) == """
    The 45-letter word
    pneumonoultramicroscopicsilicovolcanoconiosis
    is the longest English word that appears in a
    major dictionary. A 79 letter word, Donaudamp
    fschiffahrtselektrizitätenhauptbetriebswerkba
    uunterbeamtengesellschaft, was named the
    longest published word in the German language
    by the 1996 Guinness Book of World Records,
    but longer words are possible. In his comedy
    Assemblywomen (c. 392 BC) Aristophanes coined
    the 171-letter word λοπαδοτεμαχοσελαχογαλεοκρ
    ανιολειψανοδριμυποτριμματοσιλφιοκαραβομελιτοκ
    ατακεχυμενοκιχλεπικοσσυφοφαττοπεριστεραλεκτρυ
    ονοπτοκεφαλλιοκιγκλοπελειολαγῳοσιραιοβαφητραγ
    ανοπτερύγων. The longest Hebrew word is the
    25-letter-long (including vowels)
    וכשלאנציקלופדיותינו
    (u'chshelentsiklopedioténu), which means 'and
    when our encyclopedias will have....'"""

@test wrap(longwordstext, width=44) == """
    The 45-letter word pneumonoultramicroscopics
    ilicovolcanoconiosis is the longest English
    word that appears in a major dictionary. A
    79 letter word, Donaudampfschiffahrtselektri
    zitätenhauptbetriebswerkbauunterbeamtengesel
    lschaft, was named the longest published
    word in the German language by the 1996
    Guinness Book of World Records, but longer
    words are possible. In his comedy
    Assemblywomen (c. 392 BC) Aristophanes
    coined the 171-letter word λοπαδοτεμαχοσελαχ
    ογαλεοκρανιολειψανοδριμυποτριμματοσιλφιοκαρα
    βομελιτοκατακεχυμενοκιχλεπικοσσυφοφαττοπερισ
    τεραλεκτρυονοπτοκεφαλλιοκιγκλοπελειολαγῳοσιρ
    αιοβαφητραγανοπτερύγων. The longest Hebrew
    word is the 25-letter-long (including
    vowels) וכשלאנציקלופדיותינו
    (u'chshelentsiklopedioténu), which means
    'and when our encyclopedias will have....'"""

@test wrap(longwordstext, width=19) == """
    The 45-letter word
    pneumonoultramicros
    copicsilicovolcanoc
    oniosis is the
    longest English
    word that appears
    in a major
    dictionary. A 79
    letter word, Donaud
    ampfschiffahrtselek
    trizitätenhauptbetr
    iebswerkbauunterbea
    mtengesellschaft,
    was named the
    longest published
    word in the German
    language by the
    1996 Guinness Book
    of World Records,
    but longer words
    are possible. In
    his comedy
    Assemblywomen (c.
    392 BC)
    Aristophanes coined
    the 171-letter word
    λοπαδοτεμαχοσελαχογ
    αλεοκρανιολειψανοδρ
    ιμυποτριμματοσιλφιο
    καραβομελιτοκατακεχ
    υμενοκιχλεπικοσσυφο
    φαττοπεριστεραλεκτρ
    υονοπτοκεφαλλιοκιγκ
    λοπελειολαγῳοσιραιο
    βαφητραγανοπτερύγων
    . The longest
    Hebrew word is the
    25-letter-long
    (including vowels)
    וכשלאנציקלופדיותינו
    (u'chshelentsiklope
    dioténu), which
    means 'and when our
    encyclopedias will
    have....'"""

@test wrap(longwordstext, width=18) == """
    The 45-letter word
    pneumonoultramicro
    scopicsilicovolcan
    oconiosis is the
    longest English
    word that appears
    in a major
    dictionary. A 79
    letter word, Donau
    dampfschiffahrtsel
    ektrizitätenhauptb
    etriebswerkbauunte
    rbeamtengesellscha
    ft, was named the
    longest published
    word in the German
    language by the
    1996 Guinness Book
    of World Records,
    but longer words
    are possible. In
    his comedy
    Assemblywomen (c.
    392 BC)
    Aristophanes
    coined the
    171-letter word λο
    παδοτεμαχοσελαχογα
    λεοκρανιολειψανοδρ
    ιμυποτριμματοσιλφι
    οκαραβομελιτοκατακ
    εχυμενοκιχλεπικοσσ
    υφοφαττοπεριστεραλ
    εκτρυονοπτοκεφαλλι
    οκιγκλοπελειολαγῳο
    σιραιοβαφητραγανοπ
    τερύγων. The
    longest Hebrew
    word is the
    25-letter-long
    (including vowels)
    וכשלאנציקלופדיותינ
    ו (u'chshelentsikl
    opedioténu), which
    means 'and when
    our encyclopedias
    will have....'"""

@test wrap(longwordstext, width=18, break_long_words=false) == """
    The 45-letter word
    pneumonoultramicroscopicsilicovolcanoconiosis
    is the longest
    English word that
    appears in a major
    dictionary. A 79
    letter word,
    Donaudampfschiffahrtselektrizitätenhauptbetriebswerkbauunterbeamtengesellschaft,
    was named the
    longest published
    word in the German
    language by the
    1996 Guinness Book
    of World Records,
    but longer words
    are possible. In
    his comedy
    Assemblywomen (c.
    392 BC)
    Aristophanes
    coined the
    171-letter word
    λοπαδοτεμαχοσελαχογαλεοκρανιολειψανοδριμυποτριμματοσιλφιοκαραβομελιτοκατακεχυμενοκιχλεπικοσσυφοφαττοπεριστεραλεκτρυονοπτοκεφαλλιοκιγκλοπελειολαγῳοσιραιοβαφητραγανοπτερύγων.
    The longest Hebrew
    word is the
    25-letter-long
    (including vowels)
    וכשלאנציקלופדיותינו
    (u'chshelentsiklopedioténu),
    which means 'and
    when our
    encyclopedias will
    have....'"""

end # testset

@testset "escape codes" begin

N = Base.text_colors[:normal]
U = Base.text_colors[:underline]
B = Base.text_colors[:bold]
R = Base.text_colors[:reverse]

r = N * Base.text_colors[:red]
b = N * U * Base.text_colors[:light_blue]
y = N * B * Base.text_colors[:light_yellow]
m = N * B * R * Base.text_colors[134]

etext = """
    Julia is a $(r)high-level$(N), $(b)$(B)high$(b)-performance$(N) dynamic programming language
    for technical computing, with syntax that is familiar to users of
    other technical computing environments. It provides a $(y)sophisticated$(N)
    compiler, distributed parallel execution, numerical accuracy, and an
    $(m)extensive mathematical function library$(N)."""

@test wrap(etext) == """
    Julia is a $(r)high-level$(N), $(b)$(B)high$(b)-performance$(N) dynamic programming language
    for technical computing, with syntax that is familiar to users of
    other technical computing environments. It provides a $(y)sophisticated$(N)
    compiler, distributed parallel execution, numerical accuracy, and an
    $(m)extensive mathematical function library$(N)."""

@test wrap(etext, width=30) == """
    Julia is a $(r)high-level$(N), $(b)$(B)high$(b)-
    performance$(N) dynamic
    programming language for
    technical computing, with
    syntax that is familiar to
    users of other technical
    computing environments. It
    provides a $(y)sophisticated$(N)
    compiler, distributed parallel
    execution, numerical accuracy,
    and an $(m)extensive mathematical
    function library$(N)."""

@test wrap(etext, width=30, fix_sentence_endings=true, break_on_hyphens=false) == """
    Julia is a $(r)high-level$(N),
    $(b)$(B)high$(b)-performance$(N) dynamic
    programming language for
    technical computing, with
    syntax that is familiar to
    users of other technical
    computing environments.  It
    provides a $(y)sophisticated$(N)
    compiler, distributed parallel
    execution, numerical accuracy,
    and an $(m)extensive mathematical
    function library$(N)."""

@test wrap(etext, width=30, initial_indent=2, subsequent_indent=0) == """
      Julia is a $(r)high-level$(N), $(b)$(B)high$(b)-
    performance$(N) dynamic
    programming language for
    technical computing, with
    syntax that is familiar to
    users of other technical
    computing environments. It
    provides a $(y)sophisticated$(N)
    compiler, distributed parallel
    execution, numerical accuracy,
    and an $(m)extensive mathematical
    function library$(N)."""

@test wrap(etext, width=32, initial_indent=">   ", subsequent_indent="> ") == """
    >   Julia is a $(r)high-level$(N), $(b)$(B)high$(b)-
    > performance$(N) dynamic
    > programming language for
    > technical computing, with
    > syntax that is familiar to
    > users of other technical
    > computing environments. It
    > provides a $(y)sophisticated$(N)
    > compiler, distributed parallel
    > execution, numerical accuracy,
    > and an $(m)extensive mathematical
    > function library$(N)."""

@test wrap(etext, width=35, recognize_escapes=false) == """
    Julia is a $(r)high-level$(N),
    $(b)$(B)high$(b)-
    performance$(N) dynamic programming
    language for technical computing,
    with syntax that is familiar to
    users of other technical computing
    environments. It provides a
    $(y)sophisticated$(N)
    compiler, distributed parallel
    execution, numerical accuracy, and
    an $(m)extensive
    mathematical function library$(N)."""

end # testset

@testset "print" begin

tmpf = tempname()
try
    open(tmpf, "w") do f
        print_wrapped(f)
    end
    @test read(tmpf, String) == ""

    open(tmpf, "w") do f
        print_wrapped(f, initial_indent=2, subsequent_indent=2)
    end
    @test read(tmpf, String) == "  "

    open(tmpf, "w") do f
        print_wrapped(f, "")
    end
    @test read(tmpf, String) == ""

    open(tmpf, "w") do f
        print_wrapped(f, "abc", "def")
    end
    @test read(tmpf, String) == "abcdef"

    open(tmpf, "w") do f
        println_wrapped(f, "abc", "def")
    end
    @test read(tmpf, String) == "abcdef\n"

    open(tmpf, "w") do f
        redirect_stdout(f) do
            print_wrapped("abc", "def")
        end
    end
    @test read(tmpf, String) == "abcdef"

    open(tmpf, "w") do f
        redirect_stdout(f) do
            println_wrapped("abc", "def")
        end
    end
    @test read(tmpf, String) == "abcdef\n"


    open(tmpf, "w") do f
        print_wrapped(f, text, width=30, fix_sentence_endings=true, break_on_hyphens=false)
    end
    @test read(tmpf, String) == """
        Julia is a high-level,
        high-performance dynamic
        programming language for
        technical computing, with
        syntax that is familiar to
        users of other technical
        computing environments.  It
        provides a sophisticated
        compiler, distributed parallel
        execution, numerical accuracy,
        and an extensive mathematical
        function library."""

    open(tmpf, "w") do f
        println_wrapped(f, text, width=30, fix_sentence_endings=true, break_on_hyphens=false)
    end
    @test read(tmpf, String) == """
        Julia is a high-level,
        high-performance dynamic
        programming language for
        technical computing, with
        syntax that is familiar to
        users of other technical
        computing environments.  It
        provides a sophisticated
        compiler, distributed parallel
        execution, numerical accuracy,
        and an extensive mathematical
        function library.
        """

    open(tmpf, "w") do f
        println_wrapped(f, width=30, fix_sentence_endings=true, break_on_hyphens=false)
    end
    @test read(tmpf, String) == "\n"

    open(tmpf, "w") do f
        bk_stdout = stdout
        try
            redirect_stdout(f)
            print_wrapped(text, width=30, fix_sentence_endings=true, break_on_hyphens=false)
        finally
            redirect_stdout(bk_stdout)
        end
    end
    @test read(tmpf, String) == """
        Julia is a high-level,
        high-performance dynamic
        programming language for
        technical computing, with
        syntax that is familiar to
        users of other technical
        computing environments.  It
        provides a sophisticated
        compiler, distributed parallel
        execution, numerical accuracy,
        and an extensive mathematical
        function library."""
finally
    isfile(tmpf) && rm(tmpf)
end

end # testset

@testset "argument checks" begin

@test_throws ArgumentError wrap("", width=0)
@test_throws ArgumentError wrap("", initial_indent=10, width=10)
@test_throws ArgumentError wrap("", subsequent_indent=10, width=10)
@test_throws ArgumentError wrap("", initial_indent="~~~~~~~~~~", width=10)
@test_throws ArgumentError wrap("", subsequent_indent="~~~~~~~~~~", width=10)

end # testset


end # module
