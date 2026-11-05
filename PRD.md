# PRODUCT REQUIREMENTS DOCUMENT (PRD)
# RUJAK.IN.SIAK POS

### Cafe Management System — Offline-First

| Informasi | Detail |
|---|---|
| Versi | **1.6** |
| Tanggal revisi | 5 November 2026 |
| Status | Approved Product Baseline |
| Frontend | Flutter |
| Backend | Laravel 13 |
| Programming Language | Dart / PHP |
| Database Server | MySQL |
| Local Database | SQLite + Drift |
| Platform MVP | Android |
| Printer | Bluetooth Thermal ESC/POS |
| Architecture | Modular Monolith + Offline-First |
| Target Awal | Rujak In Siak |
| Target Jangka Panjang | Multi-outlet dan SaaS |

**Riwayat dokumen**

| Versi | Perubahan |
|---|---|
| 1.0 | Rancangan produk awal |
| 1.1 | Koreksi arsitektur, transaksi, dan offline |
| 1.2 | Penetapan teknologi |
| 1.3 | Perincian mekanisme offline, shift, dan sinkronisasi |
| 1.4 | Penyempurnaan verifikasi pembayaran, void, dan order lintas perangkat |
| 1.5 | Pemisahan tegas lifecycle sale dan status pembayaran; aturan selisih nominal verifikasi non-tunai |
| 1.6 | Penggunaan template Horizon sebagai baseline UI web admin Laravel |

---

# 1. EXECUTIVE SUMMARY

## 1.1 Latar Belakang

RUJAK.IN.SIAK POS merupakan aplikasi Point of Sale dan Cafe Management System untuk mengelola aktivitas bisnis cafe dan UMKM kuliner.

Sistem mengintegrasikan transaksi penjualan, pembayaran, pencetakan struk, manajemen karyawan, pengelolaan shift, persediaan, pembelian, keuangan, dan analisis performa usaha.

Sistem menerapkan pendekatan Offline-First agar transaksi tetap dapat dilakukan ketika koneksi internet tidak tersedia.

## 1.2 Visi Produk

Membangun sistem manajemen usaha kuliner yang modern, mudah digunakan, akurat, transparan, dan dapat dikembangkan menjadi produk POS komersial untuk berbagai jenis UMKM.

## 1.3 Tujuan Produk

1. Digitalisasi transaksi penjualan.
2. Mempercepat pelayanan pelanggan.
3. Mengurangi kesalahan pencatatan.
4. Mengontrol pendapatan dan pengeluaran.
5. Mengawasi aktivitas kasir.
6. Mengelola stok bahan baku.
7. Menghitung HPP dan keuntungan produk.
8. Menyediakan laporan bisnis.
9. Memastikan kasir tetap dapat beroperasi tanpa internet.
10. Mempersiapkan ekspansi ke banyak outlet.

---

# 2. TECHNOLOGY STACK

## 2.1 Teknologi Utama

| Komponen | Teknologi |
|---|---|
| Frontend | Flutter Stable |
| Language | Dart Stable |
| Backend | Laravel 13 |
| PHP Runtime | PHP 8.5 |
| Database Server | MySQL 9.7 LTS |
| Local Database | SQLite |
| Local ORM | Drift |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP Client | Dio |
| Secure Storage | Flutter Secure Storage |
| Printer | Bluetooth Thermal ESC/POS |
| Admin Web UI | Horizon React sebagai referensi visual; adaptasi ke Laravel Blade + Tailwind |
| Server OS | Ubuntu Server 26.04 LTS |
| Web Server | Nginx |

### Catatan penguncian versi

Pemilihan major version merupakan baseline teknologi. Nomor patch framework, runtime, dan package pendukung bersifat sementara sampai Phase 0.

Sebelum implementasi:

- Periksa rilis stable terbaru.
- Periksa kompatibilitas antar-framework.
- Lakukan proof of concept.
- Catat versi final.
- Commit `pubspec.lock` dan `composer.lock`.
- Dokumentasikan keputusan melalui Technology Decision Record.

Jangan menggunakan beta atau nightly untuk production.

### Template web admin

Template pada `Template/horizon-react-v1.0.0/Downloads/horizon-tailwind-react` adalah template dashboard React dan Tailwind CSS, dengan struktur aplikasi Create React App (`react-scripts`). Template ini **tidak dapat dipasang langsung sebagai view Laravel Blade**.

Keputusan baseline:

- Horizon digunakan sebagai referensi layout, komponen dashboard, tabel, form, navigasi, dan aset untuk web back-office Owner/Admin.
- Web back-office menjadi antarmuka administrasi tambahan; aplikasi Flutter Android tetap menjadi aplikasi POS utama dan tidak digantikan oleh template ini.
- Integrasi awal yang dipilih adalah mengadaptasi UI template menjadi Laravel Blade dan Tailwind CSS dalam aplikasi Laravel. Jangan menyalin JSX seolah-olah merupakan Blade.
- Data dan aksi pada halaman admin harus menggunakan route, policy, service/action, dan data aktual Laravel. Data contoh/demo dari template tidak boleh dipakai pada production.
- Pertahankan file dan pemberitahuan lisensi MIT Horizon dalam distribusi kode yang menggunakan bagian template.
- Lakukan proof of concept pada Phase 0 untuk memeriksa build asset, layout Blade, komponen yang perlu ditulis ulang, dan aksesibilitas/responsiveness sebelum memperluas halaman admin.
- Jika mempertahankan komponen React asli lebih efektif, opsi Laravel + Inertia React atau React SPA terpisah harus diputuskan melalui ADR. Opsi tersebut tidak menjadi keputusan default karena menambah frontend runtime dan pola integrasi di luar Flutter.

## 2.2 Backend

Laravel digunakan untuk:

- REST API.
- Authentication.
- Authorization.
- Transaction Processing.
- Payment Management.
- Shift Management.
- Synchronization.
- Reporting.
- Audit Logging.

Gunakan Laravel Sanctum untuk autentikasi token dan Laravel Policies untuk authorization.

## 2.3 Database

**MySQL**

Menjadi sumber data pusat untuk seluruh transaksi dan data bisnis yang telah tersinkronisasi.

**SQLite + Drift**

Menjadi penyimpanan operasional lokal pada perangkat Flutter.

Data lokal dan server memiliki tanggung jawab yang berbeda. SQLite tidak boleh diperlakukan sebagai database pusat kedua yang bebas menimpa perubahan server.

## 2.4 Arsitektur Backend

Gunakan Modular Monolith.

Microservices tidak menjadi kebutuhan MVP karena kompleksitas deployment dan konsistensi data belum sebanding dengan kebutuhan bisnis.

Redis tidak diwajibkan pada MVP. Database queue Laravel dapat digunakan terlebih dahulu.

---

# 3. PRODUCT SCOPE DAN BATAS MVP

## 3.1 Pengguna

| Role | Hak akses |
|---|---|
| Owner | Seluruh data dan konfigurasi bisnis |
| Admin | Pengelolaan operasional dan master data |
| Supervisor | Monitoring dan persetujuan tindakan sensitif |
| Kasir | POS, pembayaran, shift, dan struk |

Role dan permission harus divalidasi pada backend.

## 3.2 MVP Phase A — Core Sales

1. Authentication.
2. User management.
3. Device registration.
4. Product management.
5. Category management.
6. POS.
7. Cart dan hold order.
8. Checkout.
9. Payment management.
10. Thermal printer.
11. Transaction history.
12. Shift management.
13. Audit log.

