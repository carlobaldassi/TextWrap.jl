# TextWrap.jl documentation

```@meta
CurrentModule = TextWrap
```

This [Julia](http://julialang.org) package provides the function [`wrap`](@ref) which parses an input text
and reorganizes its white space so that it can be printed with a fixed screen width, optionally indenting it.
It also provides the two convenience functions [`print_wrapped`](@ref) and [`println_wrapped`](@ref).

Here is a quick example:

```jldoctest
julia> using TextWrap

julia> text = "This text is going to be wrapped around in lines no longer than 20 characters.";

julia> println_wrapped(text, width=20)
This text is going
to be wrapped around
in lines no longer
than 20 characters.
```

It's very similar to Python's textwrap module, but the interface is slightly different.


### Installation and usage

To install the module, use Julia's package manager: start pkg mode by pressing `]` and then enter:

```
(v1.3) pkg> add TextWrap
```

Dependencies will be installed automatically.
The module can then be loaded like any other Julia module:

```
julia> using TextWrap
```

## Functions reference

```@docs
wrap
```

```@docs
print_wrapped
```

```@docs
println_wrapped
```
