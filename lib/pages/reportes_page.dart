import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foto.dart';
import '../iconos_especie.dart';
import '../theme.dart';
import 'animales_page.dart';
import 'certificado_page.dart';
import 'movimientos_page.dart';
import 'nueva_incidencia_page.dart';
import 'resumen_mensual_page.dart';

// shortcut: categoría deducida de sexo y edad (no hay campo propio), agregar "propósito" al Animal cuando se necesite.
// Ordeño/Engorda solo aplica a bovinos; caballos, borregos y cerdos adultos van como "Adulto".
String categoria(Animal a) => !a.edad.contains('año')
    ? 'Cría'
    : a.especie != 'Bovino'
        ? 'Adulto'
        : (a.sexo == 'Hembra' ? 'Ordeño' : 'Engorda');

/// Archivo .xlsx con el padrón del hato: una hoja "Padrón" con encabezado y una fila por animal.
List<int> padronExcel(List<Animal> lista) {
  final libro = xl.Excel.createExcel();
  libro.rename(libro.getDefaultSheet()!, 'Padrón');
  final hoja = libro['Padrón'];
  for (final fila in [
    ['Código', 'Nombre', 'Especie', 'Sexo', 'Edad', 'Raza', 'Color', 'Arete', 'Ubicación', 'Categoría', 'Estado'],
    for (final a in lista)
      [
        a.codigo,
        a.nombre,
        a.nombreEspecie,
        a.sexo,
        a.edad,
        a.raza,
        a.color,
        a.arete ?? 'En trámite',
        a.ubicacion,
        categoria(a),
        etiquetaSalida(a) ?? (a.enTratamiento ? 'En tratamiento' : 'Activo'),
      ],
  ]) {
    hoja.appendRow([for (final c in fila) xl.TextCellValue(c)]);
  }
  return libro.save()!;
}

