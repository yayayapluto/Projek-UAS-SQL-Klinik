# Panduan P5: Pengujian, Bukti, dan Rilis

## Peran

Kamu adalah Anggota 5, sekaligus koordinator rilis. Pekerjaanmu membuat orang
lain bisa membuktikan bahwa proyek ini bekerja: sepuluh skenario pengujian, 34
pemeriksaan otomatis, berkas bukti, video, PDF, dan daftar periksa akhir.

Kamu juga pemeriksa hasil Anggota 1 dan Anggota 2. Review-mu berbasis eksekusi,
bukan pendapat: jalankan ulang skrip pada salinan repositori, lalu laporkan
keluaran yang berbeda.

## Berkas Milik

| Berkas atau bagian | Isi |
|---|---|
| `sql/07_pengujian.sql` | Sepuluh skenario pengujian bernomor |
| `tools/reset-db.sh` | Memuat ulang database dari nol |
| `tools/verify.sh` | 34 pemeriksaan isi dan perilaku |
| `tools/demo-isolasi.sh` | Bukti tingkat isolasi dan deadlock |
| `tools/build.sh` | Membangun PDF panduan dan laporan |
| `bukti/` | Keluaran nyata setiap skrip |
| Daftar periksa akhir | Bab 14 panduan, diperiksa dengan bukti |
| Video dan PDF | Rekaman tiap anggota, hasil build |

Kamu tidak menyunting skema, data contoh, view, trigger, atau prosedur. Kalau
pengujian menemukan kesalahan di berkas itu, laporkan ke pemiliknya dengan pesan
galat lengkap dan nomor baris.

## Konteks untuk AI

Proyek ini memakai MySQL 8.0, database `klinik_pratama`, dan skrip 01 sampai 06
yang sudah dimuat lewat `reset-db.sh`. Sebagai P5 kamu menulis
`sql/07_pengujian.sql`, skrip `tools/`, dan berkas `bukti/`.

Fakta yang wajib dipakai:

- Ada sepuluh uji. Uji 1 sampai 6 dan Uji 10 harus gagal dengan pesan tertentu.
  Uji 7, 8, dan 9 harus berhasil.
- Klien `mysql` dijalankan dengan `--force` karena kegagalan itu disengaja.
- `verify.sh` harus berakhir `Lulus: 34   Gagal: 0`.
- Data contoh: jadwal 7 penuh, obat 8 berstok 5, dua kunjungan Batal, tiga
  pembayaran Belum Lunas.
- Blok pembersihan di akhir `07_pengujian.sql` wajib ada supaya uji bisa
  dijalankan berulang.

Jangan melonggarkan pemeriksaan agar lulus. Kalau `verify.sh` gagal, perbaiki
skema, data, atau objeknya.

## Milestone 1: Sepuluh Skenario Pengujian

Setiap uji bernomor dan menyebut harapan serta hasil nyata. Tabel berikut adalah
kontrak yang harus dipenuhi.

| No | Yang diuji | Harapan | Hasil nyata |
|---|---|---|---|
| 1 | Nomor antrean ganda pada satu jadwal | Galat 1062 | `Duplicate entry '2-1' for key 'uq_kunjungan_antrean'` |
| 2 | Kunjungan dengan pasien tidak terdaftar | Galat 1452 | foreign key `fk_kunjungan_pasien` gagal |
| 3 | Suhu tubuh 50 derajat | Galat 3819 | `Check constraint 'ck_rekam_suhu' is violated` |
| 4 | Pendaftaran melewati kuota | Pesan kuota penuh | `Kuota jadwal sudah penuh` |
| 5 | Jadwal dokter bentrok | Pesan bentrok | `Jadwal dokter bentrok` |
| 6 | Resep melebihi stok | Pesan stok kurang | `Stok obat tidak cukup` |
| 7 | Alur normal daftar lalu bayar | Berhasil, total sesuai | antrean 1, `total_dibayar 155000.00` |
| 8 | Membayar kunjungan yang sudah lunas | Pesan sudah dibayar | `Kunjungan sudah dibayar` |
| 9 | View `v_kunjungan_lengkap` | Menampilkan gabungan | lima baris pertama lengkap |
| 10 | Hak akses petugas | Galat 1142 | `INSERT command denied ... 'obat'` |

Jalankan:

```bash
docker exec -i kbd-mysql mysql -uroot -pkbd --force < sql/07_pengujian.sql
```

