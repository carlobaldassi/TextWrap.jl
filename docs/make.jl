using Documenter, TextWrap

makedocs(
    modules  = [TextWrap],
    format   = :html,
    sitename = "TextWrap.jl",
    pages    = Any[
        "Home" => "index.md",
       ]
    )

deploydocs(
    repo   = "github.com/carlobaldassi/TextWrap.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
    julia  = "0.6"
)
