import 'package:flutter/material.dart';

import 'datos.dart';
import 'notificaciones_sistema.dart';
import 'pages/animales_page.dart';
import 'pages/inicio_page.dart';
import 'pages/login_page.dart';
import 'pages/movimientos_page.dart';
import 'pages/notificaciones_page.dart';
import 'pages/perfil_page.dart';
import 'pages/reportes_page.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await iniciarDatos();
  runApp(const MiGanadoApp());
}

class MiGanadoApp extends StatefulWidget {
  const MiGanadoApp({super.key});

  @override
  State<MiGanadoApp> createState() => _MiGanadoAppState();
}

/// Sigue el tema claro/oscuro del dispositivo y redibuja toda la app cuando cambia.
class _MiGanadoAppState extends State<MiGanadoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    modoOscuro = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    return MaterialApp(
      // Los colores de AppColors se leen al construir cada pantalla; con la llave nueva todo se vuelve a
      // construir con el tema actual. shortcut: al cambiar el tema con la app abierta se vuelve a Inicio.
      key: ValueKey(modoOscuro),
      title: 'AgroRegister',
      debugShowCheckedModeBanner: false,
      theme: temaApp(),
      home: ValueListenableBuilder(
        valueListenable: usuarioActual,
        builder: (_, usuario, _) => usuario == null ? const LoginPage() : const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

/// Pestaña visible del menú inferior; otras pantallas la cambian para llevar al usuario a una pestaña.
final pestanaActual = ValueNotifier(0);

class _HomeShellState extends State<HomeShell> {
  int get _index => pestanaActual.value;

  static const _titles = ['Inicio', 'Animales', 'Movimientos', 'Reportes'];
  static const _pages = [InicioPage(), AnimalesPage(), MovimientosPage(), ReportesPage()];

  void _refrescar() => setState(() {});

  @override
  void initState() {
    super.initState();
    pestanaActual.value = 0;
    pestanaActual.addListener(_refrescar);
    iniciarNotificaciones(); // ya con sesión abierta: avisos de campo en la barra del teléfono
  }

  @override
  void dispose() {
    pestanaActual.removeListener(_refrescar);
    super.dispose();
  }

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
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => pestanaActual.value = i,
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

// Encabezado común: logo, título de la página y avatar.
class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/icon/icon.png', width: 36, height: 36, semanticLabel: 'AgroRegister'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
          ),
          // Campana con el número de avisos de campo pendientes.
          ListenableBuilder(
            listenable: cambiosDeAvisos,
            builder: (context, _) {
              final n = avisosSinLeer().length; // solo los que no se han visto
              return IconButton(
                tooltip: 'Notificaciones',
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificacionesPage())),
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text(n > 99 ? '99+' : '$n'),
                  backgroundColor: AppColors.danger,
                  child: Icon(Icons.notifications_none, color: AppColors.text, size: 26),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
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
                child: CircleAvatar(
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
