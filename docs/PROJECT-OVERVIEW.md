# Gambaran Proyek Klinik Pratama

## Ringkasan

Sistem Informasi Klinik Pratama adalah proyek basis data untuk klinik rawat jalan
berskala kecil. Basis data menangani pendaftaran pasien, penjadwalan sesi praktik,
pencatatan kunjungan dan rekam medis, tindakan, resep obat beserta stok, dan
pembayaran. Seluruh pekerjaan dilakukan di MySQL 8.0.16 atau lebih baru lewat
klien SQL, tanpa aplikasi atau antarmuka grafis.

Proyek ini disusun sebagai Final Project mata kuliah Konsep Basis Data. Sebelas
tabel memetakan materi mingguan, mulai dari konsep DBMS dan model relasional
sampai normalisasi, SQL, transaksi, keamanan, indeks, dan perbandingan NoSQL.
Rincian angka, nama kolom, dan kriteria penerimaan ada di [PRD](PRD.md).

## Fitur Utama

- **Sebelas tabel ternormalisasi** sampai BCNF, lengkap dengan kunci primer,
  kunci tamu, constraint unik, `CHECK`, `ENUM`, dan `DEFAULT`.
- **Pendaftaran pasien** lewat prosedur `sp_daftar_kunjungan`, yang menolak
  jadwal lewat dan memberi nomor antrean berikutnya secara otomatis.
- **Penjagaan aturan bisnis oleh database**: kuota jadwal, bentrok jadwal dokter,
  stok obat, satu pendaftaran per sesi, dan satu pembayaran per kunjungan.
- **Pembayaran terhitung** lewat `sp_bayar_kunjungan`, yang menjumlahkan biaya
  tindakan dan harga obat di dalam satu transaksi.
- **Dua view pelaporan**: riwayat kunjungan lengkap dan pendapatan poli per bulan.
- **Sepuluh query** dari seleksi sederhana sampai `GROUP BY`, subquery, `CASE`,
  dan fungsi jendela `RANK()`.
- **Tiga pengguna database** dengan hak berbeda dan bukti penolakan `ERROR 1142`.
- **Dua indeks** dengan bukti `EXPLAIN` sebelum dan sesudah pembuatan.
- **Pengujian bernomor**: sepuluh skenario di `sql/07_pengujian.sql` dan 34
  pemeriksaan otomatis di `tools/verify.sh`.
- **Bukti teks** untuk setiap skrip di `bukti/`, dipakai langsung di laporan.

## Prasyarat

| Kebutuhan | Keterangan |
|---|---|
| Git | Mengambil dan mengirim perubahan. Cek dengan `git --version`. |
| Docker Desktop | Menjalankan MySQL 8.0 tanpa memasang server. Cek dengan `docker --version`. |
| MySQL Workbench | Klien SQL untuk memeriksa tabel dan menjalankan query. |
| Bash | Git Bash atau WSL untuk menjalankan skrip `tools/*.sh`. |
| MiKTeX | Hanya untuk Anggota 5 yang membangun PDF. Bisa diganti Overleaf. |

Tidak ada dependensi bahasa pemrograman. Yang dijalankan hanya klien `mysql` di
dalam container, `pdflatex` untuk PDF, dan skrip shell untuk pemeriksaan.

## Mulai Cepat

```bash
git clone https://github.com/<akun>/klinik-kbd.git
cd klinik-kbd

docker run -d --name kbd-mysql -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=kbd \
  -e MYSQL_DATABASE=klinik_pratama \
  mysql:8.0 --default-authentication-plugin=mysql_native_password

bash tools/reset-db.sh
bash tools/verify.sh
```

`reset-db.sh` membuat ulang `klinik_pratama` lalu memuat `01_struktur.sql`
sampai `06_indeks.sql`. `verify.sh` memeriksa struktur, isi, relasi, aturan
bisnis, indeks, hak akses, dan transaksi. Keluaran akhir yang benar:

```text
Lulus: 34   Gagal: 0
SEMUA PEMERIKSAAN LULUS
```

Langkah pemasangan alat, pembuatan container, dan alur Git per anggota ada di
[Panduan 0](panduan-0-git-dan-lingkungan.md).

## Struktur Repo

Bentuk repositori kerja setelah seluruh berkas selesai. Berkas SQL milik anggota
berbeda, sedangkan `tools/` dan `bukti/` dirawat bersama.