/// Genera el Excel y abre "Guardar como" (Android: elegir carpeta, p. ej. Descargas; computadora: diálogo de guardar).
Future<void> descargarPadron(BuildContext context) async {
  final hoy = DateTime.now();
  final nombre =
      'padron_vacatec_${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}.xlsx';
  String mensaje;
  try {
    final destino = await FilePicker.saveFile(
      dialogTitle: 'Guardar padrón en Excel',
      fileName: nombre,
      bytes: Uint8List.fromList(padronExcel(animales.value)),
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    if (destino == null) return; // el usuario canceló
    mensaje = 'Padrón guardado: $nombre';
  } catch (e) {
    mensaje = 'No se pudo guardar el Excel: $e';
  }
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
}

String _plural(int n, String palabra) => '$n ${palabra.toLowerCase()}${n == 1 ? '' : 's'}';

/// Del día 1 del mes de [hoy] hasta [hoy].
DateTimeRange periodoDelMes(DateTime hoy) =>
    DateTimeRange(start: DateTime(hoy.year, hoy.month, 1), end: DateTime(hoy.year, hoy.month, hoy.day));

/// [f] cae entre el inicio del primer día y el final del último día del periodo (ambos incluidos).
bool enPeriodo(DateTime f, DateTimeRange p) {
  final fin = DateTime(p.end.year, p.end.month, p.end.day + 1);
  return !f.isBefore(DateTime(p.start.year, p.start.month, p.start.day)) && f.isBefore(fin);
}

/// Cifras del reporte, calculadas de las listas de animales y movimientos.
/// Las del hato (total, sexo, crías, salud, arete) cuentan solo los animales que siguen en el ganado;
/// los vendidos o trasladados son las [bajas]. [periodo] solo afecta a los movimientos del periodo.
class ResumenHato {
  factory ResumenHato(List<Animal> animales, List<Movimiento> movs, DateTimeRange periodo) =>
      ResumenHato._(animales.where((a) => enHato(a, movs)).toList(), animales.length, movs, periodo);

  ResumenHato._(List<Animal> hato, this.registrados, List<Movimiento> movs, DateTimeRange periodo)
      : total = hato.length,
        ordeno = hato.where((a) => categoria(a) == 'Ordeño').length,
        engorda = hato.where((a) => categoria(a) == 'Engorda').length,
        crias = hato.where((a) => categoria(a) == 'Cría').length,
        hembras = hato.where((a) => a.sexo == 'Hembra').length,
        sinArete = hato.where((a) => a.arete == null).length,
        enTratamiento = hato.where((a) => a.enTratamiento).length,
        delPeriodo = movs.where((m) => enPeriodo(m.fecha, periodo)).toList();

  final int total, registrados, ordeno, engorda, crias, hembras, sinArete, enTratamiento;
  final List<Movimiento> delPeriodo;

  int get machos => total - hembras;
  int get activos => total;
  int get bajas => registrados - total; // vendidos o trasladados
  int get pendientes => sinArete + enTratamiento;
  int pct(int n) => total == 0 ? 0 : (n * 100 / total).round();
  String get pctActivos => registrados == 0 ? '0%' : '${(total * 100 / registrados).toStringAsFixed(1)}%';

  String get desglose {
    if (delPeriodo.isEmpty) return 'Sin movimientos en el periodo';
    return [
      for (final t in tiposMovimiento.keys)
        if (delPeriodo.any((m) => m.tipo == t)) _plural(delPeriodo.where((m) => m.tipo == t).length, t),
    ].join(', ');
  }

  String get desglosePendientes => [
        if (sinArete > 0) '$sinArete arete',
        if (enTratamiento > 0) _plural(enTratamiento, 'tratamiento'),
      ].join(', ');
}

class ReportesPage extends StatelessWidget {
  const ReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([animales, movimientos, incidencias]),
      builder: (context, _) {
        final r = ResumenHato(animales.value, movimientos.value, periodoDelMes(DateTime.now()));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _Tarjeta(
              child: Row(
                children: [
                  _iconoCuadro(Icons.assessment_outlined, AppColors.primary, AppColors.primarySoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Corte de Hato Activo',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        Text('Actualizado hoy, ${TimeOfDay.now().format(context)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  _chip('Sincronizado', AppColors.primary, AppColors.primarySoft, punto: true),
                ],
              ),
            ),
            _Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CENSO TOTAL',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppColors.textMuted)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text('${r.total}',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text)),
                                const SizedBox(width: 6),
                                const Flexible(
                                  child: Text('cabezas registradas',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _iconoCuadro(Icons.fingerprint, AppColors.primary, AppColors.primarySoft),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          _Cifra('En Ordeño', r.ordeno),
                          const VerticalDivider(color: AppColors.border, width: 1),
                          _Cifra('Engorda', r.engorda),
                          const VerticalDivider(color: AppColors.border, width: 1),
                          _Cifra('Crías', r.crias),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('POR ESPECIE',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  for (final MapEntry(key: clave, value: (_, plural, _)) in especies.entries)
                    _CensoEspecie(
                      clave,
                      plural,
                      // Las mismas cifras del reporte, solo con los animales (y ventas) de esa especie.
                      ResumenHato(
                        animales.value.where((a) => a.especie == clave).toList(),
                        movimientos.value.where((m) => m.animal.especie == clave).toList(),
                        periodoDelMes(DateTime.now()),
                      ),
                    ),
                ],
              ),
            ),
            _Tarjeta(
              child: Column(
                children: [
                  _Titulo(Icons.groups_outlined, 'Distribución por Sexo',
                      extra: Text('${r.pct(r.hembras)}% Hembras',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text))),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: r.total == 0 ? 0 : r.hembras / r.total,
                      minHeight: 8,
                      color: AppColors.primary,
                      backgroundColor: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _Caja(Icons.female, 'Hembras', '${r.hembras} cabezas')),
                      const SizedBox(width: 10),
                      Expanded(child: _Caja(Icons.male, 'Machos', '${r.machos} cabezas')),
                    ],
                  ),
                ],
              ),
            ),
            _Tarjeta(
              child: Column(
                children: [
                  const _Titulo(Icons.fact_check_outlined, 'Estado Operativo del Hato'),
                  Row(
                    children: [
                      Expanded(
                        child: _Estado('Activos', r.activos, AppColors.text,
                            _chip(r.pctActivos, AppColors.primary, AppColors.primarySoft)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Estado('Bajas del ganado', r.bajas, AppColors.danger,
                            _chip('Baja', AppColors.danger, AppColors.dangerSoft)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _Tarjeta(
              child: Column(
                children: [
                  _Titulo(Icons.swap_horiz, 'Movimientos en el Mes',
                      fondo: true,
                      extra: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResumenMensualPage())),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Text('Ver desglose',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                            ],
                          ),
                        ),
                      )),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Text('${r.delPeriodo.length}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Registrados este ciclo',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              Text(r.desglose, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _Tarjeta(
              child: Column(
                children: [
                  _Titulo(Icons.warning_amber_rounded, 'Control de Incidencias',
                      fondo: true,
                      peligro: true,
                      extra: r.pendientes == 0
                          ? null
                          : Text('${r.pendientes} Requieren atención',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.danger))),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Incidencia('Pendientes', r.pendientes, AppColors.danger,
                            r.pendientes == 0 ? 'Sin pendientes' : r.desglosePendientes,
                            const Icon(Icons.circle, size: 8, color: AppColors.danger)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Incidencia('Atendidas', incidencias.value.where((i) => i.atendida).length,
                            AppColors.text, 'Resueltas en fecha',
                            const Icon(Icons.check_circle_outline, size: 16, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hato en Seguimiento Fotográfico',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const Text('Últimos ejemplares con fichas de campo inspeccionadas',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [for (final a in animales.value.reversed.take(6)) _Mini(a)],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => descargarPadron(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.download),
                label: const Text('Exportar Padrón a Excel',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CertificadoPage())),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Certificado Oficial de Movilización',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget _chip(String text, Color fg, Color bg, {bool punto = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (punto) ...[Icon(Icons.circle, size: 7, color: fg), const SizedBox(width: 5)],
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );

Widget _iconoCuadro(IconData icon, Color fg, Color bg) => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: fg),
    );

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
        child: child,
      );
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.icon, this.text, {this.extra, this.fondo = false, this.peligro = false});

  final IconData icon;
  final String text;
  final Widget? extra;
  final bool fondo; // ícono dentro de un círculo de color
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    final fg = peligro ? AppColors.danger : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          fondo
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: peligro ? AppColors.dangerSoft : AppColors.primarySoft, shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: fg),
                )
              : Icon(icon, size: 20, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          ),
          ?extra,
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra(this.label, this.n);

  final String label;
  final int n;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Text('$n', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
          ],
        ),
      );
}

class _Caja extends StatelessWidget {
  const _Caja(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Estado extends StatelessWidget {
  const _Estado(this.label, this.n, this.color, this.chip);

  final String label;
  final int n;
  final Color color;
  final Widget chip;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text('$n', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                ],
              ),
            ),
            chip,
          ],
        ),
      );
}

