import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database.dart'; // Import database
import '../utils/pdf_generator.dart'; // Import PDF Generator

class TransactionDetailPage extends StatefulWidget {
  // Kita butuh data Header Transaksinya dilempar dari halaman sebelah
  final Transaction transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // ===========================================
              // BAGIAN HEADER (Kertas Struk Atas)
              // ===========================================
              const Icon(Icons.store, size: 50, color: Colors.grey),
              const SizedBox(height: 10),
              const Text(
                "POS KASIRKU",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text("Jalan Raya Developer No. 1"),
              const SizedBox(height: 20),

              const Divider(thickness: 2), // Garis
              // Info Tanggal & Kasir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tanggal:"),
                  Text(dateFormat.format(widget.transaction.transactionDate)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Kasir:"),
                  Text(widget.transaction.cashierName),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("No. ID:"),
                  Text(
                    "#${widget.transaction.id.substring(0, 8)}...",
                  ), // Potong ID biar gak kepanjangan
                ],
              ),

              const Divider(thickness: 2),

              // ===========================================
              // BAGIAN LIST BARANG (Isi Struk)
              // Kita ambil datanya pakai FutureBuilder
              // ===========================================
              FutureBuilder<List<TransactionItem>>(
                future: database.getTransactionItems(widget.transaction.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("Tidak ada item (Data Error?)");
                  }

                  final items = snapshot.data!;

                  return Column(
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            // Jumlah (2x)
                            Text(
                              "${item.quantity}x ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Nama Barang
                            Expanded(child: Text(item.productName)),

                            // Total Harga per Item (Harga Snapshot x Qty)
                            Text(
                              currency.format(
                                item.productPrice * item.quantity,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const Divider(thickness: 2),

              // ===========================================
              // BAGIAN FOOTER (Total & Bayar)
              // ===========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TOTAL",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    currency.format(widget.transaction.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tunai"),
                  Text(currency.format(widget.transaction.cashReceived)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Kembalian"),
                  Text(currency.format(widget.transaction.cashReturned)),
                ],
              ),

              const SizedBox(height: 40),
              const Text(
                "Terima Kasih!",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),

              const SizedBox(height: 20),
              // Tombol Cetak (Hiasan dulu)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // ambil item untuk dicetak
                    final items = await database.getTransactionItems(
                      widget.transaction.id,
                    );
                    // Panggil fungsi cetak PDF
                    await PdfGenerator.printStruk(widget.transaction, items);
                  },
                  icon: const Icon(Icons.print),
                  label: const Text("CETAK STRUK"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