## 3.3 MVP Phase B — Offline Transaction

1. SQLite local database.
2. Offline authorization lease.
3. Local product catalog.
4. Local order.
5. Local checkout.
6. Transactional outbox.
7. Background synchronization.
8. Manual synchronization.
9. Idempotency.
10. Conflict handling.
11. Local shift closing.

## 3.4 MVP Phase C — Reporting

1. Dashboard penjualan.
2. Penjualan per periode.
3. Rekap transaksi.
4. Rekap pembayaran.
5. Rekap diskon.
6. Rekap refund.
7. Rekap shift.
8. Export Excel/PDF.

## 3.5 Di Luar MVP

- Inventory management.
- Recipe management.
- HPP.
- Profitability analysis.
- Pengeluaran operasional.
- Laporan laba bersih.
- Purchasing.
- Supplier management.
- Customer loyalty.
- Kitchen Display System.
- QR self ordering.
- AI Assistant.
- Sales forecasting.
- Multi-outlet aktif.
- Web back-office Laravel berbasis Horizon; menjadi antarmuka tambahan setelah proof of concept dan penetapan fase implementasi. MVP POS tetap berfokus pada Flutter Android.

Fitur yang belum dikembangkan tidak boleh menampilkan angka seolah-olah berasal dari data aktual.

---

# 4. FUNCTIONAL REQUIREMENTS

## MODULE 01 — AUTHENTICATION & USER MANAGEMENT

### Fitur

- Login username/email dan password.
- Logout.
- Token management.
- Token refresh.
- PIN kasir.
- User management.
- Role dan permission.
- Device registration.
- Login history.
- Session management.
- Device revocation.

### Aturan offline

1. Login pertama harus online.
2. Perangkat harus terdaftar.
3. Pengguna harus memiliki otorisasi offline yang valid.
4. PIN lokal digunakan untuk membuka sesi pengguna yang sebelumnya sudah terdaftar.
5. Pengguna baru tidak dapat login ketika offline.
6. Perubahan permission berlaku setelah perangkat menerima sinkronisasi.
7. Sistem tidak boleh mengklaim bahwa akun offline sudah divalidasi server secara real-time.

### Offline Authorization Lease

Server memberikan signed authorization lease kepada perangkat.

Isi lease:

- User ID.
- Device ID.
- Business ID.
- Outlet ID.
- Role.
- Permission snapshot.
- Issued at.
- Expiration time.
- Authentication version.

**Masa berlaku maksimal: 72 jam sejak autentikasi online terakhir yang berhasil.**

Ketentuan:

- Lease dapat diperbarui saat perangkat online.
- Setelah lease kedaluwarsa, transaksi baru tidak dapat dibuat secara offline.
- Data lokal yang sudah tersimpan tetap dapat dibaca.
- Pending transaction tetap boleh disinkronisasi menggunakan identitas perangkat dan bukti lease yang valid.
- Pengguna harus online untuk memperoleh otorisasi baru.
- Pencabutan akun pada server akan berlaku pada perangkat setelah informasi pencabutan diterima.
- Perangkat yang belum menerima pencabutan tidak dapat mengklaim status otorisasinya sudah diperbarui.

### Perlindungan perangkat

- Database lokal dilindungi dengan enkripsi at-rest melalui implementasi yang telah diuji.
- Kunci enkripsi disimpan menggunakan Android Keystore.
- Token tidak disimpan sebagai plaintext di database lokal.
- Terapkan screen lock aplikasi.
- Perubahan jam perangkat lebih dari toleransi lima menit terhadap waktu tepercaya terakhir membuat waktu lokal ditandai tidak tepercaya.
- Owner dapat melakukan device revocation.
- Data offline yang belum tersinkronisasi tidak dapat dijamin pulih apabila perangkat hilang atau rusak.

---

## MODULE 02 — PRODUCT & CATEGORY MANAGEMENT

### Data produk

- Product ID.
- SKU.
- Nama produk.
- Kategori.
- Deskripsi.
- Harga jual.
- Foto.
- Barcode.
- Satuan.
- Status aktif.
- Status tersedia/habis.
- Varian.
- Add-on.
- Harga tambahan.
- Pajak produk.

### Fitur

- CRUD produk.
- CRUD kategori.
- Search.
- Filter.
- Import Excel.
- Export Excel.
- Pengaturan harga.
- Pengaturan ketersediaan.
- Varian dan topping.

### Aturan

1. Produk nonaktif tidak muncul pada POS.
2. Perubahan harga tidak mengubah transaksi historis.
3. Setiap sale menyimpan snapshot harga dan deskripsi produk.
4. Perubahan master data memerlukan koneksi server.
5. POS offline menggunakan katalog terakhir yang berhasil diunduh.
6. Katalog yang melewati 24 jam menampilkan peringatan.
7. Katalog yang lebih dari 72 jam tidak diperbarui memblokir checkout offline secara default.

Status tersedia/habis merupakan pengaturan manual pada MVP, bukan perhitungan otomatis stok.

---

## MODULE 03 — ORDER MANAGEMENT

### Tujuan

Memisahkan pesanan operasional dengan penjualan finansial.

### Entitas Order

Order digunakan untuk mencatat pesanan yang masih dalam proses.

Status:

- Draft.
- Held.
- Resumed.
- Converted.
- Cancelled.

### Fitur

- Membuat order.
- Menyimpan draft.
- Hold order.
- Resume order.
- Mengubah kuantitas.
- Mengubah catatan.
- Membatalkan order.
- Menentukan tipe pesanan.
- Menentukan meja.

### Aturan

1. Draft dan Held belum dianggap sebagai penjualan.
2. Draft dan Held tidak masuk laporan omzet.
3. Draft dan Held tidak memengaruhi laporan pembayaran.
4. Draft dan Held tidak mengurangi stok.
5. Checkout mengubah order menjadi Converted.
6. Satu order hanya dapat menghasilkan satu sale.
7. Order yang sudah Converted tidak dapat diproses ulang.
8. Pembatalan order dicatat pada audit log.

### Jenis order

- Dine In.
- Take Away.
- Delivery.

### Order lintas perangkat

Keputusan final:

**Held order yang telah berhasil disinkronisasi tersedia untuk perangkat lain pada outlet yang sama.**

Ketentuan:

- Order yang dibuat offline hanya tersedia pada perangkat pembuatnya sebelum sinkronisasi.
- Setelah server mengonfirmasi event order, order dapat diambil oleh perangkat lain melalui pull synchronization.
- Order yang belum tersinkronisasi tidak boleh ditampilkan pada perangkat lain seolah-olah merupakan data terbaru.
- Setiap order memiliki `version`.
- Perubahan order menggunakan optimistic concurrency control.
- Perangkat mengirim `base_version` ketika memperbarui order.
- Server menerima perubahan hanya jika versi masih sesuai.
- Jika versi sudah berubah, server mengembalikan Conflict.
- Sistem tidak menggunakan last-write-wins untuk konflik perubahan order.
- Perubahan konflik memerlukan pemeriksaan dan keputusan pengguna.

### Konflik meja

Ketika perangkat offline:

- Status meja diberi label STALE/UNVERIFIED.
- Kasir memperoleh peringatan bahwa meja mungkin digunakan perangkat lain.
- Kasir dapat memilih meja lain.
- Supervisor dapat memberikan persetujuan override dengan alasan.
- Override dicatat pada audit log.
- Setelah sinkronisasi, konflik ditampilkan kepada owner/admin.
- Transaksi tidak boleh dihapus otomatis akibat konflik meja.
- Reassignment meja dilakukan melalui proses terpisah dan tercatat.

