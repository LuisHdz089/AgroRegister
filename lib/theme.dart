import 'package:flutter/material.dart';

// Colores tomados del diseño de Mi Ganado.
class AppColors {
  static const primary = Color(0xFF1E5B3F); // verde oscuro (botón "+", nav activo)
  static const primarySoft = Color(0xFFDCEBE3); // verde claro (íconos, banners)
  static const danger = Color(0xFFC62828); // rojo (enfermos)
  static const dangerSoft = Color(0xFFFCE1DC); // rosa claro
  static const warning = Color(0xFF8D3B2A); // café rojizo (hembras, incidencia)
  static const background = Color(0xFFF4F6F5);
  static const surface = Colors.white;
  static const text = Color(0xFF1A1A1A);
  static const textMuted = Color(0xFF5F6B66);
  static const border = Color(0xFFE6EAE8);
}

// Sombra suave que usan las tarjetas del diseño.
const cardShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
];

final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.background,
    error: AppColors.danger,
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith(
      (s) => IconThemeData(
        color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.text,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (s) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.text,
      ),
    ),
  ),
);
