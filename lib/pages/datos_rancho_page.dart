import 'package:flutter/material.dart';

import '../datos.dart';
import '../foto.dart';
import '../theme.dart';
import 'nuevo_movimiento_page.dart';

/// Campos de los datos del rancho, compartidos por "Datos del rancho" (Perfil) y el registro inicial.
class CamposRancho {
  CamposRancho(Rancho r)
      : nombre = TextEditingController(text: r.nombre),
        propietario = TextEditingController(text: r.propietario),
        ubicacion = TextEditingController(text: r.ubicacion),
        upp = TextEditingController(text: r.upp),
        fierro = TextEditingController(text: r.fierro),
        capacidad = TextEditingController(text: '${r.capacidad}'),
        fierroFoto = r.fierroFoto;

  /// Campos en blanco para un rancho nuevo (la capacidad sugiere 30 cabezas).
  CamposRancho.vacios()
      : this(const Rancho(nombre: '', propietario: '', ubicacion: '', upp: '', fierro: '', capacidad: 30));

  final TextEditingController nombre, propietario, ubicacion, upp, fierro, capacidad;
  String? fierroFoto;

  void dispose() {
    for (final c in [nombre, propietario, ubicacion, upp, fierro, capacidad]) {
      c.dispose();
    }
  }

  /// Mensaje del primer dato que falta o no es válido; null si todo está bien.
  String? get error {
    final n = int.tryParse(capacidad.text.trim());
    if (nombre.text.trim().isEmpty) return 'Escribe el nombre del rancho';
    if (propietario.text.trim().isEmpty) return 'Escribe el nombre del propietario';
    if (n == null || n <= 0) return 'La capacidad debe ser un número mayor a 0';
    return null;
  }

  /// Solo llamar cuando [error] es null.
  Rancho get rancho => Rancho(
        nombre: nombre.text.trim(),
        propietario: propietario.text.trim(),
        ubicacion: ubicacion.text.trim(),
        upp: upp.text.trim(),
        fierro: fierro.text.trim(),
        capacidad: int.parse(capacidad.text.trim()),
        fierroFoto: fierroFoto,
      );

  /// Las dos tarjetas del formulario. [refrescar] redibuja la pantalla al elegir o quitar la imagen del fierro.
  List<Widget> tarjetas(BuildContext context, void Function(VoidCallback) refrescar) => [
        FormTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormEtiqueta('Nombre del rancho', requerido: true),
              FormCampo(controller: nombre, hint: 'Ej. Rancho San José', icon: Icons.agriculture),
              const SizedBox(height: 14),
              const FormEtiqueta('Propietario', requerido: true),
              FormCampo(controller: propietario, hint: 'Ej. Don Juan Pérez', icon: Icons.person_outline),
              const SizedBox(height: 14),
              const FormEtiqueta('Ubicación'),
              FormCampo(controller: ubicacion, hint: 'Ej. Veracruz, México', icon: Icons.location_on_outlined),
            ],
          ),
        ),
        FormTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormEtiqueta('Registro UPP'),
              FormCampo(controller: upp, hint: 'Ej. VER-30-089-214', icon: Icons.badge_outlined),
              const SizedBox(height: 14),
              const FormEtiqueta('Fierro oficial'),
              FormCampo(controller: fierro, hint: 'Ej. SJ - Reg. 842', icon: Icons.branding_watermark_outlined),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    FotoAnimal(fierroFoto,
                        size: 56, icono: Icons.branding_watermark_outlined, verComo: 'Fierro del rancho'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Imagen del fierro',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                          Text(fierroFoto == null ? 'Opcional: foto o dibujo de la marca' : 'Imagen cargada',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    if (fierroFoto != null)
                      IconButton(
                        tooltip: 'Quitar imagen',
                        icon: Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => refrescar(() => fierroFoto = null),
                      ),
                    FilledButton(
                      onPressed: () async {
                        final ruta = await elegirImagen(context);
                        if (ruta != null) refrescar(() => fierroFoto = ruta);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(fierroFoto == null ? 'Elegir' : 'Cambiar',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const FormEtiqueta('Capacidad del potrero (cabezas)', requerido: true),
              FormCampo(controller: capacidad, hint: 'Ej. 30', icon: Icons.fence, teclado: TextInputType.number),
            ],
          ),
        ),
      ];
}

// Edición de los datos del rancho: se abre desde "Datos del rancho" en el Perfil.
class DatosRanchoPage extends StatefulWidget {
  const DatosRanchoPage({super.key});

  @override
  State<DatosRanchoPage> createState() => _DatosRanchoPageState();
}

class _DatosRanchoPageState extends State<DatosRanchoPage> {
  final _campos = CamposRancho(rancho.value);

  @override
  void dispose() {
    _campos.dispose();
    super.dispose();
  }

  void _guardar() {
    final error = _campos.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    rancho.value = _campos.rancho;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Datos del rancho', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          ..._campos.tarjetas(context, setState),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Guardar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
