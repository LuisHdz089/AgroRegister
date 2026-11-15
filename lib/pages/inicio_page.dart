import 'package:flutter/material.dart';

import '../datos.dart';
import '../foto.dart';
import '../main.dart';
import '../iconos_especie.dart';
import '../theme.dart';
import 'animales_page.dart';
import 'ficha_animal_page.dart';
import 'historial_page.dart';
import 'movimientos_page.dart';
import 'nueva_incidencia_page.dart';
import 'nuevo_animal_page.dart';
import 'nuevo_movimiento_page.dart';
import 'reportes_page.dart';

/// Animales con actividad más reciente (movimientos/incidencias); si faltan, los últimos registrados.
List<Animal> inspeccionReciente(int n) {
  final codigos = <String>{
    for (final e in eventosDe(null)) e.animal.codigo,
    for (final a in animales.value.reversed) a.codigo,
  };
  return [for (final c in codigos.take(n)) animales.value.firstWhere((a) => a.codigo == c)];
}

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([animales, movimientos, incidencias, rancho]),
      builder: (context, _) {
        final r = ResumenHato(animales.value, movimientos.value, periodoDelMes(DateTime.now()));
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _Saludo(rancho.value, r.pendientes),
            SizedBox(height: 24),
            _Seccion('Resumen de hato', accion: 'Actualizado hoy'),
            _Resumen(r),
            SizedBox(height: 24),
            _Seccion('Accesos rápidos'),
            _Acceso(
              icon: Icons.add,
              iconColor: Colors.white,
              bg: AppColors.primary,
              title: 'Agregar animal',
              subtitle: 'Registro con foto, arete y datos',
              destino: NuevoAnimalPage.new,
            ),
            _Acceso(
              icon: Icons.swap_horiz,
              iconColor: AppColors.primary,
              bg: AppColors.primarySoft,
              title: 'Registrar movimiento',
              subtitle: 'Ventas, traslados, compras o nacimientos',
              destino: NuevoMovimientoPage.new,
            ),
            _Acceso(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.warning,
              bg: AppColors.dangerSoft,
              title: 'Reportar incidencia',
              subtitle: 'Pérdida de arete, golpe o tratamiento',
              destino: NuevaIncidenciaPage.new,
            ),
            SizedBox(height: 12),
            _Seccion('Inspección reciente', accion: 'Ver todas →', onAccion: () => pestanaActual.value = 1),
            for (final a in inspeccionReciente(2)) _Animal(a),
          ],
        );
      },
    );
  }
}

BoxDecoration _card() =>
    BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow);

Widget _chip(String text, {Widget? leading, Color? fg, Color? bg}) =>
    Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg ?? AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?leading,
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg ?? AppColors.primary),
          ),
        ],
      ),
    );

class _Saludo extends StatelessWidget {
  const _Saludo(this.rancho, this.pendientes);

  final Rancho rancho;
  final int pendientes;

  @override
  Widget build(BuildContext context) {
    final fg = pendientes == 0 ? AppColors.primary : AppColors.danger;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rancho.nombre.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Buen día, ${rancho.saludo} 👋',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
            ],
          ),
        ),
        _chip(
          pendientes == 0 ? 'Hato al día' : '$pendientes pendientes',
          fg: fg,
          bg: pendientes == 0 ? AppColors.primarySoft : AppColors.dangerSoft,
          leading: Container(
            width: 7,
            height: 7,
            margin: EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.title, {this.accion, this.onAccion});

  final String title;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
          ),
          if (accion != null)
            InkWell(
              onTap: onAccion,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  accion!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen(this.r);

  final ResumenHato r;

  static TextStyle get _muted => TextStyle(fontSize: 13, color: AppColors.textMuted);

  @override
  Widget build(BuildContext context) {
    final enfermos = animales.value.where((a) => a.enTratamiento && enHato(a)).toList();
    return Column(
      children: [
        _FilaStats(
          _Stat(
            label: 'Total animales',
            filtro: (sexo: null, tratamiento: false),
            icon: Icons.pets,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft,
            value: Text('${r.total}'),
            footer: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${r.pct(r.total - r.sinArete)}% con arete',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          _Stat(
            label: 'Hembras',
            filtro: (sexo: 'Hembra', tratamiento: false),
            icon: Icons.female,
            iconColor: AppColors.warning,
            iconBg: AppColors.dangerSoft,
            value: Text('${r.hembras}'),
            footer: Text('${r.pct(r.hembras)}% del total', style: _muted),
          ),
        ),
        const SizedBox(height: 12),
        _FilaStats(
          _Stat(
            label: 'Machos',
            filtro: (sexo: 'Macho', tratamiento: false),
            icon: Icons.male,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft,
            value: Text('${r.machos}'),
            footer: Text('${r.pct(r.machos)}% del total', style: _muted),
          ),
          _Stat(
            label: 'Enfermos',
            filtro: (sexo: null, tratamiento: true),
            icon: Icons.medical_services,
            iconColor: AppColors.danger,
            iconBg: AppColors.dangerSoft,
            value: Text.rich(
              TextSpan(
                text: '${enfermos.length} ',
                style: TextStyle(color: enfermos.isEmpty ? AppColors.text : AppColors.danger),
                children: [
                  if (enfermos.isNotEmpty)
                    const TextSpan(
                      text: 'Revisión',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
            footer: Text(
              enfermos.isEmpty ? 'Sin casos' : enfermos.map((a) => a.codigo).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaStats extends StatelessWidget {
  const _FilaStats(this.a, this.b);

  final Widget a;
  final Widget b;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.footer,
    required this.filtro,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget value;
  final Widget footer;
  final ({String? sexo, bool tratamiento}) filtro; // filtro con el que se abre Animales al tocarla

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            pedidoFiltroAnimales.value = filtro;
            pestanaActual.value = 1;
          },
          child: Padding(padding: const EdgeInsets.all(14), child: _contenido()),
        ),
      ),
    );
  }

  Widget _contenido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: iconColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DefaultTextStyle.merge(
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.text, height: 1.1),
          child: value,
        ),
        const SizedBox(height: 4),
        footer,
      ],
    );
  }
}

class _Acceso extends StatelessWidget {
  const _Acceso({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.destino,
  });

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String subtitle;
  final Widget Function() destino; // pantalla que abre

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino())),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                  child: Icon(Icons.chevron_right, size: 20, color: AppColors.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Animal extends StatelessWidget {
  const _Animal(this.a);

  final Animal a;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FichaAnimalPage(a))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FotoAnimal(a.foto, size: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.nombre.isEmpty ? a.codigo : '${a.codigo} · ${a.nombre}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                            ),
                          ),
                          etiquetaSalida(a) != null
                              ? _chip(etiquetaSalida(a)!, fg: AppColors.textMuted, bg: AppColors.border)
                              : a.enTratamiento
                                  ? _chip('En tratamiento', fg: AppColors.danger, bg: AppColors.dangerSoft)
                                  : _chip('Activo'),
                        ],
                      ),
                      const SizedBox(height: 2),
                      conIconoEspecie(
                        a.especie,
                        Text(
                          '${a.sexo} · ${a.raza} · ${a.edad}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.sell_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            a.arete == null ? 'Arete en trámite' : 'Arete #${a.arete}',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: AppColors.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
