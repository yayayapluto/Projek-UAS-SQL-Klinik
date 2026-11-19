# Klinik Pratama: Paket Panduan Proyek Akhir

Paket ini memandu satu tim berisi lima orang membangun basis data **Sistem
Informasi Klinik Pratama** di MySQL 8.0.16 atau lebih baru. Pekerjaan mencakup
seluruh siklus perancangan: studi kasus, kamus data, diagram relasi entitas,
transformasi ke tabel, normalisasi sampai BCNF, SQL dasar dan lanjutan, transaksi,
hak akses, indeks, pengujian, laporan, dan video demo.

Tidak ada aplikasi Java, PHP, atau antarmuka grafis. Semua pekerjaan dijalankan
lewat klien SQL, dan semua bukti berupa teks keluaran perintah. Aturan ini dipilih
supaya penilaian terfokus pada perancangan dan SQL, bukan pada kode program.

Paket ini memuat dokumen dan kerangka SQL. Folder `sql/` berisi scaffold berkomentar
tanpa pernyataan aktif. Berkas kerja lengkap (`tools/`, `bukti/`, `laporan/`,
`docs/ai/`, dan solusi SQL) berada di repositori kerja kelompok dan dipakai
bersama dokumen di sini.

## Daftar Isi

1. [PRD](docs/PRD.md): kebutuhan produk, skema sebelas tabel, aturan bisnis,
   kontrak objek basis data, kriteria penerimaan.
2. [Project Overview](docs/PROJECT-OVERVIEW.md): gambaran singkat, struktur repo
   target, peta berkas, alur pemuatan data.
3. [Pembagian Tugas](docs/PEMBAGIAN-TUGAS.md): lima peran, fase, tag, jadwal,
   definition of done.
4. [Panduan 0: Git dan Lingkungan Kerja](docs/panduan-0-git-dan-lingkungan.md):
   menyiapkan Docker, MySQL, Workbench, MiKTeX, repo, dan build pertama, ditambah
   alur Git per anggota.
5. [Panduan P1: Studi Kasus, Kamus Data, dan ERD](docs/panduan-P1-studi-kasus-erd.md)
6. [Panduan P2: Normalisasi dan Data Contoh](docs/panduan-P2-normalisasi-data.md)
7. [Panduan P3: Struktur Tabel dan Transformasi](docs/panduan-P3-struktur-transformasi.md)
8. [Panduan P4: View, Trigger, Prosedur, Keamanan, Indeks](docs/panduan-P4-view-trigger-prosedur.md)
9. [Panduan P5: Pengujian, Bukti, dan Rilis](docs/panduan-P5-pengujian-rilis.md)
10. [Panduan GitHub Bersama](PANDUAN-GITHUB.md): repo publik, undangan anggota,
    branch, pull request, dan push.

Urutannya disengaja. Baca PRD lebih dulu karena di sana semua nama tabel, nama
kolom, angka, dan perilaku objek ditetapkan. Sesudah itu panduan peran dibaca
sesuai tanggung jawab masing-masing, sedangkan Panduan 0 dipakai bersama saat
menyiapkan mesin kerja.

## Prasyarat

Pasang satu kali di komputer masing-masing.

| Alat | Kegunaan | Perintah pasang (Windows) |
|---|---|---|
| Git | Mengambil dan mengirim perubahan | `winget install --id Git.Git -e` |
| Docker Desktop | Menjalankan MySQL 8.0 tanpa memasang server | `winget install --id Docker.DockerDesktop -e` |
| MySQL Workbench | Klien SQL untuk memeriksa tabel dan menjalankan query | `winget install --id Oracle.MySQLWorkbench -e` |
| draw.io | Menggambar ulang diagram bila perlu | `winget install --id JGraph.Draw -e` |
| MiKTeX (hanya Anggota 5) | Membangun PDF panduan dan laporan | `winget install --id MiKTeX.MiKTeX -e` |

Setelah MiKTeX terpasang, aktifkan pemasangan paket otomatis supaya build tidak
berhenti menunggu dialog:

```bash
initexmf --set-config-value=[MPM]AutoInstall=1
```

Jika MiKTeX tidak bisa dipasang, PDF tetap bisa dibangun dengan mengunggah folder
`panduan/` ke Overleaf dan memakai `utama.tex` sebagai dokumen utama.

Periksa Git dan Docker sebelum mulai:

