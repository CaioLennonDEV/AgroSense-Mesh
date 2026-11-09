import 'package:flutter/material.dart';

/// Configuração oficial de Design System baseado em **Material Design 3** para o AgroSense Mesh.
class AppTheme {
  static const Color agroGreenPrimary = Color(0xFF1B5E20); // Verde Escuro Florestal
  static const Color agroGreenSecondary = Color(0xFF2E7D32); // Esmeralda de Campo
  static const Color agroAccentAmber = Color(0xFFF59E0B); // Alerta Âmbar para Umidade Baixa
  static const Color backgroundLight = Color(0xFFF4F7F5);
  static const Color cardSurface = Colors.white;
  static const Color textDark = Color(0xFF1C2826);
  static const Color syncGreen = Color(0xFF10B981);
  static const Color pendingOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFDC2626);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: agroGreenPrimary,
        primary: agroGreenPrimary,
        secondary: agroGreenSecondary,
        surface: cardSurface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: agroGreenPrimary,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: cardSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: agroGreenPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: agroGreenPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed),
        ),
      ),
    );
  }
}

