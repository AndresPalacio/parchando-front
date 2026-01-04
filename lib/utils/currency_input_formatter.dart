import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remover todo lo que no sea dígito
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si no hay texto después de limpiar, retornar vacío
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Convertir a número y formatear
    double value = double.parse(newText);
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '',
      decimalDigits: 0,
    );
    String formatted = formatter.format(value).trim();

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

