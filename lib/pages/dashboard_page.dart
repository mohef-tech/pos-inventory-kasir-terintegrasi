import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import 'cashier_page.dart';
import 'transaction_page.dart';
import 'manage_products_page.dart';
import 'settings_page.dart';
import 'report_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // FUNGSI UTAMA: Memanggil Dialog PIN
  void _showPinDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User gabisa tutup dengan klik luar
      builder: (context) {
        return const PinVerificationDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('POS Kasirku - Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,

        // TOMBOL SETTINGS
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Pengaturan Toko",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GREETING
            const Text(
              "Ringkasan Bisnis",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // SCOREBOARD
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: database.getTodayTotalRevenue(),
                    builder: (context, snapshot) {
                      final total = snapshot.data ?? 0;
                      return _buildSummaryCard(
                        title: "Omset Hari Ini",
                        value: currency.format(total),
                        icon: Icons.monetization_on,
                        color: Colors.green,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: database.getTodayTransactionCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _buildSummaryCard(
                        title: "Total Transaksi",
                        value: "$count Bon",
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),
            const Text(
              "Menu Utama",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // GRID MENU
            LayoutBuilder(
              builder: (context, constraints) {
                int crossCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.4,
                  children: [
                    _buildMenuButton(
                      context,
                      "KASIR TOKO",
                      Icons.point_of_sale,
                      Colors.blue[700]!,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const CashierPage()),
                      ),
                    ),
                    _buildMenuButton(
                      context,
                      "RIWAYAT",
                      Icons.history,
                      Colors.orange[700]!,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const TransactionPage(),
                        ),
                      ),
                    ),

                    // TOMBOL INI MEMANGGIL PIN DIALOG
                    _buildMenuButton(
                      context,
                      "KELOLA PRODUK",
                      Icons.inventory_2,
                      Colors.purple[700]!,
                      () => _showPinDialog(context),
                    ),

                    _buildMenuButton(
                      context,
                      "LAPORAN",
                      Icons.bar_chart,
                      Colors.teal[700]!,
                      () {
                        // Kita proteksi pakai PIN juga biar aman? Atau bebas?
                        // Idealnya Laporan itu rahasia dapur, jadi kita pakai PIN.
                        // Tapi karena tombol PIN di Dashboard logicnya nempel ke 'Kelola Produk',
                        // Untuk sekarang kita biarkan BEBAS AKSES dulu atau bikin logic PIN terpisah nanti.
                        // Kita buat LANGSUNG MASUK dulu biar gampang dites.
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (c) => const ReportPage()),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 50),
            Center(
              child: Text(
                "POS Kasirku V1.3 by Mohef Dev",
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 35),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: color),
              const SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// KELAS BARU: PIN DIALOG (SIDE-BY-SIDE LAYOUT)
// Letaknya di paling bawah file ini
// ============================================================================
class PinVerificationDialog extends StatefulWidget {
  const PinVerificationDialog({super.key});

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  String currentPin = "";

  // Logic Numpad (HANYA MENCATAT ANGKA)
  void _onKeyTap(String value) {
    if (currentPin.length < 6) {
      setState(() {
        currentPin += value;
      });
      // SAYA HAPUS LOGIC AUTO SUBMIT DISINI
      // Jadi dia akan diam saja menunggu tombol MASUK ditekan
    }
  }

  void _onBackspace() {
    if (currentPin.isNotEmpty) {
      setState(() {
        currentPin = currentPin.substring(0, currentPin.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      currentPin = "";
    });
  }

  void _validatePin() async {
    // HARDCODE PIN sementara
    if (currentPin == "160601") {
      Navigator.pop(context); // Tutup Dialog
      Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => const ManageProductsPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PIN Salah!"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        currentPin = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 650,
        height: 380,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // BAGIAN KIRI: INFO & PIN
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Akses Terbatas",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Menu ini khusus Owner/Admin.\nMasukkan PIN untuk lanjut.",
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // TAMPILAN PIN
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentPin.isEmpty ? "PIN" : "•" * currentPin.length,
                      style: TextStyle(
                        fontSize: 30,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                        color: currentPin.isEmpty
                            ? Colors.grey.shade400
                            : Colors.black,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // TOMBOL AKSI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Batal",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // TOMBOL MASUK (Hanya aktif jika PIN sudah 6 digit)
                      ElevatedButton(
                        onPressed: currentPin.length == 6
                            ? _validatePin
                            : null, // <-- LOGIC BARU
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          "MASUK",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const VerticalDivider(width: 40, thickness: 1),

            // BAGIAN KANAN: NUMPAD
            Expanded(
              flex: 5,
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                physics: const NeverScrollableScrollPhysics(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildNumKey(String value) {
    return InkWell(
      onTap: () => _onKeyTap(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        alignment: Alignment.center,
        child: label == "⌫"
            ? Icon(Icons.backspace_outlined, color: color)
            : Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
      ),
    );
  }
}
