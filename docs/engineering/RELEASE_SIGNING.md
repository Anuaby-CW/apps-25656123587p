# Android Release Signing

Release Talaga Coffee POS tidak boleh memakai debug signing. Konfigurasi build
bersifat fail-closed: task release hanya berjalan ketika empat nilai berikut
tersedia lengkap sebagai Gradle property atau environment variable:

- `TALAGA_RELEASE_STORE_FILE`
- `TALAGA_RELEASE_STORE_PASSWORD`
- `TALAGA_RELEASE_KEY_ALIAS`
- `TALAGA_RELEASE_KEY_PASSWORD`

`TALAGA_RELEASE_STORE_FILE` wajib berupa path absolut ke file keystore di luar
repository. Jangan menyimpan keystore, password, alias privat, atau nilai
sebenarnya di source, dokumentasi, command history, log, maupun file project
Gradle. Untuk workstation, Gradle property dapat disimpan di
`%USERPROFILE%\.gradle\gradle.properties` yang berada di luar repository.
Gunakan slash `/` pada path Windows di file properties.

## Gate sebelum distribusi

Pemilik release harus menyediakan dan mencadangkan keystore melalui media
rahasia yang disetujui. Setelah trust chain Java/Gradle sehat, verifikasi:

```powershell
flutter build apk --release
powershell -NoProfile -ExecutionPolicy Bypass -File tool/verify_release_apk.ps1 `
  -ApkPath <path-ke-apk> `
  -ExpectedSha256 <fingerprint-sha256-dari-release-record-privat>
```

Verifier menjalankan `apksigner verify` dengan warning sebagai error, menolak
APK dengan signer ambigu, dan memastikan fingerprint signer cocok dengan
fingerprint produksi yang diberikan secara eksternal. Jangan menyalin
fingerprint aktual ke source atau dokumentasi repository. Catat fingerprint
sertifikat dan lokasi backup di release record privat, bukan di Git. Artifact
belum boleh disebut production-ready sebelum build release berhasil, signature
dan identitas signer diverifikasi, lalu instalasi/update diuji pada perangkat
Android yang mewakili target.

Perintah di atas memverifikasi APK. Jika distribusi memakai Android App Bundle,
verifikasi AAB dan sertifikat upload melalui tooling resmi yang sesuai, lalu
pastikan Play App Signing certificate cocok dengan release record privat;
`apksigner` bukan verifier untuk file `.aab`.

Build debug tetap dapat berjalan tanpa konfigurasi release. Jika task release
dijalankan tanpa konfigurasi lengkap, build harus berhenti dengan daftar nama
property yang belum tersedia tanpa menampilkan nilai rahasia.