Simpan keluaran ke `bukti/07_pengujian.txt`.

### 1.1 Catatan yang harus masuk laporan

- **Uji 4 butuh jadwal penuh.** Jadwal 7 berkuota 4 dan sudah terisi 4 kunjungan
  tidak Batal. Kalau data contoh diubah, uji bisa lolos tanpa sengaja.
- **Uji 7 butuh tanggal masa depan.** Prosedur menolak jadwal yang sudah lewat.
  Uji membuat jadwal Desember 2026, lalu menghitung total 155.000 dari tindakan
  150.000 ditambah obat 5.000.
- **Uji 10 butuh koneksi akun petugas.** Tidak bisa dijalankan sebagai root.
- **Pembersihan wajib.** Blok terakhir menghapus data uji, mengembalikan stok,
  dan mencetak jumlah baris akhir. Tanpa blok ini, pengujian kedua mengubah
  angka laporan.

## Milestone 2: Pemeriksaan Otomatis

`verify.sh` berisi 34 pemeriksaan dalam tujuh bagian.

| Bagian | Isi | Jumlah |
|---|---|---|
| A | 11 tabel, 2 view, minimal 5 baris per tabel | 13 |
| B | Tidak ada kunci tamu yatim | 1 |
| C | Aturan bisnis tercermin di data | 6 |
| D | Indeks dipakai optimizer | 2 |
| E | Enam masukan salah ditolak | 6 |
| F | Hak akses dan penolakan 1142 | 3 |
| G | Transaksi berhasil seluruhnya atau tidak sama sekali | 3 |

Keluaran akhir:

```text
Lulus: 34   Gagal: 0
SEMUA PEMERIKSAAN LULUS
```

Pemeriksaan dirancang gagal jika ada yang berubah. Contohnya, bagian E tidak
hanya memastikan perintah gagal, tetapi juga memastikan pesan galatnya sesuai.
Bagian G membandingkan total tagihan dengan hitungan manual, bukan dengan angka
yang ditulis tangan.

Simpan hasil:

```bash
bash tools/verify.sh > bukti/verify.txt
```

## Milestone 3: Bukti dan Isolasi

### 3.1 Daftar bukti minimum

| Berkas | Perintah |
|---|---|
| `bukti/00-reset.txt` | `bash tools/reset-db.sh` |
| `bukti/05_keamanan.txt` | muat `sql/05_keamanan.sql` |
| `bukti/06_indeks.txt` | muat `sql/06_indeks.sql` |
| `bukti/07_pengujian.txt` | jalankan `sql/07_pengujian.sql` dengan `--force` |
| `bukti/10-kueri.txt` | jalankan `bukti/kueri-panduan.sql` |
| `bukti/isolasi.txt` | `bash tools/demo-isolasi.sh` |
| `bukti/verify.txt` | `bash tools/verify.sh` |

### 3.2 Demo isolasi

```bash
bash tools/demo-isolasi.sh
```

Demo menjalankan dua sesi bersamaan dan menampilkan tiga hal: perbedaan hasil
`READ COMMITTED` dan `REPEATABLE READ`, perubahan stok setelah `COMMIT`, dan
galat 1213 saat deadlock. Simpan keluaran ke `bukti/isolasi.txt`.

Kedua tingkat isolasi harus terlihat berbeda. Kalau hasilnya sama, sesi kedua
mungkin tidak benar-benar berjalan bersamaan.

## Milestone 4: Laporan, Video, dan PDF

### 4.1 Susunan laporan

Kerangka ada di `laporan/template-laporan.tex`. Setiap bagian diberi komentar
`% ISI: ambil dari Bab N` supaya penulis tidak mencari bahan dari awal.

| Bab | Isi |
|---|---|
| Bab I | Deskripsi basis data, studi kasus, ruang lingkup, pembagian peran |
| Bab II | ERD, transformasi, normalisasi, kode SQL, tangkapan layar demo |
| Bab III | Kesimpulan dan saran pengembangan |

Jangan menyalin angka dari panduan tanpa mencocokkannya dengan `bukti/`.
Panduan dan database harus menampilkan angka yang sama.

### 4.2 Video per anggota

Durasi satu sampai enam menit, sesuai bagian yang dikerjakan.

