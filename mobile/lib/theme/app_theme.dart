import 'package:flutter/material.dart';

/// Configuração visual premium baseada em **Material Design 3** para o AgroSense Mesh.
/// Paleta moderna inspirada em agrotechs de ponta: Esmeralda Profundo, Menta Vibrante e Cinza Ardósia.
class AppTheme {
  // Cores Primárias e Acentos
  static const Color agroGreenPrimary = Color(0xFF065F46); // Emerald 800 - Sólido e profissional
  static const Color agroGreenSecondary = Color(0xFF059669); // Emerald 600 - Destaques naturais
  static const Color agroMint = Color(0xFF10B981); // Emerald 500 - Conectividade e status ativo
  static const Color agroDark = Color(0xFF06281B); // Verde Ultra-Escuro para gradientes
  static const Color agroAccentAmber = Color(0xFFF59E0B); // Alerta Âmbar para Umidade Baixa / Sync Pendente
  static const Color waterBlue = Color(0xFF0284C7); // Sky 600 - Destaque de irrigação e água
  static const Color dangerRed = Color(0xFFEF4444); // Red 500 - Alerta crítico de solo seco

  // Cores de Superfície e Fundo
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50 - Fundo limpo e sofisticado
  static const Color cardSurface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0); // Slate 200 - Bordas suaves e elegantes
  static const Color textDark = Color(0xFF0F172A); // Slate 900 - Contraste alto e legibilidade
  static const Color textMuted = Color(0xFF64748B); // Slate 500 - Textos secundários

  // Status de Sincronização
  static const Color syncGreen = Color(0xFF10B981);
  static const Color pendingOrange = Color(0xFFF59E0B);

  // Sombras Modernas e Sutis
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withAlpha(10),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withAlpha(12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: null,
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: agroGreenPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: agroGreenPrimary,
          side: const BorderSide(color: agroGreenPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: agroGreenPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
