# User Flows

Dokumen ini menjelaskan urutan perilaku lintas layar/layer. Detail visual tetap mengikuti `DESIGN.md`; detail requirement mengikuti `docs/product/REQUIREMENTS.md`.

## Kasir — login dan membuka shift

1. Kasir login dengan akun aktif.
2. Sistem mengarahkan ke POS.
3. Jika tidak ada shift aktif, POS meminta Kasir membuka shift dan memasukkan modal awal.
4. Jika shift aktif dimiliki Kasir lain, akses POS ditahan sampai pemilik shift login atau sesi diganti.
5. Setelah shift aktif untuk user tersebut, katalog dan keranjang dapat digunakan.

Postcondition: satu shift aktif memiliki identitas Kasir, waktu mulai, dan modal awal di settings lokal.

## Kasir — checkout tunai

1. Kasir memilih produk aktif dan opsi yang relevan.
2. Item masuk ke cart; konfigurasi identik boleh digabung.
3. Kasir memilih Dine In atau Take Away dan mengisi nama pelanggan.
4. Sistem menghitung total serta menawarkan quick-cash.
5. Kasir memasukkan uang diterima; nilai harus cukup.
6. Sistem memvalidasi stok tracked dan menyimpan seluruh data transaksi secara atomik.
7. Setelah commit berhasil, sistem mencoba mencetak struk.
8. Jika cash drawer aktif dan kondisinya terpenuhi, sistem mencoba membuka drawer.
9. Kasir menerima status transaksi, kembalian, dan peringatan periferal bila ada.

Postcondition: order berstatus lunas, payment dan transaction tersedia, stock movement tercatat, serta cart dibersihkan sesuai alur sukses.

Failure rule: kegagalan sebelum commit tidak boleh menyisakan transaksi parsial; kegagalan printer/drawer setelah commit tidak boleh mengubah transaksi menjadi gagal.

## Kasir — petty cash dan tutup shift

1. Selama shift aktif, Kasir mencatat kas keluar dengan nominal dan keperluan.
2. Saat tutup shift, sistem menghitung `modal awal + penjualan tunai - petty cash`.
3. Kasir memasukkan jumlah uang fisik.
4. Sistem menampilkan expected cash dan selisih.
5. Sistem menutup state shift lalu mencoba output thermal/drawer sesuai konfigurasi.
6. Kasir dapat membagikan PDF yang memuat ringkasan serta rincian petty cash.

Catatan: histori rekonsiliasi shift lengkap belum dipersist dalam tabel khusus.

## Admin — monitoring dan laporan

1. Admin login dan masuk Dashboard.
2. Admin memilih periode preset atau rentang khusus.
3. Sistem menampilkan metrik hanya dari transaksi/order lunas.
4. Admin dapat membuka detail riwayat transaksi.
5. Admin dapat mengekspor laporan PDF ke folder Downloads aplikasi.
6. Aksi ekspor yang relevan dicatat dalam audit trail.

## Admin — pengelolaan katalog dan stok

1. Admin membuat/mengubah kategori, produk, add-on, atau beans.
2. Sistem memvalidasi parent, tipe, relasi, harga, dan aturan penghapusan.
3. Produk tracked memiliki inventory dan threshold.
4. Admin melakukan restock/koreksi atau mengubah threshold.
5. Sistem menyimpan current balance, stock movement, dan audit event yang relevan.

Invariant: master yang sudah direferensikan histori tidak boleh dihapus dengan cara yang merusak snapshot/transaksi lama.

## Admin — pengelolaan user

1. Admin membuat atau mengubah akun Admin/Kasir.
2. Sistem memvalidasi username, role, password, dan status aktif.
3. Sistem mencegah hilangnya Admin aktif terakhir.
4. Sistem mencegah perubahan berbahaya terhadap akun sendiri, pemilik shift aktif, atau user dengan histori yang dilindungi.

## Admin — reset data

1. Admin memilih satu kelompok reset yang tersedia.
2. UI menjelaskan data yang terpengaruh dan meminta konfirmasi/password.
3. Sistem memverifikasi role dan password Admin.
4. Reset berjalan atomik serta memulihkan dampak stock jika transaksi dihapus.
5. Provider/state yang relevan di-refresh; cart in-memory ditangani oleh alur UI terkait.

## Fitur diparkir

Alur nomor meja, Bayar Nanti, Orders Queue, dan fitur nonaktif lain tidak boleh dimasukkan ke flow standar. Gunakan `DEACTIVATED_FEATURES.md` dan `docs/features/FEATURE_FLAGS.md` ketika scope eksplisit meminta reaktivasi.

