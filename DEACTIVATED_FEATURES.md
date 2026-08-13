# Deactivated Features Registry — Talaga Coffee POS

> Source of truth untuk fitur yang dipertahankan di repository tetapi tidak tersedia pada build standar per 21 Juli 2026. Detail flag dan prosedur verifikasi berada di `docs/features/FEATURE_FLAGS.md`.

## Registry fitur diparkir

| ID | Fitur | Status default | Flag / mekanisme | Alasan atau dampak |
|---|---|---|---|---|
| OFF-01 | Shortcut `Pelanggan Umum` | nonaktif | `FEATURE_CUSTOMER_NAME_SHORTCUT` | Nama pelanggan harus diketik manual |
| OFF-02 | Nomor meja | nonaktif | `FEATURE_TABLE_NUMBER` | Dine In tidak meminta meja dan order baru menyimpan `null` |
| OFF-03 | Bayar Nanti | nonaktif | `FEATURE_PAY_LATER` | Request `payNow: false` ditolak |
| OFF-04 | Orders Queue | nonaktif | `FEATURE_ORDERS_QUEUE` | Menu Pesanan dan pengelolaan order belum lunas tidak tersedia |
| OFF-05 | Akses POS untuk Admin | nonaktif | `FEATURE_ADMIN_POS_ACCESS` | POS hanya tersedia untuk Kasir |
| OFF-06 | Metrik order dibatalkan | nonaktif | `FEATURE_CANCELLED_ORDERS_REPORT` | Kartu laporan dan baris PDF disembunyikan |
| OFF-07 | Switch pengelolaan stok | nonaktif | `FEATURE_INVENTORY_MANAGEMENT_SETTING` | Panel setting disembunyikan; halaman stok tetap aktif |
| OFF-08 | CRUD metode Manual Brew | nonaktif | tidak memiliki flag aktif | Manual Brew aktif hanya memakai beans dan Hot/Ice |

## Artefak kompatibilitas tanpa UI aktif

- `ProductFavorites` beserta provider/repository/test.
- `ManualBrewMethods` beserta seed/DAO/repository dan snapshot order lama.
- `CafeTables`; checkout aktif tidak membaca master meja.
- Order belum lunas, penerimaan pembayaran tertunda, pembatalan, dan perubahan status pada Orders Queue.
- Field agregasi laporan untuk status lama yang masih diperlukan query/data kompatibilitas.

Keberadaan table, enum, provider, repository, use case, atau test kompatibilitas tidak boleh ditafsirkan sebagai requirement aktif.

## Dependency reaktivasi

- Aktifkan Bayar Nanti bersama Orders Queue agar order belum lunas dapat dikelola.
- Aktifkan Nomor Meja hanya setelah acceptance Dine In dan kompatibilitas data lama diverifikasi.
- Akses POS Admin mengubah batas role dan harus diuji pada menu, route guard, shift bypass, serta data operation.
- Flag laporan/pengaturan boleh diaktifkan sendiri, tetapi tetap memerlukan test default dan enabled.

## Kebijakan data

- Penonaktifan tidak menghapus schema atau data lama.
- Menonaktifkan kembali dilakukan dengan build tanpa flag atau flag bernilai `false`.
- Penghapusan artefak kompatibilitas membutuhkan migration/cleanup plan terpisah.
- Jangan mengubah status registry ini hanya karena kode pendukung masih dikompilasi.

## Cara kerja

- Kontrak flag dan command build: `docs/features/FEATURE_FLAGS.md`
- Workflow Antigravity: `.agents/workflows/reactivate-feature.md`
- Prompt lintas-agent: gunakan `docs/prompts/IMPLEMENT_FEATURE.md` dengan requirement reaktivasi eksplisit.
- Setelah reaktivasi menjadi default, pindahkan fitur ke `FEATURES.md` dan perbarui PRD/requirement/test evidence.

