import 'package:flutter/material.dart';

import '../foto.dart';
import '../iconos_especie.dart';
import '../theme.dart';
import 'animales_page.dart';
import 'movimientos_page.dart';
import 'nuevo_movimiento_page.dart';

const tiposIncidencia = {
  'Pérdida de arete': Icons.sell_outlined,
  'Golpe o lesión': Icons.healing_outlined,
  'Enfermedad': Icons.sick_outlined,
  'Tratamiento o vacuna': Icons.vaccines_outlined,
  'Muerte': Icons.heart_broken_outlined,
  'Robo o extravío': Icons.search_off,
};

/// Qué pide cada tipo de incidencia: sus acciones posibles, un dato propio ([detalle], con su etiqueta)
/// y si da de baja al animal ([baja]: deja de contarse en el ganado, como una venta).
typedef ReglaIncidencia = ({
  List<String> acciones,
  String? detalle,
  bool detalleObligatorio,
  String detalleEjemplo,
  bool arete,
  bool baja,
  String notas,
});

const Map<String, ReglaIncidencia> reglasIncidencia = {
  'Pérdida de arete': (
    acciones: ['Cambio y reposición de arete', 'Arete en trámite (pendiente)'],
    detalle: null,
    detalleObligatorio: false,
    detalleEjemplo: '',
    arete: true,
    baja: false,
    notas: 'Ej. Se perdió el arete izquierdo durante el pastoreo...',
  ),
  'Golpe o lesión': (
    acciones: ['Curación en campo', 'Tratamiento veterinario', 'En observación (pendiente)'],
    detalle: 'Zona afectada',
    detalleObligatorio: false,
    detalleEjemplo: 'Ej. Pata trasera izquierda',
    arete: false,
    baja: false,
    notas: 'Ej. Se golpeó contra la cerca del corral...',
  ),
  'Enfermedad': (
    acciones: ['Tratamiento veterinario', 'Aislamiento y observación (pendiente)', 'Curación en campo'],
    detalle: 'Diagnóstico o síntomas',
    detalleObligatorio: true,
    detalleEjemplo: 'Ej. Fiebre, tos y falta de apetito',
    arete: false,
    baja: false,
    notas: 'Ej. Revisado por el veterinario, receta por 5 días...',
  ),
  'Tratamiento o vacuna': (
    acciones: ['Vacunación', 'Desparasitación', 'Tratamiento aplicado', 'Alta médica (fin de tratamiento)'],
    detalle: 'Producto y dosis',
    detalleObligatorio: false,
    detalleEjemplo: 'Ej. Ivermectina 1%, 5 ml',
    arete: false,
    baja: false,
    notas: 'Ej. Refuerzo programado en 21 días...',
  ),
  'Muerte': (
    acciones: ['Baja por muerte'],
    detalle: 'Causa de la muerte',
    detalleObligatorio: true,
    detalleEjemplo: 'Ej. Complicación en el parto',
    arete: false,
    baja: true,
    notas: 'Ej. Se encontró en el potrero 2, se notificó al veterinario...',
  ),
  'Robo o extravío': (
    acciones: ['Baja por robo o extravío'],
    detalle: 'Último lugar donde se vio',
    detalleObligatorio: false,
    detalleEjemplo: 'Ej. Potrero 3, cerca del arroyo',
    arete: false,
    baja: true,
    notas: 'Ej. Denuncia presentada ante la autoridad local...',
  ),
};

/// Incidencias que sacan al animal del ganado (como la venta o el traslado).
final tiposBajaIncidencia = {
  for (final MapEntry(:key, :value) in reglasIncidencia.entries)
    if (value.baja) key,
};

class Incidencia {
  const Incidencia({
    required this.tipo,
    required this.fecha,
    required this.animal,
    required this.accion,
    this.areteNuevo,
    this.notas = '',
    this.detalle = '',
  });

  final String tipo;
  final DateTime fecha;
  final Animal animal;
  final String accion;
  final String? areteNuevo;
  final String notas;
  final String detalle; // dato propio del tipo: zona afectada, diagnóstico, producto, causa…

  bool get atendida => !accion.contains('pendiente');
}

final incidencias = ValueNotifier<List<Incidencia>>([]);