---

## MODULE 04 — SALES & CHECKOUT

### Model Sale

Sale dibuat ketika order berhasil melewati checkout.

Sale merupakan catatan finansial yang berbeda dari order.

Status sale:

- Finalized.
- Voided.

Status lifecycle sale dan status pembayaran adalah dua state terpisah. `Paid` tidak pernah menjadi status sale.

| Sale lifecycle | Payment status |
|---|---|
| Finalized | Unpaid |
| Finalized | Partially Paid |
| Finalized | Awaiting Verification |
| Finalized | Paid |
| Finalized | Partially Refunded |
| Finalized | Refunded |
| Voided | Cancelled |

`Voided` sale hanya boleh memiliki payment status `Cancelled`. Sale yang telah dibayar atau dikembalikan tetap berstatus lifecycle `Finalized`; perubahan pembayaran dicatat pada payment status dan catatan refund.

### Checkout flow

1. Kasir membuka order.
2. Memeriksa seluruh item.
3. Sistem menghitung subtotal.
4. Sistem menghitung diskon.
5. Sistem menghitung pajak.
6. Sistem menghitung service charge.
7. Sistem menghitung total.
8. Kasir memilih metode pembayaran.
9. Sistem memvalidasi pembayaran.
10. Sale dan seluruh item disimpan.
11. Payment entries disimpan.
12. Transaksi dikunci.
13. Struk dicetak sesuai status pembayaran.
14. Transaksi dimasukkan dalam antrean sinkronisasi jika offline.

### Snapshot sale

Sale harus menyimpan:

- Product ID.
- SKU.
- Nama produk.
- Harga satuan.
- Kuantitas.
- Varian.
- Add-on.
- Diskon.
- Pajak.
- Service charge.
- Subtotal.
- Total.
- Waktu transaksi.
- Kasir.
- Perangkat.
- Outlet.
- Shift.

Perubahan master data tidak boleh mengubah histori sale.

### Aturan void

**Sale hanya dapat di-void apabila belum ada pembayaran yang terkonfirmasi dan tidak ada pembayaran yang masih menunggu verifikasi.**

Ketentuan:

1. Sale yang belum dibayar dapat di-void dengan otorisasi.
2. Sale yang memiliki pembayaran Awaiting Verification tidak boleh langsung di-void.
3. Pembayaran yang menunggu verifikasi harus diperiksa dan ditolak terlebih dahulu sebelum sale dapat di-void.
4. Jika pembayaran telah dikonfirmasi, sale tidak boleh di-void.
5. Sale yang telah menerima pembayaran tunai atau non-tunai terkonfirmasi harus melalui proses refund.
6. Void wajib memiliki alasan, petugas, waktu, dan referensi transaksi.
7. Sale yang di-void tetap tersimpan secara permanen.
8. Transaksi void tidak masuk penjualan lunas.
9. Void sale yang sudah tersinkronisasi wajib diproses online pada MVP.

### Acceptance Criteria

- Satu order hanya menghasilkan satu sale.
- Checkout gagal tidak menghasilkan sale parsial.
- Order yang sudah dikonversi tidak bisa di-checkout ulang.
- Sale tidak dihapus permanen.
- Sale memiliki UUID unik.

---

## MODULE 05 — PRICING, DISCOUNT & TAX

### Money Representation

Seluruh nominal uang disimpan sebagai integer dalam rupiah.

Dilarang menggunakan floating point untuk perhitungan uang.

### Rumus

Subtotal = Jumlah harga seluruh item setelah varian dan add-on.

Net subtotal = Subtotal - Diskon item - Diskon transaksi.

Service charge = Net subtotal × Tarif layanan.

Taxable base = Nilai produk kena pajak setelah diskon, ditambah service charge jika konfigurasi menyatakan service charge termasuk dasar pengenaan pajak.

Tax = Jumlah pajak seluruh baris yang dikenakan pajak.

Total = Net subtotal + Service charge + Tax.

### Kebijakan MVP

- Harga produk bersifat tax-exclusive.
- Pajak tidak aktif secara default.
- Service charge tidak aktif secara default.
- Tarif dapat dikonfigurasi owner.
- Pajak dapat berbeda berdasarkan produk atau kategori.
- Diskon transaksi dialokasikan proporsional ke item untuk perhitungan pajak.
- Service charge dihitung setelah diskon.
- Dasar pengenaan pajak mengikuti konfigurasi bisnis.
- Pembulatan menggunakan half-up ke rupiah terdekat.
- Perhitungan pajak dilakukan secara konsisten per baris pada Flutter dan Laravel.

Tarif dan perlakuan pajak aktual ditetapkan berdasarkan ketentuan yang berlaku dan kebijakan usaha.

---

## MODULE 06 — PAYMENT MANAGEMENT

### Metode pembayaran

- Cash.
- QRIS.
- Transfer bank.
- E-wallet.
- Split payment.

### Status payment

- Unpaid.
- Partially Paid.
- Awaiting Verification.
- Paid.
- Partially Refunded.
- Refunded.

Status payment merupakan status agregat dari payment entries dan refund. Sale lifecycle tidak berubah menjadi `Paid` atau `Refunded`.

Sistem juga menyimpan jumlah agregat secara terpisah agar status tunggal tidak menyembunyikan nilai yang berbeda:

- Confirmed amount.
- Awaiting verification amount.
- Outstanding amount.
- Refunded amount.

### Status payment entry

- Recorded.
- Awaiting Verification.
- Confirmed.
- Rejected.
- Cancelled.
- Refunded.

### Pembayaran tunai

- Kasir mencatat uang yang diterima.
- Sistem menghitung kembalian.
- Status pembayaran dapat menjadi Confirmed.
- Transaksi tunai dapat diproses ketika offline.

### Pembayaran non-tunai

Pada MVP, QRIS dan transfer dicatat secara manual tanpa payment gateway otomatis.

Status awal adalah Awaiting Verification.

Informasi yang dicatat:

- Metode pembayaran.
- Nominal.
- Referensi pembayaran.
- Waktu pencatatan.
- Kasir pencatat.
- Catatan.
- Bukti pembayaran jika tersedia.

### Mekanisme verifikasi

Petugas yang berwenang memeriksa mutasi rekening, notifikasi pembayaran, atau bukti transaksi pada penyedia pembayaran.

Setelah pemeriksaan, petugas melakukan salah satu tindakan:

**Verify Payment**
- Memastikan pembayaran benar-benar diterima.
- Memeriksa nominal.
- Memeriksa metode.
- Mencatat referensi transaksi.
- Mengubah payment entry menjadi Confirmed sebesar nominal yang benar-benar diterima dan diverifikasi.

### Penanganan perbedaan nominal

Keputusan bisnis:

