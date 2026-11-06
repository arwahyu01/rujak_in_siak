# Prompt Implementasi Backend POS Rujak.In.Siak

Salin prompt di bawah ini ke coding agent yang memiliki akses ke seluruh repository.

---

## Peran dan tujuan

Anda adalah senior Laravel engineer yang bertanggung jawab menyelesaikan backend MVP RUJAK.IN.SIAK POS. Implementasikan backend yang dapat melayani aplikasi Flutter Android online dan offline-first sesuai PRD, bukan hanya halaman administrasi.

Sumber kebenaran produk adalah `../PRD.md`. Baca PRD lengkap, terutama bagian 2–3, seluruh Module 01–13, arsitektur Laravel, desain database, API Contract, acceptance tests, non-functional requirements, dan roadmap fase. Baca juga `AGENTS.md` yang berlaku dan seluruh kode backend sebelum mengubah apa pun.

## Kondisi repository saat mulai

Backend adalah Laravel 13 dengan aplikasi Inertia/back-office yang telah memiliki sebagian model, migrasi, policy, action pembayaran/void/refund, katalog, shift, laporan, audit, dan tampilan admin. Jangan mengasumsikan fitur yang memiliki model atau halaman berarti alur produk sudah selesai.

Area gap yang wajib diaudit dan ditutup:

1. API ter-version `/api/v1` untuk Flutter belum tampak; `bootstrap/app.php` saat ini hanya mendaftarkan routing web.
2. Autentikasi API Sanctum, sesi/token, device registration/revocation, login history, PIN policy, dan signed offline authorization lease belum lengkap/terlihat.
3. Entitas serta lifecycle order, order item/modifier, versioning, hold/resume/cancel, optimistic concurrency, dan konversi order ke sale perlu diaudit dan dilengkapi.
4. Checkout API atomik, kalkulasi uang integer rupiah, pricing/discount/tax/service charge yang deterministik, snapshot transaksi, nomor struk, dan idempotency perlu diaudit dan dilengkapi.
5. Sinkronisasi push/pull/bootstrap/status, cursor, idempotency key, deduplikasi, ordering, retry-safe response, konflik, serta audit/reconciliation perlu diaudit dan dilengkapi. Halaman `/sync` yang hanya membaca event bukan implementasi sinkronisasi.
6. API shift open/close, cash movement, closing snapshot immutable, pending sync, dan exception reconciliation perlu diaudit dan dilengkapi.
7. API transaksi, payment, katalog, laporan, response resources, dokumentasi OpenAPI, dan validasi lintas business/outlet/device perlu diaudit.
8. Pengujian yang ada masih berupa contoh. Acceptance criteria PRD untuk backend perlu ditutup dengan tes otomatis.

Daftar ini adalah titik awal, bukan pengganti audit terhadap PRD dan kode aktual. Verifikasi setiap gap sebelum mengubahnya.

## Hasil yang diminta

Selesaikan backend MVP Phase A–C dan backend yang diperlukan untuk Phase B offline transaction/synchronization sesuai PRD. Implementasi harus siap dipakai Flutter melalui API; back-office web yang ada tetap berjalan.

Jangan implementasikan fitur yang PRD tetapkan di luar MVP: inventory, recipe/HPP, purchasing/supplier, finance/expenses, loyalty, KDS, QR self ordering, AI, forecasting, dan multi-outlet aktif. Jangan membuat data dashboard/report palsu. Printer Bluetooth ESC/POS adalah tanggung jawab aplikasi Android; backend hanya menyediakan data transaksi/receipt yang diperlukan.

## Urutan kerja wajib

### Tahap 1 — Audit dan rencana

1. Petakan setiap requirement PRD yang relevan menjadi `sudah lengkap`, `sebagian`, `belum ada`, atau `tidak berlaku untuk backend`.
2. Periksa semua route, migration, model, action/service, policy, middleware, seeder, UI admin, konfigurasi, dan tes.
3. Periksa status dependency dan versi aktual dari lockfile; jangan upgrade major atau mengganti arsitektur tanpa kebutuhan dan alasan kompatibilitas.
4. Buat rencana implementasi berurutan berdasarkan dependensi. Catat keputusan teknis penting dalam ADR singkat jika memang ada pilihan arsitektur yang belum diputuskan PRD.
5. Jangan berhenti setelah menyajikan audit. Lanjutkan implementasi sampai kriteria selesai atau ada blocker eksternal yang nyata.

### Tahap 2 — Fondasi data dan API

