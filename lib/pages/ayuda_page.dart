import 'package:flutter/material.dart';

import '../theme.dart';

const _preguntas = [
  (
    '¿Qué es el código GV-###?',
    'Es el identificador interno que la app asigna a cada animal al registrarlo. Nunca cambia, aunque el animal '
        'pierda o reemplace su arete, así su historial completo queda siempre ligado a él.'
  ),
  (
    '¿Qué hago si un animal pierde su arete?',
    'Abre su ficha y toca "Reportar incidencia". Elige "Pérdida de arete", escribe el número del arete nuevo y '
        'guarda: el animal conserva su código GV y su historial.'
  ),
  (
    '¿Cómo registro una venta, compra o traslado?',
    'Desde Inicio, la pestaña Movimientos o la ficha del animal toca "Registrar movimiento". Las ventas cuentan '
        'como baja en Reportes.'
  ),
  (
    '¿La app reemplaza el arete oficial SINIIGA?',
    'No. La app es un control interno del rancho y no sustituye la identificación oficial obligatoria de los '
        'organismos ganaderos.'
  ),
  (
    '¿Necesito internet?',
    'No. Todo se guarda en el teléfono y sigue ahí al cerrar la app.'
  ),
  (
    '¿Cómo veo el resumen de un periodo?',
    'En Reportes toca "Ver desglose". Por defecto muestra del día 1 del mes hasta hoy; toca el periodo para '
        'elegir otras fechas.'
  ),
];

// Ayuda y preguntas frecuentes: se abre desde el Perfil.
class AyudaPage extends StatelessWidget {
  const AyudaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Ayuda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          for (final (pregunta, respuesta) in _preguntas)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration:
                  BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  shape: const RoundedRectangleBorder(),
                  leading: Icon(Icons.help_outline, color: AppColors.primary),
                  title: Text(pregunta,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(respuesta, style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
