# Panduan GitHub Bersama

Repo bersama: <https://github.com/yayayapluto/Projek-UAS-SQL-Klinik>

Repo ini publik. Siapa pun boleh membaca, tetapi hanya anggota yang diundang
sebagai collaborator yang boleh mengirim perubahan langsung. Anggota lain bisa
memakai fitur fork.

## Isi Repo

| Lokasi | Isi |
|---|---|
| `README.md` | indeks paket dan aturan kerja |
| `docs/` | PRD, gambaran proyek, pembagian tugas, panduan 0, panduan P1 sampai P5 |
| `sql/` | delapan berkas scaffold berisi komentar dan daftar TODO |
| `PANDUAN-GITHUB.md` | berkas ini |

Repo ini tidak memuat solusi. Berkas kerja seperti `tools/`, `bukti/`,
`laporan/`, dan salinan LaTeX tetap berada di repo kerja kelompok.

## Undang Anggota

Pemilik repo membuka:

```text
Settings > Collaborators and teams > Add people
```

Masukkan akun GitHub setiap anggota, pilih akses `Write`, lalu kirim undangan.
Anggota menerima undangan lewat email atau halaman notifikasi GitHub.

Lewat CLI, perintahnya:

```bash
gh api --method PUT \
  repos/yayayapluto/Projek-UAS-SQL-Klinik/collaborators/<akun-anggota> \
  -f permission=push
```

Ganti `<akun-anggota>` dengan username GitHub. Undangan tetap harus diterima
anggota sebelum berlaku.

## Clone Sekali

```bash
git clone https://github.com/yayayapluto/Projek-UAS-SQL-Klinik.git
cd Projek-UAS-SQL-Klinik
```

Periksa identitas Git sebelum commit:

```bash
git config user.name
git config user.email
```

Kalau kosong, isi sekali:

```bash
git config --global user.name "Nama Kamu"
git config --global user.email "email@contoh.com"
```

## Alur Kerja Anggota

Jangan bekerja langsung di `main`. Satu tugas satu branch.

```bash
git switch main
git pull --rebase origin main
git switch -c anggota-2/data-contoh

# sunting hanya berkas milik sendiri, misalnya sql/02_data.sql
git add sql/02_data.sql
git commit -m "feat(sql): tambah data contoh poli dan dokter"
git push -u origin anggota-2/data-contoh
```

Setelah push, GitHub menampilkan tautan untuk membuka pull request. Buat PR ke
`main`, isi ringkasan perubahan dan hasil pemeriksaan, lalu minta review silang
sesuai pembagian tugas.

Aturan branch:

```text
anggota-1/<topik>   contoh: anggota-1/erd-kamus-data
anggota-2/<topik>
anggota-3/<topik>
anggota-4/<topik>
anggota-5/<topik>
```

Aturan commit mengikuti Conventional Commits:

```text
feat: fitur baru
fix: perbaikan
docs: dokumentasi
test: pengujian
chore: alat atau berkas pendukung
```

## Menarik Perubahan Sebelum Push

Bila `main` sudah bergerak saat branch sendiri masih terbuka:

```bash
git switch main
git pull --rebase origin main
git switch anggota-2/data-contoh
git rebase main
git push --force-with-lease
```

`--force-with-lease` hanya untuk branch sendiri. Jangan pernah memaksa push ke
`main`.

Konflik paling sering muncul kalau dua orang menyunting berkas yang sama.
Karena setiap berkas punya pemilik tunggal, konflik seharusnya jarang. Bila
muncul, selesaikan di branch sendiri, jalankan ulang pemeriksaan, lalu push.

## Tag Fase

Tag dipasang setelah fase selesai dan PR sudah digabung:

```bash
git switch main
git pull --rebase origin main
git tag -a kesepakatan-v1 -m "Kesepakatan nama objek dan aturan bisnis"
git push origin kesepakatan-v1
```

Urutan tag: `kesepakatan-v1`, `skema-v1`, `objek-sql`, `uji-hijau`, `rilis`.

## Aturan Repo Publik

1. Jangan commit token, kunci, kata sandi pribadi, atau berkas `.env`.
2. Kata sandi `Klinik#2026` di scaffold hanya kredensial latihan database lokal.
3. Jangan mengunggah data pasien nyata. Data contoh harus fiktif.
4. Jangan mengubah berkas anggota lain tanpa persetujuan pemiliknya.
5. Jangan push ke `main` langsung. Selalu lewat branch dan pull request.
6. Tarik perubahan dengan `git pull --rebase` sebelum push.
7. Periksa `git status` sebelum commit agar berkas sementara tidak ikut.

## Pemeriksaan Sebelum Push

Di repo kerja, jalankan:

```bash
bash tools/reset-db.sh
bash tools/verify.sh
```

Keluaran akhir harus:

```text
Lulus: 34   Gagal: 0
SEMUA PEMERIKSAAN LULUS
```

Untuk scaffold ini, cukup pastikan berkas SQL masih hanya komentar:

```bash
grep -v '^--' sql/01_struktur.sql | grep -v '^$'
```

Keluarannya harus kosong.
