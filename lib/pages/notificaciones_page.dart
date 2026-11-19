import 'package:flutter/material.dart';

import '../datos.dart';
import '../foto.dart';
import '../notificaciones_sistema.dart';
import '../theme.dart';
import 'animales_page.dart';
import 'ficha_animal_page.dart';
import 'movimientos_page.dart';
import 'nueva_incidencia_page.dart';

/// Cada cuánto debe vacunarse un animal para no generar aviso.
const diasEntreVacunas = 180;

/// Nombre, ícono y explicación de cada tipo de aviso (las claves están en [tiposAviso]).
const descripcionAvisos = {
  'Vacunas': ('Vacunas', Icons.vaccines_outlined, 'Sin vacunación registrada en los últimos 6 meses'),
  'Aretado': ('Aretado', Icons.sell_outlined, 'Animales sin arete SINIIGA'),
  'Tratamientos': ('Tratamientos', Icons.medical_services_outlined, 'Animales en tratamiento por seguir'),
  'Pendientes': ('Incidencias pendientes', Icons.pending_actions, 'Incidencias en observación o en trámite'),
};

typedef Aviso = ({String tipo, Animal animal, String titulo, String detalle});

/// Avisos de campo del ganado actual (los animales vendidos, trasladados o muertos no generan avisos).
List<Aviso> avisosDe(List<Animal> animales, List<Incidencia> incs, DateTime hoy, Set<String> activos) {
  final hato = animales.where(enHato).toList();
  DateTime? ultimaVacuna(Animal a) => incs
      .where((i) => i.animal.codigo == a.codigo && i.accion == 'Vacunación')
      .map((i) => i.fecha)
      .fold<DateTime?>(null, (m, f) => m == null || f.isAfter(m) ? f : m);
  return [
    if (activos.contains('Pendientes'))
      for (final i in incs)
        if (!i.atendida && hato.any((a) => a.codigo == i.animal.codigo))
          (
            tipo: 'Pendientes',
            animal: i.animal,
            titulo: 'Incidencia pendiente: ${i.tipo}',
            detalle: '${fechaCorta(i.fecha)} • ${i.accion}',
          ),
    if (activos.contains('Tratamientos'))
      for (final a in hato.where((a) => a.enTratamiento))
        (tipo: 'Tratamientos', animal: a, titulo: 'En tratamiento', detalle: 'Da seguimiento o registra el alta médica'),
    if (activos.contains('Aretado'))
      for (final a in hato.where((a) => a.arete == null))
        (tipo: 'Aretado', animal: a, titulo: 'Sin arete SINIIGA', detalle: 'Registra su arete oficial'),
    if (activos.contains('Vacunas'))
      for (final a in hato)
        if (ultimaVacuna(a) case final v when v == null || hoy.difference(v).inDays > diasEntreVacunas)
          (
            tipo: 'Vacunas',
            animal: a,
            titulo: 'Vacuna pendiente',
            detalle: v == null ? 'Sin vacunas registradas' : 'Última vacuna: ${fechaCorta(v)}',
          ),
  ];
}

/// Avisos actuales con las preferencias guardadas (para la pantalla y el contador de la campana).
List<Aviso> avisosActuales() =>
    avisosDe(animales.value, incidencias.value, DateTime.now(), avisosActivos.value);

/// Identifica un aviso para saber si ya se vio o ya se notificó.
String claveAviso(Aviso a) => '${a.tipo}|${a.animal.codigo}|${a.titulo}';

/// Avisos que el usuario todavía no ha visto en esta pantalla (los que cuenta la campana).
List<Aviso> avisosSinLeer() => [
      for (final a in avisosActuales())
        if (!avisosLeidos.value.contains(claveAviso(a))) a,
    ];

/// Marca como vistos los avisos actuales. Solo guarda los que siguen vigentes: si un aviso se resuelve y
/// vuelve a aparecer después, cuenta como nuevo otra vez.
void marcarAvisosLeidos() => avisosLeidos.value = avisosActuales().map(claveAviso).toSet();

/// Todo lo que puede cambiar los avisos.
final cambiosDeAvisos = Listenable.merge([animales, movimientos, incidencias, avisosActivos, avisosLeidos]);

// Notificaciones de campo: se abre desde la campana del encabezado y desde el Perfil.
class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

/// Al abrir la pantalla los avisos quedan leídos (la campana se apaga), pero los que eran nuevos se
/// siguen marcando como "Nuevo" mientras la pantalla está abierta.
class _NotificacionesPageState extends State<NotificacionesPage> {
  late final Set<String> _nuevos;

  @override
  void initState() {
    super.initState();
    _nuevos = avisosSinLeer().map(claveAviso).toSet();
    // Fuera del build: el contador de la campana escucha este cambio y se redibuja.
    Future.microtask(marcarAvisosLeidos);
    quitarNotificaciones(); // ya se vieron aquí: se limpian también de la barra del teléfono
  }

  @override
  void dispose() {
    Future.microtask(marcarAvisosLeidos); // incluye los que aparecieron mientras la pantalla estaba abierta
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Notificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: cambiosDeAvisos,
        builder: (context, _) {
          final avisos = avisosActuales();
          final nuevos = avisos.where((a) => _nuevos.contains(claveAviso(a))).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qué avisarme',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                    for (final t in tiposAviso)
                      SwitchListTile(
                        value: avisosActivos.value.contains(t),
                        onChanged: (v) => avisosActivos.value = {
                          ...avisosActivos.value.where((x) => x != t),
                          if (v) t,
                        },
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        secondary: Icon(descripcionAvisos[t]!.$2, color: AppColors.primary),
                        title: Text(descripcionAvisos[t]!.$1,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(descripcionAvisos[t]!.$3, style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                child: Row(
                  children: [
                    Text(
                      avisos.isEmpty ? 'Todo al día' : '${avisos.length} ${avisos.length == 1 ? 'aviso' : 'avisos'}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                    if (nuevos > 0)
                      Text('  •  $nuevos ${nuevos == 1 ? 'nuevo' : 'nuevos'}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
                  ],
                ),
              ),
              if (avisos.isEmpty)
                _Tarjeta(
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('No hay avisos pendientes en el ganado.',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ),
              for (final a in avisos) _AvisoCard(a, nuevo: _nuevos.contains(claveAviso(a))),
            ],
          );
        },
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
        // Material propio para que los interruptores muestren su efecto sobre la tarjeta blanca.
        child: Material(color: Colors.transparent, child: child),
      );
}

class _AvisoCard extends StatelessWidget {
  const _AvisoCard(this.aviso, {required this.nuevo});

  final Aviso aviso;
  final bool nuevo;

  @override
  Widget build(BuildContext context) {
    final a = aviso.animal;
    final urgente = aviso.tipo == 'Pendientes' || aviso.tipo == 'Tratamientos';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: cardShadow),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FichaAnimalPage(a))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: urgente ? AppColors.dangerSoft : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(descripcionAvisos[aviso.tipo]!.$2,
                      color: urgente ? AppColors.danger : AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(aviso.titulo,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                          ),
                          if (nuevo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                  color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(6)),
                              child: Text('Nuevo',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.danger)),
                            ),
                          ],
                        ],
                      ),
                      Text('${a.codigo}${a.nombre.isEmpty ? '' : ' • ${a.nombre}'} — ${aviso.detalle}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                FotoAnimal(a.foto, size: 36, radius: 8, iconSize: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