1. Jika nominal terverifikasi sama dengan nominal yang dicatat, payment entry dikonfirmasi sebesar nominal tersebut.
2. Jika nominal terverifikasi lebih kecil, pembayaran parsial diperbolehkan. Hanya nominal yang benar-benar terverifikasi yang dikonfirmasi; selisih menjadi outstanding amount pada sale, bukan payment entry berstatus Awaiting Verification. Pembayaran berikutnya dicatat sebagai payment entry baru.
3. Jika nominal terverifikasi lebih besar, sistem tidak boleh mengonfirmasi pembayaran secara otomatis. Koreksi nominal memerlukan supervisor, alasan, bukti/referensi, dan audit trail.
4. Koreksi nominal tidak boleh melebihi outstanding amount sebelum pembayaran tersebut dikonfirmasi. Jika dana yang diterima melebihi outstanding amount, selisih wajib ditangani melalui proses penyelesaian kelebihan pembayaran yang tercatat; selisih itu tidak otomatis dihitung sebagai pembayaran sale.
5. Nilai tercatat awal, nilai terverifikasi, nilai koreksi, petugas, waktu, alasan, dan referensi harus tetap dapat diaudit. Nilai awal tidak ditimpa tanpa histori.

**Reject Payment**
- Menolak pembayaran yang tidak ditemukan atau tidak valid.
- Wajib mencatat alasan.
- Mengubah payment entry menjadi Rejected.
- Memungkinkan kasir memilih metode pembayaran pengganti.

### Otorisasi verifikasi

Permission:

- `payments.view_pending`
- `payments.verify`
- `payments.reject`

Role yang dapat diberikan permission:

- Owner.
- Admin.
- Supervisor yang ditunjuk.

Aturan pemisahan tugas:

- Kasir tidak boleh memverifikasi pembayaran yang ia catat sendiri.
- Petugas verifikasi harus berbeda dari pencatat pembayaran.
- Jika hanya ada satu petugas berwenang, verifikasi harus dilakukan setelah petugas kedua yang telah diberikan permission tersedia.
- Owner dapat memberikan permission kepada petugas lain melalui pengaturan role.
- Semua verifikasi dan penolakan harus tercatat di audit log.

### Payment verification API

| Method | Endpoint | Fungsi |
|---|---|---|
| GET | `/payments/pending-verification` | Daftar pembayaran menunggu verifikasi |
| GET | `/payments/{id}` | Detail pembayaran |
| POST | `/payments/{id}/verify` | Konfirmasi pembayaran |
| POST | `/payments/{id}/reject` | Tolak pembayaran |

Contoh request verifikasi:

```json
{
  "verified_amount": 25000,
  "provider_reference": "REF-123456",
  "verification_note": "Pembayaran ditemukan pada mutasi rekening"
}
```

`verified_amount` adalah nilai aktual yang telah diperiksa. Untuk verifikasi parsial, nilai ini dapat lebih kecil daripada nominal payment entry yang dicatat. Nilai lebih besar daripada nominal tercatat harus melalui koreksi supervisor sesuai aturan di atas.

Contoh request penolakan:

```json
{
  "reason": "Pembayaran tidak ditemukan pada mutasi rekening"
}
```

Setelah verifikasi berhasil:

1. Server mengubah status payment entry menjadi Confirmed.
2. Server menghitung ulang aggregate payment status.
3. Jika seluruh kewajiban pembayaran telah terpenuhi, payment status agregat menjadi `Paid`; sale lifecycle tetap `Finalized`.
4. Jika masih ada outstanding amount atau payment entry yang menunggu verifikasi, sistem memperbarui payment status agregat dan nilai confirmed, awaiting verification, serta outstanding secara terpisah. Sale lifecycle tetap `Finalized`.
5. Server mencatat verified_by dan verified_at.
6. Server membuat audit event.
7. Status terbaru dikirim ke perangkat melalui pull synchronization.

### Aturan offline

- QRIS dan transfer offline tetap berstatus Awaiting Verification.
- Verifikasi wajib dilakukan online.
- Pembayaran pending tidak boleh dianggap lunas.
- Pembayaran pending dilaporkan secara terpisah.
- Struk pending wajib diberi label `MENUNGGU VERIFIKASI PEMBAYARAN`.
- Pesanan yang belum lunas tidak boleh dilepas kecuali mendapat supervisor override.
- Override tidak boleh mengubah status pembayaran menjadi Paid.

### Split payment

Setiap metode pembayaran memiliki payment entry terpisah.

Payment status agregat menjadi `Paid` ketika jumlah pembayaran `Confirmed` memenuhi kewajiban total transaksi. Sale lifecycle tetap `Finalized`.

---

## MODULE 07 — RECEIPT & PRINTER

### Target MVP

Printer thermal Bluetooth dengan ESC/POS.

Ukuran kertas:

- 58 mm.
- 80 mm.

### Fitur

- Printer discovery.
- Pairing.
- Connect/disconnect.
- Test print.
- Auto print.
- Manual print.
- Reprint.
- Logo.
- QR Code.
- Header/footer.
- Paper width configuration.

### Jenis struk

- PAID RECEIPT.
- PAYMENT PENDING.
- REPRINT.

### Isi struk

- Nama bisnis.
- Logo.
- Alamat.
- Nomor transaksi.
- Tanggal.
- Waktu.
- Kasir.
- Jenis pesanan.
- Nomor meja.
- Item.
- Kuantitas.
- Harga.
- Diskon.
- Pajak.
- Service charge.
- Total.
- Metode pembayaran.
- Uang diterima.
- Kembalian.

### Status printer

- Queued.
- Sending.
- Sent.
- Failed.
- Unknown.

Status Sent bukan bukti bahwa kertas telah keluar.

Jika koneksi terputus ketika proses pengiriman berlangsung, sistem memberikan status Unknown dan peringatan kemungkinan cetak ganda.

Cetak ulang menggunakan label CETAK ULANG dan tidak menghasilkan sale baru.

---

## MODULE 08 — SHIFT MANAGEMENT

### Fitur

- Open shift.
- Opening cash.
- Cash in.
- Cash out.
- Sales summary.
- Payment summary.
- Closing cash.
- Cash variance.
- Closing notes.
- Supervisor approval.

### Rumus kas seharusnya

Kas seharusnya = Saldo awal + uang tunai diterima - kembalian + kas masuk - kas keluar - refund tunai.

### Penutupan shift offline

**Shift boleh ditutup ketika masih terdapat transaksi pending synchronization.**

Ketentuannya:

1. Kasir melihat jumlah transaksi belum sinkron.
2. Kasir melihat penerimaan tunai.
3. Kasir melihat pembayaran non-tunai terkonfirmasi.
4. Kasir melihat nilai Awaiting Verification terpisah.
5. Kasir menghitung kas aktual.
6. Kasir mengisi catatan selisih.
7. Sistem membuat immutable closing snapshot.
8. Status shift menjadi Closed Pending Sync.
9. Shift tidak dapat dibuka kembali.
10. Transaksi selanjutnya masuk shift baru.

### Closing snapshot

- Shift ID.
- User ID.
- Device ID.
- Opening cash.
- Cash tendered.
- Cash change.
- Cash in.
- Cash out.
- Cash refund.
- Expected cash.
- Actual cash.
- Variance.
- Confirmed non-cash.
- Awaiting verification amount.
- Local transaction count.
- Pending sync count.
- Closing timestamp.
- Local event sequence.

### Held orders

Sebelum shift ditutup, held orders harus:

- Diselesaikan.
- Dibatalkan.
- Dipindahkan ke shift berikutnya.

Shift tidak dapat ditutup jika masih memiliki held order yang belum diselesaikan atau dipindahkan.

### Status shift

- Open.
- Closed Pending Sync.
- Closed Confirmed.
- Closed Sync Exception.

### Setelah sinkronisasi

