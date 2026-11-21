#!/usr/bin/env bash
# tools/build.sh - membangun PDF laporan dari sumber LaTeX.
# Pakai: bash tools/build.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PDFLATEX=""
if command -v pdflatex >/dev/null 2>&1; then
  PDFLATEX="$(command -v pdflatex)"
elif [ -x "/c/Program Files/MiKTeX/miktex/bin/x64/pdflatex.exe" ]; then
  PDFLATEX="/c/Program Files/MiKTeX/miktex/bin/x64/pdflatex.exe"
elif [ -x "$LOCALAPPDATA/Programs/MiKTeX/miktex/bin/x64/pdflatex.exe" ]; then
  PDFLATEX="$LOCALAPPDATA/Programs/MiKTeX/miktex/bin/x64/pdflatex.exe"
fi

if [ -z "$PDFLATEX" ]; then
  echo "pdflatex tidak ditemukan. Pasang MiKTeX atau tambahkan ke PATH." >&2
  exit 1
fi

build_tex() {
  local dir="$1" file="$2"
  echo "== pdflatex $dir/$file =="
  ( cd "$ROOT/$dir" && "$PDFLATEX" -interaction=nonstopmode -halt-on-error "$file" >/dev/null )
  ( cd "$ROOT/$dir" && "$PDFLATEX" -interaction=nonstopmode -halt-on-error "$file" >/dev/null )
  echo "   selesai: $dir/${file%.tex}.pdf"
}

build_tex laporan template-laporan.tex

echo "PDF laporan siap."
