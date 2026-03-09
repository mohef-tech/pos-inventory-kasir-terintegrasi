import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../providers/cart_provider.dart';
import 'payment_dialog.dart';
import 'transaction_page.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  void _showEditQuantityDialog(BuildContext context, CartItem item) {
    final TextEditingController qtyController = TextEditingController(
      text: item.quantity.toString(),
    );
    final cart = Provider.of<CartProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit: ${item.product.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan jumlah baru:"),
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              cart.removeFullItem(item.product);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              "Hapus Item",
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              // Validasi Sederhana:
              // Idealnya kita cek stok lagi disini, tapi untuk V1.2 ini cukup update cart dulu.
              int newQty = int.tryParse(qtyController.text) ?? 1;
              if (newQty > 0) {
                cart.removeFullItem(item.product);
                for (int i = 0; i < newQty; i++) {
                  cart.addToCart(item.product);
                }
              }
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
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
        title: const Text('Kasir Toko'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 30),
            tooltip: 'Riwayat Transaksi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isTablet = constraints.maxWidth > 600;

          int flexLeft = isTablet ? 6 : 5;
          int flexRight = isTablet ? 4 : 4;
          int crossAxisCount = isTablet ? 4 : 2;

          return Row(
            children: [
              // AREA KIRI: KATALOG PRODUK
              Expanded(
                flex: flexLeft,
                child: Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8),
                  child: StreamBuilder<List<Product>>(
                    stream: database.getAllProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products = snapshot.data!;

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio:
                              0.80, // Agak dipanjangkan ke bawah biar muat info stok
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final item = products[index];
                          // LOGIC STOK
                          final int stock = item.stock ?? 0;
                          final bool isHabis = stock <= 0;

                          return InkWell(
                            // KALAU HABIS, GABISA DIKLIK (null)
                            onTap: isHabis
                                ? null
                                : () {
                                    // panggil Provider untuk tambah ke keranjang
                                    bool success = Provider.of<CartProvider>(
                                      context,
                                      listen: false,
                                    ).addToCart(item);
                                    if (!success) {
                                      // Tampilkan snackbar kalau gagal (stok habis)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Stok sudah habis!"),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(
                                            milliseconds: 800,
                                          ),
                                        ),
                                      );
                                    }
                                  },

                            child: Opacity(
                              // Kalau habis, bikin agak transparan (pudar)
                              opacity: isHabis ? 0.5 : 1.0,
                              child: Card(
                                elevation: 1,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Icon
                                      Icon(
                                        Icons.fastfood,
                                        size: 35,
                                        color: isHabis
                                            ? Colors.grey
                                            : Colors.orange,
                                      ),
                                      const SizedBox(height: 5),

                                      // Nama Produk
                                      Text(
                                        item.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 4),

                                      // Harga
                                      Text(
                                        currency.format(item.price),
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // BADGE STOK (Visualisasi)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isHabis
                                              ? Colors.red
                                              : Colors.green[100],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          isHabis ? "HABIS" : "Stok: $stock",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isHabis
                                                ? Colors.white
                                                : Colors.green[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // AREA KANAN: KERANJANG
              Expanded(
                flex: flexRight,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.blue[50],
                        width: double.infinity,
                        child: const Text(
                          "Keranjang Belanja",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Consumer<CartProvider>(
                          builder: (context, cart, child) {
                            if (cart.items.isEmpty)
                              return const Center(
                                child: Text("Keranjang Kosong"),
                              );

                            return ListView.separated(
                              padding: const EdgeInsets.all(10),
                              itemCount: cart.items.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final cartItem = cart.items[index];
                                return ListTile(
                                  onTap: () => _showEditQuantityDialog(
                                    context,
                                    cartItem,
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    cartItem.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${currency.format(cartItem.product.price)} x ${cartItem.quantity}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildQtyButton(
                                        icon: Icons.remove,
                                        color: Colors.red.shade100,
                                        iconColor: Colors.red,
                                        onTap: () => cart.removeOneItem(
                                          cartItem.product,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 30,
                                        child: Text(
                                          "${cartItem.quantity}",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      _buildQtyButton(
                                        icon: Icons.add,
                                        color: Colors.green.shade100,
                                        iconColor: Colors.green,
                                        onTap: () {
                                          bool success = cart.addToCart(
                                            cartItem.product,
                                          );
                                          if (!success) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).hideCurrentSnackBar();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "mencapai batas stock!",
                                                ),
                                                backgroundColor: Colors.orange,
                                                duration: Duration(
                                                  milliseconds: 800,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: const Offset(0, -3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "TOTAL:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      currency.format(cart.getTotalPrice()),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: cart.items.isEmpty
                                        ? null
                                        : () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return PaymentDialog(
                                                  totalBill: cart
                                                      .getTotalPrice(),
                                                );
                                              },
                                            );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                    ),
                                    child: const Text(
                                      "BAYAR SEKARANG",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}
