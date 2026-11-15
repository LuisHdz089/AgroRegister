import 'package:flutter/material.dart';

import '../theme.dart';

/// Fecha de la versión vigente de los textos; cámbiala cuando los modifiques.
const versionLegal = '14/11/2026';

// shortcut: los datos entre corchetes los debe completar el responsable de la app (y conviene que un
// abogado revise ambos textos) antes de publicarla.
const terminosYCondiciones = <(String, String)>[
  (
    '1. Aceptación',
    'Al crear una cuenta y usar AgroRegister aceptas estos Términos y condiciones. Si no estás de acuerdo, '
        'no uses la aplicación.'
  ),
  (
    '2. Qué es AgroRegister',
    'AgroRegister es una herramienta para llevar el control interno de un rancho: registro de animales, '
        'movimientos, incidencias, reportes y documentos de apoyo.'
  ),
  (
    '3. No sustituye documentos oficiales',
    'Los códigos internos, reportes y certificados que genera la aplicación son de apoyo. No sustituyen el '
        'arete oficial SINIIGA, la guía de tránsito, el REEMO ni ningún documento que expida la autoridad '
        'ganadera o sanitaria. Cumplir con esos trámites es responsabilidad del usuario.'
  ),
  (
    '4. Responsabilidad sobre la información',
    'El usuario es responsable de que los datos que registra sean verdaderos y estén actualizados, y del uso '
        'que dé a los reportes y documentos que genere.'
  ),
  (
    '5. Cuenta y contraseña',
    'La cuenta y la contraseña son personales. Si las olvidas no hay forma de recuperarlas, porque la '
        'aplicación no se conecta a ningún servidor; en ese caso será necesario borrar los datos de la app.'
  ),
  (
    '6. Almacenamiento y respaldo',
    'Toda la información se guarda únicamente en este dispositivo. Desinstalar la aplicación, borrar sus datos '
        'o perder el dispositivo elimina la información. Se recomienda exportar periódicamente el padrón.'
  ),
  (
    '7. Limitación de responsabilidad',
    'La aplicación se ofrece "tal cual". [Nombre del responsable] no será responsable por pérdidas de '
        'información, sanciones o daños derivados del uso de la aplicación o de la información registrada.'
  ),
  (
    '8. Cambios',
    'Estos términos pueden actualizarse. La versión vigente estará siempre disponible en Perfil.'
  ),
  (
    '9. Contacto',
    'Para dudas sobre estos términos escribe a [correo de contacto].'
  ),
];

const avisoDePrivacidad = <(String, String)>[
  (
    'Responsable',
    '[Nombre del responsable], con domicilio en [domicilio], es responsable del tratamiento de los datos '
        'personales que se registran en AgroRegister, conforme a la legislación mexicana aplicable en materia '
        'de protección de datos personales.'
  ),
  (
    'Datos que se recaban',
    'Nombre del usuario y del propietario del rancho, usuario y contraseña (guardada cifrada), nombre y '
        'ubicación del rancho, registro UPP, fierro y su imagen, así como la información del ganado: '
        'fotografías, documentos, movimientos (incluidos montos de compra y venta), incidencias y datos de '
        'compradores, proveedores o destinos que el usuario capture.'
  ),
  (
    'Para qué se usan',
    'Exclusivamente para que la aplicación funcione: identificar al usuario, llevar el registro del ganado y '
        'generar reportes, el padrón y certificados de apoyo. No se usan con fines publicitarios.'
  ),
  (
    'Dónde se guardan',
    'Los datos se almacenan solo en este dispositivo. AgroRegister no los envía a ningún servidor ni los '
        'comparte con terceros. Solo salen del dispositivo cuando el usuario decide exportar o compartir un '
        'archivo (Excel, PDF o la ficha copiada).'
  ),
  (
    'Datos de terceros',
    'Si registras datos de otras personas (por ejemplo, compradores o proveedores), eres responsable de '
        'contar con su consentimiento para hacerlo.'
  ),
  (
    'Derechos ARCO',
    'Puedes acceder y rectificar tus datos directamente en la aplicación (consultando y editando los registros) '
        'y cancelarlos borrando los datos de la app; puedes oponerte a su tratamiento dejando de usarla. Para '
        'cualquier solicitud escribe a [correo de contacto].'
  ),
  (
    'Cambios al aviso',
    'Este aviso puede actualizarse. La versión vigente estará siempre disponible en Perfil.'
  ),
];

// Muestra los Términos y condiciones o el Aviso de privacidad (desde el registro y desde el Perfil).
class LegalPage extends StatelessWidget {
  const LegalPage.terminos({super.key})
      : titulo = 'Términos y condiciones',
        secciones = terminosYCondiciones;

  const LegalPage.privacidad({super.key})
      : titulo = 'Aviso de privacidad',
        secciones = avisoDePrivacidad;

  final String titulo;
  final List<(String, String)> secciones;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Última actualización: $versionLegal',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration:
                BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (encabezado, texto) in secciones) ...[
                  Text(encabezado,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text(texto, style: TextStyle(fontSize: 13, color: AppColors.text, height: 1.45)),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
