#!/usr/bin/env bash
# =====================================================================
# tools/verify.sh
# Memeriksa isi database dan perilaku sistem setelah reset-db.sh.
# Semua pemeriksaan bernomor; skrip berhenti dengan kode keluar bukan nol
# kalau ada satu saja yang gagal.
#
# Pakai: bash tools/verify.sh
# Syarat: container kbd-mysql hidup, atau MySQL host (XAMPP/Laragon) menyala.
# =====================================================================
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/tools/db.sh"
LULUS=0
GAGAL=0

q() {
  db -D klinik_pratama -N -B -e "$1" 2>/dev/null
}

cek_sama() {
  local nama="$1" harap="$2" dapat="$3"
  if [ "$harap" = "$dapat" ]; then
    printf '  [OK]   %-52s = %s\n' "$nama" "$dapat"
    LULUS=$((LULUS + 1))
  else
    printf '  [GAGAL] %-51s harap %s, dapat %s\n' "$nama" "$harap" "$dapat"
    GAGAL=$((GAGAL + 1))
  fi
}

cek_menggalat() {
  local nama="$1" sql="$2" pola="$3"
  local keluaran
  keluaran=$(db -e "USE klinik_pratama; $sql" 2>&1)
  if [ $? -ne 0 ] && echo "$keluaran" | grep -qi -- "$pola"; then
    printf '  [OK]   %-52s ditolak: %s\n' "$nama" "$(echo "$keluaran" | grep -oiE 'ERROR [0-9]+.*' | head -1 | cut -c1-40)"
    LULUS=$((LULUS + 1))
  else
    printf '  [GAGAL] %-51s seharusnya ditolak (%s)\n' "$nama" "$pola"
    GAGAL=$((GAGAL + 1))
  fi
}

echo "== A. Struktur dan isi tabel =="

cek_sama "jumlah tabel di klinik_pratama" "11" \
  "$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='klinik_pratama' AND table_type='BASE TABLE';")"

cek_sama "jumlah view di klinik_pratama" "2" \
  "$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='klinik_pratama' AND table_type='VIEW';")"

for t in poli dokter jadwal_praktik pasien kunjungan rekam_medis tindakan detail_tindakan obat detail_resep pembayaran; do
  baris=$(q "SELECT COUNT(*) FROM klinik_pratama.$t;")
  if [ "${baris:-0}" -ge 5 ]; then
    printf '  [OK]   %-52s = %s baris\n' "isi tabel $t minimal 5 baris" "$baris"
    LULUS=$((LULUS + 1))
  else
    printf '  [GAGAL] %-51s hanya %s baris\n' "isi tabel $t minimal 5 baris" "${baris:-0}"
    GAGAL=$((GAGAL + 1))
  fi
done

echo "== B. Keutuhan relasi (tidak ada foreign key yatim) =="

