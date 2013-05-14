using TextWrap
using OptionsMod

text = "Julia is a high-level, high-performance dynamic programming language " *
       "for technical computing, with syntax that is familiar to users of " *
       "other technical computing environments. It provides a sophisticated " *
       "compiler, distributed parallel execution, numerical accuracy, and an " *
       "extensive mathematical function library."

Test.@test wrap(text) ==
    "Julia is a high-level, high-performance dynamic programming language\n" *
    "for technical computing, with syntax that is familiar to users of\n" *
    "other technical computing environments. It provides a sophisticated\n" *
    "compiler, distributed parallel execution, numerical accuracy, and an\n" *
    "extensive mathematical function library."

Test.@test wrap(text, @options(width=>30)) ==
    "Julia is a high-level, high-\n" *
    "performance dynamic\n" *
    "programming language for\n" *
    "technical computing, with\n" *
    "syntax that is familiar to\n" *
    "users of other technical\n" *
    "computing environments. It\n" *
    "provides a sophisticated\n" *
    "compiler, distributed parallel\n" *
    "execution, numerical accuracy,\n" *
    "and an extensive mathematical\n" *
    "function library."
 
wrap(text, @options(width=>30, fix_sentence_endings=>true, break_on_hyphens=>false)) ==
    "Julia is a high-level,\n" *
    "high-performance dynamic\n" *
    "programming language for\n" *
    "technical computing, with\n" *
    "syntax that is familiar to\n" *
    "users of other technical\n" *
    "computing environments.  It\n" *
    "provides a sophisticated\n" *
    "compiler, distributed parallel\n" *
    "execution, numerical accuracy,\n" *
    "and an extensive mathematical\n" *
    "function library."
