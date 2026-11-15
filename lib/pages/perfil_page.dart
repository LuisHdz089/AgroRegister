import 'package:flutter/material.dart';

import '../datos.dart';
import '../foto.dart';
import '../theme.dart';
import 'ayuda_page.dart';
import 'datos_rancho_page.dart';
import 'legal_page.dart';
import 'notificaciones_page.dart';

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
        children: [
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
            destino: DatosRanchoPage.new,
          ),
          _Opcion(
            icon: Icons.notifications_active_outlined,
            title: 'Notificaciones de campo',
            subtitle: 'Alertas de vacunas, aretado y tratamientos',
            destino: NotificacionesPage.new,
          ),
          _Opcion(
            icon: Icons.help_outline,
            title: 'Ayuda y preguntas frecuentes',
            subtitle: 'Código GV-### invariable, aretes oficiales',
            destino: AyudaPage.new,
          ),
          _Opcion(
            icon: Icons.gavel_outlined,
            title: 'Términos y condiciones',
            subtitle: 'Uso de la aplicación y responsabilidades',
            destino: LegalPage.terminos,
          ),
          _Opcion(
            icon: Icons.privacy_tip_outlined,
            title: 'Aviso de privacidad',
            subtitle: 'Qué datos se guardan y dónde',
            destino: LegalPage.privacidad,
          ),
          SizedBox(height: 8),
          _CerrarSesion(),
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
  Widget build(BuildContext context) => ValueListenableBuilder(valueListenable: rancho, builder: (_, r, _) => _contenido(r));

  Widget _contenido(Rancho r) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.nombre,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                    const SizedBox(height: 4),
                    _IconText(Icons.person_outline, r.propietario, 14, AppColors.text),
                    const SizedBox(height: 2),
                    _IconText(Icons.location_on_outlined, r.ubicacion, 13, AppColors.textMuted),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Activo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Dato('REGISTRO UPP', r.upp)),
              const SizedBox(width: 10),
              Expanded(
                child: _Dato('FIERRO OFICIAL', r.fierro,
                    icon: Icons.branding_watermark_outlined, imagen: r.fierroFoto),
              ),
            ],
          ),
          if (r.fierroFoto != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: FotoAnimal(r.fierroFoto,
                  size: double.infinity,
                  radius: 12,
                  icono: Icons.branding_watermark_outlined,
                  ajuste: BoxFit.contain,
                  verComo: 'Fierro del rancho'),
            ),
            const SizedBox(height: 4),
            Text('Toca la imagen del fierro para verla en grande',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
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
          Flexible(
            child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: size, color: color)),
          ),
        ],
      );
}

class _Dato extends StatelessWidget {
  const _Dato(this.label, this.value, {this.icon, this.imagen});

  final String label;
  final String value;
  final IconData? icon;
  final String? imagen; // si hay, se muestra en lugar del ícono

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
            style: TextStyle(fontSize: 11, letterSpacing: 0.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (imagen != null) ...[
                FotoAnimal(imagen, size: 28, radius: 6, iconSize: 14, verComo: label.toLowerCase()),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.text),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
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
    required this.destino,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() destino; // pantalla que abre

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino())),
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CerrarSesion extends StatelessWidget {
  const _CerrarSesion();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          cerrarSesion();
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.dangerSoft,
          foregroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.logout),
        label: Text('Cerrar sesión (${usuarioActual.value ?? ''})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
