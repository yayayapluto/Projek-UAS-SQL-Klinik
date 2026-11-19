# Panduan P3: Struktur Tabel dan Transformasi

## Peran

Kamu adalah Anggota 3. Kamu menulis skema fisik yang dipakai semua berkas lain.
Pekerjaanmu: menerjemahkan ERD menjadi sebelas tabel, memasang kunci dan
constraint, lalu menjelaskan transformasi serta aljabar relasional untuk laporan.
Kamu juga pemeriksa pertama hasil Anggota 4.

Kalau kamu terlambat, P2 tidak bisa mengisi data dan P4 tidak bisa menulis view
atau trigger. Selesaikan Milestone 1 dan 2 lebih dulu, umumkan bahwa `skema-v1`
sudah siap, baru lanjut ke penjelasan laporan.

## Berkas Milik

| Berkas atau bagian | Isi |
|---|---|
| `sql/01_struktur.sql` | Database dan sebelas tabel, kunci, constraint |
| Dokumentasi transformasi | Tabel aturan transformasi, skema relasional, daftar kunci tamu |
| Bahan aljabar relasional | Contoh sigma, pi, join, dan agregasi untuk tiga kebutuhan |
| Catatan review P4 | Nama tabel dan kolom pada view serta trigger |

Kamu tidak menulis `sql/02_data.sql` dan tidak menyentuh berkas P4.

## Konteks untuk AI

Proyek ini adalah basis data klinik pratama dengan MySQL 8.0.16 atau lebih baru.
Sebagai P3 kamu menulis `sql/01_struktur.sql`, yang membuat database dan tepat
sebelas tabel dengan InnoDB, `utf8mb4`, serta aturan `ON DELETE RESTRICT ON UPDATE
CASCADE` pada semua kunci tamu.

Aturan keras yang berlaku:

- Urutan pembuatan tabel dari induk ke anak.
- Kunci primer `id_<tabel>`, AUTO_INCREMENT.
- Tidak ada tabel kedua belas, tidak ada kolom baru tanpa kesepakatan.
- `imt` adalah generated column, bukan kolom biasa.
- `CHECK` dipakai untuk rentang medis dan nilai tidak negatif.
- `ENUM` hanya untuk `status_kunjungan`, `tipe_dokter`, `metode`, dan
  `status_bayar`.
- Database memakai `klinik_pratama`, karakter `utf8mb4`, kolasi
  `utf8mb4_unicode_ci`.

Kalau AI mengusulkan `FOREIGN_KEY_CHECKS=0` sebagai jalan keluar galat kunci
tamu, tolak. Itu menyembunyikan urutan pembuatan yang salah.

## Milestone 1: Aturan Transformasi

Tulis tabel aturan transformasi untuk laporan, lalu terapkan satu per satu.

| Pola pada diagram | Aturan | Penerapan di klinik |
|---|---|---|
| Entitas kuat | Menjadi tabel dengan kunci primer sendiri | poli, dokter, pasien, tindakan, obat |
| Relasi 1:N | Kunci primer sisi satu menjadi kunci tamu di sisi banyak | id_poli di dokter, id_dokter di jadwal_praktik, id_jadwal di kunjungan |
| Relasi M:N | Tabel baru berisi dua kunci tamu, keduanya menjadi kunci gabungan | detail_tindakan, detail_resep |
| Relasi 1:1 atau 1:0..1 | Kunci tamu di sisi yang paling banyak satu, lalu diberi constraint unik | id_kunjungan unik di rekam_medis dan pembayaran |
| Atribut turunan | Tidak disimpan manual; dihitung saat dibutuhkan atau lewat generated column | imt, total_tagihan |
| Atribut multinilai | Dipecah menjadi relasi terpisah | nomor telepon disederhanakan menjadi satu kolom |

## Milestone 2: Tulis `sql/01_struktur.sql`

### 2.1 Urutan pembuatan

Urutan yang benar:

```text
poli → dokter → jadwal_praktik → pasien → kunjungan → rekam_medis
→ tindakan → detail_tindakan → obat → detail_resep → pembayaran
```

