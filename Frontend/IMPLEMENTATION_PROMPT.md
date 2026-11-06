# Prompt Implementasi Flutter POS RUJAK.IN.SIAK

Salin prompt di bawah ini ke coding agent yang memiliki akses ke seluruh repository.

---

## Peran dan tujuan

Anda adalah senior Flutter engineer dan product-minded UI designer. Bangun aplikasi POS Android native RUJAK.IN.SIAK yang modern, cepat digunakan kasir, tetap andal saat offline, dan terintegrasi dengan backend Laravel yang ada.

Sumber kebenaran adalah:

1. `../PRD.md` versi 1.6 untuk aturan produk, alur, offline, keamanan, performa, dan acceptance criteria.
2. `../Backend/docs/openapi.yaml` untuk kontrak HTTP.
3. Implementasi backend pada `../Backend/routes/api.php`, `../Backend/app/Http/Controllers/Api/V1/`, requests, resources, models/actions, dan tes untuk perilaku kontrak yang belum jelas.
4. `../Backend/docs/SETUP.md` untuk setup server, autentikasi, device, dan protokol sinkronisasi.

Baca seluruh sumber tersebut serta `AGENTS.md` sebelum coding. Jangan membuat endpoint, permission, state pembayaran, atau aturan bisnis yang tidak ada di kontrak. Jika PRD, OpenAPI, dan implementasi backend berbeda, dokumentasikan perbedaannya dan gunakan perilaku backend yang benar-benar tersedia sebagai target integrasi sementara; jangan menyembunyikan mismatch.

## Kondisi repository

Folder `Frontend/` mungkin masih kosong atau belum menjadi aplikasi Flutter. Periksa struktur aktual terlebih dahulu. Buat aplikasi Flutter di folder `Frontend/` tanpa mengubah backend atau template Horizon. Pertahankan perubahan pengguna yang sudah ada.

Backend menyediakan API `/api/v1` dengan Sanctum, registrasi/revokasi device, offline lease, katalog, order, checkout, pembayaran, shift, sync push/pull/bootstrap/status, serta reports. Backend juga memiliki `Backend/database/seeders/ProductCatalogSeeder.php`. Produk tanpa harga yang ditetapkan—Basreng Tempura Prasmanan—dinonaktifkan dan tidak boleh ditampilkan sebagai produk yang bisa dijual.

## Hasil yang diminta

Bangun MVP Flutter Android sesuai Phase 0–4 PRD, lalu layar riwayat/laporan dasar Phase 5 bila endpoint sudah tersedia. Aplikasi harus menjalankan transaksi online dan offline dengan data nyata dari backend/local database.

Jangan implementasikan inventory, recipe/HPP, purchasing, supplier, finance, loyalty, KDS, QR self-ordering, AI, forecasting, atau fitur multi-outlet aktif. Jangan gunakan data hardcoded/demo sebagai katalog production.

## Arsitektur wajib

Gunakan Feature-First Clean Architecture mengikuti struktur PRD:

```text
lib/
  app/                 # bootstrap, app, router
  core/                # database, network, secure storage, sync,
                       # printer, security, errors, utilities
  features/
    auth/
    dashboard/
    products/
    categories/
    orders/
    sales/
    payments/
    receipts/
    shifts/
    reports/
    settings/
  shared/              # theme, reusable widgets, extensions
```

Setiap feature memisahkan `data/`, `domain/`, dan `presentation/` secukupnya. Jangan membuat lapisan atau abstraksi generik yang tidak membantu pemisahan tanggung jawab.

Stack baseline PRD:

- Flutter Stable dan Dart Stable; verifikasi versi SDK yang terpasang dan kompatibilitas package sebelum memilih versi.
- Riverpod untuk state management.
- GoRouter untuk navigasi dan route guard.
- Dio untuk HTTP, interceptor token/device, timeout, dan error mapping.
- SQLite + Drift untuk katalog, draft/order lokal, outbox, sync cursor, shift lokal, dan printer queue.
- Flutter Secure Storage untuk token, kunci enkripsi, dan rahasia kecil; jangan menyimpan token di SQLite/log.
- Bluetooth ESC/POS untuk printer thermal.
- Commit lockfile dependency.

