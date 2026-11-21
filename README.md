# Projek UAS SQL Klinik Pratama

Repo kerja kelompok untuk proyek UAS Konsep Basis Data. Isi repo ini adalah
scaffold SQL berkomentar dan petunjuk kerja. Belum ada solusi di sini; tim mengisi
sendiri berkas di `sql/`.

Panduan lengkap, PRD, pembagian tugas, dan panduan per peran tidak disimpan di
repo publik ini. Pemilik mengirimkannya sebagai ZIP dari repo privat. Rujukan
seperti `../../docs/PRD.md` di dalam komentar SQL menunjuk folder `docs/` pada
hasil ekstrak ZIP itu, bukan isi repo ini.

## Isi Repo

| Berkas | Pemilik | Isi |
| --- | --- | --- |
| `sql/00-kesepakatan.sql` | Anggota 1 | kesepakatan nama objek, aturan bisnis, kardinalitas, kebutuhan informasi |
| `sql/01_struktur.sql` | Anggota 3 | sebelas tabel, kunci, dan constraint |
| `sql/02_data.sql` | Anggota 2 | jumlah baris dan keadaan khusus data contoh |
| `sql/03_view_trigger.sql` | Anggota 4 | dua view dan empat trigger |
| `sql/04_prosedur.sql` | Anggota 4 | dua prosedur pendaftaran dan pembayaran |
| `sql/05_keamanan.sql` | Anggota 5 | tiga pengguna dan hak akses |
| `sql/06_indeks.sql` | Anggota 5 | dua indeks dan bukti EXPLAIN |
| `sql/07_pengujian.sql` | Anggota 6 | sepuluh skenario pengujian |

Setiap berkas hanya berisi komentar dan daftar TODO. Ganti `[ ]` menjadi `[x]`
setelah bagian itu selesai.

## Clone

```bash
git clone https://github.com/yayayapluto/Projek-UAS-SQL-Klinik.git
cd Projek-UAS-SQL-Klinik
```

Prasyarat, pembuatan database, dan urutan resmi ada di ZIP panduan. Tool
`reset-db.sh`, `verify.sh`, dan `demo-isolasi.sh` ditulis Anggota 6 pada Fase F3.

## Alur Kerja

Jangan bekerja langsung di `main`. Satu tugas satu branch.

```bash
git switch main
git pull --rebase origin main
git switch -c anggota-2/data-contoh

# sunting hanya berkas milik sendiri
git add sql/02_data.sql
git commit -m "feat(sql): tambah data contoh poli dan dokter"
git push -u origin anggota-2/data-contoh
```

Setelah push, buka pull request ke `main`. Minta review silang sesuai pembagian
tugas. Jangan memaksa push ke `main`.

Nama branch: `anggota-1/<topik>` sampai `anggota-5/<topik>`.

Format commit: `feat:`, `fix:`, `docs:`, `test:`, atau `chore:`.

## Aturan

1. Nama database `klinik_pratama`, nama tabel, kolom, constraint, view, trigger,
   prosedur, pengguna, dan indeks tidak diubah.
2. Satu berkas satu pemilik. Jangan menyunting berkas anggota lain tanpa izin.
3. Jangan commit token, kunci pribadi, atau berkas `.env`.
4. Kata sandi `Klinik#2026` hanya untuk database latihan lokal.
5. Jangan mengunggah data pasien nyata. Semua data contoh harus fiktif.
6. Jangan menyalin folder panduan ZIP ke repo ini.
7. Jalankan `bash tools/reset-db.sh` dan `bash tools/verify.sh` sebelum push.
   Hasil akhir harus `Lulus: 34   Gagal: 0`.
