import 'package:flutter/material.dart';

import '../theme.dart';

// Perfil del rancho: se abre al tocar el avatar del encabezado.
class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [
          _RanchoCard(),
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'OPCIONES DE ADMINISTRACIÓN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
          ),
          _Opcion(
            icon: Icons.badge_outlined,
            title: 'Datos del rancho',
            subtitle: 'Nombre, fierro quemador, ubicación GPS',
          ),
          _Opcion(
            icon: Icons.group_outlined,
            title: 'Usuarios y personal',
            subtitle: 'Administrador, 2 vaqueros, veterinario',
            opcional: true,
          ),
          _Opcion(
            icon: Icons.notifications_active_outlined,
            title: 'Notificaciones de campo',
            subtitle: 'Alertas de vacunas, aretado y partos',
            opcional: true,
          ),
          _Opcion(
            icon: Icons.sync,
            title: 'Sincronización y respaldo',
            subtitle: 'Modo sin internet y respaldo nube',
            opcional: true,
          ),
          _Opcion(
            icon: Icons.help_outline,
            title: 'Ayuda y preguntas frecuentes',
            subtitle: 'Código VG-### invariable, aretes oficiales',
          ),
        ],
      ),
    );
  }
}

BoxDecoration _card() => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: cardShadow,
    );

class _RanchoCard extends StatelessWidget {
  const _RanchoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.agriculture, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rancho San José',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                    SizedBox(height: 4),
                    _IconText(Icons.person_outline, 'Don Juan Pérez', 14, AppColors.text),
                    SizedBox(height: 2),
                    _IconText(Icons.location_on_outlined, 'Veracruz, México', 13, AppColors.textMuted),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Activo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _Dato('REGISTRO UPP', 'VER-30-089-214')),
              SizedBox(width: 10),
              Expanded(child: _Dato('FIERRO OFICIAL', 'SJ - Reg. 842', icon: Icons.branding_watermark_outlined)),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText(this.icon, this.text, this.size, this.color);

  final IconData icon;
  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: size + 2, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: size, color: color)),
        ],
      );
}

class _Dato extends StatelessWidget {
  const _Dato(this.label, this.value, {this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, letterSpacing: 0.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.text),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.opcional = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool opcional;

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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          if (opcional) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Opcional',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
