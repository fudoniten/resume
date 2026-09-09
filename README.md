# Resume

`resume.tex` is a [moderncv](https://ctan.org/pkg/moderncv) LaTeX document.
The flake builds it into a PDF with a pinned TeX Live, so the output does not
depend on whatever LaTeX happens to be installed locally.

## Build

```sh
nix build          # -> ./result/resume.pdf
nix run            # -> ./resume.pdf in the current directory (easier to email)
```

## Iterating

```sh
nix develop        # puts pdflatex on PATH
pdflatex resume.tex
```

The build runs `pdflatex` twice with `-halt-on-error`, so a LaTeX error fails
the build rather than quietly producing a broken PDF. `SOURCE_DATE_EPOCH` is
pinned, which makes the PDF byte-for-byte reproducible.

## Updating the pinned nixpkgs

```sh
nix flake update
```
