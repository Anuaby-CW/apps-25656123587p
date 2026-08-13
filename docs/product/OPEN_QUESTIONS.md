# Open Questions and Decisions Needed

Item di sini bukan requirement. Agent tidak boleh memilih jawaban yang mengubah scope tanpa persetujuan pengguna. Setelah keputusan dibuat, pindahkan hasilnya ke PRD/requirement yang sesuai dan hapus pertanyaannya.

## Product dan operasi

1. Apakah QRIS akan memakai DANA, provider lain, atau agregator? Bagaimana callback, retry, settlement, dan rekonsiliasinya bekerja dalam produk offline-first?
2. Apakah nomor HP pelanggan sengaja dihapus permanen dari checkout? Apakah customer lookup, deduplikasi, histori, CRM, atau loyalty dibutuhkan?
3. Apakah diskon, promo, dan pajak akan menjadi fitur, atau kolom schema hanya dipertahankan untuk kompatibilitas?
4. Apakah hasil tutup shift harus dipersist agar Admin dapat melihat histori modal, expected cash, uang fisik, petty cash, selisih, serta penutup shift?
5. Apakah pengaturan printer/cash drawer tetap hanya untuk Kasir?
6. Bagaimana identitas “Nama kasir” di Settings harus bekerja ketika terdapat banyak akun Kasir?
7. Apakah target produk tetap single-outlet, atau multi-outlet/multi-device akan masuk roadmap?

## Security dan data

8. Apakah password awal, hash SHA-256 dengan pepper tetap, password minimum, dan sesi in-memory memenuhi standar produksi?
9. Apakah pengguna wajib mengganti password pada login pertama dan apakah rate limiting diperlukan?
10. Apakah sesi login perlu dipersist setelah aplikasi dimulai ulang?
11. Apakah relasi database perlu dimigrasikan ke foreign key/check constraint eksplisit?
12. Berapa kebijakan retensi, backup/restore, proteksi PDF Downloads, recovery time, dan kapasitas data resmi?
13. Kontrak periode laporan harus memakai end inklusif atau interval setengah-terbuka `[start, end)`?

## Platform dan kualitas

14. Berapa minimum/target Android serta matriks perangkat, printer, kertas, dan cash drawer yang didukung?
15. Berapa target startup, checkout latency, penggunaan memori, ukuran database, dan volume transaksi?
16. Kapan production signing, dependency SQLite berlabel EOL, dan warning kompatibilitas Gradle harus diselesaikan?
17. Apakah CI, target coverage, integration test, serta pengujian upgrade database/perangkat nyata wajib sebelum rilis?

## Dokumentasi dan artefak

18. Apakah `api-dana.md` hanya referensi riset atau akan menjadi kontrak integrasi resmi?
19. Apa fungsi `flutter_01.png` di root, dan apakah file tersebut merupakan referensi visual yang masih aktif?
20. Apakah `DESIGN.md` hasil Stitch sudah sepenuhnya selaras dengan token Flutter aktual, atau perlu reconciliation design-to-code?

