import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show sqfliteFfiInit, databaseFactoryFfi;

import 'pages/animales_page.dart';
import 'pages/legal_page.dart';
import 'pages/movimientos_page.dart';
import 'pages/nueva_incidencia_page.dart';

class Rancho {
  const Rancho({
    this.nombre = 'Rancho San José',
    this.propietario = 'Don Juan Pérez',
    this.ubicacion = 'Veracruz, México',
    this.upp = 'VER-30-089-214',
    this.fierro = 'SJ - Reg. 842',
    this.capacidad = 30,
    this.fierroFoto,
  });

  final String nombre, propietario, ubicacion, upp, fierro;
  final int capacidad; // cabezas que soporta el potrero
  final String? fierroFoto; // ruta local de la imagen del fierro

  /// "Don Juan Pérez" -> "Don Juan", para el saludo.
  String get saludo => propietario.split(' ').take(2).join(' ');
}

final rancho = ValueNotifier(const Rancho());

/// Usuario con sesión abierta; null muestra la pantalla de login.
final usuarioActual = ValueNotifier<String?>(null);

/// Tipos de aviso de campo que el usuario quiere ver (ver notificaciones_page.dart). Por defecto, todos.
const tiposAviso = ['Vacunas', 'Aretado', 'Tratamientos', 'Pendientes'];
final avisosActivos = ValueNotifier<Set<String>>(tiposAviso.toSet());

late Database _db;

// Las escrituras van en cola para que nunca se mezclen dos reescrituras de la misma tabla.
var _cola = Future<void>.value();

/// Termina cuando todos los cambios pendientes ya están escritos en la base de datos.
Future<void> guardadoPendiente() => _cola;

// ---------- Base de datos ----------

Future<void> _crearTablas(Database db, int version) async {
  final b = db.batch();
  b.execute('CREATE TABLE config (clave TEXT PRIMARY KEY, valor TEXT)');
  b.execute('''CREATE TABLE rancho (
    id INTEGER PRIMARY KEY CHECK (id = 1), nombre TEXT NOT NULL, propietario TEXT NOT NULL,
    ubicacion TEXT, upp TEXT, fierro TEXT, capacidad INTEGER NOT NULL, fierro_foto TEXT)''');
  b.execute('''CREATE TABLE animales (
    codigo TEXT PRIMARY KEY, nombre TEXT, sexo TEXT, edad TEXT, raza TEXT, arete TEXT, ubicacion TEXT,
    color TEXT, nota TEXT, en_tratamiento INTEGER NOT NULL DEFAULT 0, foto TEXT,
    especie TEXT NOT NULL DEFAULT 'Bovino', documento TEXT)''');
  b.execute('''CREATE TABLE movimientos (
    folio TEXT PRIMARY KEY, tipo TEXT NOT NULL, fecha TEXT NOT NULL, animal_codigo TEXT NOT NULL,
    notas TEXT, origen_destino TEXT, monto REAL, guia TEXT, documento TEXT)''');
  b.execute('''CREATE TABLE incidencias (
    id INTEGER PRIMARY KEY AUTOINCREMENT, tipo TEXT NOT NULL, fecha TEXT NOT NULL, animal_codigo TEXT NOT NULL,
    accion TEXT NOT NULL, arete_nuevo TEXT, notas TEXT, detalle TEXT)''');
  b.execute('CREATE TABLE usuarios (usuario TEXT PRIMARY KEY, nombre TEXT NOT NULL, salt TEXT NOT NULL, hash TEXT NOT NULL)');
  await b.commit(noResult: true);
}

Map<String, Object?> _filaAnimal(Animal a) => {
      'codigo': a.codigo,
      'nombre': a.nombre,
      'sexo': a.sexo,
      'edad': a.edad,
      'raza': a.raza,
      'arete': a.arete,
      'ubicacion': a.ubicacion,
      'color': a.color,
      'nota': a.nota,
      'en_tratamiento': a.enTratamiento ? 1 : 0,
      'foto': a.foto,
      'especie': a.especie,
      'documento': a.documento,
    };

Animal _animalDeFila(Map<String, Object?> f) => Animal(
      f['codigo'] as String,
      f['nombre'] as String? ?? '',
      f['sexo'] as String? ?? '',
      f['edad'] as String? ?? '',
      f['raza'] as String? ?? '',
      f['arete'] as String?,
      f['ubicacion'] as String? ?? '',
      color: f['color'] as String? ?? '',
      nota: f['nota'] as String?,
      enTratamiento: f['en_tratamiento'] == 1,
      foto: f['foto'] as String?,
      especie: f['especie'] as String? ?? 'Bovino',
      documento: f['documento'] as String?,
    );

