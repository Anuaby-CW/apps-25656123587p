# Implement Flutter Feature

Description: Menjalankan discovery, implementasi, test, dan handoff untuk satu perubahan Flutter yang scope-nya sudah jelas.

## Steps

1. Baca `AGENTS.md` dan prompt/requirement yang diberikan pengguna.
2. Identifikasi ID requirement, role, user flow, feature flag, acceptance criteria, serta out-of-scope.
3. Telusuri flow aktual dari UI ke provider/use case/repository/DAO/platform dan cari test yang sudah ada.
4. Jika terdapat konflik source of truth, hentikan keputusan yang mengubah scope dan minta klarifikasi; konflik teknis yang dapat dibuktikan boleh diperbaiki dengan perubahan terkecil.
5. Buat implementation plan dengan file target, invariant, failure behavior, dan test plan.
6. Implementasikan perubahan terkecil mengikuti arsitektur dan design system lokal.
7. Tambahkan/perbarui test untuk happy path dan failure/role/flag/data case yang relevan.
8. Jalankan formatter, `flutter analyze`, test terarah, dan full suite bila risikonya lintas layer.
9. Perbarui PRD/requirement/registry/feature map/test evidence hanya bila contract terkait berubah.
10. Berikan handoff: outcome, file berubah, hasil verifikasi, asumsi, dan gap yang tersisa.

