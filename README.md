# TextWrap.jl

| **Documentation**                                                         | **Build Status**                                             |
|:-------------------------------------------------------------------------:|:------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![][travis-img]][travis-url][![][codecov-img]][codecov-url] |

This [Julia] package allows to wrap long lines of text to fit within a given width.

### Quick example

```
julia> text = "This text is going to be wrapped around in lines no longer than 20 characters.";

julia> println_wrapped(text, width=20)
This text is going
to be wrapped around
in lines no longer
than 20 characters.
```

The other exported functions are `wrap` (returns a string) and `print_wrapped`.
See the documentation for more advanced settings.

### Installation

To install the module, use Julia's package manager: start pkg mode by pressing <kbd>]</kbd> and then enter:

```
(v1.3) pkg> add TextWrap
```

Dependencies will be installed automatically.
The module can then be loaded like any other Julia module:

```
julia> using TextWrap
```

### Documentation

- [**STABLE**][docs-stable-url] &mdash; **most recently tagged version of the documentation.**
- [**DEV**][docs-dev-url] &mdash; *in-development version of the documentation.*

## Changes in release 1.0.1

* Improve recognition of ANSI escape codes
* Fixes for the `replace_whitespace=true` case

## Changes in release 1.0.0

* Drop support for Julia versions v0.6/v0.7
* Recognize ANSI escape codes and by default don't count them in the width computations

[Julia]: http://julialang.org

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://carlobaldassi.github.io/TextWrap.jl/stable
[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://carlobaldassi.github.io/TextWrap.jl/dev

[travis-img]: https://travis-ci.com/carlobaldassi/TextWrap.jl.svg?branch=master
[travis-url]: https://travis-ci.com/carlobaldassi/TextWrap.jl

[codecov-img]: https://codecov.io/gh/carlobaldassi/TextWrap.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/carlobaldassi/TextWrap.jl