- Server memvalidasi transaksi sampai closing sequence.
- Server memvalidasi closing snapshot.
- Jika seluruh event valid, status menjadi Closed Confirmed.
- Jika terdapat event ditolak atau konflik, status menjadi Closed Sync Exception.
- Server tidak mengubah snapshot kas aktual.
- Selisih direkonsiliasi melalui catatan terpisah.

---

## MODULE 09 — TRANSACTION HISTORY

### Fitur

- Transaction listing.
- Search.
- Date filter.
- Cashier filter.
- Payment filter.
- Detail transaksi.
- Reprint.
- Void.
- Refund.
- Audit trail.

### Aturan

- Transaksi final tidak dapat dihapus permanen.
- Void dan refund berbeda.
- Refund mereferensikan transaksi asal.
- Setiap pembatalan menyimpan alasan.
- Transaksi offline tetap terlihat sampai sinkronisasi berhasil.

---

## MODULE 10 — OFFLINE-FIRST ENGINE

### Teknologi

- Flutter.
- Drift.
- SQLite.
- Laravel REST API.
- MySQL.
- Transactional Outbox Pattern.

### Data lokal

- Products.
- Categories.
- Pricing configuration.
- Offline authorization lease.
- Orders.
- Order items.
- Order versions.
- Sales.
- Sale items.
- Payments.
- Shifts.
- Cash movements.
- Print jobs.
- Outbox events.

### Transaksi lokal

Seluruh objek berikut harus disimpan atomik:

- Sale.
- Sale items.
- Payment entries.
- Outbox event.

Langkah:

1. Generate UUID.
2. Validasi katalog lokal.
3. Kalkulasi total.
4. Simpan sale.
5. Simpan item.
6. Simpan payment.
7. Simpan outbox.
8. Commit SQLite transaction.
9. Cetak struk.
10. Sinkronisasi ketika online.

Jika commit gagal, transaksi dianggap belum berhasil disimpan.

Cetak struk hanya dilakukan setelah commit lokal berhasil.

---

## MODULE 11 — SYNCHRONIZATION CONTRACT

### 11.1 Event Structure

Setiap event memiliki:

| Field | Fungsi |
|---|---|
| event_id | UUID unik |
| event_type | Jenis aktivitas |
| aggregate_type | Tipe objek |
| aggregate_id | ID objek |
| aggregate_version | Versi objek |
| base_version | Versi yang terakhir diketahui |
| device_id | Identitas perangkat |
| outlet_id | Identitas outlet |
| sequence | Urutan event perangkat |
| schema_version | Versi payload |
| actor_user_id | Petugas |
| occurred_at | Waktu aktivitas |
| payload | Snapshot objek |

### 11.2 Client-to-server events

Order:

- `order.created`
- `order.updated`
- `order.held`
- `order.resumed`
- `order.cancelled`
- `order.converted`

Sales:

- `sale.finalized`
- `sale.voided`

Payments:

- `payment.recorded`
- `payment.verification_requested`

Shifts:

- `shift.opened`
- `shift.cash_movement`
- `shift.closed`

Verifikasi pembayaran merupakan tindakan server-side yang memerlukan otorisasi online. Event verifikasi tidak boleh diterima sebagai klaim pembayaran lunas dari perangkat offline.

### 11.3 Order event synchronization

Setiap order memiliki `order_id` dan `version`.

- Order baru dimulai dari version 1.
- Setiap perubahan meningkatkan version.
- Event menyimpan base_version dan new_version.
- Server memverifikasi base_version sebelum menerima perubahan.
- Jika version tidak sesuai, server mengembalikan Conflict.
- Update yang konflik tidak boleh menimpa perubahan perangkat lain.

Held order yang belum tersinkronisasi tidak tersedia pada perangkat lain.

Setelah event accepted, perangkat lain pada outlet yang sama dapat mengambil perubahan melalui pull.

### 11.4 Order conversion

Ketika held order di-checkout:

1. Order dibuat menjadi Converted.
2. Sale dibuat dengan source_order_id.
3. Sale menyimpan source_order_version.
4. Event conversion harus bergantung pada versi order sebelumnya.
5. Server menyimpan conversion dan sale secara atomik.
6. Jika order sudah dikonversi perangkat lain, server menolak conversion kedua.
7. Satu order tidak boleh menghasilkan dua sale.

Jika order belum pernah disinkronisasi sebelum checkout offline, semua event order yang diperlukan tetap disimpan dan dikirim berurutan sebelum atau bersama event sale.finalized.

### 11.5 Push contract

Endpoint:

`POST /api/v1/sync/push`

Batas batch:

- Maksimal 50 event.
- Maksimal 1 MB payload.

Request:

```json
{
  "protocol_version": 1,
  "batch_id": "UUID",
  "device_id": "UUID",
  "outlet_id": "UUID",
  "events": [
    {
      "event_id": "UUID",
      "event_type": "sale.finalized",
      "aggregate_type": "sale",
      "aggregate_id": "UUID",
      "sequence": 17,
      "schema_version": 1,
      "payload": {}
    }
  ]
}
```

### 11.6 Push response

Status per event:

- Accepted.
- Duplicate.
- Rejected.
- Conflict.
- Blocked Dependency.
- Upgrade Required.

Contoh:

```json
{
  "batch_id": "UUID",
  "results": [
    {
      "event_id": "UUID",
      "status": "accepted",
      "server_record_id": "UUID"
    },
    {
      "event_id": "UUID",
      "status": "duplicate",
      "server_record_id": "UUID"
    },
    {
      "event_id": "UUID",
      "status": "conflict",
      "error_code": "ORDER_VERSION_MISMATCH",
      "retryable": false
    }
  ]
}
```

Setiap event diproses secara atomik.

Satu event gagal tidak otomatis membatalkan event independen lainnya.

### 11.7 Idempotency and ordering

- UUID digunakan sebagai global identity.
- Event ID menjadi idempotency key.
- Sequence monoton per device.
- Event dikirim FIFO.
- Event dengan dependency harus menunggu predecessor.
- Event ID sama dan payload sama menghasilkan Duplicate.
- Event ID sama dengan payload berbeda menghasilkan Conflict.
- Server tidak boleh menerima nomor sequence identik dari payload berbeda.

### 11.8 Retry policy

| Percobaan | Jeda dasar |
|---|---|
| 1 | 2 detik |
| 2 | 5 detik |
| 3 | 15 detik |
| 4 | 30 detik |
| 5 | 60 detik |
| Selanjutnya | Maksimal 15 menit |

Gunakan jitter.

Ketentuan:

- Network error: retry.
- HTTP 429: mengikuti Retry-After.
- HTTP 5xx: retry.
- HTTP 4xx invalid payload: tidak retry otomatis.
- Conflict: masuk rekonsiliasi.
- Blocked dependency: menunggu event sebelumnya.
- Failed event tidak boleh dihapus otomatis.

### 11.9 Server-to-client events

Endpoint:

`GET /api/v1/sync/pull?cursor={opaque_cursor}&limit=500`

Fungsi:

- Mengambil perubahan master data.
- Mengambil perubahan order.
- Mengambil perubahan pembayaran.
- Mengambil perubahan permission.
- Mengambil konfigurasi terbaru.

Response:

- Changes.
- Next cursor.
- Has more.
- Server timestamp.

Cursor baru disimpan setelah satu halaman berhasil diterapkan secara atomik.

Status `payment.verified` dan `payment.rejected` diterima perangkat melalui perubahan server, bukan dikirim sebagai verifikasi dari perangkat offline.

