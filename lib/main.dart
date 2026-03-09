import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'database/database.dart'; // Import database kita
import 'pages/manage_products_page.dart'; // Import halaman home (nanti kita buat)
import 'providers/cart_provider.dart'; // Import CartProvider
import 'pages/dashboard_page.dart'; // Import halaman dashboard
import 'package:intl/date_symbol_data_local.dart'; // Import untuk inisialisasi lokalisasi tanggal

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi lokalisasi tanggal (untuk menampilkan nama hari/bulan dalam bahasa Indonesia)
  await initializeDateFormatting('id', null);

  runApp(
    // ganti Provider biasa jadi MultiProvider karena sekarang ada 2 Provider:
    // 1. Database
    // 2. Cart (Keranjang)
    MultiProvider(
      providers: [
        // Provider 1: Database
        Provider<AppDatabase>(
          create: (context) => AppDatabase(),
          dispose: (context, db) => db.close(),
        ),
        // Provider 2: Keranjang Belanja (Cart)
        ChangeNotifierProvider(create: (context) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS Kasirku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Arahkan home ke Dashboard (file yang akan kita buat di Langkah 3)
      home: const DashboardPage(),
    );
  }
}
