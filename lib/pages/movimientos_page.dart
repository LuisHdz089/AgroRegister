import 'package:flutter/material.dart';

import '../theme.dart';
import 'animales_page.dart';
import 'nueva_incidencia_page.dart';
import 'nuevo_movimiento_page.dart';

const tiposMovimiento = {
  'Venta': Icons.payments_outlined,
  'Compra': Icons.shopping_cart_outlined,
  'Traslado': Icons.local_shipping_outlined,
  'Nacimiento': Icons.child_friendly_outlined,
};

String fechaCorta(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

class Movimiento {
  const Movimiento({
    required this.folio,
    required this.tipo,
    required this.fecha,
    required this.animal,
    this.notas = '',
    this.origenDestino = '',
    this.monto,
    this.guia = '',
    this.documento,
  });

  final String folio; // MOV-0001
  final String tipo; // clave de tiposMovimiento
  final DateTime fecha;
  final Animal animal;
  final String notas;
  final String origenDestino;
  final double? monto;
  final String guia;
  final String? documento; // ruta de la foto de la guía
}

final movimientos = ValueNotifier<List<Movimiento>>([]);

/// Venta y traslado (movimientos) y muerte o robo (incidencias) sacan al animal del ganado:
/// sigue registrado (ficha e historial), pero ya no se cuenta.
const tiposSalida = {'Venta', 'Traslado'};

/// Cómo salió un animal del ganado: [tipo] es el del movimiento o la incidencia; [lugar] el comprador,
/// destino, causa o último lugar visto; [folio] solo existe en los movimientos.
typedef Salida = ({String tipo, DateTime fecha, String lugar, String? folio});

/// Salida del animal del ganado, o null si sigue en él. Si hubiera varias, cuenta la más reciente.
Salida? salidaDe(String codigo, [List<Movimiento>? movs, List<Incidencia>? incs]) {
  final salidas = <Salida>[
    for (final m in movs ?? movimientos.value)
      if (m.animal.codigo == codigo && tiposSalida.contains(m.tipo))
        (tipo: m.tipo, fecha: m.fecha, lugar: m.origenDestino, folio: m.folio),
    for (final i in incs ?? incidencias.value)
      if (i.animal.codigo == codigo && tiposBajaIncidencia.contains(i.tipo))
        (tipo: i.tipo, fecha: i.fecha, lugar: i.detalle, folio: null),
  ]..sort((a, b) => a.fecha.compareTo(b.fecha));
  return salidas.lastOrNull;
}

bool enHato(Animal a, [List<Movimiento>? movs, List<Incidencia>? incs]) => salidaDe(a.codigo, movs, incs) == null;

/// "Vendido", "Trasladado", "Muerto" o "Extraviado" si el animal ya salió del ganado; null si sigue en él.
String? etiquetaSalida(Animal a) => switch (salidaDe(a.codigo)?.tipo) {
      null => null,
      'Venta' => 'Vendido',
      'Traslado' => 'Trasladado',
      'Muerte' => 'Muerto',
      _ => 'Extraviado',
    };

class MovimientosPage extends StatelessWidget {
  const MovimientosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder(
          valueListenable: movimientos,
          builder: (context, lista, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${lista.length}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text, height: 1)),
                  const SizedBox(width: 6),
                  const Text('movimientos registrados', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 16),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Aún no hay movimientos registrados',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                ),
              for (final m in lista.reversed) _MovimientoCard(m),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab-movimientos', // dos FAB viven a la vez en el IndexedStack
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NuevoMovimientoPage())),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            icon: const Icon(Icons.add),
            label: const Text('Registrar movimiento', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  const _MovimientoCard(this.m);

  final Movimiento m;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 12, color: AppColors.textMuted);
    final detalle = [fechaCorta(m.fecha), if (m.origenDestino.isNotEmpty) m.origenDestino].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(tiposMovimiento[m.tipo], color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${m.tipo} · ${m.animal.codigo} ${m.animal.nombre}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                    ),
                    if (m.monto != null)
                      Text('\$${m.monto!.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(detalle, style: muted),
                if (m.notas.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(m.notas, maxLines: 2, overflow: TextOverflow.ellipsis, style: muted),
                ],
                const SizedBox(height: 4),
                Text([m.folio, if (m.guia.isNotEmpty) 'Guía ${m.guia}'].join(' • '),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
