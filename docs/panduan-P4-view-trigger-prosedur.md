# Panduan P4: View, Trigger, Prosedur, Keamanan, dan Indeks

## Peran

Kamu adalah Anggota 4. Kamu menulis empat berkas yang membuat database bukan
hanya menyimpan data, tetapi juga menjaga aturan, menghitung tagihan, membatasi
akses, dan mempercepat pencarian. Pekerjaanmu paling banyak berkasnya, jadi
jangan menumpuk semuanya di minggu terakhir.

Kamu juga pemeriksa pertama skema buatan Anggota 3. Sebelum menulis view atau
trigger, pastikan nama tabel dan kolom di `sql/01_struktur.sql` sudah sesuai PRD.

## Berkas Milik

| Berkas | Isi |
|---|---|
| `sql/03_view_trigger.sql` | Dua view dan empat trigger |
| `sql/04_prosedur.sql` | Dua stored procedure |
| `sql/05_keamanan.sql` | Tiga pengguna dan hak akses |
| `sql/06_indeks.sql` | Dua indeks beserta EXPLAIN sebelum dan sesudah |
| Bahan Bab II | Penjelasan objek, pesan galat, dan tabel rencana eksekusi |

Skema bukan milikmu. Kalau butuh kolom baru untuk trigger atau indeks, kirim
usulan ke P3. Jangan menambah kolom lewat `ALTER TABLE` di berkas 03 sampai 06.

## Konteks untuk AI

Proyek ini memakai MySQL 8.0, database `klinik_pratama`, dan skema sebelas tabel
pada `sql/01_struktur.sql`. Sebagai P4 kamu menulis view, trigger, prosedur, hak
akses, dan indeks. Semua nama objek sudah ditetapkan dan tidak boleh diganti.

Nama yang wajib dipakai:

- View: `v_kunjungan_lengkap`, `v_pendapatan_poli`.
- Trigger: `trg_cek_kuota_jadwal`, `trg_cek_bentrok_jadwal`,
  `trg_cek_stok_obat`, `trg_kurangi_stok`.
- Prosedur: `sp_daftar_kunjungan(p_id_pasien, p_id_jadwal)`,
  `sp_bayar_kunjungan(p_id_kunjungan, p_metode)`.
- Pengguna: `petugas_klinik`, `dokter_klinik`, `admin_klinik`, kata sandi
  `Klinik#2026`.
- Indeks: `idx_pasien_nama`, `idx_kunjungan_tanggal`.

Pesan galat yang diuji lewat `SIGNAL SQLSTATE '45000'` harus sama persis:
`Kuota jadwal sudah penuh`, `Jadwal dokter bentrok`, `Stok obat tidak cukup`,
`Jadwal tidak ditemukan`, `Jadwal sudah lewat, tidak bisa didaftari`,
`Kunjungan sudah dibayar`.

Jangan memakai `FOREIGN_KEY_CHECKS=0`, jangan mengganti `DELIMITER` di luar
klien `mysql`, dan jangan menambah trigger baru yang tidak diminta.

## Milestone 1: Dua View

### 1.1 `v_kunjungan_lengkap`

View ini menggabungkan kunjungan dengan pasien, jadwal, dokter, poli, dan status
pembayaran. Kolom yang dihasilkan:

```text
id_kunjungan, tanggal_kunjungan, no_antrean, status_kunjungan,
id_pasien, nama_pasien, id_dokter, nama_dokter, tipe_dokter,
nama_poli, ruangan, jam_mulai, jam_selesai, status_bayar, total_tagihan
```

Gunakan `LEFT JOIN pembayaran` dan `COALESCE(b.status_bayar, 'Belum Ada
Tagihan')` supaya kunjungan tanpa tagihan tetap muncul. Pada data contoh, view
harus menghasilkan 14 baris.

View ini contoh kemandirian data logis. Kalau struktur tabel berubah, view yang
disesuaikan; laporan yang membaca view tidak perlu diubah.

### 1.2 `v_pendapatan_poli`

View ini meringkas pendapatan per poli per bulan. Kolomnya: `nama_poli`, `bulan`
(format `%Y-%m`), `jumlah_kunjungan`, `total_pendapatan`. Hanya baris dengan
`status_bayar = 'Lunas'` yang dihitung, supaya angka pendapatan tidak tercampur
piutang.

