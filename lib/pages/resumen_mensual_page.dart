import 'dart:math';

import 'package:flutter/material.dart';

import '../datos.dart';
import '../foto.dart';
import '../main.dart';
import '../theme.dart';
import 'animales_page.dart';
import 'ficha_animal_page.dart';
import 'historial_page.dart';
import 'movimientos_page.dart';
import 'nueva_incidencia_page.dart';
import 'reportes_page.dart';

// Resumen del Hato entre dos fechas (por defecto, del día 1 del mes a hoy).
// Se abre desde "Ver desglose" en Reportes.
class ResumenMensualPage extends StatefulWidget {
  const ResumenMensualPage({super.key});

  @override
  State<ResumenMensualPage> createState() => _ResumenMensualPageState();
}

class _ResumenMensualPageState extends State<ResumenMensualPage> {
  late DateTimeRange _periodo = periodoDelMes(DateTime.now());

  void _irAPestana(BuildContext context, int i) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    pestanaActual.value = i;
  }

  Future<void> _elegirPeriodo() async {
    final hoy = DateTime.now();
    final p = await showDateRangePicker(
      context: context,
      initialDateRange: _periodo,
      firstDate: DateTime(hoy.year - 30),
      lastDate: hoy,
      helpText: 'Periodo del resumen',
    );
    if (p != null) setState(() => _periodo = p);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([animales, movimientos, incidencias]),
      builder: (context, _) {
        final r = ResumenHato(animales.value, movimientos.value, _periodo);
        final delMes = eventosDe(null).where((e) => enPeriodo(e.fecha, _periodo)).toList();
        final ocupacion = min(r.total / rancho.value.capacidad, 1.0);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            title: const Text('Resumen del Periodo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _elegirPeriodo,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Periodo',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              Text('${fechaCorta(_periodo.start)}  –  ${fechaCorta(_periodo.end)}',
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                            ],
                          ),
                        ),
                        const Text('Cambiar',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF2E7D57)]),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.agriculture, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(rancho.value.nombre.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.white70)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text('Resumen del Hato',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('Control visual integral y balance general',
                              style: TextStyle(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.donut_large, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Tarjeta(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pie_chart_outline, size: 20, color: AppColors.text),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Distribución General',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                        ),
                        _chip('Actualizado hoy', AppColors.primary, AppColors.primarySoft),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: CustomPaint(
                        painter: _Dona(r),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${r.total}',
                                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.text)),
                              const Text('TOTAL',
                                  style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Leyenda(AppColors.primary, 'Hembras', '${r.hembras}', '(${r.pct(r.hembras)}%)'),
                    _Leyenda(_gris, 'Machos', '${r.machos}', '(${r.pct(r.machos)}%)'),
                    _Leyenda(_verdeClaro, 'Activos en Hato', '${r.activos}', ''),
                    _Leyenda(AppColors.danger, 'Bajas del ganado', '${r.bajas}', '', alerta: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Capacidad de potrero',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
                        ),
                        Text('${(ocupacion * 100).round()}% ocupación',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ocupacion,
                        minHeight: 6,
                        color: AppColors.primary,
                        backgroundColor: _gris,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text('Ejemplares Destacados',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                  ),
                  _Enlace('Ver inventario', () => _irAPestana(context, 1)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, a) in animales.value.where(enHato).take(2).indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _Destacado(a)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _Tarjeta(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, size: 20, color: AppColors.text),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Últimos Movimientos',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                        ),
                        Text('${delMes.length} en el periodo',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (delMes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Sin movimientos en el periodo', style: TextStyle(color: AppColors.textMuted)),
                      ),
                    for (final e in delMes.take(6)) _Ultimo(e),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: () => _irAPestana(context, 2),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primarySoft,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.library_books_outlined, size: 18),
                        label: const Text('Ver historial completo de bitácora',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const _gris = Color(0xFF4A5A52);
const _verdeClaro = Color(0xFF8FD6B0);

Widget _chip(String text, Color fg, Color bg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
        child: child,
      );
}

class _Enlace extends StatelessWidget {
  const _Enlace(this.text, this.onTap);

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
            ],
          ),
        ),
      );
}

/// Anillo exterior: hembras/machos. Anillo interior: activos (verde claro) y bajas (rojo).
class _Dona extends CustomPainter {
  _Dona(this.r);

  final ResumenHato r;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    void arco(double radio, double ancho, double desde, double fraccion, Color color) {
      if (fraccion <= 0) return;
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: radio),
        -pi / 2 + desde * 2 * pi,
        fraccion * 2 * pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ancho
          ..color = color,
      );
    }

    final ext = size.width / 2 - 10, inter = ext - 18;
    if (r.registrados == 0) return arco(ext, 18, 0, 1, AppColors.border);
    // Exterior: hembras/machos del ganado actual. Interior: activos/bajas de todos los registrados.
    final h = r.total == 0 ? 0.0 : r.hembras / r.total, b = r.bajas / r.registrados;
    if (r.total == 0) arco(ext, 18, 0, 1, AppColors.border);
    arco(ext, 18, 0, h, AppColors.primary);
    if (r.total > 0) arco(ext, 18, h, 1 - h, _gris);
    arco(inter, 6, 0, b, AppColors.danger);
    arco(inter, 6, b, 1 - b, _verdeClaro);
  }

  @override
  bool shouldRepaint(_Dona old) => true;
}

class _Leyenda extends StatelessWidget {
  const _Leyenda(this.color, this.label, this.valor, this.pct, {this.alerta = false});

  final Color color;
  final String label, valor, pct;
  final bool alerta;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: alerta ? AppColors.dangerSoft : AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: alerta ? AppColors.danger : AppColors.text)),
            ),
            Text(valor,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: alerta ? AppColors.danger : AppColors.text)),
            if (pct.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(pct, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ],
        ),
      );
}

class _Destacado extends StatelessWidget {
  const _Destacado(this.a);

  final Animal a;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FichaAnimalPage(a))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: Stack(
                children: [
                  Positioned.fill(child: FotoAnimal(a.foto, size: double.infinity, radius: 0, iconSize: 36)),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: a.enTratamiento
                        ? _chip('En tratamiento', Colors.white, AppColors.danger)
                        : _chip(a.sexo == 'Hembra' ? 'Activa' : 'Activo', Colors.white, AppColors.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.nombre.isEmpty ? a.codigo : a.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text('${a.codigo} • ${a.sexo}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ultimo extends StatelessWidget {
  const _Ultimo(this.e);

  final Evento e;

  @override
  Widget build(BuildContext context) {
    final extra = e.detalles.firstOrNull?.$2;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: e.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(e.icono, size: 20, color: e.fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.titulo,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text('${e.animal.codigo} • ${e.animal.nombre}${extra == null ? '' : ' ($extra)'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fechaCorta(e.fecha),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text)),
              Text(e.etiqueta, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: e.fg)),
            ],
          ),
        ],
      ),
    );
  }
}