Tabel induk harus ada sebelum tabel anak yang merujuknya. Untuk pengulangan,
hapus tabel dari anak ke induk lebih dulu, lalu buat ulang.

### 2.2 Pasang sepuluh kunci tamu

| Tabel anak | Kolom | Merujuk ke |
|---|---|---|
| dokter | id_poli | poli(id_poli) |
| jadwal_praktik | id_dokter | dokter(id_dokter) |
| kunjungan | id_pasien | pasien(id_pasien) |
| kunjungan | id_jadwal | jadwal_praktik(id_jadwal) |
| rekam_medis | id_kunjungan | kunjungan(id_kunjungan) |
| detail_tindakan | id_kunjungan | kunjungan(id_kunjungan) |
| detail_tindakan | id_tindakan | tindakan(id_tindakan) |
| detail_resep | id_rekam | rekam_medis(id_rekam) |
| detail_resep | id_obat | obat(id_obat) |
| pembayaran | id_kunjungan | kunjungan(id_kunjungan) |

Semuanya memakai `ON DELETE RESTRICT ON UPDATE CASCADE`. Baris induk tidak boleh
dihapus selama masih dirujuk anak, tetapi jika kunci primer berubah, nilainya
ikut diperbarui.

### 2.3 Constraint yang wajib ada

| Jenis | Contoh | Akibat jika dilanggar |
|---|---|---|
| PRIMARY KEY | id_pasien | Baris ganda dengan kunci sama ditolak |
| FOREIGN KEY | id_pasien pada kunjungan | Kunjungan dengan pasien tidak terdaftar ditolak |
| UNIQUE | nik, no_sip, email | Nilai kembar ditolak |
| CHECK | suhu 30 sampai 45 | Nilai di luar rentang ditolak |
| NOT NULL | nama_pasien, tanggal_periksa | Baris tanpa nilai wajib ditolak |
| ENUM | status_kunjungan | Nilai di luar empat pilihan ditolak |
| DEFAULT | status_kunjungan | Nilai terisi sendiri jika tidak disebut |
| AUTO_INCREMENT | seluruh kunci primer | Nomor urut terisi otomatis |

Constraint unik yang mudah terlewat:

- `uq_kunjungan_antrean UNIQUE (id_jadwal, no_antrean)` mencegah dua pasien
  mendapat nomor antrean sama pada satu jadwal.
- `uq_kunjungan_pasien UNIQUE (id_pasien, id_jadwal)` mencegah satu pasien
  mendaftar dua kali pada sesi yang sama.
- `uq_rekam_kunjungan UNIQUE (id_kunjungan)` dan
  `uq_pembayaran_kunjungan UNIQUE (id_kunjungan)` menjaga relasi 1:0..1.
- `uq_detail_tindakan UNIQUE (id_kunjungan, id_tindakan)` dan
  `uq_detail_resep UNIQUE (id_rekam, id_obat)` mencegah baris ganda pada tabel
  penghubung.

### 2.4 Generated column `imt`

```sql
imt DECIMAL(4,1) AS (
  ROUND(berat_badan / ((tinggi_badan/100) * (tinggi_badan/100)), 1)
) STORED
```

`STORED` dipilih supaya nilainya tersimpan dan bisa dibaca langsung seperti
kolom biasa, tetapi tetap dihitung database. Jangan mengisi kolom ini pada
`INSERT`.

### 2.5 Pemeriksaan cepat setelah menulis

```bash
bash tools/reset-db.sh
```

Keluaran yang benar menyebut `tabel terdaftar: 11`. Kalau gagal, baca pesan
galat dan nomor baris. Empat penyebab paling sering:

1. Tabel anak dibuat sebelum induk.
2. Tipe kolom kunci tamu berbeda dari kolom yang dirujuk.
3. Nama kolom pada `REFERENCES` salah ketik.
4. Constraint `CHECK` memakai ekspresi yang tidak didukung versi MySQL.

## Milestone 3: Aljabar Relasional

Tuliskan kebutuhan sebelum diterjemahkan menjadi SQL. Notasi: sigma untuk
seleksi baris, pi untuk proyeksi kolom, join untuk penggabungan, gamma untuk
agregasi.

