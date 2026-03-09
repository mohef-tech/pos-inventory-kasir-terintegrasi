import 'dart:io'; // Untuk akses file system (Android/Windows)

import 'package:drift/drift.dart';
import 'package:drift/native.dart'; // Driver database native
import 'package:path_provider/path_provider.dart'; // Untuk cari folder di HP
import 'package:path/path.dart'
    as p; // Untuk menggabungkan path folder + nama file

import 'package:uuid/uuid.dart';

// Import file tabel yang tadi kita buat
import 'tables.dart';

// ---------------------------------------------------------
// CODE GENERATION PART
// Bagian ini akan merah (error) sebentar.
// Ini wajar karena file 'database.g.dart' belum kita generate.
// ---------------------------------------------------------
part 'database.g.dart';

// =========================================================
// KELAS DATABASE UTAMA (AppDatabase)
// Disini kita daftarkan semua tabel yang mau dipakai.
// =========================================================
@DriftDatabase(
  tables: [
    Products, // Daftarkan tabel Products disini
    Users,
    Transactions,
    TransactionItems,
    // Categories, // Nanti kalau ada tabel baru, tambah disini (pakai koma)
  ],
)
class AppDatabase extends _$AppDatabase {
  // Constructor: Membuka koneksi saat class ini dipanggil
  AppDatabase() : super(_openConnection());

  // Versi Schema Database.
  // PENTING: Kalau nanti nambah kolom baru, angka ini harus dinaikkan (misal jadi 2).
  @override
  int get schemaVersion => 3;

  // Fungsi: Ambil semua produk secara Live (Stream)
  // Return: Stream<List<Product>> -> Aliran data berisi daftar produk
  Stream<List<Product>> getAllProducts() {
    // select(products) = "SELECT * FROM products"
    // .watch() = Pantau terus, kalau ada perubahan, kabari UI.
    return select(products).watch();
  }

  // --- TAMBAHAN BARU: FUNGSI HAPUS ---
  Future<int> deleteProduct(Product item) {
    // delete(products) = "DELETE FROM products"
    // .delete(item) = "... WHERE id = item.id"
    return delete(products).delete(item);
  }

  // LOGIC SIMPAN TRANSAKSI UPDATE V1.2
  // =========================================================
  Future<void> saveTransaction(
    TransactionsCompanion header,
    List<TransactionItemsCompanion> items,
  ) async {
    await transaction(() async {
      // 1. Simpan Header Transaksi
      await into(transactions).insert(header);

      // 2. Simpan Item & Kurangi Stok
      for (var item in items) {
        // A. Simpan Item ke Tabel TransactionItems
        await into(transactionItems).insert(item);

        // B. KURANGI STOK (Logic Baru!)
        // Query: "UPDATE products SET stock = stock - [qty] WHERE id = [produk_id]"
        await customUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          variables: [
            Variable<int>(item.quantity.value),
            Variable<String>(item.productId.value),
          ],
          updates: {
            products,
          }, // Memberitahu aplikasi bahwa data produk berubah (biar UI refresh otomatis)
        );
      }
    });
  }

  // 1. FUNGSI HITUNG TOTAL DUIT HARI INI
  Stream<int> getTodayTotalRevenue() {
    // Cari jam 00:00 hari ini
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Ambil semua transaksi mulai dari jam 00:00
    return (select(transactions)
          ..where((t) => t.transactionDate.isBiggerOrEqualValue(startOfDay)))
        .watch()
        .map((List<Transaction> models) {
          // Jumlahkan kolom totalAmount
          return models.fold(0, (sum, item) => sum + item.totalAmount);
        });
  }

  // 2. FUNGSI HITUNG TOTAL BON (STRUK) HARI INI
  Stream<int> getTodayTransactionCount() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return (select(transactions)
          ..where((t) => t.transactionDate.isBiggerOrEqualValue(startOfDay)))
        .watch()
        .map((models) => models.length); // Cuma hitung jumlah baris datanya
  }

  // AMBIL SEMUA RIWAYAT TRANSAKSI (Urutkan dari yang terbaru)
  Stream<List<Transaction>> getTransactions() {
    return (select(transactions)..orderBy([
          (t) => OrderingTerm(
            expression: t.transactionDate,
            mode: OrderingMode.desc,
          ),
        ]))
        .watch();
  }

  // AMBIL ITEM BELANJA BERDASARKAN ID TRANSAKSI
  // "SELECT * FROM transaction_items WHERE transaction_id = 'abc-123'"
  Future<List<TransactionItem>> getTransactionItems(String id) {
    return (select(
      transactionItems,
    )..where((t) => t.transactionId.equals(id))).get();
  }
}

// =========================================================
// FUNGSI KONEKSI (OPEN CONNECTION)
// Logika untuk mencari lokasi aman menyimpan file database
// =========================================================
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // 1. Cari folder aplikasi di HP/PC (Documents folder)
    final dbFolder = await getApplicationDocumentsDirectory();

    // 2. Tentukan nama file database-nya
    final file = File(p.join(dbFolder.path, 'pos_kasirku.sqlite'));

    // 3. Buat database di background agar aplikasi tidak macet
    return NativeDatabase.createInBackground(file);
  });
}