/// Reescribe la tabla completa dentro de una transacción.
// shortcut: reescribe todo en cada cambio (bien para cientos de animales); cambiar a insert/update por fila si crece a miles.
Future<void> _reescribir(String tabla, List<Map<String, Object?>> filas) => _db.transaction((t) async {
      await t.delete(tabla);
      for (final f in filas) {
        await t.insert(tabla, f);
      }
    });

Future<void> _guardarAnimales() => _reescribir('animales', animales.value.map(_filaAnimal).toList());

Future<void> _guardarMovimientos() => _reescribir('movimientos', [
      for (final m in movimientos.value)
        {
          'folio': m.folio,
          'tipo': m.tipo,
          'fecha': m.fecha.toIso8601String(),
          'animal_codigo': m.animal.codigo,
          'notas': m.notas,
          'origen_destino': m.origenDestino,
          'monto': m.monto,
          'guia': m.guia,
          'documento': m.documento,
        },
    ]);

Future<void> _guardarIncidencias() => _reescribir('incidencias', [
      for (final i in incidencias.value)
        {
          'tipo': i.tipo,
          'fecha': i.fecha.toIso8601String(),
          'animal_codigo': i.animal.codigo,
          'accion': i.accion,
          'arete_nuevo': i.areteNuevo,
          'notas': i.notas,
          'detalle': i.detalle,
        },
    ]);

