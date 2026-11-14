import 'package:flutter/material.dart';

import '../datos.dart';
import '../foto.dart';
import '../iconos_especie.dart';
import '../theme.dart';
import 'animales_page.dart';
import 'movimientos_page.dart';
import 'nuevo_animal_page.dart';

/// Qué pide y qué hace cada tipo de movimiento.
/// [salida]: el animal deja de contar en el ganado. [alta]: se registra un animal nuevo.
/// [lugar]/[monto]: etiqueta del campo, o null si ese tipo no lo usa.
typedef ReglaMovimiento = ({
  bool salida,
  bool alta,
  String etiqueta,
  String? lugar,
  bool lugarObligatorio,
  String? monto,
  bool guia,
  String notas,
});

const Map<String, ReglaMovimiento> reglasMovimiento = {
  'Venta': (
    salida: true,
    alta: false,
    etiqueta: 'Salida por venta',
    lugar: 'Comprador o destino',
    lugarObligatorio: false,
    monto: 'Precio de venta (\$)',
    guia: true,
    notas: 'Ej. Venta de vaca al rancho Los Pinos...',
  ),
  'Compra': (
    salida: false,
    alta: true,
    etiqueta: 'Alta por compra',
    lugar: 'Proveedor u origen',
    lugarObligatorio: false,
    monto: 'Precio de compra (\$)',
    guia: true,
    notas: 'Ej. Compra en subasta ganadera regional...',
  ),
  'Traslado': (
    salida: true,
    alta: false,
    etiqueta: 'Salida por traslado',
    lugar: 'Destino del traslado',
    lugarObligatorio: true,
    monto: null,
    guia: true,
    notas: 'Ej. Se envía al rancho El Roble para engorda...',
  ),
  'Nacimiento': (
    salida: false,
    alta: true,
    etiqueta: 'Alta por nacimiento',
    lugar: null,
    lugarObligatorio: false,
    monto: null,
    guia: false,
    notas: 'Ej. Parto sin complicaciones en corral 2...',
  ),
};

// Formulario de movimiento: se abre desde Inicio, la Ficha de Animal y la pestaña Movimientos.
// Los campos cambian según el tipo (ver [reglasMovimiento]).
class NuevoMovimientoPage extends StatefulWidget {
  const NuevoMovimientoPage({super.key, this.animal});

  final Animal? animal; // preseleccionado al venir de la ficha

  @override
  State<NuevoMovimientoPage> createState() => _NuevoMovimientoPageState();
}

class _NuevoMovimientoPageState extends State<NuevoMovimientoPage> {
  final _notas = TextEditingController();
  final _lugar = TextEditingController();
  final _monto = TextEditingController();
  final _guia = TextEditingController();
  String _tipo = reglasMovimiento.keys.first;
  DateTime _fecha = DateTime.now();
  String? _documento; // ruta de la foto de la guía
  // La ficha pasa su propia instancia; se busca en la lista para que el selector la reconozca.
  late Animal? _animal = _activos.where((a) => a.codigo == widget.animal?.codigo).firstOrNull;
  Animal? _nuevo; // alta por compra o nacimiento: se guarda junto con el movimiento
  Animal? _madre; // solo nacimiento (opcional)

  late final String _folio = 'MOV-${(movimientos.value.length + 1).toString().padLeft(4, '0')}';

  ReglaMovimiento get _regla => reglasMovimiento[_tipo]!;

  /// Solo los animales que siguen en el ganado se pueden vender, trasladar o elegir como madre.
  List<Animal> get _activos => animales.value.where(enHato).toList();

