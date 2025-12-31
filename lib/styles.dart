import 'package:flutter/material.dart';

class AppColors {
  // Colores principales del home
  static const scaffoldBackground = Color(0xFFF8F7FF); // Fondo morado/lavanda sutil
  static const cardBackground = Colors.white;
  static const primary = Color(0xFF1E2B45); // Azul oscuro principal
  static const primaryDark = Color(0xFF2E3E5C); // Azul oscuro secundario
  static const accent = Colors.orange; // Naranja para acentos
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFA3A3A3);
  static const border = Color(0xFFE0E0E0);
}

class AppTextStyles {
  static const appBarTitle = TextStyle(
      fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const headerTitle = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const headerDate =
      TextStyle(fontSize: 14, color: AppColors.textSecondary);
  static const itemQuantity =
      TextStyle(fontSize: 14, color: AppColors.textSecondary);
  static const itemName = TextStyle(fontSize: 16, color: AppColors.textPrimary);
  static const itemPrice =
      TextStyle(fontSize: 16, color: AppColors.textPrimary);
  static const label = TextStyle(fontSize: 14, color: AppColors.textSecondary);
  static const labelBold = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
}

class AppDecorations {
  static const double borderRadius = 24.0;
  static final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(borderRadius),
  );
}

const kEmptyInputDecoration = InputDecoration(
  border: InputBorder.none,
  isDense: true,
  contentPadding: EdgeInsets.zero,
  hintStyle: AppTextStyles.headerDate,
);
