# Verify Flutter Change

Description: Memverifikasi perubahan Flutter yang sudah ada tanpa memperluas scope.

## Steps

1. Baca diff/file yang berubah dan requirement yang diklaim.
2. Petakan risiko: business invariant, database, role, flag, async lifecycle, responsive UI, accessibility, native bridge, dan peripheral failure.
3. Jalankan `dart format --output=none --set-exit-if-changed lib test tool`.
4. Jalankan `flutter analyze`.
5. Jalankan test paling terarah untuk area perubahan.
6. Jalankan full `flutter test` untuk perubahan lintas layer, schema, checkout, reset, provider global, shared theme/widget, atau feature flag.
7. Jika memakai flag, ulangi test dengan kombinasi `--dart-define` yang sama dengan target build.
8. Verifikasi manual/device untuk hardware/native behavior bila perangkat tersedia; jika tidak, catat gap secara eksplisit.
9. Bandingkan hasil terhadap `docs/quality/DEFINITION_OF_DONE.md`.
10. Laporkan command aktual, PASS/FAIL, regression, dan pekerjaan tersisa. Jangan menulis PASS untuk command yang tidak dijalankan.