### 1.3 Periksa

```sql
SELECT * FROM v_kunjungan_lengkap LIMIT 5;
SELECT * FROM v_pendapatan_poli;
```

`verify.sh` bagian C memeriksa jumlah baris view. Kalau jumlahnya bukan 14,
periksa join dan data contoh lebih dulu sebelum mengubah view.

## Milestone 2: Empat Trigger

Trigger harus dibuat setelah view. `DELIMITER //` hanya berlaku di klien
`mysql`, bukan bagian dari perintah SQL.

### 2.1 `trg_cek_kuota_jadwal`

Waktu: `BEFORE INSERT` pada `kunjungan`. Ambil kuota jadwal, hitung kunjungan
yang statusnya bukan `Batal`, lalu tolak jika jumlahnya sudah mencapai kuota.

```sql
IF v_terpakai >= v_kuota THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kuota jadwal sudah penuh';
END IF;
```

Uji 4 memakai jadwal 7 yang berkuota 4 dan sudah terisi 4. Pendaftaran kelima
harus ditolak.

### 2.2 `trg_cek_bentrok_jadwal`

Waktu: `BEFORE INSERT` pada `jadwal_praktik`. Periksa jadwal lain milik dokter
yang sama pada tanggal yang sama dengan rentang jam beririsan:

```sql
WHERE id_dokter = NEW.id_dokter
  AND tanggal = NEW.tanggal
  AND jam_mulai < NEW.jam_selesai
  AND jam_selesai > NEW.jam_mulai
```

Jika ada, kirim `Jadwal dokter bentrok`. Uji 5 memakai dokter 1 yang sudah
praktik 08.00 sampai 12.00, lalu mencoba jadwal 10.00 sampai 11.00.

### 2.3 `trg_cek_stok_obat`

Waktu: `BEFORE INSERT` pada `detail_resep`. Bandingkan stok obat dengan
`NEW.jumlah`. Jika stok lebih kecil, kirim `Stok obat tidak cukup`. Uji 6 memakai
obat 8 yang berstok 5 dan resep 99 botol.

### 2.4 `trg_kurangi_stok`

Waktu: `AFTER INSERT` pada `detail_resep`. Kurangi stok obat:

```sql
UPDATE obat SET stok = stok - NEW.jumlah WHERE id_obat = NEW.id_obat;
```

Urutan penting. Pemeriksaan stok berjalan `BEFORE`, pengurangan berjalan
`AFTER`. Kalau dibalik, stok sudah berkurang sebelum diperiksa dan pesan galat
tidak lagi bisa diandalkan.

### 2.5 Periksa

`verify.sh` bagian E menjalankan enam masukan salah dan memastikan semuanya
ditolak. Trigger kuota dan bentrok memakai `SIGNAL`, sehingga pesan yang dicari
adalah teks pesannya, bukan nomor galat.

## Milestone 3: Dua Prosedur

### 3.1 `sp_daftar_kunjungan`

Langkah:

1. `START TRANSACTION`.
2. Ambil tanggal jadwal. Jika `NULL`, kirim `Jadwal tidak ditemukan`.
3. Jika tanggal sudah lewat dari `CURDATE()`, kirim
   `Jadwal sudah lewat, tidak bisa didaftari`.
4. Hitung antrean: `COALESCE(MAX(no_antrean), 0) + 1` untuk jadwal itu.
5. `INSERT` kunjungan berstatus `Menunggu`.
6. `COMMIT`.
7. Kembalikan `id_kunjungan_baru` dan `no_antrean`.

Kuota tidak diperiksa di sini karena sudah dijaga trigger. Menulis pemeriksaan
yang sama di dua tempat membuat pesan galat berbeda dan sulit diuji.

### 3.2 `sp_bayar_kunjungan`

Langkah:

1. `START TRANSACTION`.
2. Hitung `COUNT(*)` pembayaran untuk kunjungan. Jika lebih dari nol, kirim
   `Kunjungan sudah dibayar`.
