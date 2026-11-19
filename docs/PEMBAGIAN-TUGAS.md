# Pembagian Tugas

Dokumen ini mengatur siapa mengerjakan apa, kapan batas waktunya, dan bagaimana
pekerjaan dinilai selesai. Isinya dipakai bersama [PRD](PRD.md) dan
[Project Overview](PROJECT-OVERVIEW.md). Kalau ada perbedaan nama objek atau
angka, PRD yang menang.

## Prinsip

Tiga kesepakatan ini berlaku sepanjang proyek.

**Satu berkas satu pemilik.** Setiap berkas SQL, bagian laporan, atau skrip punya
tepat satu orang yang boleh menulisnya. Anggota lain boleh membaca dan
mengusulkan perubahan lewat grup, tetapi tidak menyunting langsung. Aturan ini
mencegah konflik merge dan membuat tanggung jawab jelas saat presentasi.

**Skema dibekukan sebelum menulis objek.** `sql/01_struktur.sql` adalah janji
antar berkas. Setelah tag `skema-v1` dibuat, nama tabel, nama kolom, tipe data,
dan nama constraint tidak berubah tanpa kesepakatan kelompok. Berkas view,
trigger, prosedur, dan pengujian bergantung pada nama-nama itu.

**Bukti berupa perintah dan output.** "Sudah selesai" tanpa bukti tidak dihitung.
Setiap penyerahan menyertakan perintah yang dijalankan beserta potongan
keluarannya, minimal:

```text
bash tools/reset-db.sh     → tabel terdaftar: 11
bash tools/verify.sh       → Lulus: 34   Gagal: 0
```

Tangkapan layar boleh ditambahkan, tetapi tidak menggantikan keluaran teks.

## Peran

| Kode | Peran | Berkas dan bagian milik | Panduan |
|---|---|---|---|
| P1 | Studi kasus, kamus data, ERD, laporan | Studi kasus, delapan kebutuhan informasi, kamus data, ERD, Bab I dan III laporan, video bagian konsep | [P1](panduan-P1-studi-kasus-erd.md) |
| P2 | Normalisasi dan data | `sql/02_data.sql`, dokumentasi 1NF sampai BCNF, tangkapan layar query dasar | [P2](panduan-P2-normalisasi-data.md) |
| P3 | Struktur dan transformasi | `sql/01_struktur.sql`, tabel transformasi, skema relasional, aljabar relasional | [P3](panduan-P3-struktur-transformasi.md) |
| P4 | Objek basis data | `sql/03_view_trigger.sql`, `04_prosedur.sql`, `05_keamanan.sql`, `06_indeks.sql` | [P4](panduan-P4-view-trigger-prosedur.md) |
| P5 | Pengujian dan rilis | `sql/07_pengujian.sql`, `tools/`, `bukti/`, checklist, video, PDF | [P5](panduan-P5-pengujian-rilis.md) |

P1 dan P3 sebaiknya yang paling siap menulis SQL, karena keduanya memegang
keputusan skema dan data. P2 dan P5 boleh berasal dari anggota yang baru pertama
memakai DBMS. P4 pekerjaannya menengah, tetapi paling banyak berkasnya, jadi
jangan menumpuk semuanya di minggu terakhir.

Pembagian ini membagi beban secara setara, bukan memisahkan kemampuan. Peran
bukan pagar mati: anggota yang selesai lebih cepat boleh membantu menulis
dokumentasi, asalkan bukan berkas milik orang lain. Yang tidak boleh adalah dua
orang menyunting satu berkas pada waktu bersamaan tanpa kesepakatan.

## Fase dan Tag

Pekerjaan dibagi menjadi lima fase. Setiap fase ditutup dengan tag Git, sehingga
kemajuan bisa dilihat dari riwayat repo, bukan dari cerita di grup chat.

**F0: Kesepakatan (`kesepakatan-v1`), pemilik P1.** Menyepakati delapan aturan
bisnis, ruang lingkup, kamus data sebelas entitas, dan pembagian berkas. Tag ini
menandai bahwa nama entitas, atribut, dan cakupan sudah tidak berubah.

**F1: Skema (`skema-v1`), pemilik P3 dengan P2.** P3 menulis
`sql/01_struktur.sql` sampai seluruh tabel, kunci, dan constraint ada. P2 menulis
`sql/02_data.sql` yang memenuhi jumlah baris dan keadaan khusus. Setelah tag ini,
perubahan nama tabel atau kolom harus lewat kesepakatan.

**F2: Objek dan query (`objek-sql`), pemilik P4 dengan P2.** P4 menulis view,
trigger, prosedur, hak akses, dan indeks. P2 menyelesaikan dokumentasi
normalisasi dan tangkapan layar query dasar. Pekerjaan boleh paralel karena
berkasnya berbeda, tetapi keduanya membaca `skema-v1`.

