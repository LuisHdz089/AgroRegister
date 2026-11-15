import 'package:flutter/material.dart';

import '../foto.dart';
import '../iconos_especie.dart';
import '../theme.dart';
import 'ficha_animal_page.dart';
import 'movimientos_page.dart';
import 'nueva_incidencia_page.dart';
import 'nuevo_animal_page.dart';

/// Especies del rancho: nombre, nombre en plural y razas comunes (la primera es la sugerida).
/// Su ícono es [IconoEspecie].
const especies = {
  'Bovino': (
    'Bovino',
    'Bovinos',
    [
      'Holstein (Lechera)',
      'Jersey (Lechera)',
      'Pardo Suizo (Doble propósito)',
      'Angus Negro (Carne)',
      'Brahman (Carne)',
      'Charolais (Carne)',
      'Simmental (Doble propósito)',
      'Mestizo',
    ]
  ),
  'Equino': ('Caballo', 'Caballos', ['Cuarto de Milla', 'Pura Sangre', 'Árabe', 'Appaloosa', 'Criollo', 'Mestizo']),
  'Ovino': ('Borrego', 'Borregos', ['Pelibuey', 'Dorper', 'Katahdin', 'Suffolk', 'Merino', 'Mestizo']),
  'Porcino': ('Cerdo', 'Cerdos', ['Yorkshire', 'Landrace', 'Duroc', 'Hampshire', 'Pietrain', 'Mestizo']),
};

class Animal {
  const Animal(this.codigo, this.nombre, this.sexo, this.edad, this.raza, this.arete, this.ubicacion,
      {required this.color,
      this.nota,
      this.enTratamiento = false,
      this.foto,
      this.especie = 'Bovino',
      this.documento});

  final String codigo;
  final String nombre;
  final String sexo; // 'Hembra' | 'Macho'
  final String edad;
  final String raza;
  final String? arete; // null = en trámite
  final String ubicacion;
  final String color;
  final String? nota; // ej. "Primer parto"
  final bool enTratamiento;
  final String? foto; // ruta local de la imagen
  final String especie; // clave de [especies]
  final String? documento; // ruta de la copia del documento adjunto (certificado, factura, guía…)

  /// Nombre de la especie para mostrar ("Caballo"…).
  String get nombreEspecie => especies[especie]?.$1 ?? especie;

  Animal copyWith({String? arete, String? foto, bool? enTratamiento}) => Animal(
      codigo, nombre, sexo, edad, raza, arete ?? this.arete, ubicacion,
      color: color,
      nota: nota,
      enTratamiento: enTratamiento ?? this.enTratamiento,
      foto: foto ?? this.foto,
      especie: especie,
      documento: documento);
}

/// Reemplaza en la lista compartida el animal con el mismo código.
void actualizarAnimal(Animal nuevo) =>
    animales.value = [for (final a in animales.value) a.codigo == nuevo.codigo ? nuevo : a];

// Datos de ejemplo para la primera vez que se abre la app; después se cargan los guardados (datos.dart).
const animalesEjemplo = [
  Animal('GV-001', 'Luna', 'Hembra', '3 años', 'Holstein', '2584', 'San José',
      color: 'Negro / Blanco', nota: 'Primer parto'),
  Animal('GV-002', 'Rayo', 'Macho', '2 años', 'Pardo Suizo', '2585', 'Potrero 3', color: 'Pardo'),
  Animal('GV-003', 'Estrella', 'Hembra', '1 año', 'Jersey', '2590', 'Corral A', color: 'Café claro'),
  Animal('GV-004', 'Torito', 'Macho', '6 meses', 'Mestizo', null, 'Nacimiento', color: 'Café / Blanco'),
  Animal('GV-005', 'Mora', 'Hembra', '4 años', 'Angus Negro', '2572', 'Enfermería',
      color: 'Negro', enTratamiento: true),
];

final animales = ValueNotifier<List<Animal>>(animalesEjemplo);

/// Filtro que otra pantalla (las tarjetas de Inicio) pide aplicar en Animales; la pestaña lo aplica y lo limpia.
final pedidoFiltroAnimales = ValueNotifier<({String? sexo, bool tratamiento})?>(null);

class AnimalesPage extends StatefulWidget {
  const AnimalesPage({super.key});

  @override
  State<AnimalesPage> createState() => _AnimalesPageState();
}

class _AnimalesPageState extends State<AnimalesPage> {
  String? _sexo; // null = todos
  String? _especie; // null = todas
  bool _tratamiento = false; // solo los que están en tratamiento
  final _buscador = TextEditingController();
  String _busqueda = '';

  void _refrescar() => setState(() {});

  /// Aplica el filtro pedido desde Inicio partiendo de cero (sin especie ni búsqueda previas).
  void _aplicarPedido() {
    final p = pedidoFiltroAnimales.value;
    if (p == null) return;
    setState(() {
      _sexo = p.sexo;
      _tratamiento = p.tratamiento;
      _especie = null;
      _busqueda = '';
      _buscador.clear();
    });
    pedidoFiltroAnimales.value = null;
  }