### 11.10 Bootstrap

Perangkat baru harus:

1. Memvalidasi device.
2. Melakukan autentikasi.
3. Mengunduh business profile.
4. Mengunduh katalog.
5. Mengunduh kategori.
6. Mengunduh permission.
7. Mengunduh konfigurasi.
8. Menyimpan cursor awal.
9. Mengaktifkan mode operasional.

### 11.11 Schema version

Setiap event memiliki schema_version.

Jika versi tidak didukung:

- Event tidak diproses.
- Status Upgrade Required diberikan.
- Data lokal tetap tersimpan.
- Pengguna mendapatkan instruksi update aplikasi.

---

## MODULE 12 — RECEIPT NUMBERING & DEVICE IDENTITY

### Format nomor struk

`RJS-{OUTLET}-{TERMINAL}-{SEQUENCE}`

Contoh:

`RJS-A01-T01-0000000123`

### Aturan

1. Sequence meningkat monoton per terminal.
2. Sequence tidak reset setiap hari.
3. Sequence disimpan secara persisten.
4. Sequence dibuat secara atomik.
5. Nomor tidak boleh digunakan ulang.
6. Server menerapkan unique constraint pada outlet, terminal, dan sequence.
7. Nomor tidak bergantung pada jam perangkat.
8. UUID tetap menjadi identitas transaksi utama.

### Pergantian perangkat

- Perangkat baru memperoleh terminal ID baru.
- Terminal ID lama tidak boleh dipakai hardware berbeda.
- Pemulihan backup harus memulihkan sequence dengan benar.
- Jika database lokal hilang, perangkat baru harus memakai terminal ID baru.
- Pending transaction harus diekspor atau dipulihkan sebelum perangkat lama dinonaktifkan, jika masih memungkinkan.

---

## MODULE 13 — DASHBOARD & REPORTING

### Dashboard MVP

Hanya memakai data transaksi dan pembayaran yang tersedia dalam MVP.

Informasi:

- Total nilai transaksi final.
- Total pembayaran diterima.
- Total penjualan lunas terkonfirmasi.
- Jumlah transaksi final.
- Jumlah transaksi lunas.
- Pembayaran tunai.
- Pembayaran non-tunai terkonfirmasi.
- Awaiting Verification.
- Diskon.
- Void.
- Refund.
- Average transaction value.
- Produk terlaris.
- Grafik penjualan.
- Shift summary.
- Pending synchronization.

### Definisi metrik

**Total Transaksi Final**

Nilai seluruh sale yang sudah difinalisasi, baik lunas maupun masih menunggu verifikasi. Nilai ini bukan otomatis pendapatan yang telah diterima.

**Pembayaran Diterima**

Jumlah pembayaran yang telah diterima, termasuk kas tunai dan pembayaran non-tunai terkonfirmasi.

**Penjualan Lunas Terkonfirmasi**

Nilai sale dengan seluruh kewajiban pembayaran yang telah terpenuhi.

**Awaiting Verification**

Nilai pembayaran yang belum diperiksa dan ditampilkan secara terpisah.

**Average Transaction Value**

Penjualan lunas terkonfirmasi dibagi jumlah transaksi lunas terkonfirmasi.

Refund dan void dilaporkan terpisah.

### Tidak tersedia pada MVP

- Stok tersedia.
- Bahan menipis.
- HPP.
- Profit produk.
- Laba bersih.
- Pengeluaran.
- Margin keuntungan.

Fitur tersebut hanya aktif ketika modul terkait selesai dikembangkan.

---

# 5. NON-FUNCTIONAL REQUIREMENTS

## 5.1 Performance

### Perangkat referensi

- Android 14 atau lebih baru.
- RAM minimal 6 GB.
- CPU octa-core kelas menengah.
- Penyimpanan UFS atau setara.

Model perangkat referensi harus dicatat sebelum UAT.

### Dataset pengujian

- 1.000 produk aktif.
- 50 kategori.
- Maksimal 100 item dalam satu keranjang.
- 100.000 transaksi historis.
- 500 pending synchronization events.

### Target P95

| Operasi | Target |
|---|---|
| Membuka POS dari cache | ≤ 2 detik |
| Pencarian produk lokal | ≤ 500 ms |
| Menambahkan produk | ≤ 200 ms |
| Commit transaksi lokal | ≤ 1 detik |
| Membuka dashboard cached | ≤ 3 detik |

P95 berarti 95% operasi harus selesai dalam batas waktu yang ditetapkan.

## 5.2 Security

- HTTPS.
- Token authentication.
- Signed offline authorization lease.
- RBAC.
- Server-side authorization.
- Password hashing.
- Android Keystore.
- Local database encryption.
- API rate limiting.
- Audit logging.
- Device registration.
- Backup and restore.

## 5.3 Reliability

- Local transaction commit harus atomik.
- Retry tidak menggandakan transaksi.
- Pending events tidak dihapus otomatis.
- Printer failure tidak membatalkan sale.
- Shift closing snapshot immutable.
- Konflik tidak boleh menghilangkan transaksi.
- Kegagalan sinkronisasi harus dapat dipulihkan.

---

# 6. SYSTEM ARCHITECTURE

## 6.1 Architecture Pattern

Backend: Modular Monolith.

Frontend: Feature-First Clean Architecture.

Offline: Transactional Outbox Pattern.

Database: Central MySQL + Local SQLite.

## 6.2 Flutter Structure

```text
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   └── bootstrap/
│
├── core/
│   ├── database/
│   ├── network/
│   ├── storage/
│   ├── printer/
│   ├── sync/
│   ├── security/
│   ├── errors/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── products/
│   ├── categories/
│   ├── orders/
│   ├── sales/
│   ├── payments/
│   ├── receipts/
│   ├── shifts/
│   ├── inventory/
│   ├── recipes/
│   ├── suppliers/
│   ├── finance/
│   ├── reports/
│   ├── customers/
│   ├── users/
│   └── settings/
│
└── shared/
    ├── widgets/
    ├── theme/
    └── extensions/
```

Setiap feature:

```text
feature/
├── data/
├── domain/
└── presentation/
```

## 6.3 Laravel Structure

```text
app/
├── Models/
├── Http/
│   ├── Controllers/Api/V1/
│   ├── Requests/
│   └── Resources/
│
├── Services/
├── Actions/
├── Policies/
├── Jobs/
├── Events/
└── Support/

resources/
├── views/
│   ├── layouts/       # Layout Blade web admin hasil adaptasi Horizon
│   └── admin/         # Halaman back-office Owner/Admin
├── css/               # Tailwind dan style admin
└── js/                # Entry point asset Laravel Vite
```

Controller hanya menangani HTTP request dan response. Business logic utama berada pada service/action layer.

Web admin menggunakan Laravel sebagai aplikasi penyaji halaman dan sumber otorisasi/data. Komponen React Horizon harus diadaptasi ke Blade untuk pendekatan baseline; aset dan tampilan tidak boleh menjadi jalur akses langsung yang melewati middleware, policy, atau service Laravel. UI Flutter tetap dibangun secara native dan hanya boleh mengadaptasi design language, bukan memakai komponen React.

---

# 7. DATABASE DESIGN

## 7.1 Business & Access

- businesses
- outlets
- users
- roles
- permissions
- role_permissions
- user_roles
- devices
- user_sessions

## 7.2 Products

- categories
- products
- product_variants
- product_addons
- product_addon_options
- product_prices

