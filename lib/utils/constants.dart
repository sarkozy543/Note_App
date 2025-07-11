import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF009688);      // Teal
  static const Color secondary = Color(0xFFFFC107);    // Amber
  static const Color accent = Color(0xFF673AB7);       // Deep Purple
  static const Color background = Color(0xFFF5F5F5);   // Light Grey
  static const Color surface = Color(0xFFFFFFFF);      // White
  static const Color text = Colors.black;         // Artık siyah
  static const Color textLight = Colors.black;    // Artık siyah

  static const List<Color> noteColors = [
    Color(0xFFFFF8E1), // Amber 50
    Color(0xFFE0F2F1), // Teal 50
    Color(0xFFEDE7F6), // Deep Purple 50
    Color(0xFFFFEBEE), // Red 50
    Color(0xFFE3F2FD), // Blue 50
    Color(0xFFF1F8E9), // Light Green 50
  ];
}

class AppDimensions {
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
}