Database offline harus dienkripsi at-rest dengan package/pendekatan Android yang masih didukung dan diuji. Simpan kunci di Android Keystore melalui secure storage. Jangan mengklaim database terenkripsi jika implementasi hanya memakai SQLite biasa.

## Desain UI modern

Rancang visual khusus untuk kasir RUJAK.IN.SIAK; gunakan bahasa Indonesia yang jelas dan format mata uang `Rp` tanpa pecahan.

Karakter visual:

- Bersih, segar, hangat, dan profesional; terinspirasi warna buah dan bahan segar.
- Gunakan latar warm off-white, permukaan putih, forest green sebagai warna utama, dan coral/orange sebagai aksen tindakan/produk. Tetapkan token warna, tipografi, jarak, radius, elevasi, dan status dalam satu theme.
- Material 3 dengan komponen native yang dikustomisasi konsisten. Hindari tampilan template dashboard generik, dekorasi berlebihan, gradien mencolok, dan card yang terlalu padat.
- Gunakan ikon konsisten, tipografi terbaca, kontras memadai, loading/empty/error state yang dirancang, serta animasi singkat yang tidak memperlambat transaksi.
- Prioritaskan sentuhan satu tangan, target sentuh nyaman, tombol checkout/payment yang jelas, dan jalur kasir yang minim langkah.
- Desain adaptif untuk ponsel Android portrait sebagai target utama dan tablet/landscape dengan layout POS dua panel. Pastikan keyboard, inset sistem, dan scrolling tidak menutupi aksi penting.
- Bedakan status online/offline, lease, katalog stale, printer, transaksi pending sync, konflik, dan pembayaran menunggu verifikasi dengan label teks dan ikon; jangan hanya mengandalkan warna.

Tampilan inti:

1. Login dan pemilihan/perangkat kasir yang terdaftar.
2. PIN lock/screen lock untuk pengguna yang telah memiliki otorisasi lokal.
3. Buka shift dan ringkasan kas awal.
4. POS: kategori, pencarian, katalog grid/list, produk/varian, keranjang, catatan, diskon sesuai otorisasi, hold/resume order.
5. Checkout: tunai, non-tunai menunggu verifikasi, split payment, nominal diterima/kembalian, konfirmasi total.
6. Hasil transaksi dan struk: cetak, cetak ulang sesuai izin, status printer, antrean cetak lokal.
7. Riwayat transaksi/detail, pembayaran pending untuk role berwenang, refund/void sesuai policy backend.
8. Tutup shift, hitung kas aktual, selisih, catatan, dan status sync.
9. Status sinkronisasi: antrean, percobaan ulang, konflik, last sync, manual sync.
10. Dashboard/laporan dasar hanya menggunakan nilai API; tampilkan empty state saat belum ada data.

Gunakan katalog bisnis aktual. Untuk produk yang memiliki varian, kasir harus memilih varian sebelum masuk ke cart. Miso Medan dan Soto Medan memerlukan pilihan mie. Untuk Matcha/Seasalt dan Thaitea/Seasalt tampilkan pilihan rasa dan ukuran sesuai varian backend. Jangan mengarang harga atau modifier. Jika harga produk nol atau produk tidak aktif/tidak tersedia, jangan tawarkan untuk checkout.

## Tahapan implementasi

### Tahap 1 — Audit dan scaffold

1. Inventarisasi isi `Frontend/`, Flutter SDK, Android toolchain, dan perubahan yang belum di-commit.
2. Jika proyek belum ada, scaffold aplikasi Flutter Android di `Frontend/`; jangan menimpa file yang sudah dibuat pengguna.
3. Siapkan struktur arsitektur, flavor/config environment, theme dasar, router, localization Indonesia, logging aman, dan error boundary.
4. Buat design foundation dan prototype layar login + POS menggunakan data mock hanya untuk story/dev yang terisolasi. Jangan memasukkan mock sebagai fallback diam-diam ke production.

### Tahap 2 — API dan autentikasi

