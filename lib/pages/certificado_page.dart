import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../datos.dart';
import '../iconos_especie.dart';
import '../theme.dart';
import 'animales_page.dart';
import 'movimientos_page.dart';
import 'nuevo_movimiento_page.dart';

const motivosMovilizacion = ['Venta', 'Traslado a otro predio', 'Engorda', 'Exposición o feria', 'Sacrificio'];

typedef DatosMovilizacion = ({
  String folio,
  List<Animal> animales,
  String destino,
  String motivo,
  DateTime fecha,
  String transporte,
});

/// Folio del certificado a partir de la fecha y hora de emisión: CM-AAAAMMDD-HHMM.
String folioCertificado(DateTime t) {
  String d(int n) => n.toString().padLeft(2, '0');
  return 'CM-${t.year}${d(t.month)}${d(t.day)}-${d(t.hour)}${d(t.minute)}';
}

/// PDF del certificado: datos del rancho de origen (con la imagen del fierro si la hay), destino y motivo,
/// tabla de animales, firmas y la aclaración de que no sustituye la guía oficial.
/// [comprimir] en false deja el texto legible dentro del archivo (para revisarlo en pruebas).
Future<Uint8List> certificadoPdf(DatosMovilizacion d, Rancho r, {bool comprimir = true}) {
  final verde = PdfColor.fromInt(AppColors.primary.toARGB32());
  final gris = PdfColor.fromInt(AppColors.textMuted.toARGB32());
  pw.ImageProvider? fierro;
  final rutaFierro = r.fierroFoto;
  if (rutaFierro != null && File(rutaFierro).existsSync()) {
    try {
      fierro = pw.MemoryImage(File(rutaFierro).readAsBytesSync());
    } catch (_) {
      fierro = null; // formato que el PDF no admite (p. ej. HEIC): se omite la imagen
    }
  }

  pw.Widget seccion(String titulo) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    color: verde,
    child: pw.Text(
      titulo,
      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
    ),
  );

  pw.Widget datos(List<(String, String)> filas) => pw.Table(
    columnWidths: const {0: pw.FixedColumnWidth(150)},
    children: [
      for (final (k, v) in filas)
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(k, style: pw.TextStyle(color: gris)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(v.isEmpty ? '-' : v, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
    ],
  );

  pw.Widget firma(String quien) => pw.Expanded(
    child: pw.Column(
      children: [
        pw.SizedBox(height: 36),
        pw.Container(height: 1, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(quien, style: const pw.TextStyle(fontSize: 9)),
      ],
    ),
  );

  final porEspecie = [
    for (final MapEntry(key: clave, value: (_, plural, _)) in especies.entries)
      if (d.animales.any((a) => a.especie == clave)) '$plural: ${d.animales.where((a) => a.especie == clave).length}',
  ].join('   ');

  final doc = pw.Document(title: 'Certificado de movilización ${d.folio}', author: r.nombre, compress: comprimir);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CERTIFICADO DE MOVILIZACIÓN DE GANADO',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: verde),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Folio: ${d.folio}    Emitido: ${fechaCorta(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: gris),
                  ),
                ],
              ),
            ),
            if (fierro != null) pw.Image(fierro, width: 60, height: 60, fit: pw.BoxFit.contain),
          ],
        ),
        seccion('ORIGEN'),
        datos([
          ('Rancho', r.nombre),
          ('Propietario', r.propietario),
          ('Ubicación', r.ubicacion),
          ('Registro UPP', r.upp),
          ('Fierro oficial', r.fierro),
        ]),
        seccion('DESTINO Y MOTIVO'),
        datos([
          ('Destino', d.destino),
          ('Motivo', d.motivo),
          ('Fecha de movilización', fechaCorta(d.fecha)),
          ('Transporte y placas', d.transporte),
        ]),
        seccion('ANIMALES A MOVILIZAR (${d.animales.length})'),
        pw.TableHelper.fromTextArray(
          headers: ['#', 'Código', 'Especie', 'Sexo', 'Raza', 'Edad', 'Arete SINIIGA', 'Color'],
          data: [
            for (final (i, a) in d.animales.indexed)
              [
                '${i + 1}',
                a.codigo,
                a.nombreEspecie,
                a.sexo,
                a.raza,
                a.edad,
                a.arete ?? 'En trámite',
                a.color == '—' ? '-' : a.color, // la fuente del PDF no tiene la raya larga
              ],
          ],
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: verde),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 6),
        pw.Text('Total: ${d.animales.length} cabezas    $porEspecie', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 24),
        pw.Row(
          children: [
            firma('Propietario o responsable del envío'),
            pw.SizedBox(width: 40),
            firma('Autoridad o inspector'),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Documento generado por AgroRegister con los registros del rancho. No sustituye la guía de tránsito o el '
          'documento oficial de movilización expedido por la autoridad ganadera correspondiente.',
          style: pw.TextStyle(fontSize: 8, color: gris),
        ),
      ],
    ),
  );
  return doc.save();
}

// Certificado de movilización: se abre desde Reportes. Elige animales del ganado y datos del traslado,
// y guarda el PDF con "Guardar como".
class CertificadoPage extends StatefulWidget {
  const CertificadoPage({super.key});