1. Pertahankan modular monolith Laravel. Ikuti pola repository yang sudah ada; controller hanya mengurus HTTP, logika bisnis berada di Action/Service.
2. Tambahkan API routes `/api/v1`, Form Request, API Resources, response/error schema konsisten, policy/permission, rate limit yang sesuai, dan dokumentasi OpenAPI.
3. Gunakan Sanctum sesuai kompatibilitas Laravel yang terpasang. Jangan membuat skema token kriptografi sendiri tanpa kebutuhan.
4. Terapkan isolasi `business_id`, `outlet_id`, dan `device_id` di setiap query/mutasi yang relevan. Jangan percaya ID tenant dari payload tanpa memverifikasi relasinya dengan identitas terautentikasi.
5. Gunakan UUID untuk identitas global, foreign key, unique constraint, index berdasarkan query, transaksi DB, dan integer untuk seluruh nominal rupiah. Hindari float/decimal untuk perhitungan uang.
6. Migration baru harus aman untuk data yang sudah ada dan dapat di-rollback; jangan mengedit migration yang sudah berpotensi dipakai tanpa alasan kuat.

### Tahap 3 — Authentication, users, devices, catalog

Implementasikan endpoint yang dipersyaratkan API contract: login/logout/refresh/me, device registration, katalog produk/kategori, serta fitur user/role yang memang termasuk scope. Terapkan permission server-side. Implementasikan lease offline maksimum 72 jam, expiry, authentication version, permission snapshot, device binding, signed verification, dan aturan pencabutan sesuai PRD. Jangan mengklaim validasi online ketika perangkat offline.

Katalog harus menghormati status aktif/tersedia, snapshot harga histori, dan umur katalog offline. Master data hanya dapat diubah saat terhubung ke server. Import/export hanya implementasikan bila diwajibkan scope fase atau sudah menjadi bagian kode berjalan dan tidak merusak prioritas MVP.

### Tahap 4 — Orders, checkout, pricing, payments

1. Implementasikan lifecycle order Draft/Held/Resumed/Converted/Cancelled, order version, `base_version`, konflik HTTP yang konsisten, dan batas satu sale per order.
2. Implementasikan kalkulasi harga PRD di satu jalur domain yang deterministik: rupiah integer, pembulatan half-up, diskon, alokasi diskon, pajak per baris, service charge, dan snapshot konfigurasi/harga saat transaksi.
3. Checkout harus transaksional: validasi shift/device/order, simpan sale + item snapshot + payment entries + audit/sync event, tandai order Converted, dan cegah partial commit atau checkout ganda. Gunakan unique constraint/idempotency sebagai perlindungan akhir dari race condition.
4. Pisahkan lifecycle sale dari payment status. Terapkan seluruh state payment dan agregat confirmed/awaiting/outstanding/refunded dari PRD.
5. Terapkan split payment, tunai dan kembalian, non-tunai Awaiting Verification, verifikasi/penolakan oleh petugas berbeda dari pencatat, nominal partial/overpayment rules, audit verification, serta larangan void yang tepat.
6. Void memerlukan alasan dan otorisasi; sale tidak dihapus. Refund mengikuti batas nominal terkonfirmasi yang belum direfund, alasan dan audit; operasi harus idempotent/anti double-submit.

### Tahap 5 — Shifts dan synchronization

1. Implementasikan shift open/close dan cash movements sesuai PRD. Hitung expected cash dari transaksi tunai terkonfirmasi, opening cash, cash-in/out; simpan closing snapshot immutable, variance, status pending sync/exception, dan rekonsiliasi.
2. Implementasikan event contract persis sesuai Module 11: push, pull, bootstrap, status; cursor stabil, pagination, schema version, event ordering, idempotency per device/event, validasi lease untuk transaksi offline, serta response per event yang aman di-retry.
3. Pastikan push batch bersifat atomik pada tingkat event yang ditentukan kontrak; satu event gagal tidak boleh membuat hasil ambigu. Jangan mengandalkan last-write-wins untuk order.
4. Pull hanya mengirim perubahan yang berhak dilihat user/outlet dan setelah cursor; cegah kebocoran antar business/outlet. Perubahan payment verification dan konflik harus dapat diterima perangkat melalui pull.
5. Tangani event duplicate, out-of-order, retry, device revoked, lease expired, stale schema, order version conflict, serta sinkronisasi shift exception sesuai PRD. Pending transaction valid tetap dapat disinkronkan setelah lease kedaluwarsa jika kontrak PRD menyatakan demikian.
6. Halaman back-office sync harus menampilkan keadaan aktual dari event dan status rekonsiliasi; jangan mengklaim event pending semata dari `processed_at` jika status bisnis berbeda.