  @override
  void dispose() {
    for (final c in [_notas, _lugar, _monto, _guia]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _esHoy {
    final h = DateTime.now();
    return _fecha.year == h.year && _fecha.month == h.month && _fecha.day == h.day;
  }

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

  Future<void> _capturarNuevo() async {
    final a = await Navigator.of(context).push<Animal>(MaterialPageRoute(
      builder: (_) => NuevoAnimalPage(
        editar: _nuevo,
        soloDevolver: true,
        nacimiento: _tipo == 'Nacimiento' ? _fecha : null,
      ),
    ));
    if (a != null) setState(() => _nuevo = a);
  }

  void _guardar() {
    final r = _regla;
    final Animal animal;
    if (r.alta) {
      final n = _nuevo;
      if (n == null) {
        return _error(_tipo == 'Nacimiento' ? 'Captura los datos de la cría' : 'Captura los datos del animal comprado');
      }
      animal = n;
    } else {
      final a = _animal;
      if (a == null) return _error('Selecciona un animal');
      if (!enHato(a)) return _error('${a.codigo} ya no forma parte del ganado');
      animal = a;
    }
    final lugar = _lugar.text.trim();
    if (r.lugarObligatorio && lugar.isEmpty) return _error('Indica el ${r.lugar!.toLowerCase()}');
    double? monto;
    if (r.monto != null) {
      final txt = _monto.text.trim().replaceAll(',', '');
      monto = txt.isEmpty ? null : double.tryParse(txt);
      if (txt.isNotEmpty && (monto == null || monto < 0)) return _error('Monto no válido');
    }
    final madre = _madre;

    if (r.alta) animales.value = [...animales.value, animal];
    movimientos.value = [
      ...movimientos.value,
      Movimiento(
        folio: _folio,
        tipo: _tipo,
        fecha: _fecha,
        animal: animal,
        notas: _notas.text.trim(),
        origenDestino: r.lugar != null
            ? lugar
            : (madre == null ? '' : 'Madre: ${madre.codigo}${madre.nombre.isEmpty ? '' : ' ${madre.nombre}'}'),
        monto: monto,
        guia: r.guia ? _guia.text.trim() : '',
        documento: r.guia ? _documento : null,
      ),
    ];
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // que no quede un aviso de error ya corregido
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = _regla;
    final a = r.alta ? _nuevo : _animal;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Nuevo Registro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: const [
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
          FormTarjeta(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.swap_horiz, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Movimiento de Hato',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                      Text('${rancho.value.nombre} • Registro #$_folio',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                formChip('Borrador', AppColors.textMuted, AppColors.background),
              ],
            ),
          ),
          FormTarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormEtiqueta('Tipo de movimiento', requerido: true),
                FormCaja(
                  icon: tiposMovimiento[_tipo],
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _tipo,
                      isExpanded: true,
                      isDense: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.text),
                      style: const TextStyle(fontSize: 14, color: AppColors.text),
                      items: [for (final t in reglasMovimiento.keys) DropdownMenuItem(value: t, child: Text(t))],
                      onChanged: (t) => setState(() => _tipo = t!),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    r.salida
                        ? formChip(r.etiqueta, Colors.white, AppColors.danger, icon: Icons.logout)
                        : formChip(r.etiqueta, Colors.white, AppColors.primary, icon: Icons.add_circle_outline),
                    if (r.guia)
                      formChip('Guía sanitaria', AppColors.textMuted, AppColors.border,
                          icon: Icons.local_shipping_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                FormEtiqueta(_tipo == 'Nacimiento' ? 'Fecha de nacimiento' : 'Fecha de operación',
                    requerido: true, extra: _esHoy ? 'Hoy' : null),
                FormCaja(
                  icon: Icons.calendar_today_outlined,
                  onTap: _elegirFecha,
                  child: Row(
                    children: [
                      Expanded(child: Text(fechaCorta(_fecha), style: const TextStyle(fontSize: 14))),
                      const Icon(Icons.event, size: 18, color: AppColors.text),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (r.alta) ...[
                  FormEtiqueta(_tipo == 'Nacimiento' ? 'Cría' : 'Animal comprado',
                      requerido: true, extra: a == null ? null : 'Alta: ${a.codigo}', extraColor: AppColors.primary),
                  if (a == null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _capturarNuevo,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primarySoft,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(_tipo == 'Nacimiento' ? 'Capturar datos de la cría' : 'Capturar datos del animal',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                ] else ...[
                  FormEtiqueta('Animal',
                      requerido: true, extra: a == null ? null : '1 seleccionado', extraColor: AppColors.primary),
                  FormCaja(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Animal>(
                        value: a,
                        isExpanded: true,
                        isDense: true,
                        hint: const Text('Selecciona un animal del ganado', style: TextStyle(fontSize: 14)),
                        icon: const Icon(Icons.unfold_more, color: AppColors.text),
                        style: const TextStyle(fontSize: 14, color: AppColors.text),
                        items: [
                          for (final x in _activos)
                            DropdownMenuItem(
                              value: x,
                              child: conIconoEspecie(
                                x.especie,
                                Text('${x.codigo} — ${x.nombre} (${x.sexo}, ${x.raza})',
                                    overflow: TextOverflow.ellipsis),
                                size: 20,
                              ),
                            ),
                        ],
                        onChanged: (x) => setState(() => _animal = x),
                      ),
                    ),
                  ),
                ],
                if (a != null) ...[
                  const SizedBox(height: 10),
                  _VistaAnimal(a, alCambiar: r.alta ? _capturarNuevo : null),
                ],
                if (_tipo == 'Nacimiento') ...[
                  const SizedBox(height: 16),
                  const FormEtiqueta('Madre'),
                  FormCaja(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Animal?>(
                        value: _madre,
                        isExpanded: true,
                        isDense: true,
                        hint: const Text('Sin especificar', style: TextStyle(fontSize: 14)),
                        icon: const Icon(Icons.unfold_more, color: AppColors.text),
                        style: const TextStyle(fontSize: 14, color: AppColors.text),
                        items: [
                          const DropdownMenuItem<Animal?>(value: null, child: Text('Sin especificar')),
                          for (final x in _activos.where((x) => x.sexo == 'Hembra'))
                            DropdownMenuItem<Animal?>(
                              value: x,
                              child: conIconoEspecie(x.especie,
                                  Text('${x.codigo} — ${x.nombre} (${x.raza})', overflow: TextOverflow.ellipsis),
                                  size: 20),
                            ),
                        ],
                        onChanged: (x) => setState(() => _madre = x),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const FormEtiqueta('Descripción y notas'),
                FormCampo(controller: _notas, hint: r.notas, lineas: 3),
              ],
            ),
          ),
          if (r.lugar != null || r.monto != null || r.guia)
            FormTarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, size: 20, color: AppColors.text),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Datos de la operación',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                      ),
                    ],
                  ),
                  if (r.lugar != null) ...[
                    const SizedBox(height: 12),
                    FormEtiqueta(r.lugar!, requerido: r.lugarObligatorio),
                    FormCampo(
                      controller: _lugar,
                      hint: _tipo == 'Traslado' ? 'Ej. Rancho El Roble, Potrero 5' : 'Ej. Rancho Los Pinos',
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                  if (r.monto != null || r.guia) ...[
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.monto != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FormEtiqueta(r.monto!),
                                FormCampo(
                                  controller: _monto,
                                  hint: '0.00',
                                  prefijo: '\$ ',
                                  teclado: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ],
                            ),
                          ),
                        if (r.monto != null && r.guia) const SizedBox(width: 10),
                        if (r.guia)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FormEtiqueta('No. Guía / Folio'),
                                FormCampo(controller: _guia, hint: 'G-83921', icon: Icons.receipt_long_outlined),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (r.guia) ...[
                    const SizedBox(height: 14),
                    _FotoGuia(_documento, (ruta) => setState(() => _documento = ruta)),
                  ],
                ],
              ),
            ),
          if (a != null) _Aviso(r, a),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Guardar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.border,
                foregroundColor: AppColors.text,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta del animal elegido (o del que se va a dar de alta, con botón para cambiar sus datos).
class _VistaAnimal extends StatelessWidget {
  const _VistaAnimal(this.a, {this.alCambiar});

  final Animal a;
  final VoidCallback? alCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          FotoAnimal(a.foto, size: 42, radius: 8, iconSize: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(
                  text: a.codigo,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                        text: ' • ${a.nombre}',
                        style: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textMuted)),
                  ],
                )),
                conIconoEspecie(
                  a.especie,
                  Text('${a.raza} • ${a.sexo} ${a.edad} • Arete ${a.arete ?? 'en trámite'}',
                      overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  size: 14,
                ),
              ],
            ),
          ),
          if (alCambiar != null)
            TextButton(onPressed: alCambiar, child: const Text('Cambiar', style: TextStyle(fontWeight: FontWeight.w700)))
          else if (a.enTratamiento)
            formChip('En tratamiento', AppColors.danger, AppColors.dangerSoft)
          else
            formChip('Activo', AppColors.primary, AppColors.primarySoft),
        ],
      ),
    );
  }
}

