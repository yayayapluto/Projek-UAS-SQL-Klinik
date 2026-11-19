# PRD: Sistem Informasi Klinik Pratama

Dokumen ini adalah sumber primer untuk proyek basis data **Sistem Informasi
Klinik Pratama**. Semua nama tabel, nama kolom, tipe data, constraint, angka data
contoh, dan perilaku objek basis data di seluruh paket panduan merujuk ke sini.
Berkas yang menjalankan kontrak ini adalah `sql/01_struktur.sql` sampai
`sql/07_pengujian.sql`. Jika panduan peran dan PRD berbeda, PRD yang menang.

## 1. Ringkasan dan Tujuan

Klinik Pratama adalah klinik rawat jalan berskala kecil dengan lima poli: Poli
Umum, Poli Anak, Poli Gigi, Poli Penyakit Dalam, dan Poli Mata. Pasien mendaftar
di meja depan, menerima nomor antrean, diperiksa dokter, menerima tindakan dan
resep, lalu membayar tagihan.

Proyek ini menghasilkan satu basis data relasional yang menangani seluruh alur
tersebut, dari pendaftaran sampai pembayaran. Pekerjaan mencakup identifikasi
kebutuhan, diagram relasi entitas, transformasi ke tabel, normalisasi sampai
BCNF, SQL dasar, query lanjutan, transaksi, hak akses, indeks, pengujian, dan
laporan.

Luaran yang dikumpulkan ada tiga:

1. Tujuh berkas SQL berurutan yang berjalan di MySQL 8.0.16 atau lebih baru.
2. Panduan pengerjaan sebagai pegangan kerja dan bukti pemenuhan materi mingguan.
3. Laporan akhir Bab I sampai Bab III beserta tangkapan layar hasil eksekusi.

Tidak ada aplikasi Java, PHP, atau antarmuka grafis. Semua pekerjaan dilakukan
lewat klien SQL, dan semua bukti berupa teks keluaran perintah.

## 2. Batasan Teknis

| Aspek | Ketentuan |
|---|---|
| DBMS | MySQL 8.0.16 atau lebih baru. Versi 8.0.16 adalah versi pertama yang menegakkan `CHECK`. |
| Mesin penyimpanan | InnoDB untuk seluruh tabel |
| Karakter | `utf8mb4` dengan kolasi `utf8mb4_unicode_ci` |
| Nama database | `klinik_pratama` |
| Penamaan | Huruf kecil dengan garis bawah |
| Kunci primer | `id_` diikuti nama tabel |
| Kunci tamu | Nama sama dengan kunci primer yang dirujuk |
| Alat tulis | MySQL Workbench atau klien SQL lain |
| Alat gambar | draw.io atau TikZ |
| Penyimpanan kode | Repositori Git |
| Bukti | Teks keluaran perintah, disimpan di `bukti/` |

Keputusan teknis lain:

- Kolom `hari` tidak disimpan pada `jadwal_praktik`. Nilainya diturunkan dari
  tanggal dengan `DAYNAME()`.
- Indeks massa tubuh (`imt`) tidak diisi manual, melainkan generated column.
- Spesialisasi dokter diwakili satu kolom `tipe_dokter`, bukan tiga tabel.
- Semua kunci tamu memakai `ON DELETE RESTRICT ON UPDATE CASCADE`.

## 3. Pengguna dan Skenario

Ada dua jenis pengguna yang dilayani proyek ini.

**Pengguna basis data.** Tiga akun MySQL mewakili pekerjaan nyata di klinik.
`petugas_klinik` mengurus pendaftaran dan jadwal. `dokter_klinik` menulis rekam
medis dan resep. `admin_klinik` memelihara seluruh database. Hak masing-masing
dijelaskan pada §8.4.

**Dosen atau penilai.** Tidak memakai aplikasi, tetapi memeriksa hasil:
menjalankan skrip dari database kosong, membaca keluaran `verify.sh`, menelusuri
nama objek, dan mencocokkan laporan dengan `bukti/`.

Skenario utama:

1. Petugas melihat jadwal dokter, mendaftarkan pasien, dan mencetak nomor antrean.
2. Dokter membuka riwayat kunjungan, mencatat keluhan dan diagnosis, memberi
   tindakan, lalu menulis resep.