### Tahap 6 — Reports, audit, admin compatibility

Lengkapi dashboard dan laporan Phase C sesuai definisi metrik PRD: periode, transaksi, pembayaran, diskon, refund, shift, dan export Excel/PDF bila diwajibkan. Filter tanggal mengikuti timezone business. Pastikan void/refund/awaiting tidak dihitung sebagai penjualan lunas secara keliru. Pertahankan kompatibilitas halaman admin yang sudah ada dan arahkan keduanya ke action/domain logic yang sama agar aturan bisnis tidak diduplikasi.

## Aturan engineering dan keamanan

- Ikuti naming, folder, dan gaya kode repository; hindari abstraksi berlebihan.
- Semua mutasi sensitif harus punya validasi, authorization, transaksi DB bila perlu, audit trail, dan respons retry yang aman.
- Cegah mass assignment, IDOR, akses lintas tenant, replay event, double checkout/refund, dan verifikasi pembayaran sendiri.
- Jangan mengembalikan stack trace, token, bukti pembayaran privat, atau data tenant lain.
- Gunakan eager loading/pagination; hindari N+1 dan query agregasi yang salah cakupan.
- Jangan menghapus atau mereset data pengguna, database, atau perubahan kerja yang sudah ada.
- Jangan menambahkan service eksternal wajib seperti Redis/payment gateway; PRD tidak mewajibkannya untuk MVP.
- Bila PRD bertentangan dengan implementasi lama, PRD menjadi acuan kecuali ada constraint teknis nyata; jelaskan dan dokumentasikan penyimpangan.
- Jangan mengubah kontrak API atau PRD secara diam-diam.

## Pengujian dan verifikasi

Tambahkan feature/unit tests untuk seluruh aturan kritis yang diimplementasikan, minimal:

- Authentication, permission, device binding, tenant isolation, lease expiry/revocation.
- Product access/katalog dan snapshot harga.
- Order lifecycle, optimistic concurrency, satu order satu sale.
- Checkout rollback, idempotency, concurrency/double submit, kalkulasi integer.
- Split/cash/non-cash payment, verifikasi petugas berbeda, partial verification, reject, void, refund, audit.
- Shift open/close, expected cash, variance, closing snapshot, offline close/reconciliation.
- Sync push/pull/bootstrap, duplicate, out-of-order, cursor pagination, conflicts, revoked device, retry.
- Reports filters/timezone/metric definitions.

Jalankan pemeriksaan yang didukung environment: test suite Laravel, formatter/static checks yang telah dikonfigurasi, migration pada database uji, dan build asset jika mengubah UI. Jangan mengklaim lulus jika tidak dijalankan; laporkan command dan hasil. Jangan memakai database production atau menghapus data lokal.

## Definisi selesai

Pekerjaan selesai hanya jika:

1. Seluruh API contract dan aturan backend MVP di PRD telah dipetakan dan diimplementasikan atau setiap pengecualian dijelaskan dengan alasan yang dapat ditinjau.
2. Migrations, model, request validation, authorization, resources, actions/services, routes, dan OpenAPI konsisten.
3. Back-office lama tetap berjalan dan tidak memiliki jalur yang melewati aturan domain/API.
4. Acceptance tests kritis lulus atau kegagalan lingkungan dijelaskan dengan bukti.
5. Tidak ada placeholder, stub, TODO implementasi, data demo yang dipakai seolah data aktual, atau klaim fitur selesai yang tidak terbukti.
6. Dokumentasi setup, migration, API auth, sync contract, dan cara menjalankan tes diperbarui.

## Laporan akhir wajib

Laporkan secara ringkas:

1. Fitur backend yang diselesaikan, dikelompokkan menurut modul PRD.
2. Perubahan migration/API penting dan endpoint yang ditambahkan.
3. Hasil verifikasi dengan command yang benar-benar dijalankan.
4. Gap yang masih tersisa, blocker, atau keputusan yang memerlukan product owner.
5. Risiko kompatibilitas/migrasi dan langkah deploy yang diperlukan.

Jangan menyatakan backend “selesai seluruhnya” jika ada acceptance criteria belum terpenuhi. Prioritaskan correctness dan integritas transaksi daripada menandai lebih banyak checklist.

---
