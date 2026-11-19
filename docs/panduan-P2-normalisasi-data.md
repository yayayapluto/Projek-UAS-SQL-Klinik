# Panduan P2: Normalisasi dan Data Contoh

## Peran

Kamu adalah Anggota 2. Pekerjaanmu menjelaskan mengapa skema berbentuk seperti
sekarang, lalu mengisi database dengan data yang memenuhi syarat penilaian dan
kebutuhan pengujian. Kamu juga menulis tangkapan layar query dasar untuk laporan.

Kamu tidak menentukan nama tabel. Nama itu sudah ditetapkan P1 dan P3. Tugasmu
membuktikan bahwa sebelas tabel memang hasil normalisasi, bukan kumpulan tabel
yang dibuat asal.

## Berkas Milik

| Berkas atau bagian | Isi |
|---|---|
| `sql/02_data.sql` | Data contoh seluruh tabel, minimal lima baris per tabel |
| Dokumentasi normalisasi | UNF, 1NF, 2NF, 3NF, BCNF, dependensi fungsional |
| Tangkapan layar query dasar | `SELECT`, `UPDATE`, `DELETE`, dan hasilnya |
| Bahan Bab II | Tabel perubahan tiap tahap normalisasi |

Berkas `sql/01_struktur.sql` milik P3. Kalau data tidak bisa masuk karena
constraint, laporkan ke P3 dengan pesan galat lengkap. Jangan menghapus
constraint atau mengubah urutan tabel sendiri.

## Konteks untuk AI

Proyek ini memakai MySQL 8.0, database `klinik_pratama`, sebelas tabel, dan data
contoh bertanggal Agustus sampai Oktober 2026. Sebagai P2 kamu menulis
`sql/02_data.sql` dan dokumentasi normalisasi dari 1NF sampai BCNF.

Aturan yang tidak boleh dilanggar:

- Jumlah baris: poli 5, dokter 6, jadwal_praktik 8, pasien 10, kunjungan 14,
  rekam_medis 10, tindakan 6, detail_tindakan 16, obat 8, detail_resep 12,
  pembayaran 10.
- Jadwal nomor 7 berkuota 4 dan harus terisi penuh.
- Obat nomor 8 berstok 5.
- Dua kunjungan berstatus `Batal`, dua berstatus `Menunggu`.
- Tiga pembayaran berstatus `Belum Lunas`.
- Urutan pengisian dari tabel induk ke anak.
- Jangan mengubah nama kolom atau tipe data.

Kalau AI mengusulkan angka baru, jalankan `reset-db.sh` dan `verify.sh` lebih
dulu. Angka yang membuat pemeriksaan gagal tidak dipakai, walaupun terlihat lebih
rapi.

## Milestone 1: Dokumentasi Normalisasi

### 1.1 Mulai dari satu formulir kunjungan

Sebelum normalisasi, data dibayangkan tersimpan pada satu formulir. Satu baris
memuat identitas pasien, dokter, poli, daftar tindakan, dan daftar obat.

| Tanggal | Pasien | Dokter | Isi |
|---|---|---|---|
| 2026-08-05 | Ahmad Subarjo | dr. Andi Pratama | Tindakan: Konsultasi (50.000), Tekanan Darah (15.000). Obat: Paracetamol 10 tablet. Poli Umum, R-01. |

Bentuk ini disebut unnormalized form karena ada kelompok data berulang di dalam
satu sel.

### 1.2 1NF

Syarat: setiap sel hanya berisi satu nilai. Kelompok tindakan dan obat dipecah
menjadi baris terpisah, sehingga satu kunjungan bisa muncul beberapa kali dengan
tindakan berbeda. Kunci pada tahap ini adalah gabungan nomor kunjungan dengan
nomor tindakan.

Tuliskan masalah yang masih tersisa: nama pasien dan tarif tindakan masih
berulang di banyak baris.

### 1.3 2NF

Syarat: tidak ada atribut bukan kunci yang bergantung pada sebagian kunci
gabungan. Nama pasien hanya bergantung pada nomor kunjungan. Tarif tindakan hanya
bergantung pada kode tindakan. Keduanya dipindahkan ke tabel sendiri.

Hasil tahap ini memisahkan pasien, tindakan, dan hubungan kunjungan dengan
tindakan.

### 1.4 3NF

Syarat: tidak ada atribut bukan kunci yang bergantung pada atribut bukan kunci
lain. Pelanggaran yang tersisa:

- `id_dokter` menentukan `nama_dokter`, `no_sip`, dan `email`; ketiganya pindah
  ke tabel dokter.
- `id_dokter` menentukan `id_poli`; poli dipisah ke tabel sendiri.
- `id_rekam` menentukan `keluhan` dan `diagnosis`; data pemeriksaan dipisah ke
  tabel rekam_medis.