3. Petugas menghitung tagihan dari tindakan dan obat, mencatat pembayaran, lalu
   menerima penolakan jika kunjungan sudah dibayar.
4. Pengelola sistem memeriksa rencana eksekusi query sebelum dan sesudah indeks
   dibuat.

## 4. Ruang Lingkup

Termasuk dalam cakupan:

- pendaftaran pasien dan penjadwalan sesi praktik;
- pencatatan kunjungan dan rekam medis;
- tindakan medis dan resep obat beserta stok;
- perhitungan tagihan dan pencatatan pembayaran;
- pelaporan kunjungan, sisa kuota, pendapatan poli, dan pemakaian obat;
- pengaturan hak akses, indeks, transaksi, dan pengujian.

Tidak termasuk, dan alasan pembatasannya dicatat di laporan:

| Di luar cakupan | Alasan |
|---|---|
| Riwayat cicilan pembayaran | Pembayaran dianggap lunas sekali bayar, cukup status dan tanggal |
| Pengadaan obat dari pemasok | Stok hanya berkurang; penambahan dilakukan manual lewat SQL |
| Jadwal berulang mingguan | Setiap sesi dicatat satu baris pada tanggal tertentu; hari diturunkan dengan `DAYNAME()` |
| Autentikasi aplikasi | Hak akses diatur di tingkat database dengan `GRANT` |
| Jenis kelamin pasien | Tidak dibutuhkan oleh satu pun kebutuhan informasi |
| Aplikasi antarmuka | Penilaian terfokus pada perancangan dan SQL |

## 5. Kontrak Skema

### 5.1 Aturan penamaan

Nama tabel memakai bentuk tunggal (`pasien`, bukan `pasien_pasien`). Kunci primer
memakai `id_` diikuti nama tabel atau bentuk pendeknya: `id_rekam` pada
`rekam_medis`, `id_pembayaran` pada `pembayaran`. Kunci tamu memakai nama kolom
yang sama dengan kunci primer yang dirujuk. Semua
objek lain memakai awalan jenisnya: `v_` untuk view, `trg_` untuk trigger, `sp_`
untuk prosedur, `idx_` untuk indeks, `uq_` dan `ck_` untuk constraint.

### 5.2 Tabel

Database berisi tepat **sebelas tabel**. Jumlah, nama, dan kolomnya tidak berubah
tanpa kesepakatan kelompok.

**poli**: tempat layanan.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_poli | INT | PK, AUTO_INCREMENT |
| nama_poli | VARCHAR(50) | NOT NULL, UNIQUE `uq_poli_nama` |
| lantai | VARCHAR(10) | NOT NULL |

**dokter**: tenaga medis, relasi 1:N dari poli.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_dokter | INT | PK, AUTO_INCREMENT |
| id_poli | INT | FK ke `poli`, NOT NULL |
| nama_dokter | VARCHAR(100) | NOT NULL |
| no_sip | VARCHAR(30) | NOT NULL, UNIQUE `uq_dokter_sip` |
| email | VARCHAR(100) | NOT NULL, UNIQUE `uq_dokter_email` |
| no_telp | VARCHAR(20) | NULL |
| tipe_dokter | ENUM('Umum','Spesialis') | NOT NULL, DEFAULT 'Umum' |

**jadwal_praktik**: satu baris untuk satu sesi praktik pada satu tanggal.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_jadwal | INT | PK, AUTO_INCREMENT |
| id_dokter | INT | FK ke `dokter`, NOT NULL |
| tanggal | DATE | NOT NULL |
| jam_mulai | TIME | NOT NULL |
| jam_selesai | TIME | NOT NULL |
| ruangan | VARCHAR(30) | NOT NULL |
| kuota | INT | NOT NULL |

Constraint: `uq_jadwal_sesi UNIQUE (id_dokter, tanggal, jam_mulai)`,
`ck_jadwal_jam CHECK (jam_selesai > jam_mulai)`,
`ck_jadwal_kuota CHECK (kuota > 0)`.

