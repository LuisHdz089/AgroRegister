import 'dart:math';

import 'package:flutter/material.dart';

import '../datos.dart';
import '../foto.dart';
import '../iconos_especie.dart';
import '../theme.dart';
import 'animales_page.dart';

/// "2 años 9 m", "1 año", "6 meses" a partir de la fecha de nacimiento.
String edadDesde(DateTime nac, DateTime hoy) {
  var meses = (hoy.year - nac.year) * 12 + hoy.month - nac.month;
  if (hoy.day < nac.day) meses--;
  meses = max(meses, 0);
  final a = meses ~/ 12, m = meses % 12;
  if (a == 0) return m == 1 ? '1 mes' : '$m meses';
  final anios = a == 1 ? '1 año' : '$a años';
  return m == 0 ? anios : '$anios $m m';
}

// Formulario de alta: se abre desde "Agregar animal" en Inicio y en Animales.
// Con [editar] se reutiliza para modificar un animal existente (desde "Editar" en su ficha).
// Con [soloDevolver] no guarda nada: devuelve el animal al cerrarse (alta por compra o nacimiento,
// que se guarda junto con su movimiento).
class NuevoAnimalPage extends StatefulWidget {
  const NuevoAnimalPage({super.key, this.editar, this.soloDevolver = false, this.nacimiento});

  final Animal? editar;
  final bool soloDevolver;
  final DateTime? nacimiento; // fecha de nacimiento ya conocida (cría)

  @override
  State<NuevoAnimalPage> createState() => _NuevoAnimalPageState();
}

class _NuevoAnimalPageState extends State<NuevoAnimalPage> {
  late final Animal? _e = widget.editar;
  late final _nombre = TextEditingController(text: _e?.nombre);
  late final _color = TextEditingController(text: _e == null || _e.color == "—" ? "" : _e.color);
  late final _arete = TextEditingController(text: _e?.arete);
  final _fierro = TextEditingController(text: rancho.value.nombre);
  late String _sexo = _e?.sexo ?? "Hembra";
  late String _especie = _e?.especie ?? 'Bovino';
  late String _raza = _e == null ? _opcionesRaza.first : _opcionesRaza.firstWhere((r) => r.startsWith(_e.raza));

  /// Razas de la especie elegida; al editar, una raza que no está en la lista se agrega para no perderla.
  List<String> get _opcionesRaza {
    final razas = especies[_especie]!.$3;
    final propia = _e?.especie == _especie && !razas.any((r) => r.startsWith(_e!.raza)) ? _e!.raza : null;
    return [...razas, ?propia];
  }

  void _cambiarEspecie(String e) => setState(() {
        _especie = e;
        _raza = _opcionesRaza.first;
      });
  late DateTime? _nacimiento = widget.nacimiento;
  late String? _foto = _e?.foto;
  late String? _documento = _e?.documento;

  late final String _codigo = _e?.codigo ?? () {
    final ultimo = animales.value.map((a) => int.tryParse(a.codigo.substring(3)) ?? 0).fold(0, max);
    return 'GV-${(ultimo + 1).toString().padLeft(3, '0')}';
  }();

  @override
  void dispose() {
    for (final c in [_nombre, _color, _arete, _fierro]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _nacimiento ?? hoy,
      firstDate: DateTime(hoy.year - 30),
      lastDate: hoy,
    );
    if (f != null) setState(() => _nacimiento = f);
  }

