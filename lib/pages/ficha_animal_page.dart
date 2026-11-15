import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../datos.dart';
import '../foto.dart';
import '../iconos_especie.dart';
import '../theme.dart';
import 'animales_page.dart';
import 'historial_page.dart';
import 'movimientos_page.dart';
import 'nueva_incidencia_page.dart';
import 'nuevo_animal_page.dart';
import 'nuevo_movimiento_page.dart';

/// Resumen en texto plano de la ficha, para compartirla.
String fichaEnTexto(Animal a, List<Evento> eventos) => [
  '${a.codigo}${a.nombre.isEmpty ? '' : ' — ${a.nombre}'} (${rancho.value.nombre})',
  '${a.sexo} • ${a.edad} • ${a.raza} • ${a.color}',
  'Arete: ${a.arete ?? 'en trámite'}',
  'Estado: ${etiquetaSalida(a) ?? (a.enTratamiento ? 'En tratamiento' : 'Activo')}',
  if (eventos.isNotEmpty) ...[
    '',
    'Historial:',
    for (final e in eventos.take(10)) '• ${fechaCorta(e.fecha)} ${e.titulo} (${e.etiqueta})',
  ],
].join('\n');

// Ficha de un animal: se abre al tocar una tarjeta en la pestaña Animales.
class FichaAnimalPage extends StatelessWidget {
  const FichaAnimalPage(this.animal, {super.key});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([animales, movimientos, incidencias]),
      builder: (context, _) =>
          _build(context, animales.value.where((x) => x.codigo == animal.codigo).firstOrNull ?? animal),
    );
  }

  Widget _build(BuildContext context, Animal a) {
    final estadoColor = a.enTratamiento ? AppColors.danger : AppColors.primary;
    final estadoBg = a.enTratamiento ? AppColors.dangerSoft : AppColors.primarySoft;
    final eventos = eventosDe(a.codigo);
    final nInc = eventos.where((e) => e.esIncidencia).length;
    final pendientes = incidencias.value.where((i) => i.animal.codigo == a.codigo && !i.atendida).length;
    final ultimo = eventos.firstOrNull;
    final salida = salidaDe(a.codigo); // venta, traslado, muerte o robo: ya no forma parte del ganado
    void abrirHistorial(bool inc) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => HistorialPage(a.codigo, incidencias: inc)));

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
          if (salida != null) _AvisoSalida(salida),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _chip('REGISTRO SINCRONIZADO', AppColors.primary, AppColors.primarySoft, dot: true),
                ),
              ),
              const SizedBox(width: 8),
              // Sin paquete de compartir: se copia la ficha al portapapeles para pegarla en WhatsApp, correo, etc.
              _BotonBlanco(
                icon: Icons.share_outlined,
                tooltip: 'Compartir',
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: fichaEnTexto(a, eventos)));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ficha copiada. Pégala en WhatsApp, correo o mensajes.')),
                    );
                  }
                },
              ),
              if (salida == null) ...[
                const SizedBox(width: 8),
                _BotonBlanco(
                  icon: Icons.edit_outlined,
                  label: 'Editar',
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => NuevoAnimalPage(editar: a))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                Positioned.fill(child: FotoAnimal(a.foto, size: double.infinity, radius: 16, iconSize: 56)),
                Positioned(
                  left: 10,
                  top: 10,
                  child: _chip(
                    'Fierro verificado',
                    AppColors.text,
                    AppColors.surface.withValues(alpha: 0.85),
                    icon: Icons.verified_outlined,
                  ),
                ),
                if (salida == null)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Material(
                      color: AppColors.surface,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () async {
                          final ruta = await elegirImagen(context);
                          if (ruta != null) actualizarAnimal(a.copyWith(foto: ruta));
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_camera, size: 16, color: AppColors.text),
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
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.codigo,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                    salida != null
                        ? _chip(etiquetaSalida(a)!, AppColors.textMuted, AppColors.border, dot: true)
                        : _chip(a.enTratamiento ? 'En tratamiento' : 'Activo', estadoColor, estadoBg, dot: true),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      a.nombre,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    if (a.nota != null) ...[
                      const SizedBox(width: 6),
                      Text('(${a.nota})', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _Grid([
                  _Dato(a.sexo == 'Hembra' ? Icons.female : Icons.male, 'Sexo', a.sexo),
                  _Dato(Icons.calendar_today_outlined, 'Edad', a.edad),
                  _Dato(IconoEspecie(a.especie, size: 20), a.nombreEspecie, a.raza),
                  _Dato(Icons.palette_outlined, 'Color', a.color),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: [
                const _Titulo('Identificación y Rancho', 'Trazabilidad oficial'),
                _Fila(
                  icon: Icons.sell_outlined,
                  label: 'Arete Oficial SINIIGA',
                  value: a.arete ?? 'En trámite',
                  trailing: a.arete == null
                      ? _chip('Pendiente', AppColors.warning, AppColors.dangerSoft)
                      : _chip('Vigente', AppColors.primary, AppColors.primarySoft),
                ),
                const SizedBox(height: 10),
                _Fila(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Fierro o Marca Registrada',
                  value: rancho.value.nombre,
                  trailing: rancho.value.fierroFoto == null
                      ? Icon(Icons.verified_user_outlined, size: 20, color: AppColors.textMuted)
                      : FotoAnimal(
                          rancho.value.fierroFoto,
                          size: 40,
                          radius: 8,
                          iconSize: 18,
                          verComo: 'Fierro del rancho',
                        ),
                ),
                const SizedBox(height: 10),
                _Fila(
                  icon: Icons.description_outlined,
                  label: 'Documento',
                  value: a.documento == null ? 'Sin documento (agrégalo con Editar)' : nombreDocumento(a.documento!),
                  trailing: a.documento == null
                      ? const SizedBox.shrink()
                      : TextButton.icon(
                          onPressed: () => abrirDocumento(context, a.documento!),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Abrir', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Titulo('Historiales de ${a.nombre}', 'Actualizado hoy'),
          _Historial(
            icon: Icons.swap_horiz,
            color: AppColors.primary,
            bg: AppColors.primarySoft,
            title: 'Historial de movimientos',
            badge: _chip('${eventos.length - nInc} reg.', AppColors.textMuted, AppColors.background),
            subtitle: 'Ventas, traslados entre potreros, pesajes y más',
            onTap: () => abrirHistorial(false),
          ),
          _Historial(
            icon: Icons.health_and_safety_outlined,
            color: AppColors.danger,
            bg: AppColors.dangerSoft,
            title: 'Incidencias y salud',
            badge: pendientes == 0
                ? _chip('Al día', AppColors.primary, AppColors.primarySoft)
                : _chip('$pendientes pend.', AppColors.danger, AppColors.dangerSoft),
            subtitle: 'Pérdida de arete, vacunas, revisiones y tratamientos',
            onTap: () => abrirHistorial(true),
          ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Último evento registrado',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                    ),
                    if (ultimo != null)
                      Text(
                        fechaCorta(ultimo.fecha),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: ultimo == null
                      ? Text(
                          'Sin eventos registrados',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20, color: ultimo.fg),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ultimo.titulo,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  if (ultimo.descripcion.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      ultimo.descripcion,
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          // Un animal que ya salió del ganado no admite movimientos ni incidencias nuevas.
          if (salida == null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => NuevoMovimientoPage(animal: a))),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Registrar movimiento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => NuevaIncidenciaPage(animal: a))),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.text,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('Reportar incidencia', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _chip(String text, Color fg, Color bg, {bool dot = false, IconData? icon}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (dot)
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
        ),
      if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
      Flexible(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
        ),
      ),
    ],
  ),
);

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
    child: child,
  );
}

class _BotonBlanco extends StatelessWidget {
  const _BotonBlanco({required this.icon, this.label, this.tooltip, required this.onTap});

  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? label ?? '',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.text),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(label!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.title, this.accion);

  final String title;
  final String accion;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
        ),
        Text(
          accion,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ],
    ),
  );
}