**F3: Integrasi dan pengujian (`uji-hijau`), pemilik P5.** P5 menulis
`sql/07_pengujian.sql`, menjalankan `tools/verify.sh`, memperbarui `bukti/`, dan
menjalankan `demo-isolasi.sh`. Tag dipasang setelah 34 pemeriksaan lulus dan
seluruh bukti diperbarui.

**F4: Rilis (`rilis`), pemilik P5 dengan seluruh tim.** Laporan Bab I sampai III
selesai, PDF panduan dan laporan terbangun, video setiap anggota diunggah,
daftar periksa Bab 14 panduan diperiksa. Tag `rilis` adalah versi yang
dikumpulkan.

Urutan tag: `kesepakatan-v1` → `skema-v1` → `objek-sql` → `uji-hijau` → `rilis`.
Tag tidak boleh melompati fase, karena tag berikutnya mengasumsikan tag
sebelumnya sudah ada.

## Aturan Berkas

**Skema hanya lewat P3.** Nama tabel, kolom, tipe data, dan constraint diubah di
`sql/01_struktur.sql` oleh P3. Jika P4 membutuhkan kolom baru untuk trigger atau
indeks, usulan dikirim ke P3, bukan ditambahkan lewat `ALTER TABLE` di berkas
lain. P3 yang memutuskan, menyunting skema, lalu memberi tahu P1, P2, dan P5
karena ketiganya memakai nama yang sama.

**Data contoh hanya lewat P2.** Angka pada `sql/02_data.sql` memengaruhi hasil
query, tabel di panduan, `bukti/`, dan 34 pemeriksaan. Karena itu hanya P2 yang
menyunting berkas itu, dan setiap perubahan harus disertai `reset-db.sh` serta
`verify.sh` yang lulus.

