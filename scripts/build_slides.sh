#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../presentation/source"
pdflatex -interaction=nonstopmode -halt-on-error main.tex
pdflatex -interaction=nonstopmode -halt-on-error main.tex
mv main.pdf ../Volatility_Management.pdf
printf 'Built presentation/Volatility_Management.pdf\n'