| Anggota | Isi rekaman |
|---|---|
| Anggota 1 | Studi kasus, ruang lingkup, kamus data, ERD, kesimpulan |
| Anggota 2 | Normalisasi tiap tahap, data contoh, hasil query dasar |
| Anggota 3 | Struktur tabel, constraint, transformasi, aljabar relasional |
| Anggota 4 | View, trigger dengan demo penolakan, prosedur, hak akses, indeks dan `EXPLAIN` |
| Anggota 5 | Sepuluh pengujian, demo isolasi dan deadlock, `verify.sh`, build PDF |

Urutan demo enam menit yang efisien:

1. `reset-db.sh`, tunjukkan 11 tabel.
2. Workbench, tampilkan diagram dan satu tabel berisi data.
3. Q3 dan Q4, tunjukkan sisa kuota 0 pada jadwal 7.
4. Uji 4, tunjukkan pesan kuota penuh.
5. Panggil `sp_bayar_kunjungan`, lalu panggil lagi untuk pesan sudah dibayar.
6. `demo-isolasi.sh`, tunjukkan perbedaan isolasi dan galat 1213.
7. `SHOW GRANTS` dan penolakan 1142.
8. `verify.sh` yang seluruhnya lulus.

Rekam setelah `reset-db.sh`, bukan setelah percobaan sebelumnya.

### 4.3 Build PDF

```bash
bash tools/build.sh
```

Hasil: `panduan/utama.pdf` dan `laporan/template-laporan.pdf`. Build berhenti
dengan pesan jika `pdflatex` tidak ditemukan atau kompilasi gagal. PDF di bawah
100 KB biasanya menandakan kompilasi berhenti di tengah.

## Milestone 5: Daftar Periksa Akhir

Periksa satu per satu. Setiap butir harus punya bukti.

- [ ] Database dibuat ulang dari nol dengan `reset-db.sh` tanpa galat.
- [ ] `verify.sh` selesai `Lulus: 34   Gagal: 0`.
- [ ] Sebelas tabel ada, setiap tabel minimal lima baris.
- [ ] Tidak ada kunci tamu yatim.
- [ ] Sepuluh query berjalan dan hasilnya sama dengan tabel panduan.
- [ ] Dua view menampilkan data benar.
- [ ] Empat trigger menolak data yang melanggar aturan.
- [ ] Dua prosedur berjalan, pembayaran kedua ditolak.
- [ ] Tiga pengguna ada, penulisan oleh petugas ditolak 1142.
- [ ] Dua indeks dipakai optimizer.
- [ ] `bukti/` memuat keluaran setiap skrip.
- [ ] PDF panduan tanpa rujukan menggantung dan daftar isi lengkap.
- [ ] PDF laporan terbangun, sampul berisi nama dan NIM.
- [ ] Repositori bersih dari `.aux`, `.log`, `.toc`.
- [ ] Video setiap anggota bisa dibuka.

## Kesalahan yang Sering Terjadi

1. Menjalankan skrip tidak berurutan, lalu menyalahkan kunci tamu.
2. Mengubah data contoh tanpa memperbarui tabel hasil dan `bukti/`.
3. Menjalankan pengujian berulang tanpa blok pembersihan, sehingga jumlah baris
   bertambah.
4. Melampirkan hanya sebagian konteks saat bertanya ke AI, lalu menerima jawaban
   dengan nama tabel karangan.
5. Lupa `reset-db.sh` sebelum merekam video.
6. Membangun PDF sebelum isi laporan final, lalu lupa membangun ulang.
7. Menyimpan keluaran `verify.sh` yang lama setelah skema berubah.

## Prompt Siap Tempel

```text
Saya Anggota 5. Saya sedang menguji basis data klinik pratama. Berikut aturan
umum proyek, sql/07_pengujian.sql, dan keluaran verify.sh terakhir.

Periksa apakah sepuluh uji sudah mencakup seluruh aturan bisnis dan apakah blok
pembersihan mengembalikan database ke kondisi semula. Untuk setiap kegagalan,
sebutkan uji nomor berapa, pesan galat lengkap, dan berkas pemilik yang harus
memperbaikinya. Jangan mengubah data contoh atau melonggarkan pemeriksaan.
```

## Definition of Done

Fase P5 selesai jika sepuluh uji memberi hasil sesuai kontrak, `verify.sh`
melaporkan 34 lulus dan 0 gagal, seluruh `bukti/` diperbarui dari database hasil
`reset-db.sh`, kedua PDF terbangun, video setiap anggota bisa dibuka, dan daftar
periksa akhir terisi dengan bukti.