**Nama objek tidak diganti.** Daftar nama ada di [PRD §5.4](PRD.md#54-objek-bernama).
Mengganti nama trigger berarti memperbarui pengujian, panduan, laporan, dan
`bukti/` sekaligus. Biayanya jauh lebih besar daripada manfaatnya.

**Pengujian tidak disesuaikan dengan hasil yang gagal.** Jika `verify.sh` gagal,
yang diperbaiki adalah skema, data, atau objeknya, bukan pemeriksaannya. Satu
pengecualian: pemeriksaan yang memang salah tulis dan sudah disepakati P5 serta
pemilik berkas terkait.

**Berkas bersama disepakati.** `README.md`, `docs/ai/`, `tools/`, dan
`.gitignore` tidak dimiliki satu orang. Perubahan yang memengaruhi perintah kerja
semua orang diumumkan di grup sebelum dikirim.

## Pendampingan Anggota Baru

P2 dan P5 bukan latar belakang basis data, jadi pendampingan masuk ke rencana
kerja, bukan tindakan darurat menjelang deadline.

Review dilakukan maksimal satu hari setelah penyerahan. Review menyebut hal
konkret: nama berkas, nomor baris, pesan galat, dan perbaikan yang disarankan.
Komentar "rapikan lagi" tidak dihitung sebagai review; yang dihitung adalah
"trigger `trg_cek_stok_obat` membaca `stok` sebelum `trg_kurangi_stok`
berjalan, jadi urutannya sudah benar, tetapi pesan galatnya belum diuji di Uji
6".

Satu sesi kerja bersama per fase. P3 dan P2 duduk selama 30 sampai 60 menit untuk
membahas satu berkas yang macet, misalnya urutan pembuatan tabel atau data yang
melanggar kunci tamu. Sesi dicatat tanggalnya di pesan grup.

Checklist "bisa menjelaskan" berlaku per objek yang dipegang. Sebelum penyerahan
boleh digabung, pemiliknya harus bisa menjawab tanpa membuka berkas:

- apa yang dilakukan objek itu;
- kapan objek itu berjalan atau dipanggil;
- pesan galat apa yang dihasilkan jika aturannya dilanggar;
- pengujian mana yang membuktikannya.

Jika tidak bisa menjawab, objeknya belum dianggap selesai meskipun
`verify.sh` lulus.

## Jadwal

Empat minggu, dengan asumsi sekitar 8 sampai 10 jam kerja per orang per minggu.

| Minggu | Fokus | Keluaran | Penanggung jawab |
|---|---|---|---|
| M1 | Kesepakatan dan konsep | delapan aturan bisnis, kamus data, ERD, ruang lingkup, tag `kesepakatan-v1` | P1, dibantu seluruh tim |
| M2 | Skema dan data | `sql/01_struktur.sql`, `sql/02_data.sql`, dokumentasi normalisasi, tag `skema-v1` | P2 dan P3 |
| M3 | Objek, query, dan pengujian | view, empat trigger, dua prosedur, hak akses, dua indeks, sepuluh query, `07_pengujian.sql`, `verify.sh` lulus | P4 dan P5 |
| M4 | Rilis | ulangan dari database kosong, `bukti/` diperbarui, video, PDF panduan dan laporan, daftar periksa | seluruh tim, koordinasi P5 |

M2 dan M3 paling padat karena skema harus selesai sebelum objek ditulis. Jika
jadwal mepet, yang dipotong adalah tambahan penjelasan di laporan, bukan
pengujian atau perbaikan data.

Minggu 4 sengaja dipakai untuk menjalankan ulang seluruh skrip dari keadaan
kosong. Kesalahan yang paling sering muncul justru di sini: urutan pembuatan
tabel salah, atau ada data yang hanya bekerja karena sisa percobaan sebelumnya.

## Definition of Done

Kriteria berikut berlaku per fase. Fase belum boleh ditutup jika ada satu butir
yang belum terpenuhi.

**F0: `kesepakatan-v1`.** Delapan aturan bisnis tertulis dan masing-masing punya
penjaga teknis. Kamus data memuat sebelas entitas beserta atributnya. ERD
memuat kardinalitas 1:N, M:N, dan 1:0..1. Ruang lingkup dan empat hal di luar
cakupan disepakati. Pembagian berkas tercatat.

**F1: `skema-v1`.** `reset-db.sh` berhasil membuat 11 tabel. Setiap tabel punya
kunci primer. Sepuluh kunci tamu memakai `ON DELETE RESTRICT ON UPDATE
CASCADE`. Setiap tabel berisi minimal lima baris. Tidak ada kunci tamu yatim.
`verify.sh` bagian A dan B lulus.

**F2: `objek-sql`.** Dua view, empat trigger, dua prosedur, tiga pengguna, dan
dua indeks ada dengan nama yang ditetapkan PRD. `EXPLAIN` sebelum dan sesudah
indeks menunjukkan perubahan kolom `key`. Percobaan menulis oleh
`petugas_klinik` ditolak 1142. Sepuluh query menghasilkan angka yang sama dengan
`bukti/10-kueri.txt`. Bagian C, D, dan F pada `verify.sh` lulus.

**F3: `uji-hijau`.** Sepuluh skenario pada `07_pengujian.sql` memberi hasil
sesuai tabel pengujian. `verify.sh` berakhir `Lulus: 34   Gagal: 0`. Seluruh
berkas `bukti/` sudah diperbarui dari database hasil `reset-db.sh`. Demo isolasi
menampilkan perbedaan `READ COMMITTED` dan `REPEATABLE READ` serta galat 1213.

**F4: `rilis`.** PDF panduan terbangun tanpa rujukan menggantung. PDF laporan
terbangun dengan sampul berisi nama dan NIM. Isi laporan cocok dengan angka pada
`bukti/`. Video setiap anggota sudah diunggah dan tautannya bisa dibuka. Daftar
periksa Bab 14 panduan sudah diperiksa satu per satu.

## Pemetaan Materi ke Pemilik

Tabel ini memastikan setiap materi kuliah punya wujud nyata dan ada orang yang
bertanggung jawab menjelaskannya saat demo.

| Minggu | Materi | Wujud wajib | Pemilik |
|---|---|---|---|
| W1 | Konsep dasar, arsitektur DBMS, kemandirian data | penjelasan Bab 1, contoh kemandirian lewat view dan indeks | P1 |
| W2 | Model relasional, istilah relasi, kunci | skema sebelas tabel beserta daftar kunci | P3 |
| W3 | Perancangan basis data, identifikasi kebutuhan | delapan aturan bisnis, kamus data | P1 |
| W4 | Model relasi entitas, kardinalitas | ERD dan tabel kardinalitas | P1 |
| W5 | Transformasi ke tabel, aljabar relasional | tabel transformasi, contoh sigma, pi, join, agregasi | P3 |
| W6 | Normalisasi sampai 3NF | tabel perubahan tiap tahap | P2 |
| W7 | BCNF dan dependensi fungsional | daftar dependensi dan pembuktian BCNF | P2 |
| W8 | Ujian tengah semester | tidak ada luaran baru | tidak ada |
| W9 | DDL, tipe data, constraint | `sql/01_struktur.sql` | P3 |
| W10 | DML, INSERT, UPDATE, DELETE | `sql/02_data.sql` | P2 |
| W11 | Join, subquery, agregasi | Q1 sampai Q3 dan Q6 | P4 dan P5 |
| W12 | Pengelompokan, fungsi jendela | Q4, Q5, Q7 sampai Q10 | P4 dan P5 |
| W13 | Transaksi, ACID, isolasi | `sql/04_prosedur.sql`, `bukti/isolasi.txt` | P4 dan P5 |
| W14 | Keamanan, hak akses, indeks | `sql/05_keamanan.sql`, `sql/06_indeks.sql` | P4 |
| W15 | NoSQL dan tren teknologi | pemetaan dokumen JSON, tabel perbandingan | P1 |

W8 tidak punya luaran baru karena pekan ujian. Bahan normalisasi tetap dipakai
untuk belajar.

W13 sampai W15 sering terlewat karena pengerjaan berhenti setelah query selesai.
Di proyek ini ketiganya wajib dan dibuktikan dengan skrip yang benar-benar
dijalankan, bukan hanya dijelaskan.