**Kebutuhan 3: riwayat kunjungan lengkap.**

```text
pi(tanggal, nama_pasien, nama_dokter, nama_poli)(
  kunjungan join pasien join jadwal_praktik join dokter join poli
)
```

**Kebutuhan 4: sisa kuota per jadwal.**

```text
gamma(id_jadwal; COUNT(id_kunjungan))(
  sigma(status != 'Batal')(kunjungan)
)
```

**Kebutuhan 7: poli dengan pendapatan di atas rata-rata.**

```text
sigma(total > rata_rata)(gamma(nama_poli; SUM(total_tagihan))(
  pembayaran join kunjungan join jadwal_praktik join dokter join poli
))
```

Ketiganya menjadi Q3, Q4, dan Q7 di `bukti/kueri-panduan.sql`. Urutan operasi
pada aljabar menentukan urutan `JOIN` dan `GROUP BY` di SQL.

## Milestone 4: Review dan Skema Beku

1. Bandingkan skema dengan [PRD §5](PRD.md#5-kontrak-skema). Nama, tipe, dan
   constraint harus identik.
2. Periksa tidak ada kunci tamu yatim:
   `bash tools/verify.sh` bagian B.
3. Periksa review P4: setiap nama tabel dan kolom pada view serta trigger harus
   ada di skema. Salah ketik nama kolom biasanya baru terlihat saat view dibuat.
4. Setelah `verify.sh` bagian A dan B lulus, minta tag `skema-v1` dipasang.
5. Setelah tag, perubahan nama hanya lewat kesepakatan.

## Checklist

- [ ] Database `klinik_pratama` memakai `utf8mb4` dan `utf8mb4_unicode_ci`.
- [ ] Sebelas tabel dibuat dari induk ke anak.
- [ ] Seluruh kunci primer memakai AUTO_INCREMENT.
- [ ] Sepuluh kunci tamu memakai `ON DELETE RESTRICT ON UPDATE CASCADE`.
- [ ] Constraint unik, CHECK, NOT NULL, ENUM, DEFAULT terpasang.
- [ ] `imt` adalah generated column STORED.
- [ ] `reset-db.sh` melaporkan 11 tabel.
- [ ] `verify.sh` bagian A dan B lulus.
- [ ] Tabel transformasi dan daftar kunci tamu ada di laporan.
- [ ] Tiga contoh aljabar relasional ada.
- [ ] Review P4 mencatat nama yang tidak cocok.

## Kesalahan yang Sering Terjadi

1. Membuat tabel anak sebelum induk.
2. Memakai `INT` pada satu sisi kunci tamu dan `BIGINT` pada sisi lain.
3. Memberi `ON DELETE CASCADE` karena lebih mudah saat mengulang pengujian.
   Aturan proyek memakai `RESTRICT`.
4. Menyimpan `hari` pada jadwal, lalu nilainya bertentangan dengan tanggal.
5. Mengubah `ENUM` setelah data masuk tanpa memperbarui data dan laporan.
6. Menonaktifkan pemeriksaan kunci tamu untuk melewati galat.

## Prompt Siap Tempel

```text
Saya Anggota 3. Saya sedang menulis sql/01_struktur.sql. Berikut aturan umum
proyek dan isi berkas saya.

Periksa tiga hal: (1) urutan pembuatan tabel sudah induk ke anak, (2) setiap
kunci tamu merujuk kolom dengan tipe yang sama dan memakai ON DELETE RESTRICT
ON UPDATE CASCADE, (3) setiap CHECK memakai rentang yang masuk akal. Sebutkan
baris yang bermasalah, jangan tulis ulang seluruh berkas. Jangan menambah tabel
atau kolom baru.
```

## Definition of Done

Fase P3 selesai jika `reset-db.sh` membuat 11 tabel tanpa galat, `verify.sh`
bagian A dan B lulus, seluruh constraint yang tercantum di PRD terpasang,
dokumentasi transformasi dan aljabar relasional siap dipakai di Bab II, dan tag
`skema-v1` sudah dipasang.
