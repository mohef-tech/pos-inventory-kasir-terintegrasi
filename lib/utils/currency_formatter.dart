import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Kalau kosong, biarkan kosong
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya ambil angka (buang titik atau karakter lain)
    // Contoh: "15.000" -> "15000"
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Cegah error kalau user hapus semua jadi string kosong
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format jadi Rupiah (pakai titik)
    final int value = int.parse(newText);
    final formatter = NumberFormat('#,###', 'id');
    final String newString = formatter.format(value);

    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }

  // Fungsi Bantuan: Mengubah String "15.000" kembali jadi Integer 15000 buat database
  static int toInt(String text) {
    String clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.isEmpty ? 0 : int.parse(clean);
  }
}
