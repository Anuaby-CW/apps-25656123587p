# Prompt Template — Implement Flutter Feature

Gunakan template ini untuk Codex, Antigravity, atau coding agent lain. Hapus bagian yang tidak relevan dan isi placeholder dengan keputusan konkret.

```text
Objective
Implementasikan [nama fitur/perubahan] untuk [role/user] agar [outcome terukur].

Source of truth
- Product: PRD.md
- Requirements: [ID dari docs/product/REQUIREMENTS.md]
- User flow: [bagian docs/product/USER_FLOWS.md]
- Design: DESIGN.md dan token aktual di lib/theme/
- Engineering: AGENTS.md serta [dokumen teknis relevan]
- Feature status/flags: [FEATURES.md atau DEACTIVATED_FEATURES.md]

Current behavior
[Jelaskan perilaku sekarang dan masalah yang diamati. Sertakan file/symbol hanya jika sudah diketahui.]

Target behavior
1. [Perilaku pengguna yang harus terlihat]
2. [Business/data invariant]
3. [Error/loading/empty/disabled behavior]
4. [Role, responsive, accessibility, dan localization behavior]

Acceptance criteria
- [Given/When/Then atau hasil yang dapat diuji]
- [Default feature-flag behavior]
- [Enabled behavior bila memakai flag]
- [Data compatibility/migration rule]
- [Peripheral failure rule bila relevan]

Out of scope
- [Hal yang sengaja tidak dikerjakan]
- Jangan melakukan refactor luas yang tidak dibutuhkan acceptance criteria.

Execution instructions
1. Baca source of truth dan telusuri implementasi aktual sebelum mengedit.
2. Jika dokumen, kode, dan test bertentangan, laporkan konflik dan gunakan urutan prioritas AGENTS.md.
3. Buat perubahan terkecil yang memenuhi acceptance criteria.
4. Gunakan pola Riverpod, Drift, theme, dan shared component yang sudah ada.
5. Tambahkan/perbarui test untuk happy path, invalid input, failure, role, dan flag yang relevan.
6. Jalankan verification yang proporsional dari docs/quality/TESTING.md.
7. Perbarui dokumentasi source of truth jika behavior/status berubah.

Required handoff
- Ringkasan outcome.
- Daftar file/area berubah.
- Hasil format/analyze/test/build.
- Asumsi dan keputusan.
- Risiko atau verifikasi perangkat yang belum dilakukan.
```

## Prompt untuk discovery sebelum implementation

```text
Audit requirement [ID/nama fitur] tanpa mengubah kode. Petakan flow UI -> provider -> use case -> repository/DAO -> database/platform, identifikasi invariant, test coverage, feature flag, dan konflik dokumentasi. Hasilkan implementation plan ringkas dengan file target, acceptance criteria, test plan, migration risk, serta pertanyaan yang benar-benar memerlukan keputusan produk.
```

## Prompt untuk review hasil

```text
Review perubahan saat ini terhadap [ID requirement] dan Definition of Done. Cari behavior regression, partial transaction, duplicate submit, role/flag bypass, stale provider state, migration gap, hardcoded design token, async context issue, serta test yang belum mencakup failure path. Jangan mengubah kode; laporkan temuan berurutan berdasarkan severity dengan file/symbol dan saran verifikasi.
```