3. Hitung total dari tindakan ditambah obat:

   ```text
   SUM(detail_tindakan.jumlah * tindakan.tarif)
   +
   SUM(detail_resep.jumlah * obat.harga)
   ```

4. `INSERT` pembayaran dengan `CURDATE()`, metode dari parameter, status
   `Lunas`.
5. `COMMIT`.
6. Kembalikan `total_dibayar`.

Kedua prosedur memakai `EXIT HANDLER FOR SQLEXCEPTION` yang menjalankan
`ROLLBACK` dan `RESIGNAL`. Ini yang membuat sifat atomicity bisa dibuktikan:
jika salah satu langkah gagal, tidak ada baris setengah jadi.

### 3.3 Periksa

Uji 7 mendaftarkan pasien pada jadwal Desember 2026, menambah satu tindakan dan
satu resep, lalu membayar. Total yang diharapkan 155.000, dari 150.000 biaya
pembersihan karang gigi ditambah 5.000 harga sepuluh tablet Paracetamol.

Pemanggilan kedua harus ditolak `Kunjungan sudah dibayar`.

## Milestone 4: Hak Akses

Tiga pengguna dengan kata sandi `Klinik#2026`.

| Pengguna | Hak | Alasan |
|---|---|---|
| `petugas_klinik` | SELECT pada poli, dokter, jadwal_praktik; SELECT dan INSERT pada pasien, kunjungan | Meja depan melihat jadwal dan mendaftarkan pasien, tetapi tidak membuka rekam medis atau pembayaran |
| `dokter_klinik` | SELECT pada semua tabel; INSERT dan UPDATE pada rekam_medis, detail_resep | Dokter membaca riwayat, lalu menulis hasil pemeriksaan dan resep |
| `admin_klinik` | ALL PRIVILEGES pada `klinik_pratama.*` | Pengelola sistem memerlukan hak penuh |

Skrip memakai `DROP USER IF EXISTS` agar bisa dijalankan ulang, lalu
`FLUSH PRIVILEGES`, lalu `SHOW GRANTS` sebagai bukti.

Bukti penolakan diambil dengan koneksi memakai akun petugas:

```bash
docker exec -i kbd-mysql mysql -upetugas_klinik -p'Klinik#2026' klinik_pratama \
  -e "INSERT INTO obat (nama_obat,satuan,harga,stok) VALUES ('Uji Ilegal','Tablet',1000.00,1);"
```

Keluaran yang benar:

```text
ERROR 1142 (42000): INSERT command denied to user 'petugas_klinik'@'localhost' for table 'obat'
```

`verify.sh` bagian F memeriksa `SHOW GRANTS` dan penolakan ini.

## Milestone 5: Dua Indeks

### 5.1 `idx_pasien_nama`

```sql
EXPLAIN SELECT * FROM pasien WHERE nama_pasien LIKE 'A%';
CREATE INDEX idx_pasien_nama ON pasien (nama_pasien);
EXPLAIN SELECT * FROM pasien WHERE nama_pasien LIKE 'A%';
```

| Keadaan | type | key | rows |
|---|---|---|---|
| Sebelum | ALL | NULL | 10 |
| Sesudah | range | idx_pasien_nama | 1 |

### 5.2 `idx_kunjungan_tanggal`

Indeks gabungan `(tanggal_kunjungan, id_jadwal)`. Kolom tanggal diletakkan lebih
dulu karena dipakai sendirian pada penyaringan; kolom kedua berguna saat laporan
menyaring tanggal sekaligus jadwal.

| Keadaan | type | key | rows |
|---|---|---|---|
| Sebelum | ALL | NULL | 14 |
| Sesudah | ref | idx_kunjungan_tanggal | 3 |

### 5.3 Skrip harus bisa diulang

`06_indeks.sql` membuang indeks lebih dulu jika sudah ada, memakai
`information_schema.statistics` dan `PREPARE`. Tanpa ini, menjalankan
`reset-db.sh` dua kali akan gagal karena nama indeks sudah dipakai.

`verify.sh` bagian D membaca kolom `key` dari `EXPLAIN`. Jika isinya masih
`NULL`, indeks tidak dipakai optimizer dan pemeriksaan gagal.

## Milestone 6: Transaksi dan Isolasi

