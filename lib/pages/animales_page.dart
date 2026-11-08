import 'package:flutter/material.dart';

import '../theme.dart';

class Animal {
  const Animal(this.codigo, this.nombre, this.sexo, this.edad, this.raza, this.arete, this.ubicacion,
      {this.enTratamiento = false});

  final String codigo;
  final String nombre;
  final String sexo; // 'Hembra' | 'Macho'
  final String edad;
  final String raza;
  final String? arete; // null = en trámite
  final String ubicacion;
  final bool enTratamiento;
}

// shortcut: datos de ejemplo del diseño, reemplazar por la base de datos real.
const animales = [
  Animal('VG-001', 'Luna', 'Hembra', '3 años', 'Holstein', '2584', 'San José'),
  Animal('VG-002', 'Rayo', 'Macho', '2 años', 'Pardo Suizo', '2585', 'Potrero 3'),
  Animal('VG-003', 'Estrella', 'Hembra', '1 año', 'Jersey', '2590', 'Corral A'),
  Animal('VG-004', 'Torito', 'Macho', '6 meses', 'Mestizo', null, 'Nacimiento'),
  Animal('VG-005', 'Mora', 'Hembra', '4 años', 'Angus Negro', '2572', 'Enfermería', enTratamiento: true),
];

class AnimalesPage extends StatefulWidget {
  const AnimalesPage({super.key});

  @override
  State<AnimalesPage> createState() => _AnimalesPageState();
}

class _AnimalesPageState extends State<AnimalesPage> {
  String? _sexo; // null = todos
  String _busqueda = '';

  List<Animal> get _filtrados {
    final q = _busqueda.trim().toLowerCase();
    return animales.where((a) {
      if (_sexo != null && a.sexo != _sexo) return false;
      if (q.isEmpty) return true;
      return a.codigo.toLowerCase().contains(q) ||
          a.nombre.toLowerCase().contains(q) ||
          (a.arete ?? '').contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hembras = animales.where((a) => a.sexo == 'Hembra').length;
    final lista = _filtrados;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${animales.length}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text, height: 1),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('bovinos en rancho', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_outlined, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Modo Campo',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: cardShadow,
              ),
              child: TextField(
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar por código, nombre o arete...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.text),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Filtro(Icons.grid_view_rounded, 'Todos (${animales.length})', _sexo == null,
                      () => setState(() => _sexo = null)),
                  _Filtro(Icons.female, 'Hembras ($hembras)', _sexo == 'Hembra',
                      () => setState(() => _sexo = 'Hembra')),
                  _Filtro(Icons.male, 'Machos (${animales.length - hembras})', _sexo == 'Macho',
                      () => setState(() => _sexo = 'Macho')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sin resultados', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
              ),
            for (final a in lista) _AnimalCard(a),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () {}, // shortcut: sin formulario aún, conectar cuando exista la pantalla de alta.
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar animal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro(this.icon, this.label, this.selected, this.onTap);

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.text;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard(this.a);

  final Animal a;

  @override
  Widget build(BuildContext context) {
    final estadoColor = a.enTratamiento ? AppColors.danger : AppColors.primary;
    const muted = TextStyle(fontSize: 12, color: AppColors.textMuted);
    const fuerte = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // shortcut: sin detalle aún, conectar cuando exista la ficha del animal.
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // shortcut: ícono en lugar de la foto, usar Image cuando el animal tenga foto.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.pets, color: AppColors.primary),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: estadoColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(a.codigo,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(a.nombre,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, color: AppColors.text)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: a.enTratamiento ? AppColors.dangerSoft : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              a.enTratamiento ? 'En tratamiento' : 'Activo',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: estadoColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: a.sexo, style: fuerte),
                        TextSpan(text: ' • ${a.edad} • ${a.raza}', style: muted),
                      ])),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            a.arete == null ? Icons.warning_amber_rounded : Icons.sell_outlined,
                            size: 14,
                            color: a.arete == null ? AppColors.warning : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text('Arete: ${a.arete ?? 'En trámite'}',
                                overflow: TextOverflow.ellipsis, style: fuerte),
                          ),
                          Container(
                            width: 1,
                            height: 12,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: AppColors.border,
                          ),
                          Flexible(child: Text(a.ubicacion, overflow: TextOverflow.ellipsis, style: fuerte)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
