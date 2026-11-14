import 'package:flutter/material.dart';

import '../datos.dart';
import '../foto.dart';
import '../theme.dart';
import 'nuevo_movimiento_page.dart';

// Edición de los datos del rancho: se abre desde "Datos del rancho" en el Perfil.
class DatosRanchoPage extends StatefulWidget {
  const DatosRanchoPage({super.key});

  @override
  State<DatosRanchoPage> createState() => _DatosRanchoPageState();
}

class _DatosRanchoPageState extends State<DatosRanchoPage> {
  final r = rancho.value;
  late final _nombre = TextEditingController(text: r.nombre);
  late final _propietario = TextEditingController(text: r.propietario);
  late final _ubicacion = TextEditingController(text: r.ubicacion);
  late final _upp = TextEditingController(text: r.upp);
  late final _fierro = TextEditingController(text: r.fierro);
  late final _capacidad = TextEditingController(text: '${r.capacidad}');
  late String? _fierroFoto = r.fierroFoto;

  @override
  void dispose() {
    for (final c in [_nombre, _propietario, _ubicacion, _upp, _fierro, _capacidad]) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    final capacidad = int.tryParse(_capacidad.text.trim());
    final error = _nombre.text.trim().isEmpty
        ? 'Escribe el nombre del rancho'
        : _propietario.text.trim().isEmpty
            ? 'Escribe el nombre del propietario'
            : (capacidad == null || capacidad <= 0)
                ? 'La capacidad debe ser un número mayor a 0'
                : null;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    rancho.value = Rancho(
      nombre: _nombre.text.trim(),
      propietario: _propietario.text.trim(),
      ubicacion: _ubicacion.text.trim(),
      upp: _upp.text.trim(),
      fierro: _fierro.text.trim(),
      capacidad: capacidad!,
      fierroFoto: _fierroFoto,
    );
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
          FormTarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormEtiqueta('Nombre del rancho', requerido: true),
                FormCampo(controller: _nombre, hint: 'Ej. Rancho San José', icon: Icons.agriculture),
                const SizedBox(height: 14),
                const FormEtiqueta('Propietario', requerido: true),
                FormCampo(controller: _propietario, hint: 'Ej. Don Juan Pérez', icon: Icons.person_outline),
                const SizedBox(height: 14),
                const FormEtiqueta('Ubicación'),
                FormCampo(controller: _ubicacion, hint: 'Ej. Veracruz, México', icon: Icons.location_on_outlined),
              ],
            ),
          ),
          FormTarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormEtiqueta('Registro UPP'),
                FormCampo(controller: _upp, hint: 'Ej. VER-30-089-214', icon: Icons.badge_outlined),
                const SizedBox(height: 14),
                const FormEtiqueta('Fierro oficial'),
                FormCampo(controller: _fierro, hint: 'Ej. SJ - Reg. 842', icon: Icons.branding_watermark_outlined),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      FotoAnimal(_fierroFoto,
                          size: 56, icono: Icons.branding_watermark_outlined, verComo: 'Fierro del rancho'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Imagen del fierro',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                            Text(_fierroFoto == null ? 'Opcional: foto o dibujo de la marca' : 'Imagen cargada',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      if (_fierroFoto != null)
                        IconButton(
                          tooltip: 'Quitar imagen',
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                          onPressed: () => setState(() => _fierroFoto = null),
                        ),
                      FilledButton(
                        onPressed: () async {
                          final ruta = await elegirImagen(context);
                          if (ruta != null) setState(() => _fierroFoto = ruta);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primarySoft,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(_fierroFoto == null ? 'Elegir' : 'Cambiar',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const FormEtiqueta('Capacidad del potrero (cabezas)', requerido: true),
                FormCampo(
                  controller: _capacidad,
                  hint: 'Ej. 30',
                  icon: Icons.fence,
                  teclado: TextInputType.number,
                ),
              ],
            ),
          ),
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