Kamu menulis prosedur yang membuktikan ACID. Demo isolasi dijalankan P5 atau
kamu sendiri memakai `tools/demo-isolasi.sh`.

- **Atomicity.** Total dihitung dan pembayaran disimpan dalam satu transaksi.
- **Consistency.** Pemeriksaan pembayaran ganda berjalan sebelum insert.
- **Isolation.** Sesi lain tidak melihat baris sebelum `COMMIT`.
- **Durability.** Setelah `COMMIT`, baris tetap ada walaupun koneksi putus.

Demo membandingkan dua tingkat isolasi:

```text
READ COMMITTED
Stok awal obat 1: 200
A membaca pertama kali  : 200
A membaca setelah B commit: 195
B mengubah stok menjadi  : 195

REPEATABLE READ
Stok obat 1 sebelum percobaan: 195
A membaca pertama kali  : 195
A membaca setelah B commit: 195
B mengubah stok menjadi  : 190
```

Pada `REPEATABLE READ`, semua bacaan dalam satu transaksi memakai gambaran data
yang sama sejak transaksi dimulai. Ini tingkat bawaan MySQL.

Deadlock muncul saat dua sesi mengunci baris dengan urutan berlawanan. InnoDB
memilih satu transaksi sebagai korban:

```text
ERROR 1213 (40001): Deadlock found when trying to get lock;
try restarting transaction
```

Galat ini bukan kerusakan. Penanganan yang benar adalah mengulang transaksi
sekali atau dua kali.

## Checklist

- [ ] Dua view ada dengan nama yang ditetapkan dan menghasilkan data benar.
- [ ] `v_kunjungan_lengkap` menghasilkan 14 baris.
- [ ] Empat trigger ada, urutan BEFORE dan AFTER benar.
- [ ] Pesan galat trigger sama persis dengan yang diuji.
- [ ] Dua prosedur memakai transaksi dan `EXIT HANDLER`.
- [ ] Pembayaran kedua ditolak.
- [ ] Tiga pengguna ada; penolakan 1142 terbukti.
- [ ] Dua indeks ada dan dipakai optimizer pada `EXPLAIN`.
- [ ] Skrip 03 sampai 06 bisa dijalankan ulang.
- [ ] `verify.sh` bagian C, D, dan F lulus.
- [ ] Bahan Bab II memuat tabel rencana eksekusi dan potongan `SHOW GRANTS`.

## Kesalahan yang Sering Terjadi

1. Membuat trigger sebelum view selesai, lalu nama kolom view berubah.
2. Memakai `AFTER INSERT` untuk pemeriksaan stok, sehingga data sudah masuk
   sebelum ditolak.
3. Menulis `DELIMITER` di dalam berkas yang dijalankan lewat `mysql -e`; opsi
   itu hanya dikenal klien interaktif.
4. Memberi `GRANT ALL` kepada petugas agar tidak muncul galat, lalu pemeriksaan
   hak akses gagal.
5. Membuat indeks tanpa `EXPLAIN` sebelum, sehingga tidak ada bukti pengaruhnya.
6. Menjalankan `06_indeks.sql` dua kali tanpa membuang indeks lebih dulu.
7. Mengubah urutan kolom indeks gabungan tanpa memahami query yang dilayani.

## Prompt Siap Tempel

```text
Saya Anggota 4. Saya sedang menulis sql/03_view_trigger.sql dan
sql/04_prosedur.sql. Berikut aturan umum proyek, skema, dan potongan berkas saya.

Periksa: (1) setiap nama tabel dan kolom yang dipakai ada di skema, (2) trigger
stok memakai BEFORE untuk memeriksa dan AFTER untuk mengurangi, (3) prosedur
memakai START TRANSACTION dan EXIT HANDLER ROLLBACK. Sebutkan baris yang salah.
Jangan mengganti nama objek dan jangan menambah trigger baru.
```

## Definition of Done

Fase P4 selesai jika dua view, empat trigger, dua prosedur, tiga pengguna, dan
dua indeks berjalan dengan nama yang ditetapkan; `verify.sh` bagian C, D, dan F
lulus; serta bukti `SHOW GRANTS`, penolakan 1142, dan `EXPLAIN` sudah disimpan
untuk laporan.