```bash
git --version
docker --version
```

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

`reset-db.sh` memuat `sql/01_struktur.sql` sampai `sql/06_indeks.sql` dari
database kosong. `verify.sh` menjalankan 34 pemeriksaan atas isi dan perilaku
database. Keluaran yang benar berakhir dengan:

```text
Lulus: 34   Gagal: 0
SEMUA PEMERIKSAAN LULUS
```

Anggota baru wajib melihat seluruh pemeriksaan lulus sebelum mulai bekerja.
Langkah lengkap dari nol ada di [Panduan 0](docs/panduan-0-git-dan-lingkungan.md).

Untuk membangun kedua PDF:

```bash
bash tools/build.sh
```

Hasilnya `panduan/utama.pdf` dan `laporan/template-laporan.pdf`.

## Isi Repositori Kerja

| Lokasi | Isi |
|---|---|
| `sql/01_struktur.sql` | Membuat database dan sebelas tabel |
| `sql/02_data.sql` | Data contoh, setiap tabel minimal lima baris |
| `sql/03_view_trigger.sql` | Dua view dan empat trigger |
| `sql/04_prosedur.sql` | Dua stored procedure |
| `sql/05_keamanan.sql` | Tiga pengguna dan hak aksesnya |
| `sql/06_indeks.sql` | Dua indeks beserta EXPLAIN sebelum dan sesudah |
| `sql/07_pengujian.sql` | Sepuluh skenario pengujian |
| `tools/reset-db.sh` | Mengembalikan database dari nol lalu memuat 01 sampai 06 |
| `tools/verify.sh` | Memeriksa isi dan perilaku database, 34 pemeriksaan |
| `tools/demo-isolasi.sh` | Membuktikan tingkat isolasi dan deadlock |
| `tools/build.sh` | Membangun PDF panduan dan laporan |
| `panduan/` | Sumber LaTeX panduan (14 bab) |
| `laporan/template-laporan.tex` | Kerangka laporan Bab I sampai III |
| `bukti/` | Keluaran nyata setiap skrip, dipakai sebagai bukti di laporan |
| `docs/ai/` | Paket konteks untuk sesi AI setiap anggota |

## Peta Kerja per Anggota

| Anggota | Berkas milik | Panduan | Minggu target |
|---|---|---|---|
| Anggota 1 | Studi kasus, kamus data, ERD, Bab I dan III laporan | [P1](docs/panduan-P1-studi-kasus-erd.md) | Minggu 1 dan 4 |
| Anggota 2 | `sql/02_data.sql`, dokumentasi normalisasi, tangkapan layar query dasar | [P2](docs/panduan-P2-normalisasi-data.md) | Minggu 2 |
| Anggota 3 | `sql/01_struktur.sql`, transformasi, aljabar relasional | [P3](docs/panduan-P3-struktur-transformasi.md) | Minggu 2 |
| Anggota 4 | `sql/03` sampai `sql/06` | [P4](docs/panduan-P4-view-trigger-prosedur.md) | Minggu 3 |
| Anggota 5 | `sql/07_pengujian.sql`, demo isolasi, video, build PDF, daftar periksa | [P5](docs/panduan-P5-pengujian-rilis.md) | Minggu 3 dan 4 |

Review silang: Anggota 3 memeriksa hasil Anggota 4, Anggota 4 memeriksa hasil
Anggota 3, Anggota 5 memeriksa hasil Anggota 1 dan Anggota 2, Anggota 1 memeriksa
daftar periksa buatan Anggota 5. Rincian alurnya ada di
[Pembagian Tugas](docs/PEMBAGIAN-TUGAS.md).

## Alur Kerja Harian

1. `git pull` untuk mengambil perubahan terbaru.
2. Kerjakan hanya berkas milik sendiri. Berkas anggota lain tidak disunting tanpa
   kesepakatan di grup.
3. Uji di komputer sendiri: `bash tools/reset-db.sh` lalu `bash tools/verify.sh`.
   Jangan mengirim perubahan yang membuat pemeriksaan gagal.
4. Simpan dan kirim:

   ```bash
   git add sql/02_data.sql
   git commit -m "feat: tambah data contoh poli dan dokter"
   git push
   ```

5. Minta review silang lewat grup, sebutkan berkas dan hasil `verify.sh` terakhir.
6. Setelah disetujui, perbarui `bukti/` bila keluarannya berubah.

