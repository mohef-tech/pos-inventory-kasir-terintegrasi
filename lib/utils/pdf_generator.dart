import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- Tambah Import ini
import '../database/database.dart';

class PdfGenerator {
  static Future<void> printStruk(
    Transaction trx,
    List<TransactionItem> items,
  ) async {
    final doc = pw.Document();

    // 1. AMBIL SETTINGAN TOKO DARI MEMORI
    final prefs = await SharedPreferences.getInstance();
    final String storeName = prefs.getString('store_name') ?? 'POS KASIRKU';
    final String storeAddress =
        prefs.getString('store_address') ?? 'Jl. Raya Developer No. 1';
    final String storePhone =
        prefs.getString('store_phone') ?? '0812-3456-7890';

    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER DINAMIS (Sesuai Settingan)
              pw.Center(
                child: pw.Text(
                  storeName,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  storeAddress,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "Telp: $storePhone",
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),

              pw.Divider(),

              // ... (Sisanya SAMA SEPERTI KODE LAMA) ...
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Tgl: ${dateFormat.format(trx.transactionDate)}",
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    "ID: #${trx.id.substring(0, 6)}",
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),

              pw.ListView(
                children: items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            "${item.quantity}x ${item.productName}",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Text(
                          currency.format(item.productPrice * item.quantity),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              pw.Divider(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "TOTAL",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    currency.format(trx.totalAmount),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Tunai", style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    currency.format(trx.cashReceived),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Kembali", style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    currency.format(trx.cashReturned),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  "Terima Kasih!",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Struk-${trx.id}',
    );
  }
}
