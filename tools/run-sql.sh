#!/usr/bin/env bash
# =====================================================================
# tools/run-sql.sh
# Menjalankan satu berkas SQL dari folder sql/.
#
# Pakai:
#   bash tools/run-sql.sh 02
#   bash tools/run-sql.sh 7
#   bash tools/run-sql.sh --name kbd-mysql 02
#   bash tools/run-sql.sh --host 02
#
# Deteksi otomatis: container kbd-mysql, container mysql, lalu MySQL
# host (Laragon/XAMPP). Berkas 07 memakai --force.
# =====================================================================
set -uo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CT_NAME=""
FORCE_HOST=0
NUM=""

pakai() {
  cat <<'TEKS'
Pakai: bash tools/run-sql.sh [opsi] <nomor>

Nomor: 01 sampai 07. Angka 1 sampai 7 juga diterima.
Opsi:
  --name <container>  pakai container MySQL dengan nama tersebut
  --host              langsung pakai MySQL host, lewati deteksi container
  -h, --help          tampilkan bantuan ini

Contoh:
  bash tools/run-sql.sh 02
  bash tools/run-sql.sh 07
  bash tools/run-sql.sh --name mysql 03
TEKS
}

gagal() {
  printf 'GAGAL: %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --name)
      [ $# -ge 2 ] || gagal "--name butuh nama container."
      CT_NAME="$2"
      shift 2
      ;;
    --host)
      FORCE_HOST=1
      shift
      ;;
    -h|--help)
      pakai
      exit 0
      ;;
    -*)
      gagal "opsi tidak dikenal: $1"
      ;;
    *)
      [ -z "$NUM" ] || gagal "hanya satu nomor berkas yang boleh diberikan."
      NUM="$1"
      shift
      ;;
  esac
done

[ -n "$NUM" ] || { pakai; exit 1; }

case "$NUM" in
  [1-7]) NUM="0$NUM" ;;
  01|02|03|04|05|06|07) ;;
  *) gagal "nomor harus 01 sampai 07, bukan $NUM." ;;
esac

BERKAS=("$ROOT/sql/${NUM}"_*.sql)
[ ${#BERKAS[@]} -eq 1 ] || gagal "berkas sql/${NUM}_*.sql tidak ditemukan atau lebih dari satu."
BERKAS="${BERKAS[0]}"

# Cari klien mysql host: PATH, Laragon, XAMPP, MySQL umum.
cari_mysql_host() {
  local kandidat
  for kandidat in mysql mysql.exe; do
    if command -v "$kandidat" >/dev/null 2>&1; then
      command -v "$kandidat"
      return 0
    fi
  done
  for kandidat in \
    /c/laragon/bin/mysql/*/bin/mysql.exe \
    /c/xampp/mysql/bin/mysql.exe \
    "/c/Program Files/MySQL/MySQL Server"*/bin/mysql.exe \
    /c/msys64/mingw64/bin/mysql.exe; do
    if [ -x "$kandidat" ]; then
      printf '%s\n' "$kandidat"
      return 0
    fi
  done
  return 1
}

# Argumen koneksi host.
HOST_ARGS=(-h 127.0.0.1 -P "${KBD_PORT:-3306}" -u root)
[ -z "${KBD_PW-}" ] || HOST_ARGS+=("-p${KBD_PW}")

# 1. Container yang dipaksa lewat --name.
if [ -n "$CT_NAME" ]; then
  if ! command -v docker >/dev/null 2>&1; then
    gagal "Docker tidak ditemukan, tetapi --name $CT_NAME diberikan."
  fi
  JALAN=$(docker inspect -f '{{.State.Running}}' "$CT_NAME" 2>/dev/null || true)
  [ "$JALAN" = "true" ] || gagal "container $CT_NAME tidak ada atau tidak berjalan."
  MODE="container"
fi

# 2. Deteksi container otomatis.
if [ -z "${MODE-}" ] && [ "$FORCE_HOST" -eq 0 ] && command -v docker >/dev/null 2>&1; then
  NAMA_CONTAINER=$(docker ps --format '{{.Names}}' 2>/dev/null || true)
  for kandidat in kbd-mysql mysql; do
    if printf '%s\n' "$NAMA_CONTAINER" | grep -Fxq "$kandidat"; then
      CT_NAME="$kandidat"
      MODE="container"
      break
    fi
  done
fi

# 3. Host: cari klien, lalu uji koneksi.
if [ -z "${MODE-}" ]; then
  MYSQL_BIN="$(cari_mysql_host || true)"
  if [ -n "$MYSQL_BIN" ]; then
    PESAN=$("$MYSQL_BIN" "${HOST_ARGS[@]}" -e 'SELECT 1' 2>&1)
    if [ $? -eq 0 ]; then
      MODE="host"
    else
      printf '%s\n' "$PESAN" >&2
      case "$PESAN" in
        *"Access denied"*|*"ERROR 1045"*)
          gagal "MySQL host menolak login root. Set KBD_PW dengan kata sandi yang benar."
          ;;
        *)
          gagal "MySQL host belum menyala. Nyalakan XAMPP atau Laragon, lalu ulangi."
          ;;
      esac
    fi
  fi
fi

[ -n "${MODE-}" ] || gagal "container kbd-mysql/mysql tidak ditemukan dan MySQL host tidak tersedia. Jalankan dengan --name <container>, atau nyalakan XAMPP/Laragon."

FORCE=()
[ "$NUM" = "07" ] && FORCE=(--force)

printf '== Menjalankan %s ==\n' "${BERKAS#$ROOT/}"
if [ "$MODE" = "container" ]; then
  PW="${KBD_PW-kbd}"
  ARGS=(-uroot)
  [ -z "$PW" ] || ARGS+=("-p$PW")
  printf '   container: %s\n' "$CT_NAME"
  docker exec -i "$CT_NAME" mysql "${ARGS[@]}" "${FORCE[@]}" < "$BERKAS"
else
  printf '   host: %s\n' "$MYSQL_BIN"
  "$MYSQL_BIN" "${HOST_ARGS[@]}" "${FORCE[@]}" < "$BERKAS"
fi

STATUS=$?
if [ $STATUS -eq 0 ]; then
  printf '== Selesai: %s ==\n' "${BERKAS##*/}"
else
  printf '== GAGAL: %s (kode %s) ==\n' "${BERKAS##*/}" "$STATUS" >&2
fi
exit $STATUS