Alur branch dan tag yang lebih rinci ada di
[Panduan 0](docs/panduan-0-git-dan-lingkungan.md).

## Cara Bertanya ke AI Tanpa Kehilangan Konteks

Asisten AI tidak membaca isi percakapan kelompok dan tidak melihat repositori ini.
Setiap sesi dimulai dengan melampirkan tiga hal, berurutan:

1. Isi `docs/ai/00-aturan-umum.md`, yaitu skema resmi, delapan aturan bisnis, dan
   larangan.
2. Isi `docs/ai/anggota-N.md` sesuai peran.
3. Berkas nyata yang sedang dikerjakan, misalnya `sql/01_struktur.sql`, ditambah
   bab panduan yang relevan atau halaman PDF-nya.

Perintah menyalin konteks ke papan klip (Windows, Git Bash):

```bash
cat docs/ai/00-aturan-umum.md docs/ai/anggota-3.md sql/01_struktur.sql | clip
```

Kalau memakai PowerShell:

```powershell
Get-Content docs/ai/00-aturan-umum.md, docs/ai/anggota-3.md, sql/01_struktur.sql | Set-Clipboard
```

Setiap bab panduan diakhiri kotak **Konteks untuk AI** yang menyebut berkas mana
yang harus dilampirkan untuk bab itu. Kotak itulah daftar periksa tercepat.

## Aturan yang Tidak Boleh Dilanggar

Berlaku untuk manusia maupun asisten AI.

1. Nama database `klinik_pratama` dan **sebelas** tabel tidak diubah.
2. Nama kolom, tipe data, dan isi `ENUM` mengikuti `sql/01_struktur.sql`.
3. Nama trigger, prosedur, pengguna, dan indeks tidak diganti.
4. Angka pada `sql/02_data.sql` tidak diubah tanpa memperbarui tabel hasil di
   panduan dan `bukti/`.
5. Setiap perubahan skema harus disertai `bash tools/reset-db.sh` dan
   `bash tools/verify.sh` yang seluruhnya lulus.
6. AI hanya boleh menulis atau memperbaiki berkas milik anggota yang bertanya.
7. Jika permintaan bertentangan dengan `docs/ai/00-aturan-umum.md`, AI wajib
   menolak dan menyebut pertentangannya.

## Perintah yang Sering Dipakai

```bash
# muat ulang database dari nol
bash tools/reset-db.sh

# periksa isi dan perilaku database
bash tools/verify.sh

# jalankan sepuluh pengujian (skenario galat sengaja gagal)
docker exec -i kbd-mysql mysql -uroot -pkbd --force < sql/07_pengujian.sql

# masuk ke klien SQL interaktif
docker exec -it kbd-mysql mysql -uroot -pkbd klinik_pratama

# buktikan tingkat isolasi dan deadlock
bash tools/demo-isolasi.sh

# bangun kedua PDF
bash tools/build.sh
```

## Kalau Ada Masalah

| Gejala | Penyebab dan penanganan |
|---|---|
| `Cannot connect to the Docker daemon` | Docker Desktop belum menyala. Buka aplikasinya, tunggu status *running*. |
| `ERROR 1045 Access denied` | Kata sandi berbeda. Container ini memakai `-pkbd`, bukan kata sandi XAMPP. |
| `ERROR 2003 Can't connect to MySQL server` | Container belum siap. Tunggu beberapa detik, lalu ulangi `reset-db.sh`. |
| `ERROR 1046 No database selected` | Tambahkan `klinik_pratama` pada perintah, atau jalankan lewat skrip yang sudah memuat `USE`. |
| `pdflatex tidak ditemukan` | MiKTeX belum terpasang atau belum masuk PATH. Lihat bagian Prasyarat. |
| `verify.sh` gagal pada bagian E | Data contoh berubah. Jalankan `reset-db.sh` agar kembali ke angka semestinya. |
| Port 3307 sudah dipakai | Hentikan container lain (`docker ps`), atau ubah pemetaan port pada perintah `docker run`. |

## Berkas yang Tidak Perlu Dikirim

`*.aux`, `*.log`, `*.toc`, dan berkas sementara LaTeX lain sudah masuk
`.gitignore`. PDF hasil build tetap dikirim supaya dosen bisa membaca tanpa
memasang LaTeX.