Setelah tahap ini terbentuk sebelas tabel. Setiap tabel menyimpan satu jenis
fakta: tabel pasien hanya soal pasien, tabel obat hanya soal obat.

### 1.5 BCNF

Syarat: setiap determinan harus candidate key. Tulis tabel berikut dan periksa
satu per satu.

| Relasi | Dependensi fungsional | Determinan candidate key? |
|---|---|---|
| poli | id_poli → semua; nama_poli → semua | Ya, keduanya unik |
| dokter | id_dokter → semua; no_sip → semua; email → semua | Ya, ketiganya unik |
| jadwal_praktik | id_jadwal → semua; (id_dokter, tanggal, jam_mulai) → semua | Ya, kunci primer dan constraint unik |
| pasien | id_pasien → semua; nik → semua; email → semua | Ya |
| kunjungan | id_kunjungan → semua; (id_jadwal, no_antrean) → semua; (id_pasien, id_jadwal) → semua | Ya |
| rekam_medis | id_rekam → semua; id_kunjungan → semua | Ya, id_kunjungan unik |
| tindakan | id_tindakan → semua; nama_tindakan → semua | Ya |
| detail_tindakan | id_detail_tindakan → semua; (id_kunjungan, id_tindakan) → semua | Ya |
| obat | id_obat → semua; nama_obat → semua | Ya |
| detail_resep | id_detail_resep → semua; (id_rekam, id_obat) → semua | Ya |
| pembayaran | id_pembayaran → semua; id_kunjungan → semua | Ya, id_kunjungan unik |

Perhatikan peran constraint unik. Pada rekam_medis, `id_kunjungan` bukan kunci
primer, tetapi karena diberi constraint unik ia menjadi candidate key. Tanpa
constraint itu, satu kunjungan bisa punya dua rekam medis dan BCNF tidak lagi
terpenuhi.

### 1.6 Atribut turunan

Kolom `imt` bisa dianggap melanggar 3NF karena nilainya bisa dihitung dari berat
dan tinggi. Di proyek ini kolom tersebut tetap ada sebagai generated column:

```sql
imt DECIMAL(4,1) AS (
  ROUND(berat_badan / ((tinggi_badan/100) * (tinggi_badan/100)), 1)
) STORED
```

Karena nilainya selalu dihitung database, tidak ada kemungkinan angka tidak
konsisten seperti kalau diisi manual. Ini kompromi yang lazim: bentuk normal
dipertahankan dari sisi kebenaran data, sementara kemudahan pembacaan tetap
didapat.

## Milestone 2: Data Contoh

### 2.1 Isi dari induk ke anak

Urutan pengisian:

```text
poli → dokter → jadwal_praktik → pasien → kunjungan → rekam_medis
→ tindakan → detail_tindakan → obat → detail_resep → pembayaran
```

Tabel anak tidak bisa diisi sebelum induknya ada karena kunci tamu.

### 2.2 Penuhi jumlah baris

| Tabel | Jumlah |
|---|---|
| poli | 5 |
| dokter | 6 |
| jadwal_praktik | 8 |
| pasien | 10 |
| kunjungan | 14 |
| rekam_medis | 10 |
| tindakan | 6 |
| detail_tindakan | 16 |
| obat | 8 |
| detail_resep | 12 |
| pembayaran | 10 |

Angka ini dipakai `verify.sh` bagian A. Mengubahnya tanpa memperbarui
pemeriksaan dan tabel panduan akan membuat laporan tidak cocok.

### 2.3 Sediakan keadaan khusus

Data contoh bukan hanya memenuhi jumlah. Ia harus menyediakan keadaan yang
dibutuhkan pengujian:

- **Jadwal 7 penuh.** Kuota 4, terisi 4 kunjungan tidak Batal. Uji 4 memakai
  keadaan ini untuk membuktikan trigger kuota menolak pendaftaran kelima.
- **Obat 8 berstok 5.** Uji 6 memakai obat ini untuk membuktikan resep 99 botol
  ditolak.
- **Dua kunjungan batal.** Status `Batal` tidak dihitung sebagai pemakaian kuota.
- **Tiga pembayaran belum lunas.** Q5 memakai keadaan ini.
- **Tanggal Agustus sampai Oktober 2026.** Uji 7 membuat jadwal baru bertanggal
  Desember karena prosedur pendaftaran menolak jadwal yang sudah lewat.

### 2.4 Jangan merusak nilai hasil query

Sebagian angka pada laporan berasal langsung dari data contoh:

