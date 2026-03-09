import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

import '../database/database.dart';
import '../providers/cart_provider.dart';
import '../utils/pdf_generator.dart'; // Import PDF Generator

class PaymentDialog extends StatefulWidget {
  final int totalBill;

  const PaymentDialog({super.key, required this.totalBill});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  // PENGGANTI CONTROLLER: Kita pakai String biasa
  String _inputAmount = "";

  int _change = 0;
  bool _isValid = false;
  Transaction? _successTransaction;
  bool _hasPrinted = false;

  final currency = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // LOGIC: Saat tombol angka ditekan
  void _onKeyTap(String value) {
    setState(() {
      // Batasi panjang angka biar gak miliaran triliun (max 12 digit)
      if (_inputAmount.length < 12) {
        _inputAmount += value;
        _calculateChange();
      }
    });
  }

  // LOGIC: Hapus satu karakter (Backspace)
  void _onBackspace() {
    setState(() {
      if (_inputAmount.isNotEmpty) {
        _inputAmount = _inputAmount.substring(0, _inputAmount.length - 1);
        _calculateChange();
      }
    });
  }

  // LOGIC: Hapus Semua (Clear)
  void _onClear() {
    setState(() {
      _inputAmount = "";
      _calculateChange();
    });
  }

  // LOGIC: Hitung Kembalian
  void _calculateChange() {
    // Kalau kosong anggap 0
    int cash = _inputAmount.isEmpty ? 0 : int.parse(_inputAmount);
    _change = cash - widget.totalBill;
    _isValid = cash >= widget.totalBill;
  }

  // LOGIC: Proses Bayar (Sama seperti sebelumnya)
  void _processPayment() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    final int cashInt = _inputAmount.isEmpty ? 0 : int.parse(_inputAmount);
    final String transactionId = DateTime.now().millisecondsSinceEpoch
        .toString();

    final headerData = TransactionsCompanion(
      id: drift.Value(transactionId),
      totalAmount: drift.Value(widget.totalBill),
      cashReceived: drift.Value(cashInt),
      cashReturned: drift.Value(_change),
      paymentMethod: const drift.Value("CASH"),
      cashierName: const drift.Value("Admin"),
      transactionDate: drift.Value(DateTime.now()),
    );

    final List<TransactionItemsCompanion> itemsData = cart.items.map((item) {
      return TransactionItemsCompanion(
        transactionId: drift.Value(transactionId),
        productId: drift.Value(item.product.id),
        productName: drift.Value(item.product.name),
        productPrice: drift.Value(item.product.price),
        quantity: drift.Value(item.quantity),
      );
    }).toList();

    try {
      await database.saveTransaction(headerData, itemsData);

      final newTransaction = Transaction(
        id: transactionId,
        totalAmount: widget.totalBill,
        cashReceived: cashInt,
        cashReturned: _change,
        paymentMethod: "CASH",
        cashierName: "Admin",
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cashierId: null,
      );

      cart.clearCart();

      if (mounted) {
        setState(() {
          _successTransaction = newTransaction;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TENTUKAN UKURAN DIALOG:
    // Kita paksa lebar dialog agak besar biar Numpad muat enak
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 700, // Lebar Dialog (Pas buat Tablet)
        height: 500, // Tinggi Dialog
        padding: const EdgeInsets.all(20),
        child: _successTransaction != null
            ? _buildReceiptView(_successTransaction!) // Tampilan Struk
            : _buildNumpadLayout(), // Tampilan Numpad
      ),
    );
  }

  // TAMPILAN 1: NUMPAD LAYOUT (Split Kiri-Kanan)
  Widget _buildNumpadLayout() {
    // Format tampilan angka input biar ada titiknya (Visual Only)
    String displayInput = "";
    if (_inputAmount.isNotEmpty) {
      displayInput = currency
          .format(int.parse(_inputAmount))
          .replaceAll("Rp ", "");
    }

    return Column(
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Pembayaran",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const Divider(),

        Expanded(
          child: Row(
            children: [
              // ==============================
              // BAGIAN KIRI: DISPLAY INFO (45%)
              // ==============================
              Expanded(
                flex: 45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Total Tagihan:",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      currency.format(widget.totalBill),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Uang Diterima:",
                      style: TextStyle(color: Colors.grey),
                    ),
                    // KOTAK TAMPILAN ANGKA MANUAL
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blue[50],
                      ),
                      child: Text(
                        displayInput.isEmpty ? "0" : displayInput,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Kembalian:",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      currency.format(_change),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isValid ? Colors.green : Colors.red,
                      ),
                    ),

                    const Spacer(),

                    // TOMBOL PROSES
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isValid ? _processPayment : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          "PROSES BAYAR",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(width: 30),

              // ==============================
              // BAGIAN KANAN: TOMBOL ANGKA (55%)
              // ==============================
              Expanded(
                flex: 55,
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3, // 3 Kolom
                        childAspectRatio: 1.5, // Lebar : Tinggi tombol
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          _buildNumKey("1"),
                          _buildNumKey("2"),
                          _buildNumKey("3"),
                          _buildNumKey("4"),
                          _buildNumKey("5"),
                          _buildNumKey("6"),
                          _buildNumKey("7"),
                          _buildNumKey("8"),
                          _buildNumKey("9"),
                          _buildActionKey("C", Colors.orange, _onClear),
                          _buildNumKey("0"),
                          _buildActionKey("⌫", Colors.red, _onBackspace),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tombol 000 (Opsional, sangat berguna buat Rupiah)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => _onKeyTap("000"),
                        child: const Text(
                          "000",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget Tombol Angka Biasa
  Widget _buildNumKey(String value) {
    return InkWell(
      onTap: () => _onKeyTap(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Widget Tombol Aksi (Clear / Backspace)
  Widget _buildActionKey(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  // TAMPILAN 2: STRUK / RECEIPT (Sama seperti sebelumnya, dirapikan layoutnya)
  Widget _buildReceiptView(Transaction trx) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final database = Provider.of<AppDatabase>(context, listen: false);

    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 60),
        const SizedBox(height: 10),
        const Text(
          "Pembayaran Berhasil!",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const Divider(),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "Total: ${currency.format(trx.totalAmount)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<TransactionItem>>(
                  future: database.getTransactionItems(trx.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const LinearProgressIndicator();
                    return Column(
                      children: snapshot.data!.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item.quantity}x ${item.productName}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                currency.format(
                                  item.productPrice * item.quantity,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: _hasPrinted
                  ? null
                  : () async {
                      setState(() => _hasPrinted = true);
                      final items = await database.getTransactionItems(trx.id);
                      await PdfGenerator.printStruk(trx, items);
                    },
              icon: Icon(Icons.print, color: _hasPrinted ? Colors.grey : null),
              label: Text(_hasPrinted ? "Dicetak" : "Cetak Struk"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Transaksi Baru"),
            ),
          ],
        ),
      ],
    );
  }
}