```text
.
├── README.md
├── .gitignore
├── Guidebook KBD UAS.pdf                  (materi dan ketentuan tugas)
├── sql/
│   ├── 01_struktur.sql                    (P3)
│   ├── 02_data.sql                        (P2)
│   ├── 03_view_trigger.sql                (P4)
│   ├── 04_prosedur.sql                    (P4)
│   ├── 05_keamanan.sql                    (P4)
│   ├── 06_indeks.sql                      (P4)
│   └── 07_pengujian.sql                   (P5)
├── tools/
│   ├── reset-db.sh                        (P5, dipakai semua)
│   ├── verify.sh                          (P5)
│   ├── demo-isolasi.sh                    (P5)
│   └── build.sh                           (P5)
├── bukti/
│   ├── 00-reset.txt
│   ├── 05_keamanan.txt
│   ├── 06_indeks.txt
│   ├── 07_pengujian.txt
│   ├── 10-kueri.txt
│   ├── isolasi.txt
│   ├── kueri-panduan.sql
│   └── verify.txt
├── panduan/
│   ├── utama.tex
│   ├── bab/01-gambaran.tex ... 14-daftar-periksa.tex
│   ├── gambar/erd.tex
│   └── utama.pdf
├── laporan/
│   ├── template-laporan.tex
│   └── template-laporan.pdf
└── docs/
    └── ai/
        ├── 00-aturan-umum.md
        └── anggota-1.md ... anggota-5.md
```

## Peta Berkas dan Pemilik

| Berkas atau bagian | Pemilik | Isi |
|---|---|---|
| Studi kasus, kamus data, ERD, Bab I dan III laporan | Anggota 1 | Bahan konseptual dan dokumen akhir |
| `sql/02_data.sql`, dokumentasi normalisasi | Anggota 2 | Data contoh dan bukti 1NF sampai BCNF |
| `sql/01_struktur.sql`, transformasi, aljabar relasional | Anggota 3 | Skema fisik dan penjelasan transformasi |
| `sql/03_view_trigger.sql`, `04_prosedur.sql`, `05_keamanan.sql`, `06_indeks.sql` | Anggota 4 | Objek basis data dan pengaturan akses |
| `sql/07_pengujian.sql`, `tools/`, `bukti/`, video, PDF | Anggota 5 | Pengujian, bukti, dan rilis |

Berkas bersama yang tidak dimiliki satu orang: `README.md`, `docs/ai/`, dan
`.gitignore`. Perubahannya disepakati di grup sebelum dikirim.

## Alur Runtime

Tidak ada program yang berjalan terus. Yang ada adalah urutan pemuatan skrip dan
urutan pemeriksaan.

```text
docker run  →  container kbd-mysql (MySQL 8.0, port host 3307)
                     │
                     ▼
             tools/reset-db.sh
                     │
   ┌─────────────────┼──────────────────┐
   ▼                 ▼                  ▼
01_struktur  02_data  03_view_trigger  04_prosedur
                     │
                     ▼
             05_keamanan  06_indeks
                     │
                     ▼
             tools/verify.sh  ──►  bukti/verify.txt
                     │
                     ▼
             sql/07_pengujian.sql ──►  bukti/07_pengujian.txt
```

`07_pengujian.sql` dijalankan terpisah karena berisi pernyataan yang sengaja
gagal. Klien `mysql` harus memakai opsi `--force` supaya tetap lanjut ke
pernyataan berikutnya. Blok terakhir skrip menghapus data uji dan mengembalikan
stok, sehingga pengujian bisa dijalankan berulang.

## Alur Bukti

Setiap hasil yang diklaim harus punya keluaran yang bisa ditunjukkan. Alurnya:

```text
perintah dijalankan
      │
      ▼
keluaran disimpan di bukti/<nama>.txt
      │
      ├──► dikutip di laporan Bab II
      ├──► dicocokkan dengan tabel hasil di panduan
      └──► dipakai verify.sh sebagai pembanding
```

Karena itu `bukti/` diperbarui setiap kali skrip berubah. Tanpa pembaruan,
laporan dan database bisa menampilkan angka berbeda.

## Yang Dinilai

Penilaian mengikuti syarat pada panduan, bukan jumlah baris kode. Ringkasnya:

| Syarat | Wujud di proyek |
|---|---|
| Minimal 5 tabel | 11 tabel |
| Setiap tabel minimal 5 baris | data contoh pada `02_data.sql` |
| Relasi 1:N, M:N, 1:0..1 | poli-dokter, detail_tindakan, rekam_medis |
| Kunci primer dan kunci tamu | seluruh tabel |
| Constraint | UNIQUE, CHECK, NOT NULL, ENUM, DEFAULT |
| View | `v_kunjungan_lengkap`, `v_pendapatan_poli` |
| Trigger | empat trigger penjaga aturan bisnis |
| Stored procedure | pendaftaran dan pembayaran |
| Transaksi | `START TRANSACTION`, `COMMIT`, `ROLLBACK` |
| Hak akses | tiga pengguna dengan hak berbeda |
| Indeks dan analisis | dua indeks dengan `EXPLAIN` |
| Pengujian skenario galat | sepuluh uji bernomor |
| Normalisasi | dokumentasi 1NF sampai BCNF |
| Perbandingan NoSQL | pemetaan dokumen JSON dan alasan memilih relasional |

Kriteria penerimaan yang lebih tegas ada di [PRD §11](PRD.md#11-kriteria-penerimaan).
