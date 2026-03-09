import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../utils/currency_formatter.dart';

class ManageProductsPage extends StatefulWidget {
  const ManageProductsPage({super.key});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  // FUNGSI SIMPAN BARU (CREATE)
  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Harga harus diisi!')),
      );
      return;
    }

    final database = Provider.of<AppDatabase>(context, listen: false);

    // 1. CEK DUPLIKAT NAMA
    // Kita query dulu apakah nama ini sudah ada di database?
    final existingProduct = await (database.select(
      database.products,
    )..where((tbl) => tbl.name.equals(_nameController.text))).getSingleOrNull();

    if (existingProduct != null) {
      // Jika ketemu, tolak!
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Gagal Simpan"),
            content: Text(
              "Produk dengan nama '${_nameController.text}' sudah ada.\nSilakan gunakan nama lain atau edit produk yang ada.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Oke"),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 2. PROSES SIMPAN JIKA AMAN
    int priceInt = CurrencyInputFormatter.toInt(_priceController.text);
    int stockInt = _stockController.text.isEmpty
        ? 0
        : int.parse(_stockController.text);

    try {
      await database
          .into(database.products)
          .insert(
            ProductsCompanion.insert(
              name: _nameController.text,
              price: priceInt,
              stock: drift.Value(stockInt),
            ),
          );

      _nameController.clear();
      _priceController.clear();
      _stockController.clear();

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu berhasil disimpan!')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // FUNGSI UPDATE / EDIT PRODUK (BARU!)
  // Solusi untuk salah input stok/harga tanpa harus hapus
  void _showEditDialog(Product item) {
    final nameEd = TextEditingController(text: item.name);
    final priceEd = TextEditingController(text: item.price.toString());
    final stockEd = TextEditingController(text: item.stock.toString());

    // Format tampilan harga awal biar ada titiknya
    final formatter = NumberFormat('#,###', 'id');
    priceEd.text = formatter.format(item.price);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit: ${item.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameEd,
              decoration: const InputDecoration(
                labelText: "Nama Produk",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceEd,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: "Harga",
                prefixText: "Rp ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: stockEd,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Stok",
                suffixText: "Pcs",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final database = Provider.of<AppDatabase>(context, listen: false);
              int newPrice = CurrencyInputFormatter.toInt(priceEd.text);
              int newStock = int.tryParse(stockEd.text) ?? 0;

              // Update ke Database
              await (database.update(
                database.products,
              )..where((t) => t.id.equals(item.id))).write(
                ProductsCompanion(
                  name: drift.Value(nameEd.text),
                  price: drift.Value(newPrice),
                  stock: drift.Value(newStock),
                  updatedAt: drift.Value(DateTime.now()), // Update jam edit
                ),
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Data berhasil diperbarui!")),
                );
              }
            },
            child: const Text("Simpan Perubahan"),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(Product item) {
    final database = Provider.of<AppDatabase>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Menu?'),
        content: Text('Yakin mau menghapus ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              database.deleteProduct(item);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
      appBar: AppBar(
        title: const Text('Kelola Produk (Admin)'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KIRI: FORM INPUT (40%)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tambah Menu Baru",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Barang',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fastfood),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Harga Jual',
                            border: OutlineInputBorder(),
                            prefixText: 'Rp ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Stok',
                            border: OutlineInputBorder(),
                            suffixText: 'Pcs',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveProduct,
                      icon: const Icon(Icons.save),
                      label: const Text('SIMPAN MENU'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // KANAN: LIST PRODUK (60%)
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Daftar Menu Tersimpan",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<List<Product>>(
                      stream: database.getAllProducts(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        final products = snapshot.data!;
                        if (products.isEmpty)
                          return const Center(child: Text("Belum ada data"));

                        return ListView.separated(
                          itemCount: products.length,
                          separatorBuilder: (c, i) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = products[index];
                            final int stock = item.stock ?? 0;

                            return ListTile(
                              tileColor: Colors.white,
                              leading: CircleAvatar(
                                backgroundColor: stock > 0
                                    ? Colors.blue[100]
                                    : Colors.red[100],
                                child: Text(item.name[0].toUpperCase()),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(currency.format(item.price)),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: stock > 0
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Stok: $stock",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // TOMBOL AKSI: EDIT & HAPUS
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Tombol Edit
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    tooltip: "Edit Produk",
                                    onPressed: () => _showEditDialog(item),
                                  ),
                                  // Tombol Hapus
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: "Hapus Produk",
                                    onPressed: () => _deleteProduct(item),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
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
