import 'package:flutter/material.dart';

import '../theme.dart';

// shortcut: datos fijos copiados del diseño, conectarlos al modelo real cuando exista.
class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: const [
        _Saludo(),
        SizedBox(height: 24),
        _Seccion('Resumen de hato', accion: 'Actualizado hoy'),
        _Resumen(),
        SizedBox(height: 24),
        _Seccion('Accesos rápidos'),
        _Acceso(
          icon: Icons.add,
          iconColor: Colors.white,
          bg: AppColors.primary,
          title: 'Agregar animal',
          subtitle: 'Registro con foto, arete y datos',
        ),
        _Acceso(
          icon: Icons.swap_horiz,
          iconColor: AppColors.primary,
          bg: AppColors.primarySoft,
          title: 'Registrar movimiento',
          subtitle: 'Ventas, traslados, compras o nacimientos',
        ),
        _Acceso(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.warning,
          bg: AppColors.dangerSoft,
          title: 'Reportar incidencia',
          subtitle: 'Pérdida de arete, golpe o tratamiento',
        ),
        SizedBox(height: 12),
        _Seccion('Inspección reciente', accion: 'Ver todas →'),
        _Animal(codigo: 'VG-001', nombre: 'Luna', detalle: 'Hembra · Holstein · 3 años', arete: '#2584'),
        _Animal(codigo: 'VG-002', nombre: 'Rayo', detalle: 'Macho · Pardo Suizo · 2 años', arete: '#3109'),
      ],
    );
  }
}

BoxDecoration _card() => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: cardShadow,
    );

Widget _chip(String text, {Widget? leading}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?leading,
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ],
      ),
    );

class _Saludo extends StatelessWidget {
  const _Saludo();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RANCHO SAN JOSÉ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppColors.textMuted),
              ),
              SizedBox(height: 2),
              Text(
                'Buen día, Don Juan 👋',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
            ],
          ),
        ),
        _chip(
          'Hato al día',
          leading: Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.title, {this.accion});

  final String title;
  final String? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
          ),
          if (accion != null)
            Text(accion!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen();

  static const _muted = TextStyle(fontSize: 13, color: AppColors.textMuted);

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FilaStats(
          _Stat(
            label: 'Total animales',
            icon: Icons.pets,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft,
            value: Text('24'),
            footer: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 15, color: AppColors.primary),
                SizedBox(width: 4),
                Flexible(
                  child: Text('100% registrados',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ],
            ),
          ),
          _Stat(
            label: 'Hembras',
            icon: Icons.female,
            iconColor: AppColors.warning,
            iconBg: AppColors.dangerSoft,
            value: Text('14'),
            footer: Text('58% del total', style: _muted),
          ),
        ),
        SizedBox(height: 12),
        _FilaStats(
          _Stat(
            label: 'Machos',
            icon: Icons.male,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft,
            value: Text('10'),
            footer: Text('42% del total', style: _muted),
          ),
          _Stat(
            label: 'Enfermos',
            icon: Icons.medical_services,
            iconColor: AppColors.danger,
            iconBg: AppColors.dangerSoft,
            value: Text.rich(
              TextSpan(
                text: '1 ',
                style: TextStyle(color: AppColors.danger),
                children: [
                  TextSpan(text: 'Revisión', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            footer: Text('VG-004 (Fiebre leve)', style: _muted),
          ),
        ),
      ],
    );
  }
}

class _FilaStats extends StatelessWidget {
  const _FilaStats(this.a, this.b);

  final Widget a;
  final Widget b;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.footer,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget value;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.text, height: 1.1),
            child: value,
          ),
          const SizedBox(height: 4),
          footer,
        ],
      ),
    );
  }
}

class _Acceso extends StatelessWidget {
  const _Acceso({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // shortcut: sin destino aún, conectar cuando existan las pantallas.
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right, size: 20, color: AppColors.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Animal extends StatelessWidget {
  const _Animal({required this.codigo, required this.nombre, required this.detalle, required this.arete});

  final String codigo;
  final String nombre;
  final String detalle;
  final String arete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: _card(),
      child: Row(
        children: [
          // shortcut: ícono en lugar de la foto, usar Image cuando el animal tenga foto.
          Container(
            width: 64,
            height: 56,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.pets, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$codigo · $nombre',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                    ),
                    _chip('Activo'),
                  ],
                ),
                const SizedBox(height: 2),
                Text(detalle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.sell_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Arete $arete', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.text),
        ],
      ),
    );
  }
}