/// Guarda la incidencia y aplica su efecto en el animal (el código GV no cambia):
/// arete nuevo, entrada o salida de tratamiento. Las bajas no tocan al animal: se deducen de la incidencia.
void registrarIncidencia(Incidencia i) {
  incidencias.value = [...incidencias.value, i];
  final actual = animales.value.where((a) => a.codigo == i.animal.codigo).firstOrNull;
  if (actual == null) return;
  final tratamiento = switch (i.accion) {
    'Tratamiento veterinario' => true,
    'Alta médica (fin de tratamiento)' => false,
    _ => null,
  };
  if (i.areteNuevo != null || tratamiento != null) {
    actualizarAnimal(actual.copyWith(arete: i.areteNuevo, enTratamiento: tratamiento));
  }
}

// Formulario de incidencia: se abre desde "Reportar incidencia" en Inicio y en la Ficha de Animal.
// Los campos cambian según el tipo (ver [reglasIncidencia]).
class NuevaIncidenciaPage extends StatefulWidget {
  const NuevaIncidenciaPage({super.key, this.animal});

  final Animal? animal;

  @override
  State<NuevaIncidenciaPage> createState() => _NuevaIncidenciaPageState();
}

class _NuevaIncidenciaPageState extends State<NuevaIncidenciaPage> {
  final _arete = TextEditingController();
  final _notas = TextEditingController();
  final _detalle = TextEditingController();
  String _tipo = reglasIncidencia.keys.first;
  late String _accion = _regla.acciones.first;
  DateTime _fecha = DateTime.now();
  // La ficha pasa su propia instancia; se busca en la lista para que el selector la reconozca.
  late Animal? _animal = _activos.where((a) => a.codigo == widget.animal?.codigo).firstOrNull;

  ReglaIncidencia get _regla => reglasIncidencia[_tipo]!;

  /// Solo el ganado actual: a un animal que ya salió no se le registran incidencias.
  List<Animal> get _activos => animales.value.where(enHato).toList();

  @override
  void dispose() {
    _arete.dispose();
    _notas.dispose();
    _detalle.dispose();
    super.dispose();
  }

  void _cambiarTipo(String t) => setState(() {
        _tipo = t;
        _accion = _regla.acciones.first;
      });

