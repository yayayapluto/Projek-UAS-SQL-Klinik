#!/usr/bin/env bash
# =====================================================================
# tools/reset-db.sh
# Mengembalikan database klinik_pratama ke kondisi bersih, lalu memuat
# seluruh skrip SQL dari awal: struktur, data, view/trigger, prosedur,
# keamanan, dan indeks.
#
# Pakai: bash tools/reset-db.sh
# Syarat: container kbd-mysql hidup, atau MySQL host (XAMPP/Laragon) menyala.
# =====================================================================
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/tools/db.sh"
echo "   sumber: $MODE${MYSQL_BIN:+ ($MYSQL_BIN)}"

echo "== 1. Hapus dan buat ulang database =="
db -e "DROP DATABASE IF EXISTS klinik_pratama;" 2>/dev/null
echo "   database klinik_pratama dihapus"

for skrip in 01_struktur 02_data 03_view_trigger 04_prosedur 05_keamanan 06_indeks; do
  echo "== 2. Jalankan sql/${skrip}.sql =="
  db < "$DIR/sql/${skrip}.sql" 2>&1 | grep -v "Using a password" || true
  echo "   selesai"
done

echo "== 3. Periksa jumlah tabel =="
JUMLAH=$(db -N -B \
  -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='klinik_pratama' AND table_type='BASE TABLE';" 2>/dev/null)
echo "   tabel terdaftar: $JUMLAH"

if [ "$JUMLAH" != "11" ]; then
  echo "GAGAL: tabel seharusnya 11, yang ada $JUMLAH" >&2
  exit 1
fi

echo "Database siap dipakai."