Future<void> _guardarRancho() {
  final r = rancho.value;
  return _db.insert(
    'rancho',
    {
      'id': 1,
      'nombre': r.nombre,
      'propietario': r.propietario,
      'ubicacion': r.ubicacion,
      'upp': r.upp,
      'fierro': r.fierro,
      'capacidad': r.capacidad,
      'fierro_foto': r.fierroFoto,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<String?> _config(String clave) async =>
    (await _db.query('config', where: 'clave = ?', whereArgs: [clave])).firstOrNull?['valor'] as String?;

Future<void> _ponerConfig(String clave, String? valor) => valor == null
    ? _db.delete('config', where: 'clave = ?', whereArgs: [clave])
    : _db.insert('config', {'clave': clave, 'valor': valor}, conflictAlgorithm: ConflictAlgorithm.replace);

Future<void> _cargar() async {
  final r = (await _db.query('rancho')).firstOrNull;
  if (r != null) {
    rancho.value = Rancho(
      nombre: r['nombre'] as String,
      propietario: r['propietario'] as String,
      ubicacion: r['ubicacion'] as String? ?? '',
      upp: r['upp'] as String? ?? '',
      fierro: r['fierro'] as String? ?? '',
      capacidad: r['capacidad'] as int,
      fierroFoto: r['fierro_foto'] as String?,
    );
  }
  final lista = [for (final f in await _db.query('animales', orderBy: 'rowid')) _animalDeFila(f)];
  animales.value = lista;
  // Si un registro apunta a un animal que ya no existe, se conserva con un animal mínimo en vez de perderlo.
  Animal buscar(String codigo) => lista.where((a) => a.codigo == codigo).firstOrNull ??
      Animal(codigo, '', '', '', '', null, '', color: '');
  movimientos.value = [
    for (final f in await _db.query('movimientos', orderBy: 'rowid'))
      Movimiento(
        folio: f['folio'] as String,
        tipo: f['tipo'] as String,
        fecha: DateTime.parse(f['fecha'] as String),
        animal: buscar(f['animal_codigo'] as String),
        notas: f['notas'] as String? ?? '',
        origenDestino: f['origen_destino'] as String? ?? '',
        monto: (f['monto'] as num?)?.toDouble(),
        guia: f['guia'] as String? ?? '',
        documento: f['documento'] as String?,
      ),
  ];
  incidencias.value = [
    for (final f in await _db.query('incidencias', orderBy: 'id'))
      Incidencia(
        tipo: f['tipo'] as String,
        fecha: DateTime.parse(f['fecha'] as String),
        animal: buscar(f['animal_codigo'] as String),
        accion: f['accion'] as String,
        areteNuevo: f['arete_nuevo'] as String?,
        notas: f['notas'] as String? ?? '',
        detalle: f['detalle'] as String? ?? '',
      ),
  ];
  usuarioActual.value = await _config('sesion');
  final avisos = await _config('avisos'); // lista separada por comas; vacía = ninguno activo
  if (avisos != null) avisosActivos.value = avisos.split(',').where(tiposAviso.contains).toSet();
}

/// Abre la base de datos, la llena la primera vez y guarda cada cambio posterior.
/// [ruta] permite usar una base en memoria en las pruebas.
Future<void> iniciarDatos({String? ruta}) async {
  // Android/iOS usan el plugin nativo; Windows, Linux y macOS usan la versión FFI de SQLite.
  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  _db = await openDatabase(
    ruta ?? p.join(await getDatabasesPath(), 'vacatec.db'),
    version: 5,
    onCreate: _crearTablas,
    // v2: imagen del fierro del rancho. v3: especie de cada animal (los existentes son bovinos). v4: documento del animal.
    // v5: dato propio de cada incidencia (diagnóstico, causa…).
    onUpgrade: (db, anterior, _) async {
      if (anterior < 2) await db.execute('ALTER TABLE rancho ADD COLUMN fierro_foto TEXT');
      if (anterior < 3) await db.execute("ALTER TABLE animales ADD COLUMN especie TEXT NOT NULL DEFAULT 'Bovino'");
      if (anterior < 4) await db.execute('ALTER TABLE animales ADD COLUMN documento TEXT');
      if (anterior < 5) await db.execute('ALTER TABLE incidencias ADD COLUMN detalle TEXT');
    },
  );

  if (await _config('iniciado') == null) {
    await _migrarDesdePreferencias(); // datos guardados por la versión anterior de la app
    await _guardarRancho();
    await _guardarAnimales(); // los de ejemplo, o los migrados
    await _guardarMovimientos();
    await _guardarIncidencias();
    await _ponerConfig('iniciado', '1');
  }
  await _renombrarCodigosVG();
  await _cargar();

  void alCambiar(Listenable n, Future<void> Function() guardar) => n.addListener(() {
        _cola = _cola.then((_) => guardar()).catchError((e) => debugPrint('No se pudo guardar: $e'));
      });
  alCambiar(rancho, _guardarRancho);
  alCambiar(animales, _guardarAnimales);
  alCambiar(movimientos, _guardarMovimientos);
  alCambiar(incidencias, _guardarIncidencias);
  alCambiar(avisosActivos, () => _ponerConfig('avisos', avisosActivos.value.join(',')));
}

/// Los códigos internos pasaron de "VG-###" a "GV-###". Renombra los guardados con el formato anterior
/// (en animales y en lo que apunta a ellos). Si ya no hay ninguno, no cambia nada.
Future<void> _renombrarCodigosVG() => _db.transaction((t) async {
      await t.rawUpdate("UPDATE animales SET codigo = 'GV' || substr(codigo, 3) WHERE codigo LIKE 'VG-%'");
      for (final tabla in ['movimientos', 'incidencias']) {
        await t.rawUpdate(
            "UPDATE $tabla SET animal_codigo = 'GV' || substr(animal_codigo, 3) WHERE animal_codigo LIKE 'VG-%'");
      }
    });

// ---------- Migración desde la versión que guardaba en SharedPreferences ----------

Future<void> _migrarDesdePreferencias() async {
  final prefs = await SharedPreferences.getInstance();
  T? leer<T>(String clave, T Function(dynamic) deJson) {
    final s = prefs.getString(clave);
    if (s == null) return null;
    try {
      return deJson(jsonDecode(s));
    } catch (e) {
      debugPrint('No se pudo migrar "$clave": $e');
      return null;
    }
  }

  final r = leer('rancho', (j) => ranchoDeJson(j));
  if (r != null) rancho.value = r;
  final a = leer('animales', (j) => [for (final x in j) animalDeJson(x)]);
  if (a != null) animales.value = a;
  final m = leer('movimientos', (j) => [for (final x in j) movimientoDeJson(x)]);
  if (m != null) movimientos.value = m;
  final i = leer('incidencias', (j) => [for (final x in j) incidenciaDeJson(x)]);
  if (i != null) incidencias.value = i;
  for (final k in ['rancho', 'animales', 'movimientos', 'incidencias']) {
    await prefs.remove(k);
  }
}

Rancho ranchoDeJson(Map<String, dynamic> j) => Rancho(
      nombre: j['nombre'],
      propietario: j['propietario'],
      ubicacion: j['ubicacion'],
      upp: j['upp'],
      fierro: j['fierro'],
      capacidad: j['capacidad'],
    );

Animal animalDeJson(Map<String, dynamic> j) => Animal(
      j['codigo'],
      j['nombre'],
      j['sexo'],
      j['edad'],
      j['raza'],
      j['arete'],
      j['ubicacion'],
      color: j['color'],
      nota: j['nota'],
      enTratamiento: j['enTratamiento'],
      foto: j['foto'],
    );

Movimiento movimientoDeJson(Map<String, dynamic> j) => Movimiento(
      folio: j['folio'],
      tipo: j['tipo'],
      fecha: DateTime.parse(j['fecha']),
      animal: animalDeJson(j['animal']),
      notas: j['notas'],
      origenDestino: j['origenDestino'],
      monto: (j['monto'] as num?)?.toDouble(),
      guia: j['guia'],
      documento: j['documento'],
    );

Incidencia incidenciaDeJson(Map<String, dynamic> j) => Incidencia(
      tipo: j['tipo'],
      fecha: DateTime.parse(j['fecha']),
      animal: animalDeJson(j['animal']),
      accion: j['accion'],
      areteNuevo: j['areteNuevo'],
      notas: j['notas'],
    );

// ---------- Usuarios ----------

/// Contraseña con sal y 10 000 rondas de SHA-256: nunca se guarda en texto plano.
String _hash(String password, String salt) {
  List<int> d = utf8.encode('$salt:$password');
  for (var i = 0; i < 10000; i++) {
    d = sha256.convert(d).bytes;
  }
  return base64.encode(d);
}

Future<bool> hayUsuarios() async => Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM usuarios'))! > 0;

/// Crea un usuario y abre su sesión. Devuelve el mensaje de error, o null si salió bien.
Future<String?> registrar(String usuario, String nombre, String password) async {
  usuario = usuario.trim().toLowerCase();
  if (usuario.isEmpty || nombre.trim().isEmpty) return 'Escribe tu nombre y un usuario';
  if (password.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
  final salt = base64.encode(List.generate(16, (_) => Random.secure().nextInt(256)));
  try {
    await _db.insert('usuarios', {'usuario': usuario, 'nombre': nombre.trim(), 'salt': salt, 'hash': _hash(password, salt)});
  } on DatabaseException catch (e) {
    if (e.isUniqueConstraintError()) return 'Ese usuario ya existe';
    rethrow;
  }
  await _abrirSesion(usuario);
  return null;
}

/// Devuelve true si el usuario y la contraseña son correctos (y abre la sesión).
Future<bool> iniciarSesion(String usuario, String password) async {
  usuario = usuario.trim().toLowerCase();
  final f = (await _db.query('usuarios', where: 'usuario = ?', whereArgs: [usuario])).firstOrNull;
  if (f == null || _hash(password, f['salt'] as String) != f['hash']) return false;
  await _abrirSesion(usuario);
  return true;
}

Future<void> _abrirSesion(String usuario) async {
  await _ponerConfig('sesion', usuario);
  usuarioActual.value = usuario;
}

Future<void> cerrarSesion() async {
  await _ponerConfig('sesion', null);
  usuarioActual.value = null;
}

/// Los datos siguen siendo los de ejemplo de la primera instalación: mismos animales, sin movimientos ni incidencias.
bool get soloDatosDeEjemplo {
  String firma(List<Animal> l) => l.map((a) => '${a.codigo}|${a.nombre}|${a.arete}').join(',');
  return movimientos.value.isEmpty && incidencias.value.isEmpty && firma(animales.value) == firma(animalesEjemplo);
}

/// Primer registro: guarda los datos del rancho y la aceptación de los términos (fecha y versión).
/// Si el ganado sigue siendo el de ejemplo, la app empieza vacía; si ya hay datos reales, no se toca nada.
Future<void> iniciarRanchoNuevo(Rancho r) async {
  rancho.value = r;
  if (soloDatosDeEjemplo) animales.value = [];
  await _ponerConfig('terminos_aceptados', '${DateTime.now().toIso8601String()} (versión $versionLegal)');
  await guardadoPendiente();
}

/// Fecha y versión en que se aceptaron los términos y el aviso de privacidad, o null si no hay registro.
Future<String?> terminosAceptados() => _config('terminos_aceptados');