  void _error(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year - 30),
      lastDate: hoy,
    );
    if (f != null) setState(() => _fecha = f);
  }

  void _guardar() {
    final r = _regla;
    final animal = _animal;
    if (animal == null) return _error('Selecciona el animal afectado');
    final detalle = r.detalle == null ? '' : _detalle.text.trim();
    if (r.detalleObligatorio && detalle.isEmpty) return _error('Indica ${r.detalle!.toLowerCase()}');
    final arete = _arete.text.trim();
    registrarIncidencia(Incidencia(
      tipo: _tipo,
      fecha: _fecha,
      animal: animal,
      accion: _accion,
      areteNuevo: r.arete && arete.isNotEmpty ? arete : null,
      notas: _notas.text.trim(),
      detalle: detalle,
    ));
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // que no quede un aviso de error ya corregido
    Navigator.of(context).pop();
  }

  Widget _dropdown<T>(T? value, List<T> items, String Function(T) texto, ValueChanged<T?> onChanged,
          {Widget? hint, IconData flecha = Icons.keyboard_arrow_down, String Function(T)? especie}) =>
      DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: hint,
          icon: Icon(flecha, color: AppColors.text),
          style: TextStyle(fontSize: 14, color: AppColors.text),
          items: [
            for (final x in items)
              DropdownMenuItem(
                value: x,
                child: especie == null
                    ? Text(texto(x), overflow: TextOverflow.ellipsis)
                    : conIconoEspecie(especie(x), Text(texto(x), overflow: TextOverflow.ellipsis), size: 20),
              ),
          ],
          onChanged: onChanged,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = _regla;
    final a = _animal;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Nueva incidencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
          if (a != null)
            FormTarjeta(
              child: Row(
                children: [
                  FotoAnimal(a.foto, size: 46, radius: 8, iconSize: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(a.codigo,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
                            const SizedBox(width: 6),
                            if (a.nombre.isNotEmpty)
                              Flexible(child: formChip(a.nombre, AppColors.primary, AppColors.primarySoft)),
                          ],
                        ),
                        conIconoEspecie(
                          a.especie,
                          Text('${a.sexo} • ${a.edad} • Arete actual: ${a.arete ?? 'en trámite'}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                  a.enTratamiento
                      ? formChip('En tratamiento', AppColors.danger, AppColors.dangerSoft)
                      : formChip('● Activo', AppColors.primary, AppColors.primarySoft),
                ],
              ),
            ),
          FormTarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormEtiqueta('Tipo de incidencia', requerido: true),
                FormCaja(
                  icon: tiposIncidencia[_tipo],
                  child: _dropdown(_tipo, reglasIncidencia.keys.toList(), (t) => t, (t) => _cambiarTipo(t!)),
                ),
                if (r.baja) ...[
                  const SizedBox(height: 8),
                  formChip('Baja del ganado', Colors.white, AppColors.danger, icon: Icons.logout),
                ],
                const SizedBox(height: 16),
                const FormEtiqueta('Fecha del suceso', requerido: true),
                FormCaja(
                  icon: Icons.calendar_month_outlined,
                  onTap: _elegirFecha,
                  child: Row(
                    children: [
                      Expanded(child: Text(fechaCorta(_fecha), style: const TextStyle(fontSize: 14))),
                      Icon(Icons.event, size: 18, color: AppColors.text),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const FormEtiqueta('Animal afectado', requerido: true),
                FormCaja(
                  icon: Icons.tag,
                  child: _dropdown(
                    a,
                    _activos,
                    (x) => '${x.codigo} - ${x.nombre} (${x.sexo}, ${x.raza})',
                    (x) => setState(() => _animal = x),
                    hint: const Text('Selecciona un animal', style: TextStyle(fontSize: 14)),
                    flecha: Icons.unfold_more,
                    especie: (x) => x.especie,
                  ),
                ),
                // Las bajas tienen una sola acción posible: no hace falta elegirla.
                if (r.acciones.length > 1) ...[
                  const SizedBox(height: 16),
                  const FormEtiqueta('Acción tomada', requerido: true),
                  FormCaja(
                    icon: Icons.build_circle_outlined,
                    child: _dropdown(_accion, r.acciones, (x) => x, (x) => setState(() => _accion = x!)),
                  ),
                ],
                if (r.detalle != null) ...[
                  const SizedBox(height: 16),
                  FormEtiqueta(r.detalle!, requerido: r.detalleObligatorio),
                  FormCampo(controller: _detalle, hint: r.detalleEjemplo, icon: Icons.notes),
                ],
              ],
            ),
          ),
          if (r.arete && _accion.startsWith('Cambio'))
            FormTarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sell_outlined, size: 16, color: AppColors.text),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text.rich(TextSpan(
                          text: 'Nuevo arete oficial ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                          children: [
                            TextSpan(
                                text: '(opcional)',
                                style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.textMuted)),
                          ],
                        )),
                      ),
                      Text('Reemplazo físico',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: FormCampo(controller: _arete, hint: 'Ej. 2890-B')),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => avisoProximamente(context, 'El escáner de aretes'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primarySoft,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text('Escanear', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Asigna el número oficial plastificado o metálico. No afecta el identificador primario del animal.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          FormTarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormEtiqueta('Descripción detallada', extra: 'Notas de campo', extraColor: AppColors.textMuted),
                FormCampo(controller: _notas, hint: r.notas, lineas: 4),
              ],
            ),
          ),
          if (a != null) _Efecto(_tipo, _accion, a),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: r.baja ? AppColors.danger : AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.save_outlined),
              label: Text(r.baja ? 'Guardar y dar de baja' : 'Guardar Incidencia',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar y volver al expediente',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

/// Explica qué le pasará al animal al guardar (baja, tratamiento o arete), si algo cambia.
class _Efecto extends StatelessWidget {
  const _Efecto(this.tipo, this.accion, this.a);

  final String tipo;
  final String accion;
  final Animal a;

  @override
  Widget build(BuildContext context) {
    final quien = '${a.codigo}${a.nombre.isEmpty ? '' : ' (${a.nombre})'}';
    final baja = reglasIncidencia[tipo]!.baja;
    final texto = baja
        ? '$quien saldrá del ganado. Su ficha e historial se conservan, pero ya no se cuenta en el hato.'
        : switch (accion) {
            'Tratamiento veterinario' => '$quien quedará marcado como "En tratamiento".',
            'Alta médica (fin de tratamiento)' => '$quien dejará de estar "En tratamiento".',
            'Cambio y reposición de arete' => 'El arete nuevo se asignará a $quien; su código GV no cambia.',
            _ => null,
          };
    if (texto == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: baja ? AppColors.dangerSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(baja ? Icons.logout : Icons.info_outline, size: 18, color: baja ? AppColors.danger : AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('Al guardar, $texto', style: TextStyle(fontSize: 12, color: AppColors.text))),
        ],
      ),
    );
  }
}
