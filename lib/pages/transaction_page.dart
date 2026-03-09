import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import 'transaction_detail_page.dart';
import 'cashier_page.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm'); // Format Tanggal

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        // Tambah tombol kembali ke halaman kasir (tempat nambah shortcut)
        actions: [
          IconButton(
            icon: const Icon(Icons.point_of_sale, size: 30),
            tooltip: 'Kembali ke Kasir',
            onPressed: () {
              // Kita pakai pushReplacement agar halaman riwayat ditutup
              // dan langsung ganti ke halaman kasir (biar memori gak numpuk)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CashierPage()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<List<Transaction>>(
        // Ambil List<Transaction>
        // Kita butuh buat query ini di database.dart nanti
        stream: database.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(child: Text("Belum ada transaksi hari ini."));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.check, color: Colors.green),
                  ),
                  title: Text(
                    currency.format(item.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateFormat.format(item.transactionDate)),
                      Text(
                        "Kasir: ${item.cashierName} | ${item.paymentMethod}",
                      ),
                    ],
                  ),
                  // Nanti kita bisa tambah fitur klik buat lihat detail barangnya
                  onTap: () {
                    // TODO: Lihat Detail
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TransactionDetailPage(transaction: item),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
