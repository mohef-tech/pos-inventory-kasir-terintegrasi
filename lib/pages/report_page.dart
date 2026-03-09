import 'dart:typed_data'; // Tambahan untuk Bytes
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart'; // <--- GANTI INI (Library Baru)
import '../database/database.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late DateTimeRange selectedRange;
  List<double> chartValues = [];
  List<String> chartLabels = [];
  List<Map<String, dynamic>> topProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedRange = DateTimeRange(
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );
    _prepareData();
  }

  Future<void> _prepareData() async {
    setState(() => isLoading = true);
    final database = Provider.of<AppDatabase>(context, listen: false);

    final start = DateTime(
      selectedRange.start.year,
      selectedRange.start.month,
      selectedRange.start.day,
    );
    final end = DateTime(
      selectedRange.end.year,
      selectedRange.end.month,
      selectedRange.end.day,
      23,
      59,
      59,
    );

    final transactions =
        await (database.select(database.transactions)
              ..where((t) => t.transactionDate.isBetweenValues(start, end))
              ..orderBy([(t) => OrderingTerm(expression: t.transactionDate)]))
            .get();

    Map<String, double> dailyRevenue = {};
    int daysCount = end.difference(start).inDays + 1;

    for (int i = 0; i < daysCount; i++) {
      final date = start.add(Duration(days: i));
      String key = DateFormat('yyyy-MM-dd').format(date);
      dailyRevenue[key] = 0.0;
    }

    for (var trx in transactions) {
      String key = DateFormat('yyyy-MM-dd').format(trx.transactionDate);
      dailyRevenue[key] = (dailyRevenue[key] ?? 0) + trx.totalAmount.toDouble();
    }

    List<double> tempValues = [];
    List<String> tempLabels = [];

    dailyRevenue.forEach((key, value) {
      tempValues.add(value);
      DateTime date = DateTime.parse(key);
      tempLabels.add(DateFormat('dd/MM').format(date));
    });

    // Top Produk Logic (Sama seperti sebelumnya)
    List<String> trxIds = transactions.map((t) => t.id).toList();
    final items = await (database.select(
      database.transactionItems,
    )..where((t) => t.transactionId.isIn(trxIds))).get();

    Map<String, int> productCount = {};
    Map<String, String> productNames = {};

    for (var item in items) {
      productCount[item.productId] =
          (productCount[item.productId] ?? 0) + item.quantity;
      productNames[item.productId] = item.productName;
    }

    var sortedKeys = productCount.keys.toList()
      ..sort((k1, k2) => productCount[k2]!.compareTo(productCount[k1]!));

    List<Map<String, dynamic>> tempTop = [];
    for (int i = 0; i < sortedKeys.length && i < 5; i++) {
      String pid = sortedKeys[i];
      tempTop.add({'name': productNames[pid], 'qty': productCount[pid]});
    }

    if (mounted) {
      setState(() {
        chartValues = tempValues;
        chartLabels = tempLabels;
        topProducts = tempTop;
        isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue[800],
            colorScheme: ColorScheme.light(primary: Colors.blue[800]!),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });
      _prepareData();
    }
  }

  // 3. FUNGSI EXPORT EXCEL (VERSI BARU: FILE SAVER)
  Future<void> _exportExcel() async {
    final database = Provider.of<AppDatabase>(context, listen: false);

    // Siapkan Data
    final start = DateTime(
      selectedRange.start.year,
      selectedRange.start.month,
      selectedRange.start.day,
    );
    final end = DateTime(
      selectedRange.end.year,
      selectedRange.end.month,
      selectedRange.end.day,
      23,
      59,
      59,
    );

    final transactions =
        await (database.select(database.transactions)
              ..where((t) => t.transactionDate.isBetweenValues(start, end))
              ..orderBy([(t) => OrderingTerm(expression: t.transactionDate)]))
            .get();

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diexport")),
      );
      return;
    }

    // Buat Excel
    var excel = Excel.createExcel();
    Sheet sheet = excel['Laporan Transaksi'];

    // Header
    sheet.appendRow([
      TextCellValue('ID Transaksi'),
      TextCellValue('Tanggal'),
      TextCellValue('Jam'),
      TextCellValue('Total'),
      TextCellValue('Tunai'),
      TextCellValue('Kembali'),
      TextCellValue('Kasir'),
    ]);

    // Isi Data
    for (var trx in transactions) {
      sheet.appendRow([
        TextCellValue(trx.id),
        TextCellValue(DateFormat('dd/MM/yyyy').format(trx.transactionDate)),
        TextCellValue(DateFormat('HH:mm').format(trx.transactionDate)),
        IntCellValue(trx.totalAmount),
        IntCellValue(trx.cashReceived),
        IntCellValue(trx.cashReturned),
        TextCellValue(trx.cashierName ?? "-"),
      ]);
    }

    // Konversi Excel ke Bytes
    var fileBytes = excel.save();

    if (fileBytes != null) {
      // PERBAIKAN: Tambahkan .xlsx langsung di nama file
      String fileName =
          "Laporan_POS_${DateFormat('ddMMyy').format(start)}_${DateFormat('ddMMyy').format(end)}.xlsx";

      try {
        // GUNAKAN SALAH SATU dari 2 cara ini:

        // CARA 1: Untuk file_saver versi baru (^0.2.0 keatas)
        String? path = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          mimeType: MimeType.microsoftExcel,
        );

        // CARA 2: Alternatif jika cara 1 tidak work (untuk versi tertentu)
        // String? path = await FileSaver.instance.saveAs(
        //   name: fileName,
        //   bytes: Uint8List.fromList(fileBytes),
        //   ext: 'xlsx',
        //   mimeType: MimeType.microsoftExcel,
        // );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Berhasil disimpan: $fileName"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menyimpan: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        "${DateFormat('dd MMM').format(selectedRange.start)} - ${DateFormat('dd MMM yyyy').format(selectedRange.end)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          // TOMBOL EXPORT EXCEL (REVISI UI)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: isLoading ? null : _exportExcel,
              icon: const Icon(Icons.file_download, color: Colors.green),
              label: const Text(
                "Export Laporan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(
                  0.1,
                ), // Background tipis biar manis
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: Column(
        children: [
          // FILTER BAR
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Periode Laporan:",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text("Ganti Tanggal"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // KONTEN UTAMA
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // GRAFIK
                        const Text(
                          "Grafik Omset",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 250,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: chartValues.isEmpty
                              ? const Center(
                                  child: Text("Tidak ada data di periode ini"),
                                )
                              : BarChart(
                                  BarChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            int idx = value.toInt();
                                            if (idx >= 0 &&
                                                idx < chartLabels.length) {
                                              if (chartLabels.length > 10 &&
                                                  idx % 2 != 0)
                                                return const SizedBox.shrink();
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  chartLabels[idx],
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: List.generate(
                                      chartValues.length,
                                      (index) {
                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: chartValues[index],
                                              color: Colors.blue[800],
                                              width: chartLabels.length > 10
                                                  ? 10
                                                  : 20,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 30),
                        const Text(
                          "Top 5 Produk (Periode Ini)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // LIST TOP PRODUK
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topProducts.length,
                          itemBuilder: (context, index) {
                            final item = topProducts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange[100],
                                  foregroundColor: Colors.orange[800],
                                  child: Text("#${index + 1}"),
                                ),
                                title: Text(
                                  item['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Text(
                                  "${item['qty']} Terjual",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (topProducts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                "Belum ada data penjualan",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
