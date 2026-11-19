# AgroRegister

Aplicación móvil para llevar el control del ganado de un rancho desde el teléfono, sin internet.

## ¿Para qué sirve?

Reemplaza la libreta del rancho. Con ella el ganadero puede:

- saber cuántos animales tiene hoy y de qué especie y categoría;
- registrar compras, ventas, traslados y nacimientos;
- registrar vacunas, tratamientos y bajas;
- tener a la mano el padrón y el certificado de movilización para trámites;
- recibir avisos de lo que está pendiente: vacunas, aretes, tratamientos e incidencias.

## Funciones

| Sección | Qué hace |
| --- | --- |
| **Inicio** | Saludo, resumen del hato y accesos rápidos para registrar animales, movimientos e incidencias. |
| **Animales** | Bovinos, equinos, ovinos y porcinos. Cada uno con foto, arete SINIIGA, raza, documento adjunto y ficha con historial. Se pueden filtrar por especie, sexo o tratamiento. |
| **Movimientos** | Compra y nacimiento dan de alta al animal; venta y traslado lo sacan del hato. El formulario cambia según el tipo. |
| **Incidencias** | Vacunación, tratamiento, alta médica, cambio de arete, muerte, robo o extravío. Las de muerte y robo dan de baja al animal. |
| **Reportes** | Censo total y por especie, resumen entre dos fechas, padrón en Excel (`.xlsx`) y certificado de movilización en PDF. |
| **Avisos** | Campana con los avisos sin leer, que se marcan como leídos al verlos. En Android también llegan como notificaciones del teléfono. |
| **Perfil** | Datos del rancho y del fierro, tipos de aviso, ayuda, términos y aviso de privacidad, y cerrar sesión. |

Además:

- la cuenta del rancho se crea al registrarse y se inicia sesión de forma local;
- tema claro u oscuro según el dispositivo;
- todos los datos se guardan en el teléfono.

## Stack

- **Lenguaje:** [Flutter](https://flutter.dev) 3.47 / Dart 3.13, con Material 3.
- **Base de datos:** SQLite con `sqflite` (`sqflite_common_ffi` en escritorio y pruebas).
- **Contraseñas:** hash SHA-256 con sal (`crypto`).
- **Archivos:**
  - `excel` para el padrón;
  - `pdf` para el certificado;
  - `file_picker` para guardar archivos;
  - `image_picker` para fotos.
- **Android nativo (Kotlin):** notificaciones, apertura de documentos (FileProvider) y barra de navegación oculta.
- **iOS:** se compila en GitHub Actions (macOS).

## Instalación

### Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47 o superior.
- Android Studio con el SDK de Android, o un teléfono Android con la depuración USB activada.

Para comprobar que todo está bien:

```bash
flutter doctor
```

### Pasos

1. Clona el repositorio y entra a la carpeta:

   ```bash
   git clone https://github.com/LuisHdz089/VacaTec.git
   cd VacaTec
   ```

2. Instala las dependencias:

   ```bash
   flutter pub get
   ```

3. Conecta el teléfono (o abre un emulador) y ejecuta:

   ```bash
   flutter run
   ```

### Instalar en un teléfono Android (APK)

Genera el APK:

```bash
flutter build apk --release
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`. Cópialo al teléfono y ábrelo para instalarlo.

### iOS

Cada push a `main` compila la app sin firmar con GitHub Actions (`.github/workflows/ios.yml`). El `.ipa` se descarga desde los artefactos del workflow y se instala con una herramienta de firmado como Sideloadly o AltStore.

## Pruebas

```bash
flutter test
```

## Primer uso

1. Abre la app y elige **Crear cuenta**.
2. Llena los datos del rancho y acepta los términos.
3. La app empieza vacía: registra tu primer animal desde **Inicio → Agregar animal**.
