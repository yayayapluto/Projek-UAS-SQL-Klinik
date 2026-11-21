#!/usr/bin/env bash
# Kompilasi diagram alur Mermaid lalu ganti variabel warna jadi literal.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
node ~/.omp/tools/pele/render.mjs docs/alur-muat.mmd -o docs/alur-muat.svg
perl -0pi -e 's/(<svg\b[^>]*>)/$1\n<rect width="100%" height="100%" fill="#ffffff"\/>/; s/fill="var\(--_fg\)"/fill="#1f1f1f"/g; s/stroke="var\(--_l\)"/stroke="#1f1f1f"/g; s/fill="var\(--_l\)"/fill="#1f1f1f"/g; s/fill="var\(--_s\)"/fill="#f3f3f3"/g; s/stroke="var\(--_b\)"/stroke="#334155"/g' docs/alur-muat.svg
echo "docs/alur-muat.svg siap"