class _Incidencia extends StatelessWidget {
  const _Incidencia(this.label, this.n, this.color, this.detalle, this.marca);

  final String label;
  final int n;
  final Color color;
  final String detalle;
  final Widget marca;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: TextStyle(fontSize: 11, color: color == AppColors.text ? AppColors.textMuted : color)),
                ),
                marca,
              ],
            ),
            Text('$n', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(detalle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      );
}

class _Mini extends StatelessWidget {
  const _Mini(this.a);

  final Animal a;

  @override
  Widget build(BuildContext context) => Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            FotoAnimal(a.foto, size: 36, radius: 6, iconSize: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${a.codigo} (${a.nombre})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text('${a.edad} · ${categoria(a)}',
                      overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Bloque del censo para una especie: total y todos sus datos (sexo, edad, salud, arete y bajas).
class _CensoEspecie extends StatelessWidget {
  const _CensoEspecie(this.especie, this.plural, this.r);

  final String especie;
  final String plural;
  final ResumenHato r;

  @override
  Widget build(BuildContext context) {
    final vacio = r.total == 0;
    final datos = <(String, int, Color?)>[
      ('Hembras', r.hembras, null),
      ('Machos', r.machos, null),
      ('Crías', r.crias, null),
      if (especie == 'Bovino') ...[('Ordeño', r.ordeno, null), ('Engorda', r.engorda, null)]
      else ('Adultos', r.total - r.crias, null),
      ('En tratamiento', r.enTratamiento, r.enTratamiento > 0 ? AppColors.danger : null),
      ('Sin arete', r.sinArete, r.sinArete > 0 ? AppColors.warning : null),
      ('Bajas (venta, traslado, muerte o robo)', r.bajas, r.bajas > 0 ? AppColors.danger : null),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: IconoEspecie(especie, size: 26, color: vacio ? AppColors.textMuted : AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(plural,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: vacio ? AppColors.textMuted : AppColors.text)),
              ),
              Text('${r.total}',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: vacio ? AppColors.textMuted : AppColors.text)),
              const SizedBox(width: 4),
              Text(r.total == 1 ? 'cabeza' : 'cabezas', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          if (!vacio) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (etiqueta, n, alerta) in datos)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: alerta == null ? AppColors.surface : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text.rich(TextSpan(
                      text: '$etiqueta ',
                      style: TextStyle(fontSize: 11, color: alerta ?? AppColors.textMuted),
                      children: [
                        TextSpan(
                            text: '$n',
                            style: TextStyle(fontWeight: FontWeight.w800, color: alerta ?? AppColors.text)),
                      ],
                    )),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