**pasien**: identitas pasien.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_pasien | INT | PK, AUTO_INCREMENT |
| nama_pasien | VARCHAR(100) | NOT NULL |
| nik | CHAR(16) | NOT NULL, UNIQUE `uq_pasien_nik` |
| email | VARCHAR(100) | NULL, UNIQUE `uq_pasien_email` |
| no_telp | VARCHAR(20) | NULL |
| tanggal_lahir | DATE | NOT NULL |
| alamat | VARCHAR(200) | NULL |

**kunjungan**: pendaftaran pasien pada satu sesi jadwal.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_kunjungan | INT | PK, AUTO_INCREMENT |
| id_pasien | INT | FK ke `pasien`, NOT NULL |
| id_jadwal | INT | FK ke `jadwal_praktik`, NOT NULL |
| tanggal_kunjungan | DATE | NOT NULL |
| no_antrean | INT | NOT NULL |
| status_kunjungan | ENUM('Menunggu','Diperiksa','Selesai','Batal') | NOT NULL, DEFAULT 'Menunggu' |

Constraint: `uq_kunjungan_antrean UNIQUE (id_jadwal, no_antrean)`,
`uq_kunjungan_pasien UNIQUE (id_pasien, id_jadwal)`.

**rekam_medis**: hasil pemeriksaan, relasi 1:0..1 dari kunjungan.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_rekam | INT | PK, AUTO_INCREMENT |
| id_kunjungan | INT | FK ke `kunjungan`, NOT NULL, UNIQUE `uq_rekam_kunjungan` |
| keluhan | VARCHAR(200) | NOT NULL |
| diagnosis | VARCHAR(200) | NOT NULL |
| tekanan_darah | VARCHAR(15) | NULL |
| suhu | DECIMAL(4,1) | NULL, `ck_rekam_suhu` 30.0 sampai 45.0 |
| berat_badan | DECIMAL(5,1) | NULL, `ck_rekam_berat` 1.0 sampai 300.0 |
| tinggi_badan | DECIMAL(4,1) | NULL, `ck_rekam_tinggi` 30.0 sampai 250.0 |
| imt | DECIMAL(4,1) | GENERATED STORED, dihitung dari berat dan tinggi |
| tanggal_periksa | DATE | NOT NULL |

Rumus `imt`:

```sql
ROUND(berat_badan / ((tinggi_badan/100) * (tinggi_badan/100)), 1)
```

Karena nilainya selalu dihitung database, tidak ada kemungkinan angka tidak
konsisten seperti kalau diisi manual.

**tindakan**: master tindakan beserta tarif.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_tindakan | INT | PK, AUTO_INCREMENT |
| nama_tindakan | VARCHAR(80) | NOT NULL, UNIQUE `uq_tindakan_nama` |
| tarif | DECIMAL(10,2) | NOT NULL, `ck_tindakan_tarif` >= 0 |

**detail_tindakan**: penghubung M:N antara kunjungan dan tindakan.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_detail_tindakan | INT | PK, AUTO_INCREMENT |
| id_kunjungan | INT | FK ke `kunjungan`, NOT NULL |
| id_tindakan | INT | FK ke `tindakan`, NOT NULL |
| jumlah | INT | NOT NULL, DEFAULT 1, `ck_detail_tindakan_jumlah` > 0 |

Constraint: `uq_detail_tindakan UNIQUE (id_kunjungan, id_tindakan)`.

**obat**: master obat beserta sisa stok.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_obat | INT | PK, AUTO_INCREMENT |
| nama_obat | VARCHAR(80) | NOT NULL, UNIQUE `uq_obat_nama` |
| satuan | VARCHAR(20) | NOT NULL |
| harga | DECIMAL(10,2) | NOT NULL, `ck_obat_harga` >= 0 |
| stok | INT | NOT NULL, DEFAULT 0, `ck_obat_stok` >= 0 |

**detail_resep**: penghubung M:N antara rekam medis dan obat.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_detail_resep | INT | PK, AUTO_INCREMENT |
| id_rekam | INT | FK ke `rekam_medis`, NOT NULL |
| id_obat | INT | FK ke `obat`, NOT NULL |
| jumlah | INT | NOT NULL, `ck_detail_resep_jumlah` > 0 |
| aturan_pakai | VARCHAR(100) | NULL |