  @override
  void initState() {
    super.initState();
    animales.addListener(_refrescar);
    movimientos.addListener(_refrescar); // una venta, traslado, muerte o robo cambia el estado de la tarjeta
    incidencias.addListener(_refrescar);
    pedidoFiltroAnimales.addListener(_aplicarPedido);
  }

  @override
  void dispose() {
    animales.removeListener(_refrescar);
    movimientos.removeListener(_refrescar);
    incidencias.removeListener(_refrescar);
    pedidoFiltroAnimales.removeListener(_aplicarPedido);
    _buscador.dispose();
    super.dispose();
  }

  /// Los que siguen en el ganado primero; los vendidos o trasladados al final (atenuados).
  List<Animal> get _filtrados {
    final q = _busqueda.trim().toLowerCase();
    final lista = animales.value.where((a) {
      if (_especie != null && a.especie != _especie) return false;
      if (_sexo != null && a.sexo != _sexo) return false;
      if (_tratamiento && (!a.enTratamiento || !enHato(a))) return false;
      if (q.isEmpty) return true;
      return a.codigo.toLowerCase().contains(q) ||
          a.nombre.toLowerCase().contains(q) ||
          (a.arete ?? '').contains(q);
    });
    return [...lista.where(enHato), ...lista.where((a) => !enHato(a))];
  }

  @override
  Widget build(BuildContext context) {
    // Los conteos son del ganado actual (sin vendidos ni trasladados); los de sexo, de la especie elegida.
    final hato = animales.value.where(enHato).toList();
    final deEspecie = hato.where((a) => _especie == null || a.especie == _especie).toList();
    final hembras = deEspecie.where((a) => a.sexo == 'Hembra').length;
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
                  '${hato.length}',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text, height: 1),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('animales en rancho', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
                controller: _buscador,
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: InputDecoration(
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
                  _Filtro(Icons.pets, 'Todas las especies', _especie == null, () => setState(() => _especie = null)),
                  for (final MapEntry(key: clave, value: (_, plural, _)) in especies.entries)
                    _Filtro(null, '$plural (${hato.where((a) => a.especie == clave).length})',
                        _especie == clave, () => setState(() => _especie = clave),
                        especie: clave),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Filtro(Icons.grid_view_rounded, 'Todos (${deEspecie.length})', _sexo == null,
                      () => setState(() => _sexo = null)),
                  _Filtro(Icons.female, 'Hembras ($hembras)', _sexo == 'Hembra',
                      () => setState(() => _sexo = 'Hembra')),
                  _Filtro(Icons.male, 'Machos (${deEspecie.length - hembras})', _sexo == 'Macho',
                      () => setState(() => _sexo = 'Macho')),
                  _Filtro(Icons.medical_services_outlined,
                      'En tratamiento (${deEspecie.where((a) => a.enTratamiento).length})', _tratamiento,
                      () => setState(() => _tratamiento = !_tratamiento)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (lista.isEmpty)
              Padding(
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
            heroTag: 'fab-animales',
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NuevoAnimalPage())),
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
  const _Filtro(this.icon, this.label, this.selected, this.onTap, {this.especie});

  final IconData? icon;
  final String? especie; // filtro de especie: muestra su ícono en lugar de [icon]
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
                especie != null ? IconoEspecie(especie!, size: 18, color: color) : Icon(icon, size: 16, color: color),
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
    final salida = etiquetaSalida(a); // "Vendido", "Muerto"…: ya no está en el ganado
    final estadoColor = salida != null
        ? AppColors.textMuted
        : (a.enTratamiento ? AppColors.danger : AppColors.primary);
    final estadoTexto = salida ?? (a.enTratamiento ? 'En tratamiento' : 'Activo');
    final estadoFondo = salida != null
        ? AppColors.border
        : (a.enTratamiento ? AppColors.dangerSoft : AppColors.primarySoft);
    final muted = TextStyle(fontSize: 12, color: AppColors.textMuted);
    final fuerte = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text);

    // Tarjeta deshabilitada (atenuada) si el animal ya salió; al tocarla, la ficha explica por qué.
    return Opacity(opacity: salida == null ? 1 : 0.5, child: _tarjeta(context, estadoColor, estadoTexto, estadoFondo, muted, fuerte));
  }

  Widget _tarjeta(BuildContext context, Color estadoColor, String estadoTexto, Color estadoFondo, TextStyle muted,
      TextStyle fuerte) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FichaAnimalPage(a))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    FotoAnimal(a.foto),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: estadoColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
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
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(a.nombre,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, color: AppColors.text)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: estadoFondo,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              estadoTexto,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: estadoColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text.rich(TextSpan(children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: IconoEspecie(a.especie, size: 16, semanticLabel: a.nombreEspecie),
                          ),
                        ),
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
                Icon(Icons.chevron_right, color: AppColors.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
