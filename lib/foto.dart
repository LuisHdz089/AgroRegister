import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

import 'theme.dart';

/// Abre la galería (Android/iOS) o el explorador de archivos (Windows/macOS/Linux).
/// Devuelve la ruta de la imagen, o null si el usuario cancela.
Future<String?> elegirImagen(BuildContext context) async {
  try {
    return (await ImagePicker().pickImage(source: ImageSource.gallery))?.path;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir la imagen: $e')));
    }
    return null;
  }
}

/// Imagen local (foto del animal, del fierro…), o [icono] si no hay.
// shortcut: Image.file no funciona en web; usar Image.network/bytes si se publica la versión web.
class FotoAnimal extends StatelessWidget {
  const FotoAnimal(this.ruta,
      {super.key, this.size = 60, this.radius = 10, this.iconSize = 24, this.icono = Icons.pets, this.verComo, this.ajuste = BoxFit.cover});

  final String? ruta;
  final double size;
  final double radius;
  final double iconSize;
  final IconData icono; // se muestra si no hay imagen
  final String? verComo; // título al tocarla para verla en grande; null = no se amplía
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) {
    final r = ruta;
    final imagen = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.primarySoft,
        child: r == null
            ? Icon(icono, size: iconSize, color: AppColors.primary)
            : Image.file(File(r), fit: ajuste,
                errorBuilder: (_, _, _) => Icon(icono, size: iconSize, color: AppColors.primary)),
      ),
    );
    if (r == null || verComo == null) return imagen;
    return Semantics(
      button: true,
      label: 'Ver $verComo',
      child: GestureDetector(onTap: () => verImagen(context, r, verComo!), child: imagen),
    );
  }
}

/// Muestra la imagen en pantalla completa, con zoom.
void verImagen(BuildContext context, String ruta, String titulo) => showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(titulo,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.file(
                  File(ruta),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No se encontró la imagen. Puede que se haya borrado de la galería.',
                        textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

const _extensionesImagen = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];

/// Nombre del archivo sin la marca de tiempo que se le agrega al copiarlo.
String nombreDocumento(String ruta) => p.basename(ruta).replaceFirst(RegExp(r'^\d{13}_'), '');

/// Abre el explorador para elegir un documento (PDF, imagen o Word) y guarda una copia dentro de la app,
/// para que no se pierda si el original se borra o el sistema limpia su caché. Devuelve la ruta de la copia.
Future<String?> elegirDocumento(BuildContext context) async {
  try {
    final archivo = await FilePicker.pickFile(
      dialogTitle: 'Documento del animal',
      type: FileType.custom,
      allowedExtensions: ['pdf', ..._extensionesImagen, 'doc', 'docx'],
    );
    final origen = archivo?.path;
    if (origen == null) return null; // canceló
    // En Android van a la carpeta "files" de la app (junto a "databases"): es la que comparte el FileProvider.
    final bd = await getDatabasesPath();
    final carpeta = Directory(p.join(Platform.isAndroid ? p.join(p.dirname(bd), 'files') : bd, 'documentos'));
    await carpeta.create(recursive: true);
    final destino = p.join(carpeta.path, '${DateTime.now().millisecondsSinceEpoch}_${p.basename(origen)}');
    await File(origen).copy(destino);
    return destino;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo adjuntar el documento: $e')));
    }
    return null;
  }
}

/// Las imágenes se ven dentro de la app; PDF y Word se abren con la app del teléfono o la computadora.
Future<void> abrirDocumento(BuildContext context, String ruta) async {
  final ext = p.extension(ruta).replaceFirst('.', '').toLowerCase();
  if (_extensionesImagen.contains(ext)) return verImagen(context, ruta, nombreDocumento(ruta));
  String? error;
  try {
    if (!File(ruta).existsSync()) {
      error = 'No se encontró el documento';
    } else if (Platform.isAndroid) {
      // Canal propio en MainActivity.kt (FileProvider + "Abrir con…").
      final r = await const MethodChannel('vacatec/archivos').invokeMethod<String>('abrir', {'ruta': ruta});
      if (r == 'sinApp') error = 'No hay una app para abrir este tipo de archivo';
    } else if (Platform.isWindows) {
      await Process.run('explorer', [ruta]); // explorer devuelve código 1 aunque abra bien: no se revisa
    } else if (Platform.isMacOS || Platform.isLinux) {
      final r = await Process.run(Platform.isMacOS ? 'open' : 'xdg-open', [ruta]);
      if (r.exitCode != 0) error = 'No hay una app para abrir este tipo de archivo';
    } else {
      error = 'Abrir PDF o Word aún no está disponible en este dispositivo';
    }
  } on PlatformException catch (e) {
    error = 'No se pudo abrir el documento: ${e.message}';
  }
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}
