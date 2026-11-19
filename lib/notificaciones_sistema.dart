import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pages/notificaciones_page.dart';

const _canal = MethodChannel('agroregister/notificaciones'); // ver MainActivity.kt

/// Si llegan más avisos nuevos que esto a la vez (p. ej. al activar un tipo), se notifica uno solo de resumen.
const maxAvisosSueltos = 3;

Future<void> _llamar(String metodo, [Map<String, Object>? args]) async {
  if (!Platform.isAndroid) return; // shortcut: solo Android; iOS y escritorio requieren su propio código nativo
  try {
    await _canal.invokeMethod(metodo, args);
  } catch (e) {
    debugPrint('No se pudo mostrar la notificación: $e');
  }
}

Future<void> _mostrar(int id, String titulo, String texto) =>
    _llamar('mostrar', {'id': id, 'titulo': titulo, 'texto': texto});

/// Quita de la barra del teléfono las notificaciones de avisos (cuando ya se vieron en la app).
Future<void> quitarNotificaciones() => _llamar('quitar');

/// "3 vacunas pendientes • 1 sin arete": cuántos avisos hay de cada tipo.
String resumenAvisos(List<Aviso> avisos) {
  final nombres = {
    'Pendientes': ('incidencia pendiente', 'incidencias pendientes'),
    'Tratamientos': ('en tratamiento', 'en tratamiento'),
    'Aretado': ('sin arete', 'sin arete'),
    'Vacunas': ('vacuna pendiente', 'vacunas pendientes'),
  };
  return [
    for (final MapEntry(key: tipo, value: (uno, varios)) in nombres.entries)
      if (avisos.where((a) => a.tipo == tipo).length case final n when n > 0) '$n ${n == 1 ? uno : varios}',
  ].join(' • ');
}

bool _iniciado = false;

/// Muestra los avisos de campo como notificaciones del dispositivo: al entrar a la app un resumen de los que
/// hay, y después cada aviso nuevo que aparezca mientras se usa (o un resumen si llegan muchos juntos).
void iniciarNotificaciones() {
  if (_iniciado) return;
  _iniciado = true;
  _llamar('permiso');

  // Al entrar solo se resumen los que el usuario aún no ha visto; los ya leídos no se vuelven a notificar.
  final iniciales = avisosSinLeer();
  final vistos = avisosActuales().map(claveAviso).toSet();
  if (iniciales.isNotEmpty) {
    _mostrar(1, 'Tienes ${iniciales.length} ${iniciales.length == 1 ? 'aviso' : 'avisos'} de campo',
        resumenAvisos(iniciales));
  }

  cambiosDeAvisos.addListener(() {
    final nuevos = [
      for (final a in avisosActuales())
        if (vistos.add(claveAviso(a))) a,
    ];
    if (nuevos.isEmpty) return;
    if (nuevos.length > maxAvisosSueltos) {
      _mostrar(2, '${nuevos.length} avisos nuevos', resumenAvisos(nuevos));
      return;
    }
    for (final a in nuevos) {
      final quien = '${a.animal.codigo}${a.animal.nombre.isEmpty ? '' : ' ${a.animal.nombre}'}';
      _mostrar(claveAviso(a).hashCode & 0x7fffffff, a.titulo, '$quien — ${a.detalle}');
    }
  });
}
