import 'package:flutter/material.dart';
import '../database/database.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // FUNGSI TAMBAH ITEM (DENGAN PROTEKSI STOK)
  // Return true jika berhasil, false jika stok habis (biar UI tau)
  bool addToCart(Product product) {
    // 1. Cek apakah barang ini sudah ada di keranjang?
    int index = _items.indexWhere((item) => item.product.id == product.id);

    // Ambil stok saat ini dari database (snapshot)
    int currentStock = product.stock ?? 0;

    if (index != -1) {
      // ITEM SUDAH ADA: Cek dulu sebelum nambah
      if (_items[index].quantity < currentStock) {
        _items[index].quantity++;
        notifyListeners();
        return true; // Berhasil nambah
      } else {
        // Gagal nambah karena mentok stok
        return false;
      }
    } else {
      // ITEM BARU: Cek apakah stok minimal ada 1?
      if (currentStock > 0) {
        _items.add(CartItem(product: product));
        notifyListeners();
        return true;
      } else {
        return false;
      }
    }
  }

  // Hapus 1 Item (Logic Tombol Minus)
  void removeOneItem(Product product) {
    int index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Hapus Full Item (Tombol Sampah)
  void removeFullItem(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  // Bersihkan Keranjang (Setelah Bayar)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Hitung Total Harga
  int getTotalPrice() {
    int total = 0;
    for (var item in _items) {
      total += item.product.price * item.quantity;
    }
    return total;
  }
}