| Acuan | Nilai |
|---|---|
| Q4 jadwal 7 sisa kuota | 0 |
| Q7 poli di atas rata-rata | Poli Umum 274.000, Poli Gigi 213.000, Poli Penyakit Dalam 202.000 |
| Q8 obat terbanyak | Amlodipine 5mg, 60 tablet |
| Q10 peringkat pertama | dr. Andi Pratama, 6 kunjungan |
| View `v_kunjungan_lengkap` | 14 baris |
| `imt` rekam 1 | 24,9 (72 kg, 170 cm) |

Kalau salah satu angka berubah, perbarui panduan, `bukti/`, dan laporan pada
waktu yang sama. Jangan mengubah data hanya agar satu query terlihat lebih bagus.

## Milestone 3: Query Dasar dan Tangkapan Layar

Jalankan di Workbench atau klien SQL, lalu simpan tangkapan layar untuk Bab II:

```sql
-- seleksi dan pengurutan
SELECT id_pasien, nama_pasien, tanggal_lahir
  FROM pasien
 WHERE tanggal_lahir < '2005-01-01'
 ORDER BY tanggal_lahir;

-- perubahan satu baris dengan WHERE
UPDATE pasien SET no_telp = '081310000099' WHERE id_pasien = 4;

-- penghapusan yang tidak mengenai apa pun
DELETE FROM pasien WHERE id_pasien = 99;
```

Tunjukkan juga jumlah baris terpengaruh setelah `UPDATE`. Angka itu dipakai
sebagai pemeriksaan cepat: kalau jauh lebih besar dari perkiraan, batalkan.

### 3.1 Peringatan UPDATE dan DELETE

`UPDATE pasien SET no_telp = '0';` tanpa `WHERE` mengubah seluruh baris. Dua
kebiasaan mencegahnya:

1. Tulis `WHERE` lebih dulu, baru `SET` atau `FROM`.
2. Jalankan `SELECT` dengan `WHERE` yang sama untuk memastikan jumlah baris
   sebelum mengubah.

## Milestone 4: Verifikasi

1. Jalankan `bash tools/reset-db.sh`.
2. Jalankan `bash tools/verify.sh` dan pastikan `Lulus: 34   Gagal: 0`.
3. Periksa Q4, Q5, dan Q8 memakai `bukti/10-kueri.txt`.
4. Perbarui `bukti/00-reset.txt` dan `bukti/verify.txt` jika keluarannya berubah.
5. Serahkan berkas ke reviewer P5. Reviewer menjalankan ulang, bukan membaca
   saja.

## Checklist

- [ ] Dokumentasi UNF, 1NF, 2NF, 3NF, BCNF lengkap.
- [ ] Tabel dependensi fungsional memuat sebelas relasi.
- [ ] Alasan `imt` sebagai generated column dijelaskan.
- [ ] `sql/02_data.sql` mengisi induk ke anak.
- [ ] Jumlah baris sesuai tabel di PRD.
- [ ] Jadwal 7 penuh, obat 8 berstok 5, dua batal, tiga belum lunas.
- [ ] `verify.sh` lulus seluruhnya.
- [ ] Tangkapan layar query dasar tersedia untuk Bab II.
- [ ] Tidak ada perubahan pada `sql/01_struktur.sql`.

## Kesalahan yang Sering Terjadi

1. Mengisi tabel anak sebelum induk, sehingga kunci tamu gagal.
2. Menjalankan pengujian berulang tanpa `reset-db.sh`, sehingga jumlah baris
   bertambah.
3. Mengubah angka data agar satu query terlihat bagus, lalu lupa memperbarui
   tabel hasil di panduan.
4. Menghapus constraint karena data tidak bisa masuk. Yang salah adalah datanya,
   bukan constraint-nya.
5. Menyimpan `imt` manual, lalu nilainya tidak cocok dengan hitungan database.

## Prompt Siap Tempel

```text
Saya Anggota 2. Saya sedang menulis sql/02_data.sql dan dokumentasi normalisasi.
Berikut aturan umum proyek, skema sql/01_struktur.sql, dan potongan berkas saya.

Periksa dua hal: (1) apakah urutan INSERT sudah dari induk ke anak dan setiap
kunci tamu menunjuk baris yang benar, (2) apakah data memenuhi keadaan khusus
jadwal 7 penuh, obat 8 berstok 5, dua kunjungan Batal, dan tiga pembayaran
Belum Lunas. Jangan mengubah nama kolom atau constraint.
```

## Definition of Done

Fase P2 selesai jika dokumentasi normalisasi menjelaskan perpindahan setiap
kelompok data, `sql/02_data.sql` memenuhi seluruh jumlah dan keadaan khusus,
`verify.sh` lulus, dan tangkapan layar query dasar siap dipakai di Bab II.