Widget _iconoCirculo(IconData icon) => _circulo(Icon(icon, size: 18, color: AppColors.primary));

Widget _circulo(Widget icono) => Container(
  width: 36,
  height: 36,
  alignment: Alignment.center,
  decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
  child: icono,
);

class _Dato extends StatelessWidget {
  const _Dato(this.icon, this.label, this.value);

  final Object icon; // IconData, o un widget (ícono de la especie)
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        icon is IconData ? _iconoCirculo(icon as IconData) : _circulo(icon as Widget),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Grid extends StatelessWidget {
  const _Grid(this.items);

  final List<Widget> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < items.length; i += 2) ...[
        if (i > 0) const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: items[i]),
            const SizedBox(width: 10),
            Expanded(child: items[i + 1]),
          ],
        ),
      ],
    ],
  );
}

class _Fila extends StatelessWidget {
  const _Fila({required this.icon, required this.label, required this.value, required this.trailing});

  final IconData icon;
  final String label;
  final String value;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        _iconoCirculo(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
              ),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _Historial extends StatelessWidget {
  const _Historial({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final Widget badge;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                            ),
                          ),
                          const SizedBox(width: 6),
                          badge,
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso en la ficha de un animal vendido o trasladado: ya no forma parte del ganado.
class _AvisoSalida extends StatelessWidget {
  const _AvisoSalida(this.s);

  final Salida s;

  @override
  Widget build(BuildContext context) {
    final fecha = fechaCorta(s.fecha);
    final detalle = [
      switch (s.tipo) {
        'Venta' => 'Vendido el $fecha',
        'Traslado' => 'Trasladado el $fecha',
        'Muerte' => 'Murió el $fecha',
        _ => 'Robado o extraviado el $fecha',
      },
      if (s.lugar.isNotEmpty)
        switch (s.tipo) {
          'Venta' => 'a ${s.lugar}',
          'Traslado' => 'hacia ${s.lugar}',
          'Muerte' => 'Causa: ${s.lugar}',
          _ => 'Visto por última vez en ${s.lugar}',
        },
      if (s.folio != null) 'Folio #${s.folio}',
    ].join(' • ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.block, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ya no forma parte del ganado',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.danger),
                ),
                const SizedBox(height: 2),
                Text(detalle, style: TextStyle(fontSize: 12, color: AppColors.text)),
                const SizedBox(height: 4),
                Text(
                  'Su ficha e historial se conservan, pero no se cuenta en el hato ni admite nuevos registros.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
