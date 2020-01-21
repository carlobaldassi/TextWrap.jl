using Documenter, TextWrap

makedocs(
    modules  = [TextWrap],
    format = Documenter.HTML(prettyurls = "--local" ∉ ARGS),
    sitename = "TextWrap.jl",
    pages    = Any[
        "Home" => "index.md",
       ]
    )

deploydocs(
    repo   = "github.com/carlobaldassi/TextWrap.jl.git",
)