Constraint: `uq_detail_resep UNIQUE (id_rekam, id_obat)`.

**pembayaran**: tagihan satu kunjungan, relasi 1:0..1.

| Kolom | Tipe | Aturan |
|---|---|---|
| id_pembayaran | INT | PK, AUTO_INCREMENT |
| id_kunjungan | INT | FK ke `kunjungan`, NOT NULL, UNIQUE `uq_pembayaran_kunjungan` |
| tanggal_bayar | DATE | NULL |
| metode | ENUM('Tunai','Transfer','BPJS') | NOT NULL |
| total_tagihan | DECIMAL(12,2) | NOT NULL, `ck_pembayaran_total` >= 0 |
| status_bayar | ENUM('Lunas','Belum Lunas') | NOT NULL, DEFAULT 'Belum Lunas' |

### 5.3 Kunci tamu

Ada sepuluh kunci tamu. Semuanya memakai aturan yang sama: baris induk tidak
boleh dihapus selama masih dirujuk anak, tetapi perubahan kunci primer ikut
diperbarui di anak.

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

### 5.4 Objek bernama

Nama berikut tidak boleh diganti karena dipakai di skrip pengujian, panduan, dan
laporan.

| Jenis | Nama |
|---|---|
| View | `v_kunjungan_lengkap`, `v_pendapatan_poli` |
| Trigger | `trg_cek_kuota_jadwal`, `trg_cek_bentrok_jadwal`, `trg_cek_stok_obat`, `trg_kurangi_stok` |
| Prosedur | `sp_daftar_kunjungan`, `sp_bayar_kunjungan` |
| Pengguna | `petugas_klinik`, `dokter_klinik`, `admin_klinik` |
| Indeks | `idx_pasien_nama`, `idx_kunjungan_tanggal` |

## 6. Aturan Bisnis dan Penjaganya

Aturan bisnis adalah pernyataan tentang apa yang boleh dan tidak boleh terjadi.
Setiap aturan punya penjaga teknis, jadi bisa diperiksa mesin, bukan hanya diingat
orang. Kolom terakhir menyebut pengujian yang membuktikannya.

| No | Aturan | Penjaga | Bukti |
|---|---|---|---|
| 1 | Kuota jadwal tidak boleh terlampaui | `trg_cek_kuota_jadwal` | Uji 4 |
| 2 | Satu dokter tidak bisa punya dua jadwal beririsan pada tanggal yang sama | `trg_cek_bentrok_jadwal` | Uji 5 |
| 3 | Satu pasien hanya boleh terdaftar sekali pada satu sesi jadwal | `uq_kunjungan_pasien` | `verify.sh` bagian E |
| 4 | Resep hanya boleh dibuat setelah rekam medis ada | `fk_detail_resep_rekam` | skema |
| 5 | Satu kunjungan punya paling banyak satu baris pembayaran | `uq_pembayaran_kunjungan` | Uji 8 |
| 6 | Total tagihan adalah jumlah biaya tindakan ditambah harga obat | `sp_bayar_kunjungan` menghitung sendiri | Uji 7 |
| 7 | Stok obat berkurang otomatis saat resep disimpan | `trg_kurangi_stok` dan `trg_cek_stok_obat` | Uji 6 |
| 8 | Status kunjungan hanya salah satu dari empat nilai | `ENUM` | skema |

Aturan 1 dan 7 sering tertukar. Aturan 1 menjaga jumlah pasien per sesi,
sedangkan aturan 7 menjaga jumlah obat per resep. Keduanya bekerja pada tabel
berbeda.

## 7. Kebutuhan Informasi dan Query

Delapan kebutuhan informasi ditulis sebagai pertanyaan yang harus bisa dijawab
sistem. Rumusan pertanyaan lebih berguna daripada daftar fitur, karena setiap
pertanyaan langsung bisa diuji dengan query.