Implementasikan client sesuai OpenAPI: envelope `{data, meta}` dan `{error:{code,message,details,retryable}}`, bearer token, refresh rotation, `X-Device-Id`, timeout, pagination, dan mapping error yang bisa dipahami kasir.

Alur onboarding device harus mengikuti API aktual:

1. Login online dengan identifier/password.
2. Bila perangkat belum terdaftar, registrasikan perangkat memakai endpoint yang disediakan dan simpan UUID perangkat.
3. Ambil bootstrap dan offline lease setelah device context valid.
4. Simpan token/lease dengan aman; jangan menyimpan password.
5. Login offline hanya untuk user/perangkat yang pernah memperoleh otorisasi valid. Lease maksimal 72 jam. Jangan menyatakan server telah memvalidasi sesi offline secara real-time.
6. Setelah lease kedaluwarsa, blok transaksi offline baru, tetapi izinkan outbox valid yang sudah dibuat untuk disinkronkan sesuai kontrak PRD.
7. Logout/revocation harus membersihkan token/lease sesuai perilaku API, tanpa menghapus antrean transaksi pending secara diam-diam.

Jangan menerima role/permission dari cache tanpa menerapkan snapshot lease, masa berlaku, authentication version, dan device binding.

### Tahap 3 — Local data dan online POS

1. Buat schema Drift dan migration lokal dengan UUID global, indeks yang diperlukan, foreign keys, dan versioning.
2. Simpan snapshot produk/harga untuk histori order/sale. Perubahan katalog tidak boleh mengubah transaksi yang sudah dibuat.
3. Ambil katalog dari bootstrap/API, sediakan search/filter lokal cepat, dan tampilkan peringatan katalog berumur >24 jam. Blok checkout offline jika katalog lebih dari 72 jam belum diperbarui, sesuai PRD.
4. Buat order, edit kuantitas/catatan/modifier, hold/resume/cancel, serta checkout online dengan optimistic version.
5. Gunakan seluruh perhitungan nominal integer rupiah dan samakan aturan pembulatan/per-item tax dengan `Backend/app/Services/PricingCalculator.php`. Jangan memakai `double` untuk uang.
6. Tampilkan konflik `base_version` secara eksplisit; minta pengguna meninjau data server dan jangan menimpa dengan last-write-wins.
7. Integrasikan payments, shift, history, dan permission dari API.

### Tahap 4 — Offline-first dan sync

1. Implementasikan transactional outbox lokal. Perubahan order/sale/payment/shift dan pencatatan event outbox harus berada dalam transaksi SQLite yang sama.
2. Gunakan kontrak event Module 11 PRD dan implementasi `Backend/app/Services/SyncPushService.php`, `SyncPullService.php`, `SyncEventApplier.php`, `SyncCursorCodec.php`, serta API docs. Jangan membuat format event kedua.
3. Persist event UUID, sequence per device, aggregate/version, schema version, occurred_at, payload snapshot, retry count, dan status.
4. Retry harus idempotent, backoff dengan batas, mempertahankan urutan event yang bergantung pada aggregate, dan membedakan network failure, retryable error, rejected, conflict, dan upgrade-required.
5. Pull dengan opaque cursor; simpan cursor hanya setelah perubahan berhasil dipersist ke database lokal.
6. Jangan hapus event outbox sampai server mengembalikan hasil yang mengonfirmasi event diterima/duplicate. Simpan rejected/conflict untuk tindakan pengguna/supervisor.
7. Tampilkan indikator pending sync dan conflict di UI. Manual sync harus dapat dipicu dan statusnya dapat diamati.
8. Offline table/order diberi label stale/unverified sesuai PRD. Jangan menampilkan data offline sebagai data outlet yang telah tersinkron.
9. Background sync tidak boleh memblokir input POS atau menyebabkan duplikasi saat app resume/restart.

### Tahap 5 — Printer dan stabilisasi