## 7.3 Orders

- orders
- order_items
- order_item_modifiers
- order_status_histories

## 7.4 Sales

- sales
- sale_items
- sale_item_modifiers
- sale_payments
- refunds
- refund_items
- sale_status_histories

## 7.5 Operations

- registers
- shifts
- shift_cash_movements
- shift_closing_snapshots
- tables

## 7.6 Inventory — Future

- ingredients
- ingredient_units
- recipes
- recipe_items
- stock_movements
- stock_opnames
- stock_opname_items
- waste_records

## 7.7 Purchasing — Future

- suppliers
- purchase_orders
- purchase_order_items
- goods_receipts
- goods_receipt_items
- supplier_payments

## 7.8 Finance — Future

- expense_categories
- expenses
- cash_accounts
- cash_movements

## 7.9 Synchronization & Audit

- audit_logs
- sync_logs
- sync_events
- idempotency_keys
- sync_cursors
- receipt_print_jobs
- app_settings

### Database Rules

- UUID sebagai identitas global.
- business_id untuk setiap data bisnis.
- outlet_id untuk data operasional.
- device_id untuk aktivitas perangkat.
- Foreign key.
- Unique constraints.
- Index sesuai pola query.
- Snapshot harga transaksi.
- Immutable closing snapshot.
- Soft delete tidak digunakan untuk menghilangkan transaksi final.

### Relasi inti

- Satu order menghasilkan maksimal satu sale.
- Satu sale memiliki banyak sale items.
- Satu sale memiliki satu atau lebih payment entries.
- Satu shift memiliki banyak sales.
- Satu shift memiliki banyak cash movements.
- Satu device memiliki banyak sync events.
- Satu sync event memiliki satu idempotency key.

---

# 8. API CONTRACT

Base path:

`/api/v1`

## Authentication

| Method | Endpoint |
|---|---|
| POST | /auth/login |
| POST | /auth/logout |
| POST | /auth/refresh |
| GET | /me |
| POST | /devices/register |

## Products

| Method | Endpoint |
|---|---|
| GET | /products |
| POST | /products |
| PUT | /products/{id} |
| GET | /categories |

## Orders

| Method | Endpoint |
|---|---|
| POST | /orders |
| PUT | /orders/{id} |
| POST | /orders/{id}/hold |
| POST | /orders/{id}/resume |
| POST | /orders/{id}/cancel |

Setiap update order wajib menyertakan base_version.

## Sales

| Method | Endpoint |
|---|---|
| POST | /sales/checkout |
| GET | /sales |
| GET | /sales/{id} |
| POST | /sales/{id}/void |
| POST | /sales/{id}/refund |

## Payments

| Method | Endpoint |
|---|---|
| GET | /payments/pending-verification |
| GET | /payments/{id} |
| POST | /payments/{id}/verify |
| POST | /payments/{id}/reject |

Endpoint verifikasi dan penolakan hanya dapat diakses pengguna berwenang yang berbeda dari pencatat pembayaran.

## Shifts

| Method | Endpoint |
|---|---|
| POST | /shifts/open |
| POST | /shifts/close |
| GET | /shifts |

## Synchronization

| Method | Endpoint |
|---|---|
| POST | /sync/push |
| GET | /sync/pull |
| GET | /sync/bootstrap |
| GET | /sync/status |

## Reports

| Method | Endpoint |
|---|---|
| GET | /reports/sales |
| GET | /reports/payments |
| GET | /reports/products |
| GET | /reports/shifts |

### API Requirements

Seluruh endpoint wajib memiliki:

- Request validation.
- Authorization.
- Consistent response schema.
- Standard error code.
- Pagination.
- Idempotency pada operasi yang memerlukan.
- OpenAPI documentation.
- API versioning.

---

# 9. TESTING & ACCEPTANCE CRITERIA

## 9.1 Core Tests

- Product management.
- Order lifecycle.
- Checkout.
- Payment.
- Split payment.
- Cash change.
- Discount.
- Tax.
- Receipt.
- Shift calculation.
- Refund.
- Void.
- Audit.

## 9.2 Payment Verification Tests

1. Kasir mencatat QRIS.
2. Payment menjadi Awaiting Verification.
3. Kasir tidak dapat memverifikasi pembayaran sendiri.
4. Supervisor dapat melihat daftar pending.
5. Supervisor memverifikasi nominal dan referensi.
6. Server mengubah status menjadi Confirmed.
7. Perubahan tercatat dalam audit log.
8. Perangkat lain menerima perubahan melalui pull.
9. Penolakan pembayaran menyimpan alasan.
10. Pembayaran yang sudah terkonfirmasi tidak dapat dikonfirmasi dua kali.
11. Nilai terverifikasi sama dengan nilai tercatat mengonfirmasi nilai tersebut.
12. Nilai terverifikasi lebih kecil mengonfirmasi hanya nilai aktual dan menyisakan outstanding amount.
13. Sisa pembayaran parsial tidak dibuat sebagai payment entry Awaiting Verification.
14. Nilai terverifikasi lebih besar tidak dikonfirmasi otomatis.
15. Koreksi nominal lebih memerlukan supervisor dan tersimpan dalam audit trail tanpa menimpa nilai awal.
16. Pembayaran yang melebihi outstanding amount memerlukan penyelesaian kelebihan pembayaran yang tercatat.
17. Status `Paid` atau `Refunded` tidak mengubah sale lifecycle dari `Finalized`.

## 9.3 Void and Refund Tests

1. Sale tanpa pembayaran dapat di-void.
2. Sale dengan pembayaran awaiting verification tidak dapat langsung di-void.
3. Payment pending harus ditolak terlebih dahulu sebelum void.
4. Sale dengan pembayaran confirmed wajib melalui refund.
5. Sale yang sudah di-refund tidak dapat di-refund melebihi nilai yang diizinkan.
6. Void dan refund tercatat secara terpisah.
7. Transaksi asal tidak dihapus.

## 9.4 Order Synchronization Tests

1. Held order online tersedia pada perangkat lain setelah pull.
2. Held order offline tidak muncul di perangkat lain.
3. Order offline tersimpan pada perangkat pembuat.
4. Order baru tersinkronisasi ketika internet kembali.
5. Dua perangkat mengubah order yang sama.
6. Perangkat dengan base_version lama menerima Conflict.
7. Perubahan tidak saling menimpa.
8. Order yang dikonversi menghasilkan satu sale.
9. Retry conversion tidak menciptakan sale tambahan.
10. Cancelled order tidak muncul kembali sebagai held order.

## 9.5 Offline Tests

- Transaction offline.
- Application force close.
- Local database recovery.
- Retry.
- Duplicate event.
- Batch partial failure.
- Network interruption.
- Device clock changes.
- Expired authorization lease.
- Pending shift closure.
- Device revocation.
- Device replacement.
- Restored backup.

## 9.6 Printer Tests

- Pairing.
- Disconnect.
- Paper width.
- Encoding.
- Logo.
- QR Code.
- Consecutive print.
- Unknown print status.
- Reprint.

## 9.7 Critical Shift Scenarios

**Skenario A — Shift ditutup dengan transaksi offline**

Expected:

- Transaksi lokal ikut masuk perhitungan.
- Closing snapshot dibuat.
- Status menjadi Closed Pending Sync.
- Shift tidak berubah akibat transaksi yang diterima server.

**Skenario B — Shift ditutup dengan QRIS pending verification**

Expected:

- Nilai QRIS dicatat sebagai pending.
- Tidak masuk confirmed non-cash payment.
- Tidak memengaruhi kas aktual.
- Laporan menampilkan outstanding verification secara terpisah.

**Skenario C — Sinkronisasi gagal sebagian**

Expected:

- Event accepted tidak dibuat ulang.
- Event gagal tetap disimpan.
- Event dependent ditahan.
- Shift menjadi Closed Sync Exception apabila closing dependency belum terpenuhi.
- Snapshot kas aktual tidak diubah.

**Skenario D — Dua perangkat memilih meja yang sama**

Expected:

- Peringatan konflik muncul.
- Supervisor override tercatat apabila dilanjutkan.
- Kedua transaksi tetap tersimpan.
- Konflik diselesaikan melalui reassignment dan audit trail.

---

# 10. DEVELOPMENT ROADMAP

## Phase 0 — Architecture Foundation

- Flutter project setup.
- Laravel project setup.
- Database foundation.
- Authentication.
- RBAC.
- Device identity.
- Database migration.
- API conventions.
- Local storage foundation.
- Synchronization event schema.
- Printer proof of concept.
- Horizon-to-Laravel Blade proof of concept untuk memastikan kelayakan web back-office.

Offline-first dirancang sejak awal, termasuk struktur database dan kontrak event.

## Phase 1 — Online POS

- Product.
- Category.
- Cart.
- Order draft.
- Hold/resume.
- Checkout.
- Sales.
- Transaction history.

Target: satu siklus transaksi online berjalan dengan benar.

## Phase 2 — Payment, Printer & Shift

- Cash payment.
- Manual non-cash recording.
- Payment verification.
- Split payment.
- Receipt.
- Bluetooth thermal printer.
- Open shift.
- Close shift.
- Cash reconciliation.

Target: proses operasional kasir dapat digunakan secara nyata.

## Phase 3 — Local Offline Transaction

- SQLite.
- Offline authorization lease.
- Local catalog.
- Local order.
- Local checkout.
- Local payment.
- Local printer queue.
- Transactional outbox.

Target: transaksi dapat dilakukan tanpa internet.

## Phase 4 — Synchronization & Reconciliation

- Push contract.
- Pull contract.
- Batch processing.
- Idempotency.
- Retry.
- Conflict handling.
- Shift reconciliation.
- Pending event monitoring.

Target: transaksi lokal dapat disinkronisasi tanpa duplikasi atau kehilangan data secara diam-diam.

## Phase 5 — Dashboard & Reporting

- Sales dashboard.
- Daily reports.
- Payment reports.
- Shift reports.
- Export.
- Audit log review.

Target: laporan konsisten dengan transaksi sumber.

## Phase 6 — Cafe Operations

- Inventory.
- Recipe.
- HPP.
- Purchasing.
- Supplier.
- Waste management.

## Phase 7 — Advanced Features

- KDS.
- Loyalty.
- QR ordering.
- Digital menu.
- AI assistant.
- Sales forecasting.

## Phase 8 — Multi-Outlet & SaaS

- Multi-outlet activation.
- Multi-tenant provisioning.
- Subscription.
- License management.
- Centralized administration.

---

# 11. SUCCESS METRICS

| KPI | Target |
|---|---|
| Transaction integrity | Tidak ada duplikasi akibat retry |
| Local persistence | Tidak ada transaksi hilang akibat gangguan jaringan |
| Synchronization | Semua event dapat direkonsiliasi |
| Payment accuracy | Total pembayaran sesuai transaksi |
| Shift accuracy | Closing snapshot konsisten |
| Printer compatibility | Lulus pada printer referensi |
| Reporting accuracy | Konsisten dengan data sumber |
| POS performance | Memenuhi target P95 |

---

# 12. MVP RELEASE CRITERIA

MVP hanya boleh dirilis ketika:

1. Login dan authorization berjalan.
2. Product management berjalan.
3. Order dan sale memiliki lifecycle terpisah.
4. Checkout berjalan secara atomik.
5. Payment dapat direkonsiliasi.
6. Verifikasi QRIS dan transfer tersedia.
7. Void dan refund memiliki aturan berbeda.
8. Printer fisik telah diuji.
9. Transaksi dapat dilakukan ketika offline.
10. Offline lease berjalan sesuai aturan.
11. Sinkronisasi tidak menggandakan transaksi.
12. Partial batch failure dapat ditangani.
13. Held order tersinkronisasi sesuai aturan.
14. Shift dapat ditutup ketika offline.
15. Closing snapshot tetap immutable.
16. Laporan memisahkan pembayaran confirmed dan pending.
17. Backup dan restore diuji.
18. Audit trail tersedia.

---

# 13. FINAL PRODUCT DEFINITION

RUJAK.IN.SIAK POS adalah Cafe Management System dengan karakteristik:

- Flutter Native Application.
- Laravel REST API.
- Laravel Blade web back-office untuk Owner/Admin dengan UI yang diadaptasi dari Horizon React setelah proof of concept.
- MySQL Central Database.
- SQLite Local Database.
- Offline-First Transaction Processing.
- Transactional Outbox.
- Bluetooth ESC/POS Printing.
- Multi-user Authentication.
- Role-Based Authorization.
- Order Management.
- Sales Management.
- Payment Management.
- Payment Verification.
- Shift Management.
- Audit Logging.
- Business Reporting.
- Modular Inventory Expansion.
- Multi-outlet-ready architecture.
- Expandable SaaS architecture.

## Prinsip utama

1. Integritas transaksi lebih penting daripada jumlah fitur.
2. Order operasional tidak boleh tercampur dengan penjualan finansial.
3. Pembayaran belum terverifikasi bukan pembayaran lunas.
4. Kasir tidak boleh memverifikasi pembayaran yang dicatatnya sendiri.
5. Sale yang sudah dibayar harus melalui refund, bukan void.
6. Shift harus dapat ditutup secara terkontrol ketika offline.
7. Printer gagal tidak boleh menghilangkan transaksi.
8. Sinkronisasi harus idempotent.
9. Snapshot historis tidak boleh berubah otomatis.
10. Konflik data harus dapat diaudit.
11. Seluruh tindakan sensitif memiliki identitas pelaksana.
12. Fitur baru tidak boleh merusak core POS.

---

# 14. STATUS DAN GOVERNANCE DOKUMEN

PRD RUJAK.IN.SIAK POS versi 1.6 merupakan baseline kebutuhan produk yang telah menetapkan keputusan bisnis utama dan kontrak operasional.

Dokumen ini menjadi dasar penyusunan:

1. Software Architecture Document (SAD).
2. Entity Relationship Diagram (ERD).
3. Database Design Specification.
4. API Contract / OpenAPI.
5. UI/UX Specification.
6. Test Plan dan User Acceptance Test.

**Status: Approved Product Baseline — Detailed Technical Design Required.**

Dokumen belum menyatakan seluruh detail implementasi selesai. Keputusan teknis yang belum memiliki proof of concept harus diverifikasi sebelum coding production.

Detail implementasi yang tidak mengubah keputusan bisnis baseline ditempatkan pada SAD, ERD, API Contract / OpenAPI, atau ADR yang relevan. PRD direvisi untuk perubahan kebutuhan atau keputusan bisnis, bukan untuk setiap detail implementasi kecil.

Setiap perubahan kebutuhan bisnis atau teknologi harus dicatat melalui revisi PRD atau Architecture Decision Record (ADR).