| No | Pertanyaan | Query |
|---|---|---|
| 1 | Pasien mana yang lahir sebelum 2005, diurutkan dari yang paling tua? | Q1 |
| 2 | Dokter mana bertugas di poli apa, dan poli itu di lantai berapa? | Q2 |
| 3 | Bagaimana riwayat kunjungan lengkap: pasien, dokter, poli, status? | Q3 |
| 4 | Berapa sisa kuota setiap jadwal praktik saat ini? | Q4 |
| 5 | Kunjungan mana yang tagihannya belum lunas? | Q5 |
| 6 | Pasien mana yang pernah dirujuk ke Poli Anak? | Q6 |
| 7 | Poli mana yang pendapatannya di atas rata-rata? | Q7 |
| 8 | Obat apa yang paling banyak keluar, dan dokter mana yang menangani kunjungan terbanyak? | Q8, Q10 |

Sepuluh query pada `bukti/kueri-panduan.sql` menjadi kontrak keluaran. Hasil
lengkapnya disimpan di `bukti/10-kueri.txt`.

| Query | Tujuan | Teknik | Acuan hasil |
|---|---|---|---|
| Q1 | Pasien lahir sebelum 2005 | `WHERE`, `ORDER BY` | 10 baris, tertua Gilang Ramadhan 1980-02-18 |
| Q2 | Dokter, poli, lantai | `JOIN` dua tabel | 6 dokter |
| Q3 | Riwayat kunjungan lengkap | `JOIN` lima tabel | 14 baris |
| Q4 | Sisa kuota per jadwal | `LEFT JOIN`, `COUNT`, `GROUP BY` | jadwal 7 sisa 0 |
| Q5 | Tagihan belum lunas | `JOIN`, `WHERE`, `ORDER BY` | 3 baris |
| Q6 | Pasien Poli Anak dan pasien tertua | subquery `IN`, subquery skalar | 2 pasien; Gilang Ramadhan |
| Q7 | Poli di atas rata-rata pendapatan | `GROUP BY`, `HAVING`, subquery | Poli Umum, Poli Gigi, Poli Penyakit Dalam |
| Q8 | Obat paling banyak keluar | `SUM`, `COUNT`, `LIMIT` | Amlodipine 5mg 60 tablet |
| Q9 | Kategori biaya kunjungan | `CASE` | 5 Ringan, 3 Sedang, 2 Berat |
| Q10 | Peringkat dokter | fungsi jendela `RANK()` | dr. Andi Pratama peringkat 1 |

Q9 tidak berasal langsung dari satu pertanyaan kebutuhan, tetapi dipakai untuk
melatih `CASE` dan membaca sebaran biaya.

## 8. Kontrak Objek Basis Data

### 8.1 View

**`v_kunjungan_lengkap`** menggabungkan kunjungan dengan pasien, dokter, poli,
jadwal, dan status pembayaran. Kolomnya: `id_kunjungan`, `tanggal_kunjungan`,
`no_antrean`, `status_kunjungan`, `id_pasien`, `nama_pasien`, `id_dokter`,
`nama_dokter`, `tipe_dokter`, `nama_poli`, `ruangan`, `jam_mulai`, `jam_selesai`,
`status_bayar`, `total_tagihan`. Status bayar memakai `COALESCE` sehingga
kunjungan tanpa tagihan tampil sebagai `Belum Ada Tagihan`. View ini harus
menghasilkan 14 baris pada data contoh.

**`v_pendapatan_poli`** meringkas pendapatan per poli per bulan. Kolomnya:
`nama_poli`, `bulan` (format `%Y-%m`), `jumlah_kunjungan`, `total_pendapatan`.
Hanya tagihan berstatus `Lunas` yang dihitung.

### 8.2 Trigger

| Nama | Waktu | Aturan yang dijaga | Pesan penolakan |
|---|---|---|---|
| `trg_cek_kuota_jadwal` | BEFORE INSERT pada kunjungan | Jumlah kunjungan tidak Batal harus kurang dari kuota | `Kuota jadwal sudah penuh` |
| `trg_cek_bentrok_jadwal` | BEFORE INSERT pada jadwal_praktik | Tidak ada rentang jam beririsan untuk dokter dan tanggal yang sama | `Jadwal dokter bentrok` |
| `trg_cek_stok_obat` | BEFORE INSERT pada detail_resep | Jumlah resep tidak melebihi stok | `Stok obat tidak cukup` |
| `trg_kurangi_stok` | AFTER INSERT pada detail_resep | Stok berkurang sebesar jumlah resep | tidak menghasilkan pesan |