1. Implementasikan Bluetooth ESC/POS dengan permission Android yang sesuai versi OS, pairing/pemilihan printer, reconnect, status unavailable, dan error yang dapat dipulihkan.
2. Printer failure tidak boleh membatalkan sale. Simpan receipt print job lokal dan dukung retry/cetak ulang tanpa membuat sale/payment baru.
3. Uji layout struk untuk lebar printer target, termasuk nama/varian/add-on, diskon, pajak/service, metode/status pembayaran, change, nomor struk, kasir, waktu, outlet, dan status offline/pending bila relevan.
4. Uji startup POS dari cache, restart saat outbox pending, network timeout, token expiry, lease expiry, konflik order, printer disconnect, database migration, dan baterai/app lifecycle.

## Aturan bisnis yang tidak boleh dilanggar

- Draft/Held bukan penjualan dan tidak mengurangi stok.
- Satu order menghasilkan maksimal satu sale; checkout retry tidak boleh menggandakan transaksi.
- Lifecycle sale dan status pembayaran terpisah.
- Non-tunai dicatat sebagai Awaiting Verification; UI tidak boleh menandainya Paid sebelum konfirmasi backend.
- Kasir tidak boleh memverifikasi pembayaran yang dicatatnya sendiri.
- Sale dengan pembayaran terkonfirmasi harus melalui refund, bukan void.
- Pembayaran pending verification harus ditolak terlebih dahulu sebelum sale dapat di-void.
- Offline lease maksimal 72 jam; transaksi baru offline dilarang setelah expiry.
- Shift dapat ditutup offline sesuai PRD dengan closing snapshot/outbox.
- Printer gagal tidak menghapus atau menggagalkan transaksi finansial.
- Konflik order tidak diselesaikan otomatis dengan last-write-wins.

## Kualitas kode, keamanan, dan performa

- Ikuti null safety, lint rules, naming konsisten, widget kecil yang memiliki tanggung jawab jelas, dan pemisahan domain/data/presentation.
- Jangan menaruh seluruh fitur dalam satu file atau satu provider besar.
- Hindari rebuild tidak perlu, query lokal berulang, fetch katalog per item, dan operasi berat di UI isolate.
- Jangan log token, password, PIN, lease token, bukti pembayaran, atau data sensitif.
- Validasi input di client untuk UX, tetapi server tetap menjadi otoritas validasi dan authorization.
- Gunakan loading/error/empty/offline states yang eksplisit; jangan menelan exception.
- Pertahankan data lokal pending saat update app dan proses migration Drift dengan aman.
- Penuhi target P95 dan skenario dataset di PRD sejauh dapat diuji pada environment yang tersedia. Catat perangkat/perintah pengukuran; jangan mengklaim target tanpa bukti.

## Pengujian dan definisi selesai

Tambahkan pengujian untuk unit pricing, domain state, repository/API parsing, outbox, cursor, idempotency, order conflict, lease expiration, shift close, dan status pembayaran. Tambahkan widget tests untuk alur POS/checkout/error/offline yang kritis. Jalankan:

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug` jika Android SDK tersedia.

Jangan mengklaim lulus jika command tidak dijalankan; jelaskan keterbatasan environment. Hindari tes yang memakai backend production atau menghapus data pengguna.

Implementasi selesai hanya jika:

1. Aplikasi Android dapat dijalankan dan navigasi inti berfungsi.
2. Satu siklus login/device → buka shift → pilih produk → order → checkout → receipt selesai terhadap backend dev.
3. Siklus transaksi offline tersimpan lokal dan dapat dipush/pull tanpa duplikasi setelah online kembali.
4. Aturan pembayaran, lease, order conflict, shift, dan printer sesuai PRD.
5. Desain konsisten, modern, terbaca, responsif, serta mendukung state online/offline dan error.
6. Pengujian/analyze/build yang tersedia lulus atau blocker dicatat secara spesifik.
7. Tidak ada tombol palsu, layar utama placeholder, data demo production, atau acceptance criteria yang diklaim selesai tanpa implementasi.

## Laporan akhir wajib

Laporkan layar dan alur yang selesai, struktur/keputusan teknis, endpoint yang dipakai, dependency penting, hasil perintah verifikasi, gap terhadap PRD/backend, serta cara menjalankan aplikasi di Android. Nyatakan jelas bila integrasi nyata masih memerlukan konfigurasi server/printer/perangkat tertentu.

---
