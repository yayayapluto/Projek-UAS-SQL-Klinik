#!/usr/bin/env bash
# =====================================================================
# tools/db.sh
# Pemilih koneksi yang dipakai bersama oleh reset-db.sh, verify.sh, dan
# demo-isolasi.sh.
#
# Urutan pilihan:
#   1. container kbd-mysql (atau $KBD_CT) bila Docker hidup,
#   2. MySQL host: XAMPP / Laragon / klien mysql di PATH.
#
# Dipakai dengan: source "$(dirname "$0")/db.sh"
#
# Variabel lingkungan:
#   KBD_CT       nama container (bawaan kbd-mysql)
#   KBD_ROOT_PW  kata sandi root; bawaan "kbd" untuk container, kosong untuk host
#   KBD_HOST     host MySQL (bawaan 127.0.0.1)
#   KBD_PORT     port MySQL (bawaan 3306)
#   KBD_USER     pengguna root host (bawaan root)
# =====================================================================

CT="${KBD_CT:-kbd-mysql}"

cari_klien_host() {
  command -v mysql 2>/dev/null && return 0
  local kandidat=(
    /c/xampp/mysql/bin/mysql.exe
    /c/laragon/bin/mysql/*/bin/mysql.exe
    "/c/Program Files/MySQL"/*/bin/mysql.exe
  )
  local f
  for f in "${kandidat[@]}"; do
    [ -x "$f" ] && { printf '%s\n' "$f"; return 0; }
  done
  return 1
}

salah() { printf 'GAGAL: %s\n' "$1" >&2; exit 1; }

if command -v docker >/dev/null 2>&1 \
   && docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CT"; then
  MODE=container
  ROOT_PW="${KBD_ROOT_PW:-kbd}"

  db() {
    docker exec -i "$CT" mysql -uroot -p"$ROOT_PW" "$@"
  }

  # db_as <user> <sandi> <database> [argumen mysql lain]
  db_as() {
    local u="$1" p="$2" d="$3"; shift 3
    docker exec -i "$CT" mysql -u"$u" -p"$p" "$d" "$@"
  }
else
  MODE=""
  MYSQL_BIN="$(cari_klien_host)" || MYSQL_BIN=""
  [ -n "$MYSQL_BIN" ] || salah "container $CT tidak ada dan klien mysql host tidak ditemukan."
  ROOT_PW="${KBD_ROOT_PW-}"
  KBD_HOST="${KBD_HOST:-127.0.0.1}"
  KBD_PORT="${KBD_PORT:-3306}"

  HOST_CONN=(-h "$KBD_HOST" -P "$KBD_PORT")

  if ! "$MYSQL_BIN" "${HOST_CONN[@]}" -u "${KBD_USER:-root}" \
       ${ROOT_PW:+-p"$ROOT_PW"} -e "SELECT 1;" >/dev/null 2>&1; then
    salah "MySQL host $KBD_HOST:$KBD_PORT tidak bisa dihubungi. Nyalakan XAMPP atau Laragon, atau jalankan container $CT."
  fi
  MODE=host

  db() {
    "$MYSQL_BIN" "${HOST_CONN[@]}" -u "${KBD_USER:-root}" ${ROOT_PW:+-p"$ROOT_PW"} "$@"
  }

  db_as() {
    local u="$1" p="$2" d="$3"; shift 3
    "$MYSQL_BIN" "${HOST_CONN[@]}" -u"$u" -p"$p" "$d" "$@"
  }
fi
