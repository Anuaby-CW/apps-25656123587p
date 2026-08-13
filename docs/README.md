# Documentation Map

Dokumentasi dipisah berdasarkan jenis keputusan agar agent tidak perlu memuat seluruh konteks pada setiap task.

| Dokumen | Fungsi | Kapan diperbarui |
|---|---|---|
| `AGENTS.md` | Aturan permanen repository dan routing konteks | Saat konvensi engineering/workflow berubah |
| `PRD.md` | Tujuan produk, pengguna, scope, dan batas produk | Saat keputusan produk berubah |
| `FEATURES.md` | Registry fitur aktif dan statusnya | Saat fitur aktif ditambah/diubah/dihapus |
| `DEACTIVATED_FEATURES.md` | Registry fitur yang sengaja diparkir | Saat fitur dinonaktifkan/diaktifkan kembali |
| `DESIGN.md` | Design system dan token visual | Saat bahasa visual atau token berubah |
| `docs/product/REQUIREMENTS.md` | Requirement fungsional/nonfungsional dengan ID stabil | Saat behavior/acceptance berubah |
| `docs/product/USER_FLOWS.md` | Alur pengguna lintas layar/layer | Saat urutan interaksi berubah |
| `docs/product/OPEN_QUESTIONS.md` | Keputusan yang belum dibuat | Saat pertanyaan dijawab/ditambah |
| `docs/engineering/ARCHITECTURE.md` | Boundary layer dan dependency direction | Saat struktur teknis berubah |
| `docs/engineering/DATA_MODEL.md` | Entitas, invariant, migrasi, dan persistence | Saat schema/data rule berubah |
| `docs/engineering/ENGINEERING_RULES.md` | Konvensi implementasi Flutter | Saat pola engineering berubah |
| `docs/engineering/FEATURE_MAP.md` | Peta fitur ke module/source code | Saat lokasi ownership berubah |
| `docs/features/FEATURE_FLAGS.md` | Kontrak flag, dependency, dan reaktivasi | Saat flag berubah |
| `docs/quality/TESTING.md` | Strategi dan command verifikasi | Saat test strategy/tooling berubah |
| `docs/quality/DEFINITION_OF_DONE.md` | Exit criteria setiap perubahan | Saat quality gate berubah |
| `docs/prompts/IMPLEMENT_FEATURE.md` | Template prompt implementasi | Saat workflow agent diperbaiki |

## Aturan anti-duplikasi

- Status produk aktif hanya ditentukan oleh `FEATURES.md`.
- Status fitur nonaktif hanya ditentukan oleh `DEACTIVATED_FEATURES.md`.
- Detail flag hanya berada di `docs/features/FEATURE_FLAGS.md`.
- Requirement memakai ID stabil dan hanya didefinisikan di `docs/product/REQUIREMENTS.md`.
- `PRD.md` merujuk requirement; tidak menyalin seluruh tabel requirement.
- Bukti lokasi kode berada di `docs/engineering/FEATURE_MAP.md`, bukan di PRD.
- Hasil test terbaru dicatat di `docs/quality/TESTING.md`, bukan disalin ke semua dokumen.

Arsip dokumen sebelum restrukturisasi berada di `docs/archive/2026-07-21/` dan bukan source of truth aktif.

## Entry point agent

- Codex membaca `AGENTS.md` di root sebagai instruksi repository permanen.
- Antigravity memakai `.agents/rules/project-context.md`; atur activation menjadi **Always On** melalui panel Customizations.
- Atur `.agents/rules/flutter-engineering.md` sebagai rule **Glob** untuk `**/*.dart`, `pubspec.yaml`, dan `android/**`.
- Workflow berulang tersedia di `.agents/workflows/` dan dapat dipanggil sebagai slash command sesuai nama file.
- `.agents/AGENT.md` hanya compatibility pointer dan tidak boleh menjadi lokasi aturan baru.