class _FotoGuia extends StatelessWidget {
  const _FotoGuia(this.ruta, this.alElegir);

  final String? ruta;
  final ValueChanged<String> alElegir;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          ruta == null
              ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.photo_camera_outlined, size: 20, color: AppColors.text),
                )
              : FotoAnimal(ruta, size: 36, radius: 8, iconSize: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Foto de documento o guía',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text(ruta == null ? 'Opcional para respaldo sanitario' : 'Documento adjunto',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          FilledButton(
            onPressed: () async {
              final r = await elegirImagen(context);
              if (r != null) alElegir(r);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(ruta == null ? 'Adjuntar' : 'Cambiar', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Explica qué le pasará al ganado al guardar.
class _Aviso extends StatelessWidget {
  const _Aviso(this.r, this.a);

  final ReglaMovimiento r;
  final Animal a;

  @override
  Widget build(BuildContext context) {
    final quien = '${a.codigo}${a.nombre.isEmpty ? '' : ' (${a.nombre})'}';
    final (inicio, fin) = r.alta
        ? ('Al guardar, se dará de alta ', ' en el ganado.')
        : (
            'Al guardar, ',
            ' dejará de contarse en el ganado. Su ficha e historial se conservan como '
                '${r.etiqueta.contains('venta') ? 'vendido' : 'trasladado'}.'
          );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: r.salida ? AppColors.dangerSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(r.salida ? Icons.logout : Icons.verified_user_outlined,
              size: 18, color: r.salida ? AppColors.danger : AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.text),
                children: [
                  TextSpan(text: inicio),
                  TextSpan(text: quien, style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: fin),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget formChip(String text, Color fg, Color bg, {IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ),
        ],
      ),
    );

class FormTarjeta extends StatelessWidget {
  const FormTarjeta({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
        child: child,
      );
}

class FormEtiqueta extends StatelessWidget {
  const FormEtiqueta(this.text, {super.key, this.requerido = false, this.extra, this.extraColor = AppColors.danger});

  final String text;
  final bool requerido;
  final String? extra;
  final Color extraColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(TextSpan(
                text: text,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                children: [if (requerido) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger))],
              )),
            ),
            if (extra != null)
              Text(extra!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: extraColor)),
          ],
        ),
      );
}

const _bordeCampo = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: AppColors.border),
);

// Caja blanca con borde, igual que los selectores del diseño.
class FormCaja extends StatelessWidget {
  const FormCaja({super.key, required this.child, this.icon, this.onTap});

  final Widget child;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: _bordeCampo,
        child: InkWell(
          customBorder: _bordeCampo,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: AppColors.text), const SizedBox(width: 10)],
                Expanded(child: child),
              ],
            ),
          ),
        ),
      );
}

class FormCampo extends StatelessWidget {
  const FormCampo({super.key, required this.controller, required this.hint, this.icon, this.prefijo, this.teclado, this.lineas = 1});

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final String? prefijo;
  final TextInputType? teclado;
  final int lineas;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: teclado,
        minLines: lineas,
        maxLines: lineas,
        style: const TextStyle(fontSize: 14, color: AppColors.text),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surface,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          prefixIcon: icon == null ? null : Icon(icon, size: 18, color: AppColors.textMuted),
          prefixText: prefijo,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: _bordeCampo,
          enabledBorder: _bordeCampo,
          focusedBorder: _bordeCampo.copyWith(borderSide: const BorderSide(color: AppColors.primary)),
        ),
      );
}