  void _guardar() {
    if (_nacimiento == null && _e == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica la fecha de nacimiento o edad aproximada')),
      );
      return;
    }
    final arete = _arete.text.trim();
    final e = _e;
    final animal = Animal(
      _codigo,
      _nombre.text.trim(),
      _sexo,
      _nacimiento == null ? e!.edad : edadDesde(_nacimiento!, DateTime.now()),
      _raza.split(' (').first,
      arete.isEmpty ? null : arete,
      e?.ubicacion ?? 'Sin asignar',
      color: _color.text.trim().isEmpty ? '—' : _color.text.trim(),
      nota: e?.nota,
      enTratamiento: e?.enTratamiento ?? false,
      foto: _foto,
      especie: _especie,
      documento: _documento,
    );
    if (widget.soloDevolver) return Navigator.of(context).pop(animal);
    if (e == null) {
      animales.value = [...animales.value, animal];
    } else {
      actualizarAnimal(animal);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final n = _nacimiento;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.soloDevolver ? 'Datos del animal' : (_e == null ? "Nuevo Registro" : "Editar Registro"),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
          SizedBox(
            height: 170,
            child: Stack(
              children: [
                Positioned.fill(child: FotoAnimal(_foto, size: double.infinity, radius: 16, iconSize: 56)),
                const Positioned(
                  left: 10,
                  bottom: 12,
                  child: Row(
                    children: [
                      Icon(Icons.photo_camera, size: 14, color: AppColors.text),
                      SizedBox(width: 4),
                      Text('Foto frontal o perfil', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final ruta = await elegirImagen(context);
                        if (ruta != null) setState(() => _foto = ruta);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        child: Row(
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 16, color: AppColors.text),
                            SizedBox(width: 6),
                            Text('Cambiar foto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.fingerprint, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Código interno (Automático)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                            child: const Text('Invariable',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                        child: Text(_codigo,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.primary)),
                      ),
                      const SizedBox(height: 8),
                      const Text('Identificador único del rancho. Se conserva aunque el animal pierda su arete.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Seccion(
            label: const Text.rich(TextSpan(text: 'Especie ', children: [
              TextSpan(text: '*', style: TextStyle(color: AppColors.danger)),
            ])),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.95,
              children: [
                for (final MapEntry(key: clave, value: (nombre, _, _)) in especies.entries)
                  Material(
                    color: _especie == clave ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _cambiarEspecie(clave),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconoEspecie(clave, size: 34, color: _especie == clave ? Colors.white : AppColors.primary),
                          const SizedBox(height: 4),
                          Text(
                            nombre,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _especie == clave ? Colors.white : AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _Seccion(
            label: const Text.rich(TextSpan(text: 'Nombre o apodo ', children: [
              TextSpan(text: '(opcional)', style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.textMuted)),
            ])),
            child: _Campo(controller: _nombre, icon: Icons.edit_note, hint: 'Ej. Sol, La Pinta, Trueno'),
          ),
          _Seccion(
            label: const Text.rich(TextSpan(text: 'Sexo ', children: [
              TextSpan(text: '*', style: TextStyle(color: AppColors.danger)),
            ])),
            child: Row(
              children: [
                for (final (s, icon) in [('Hembra', Icons.female), ('Macho', Icons.male)]) ...[
                  if (s == 'Macho') const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: () => setState(() => _sexo = s),
                        style: FilledButton.styleFrom(
                          backgroundColor: _sexo == s ? AppColors.primary : AppColors.background,
                          foregroundColor: _sexo == s ? Colors.white : AppColors.text,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(icon, size: 18),
                        label: Text(s, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _Seccion(
            label: const Text('Fecha de nacimiento o edad aprox.'),
            trailing: n == null ? null : edadDesde(n, DateTime.now()),
            child: _Caja(
              onTap: _elegirFecha,
              icon: Icons.calendar_today_outlined,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      n == null
                          ? 'dd/mm/aaaa'
                          : '${n.day.toString().padLeft(2, '0')}/${n.month.toString().padLeft(2, '0')}/${n.year}',
                      style: TextStyle(fontSize: 14, color: n == null ? AppColors.textMuted : AppColors.text),
                    ),
                  ),
                  const Icon(Icons.event, size: 18, color: AppColors.text),
                ],
              ),
            ),
          ),
          _Seccion(
            label: const Text('Raza predominante'),
            child: _Caja(
              icon: Icons.pets,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _raza,
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.text),
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                  items: [for (final r in _opcionesRaza) DropdownMenuItem(value: r, child: Text(r))],
                  onChanged: (r) => setState(() => _raza = r!),
                ),
              ),
            ),
          ),
          _Seccion(
            label: const Text('Color y señas particulares'),
            child: _Campo(
                controller: _color, icon: Icons.palette_outlined, hint: 'Ej. Blanco con manchas negras, cuerno mocho'),
          ),
          _Seccion(
            label: const Text.rich(TextSpan(text: 'Documento ', children: [
              TextSpan(text: '(opcional)', style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.textMuted)),
            ])),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _documento == null ? 'Certificado, factura o guía (PDF, imagen o Word)' : nombreDocumento(_documento!),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _documento == null ? FontWeight.w400 : FontWeight.w600,
                        color: _documento == null ? AppColors.textMuted : AppColors.text,
                      ),
                    ),
                  ),
                  if (_documento != null)
                    IconButton(
                      tooltip: 'Quitar documento',
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      onPressed: () => setState(() => _documento = null),
                    ),
                  FilledButton(
                    onPressed: () async {
                      final ruta = await elegirDocumento(context);
                      if (ruta != null) setState(() => _documento = ruta);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(_documento == null ? 'Adjuntar' : 'Cambiar',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.verified_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text('Identificación oficial y rancho',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Datos para seguimiento sanitario y movilización ganadera.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          _Seccion(
            label: const Text('Número de arete (SINIGA / Arete oficial o interno)'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Campo(controller: _arete, icon: Icons.label_outline, hint: 'Ej. Arete: 2592'),
                const SizedBox(height: 14),
                const Text('Fierro o marca del rancho',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 8),
                _Campo(controller: _fierro, icon: Icons.branding_watermark_outlined, hint: 'Marca registrada'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textMuted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'La aplicación no sustituye la identificación oficial obligatoria correspondiente a los organismos ganaderos locales.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(widget.soloDevolver ? 'Usar estos datos' : 'Guardar animal',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.label, this.trailing, required this.child});

  final Widget label;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                  child: label,
                ),
              ),
              if (trailing != null)
                Text(trailing!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// Caja gris con ícono a la izquierda, igual que los campos del diseño.
class _Caja extends StatelessWidget {
  const _Caja({required this.icon, required this.child, this.onTap});

  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({required this.controller, required this.icon, required this.hint});

  final TextEditingController controller;
  final IconData icon;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}