Trigger kuota hanya memeriksa kunjungan berstatus selain `Batal`. Trigger
bentrok memakai perbandingan `jam_mulai < NEW.jam_selesai AND jam_selesai >
NEW.jam_mulai`.

### 8.3 Prosedur

**`sp_daftar_kunjungan(p_id_pasien, p_id_jadwal)`** mendaftarkan pasien ke satu
jadwal. Langkahnya:

1. Buka transaksi.
2. Ambil tanggal jadwal. Jika tidak ada, hentikan dengan pesan
   `Jadwal tidak ditemukan`.
3. Tolak jadwal yang tanggalnya sudah lewat dengan pesan
   `Jadwal sudah lewat, tidak bisa didaftari`.
4. Hitung nomor antrean berikutnya dengan `COALESCE(MAX(no_antrean), 0) + 1`.
5. Simpan kunjungan berstatus `Menunggu`, lalu `COMMIT`.
6. Kembalikan `id_kunjungan_baru` dan `no_antrean`.

Penjagaan kuota diserahkan ke `trg_cek_kuota_jadwal`, bukan diulang di prosedur.

**`sp_bayar_kunjungan(p_id_kunjungan, p_metode)`** menghitung tagihan lalu
menyimpan pembayaran. Langkahnya:

1. Buka transaksi.
2. Tolak kunjungan yang sudah punya baris pembayaran dengan pesan
   `Kunjungan sudah dibayar`.
3. Hitung total dari `SUM(detail_tindakan.jumlah * tindakan.tarif)` ditambah
   `SUM(detail_resep.jumlah * obat.harga)`.
4. Simpan baris pembayaran berstatus `Lunas` dan tanggal `CURDATE()`.
5. `COMMIT`, lalu kembalikan `total_dibayar`.

Kedua prosedur memakai `EXIT HANDLER FOR SQLEXCEPTION` yang menjalankan
`ROLLBACK` dan `RESIGNAL`, sehingga tidak ada perubahan setengah jadi.

### 8.4 Hak Akses

| Pengguna | Hak | Alasan |
|---|---|---|
| `petugas_klinik` | SELECT pada poli, dokter, jadwal_praktik; SELECT dan INSERT pada pasien, kunjungan | Meja depan melihat jadwal dan mendaftarkan pasien, tetapi tidak boleh membuka rekam medis atau pembayaran |
| `dokter_klinik` | SELECT pada semua tabel; INSERT dan UPDATE pada rekam_medis, detail_resep | Dokter membaca riwayat, lalu menulis hasil pemeriksaan dan resep |
| `admin_klinik` | ALL PRIVILEGES pada `klinik_pratama.*` | Pengelola sistem memerlukan hak penuh untuk pemeliharaan |

Ketiganya memakai kata sandi `Klinik#2026`. Percobaan `INSERT` ke tabel `obat`
memakai akun petugas harus ditolak dengan `ERROR 1142`.

### 8.5 Indeks

| Nama | Tabel | Kolom | Query yang dilayani |
|---|---|---|---|
| `idx_pasien_nama` | pasien | nama_pasien | `WHERE nama_pasien LIKE 'A%'` |
| `idx_kunjungan_tanggal` | kunjungan | tanggal_kunjungan, id_jadwal | `WHERE tanggal_kunjungan = '2026-09-10'` |

Setiap indeks dibuktikan dengan `EXPLAIN` sebelum dan sesudah pembuatan. Sebelum
indeks, kolom `key` berisi `NULL` dan `type` bernilai `ALL`. Sesudah indeks,
`key` berisi nama indeks dan jumlah baris yang diperiksa turun. Pada tabel berisi
sepuluh sampai empat belas baris, pemindaian penuh masih cepat; perbedaan rencana
eksekusi tetap relevan karena menunjukkan cara kerja optimizer.

## 9. Data Contoh

Data contoh dirancang memenuhi syarat minimal lima baris per tabel sekaligus
menyediakan keadaan yang dibutuhkan pengujian.

