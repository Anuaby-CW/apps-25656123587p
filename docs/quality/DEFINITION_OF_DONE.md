# Definition of Done

Sebuah task dianggap selesai hanya jika seluruh item yang relevan terpenuhi.

## Scope dan behavior

- Objective dan acceptance criteria terpenuhi.
- Tidak ada perubahan behavior di luar scope yang tidak dijelaskan.
- Role Admin/Kasir dan state feature flag telah dipertimbangkan.
- Loading, empty, error, disabled, success, dan retry state ditangani bila relevan.
- Financial/data invariant tidak menghasilkan partial state atau duplicate action.

## Code quality

- Implementasi mengikuti boundary di `docs/engineering/ARCHITECTURE.md`.
- Tidak ada abstraction, provider, atau shared widget baru tanpa kebutuhan nyata.
- Tidak ada literal design token berulang pada UI yang diubah.
- Tidak ada generated/local artifact yang diedit manual.
- Async lifecycle, mounted check, submit lock, dan error handling aman.
- Tidak ada credential atau data sensitif baru di source/docs/log.

## Data dan compatibility

- Perubahan schema memiliki migration dan test upgrade/fresh install.
- Seed, reset, export, dan data lama dievaluasi.
- Feature yang diparkir tidak teraktifkan secara tidak sengaja.
- Destructive operation memiliki target, konfirmasi, dan rollback/recovery story yang jelas.

## Testing

- Formatter lulus untuk file yang diubah.
- `flutter analyze` lulus.
- Test terarah untuk behavior berubah lulus.
- Full suite dijalankan untuk perubahan lintas layer/high-risk.
- Enabled/default matrix dijalankan untuk perubahan feature flag.
- Kebutuhan device/manual test dijalankan atau dinyatakan belum terverifikasi.

## Documentation

- Requirement diperbarui bila behavior berubah.
- `FEATURES.md` atau `DEACTIVATED_FEATURES.md` diperbarui bila status berubah.
- Feature map/architecture/data model diperbarui bila ownership atau contract teknis berubah.
- Test baseline/evidence diperbarui hanya berdasarkan command aktual.
- Open question baru dicatat bila keputusan produk masih dibutuhkan.

## Handoff

Handoff akhir harus menyebut:

1. Outcome pengguna.
2. File/area yang berubah.
3. Command verifikasi dan hasil.
4. Asumsi yang dibuat.
5. Risiko, gap perangkat, atau follow-up yang tersisa.