  @override
  State<CertificadoPage> createState() => _CertificadoPageState();
}

class _CertificadoPageState extends State<CertificadoPage> {
  final _destino = TextEditingController();
  final _transporte = TextEditingController();
  final _elegidos = <String>{}; // códigos
  String _motivo = motivosMovilizacion.first;
  DateTime _fecha = DateTime.now();
  final String _folio = folioCertificado(DateTime.now());
  bool _generando = false;

  /// Solo se pueden movilizar los animales que siguen en el ganado.
  List<Animal> get _activos => animales.value.where(enHato).toList();

  @override
  void dispose() {
    _destino.dispose();
    _transporte.dispose();
    super.dispose();
  }

  void _aviso(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar() // el aviso nuevo reemplaza al anterior en vez de esperar turno
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year - 1),
      lastDate: DateTime(hoy.year + 1, hoy.month, hoy.day),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _generar() async {
    final destino = _destino.text.trim();
    final lista = _activos.where((a) => _elegidos.contains(a.codigo)).toList();
    if (lista.isEmpty) return _aviso('Selecciona al menos un animal');
    if (destino.isEmpty) return _aviso('Indica el destino');
    setState(() => _generando = true);
    try {
      final bytes = await certificadoPdf((
        folio: _folio,
        animales: lista,
        destino: destino,
        motivo: _motivo,
        fecha: _fecha,
        transporte: _transporte.text.trim(),
      ), rancho.value);
      final destinoArchivo = await FilePicker.saveFile(
        dialogTitle: 'Guardar certificado de movilización',
        fileName: 'agroregister_certificado_movilizacion_$_folio.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      if (destinoArchivo != null && mounted) _aviso('Certificado guardado: $_folio');
    } catch (e) {
      if (mounted) _aviso('No se pudo generar el certificado: $e');
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activos = _activos;
    final todos = activos.isNotEmpty && activos.every((a) => _elegidos.contains(a.codigo));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Certificado de movilización', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          FormTarjeta(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.description_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rancho.value.nombre,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      Text(
                        'UPP ${rancho.value.upp} • Folio $_folio',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FormTarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormEtiqueta('Destino', requerido: true),
                FormCampo(
                  controller: _destino,
                  hint: 'Ej. Rancho El Roble, Tierra Blanca, Ver.',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 14),
                const FormEtiqueta('Motivo', requerido: true),
                FormCaja(
                  icon: Icons.flag_outlined,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _motivo,
                      isExpanded: true,
                      isDense: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: AppColors.text),
                      style: TextStyle(fontSize: 14, color: AppColors.text),
                      items: [for (final m in motivosMovilizacion) DropdownMenuItem(value: m, child: Text(m))],
                      onChanged: (m) => setState(() => _motivo = m!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const FormEtiqueta('Fecha de movilización', requerido: true),
                FormCaja(
                  icon: Icons.calendar_today_outlined,
                  onTap: _elegirFecha,
                  child: Row(
                    children: [
                      Expanded(child: Text(fechaCorta(_fecha), style: const TextStyle(fontSize: 14))),
                      Icon(Icons.event, size: 18, color: AppColors.text),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const FormEtiqueta('Transporte y placas'),
                FormCampo(
                  controller: _transporte,
                  hint: 'Ej. Camión Ford, placas XA-1234',
                  icon: Icons.local_shipping_outlined,
                ),
              ],
            ),
          ),
          FormTarjeta(
            // Material propio para que las casillas muestren su efecto al tocarlas sobre la tarjeta blanca.
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormEtiqueta(
                    'Animales a movilizar',
                    requerido: true,
                    extra: '${_elegidos.length} seleccionados',
                    extraColor: AppColors.primary,
                  ),
                  if (activos.isEmpty)
                    Text('No hay animales en el ganado', style: TextStyle(color: AppColors.textMuted))
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          todos ? _elegidos.clear() : _elegidos.addAll(activos.map((a) => a.codigo));
                        }),
                        icon: Icon(todos ? Icons.deselect : Icons.select_all, size: 18),
                        label: Text(todos ? 'Quitar todos' : 'Seleccionar todos'),
                      ),
                    ),
                  for (final a in activos)
                    CheckboxListTile(
                      value: _elegidos.contains(a.codigo),
                      onChanged: (v) => setState(() => v! ? _elegidos.add(a.codigo) : _elegidos.remove(a.codigo)),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      secondary: IconoEspecie(a.especie, size: 26, semanticLabel: a.nombreEspecie),
                      title: Text(
                        '${a.codigo}${a.nombre.isEmpty ? '' : ' • ${a.nombre}'}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${a.sexo} • ${a.raza} • ${a.arete == null ? 'Sin arete SINIIGA' : 'Arete ${a.arete}'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: a.arete == null ? AppColors.warning : AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El certificado reúne los datos del rancho y de los animales para el trámite. No sustituye la guía '
                    'de tránsito o el documento oficial que expide la autoridad ganadera.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _generando ? null : _generar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                _generando ? 'Generando…' : 'Generar certificado PDF',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
