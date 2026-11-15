import 'package:flutter/material.dart';

/// true cuando el dispositivo está en modo oscuro. Lo actualiza la app al iniciar y cuando cambia el tema
/// del sistema (ver MiGanadoApp en main.dart); todos los colores de [AppColors] dependen de él.
bool modoOscuro = false;

// Colores de AgroRegister: (tema claro, tema oscuro).
class AppColors {
  static Color _c(int claro, int oscuro) => Color(modoOscuro ? oscuro : claro);

  static Color get primary => _c(0xFF1E5B3F, 0xFF3D9A6C); // verde (botón "+", nav activo)
  static Color get primarySoft => _c(0xFFDCEBE3, 0xFF1F3A2D); // verde suave (íconos, banners)
  static Color get danger => _c(0xFFC62828, 0xFFEF6B6B); // rojo (enfermos, bajas)
  static Color get dangerSoft => _c(0xFFFCE1DC, 0xFF4A2626); // fondo rojo suave
  static Color get warning => _c(0xFF8D3B2A, 0xFFE0A07A); // café rojizo (hembras, sin arete)
  static Color get background => _c(0xFFF4F6F5, 0xFF121614);
  static Color get surface => _c(0xFFFFFFFF, 0xFF1C211E); // tarjetas
  static Color get text => _c(0xFF1A1A1A, 0xFFE6EBE8);
  static Color get textMuted => _c(0xFF5F6B66, 0xFF9AA8A1);
  static Color get border => _c(0xFFE6EAE8, 0xFF2C3530);
}

// Sombra suave que usan las tarjetas del diseño (en oscuro casi no se nota, como debe ser).
const cardShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
];

/// Tema de la app con los colores de [AppColors] para el modo actual ([modoOscuro]).
ThemeData temaApp() => ThemeData(
      useMaterial3: true,
      brightness: modoOscuro ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: modoOscuro ? Brightness.dark : Brightness.light,
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
        indicatorColor: AppColors.primarySoft, // fondo verde suave animado tras la pestaña activa
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

/// Aviso para funciones que aún no están disponibles (exportar PDF, escáner, etc.).
void avisoProximamente(BuildContext context, String que) => ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text('$que estará disponible en una próxima versión')));
