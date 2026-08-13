# Flutter Engineering Rules

## Naming dan language

- File Dart: `lower_case_with_underscores.dart`.
- Class/enum/typedef: `UpperCamelCase`.
- Variable/method/provider: `lowerCamelCase`.
- Identifier kode baru menggunakan Bahasa Inggris.
- UI copy menggunakan Bahasa Indonesia; istilah domain/merek seperti QRIS, Bluetooth, ESC/POS, PDF, Manual Brew, Hot/Ice, Add-on, Dine In, dan Take Away boleh dipertahankan.
- Exception identifier Indonesia yang sudah ada bukan preseden untuk kode baru.

## Flutter UI

- Gunakan `Theme.of(context)` serta `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, dan `AppLayout` untuk nilai visual berulang.
- Gunakan `AppPageFrame`/`AppPageHeader` untuk halaman konten standar. Login, shell, fullscreen dialog, POS, atau workspace khusus boleh memakai layout khusus.
- Primitive lintas fitur masuk `lib/widgets/common/`; jangan mempromosikan widget feature-specific hanya untuk menghindari duplikasi kecil.
- Jaga state loading, empty, error, disabled, success, dan destructive confirmation.
- Semua layout baru harus diuji pada compact dan wide; pertimbangkan tinggi layar rendah serta keyboard.
- Tambahkan semantics, label, focus behavior, dan touch target yang sesuai untuk interaksi penting.
- Renderer PDF `pw.*` boleh memiliki token terpisah karena bukan Flutter widget tree, tetapi nilainya harus konsisten dengan brand.

## Riverpod dan async

- Gunakan pola provider yang sudah ada dan tempatkan wiring service/repository di composition root.
- Simpan form controller/animation/local filter pada widget bila lifecycle-nya lokal.
- Hindari `BuildContext` setelah async gap tanpa pemeriksaan `mounted` yang benar.
- Mutation harus menampilkan progress, mencegah submit ganda, menangani error, dan refresh state terdampak.
- Jangan menangkap exception lalu diam; ubah menjadi failure yang dapat ditindaklanjuti atau log diagnostik yang relevan.

## Data dan business rules

- Transaction ditentukan oleh invariant all-or-nothing, bukan sekadar jumlah table.
- Jangan menjalankan printer, drawer, file IO, atau platform call di dalam transaction Drift.
- Pertahankan historical snapshot pada order/items/customer.
- Validate di boundary yang tepat: UI untuk feedback cepat, use case/repository untuk invariant bisnis.
- Hindari hardcoded username/password/user ID baru; gunakan konstanta/lookup terpusat.
- Jangan menyimpulkan schema lama sebagai requirement aktif tanpa UI dan keputusan produk.

## Generated dan local artifacts

Jangan edit manual:

- `*.g.dart`
- `.flutter-plugins-dependencies`
- `GeneratedPluginRegistrant.java`
- `android/local.properties`
- `build/`
- output asset yang memiliki generator resmi

Gunakan generator yang sesuai dan commit hanya artifact yang memang menjadi kebijakan repository.

## Error dan observability

- Pesan pengguna singkat, berbahasa Indonesia, dan menjelaskan tindakan pemulihan.
- Detail teknis sensitif masuk log, bukan dialog pengguna.
- Financial commit, print, dan drawer memiliki status terpisah.
- Log perangkat harus cukup untuk membedakan permission, connection, formatting, send, timeout, dan drawer failure.

## Security dan destructive operations

- Role guard UI bukan satu-satunya validasi operasi sensitif.
- Reset/delete harus menjelaskan target, meminta konfirmasi yang sesuai, dan menjaga referential/business invariant.
- Jangan memperlemah password/auth rule sebagai efek samping task lain.
- Jangan menambahkan credential merchant/API ke source atau Markdown.

## Documentation discipline

- Product decision -> `PRD.md` / requirements.
- Status aktif -> `FEATURES.md`.
- Status diparkir -> `DEACTIVATED_FEATURES.md`.
- Lokasi ownership -> feature map.
- Arsitektur/data rule -> docs engineering.
- Hasil verifikasi -> testing doc.

Jangan menyalin fakta yang sama ke banyak file bila link cukup.