| Tabel | Jumlah baris |
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

Keadaan khusus yang harus tetap ada:

- Jadwal nomor 7 berkuota empat dan terisi penuh, sehingga sisa kuota 0.
- Obat nomor 8 berstok lima, dipakai Uji 6.
- Dua kunjungan berstatus `Batal`, dua berstatus `Menunggu`.
- Tiga pembayaran berstatus `Belum Lunas`.

Seluruh tanggal data contoh berada pada Agustus sampai Oktober 2026. Angka ini
tidak diubah tanpa memperbarui tabel hasil di panduan dan berkas `bukti/`.

## 10. Urutan Pemuatan dan Idempotensi

Skrip dijalankan berurutan karena kunci tamu menuntut tabel induk sudah ada.

```text
01_struktur.sql      membuat database dan sebelas tabel
02_data.sql          mengisi data contoh
03_view_trigger.sql  dua view dan empat trigger
04_prosedur.sql      dua stored procedure
05_keamanan.sql      tiga pengguna dan hak akses
06_indeks.sql        dua indeks beserta EXPLAIN
07_pengujian.sql     sepuluh skenario, dijalankan terpisah
```

`reset-db.sh` menjalankan 01 sampai 06 dari database kosong. `07_pengujian.sql`
tidak dimuat oleh `reset-db.sh` karena berisi pernyataan yang sengaja gagal dan
blok pembersihan data uji.

Skrip harus bisa dijalankan ulang. `01_struktur.sql` memakai
`DROP TABLE IF EXISTS` dari anak ke induk. `03` dan `04` memakai
`DROP ... IF EXISTS`. `05` memakai `DROP USER IF EXISTS`. `06` membuang indeks
lebih dulu jika sudah ada. `02_data.sql` mengisi tabel yang baru dibuat, jadi
tidak menimbulkan duplikasi setelah reset.

## 11. Kriteria Penerimaan

Pekerjaan dinyatakan selesai jika seluruh butir berikut terbukti, bukan hanya
dicentang.

1. `bash tools/reset-db.sh` berhasil dari database kosong dan melaporkan
   `tabel terdaftar: 11`.
2. `bash tools/verify.sh` berakhir dengan `Lulus: 34   Gagal: 0`.
3. Setiap tabel berisi minimal lima baris dan tidak ada kunci tamu yatim.
4. Sepuluh query berjalan dan hasilnya sama dengan `bukti/10-kueri.txt`.
5. Dua view menampilkan data yang benar.
6. Empat trigger menolak data yang melanggar aturan bisnis.
7. Kedua prosedur berjalan; pemanggilan pembayaran kedua ditolak.
8. Tiga pengguna ada dan percobaan menulis oleh petugas ditolak 1142.
9. Dua indeks terpasang dan dipakai optimizer pada hasil `EXPLAIN`.
10. `bukti/` memuat keluaran setiap skrip.
11. PDF panduan dan laporan terbangun tanpa rujukan menggantung.
12. Video setiap anggota sudah diunggah dan tautannya bisa dibuka.

## 12. Keputusan yang Dicatat

Empat keputusan berikut ditulis di laporan supaya tidak dianggap kelalaian.

- **Atribut turunan.** `imt` tetap ada sebagai generated column. Nilainya selalu
  dihitung database, sehingga bentuk normal dipertahankan dari sisi kebenaran
  data.
- **Spesialisasi dokter.** Model extended ER menggambarkan dokter umum dan
  spesialis sebagai subentitas. Implementasinya memakai satu tabel dengan kolom
  `tipe_dokter`, karena atribut tambahan masih sedikit. Jika nanti spesialis
  memerlukan belasan atribut sendiri, tabel terpisah baru masuk akal.
- **Hari tidak disimpan.** Menyimpan hari bersama tanggal akan menduplikasi
  informasi dan membuka kemungkinan keduanya bertentangan. Nilai hari diambil
  saat query dengan `DAYNAME(tanggal)`.
- **NoSQL hanya perbandingan.** Materi minggu 15 dinilai lewat pemetaan struktur
  relasional ke dokumen JSON, bukan pembangunan server NoSQL.
