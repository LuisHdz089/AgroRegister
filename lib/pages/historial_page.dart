import 'package:flutter/material.dart';

import '../foto.dart';
import '../iconos_especie.dart';
import '../theme.dart';
import 'animales_page.dart';
import 'movimientos_page.dart';
import 'nueva_incidencia_page.dart';
import 'nuevo_movimiento_page.dart';

const _azul = Color(0xFF1565C0);
const _azulSoft = Color(0xFFDCE8F7);

/// Un punto de la línea de tiempo (movimiento o incidencia).
class Evento {
  const Evento(this.fecha, this.titulo, this.etiqueta, this.fg, this.bg, this.descripcion, this.detalles,
      {this.folio, required this.esIncidencia, required this.animal, required this.icono});

  final DateTime fecha;
  final String titulo;
  final String etiqueta;
  final Color fg, bg;
  final String descripcion;
  final List<(IconData, String)> detalles;
  final String? folio;
  final bool esIncidencia;
  final Animal animal;
  final IconData icono;
}

// Getter (no constante): los colores cambian con el tema claro/oscuro.
Map<String, (String, String, Color, Color)> get _vistaMovimiento => {
  'Venta': ('Venta definitiva', 'Egreso', AppColors.danger, AppColors.dangerSoft),
  'Compra': ('Ingreso de Compra', 'Ingreso', AppColors.textMuted, AppColors.border),
  'Traslado': ('Traslado interno', 'Manejo', AppColors.primary, AppColors.primarySoft),
  'Nacimiento': ('Parto / Nacimiento', 'Reproducción', _azul, _azulSoft),
};

/// Movimientos e incidencias de un animal (o de todo el hato si [codigo] es null), del más reciente al más antiguo.
List<Evento> eventosDe(String? codigo) {
  final lista = <Evento>[
    for (final m in movimientos.value.where((m) => codigo == null || m.animal.codigo == codigo))
      () {
        final (titulo, etiqueta, fg, bg) = _vistaMovimiento[m.tipo]!;
        return Evento(
          m.fecha,
          titulo,
          etiqueta,
          fg,
          bg,
          m.notas,
          [
            if (m.origenDestino.isNotEmpty)
              (
                Icons.location_on_outlined,
                switch (m.tipo) {
                  'Venta' => 'Comprador: ${m.origenDestino}',
                  'Compra' => 'Origen: ${m.origenDestino}',
                  'Traslado' => 'Destino: ${m.origenDestino}',
                  _ => m.origenDestino, // nacimiento: ya dice "Madre: …"
                }
              ),
            if (m.guia.isNotEmpty) (Icons.receipt_long_outlined, 'Guía ${m.guia}'),
            if (m.monto != null) (Icons.payments_outlined, '\$${m.monto!.toStringAsFixed(2)}'),
            if (m.documento != null) (Icons.attach_file, 'Documento adjunto'),
          ],
          folio: m.folio,
          esIncidencia: false,
          animal: m.animal,
          icono: tiposMovimiento[m.tipo]!,
        );
      }(),
    for (final i in incidencias.value.where((i) => codigo == null || i.animal.codigo == codigo))
      Evento(
        i.fecha,
        i.tipo,
        i.atendida ? 'Atendida' : 'Pendiente',
        i.atendida ? AppColors.primary : AppColors.danger,
        i.atendida ? AppColors.primarySoft : AppColors.dangerSoft,
        i.notas,
        [
          (Icons.build_circle_outlined, i.accion),
          if (i.detalle.isNotEmpty) (Icons.notes, i.detalle),
          if (i.areteNuevo != null) (Icons.sell_outlined, 'Nuevo arete: ${i.areteNuevo}'),
        ],
        esIncidencia: true,
        animal: i.animal,
        icono: tiposIncidencia[i.tipo]!,
      ),
  ];
  lista.sort((a, b) => b.fecha.compareTo(a.fecha));
  return lista;
}

// Historial de un animal: se abre desde "Historial de movimientos" o "Incidencias y salud" en la ficha.
class HistorialPage extends StatefulWidget {
  const HistorialPage(this.codigo, {super.key, this.incidencias = false});

  final String codigo;
  final bool incidencias; // pestaña inicial

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  late bool _verIncidencias = widget.incidencias;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([animales, movimientos, incidencias]),
      builder: (context, _) {
        final a = animales.value.firstWhere((x) => x.codigo == widget.codigo);
        final todos = eventosDe(a.codigo);
        final nInc = todos.where((e) => e.esIncidencia).length;
        final lista = todos.where((e) => e.esIncidencia == _verIncidencias).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            title: const Text('Ficha De Animal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(Icons.person, size: 20, color: AppColors.primary),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _Encabezado(a),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _Segmento(Icons.swap_horiz, 'Movimientos (${todos.length - nInc})', !_verIncidencias,
                        () => setState(() => _verIncidencias = false)),
                    _Segmento(Icons.medical_services_outlined, 'Incidencias ($nInc)', _verIncidencias,
                        () => setState(() => _verIncidencias = true)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('LÍNEA DE TIEMPO REGISTRADA',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textMuted)),
                  ),
                  _chip('Trazabilidad oficial', AppColors.primary, AppColors.primarySoft),
                ],
              ),
              const SizedBox(height: 12),
              if (lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_verIncidencias ? 'Sin incidencias registradas' : 'Sin movimientos registrados',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                ),
              for (final (i, e) in lista.indexed) _Punto(e, ultimo: i == lista.length - 1),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          _verIncidencias ? NuevaIncidenciaPage(animal: a) : NuevoMovimientoPage(animal: a))),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(_verIncidencias ? 'Añadir Nueva Incidencia' : 'Añadir Nuevo Evento',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => avisoProximamente(context, 'La descarga en PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Descargar Ficha en PDF', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _chip(String text, Color fg, Color bg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );

class _Encabezado extends StatelessWidget {
  const _Encabezado(this.a);

  final Animal a;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
      child: Row(
        children: [
          FotoAnimal(a.foto, size: 56, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(a.nombre.isEmpty ? a.codigo : a.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                    ),
                    const SizedBox(width: 6),
                    _chip(a.codigo, AppColors.textMuted, AppColors.border),
                  ],
                ),
                conIconoEspecie(
                  a.especie,
                  Text('${a.raza} • ${a.sexo} • Arete ${a.arete ?? 'en trámite'}',
                      overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  size: 14,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              a.enTratamiento
                  ? _chip('En tratamiento', AppColors.danger, AppColors.dangerSoft)
                  : _chip('Activo', AppColors.primary, AppColors.primarySoft),
              const SizedBox(height: 4),
              Text(a.edad, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento(this.icon, this.label, this.activo, this.onTap);

  final IconData icon;
  final String label;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = activo ? Colors.white : AppColors.text;
    return Expanded(
      child: Material(
        color: activo ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto(this.e, {required this.ultimo});

  final Evento e;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(width: 10, height: 10, decoration: BoxDecoration(color: e.fg, shape: BoxShape.circle)),
                if (!ultimo) Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: cardShadow),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(e.titulo,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                      ),
                      const SizedBox(width: 6),
                      _chip(e.etiqueta, e.fg, e.bg),
                      const Spacer(),
                      Text(fechaCorta(e.fecha),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
                    ],
                  ),
                  if (e.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(e.descripcion, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                  if (e.detalles.isNotEmpty || e.folio != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final (icon, texto) in e.detalles)
                                  Row(
                                    children: [
                                      Icon(icon, size: 13, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(texto,
                                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (e.folio != null)
                            Text('Folio #${e.folio}',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
