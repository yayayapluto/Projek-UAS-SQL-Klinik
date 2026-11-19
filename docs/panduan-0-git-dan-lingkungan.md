# Panduan 0: Git dan Lingkungan Kerja

Panduan ini dipakai bersama oleh semua anggota. Isinya menyiapkan alat, membuat
container MySQL, memuat database dari nol, membangun PDF, dan menjalankan alur
Git per anggota. Kerjakan bagian ini sampai `verify.sh` lulus sebelum menyentuh
berkas milik sendiri.

## 1. Pasang alat

Windows, PowerShell atau Git Bash:

```powershell
winget install --id Git.Git -e
winget install --id Docker.DockerDesktop -e
winget install --id Oracle.MySQLWorkbench -e
winget install --id JGraph.Draw -e
winget install --id MiKTeX.MiKTeX -e
```

MiKTeX hanya wajib untuk Anggota 5. Anggota lain boleh melewatinya dan memakai
PDF hasil build yang sudah ada.

Setelah MiKTeX terpasang, aktifkan pemasangan paket otomatis supaya kompilasi
tidak berhenti menunggu dialog:

```bash
initexmf --set-config-value=[MPM]AutoInstall=1
```

Periksa semuanya:

```bash
git --version
docker --version
```

Docker Desktop harus berstatus *running* sebelum perintah `docker` dipakai.
Buka aplikasinya dari menu Start dan tunggu sampai statusnya berubah.

## 2. Siapkan Git

Isi nama dan email sekali saja:

```bash
git config --global user.name "Nama Anda"
git config --global user.email "email@contoh.ac.id"
```

Di Windows, setel akhir baris supaya skrip `.sh` tetap memakai LF dan tidak
gagal di Git Bash:

```bash
git config --global core.autocrlf input
```

## 3. Clone repositori

```bash
git clone https://github.com/<akun>/klinik-kbd.git
cd klinik-kbd
```

Kalau repositori belum ada, Anggota 5 membuatnya dan mengundang empat anggota
lain sebagai collaborator. Nama repositori bebas, asalkan konsisten di laporan.

## 4. Buat container MySQL

Satu container dipakai untuk seluruh proyek. Jalankan sekali:

```bash
docker run -d --name kbd-mysql -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=kbd \
  -e MYSQL_DATABASE=klinik_pratama \
  mysql:8.0 --default-authentication-plugin=mysql_native_password
```

Port host 3307 dipilih supaya tidak bertabrakan dengan MySQL lokal atau XAMPP
yang biasanya memakai 3306. Dari dalam container, MySQL tetap di port 3306.

Periksa container berjalan:

```bash
docker ps --filter name=kbd-mysql
```

Kalau container sudah ada tetapi berhenti:

```bash
docker start kbd-mysql
```

Kalau ingin menghapus dan membuat ulang:

```bash
docker rm -f kbd-mysql
```

Perintah `docker rm -f` menghapus seluruh data di dalam container. Database
bisa dibentuk ulang dari skrip, jadi kehilangan data di sini tidak masalah.

## 5. Muat database dari nol

```bash
bash tools/reset-db.sh
```

Keluaran yang benar berakhir seperti ini:

```text
== 3. Periksa jumlah tabel ==
   tabel terdaftar: 11
Database siap dipakai.
```

Skrip menjalankan `01_struktur.sql` sampai `06_indeks.sql`. Jika ada galat,
skrip berhenti dan menampilkan pesannya. Baca nama berkas dan nomor barisnya
sebelum mengubah apa pun.

## 6. Jalankan pemeriksaan

```bash
bash tools/verify.sh
```

Keluaran yang benar:

```text
==============================================
Lulus: 34   Gagal: 0
SEMUA PEMERIKSAAN LULUS
```

Anggota baru wajib melihat seluruh pemeriksaan lulus sebelum mulai bekerja.
Kalau ada yang gagal, jangan mengirim perubahan. Jalankan `reset-db.sh` lebih
dulu untuk memastikan database tidak membawa sisa percobaan.

`verify.sh` memeriksa tujuh bagian:

| Bagian | Isi |
|---|---|
| A | Jumlah tabel, jumlah view, minimal lima baris per tabel |
| B | Tidak ada kunci tamu yatim |
| C | Aturan bisnis tercermin di data contoh |
| D | Indeks dipakai optimizer pada `EXPLAIN` |
| E | Enam masukan salah ditolak dengan pesan yang benar |
| F | Hak akses tiga pengguna dan penolakan 1142 |
| G | Transaksi berhasil seluruhnya atau tidak sama sekali |