YATIM=$(q "
SELECT COUNT(*) FROM (
  SELECT d.id_dokter FROM klinik_pratama.dokter d
    LEFT JOIN klinik_pratama.poli p ON p.id_poli = d.id_poli WHERE p.id_poli IS NULL
  UNION ALL
  SELECT j.id_jadwal FROM klinik_pratama.jadwal_praktik j
    LEFT JOIN klinik_pratama.dokter d ON d.id_dokter = j.id_dokter WHERE d.id_dokter IS NULL
  UNION ALL
  SELECT k.id_kunjungan FROM klinik_pratama.kunjungan k
    LEFT JOIN klinik_pratama.pasien p ON p.id_pasien = k.id_pasien WHERE p.id_pasien IS NULL
  UNION ALL
  SELECT k.id_kunjungan FROM klinik_pratama.kunjungan k
    LEFT JOIN klinik_pratama.jadwal_praktik j ON j.id_jadwal = k.id_jadwal WHERE j.id_jadwal IS NULL
  UNION ALL
  SELECT r.id_rekam FROM klinik_pratama.rekam_medis r
    LEFT JOIN klinik_pratama.kunjungan k ON k.id_kunjungan = r.id_kunjungan WHERE k.id_kunjungan IS NULL
  UNION ALL
  SELECT dt.id_detail_tindakan FROM klinik_pratama.detail_tindakan dt
    LEFT JOIN klinik_pratama.kunjungan k ON k.id_kunjungan = dt.id_kunjungan WHERE k.id_kunjungan IS NULL
  UNION ALL
  SELECT dt.id_detail_tindakan FROM klinik_pratama.detail_tindakan dt
    LEFT JOIN klinik_pratama.tindakan t ON t.id_tindakan = dt.id_tindakan WHERE t.id_tindakan IS NULL
  UNION ALL
  SELECT dr.id_detail_resep FROM klinik_pratama.detail_resep dr
    LEFT JOIN klinik_pratama.rekam_medis r ON r.id_rekam = dr.id_rekam WHERE r.id_rekam IS NULL
  UNION ALL
  SELECT dr.id_detail_resep FROM klinik_pratama.detail_resep dr
    LEFT JOIN klinik_pratama.obat o ON o.id_obat = dr.id_obat WHERE o.id_obat IS NULL
  UNION ALL
  SELECT b.id_pembayaran FROM klinik_pratama.pembayaran b
    LEFT JOIN klinik_pratama.kunjungan k ON k.id_kunjungan = b.id_kunjungan WHERE k.id_kunjungan IS NULL
) x;")
cek_sama "jumlah baris dengan relasi yatim" "0" "$YATIM"

echo "== C. Aturan bisnis tercermin di data =="

cek_sama "sisa kuota jadwal 7 (kuota 4)" "0" \
  "$(q "SELECT j.kuota - COUNT(k.id_kunjungan) FROM klinik_pratama.jadwal_praktik j
          LEFT JOIN klinik_pratama.kunjungan k ON k.id_jadwal = j.id_jadwal
           AND k.status_kunjungan <> 'Batal' WHERE j.id_jadwal = 7 GROUP BY j.kuota;")"

cek_sama "kunjungan berstatus Batal" "2" \
  "$(q "SELECT COUNT(*) FROM klinik_pratama.kunjungan WHERE status_kunjungan='Batal';")"

cek_sama "kunjungan berstatus Menunggu" "2" \
  "$(q "SELECT COUNT(*) FROM klinik_pratama.kunjungan WHERE status_kunjungan='Menunggu';")"

cek_sama "pembayaran Belum Lunas" "3" \
  "$(q "SELECT COUNT(*) FROM klinik_pratama.pembayaran WHERE status_bayar='Belum Lunas';")"

cek_sama "baris view v_kunjungan_lengkap" "14" \
  "$(q "SELECT COUNT(*) FROM klinik_pratama.v_kunjungan_lengkap;")"

cek_sama "imt rekam medis 1 (72 kg, 170 cm)" "24.9" \
  "$(q "SELECT imt FROM klinik_pratama.rekam_medis WHERE id_rekam=1;")"

echo "== D. Indeks dipakai optimizer =="

cek_sama "EXPLAIN nama_pasien LIKE 'A%'" "idx_pasien_nama" \
  "$(q "EXPLAIN SELECT * FROM klinik_pratama.pasien WHERE nama_pasien LIKE 'A%';" | awk -F'\t' '{print $6}')"

cek_sama "EXPLAIN tanggal_kunjungan 2026-09-10" "idx_kunjungan_tanggal" \
  "$(q "EXPLAIN SELECT * FROM klinik_pratama.kunjungan WHERE tanggal_kunjungan='2026-09-10';" | awk -F'\t' '{print $6}')"

echo "== E. Penjagaan data menolak masukan salah =="

cek_menggalat "nomor antrean ganda ditolak" \
  "INSERT INTO kunjungan (id_pasien,id_jadwal,tanggal_kunjungan,no_antrean,status_kunjungan) VALUES (5,2,'2026-08-06',1,'Menunggu');" \
  "uq_kunjungan_antrean"

cek_menggalat "pasien tidak terdaftar ditolak" \
  "INSERT INTO kunjungan (id_pasien,id_jadwal,tanggal_kunjungan,no_antrean,status_kunjungan) VALUES (999,1,'2026-08-05',9,'Menunggu');" \
  "fk_kunjungan_pasien"

cek_menggalat "suhu 50 derajat ditolak" \
  "UPDATE rekam_medis SET suhu=50.0 WHERE id_rekam=1;" \
  "ck_rekam_suhu"

cek_menggalat "pendaftaran melewati kuota ditolak" \
  "INSERT INTO kunjungan (id_pasien,id_jadwal,tanggal_kunjungan,no_antrean,status_kunjungan) VALUES (5,7,'2026-10-07',5,'Menunggu');" \
  "Kuota jadwal sudah penuh"

cek_menggalat "jadwal dokter bentrok ditolak" \
  "INSERT INTO jadwal_praktik (id_dokter,tanggal,jam_mulai,jam_selesai,ruangan,kuota) VALUES (1,'2026-08-05','10:00:00','11:00:00','R-02',5);" \
  "Jadwal dokter bentrok"

cek_menggalat "resep melebihi stok ditolak" \
  "INSERT INTO detail_resep (id_rekam,id_obat,jumlah,aturan_pakai) VALUES (1,8,99,'3x1 sendok teh');" \
  "Stok obat tidak cukup"

echo "== F. Hak akses pengguna =="

GRANT_PETUGAS=$(db -N -B -e "SHOW GRANTS FOR 'petugas_klinik'@'%';" 2>/dev/null)
if echo "$GRANT_PETUGAS" | grep -q "klinik_pratama\`.\`pasien\`" \
   && echo "$GRANT_PETUGAS" | grep -q "klinik_pratama\`.\`kunjungan\`" \
   && ! echo "$GRANT_PETUGAS" | grep -q "rekam_medis"; then
  printf '  [OK]   %-52s sesuai\n' "GRANT petugas_klinik"
  LULUS=$((LULUS + 1))
else
  printf '  [GAGAL] %-51s tidak sesuai\n' "GRANT petugas_klinik"
  GAGAL=$((GAGAL + 1))
fi

GRANT_DOKTER=$(db -N -B -e "SHOW GRANTS FOR 'dokter_klinik'@'%';" 2>/dev/null)
if echo "$GRANT_DOKTER" | grep -q "klinik_pratama\`.\`rekam_medis\`"; then
  printf '  [OK]   %-52s sesuai\n' "GRANT dokter_klinik"
  LULUS=$((LULUS + 1))
else
  printf '  [GAGAL] %-51s tidak sesuai\n' "GRANT dokter_klinik"
  GAGAL=$((GAGAL + 1))
fi

KELUARAN_PETUGAS=$(db_as petugas_klinik 'Klinik#2026' klinik_pratama \
  -e "INSERT INTO obat (nama_obat,satuan,harga,stok) VALUES ('Uji Ilegal','Tablet',1000.00,1);" 2>&1)
if echo "$KELUARAN_PETUGAS" | grep -q "ERROR 1142"; then
  printf '  [OK]   %-52s ditolak 1142\n' "petugas_klinik menulis ke obat"
  LULUS=$((LULUS + 1))
else
  printf '  [GAGAL] %-51s tidak ditolak\n' "petugas_klinik menulis ke obat"
  GAGAL=$((GAGAL + 1))
fi

echo "== G. Transaksi berhasil seluruhnya atau tidak sama sekali =="

q "INSERT INTO jadwal_praktik (id_dokter,tanggal,jam_mulai,jam_selesai,ruangan,kuota)
   VALUES (4,'2026-12-21','09:00:00','11:00:00','R-04',5);" >/dev/null 2>&1
JADWAL_UJI=$(q "SELECT MAX(id_jadwal) FROM klinik_pratama.jadwal_praktik;")

q "CALL sp_daftar_kunjungan(9,$JADWAL_UJI);" >/dev/null 2>&1
KUNJUNGAN_UJI=$(q "SELECT MAX(id_kunjungan) FROM klinik_pratama.kunjungan;")

q "INSERT INTO rekam_medis (id_kunjungan,keluhan,diagnosis,tekanan_darah,suhu,berat_badan,tinggi_badan,tanggal_periksa)
   VALUES ($KUNJUNGAN_UJI,'Uji transaksi','Uji transaksi','110/70',36.5,60.0,165.0,'2026-12-21');" >/dev/null 2>&1
REKAM_UJI=$(q "SELECT MAX(id_rekam) FROM klinik_pratama.rekam_medis;")

q "INSERT INTO detail_tindakan (id_kunjungan,id_tindakan,jumlah) VALUES ($KUNJUNGAN_UJI,3,1);
   INSERT INTO detail_resep (id_rekam,id_obat,jumlah,aturan_pakai) VALUES ($REKAM_UJI,1,10,'3x1 tablet');" >/dev/null 2>&1

q "CALL sp_bayar_kunjungan($KUNJUNGAN_UJI,'Tunai');" >/dev/null 2>&1

cek_sama "total tagihan sama dengan hitungan manual" "0" \
  "$(q "SELECT COUNT(*) FROM klinik_pratama.pembayaran b WHERE b.id_kunjungan=$KUNJUNGAN_UJI
          AND b.total_tagihan <> (
            COALESCE((SELECT SUM(dt.jumlah*t.tarif) FROM klinik_pratama.detail_tindakan dt
                        JOIN klinik_pratama.tindakan t ON t.id_tindakan=dt.id_tindakan
                       WHERE dt.id_kunjungan=$KUNJUNGAN_UJI),0)
            +
            COALESCE((SELECT SUM(dr.jumlah*o.harga) FROM klinik_pratama.detail_resep dr
                        JOIN klinik_pratama.rekam_medis rm ON rm.id_rekam=dr.id_rekam
                        JOIN klinik_pratama.obat o ON o.id_obat=dr.id_obat
                       WHERE rm.id_kunjungan=$KUNJUNGAN_UJI),0));")"

cek_menggalat "membayar dua kali ditolak" \
  "CALL sp_bayar_kunjungan($KUNJUNGAN_UJI,'Tunai');" \
  "Kunjungan sudah dibayar"

cek_sama "insert yang gagal tidak menyisakan baris" "0" \
  "$(q "SELECT COUNT(*) FROM klinik_pratama.pembayaran WHERE id_kunjungan=$KUNJUNGAN_UJI AND total_tagihan=0;")"

# Bersihkan data uji transaksi supaya database kembali seperti semula.
q "DELETE FROM klinik_pratama.pembayaran WHERE id_kunjungan=$KUNJUNGAN_UJI;
   DELETE FROM klinik_pratama.detail_resep WHERE id_rekam=$REKAM_UJI;
   DELETE FROM klinik_pratama.detail_tindakan WHERE id_kunjungan=$KUNJUNGAN_UJI;
   DELETE FROM klinik_pratama.rekam_medis WHERE id_rekam=$REKAM_UJI;
   DELETE FROM klinik_pratama.kunjungan WHERE id_kunjungan=$KUNJUNGAN_UJI;
   DELETE FROM klinik_pratama.jadwal_praktik WHERE id_jadwal=$JADWAL_UJI;
   UPDATE klinik_pratama.obat SET stok = stok + 10 WHERE id_obat=1;" >/dev/null 2>&1

echo
echo "=============================================="
printf 'Lulus: %s   Gagal: %s\n' "$LULUS" "$GAGAL"
if [ "$GAGAL" -ne 0 ]; then
  echo "ADA PEMERIKSAAN YANG GAGAL"
  exit 1
fi
echo "SEMUA PEMERIKSAAN LULUS"
