# Flutter Engineering Rule

Recommended activation: **Glob** untuk `**/*.dart`, `pubspec.yaml`, dan `android/**`.

@../../docs/engineering/ARCHITECTURE.md
@../../docs/engineering/ENGINEERING_RULES.md
@../../docs/quality/DEFINITION_OF_DONE.md

Sebelum mengedit:

1. Cari pola lokal dan test terkait.
2. Tentukan layer owner, transaction boundary, role, feature flag, dan state lifecycle.
3. Jika menyentuh database, baca `@../../docs/engineering/DATA_MODEL.md`.
4. Jika menyentuh fitur produk, baca requirement ID dan flow yang relevan.

Sesudah mengedit, jalankan verifikasi dari `@../../docs/quality/TESTING.md` dan jangan mengklaim command yang tidak dijalankan.