## 7. Jalankan pengujian manual

```bash
docker exec -i kbd-mysql mysql -uroot -pkbd --force < sql/07_pengujian.sql
```

Opsi `--force` wajib. Tanpa opsi itu, klien `mysql` berhenti pada galat pertama,
padahal Uji 1 sampai 6 dan Uji 10 memang harus menghasilkan galat.

Untuk masuk ke klien interaktif:

```bash
docker exec -it kbd-mysql mysql -uroot -pkbd klinik_pratama
```

Keluar dengan `exit`.

## 8. Bangun PDF

```bash
bash tools/build.sh
```

Perintah ini mengompilasi `panduan/utama.tex` dan
`laporan/template-laporan.tex` dua kali. Lintasan pertama mengisi daftar isi dan
rujukan, lintasan kedua memakainya. Hasilnya:

```text
panduan/utama.pdf
laporan/template-laporan.pdf
```

Kalau `pdflatex` tidak ditemukan, MiKTeX belum masuk PATH. `build.sh` sudah
mencoba beberapa lokasi pemasangan MiKTeX di Windows. Kalau tetap gagal, unggah
folder `panduan/` dan `laporan/` ke Overleaf dan jadikan `utama.tex` serta
`template-laporan.tex` sebagai dokumen utama.

## 9. Alur Git per Anggota

Repositori memakai tiga jenis branch:

| Branch | Isi | Siapa yang menulis |
|---|---|---|
| `main` | Versi yang dikumpulkan | hanya hasil merge `dev` saat rilis |
| `dev` | Integrasi seluruh pekerjaan | semua anggota lewat PR |
| `feat/<kode>-<singkat>` | Satu berkas atau satu peran | pemilik berkas |

### 9.1 Mulai bekerja

```bash
git checkout dev
git pull origin dev
git checkout -b feat/p3-struktur
```

Nama branch menyesuaikan peran, misalnya:

| Branch | Pemilik | Berkas |
|---|---|---|
| `feat/p1-erd` | Anggota 1 | ERD, kamus data, Bab I dan III |
| `feat/p2-data` | Anggota 2 | `sql/02_data.sql`, dokumentasi normalisasi |
| `feat/p3-struktur` | Anggota 3 | `sql/01_struktur.sql`, transformasi |
| `feat/p4-objek` | Anggota 4 | `sql/03` sampai `sql/06` |
| `feat/p5-uji` | Anggota 5 | `sql/07`, `tools/`, `bukti/` |

Satu branch boleh memuat beberapa commit, tetapi hanya menyentuh berkas milik
branch itu.

### 9.2 Simpan perubahan

```bash
git status
git add sql/01_struktur.sql
git commit -m "feat: tambah tabel rekam_medis dan generated column imt"
```

Awalan pesan commit:

| Awalan | Dipakai untuk |
|---|---|
| `feat:` | objek atau data baru |
| `fix:` | memperbaiki galat atau data yang salah |
| `docs:` | panduan, laporan, README |
| `test:` | skrip pengujian dan `verify.sh` |
| `chore:` | `.gitignore`, alat bantu, perapian |

Sebelum commit, jalankan ulang dua perintah bukti:

```bash
bash tools/reset-db.sh
bash tools/verify.sh
```

Jangan commit `*.aux`, `*.log`, `*.toc`, atau isi folder `build-*`. Berkas itu
sudah masuk `.gitignore`.

### 9.3 Kirim dan minta review

```bash
git push -u origin feat/p3-struktur
```

Buka pull request ke `dev`, bukan ke `main`. Isi PR minimal memuat:

- berkas yang berubah dan alasannya;
- perintah yang dijalankan;
- potongan keluaran `verify.sh`, misalnya `Lulus: 34   Gagal: 0`;
- nama reviewer yang ditetapkan pada Pembagian Tugas.

Review silang yang berlaku:

| Pemeriksa | Memeriksa |
|---|---|
| P3 | hasil P4, terutama nama tabel dan kolom pada view serta trigger |
| P4 | hasil P3, terutama kunci tamu dan constraint |
| P5 | hasil P1 dan P2, apakah ERD sesuai skema dan data memenuhi aturan |
| P1 | daftar periksa P5, setiap butir harus punya bukti |

Review dilakukan dengan menjalankan `reset-db.sh` dan `verify.sh` pada salinan
hasil pekerjaan, bukan dengan membaca kode saja.

### 9.4 Gabungkan dan tag

Setelah disetujui, pengirim PR atau P5 menggabungkan ke `dev`. Tag dipasang pada
`dev` setelah fase selesai:

```bash
git checkout dev
git pull origin dev
git tag -a skema-v1 -m "Skema sebelas tabel dibekukan"
git push origin skema-v1
```

Urutan tag ada di [Pembagian Tugas](PEMBAGIAN-TUGAS.md#fase-dan-tag). Tag tidak
dipasang pada branch fitur.

### 9.5 Aturan yang mencegah masalah

1. Jangan `git push --force` ke `dev` atau `main`.
2. Jangan menyunting berkas milik anggota lain. Usulkan lewat grup.
3. Jangan menggabungkan PR sendiri tanpa satu review.
4. Jangan mengubah `sql/02_data.sql` hanya untuk membuat satu query terlihat
   bagus; angka itu dipakai di laporan dan `bukti/`.
5. Jika muncul konflik, selesaikan hanya pada berkas milik sendiri. Konflik pada
   berkas bersama diselesaikan oleh pemilik terakhir yang menyetujui perubahan.
6. Jangan commit hasil `reset-db.sh` berupa berkas sementara. Yang dikirim hanya
   `bukti/*.txt` bila memang diperbarui.
7. Sebelum meninggalkan komputer, pastikan pekerjaan tersimpan di commit, bukan
   hanya di working tree.

## 10. Alur Harian

```text
pagi        git pull origin dev
kerja       sunting berkas sendiri
uji         reset-db.sh, verify.sh
simpan      commit dengan awalan yang benar
kirim       push branch, buka PR ke dev
review      reviewer menjalankan verify.sh pada salinan
gabung      merge ke dev
bukti       perbarui bukti/ bila keluaran berubah
rilis       tag, build PDF, rekam video
```

Perintah memperbarui bukti setelah perubahan yang memengaruhi keluaran:

```bash
bash tools/reset-db.sh       > bukti/00-reset.txt
bash tools/verify.sh         > bukti/verify.txt
bash tools/demo-isolasi.sh   > bukti/isolasi.txt
```

Untuk query panduan:

```bash
docker exec -i kbd-mysql mysql -uroot -pkbd klinik_pratama \
  < bukti/kueri-panduan.sql > bukti/10-kueri.txt
```

## 11. Masalah yang Sering Muncul

| Gejala | Penyebab dan penanganan |
|---|---|
| `Cannot connect to the Docker daemon` | Docker Desktop belum menyala. Buka aplikasinya, tunggu status *running*. |
| `docker: Error response from daemon: Conflict` | Nama `kbd-mysql` sudah dipakai. Jalankan `docker start kbd-mysql`, atau `docker rm -f kbd-mysql` lalu buat ulang. |
| `ERROR 1045 Access denied` | Kata sandi berbeda. Container ini memakai `-pkbd`. |
| `ERROR 2003 Can't connect to MySQL server` | Container belum siap. Tunggu beberapa detik, lalu ulangi. |
| `ERROR 1046 No database selected` | Tambahkan `klinik_pratama` pada perintah atau jalankan skrip yang memuat `USE`. |
| `ERROR 1215 Cannot add foreign key constraint` | Tabel induk belum dibuat atau tipe kolom tidak sama. Periksa urutan pada `01_struktur.sql`. |
| `ERROR 1064 You have an error in your SQL syntax` | Biasanya karena `DELIMITER` dijalankan di luar klien `mysql`, atau tanda kutip tidak berpasangan. |
| `ERROR 3819 Check constraint is violated` | Data melanggar `CHECK`. Ini perilaku yang diinginkan pada Uji 3. |
| `verify.sh` gagal bagian E | Data contoh berubah. Jalankan `reset-db.sh`. |
| `pdflatex tidak ditemukan` | MiKTeX belum terpasang atau belum masuk PATH. Lihat bagian 8. |
| PDF kecil di bawah 100 KB | Kompilasi berhenti di tengah. Baca `panduan/build-2.log` atau `laporan/build-2.log`. |
| Port 3307 sudah dipakai | Hentikan container lain (`docker ps`), atau ubah pemetaan port pada `docker run`. |

## 12. Berkas yang Tidak Dikirim

`.gitignore` sudah memuat `*.aux`, `*.log`, `*.toc`, `*.out`, `build-*.log`, dan
berkas sementara LaTeX lain. PDF hasil build tetap dikirim supaya dosen bisa
membaca tanpa memasang LaTeX.

Sebelum rilis, periksa:

```bash
git status --short
```

Keluaran yang diharapkan hanya berisi berkas yang memang sengaja diubah.
