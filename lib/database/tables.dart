import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// =========================================================
// SECTION 0: TABEL USERS (KASIR) - BARU!
// =========================================================
class Users extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  // Nama Kasir (misal: "Budi", "Siti")
  TextColumn get name => text().withLength(min: 1, max: 50)();

  // PIN atau Password (untuk login nanti)
  // Sementara simpan angka biasa misal "123456"
  TextColumn get pin => text().withLength(min: 4, max: 6)();

  // Role: "ADMIN" (Bisa hapus data) atau "CASHIER" (Cuma bisa transaksi)
  TextColumn get role => text().withDefault(const Constant('CASHIER'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft Delete

  @override
  Set<Column> get primaryKey => {id};
}

// =========================================================
// SECTION 1: TABEL PRODUK (PRODUCTS)
// Digunakan untuk menyimpan data barang jualan
// =========================================================
class Products extends Table {
  // --- KOLOM PRIMARY KEY ---
  // Kita pakai UUID (String acak) agar unik saat sinkronisasi cloud nanti.
  // clientDefault: Artinya kalau kita gak isi, otomatis diisikan UUID baru.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  // --- KOLOM DATA UTAMA ---
  // Nama produk, minimal 1 karakter, maksimal 100 karakter.
  TextColumn get name => text().withLength(min: 1, max: 100)();

  // Harga produk. Simpan sebagai INTEGER (Rp 15000), jangan pakai koma/float.
  // nullable: false (wajib diisi).
  IntColumn get price => integer()();

  // Stock (Persediaan).
  // nullable: true (boleh kosong dulu untuk tahap awal).
  IntColumn get stock => integer().nullable()();

  // --- KOLOM KHUSUS SINKRONISASI (META DATA) ---
  // Wajib ada untuk keperluan upload ke server Laravel nanti.

  // Kapan dibuat. Default: Jam sekarang (currentDateAndTime).
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Kapan terakhir diedit. Default: Jam sekarang.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Kapan dihapus (Soft Delete). Kalau terisi tanggal, anggap data ini sampah.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // --- PENGATURAN PRIMARY KEY ---
  @override
  Set<Column> get primaryKey => {id};
}

// =========================================================
// SECTION 3: TABEL TRANSAKSI (HEADER) belum eksekusi sudah update
// Menyimpan data umum: Total belanja, Uang bayar, Metode bayar
// =========================================================
class Transactions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  // --- TAMBAHAN RELASI KE USER ---
  // Siapa yang menangani transaksi ini?
  // nullable: true (Jaga-jaga kalau usernya dihapus, history tetap ada)
  TextColumn get cashierId => text().nullable().references(Users, #id)();

  // SNAPSHOT NAMA KASIR (PENTING!)
  // Kenapa? Kalau akun "Si Budi" dihapus, kita tetap tahu di struk tertulis "Kasir: Budi"
  // Bukan "Unknown User".
  TextColumn get cashierName => text().withDefault(const Constant('Admin'))();

  // Total belanja (misal: 27000)
  IntColumn get totalAmount => integer()();

  // Uang yang diterima dari pelanggan (misal: 50000)
  IntColumn get cashReceived => integer()();

  // Kembalian (misal: 23000)
  IntColumn get cashReturned => integer()();

  // --- FUTURE PROOF: METODE PEMBAYARAN ---
  // Kita simpan sebagai String dulu: "CASH", "QRIS", "DEBIT", "TRANSFER"
  // Untuk sekarang, kita akan selalu isi dengan "CASH".
  TextColumn get paymentMethod => text().withDefault(const Constant('CASH'))();

  // Kapan transaksi terjadi
  DateTimeColumn get transactionDate =>
      dateTime().withDefault(currentDateAndTime)();

  // Kolom Sync (Masa Depan)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// =========================================================
// SECTION 4: TABEL ITEM TRANSAKSI (DETAIL)
// Menyimpan rincian barang apa saja yang dibeli
// =========================================================
class TransactionItems extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  // Link ke Tabel Transactions (Header)
  // Ini ibarat tali pengikat: "Item ini punya struk nomor berapa?"
  TextColumn get transactionId => text().references(Transactions, #id)();

  // Link ke Produk Asli (Biar tahu ini produk ID mana)
  TextColumn get productId => text().references(Products, #id)();

  // --- SNAPSHOT DATA (PENTING!) ---
  // Kita simpan Nama & Harga saat transaksi terjadi.
  // Jadi kalau besok harga produk induk naik, laporan transaksi lama GAK BERUBAH.
  TextColumn get productName => text()();
  IntColumn get productPrice => integer()();

  // Jumlah beli
  IntColumn get quantity => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// =========================================================
// SECTION 2: TABEL KATEGORI (CATEGORIES)
// Nanti kita isi bagian ini di update selanjutnya
// =========================================================
// class Categories extends Table {
//    ...
// }
