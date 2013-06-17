module TextWrapTest

using TextWrap
using Base.Test

text = """
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

tmpf = tempname()
try
    open(tmpf, "w") do f
        print_wrapped(f, text, width=30, fix_sentence_endings=true, break_on_hyphens=false)
    end
    @test readall(tmpf) == """
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
       
end
