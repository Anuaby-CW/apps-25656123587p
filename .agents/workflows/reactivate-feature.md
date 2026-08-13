# Reactivate Parked Feature

Description: Mengaktifkan kembali fitur yang tercatat di `DEACTIVATED_FEATURES.md` dengan menjaga kompatibilitas data.

## Steps

1. Baca `DEACTIVATED_FEATURES.md` dan `docs/features/FEATURE_FLAGS.md`.
2. Pastikan pengguna menyebut fitur yang akan diaktifkan dan apakah perubahan hanya untuk build flag atau menjadi default produk.
3. Petakan dependency; Pay Later harus dinilai bersama Orders Queue.
4. Audit UI entry point, role guard, use case/repository, schema/data lama, report/export, dan test kompatibilitas.
5. Tetapkan acceptance criteria untuk default-off dan enabled-state.
6. Aktifkan melalui flag yang tersedia; jangan menghapus schema/data lama sebagai bagian reaktivasi.
7. Jalankan test default tanpa flag.
8. Jalankan test dengan kombinasi `--dart-define` target.
9. Uji data lama, role access, duplicate payment/stock restore, dan rollback ke flag `false`.
10. Jika fitur menjadi default aktif, pindahkan status ke `FEATURES.md`, perbarui requirement/user flow/feature map, dan catat evidence test.

