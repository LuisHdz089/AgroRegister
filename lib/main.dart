import 'package:flutter/material.dart';

import 'pages/animales_page.dart';
import 'pages/inicio_page.dart';
import 'pages/movimientos_page.dart';
import 'pages/perfil_page.dart';
import 'pages/reportes_page.dart';
import 'theme.dart';

void main() => runApp(const MiGanadoApp());

class MiGanadoApp extends StatelessWidget {
  const MiGanadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Ganado',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Inicio', 'Animales', 'Movimientos', 'Reportes'];
  static const _pages = [InicioPage(), AnimalesPage(), MovimientosPage(), ReportesPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(title: _titles[_index]),
            Expanded(child: IndexedStack(index: _index, children: _pages)),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
            NavigationDestination(icon: Icon(Icons.pets_outlined), label: 'Animales'),
            NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Movimientos'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reportes'),
          ],
        ),
      ),
    );
  }
}

// Encabezado común: logo, "MI GANADO" + título de la página, avatar.
class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // shortcut: ícono en lugar del logo, cambiar por Image.asset cuando exista el archivo.
          const Icon(Icons.agriculture, color: AppColors.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MI GANADO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Perfil',
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PerfilPage()),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primarySoft, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
