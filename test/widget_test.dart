import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:vaca_tec/datos.dart';
import 'package:vaca_tec/main.dart';
import 'package:vaca_tec/foto.dart';
import 'package:vaca_tec/pages/animales_page.dart';
import 'package:vaca_tec/pages/certificado_page.dart';
import 'package:vaca_tec/pages/ficha_animal_page.dart';
import 'package:vaca_tec/pages/inicio_page.dart';
import 'package:vaca_tec/pages/movimientos_page.dart';
import 'package:vaca_tec/pages/notificaciones_page.dart';
import 'package:vaca_tec/pages/nueva_incidencia_page.dart';
import 'package:vaca_tec/pages/nuevo_animal_page.dart';
import 'package:vaca_tec/pages/reportes_page.dart';

void main() {
  // Las pruebas de pantallas entran con sesión abierta; las de login/base de datos (al final) la manejan solas.
  setUp(() => usuarioActual.value = 'prueba');

  testWidgets('la barra inferior cambia de página', (tester) async {
    await tester.pumpWidget(const MiGanadoApp());
    expect(find.text('Inicio'), findsNWidgets(2));
    expect(find.text('Buen día, Don Juan 👋'), findsOneWidget);

    for (final t in ['Animales', 'Movimientos', 'Reportes']) {
      await tester.tap(find.widgetWithText(NavigationDestination, t));
      await tester.pumpAndSettle();
      expect(find.text(t), findsNWidgets(2)); // encabezado + barra
    }
  });

  testWidgets('las tarjetas del resumen abren Animales con su filtro', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    expect(find.text('MI GANADO'), findsNothing);

    // Una búsqueda previa en Animales no debe esconder el resultado.
    await tester.tap(find.widgetWithText(NavigationDestination, 'Animales'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'rayo');
    await tester.tap(find.widgetWithText(NavigationDestination, 'Inicio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enfermos'));
    await tester.pumpAndSettle();
    expect(find.text('animales en rancho'), findsOneWidget); // está en Animales
    expect(find.text('GV-005'), findsOneWidget); // Mora, en tratamiento
    expect(find.text('GV-001'), findsNothing);
    expect(find.text('GV-002'), findsNothing);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Machos'));
    await tester.pumpAndSettle();
    expect(find.text('GV-002'), findsOneWidget);
    expect(find.text('GV-004'), findsOneWidget);
    expect(find.text('GV-001'), findsNothing); // Luna es hembra
    expect(find.text('GV-005'), findsNothing); // ya no filtra por tratamiento

    await tester.tap(find.widgetWithText(NavigationDestination, 'Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Total animales'));
    await tester.pumpAndSettle();
    for (final c in ['GV-001', 'GV-002', 'GV-003', 'GV-004', 'GV-005']) {
      expect(find.text(c), findsOneWidget);
    }
  });

  testWidgets('tocar el avatar abre el perfil', (tester) async {
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.bySemanticsLabel('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Rancho San José'), findsOneWidget);
    expect(find.text('Usuarios y personal'), findsNothing);
    expect(find.textContaining('Sincronización'), findsNothing);
    expect(find.text('Notificaciones de campo'), findsOneWidget);
  });

  test('avisos de campo: solo del ganado actual y según las preferencias', () {
    const sinArete = Animal('GV-1', 'A', 'Hembra', '3 años', 'Holstein', null, 'X', color: '', enTratamiento: true);
    const reciente = Animal('GV-2', 'B', 'Macho', '2 años', 'Angus', '22', 'X', color: '');
    const atrasada = Animal('GV-3', 'C', 'Hembra', '4 años', 'Jersey', '33', 'X', color: '');
    final hoy = DateTime(2026, 11, 13);
    final incs = [
      Incidencia(tipo: 'Tratamiento o vacuna', fecha: DateTime(2026, 10, 1), animal: reciente, accion: 'Vacunación'),
      Incidencia(tipo: 'Tratamiento o vacuna', fecha: DateTime(2025, 10, 1), animal: atrasada, accion: 'Vacunación'),
      Incidencia(tipo: 'Golpe o lesión', fecha: hoy, animal: sinArete, accion: 'En observación (pendiente)'),
    ];
    final todos = avisosDe([sinArete, reciente, atrasada], incs, hoy, tiposAviso.toSet());
    String de(Aviso a) => '${a.tipo}:${a.animal.codigo}';
    expect(todos.map(de).toSet(),
        {'Pendientes:GV-1', 'Tratamientos:GV-1', 'Aretado:GV-1', 'Vacunas:GV-1', 'Vacunas:GV-3'});
    expect(todos.firstWhere((a) => a.animal.codigo == 'GV-3').detalle, 'Última vacuna: 01/10/2025');
    expect(avisosDe([sinArete, reciente, atrasada], incs, hoy, {'Aretado'}).map(de), ['Aretado:GV-1']);
    expect(avisosDe([sinArete, reciente, atrasada], incs, hoy, {}), isEmpty);
  });

  testWidgets('la campana abre las notificaciones y se pueden apagar tipos de aviso', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      avisosActivos.value = tiposAviso.toSet();
    });
    await tester.pumpWidget(const MiGanadoApp());
    final total = avisosActuales().length;
    expect(total, greaterThan(0));
    expect(find.text('$total'), findsWidgets); // contador de la campana
    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pumpAndSettle();
    expect(find.text('$total avisos'), findsOneWidget);
    expect(find.text('Sin arete SINIIGA'), findsOneWidget); // Torito

    await tester.tap(find.text('Aretado'));
    await tester.pumpAndSettle();
    expect(find.text('Sin arete SINIIGA'), findsNothing);
    expect(find.text('${total - 1} avisos'), findsOneWidget);
    expect(avisosActivos.value.contains('Aretado'), isFalse);
  });

  testWidgets('animales: filtro por sexo y búsqueda', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Animales'));
    await tester.pumpAndSettle();
    expect(find.text('GV-002'), findsOneWidget);

    await tester.tap(find.text('Hembras (3)'));
    await tester.pump();
    expect(find.text('GV-001'), findsOneWidget);
    expect(find.text('GV-002'), findsNothing);

    await tester.tap(find.text('Todos (5)'));
    await tester.enterText(find.byType(TextField), 'rayo');
    await tester.pump();
    expect(find.text('GV-002'), findsOneWidget);
    expect(find.text('GV-001'), findsNothing);

    await tester.tap(find.text('GV-002'));
    await tester.pumpAndSettle();
    expect(find.text('Ficha De Animal'), findsOneWidget);
    expect(find.text('Historiales de Rayo'), findsOneWidget);
  });

  testWidgets('Agregar animal abre el registro desde Inicio y Animales', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.text('Agregar animal'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo Registro'), findsOneWidget);
    expect(find.text('GV-006'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Animales'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Agregar animal'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo Registro'), findsOneWidget);
  });

  testWidgets('movimiento desde la ficha aparece en la pestaña Movimientos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Movimientos'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay movimientos registrados'), findsOneWidget);

    // Guardar sin animal no registra nada.
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Registrar movimiento'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Selecciona un animal'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Animales'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GV-001'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Registrar movimiento'));
    await tester.tap(find.text('Registrar movimiento'));
    await tester.pumpAndSettle();
    expect(find.text('1 seleccionado'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '0.00'), '15000');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Movimientos'));
    await tester.pumpAndSettle();
    expect(find.text('Venta · GV-001 Luna'), findsOneWidget);
    expect(find.text('\$15000.00'), findsOneWidget);
  });

  testWidgets('Reportes se dibuja en pantalla de teléfono', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Reportes'));
    await tester.pumpAndSettle();
    expect(find.text('CENSO TOTAL'), findsOneWidget);
    expect(find.text('POR ESPECIE'), findsOneWidget);
    for (final e in ['Bovinos', 'Caballos', 'Borregos', 'Cerdos']) {
      expect(find.text(e), findsOneWidget); // las cuatro especies, aunque no haya animales
    }
    expect(find.textContaining('Hembras '), findsWidgets); // datos por especie
  });

  test('venta y traslado sacan al animal del ganado; compra y nacimiento no', () {
    const a = Animal('GV-1', 'A', 'Hembra', '3 años', 'Holstein', '1', 'X', color: '');
    Movimiento m(String tipo, int dia) => Movimiento(folio: 'M$dia', tipo: tipo, fecha: DateTime(2026, 1, dia), animal: a);
    expect(enHato(a, []), isTrue);
    expect(enHato(a, [m('Compra', 1), m('Nacimiento', 2)]), isTrue);
    expect(enHato(a, [m('Compra', 1), m('Venta', 2)]), isFalse);
    expect(salidaDe(a.codigo, [m('Traslado', 3)])!.tipo, 'Traslado');
  });

  // Depende de la prueba anterior de movimientos: Luna (GV-001) quedó vendida.
  testWidgets('un animal vendido queda atenuado y su ficha avisa que ya no forma parte del ganado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    expect(find.text('4'), findsWidgets); // Inicio: 5 animales, uno vendido
    await tester.tap(find.widgetWithText(NavigationDestination, 'Animales'));
    await tester.pumpAndSettle();
    expect(find.text('Vendido'), findsOneWidget);
    await tester.tap(find.text('GV-001'));
    await tester.pumpAndSettle();
    expect(find.text('Ya no forma parte del ganado'), findsOneWidget);
    expect(find.textContaining('Vendido el'), findsOneWidget);
    expect(find.text('Registrar movimiento'), findsNothing);
    expect(find.text('Reportar incidencia'), findsNothing);
    expect(find.text('Editar'), findsNothing);
  });

  testWidgets('el formulario de movimiento cambia con el tipo y da de alta o de baja', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Movimientos'));
    await tester.pumpAndSettle();
    Future<void> abrir(String tipo) async {
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Registrar movimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tipo).last);
      await tester.pumpAndSettle();
    }

    final total = animales.value.length;

    // Traslado: sin precio, destino obligatorio, y solo animales del ganado.
    await abrir('Traslado');
    expect(find.text('Precio de venta (\$)'), findsNothing);
    expect(find.text('Destino del traslado *'), findsOneWidget); // obligatorio
    await tester.tap(find.byType(DropdownButton<Animal>));
    await tester.pumpAndSettle();
    expect(find.text('GV-001 — Luna (Hembra, Holstein)'), findsNothing); // vendida
    await tester.tap(find.text('GV-004 — Torito (Macho, Mestizo)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Indica el destino del traslado'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Ej. Rancho El Roble, Potrero 5'), 'Rancho El Roble');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(salidaDe('GV-004')!.lugar, 'Rancho El Roble');
    expect(animales.value.length, total); // no se borra, solo sale del ganado

    // Compra: se capturan los datos del animal y se da de alta junto con el movimiento.
    await abrir('Compra');
    expect(find.text('Precio de compra (\$)'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Captura los datos del animal comprado'), findsOneWidget);
    await tester.tap(find.text('Capturar datos del animal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Ej. Sol, La Pinta, Trueno'), 'Pinta');
    await tester.tap(find.text('dd/mm/aaaa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar estos datos'));
    await tester.pumpAndSettle();
    expect(animales.value.length, total); // aún no se guarda
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final pinta = animales.value.last;
    expect([pinta.nombre, enHato(pinta), movimientos.value.last.tipo], ['Pinta', true, 'Compra']);

    // Nacimiento: sin precio ni guía; pide la cría y permite indicar la madre.
    await abrir('Nacimiento');
    expect(find.text('Madre'), findsOneWidget);
    expect(find.text('Fecha de nacimiento *'), findsOneWidget);
    expect(find.text('No. Guía / Folio'), findsNothing);
    expect(find.text('Datos de la operación'), findsNothing);
    await tester.tap(find.text('Capturar datos de la cría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Ej. Sol, La Pinta, Trueno'), 'Becerrito');
    await tester.tap(find.text('Usar estos datos')); // la fecha de nacimiento ya viene del movimiento
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final cria = animales.value.last;
    expect([cria.nombre, categoria(cria), movimientos.value.last.tipo], ['Becerrito', 'Cría', 'Nacimiento']);
    expect(animales.value.length, total + 2);
  });

  // Depende de la prueba anterior: usa a Pinta (compra) y Becerrito (nacimiento).
  testWidgets('incidencias: campos por tipo, tratamiento y baja por muerte', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final pinta = animales.value.firstWhere((a) => a.nombre == 'Pinta');
    final becerrito = animales.value.firstWhere((a) => a.nombre == 'Becerrito');
    await tester.pumpWidget(const MiGanadoApp());

    Future<void> abrir(Animal a, String tipo) async {
      await tester.tap(find.text('Reportar incidencia'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(tipo).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<Animal>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${a.codigo} - ${a.nombre} (${a.sexo}, ${a.raza})').last);
      await tester.pumpAndSettle();
    }

    // Enfermedad: diagnóstico obligatorio; "Tratamiento veterinario" marca al animal en tratamiento.
    await abrir(pinta, 'Enfermedad');
    expect(find.text('Nueva incidencia'), findsOneWidget);
    expect(find.textContaining('Modo campo'), findsNothing); // ya no hay franja de la nube
    expect(find.text('Diagnóstico o síntomas *'), findsOneWidget);
    expect(find.textContaining('Nuevo arete oficial'), findsNothing);
    await tester.tap(find.text('Guardar Incidencia'));
    await tester.pump();
    expect(find.text('Indica diagnóstico o síntomas'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Ej. Fiebre, tos y falta de apetito'), 'Fiebre');
    await tester.tap(find.text('Guardar Incidencia'));
    await tester.pumpAndSettle();
    expect(animales.value.firstWhere((a) => a.codigo == pinta.codigo).enTratamiento, isTrue);
    expect(incidencias.value.last.detalle, 'Fiebre');

    // Alta médica: le quita el "En tratamiento".
    await abrir(pinta, 'Tratamiento o vacuna');
    expect(find.text('Producto y dosis'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alta médica (fin de tratamiento)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar Incidencia'));
    await tester.pumpAndSettle();
    expect(animales.value.firstWhere((a) => a.codigo == pinta.codigo).enTratamiento, isFalse);

    // Muerte: sin acción que elegir, causa obligatoria, y el animal sale del ganado.
    await abrir(becerrito, 'Muerte');
    expect(find.text('Acción tomada *'), findsNothing);
    expect(find.text('Guardar y dar de baja'), findsOneWidget);
    expect(find.textContaining('saldrá del ganado'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Ej. Complicación en el parto'), 'Neumonía');
    await tester.tap(find.text('Guardar y dar de baja'));
    await tester.pumpAndSettle();
    final muerto = animales.value.firstWhere((a) => a.codigo == becerrito.codigo);
    expect(enHato(muerto), isFalse);
    expect(etiquetaSalida(muerto), 'Muerto');
    expect(salidaDe(muerto.codigo)!.lugar, 'Neumonía');
  });

  test('certificado de movilización: folio y PDF con los datos', () async {
    expect(folioCertificado(DateTime(2026, 3, 7, 9, 5)), 'CM-20260307-0905');
    const a = Animal('GV-77', 'Lucero', 'Hembra', '3 años', 'Holstein', '4455', 'X', color: 'Pinta');
    const b = Animal('GV-78', 'Trueno', 'Macho', '2 años', 'Cuarto de Milla', null, 'X', color: '', especie: 'Equino');
    final datos = (
      folio: 'CM-1',
      animales: [a, b],
      destino: 'Rancho El Roble',
      motivo: 'Venta',
      fecha: DateTime(2026, 3, 7),
      transporte: 'Placas XA-1234',
    );
    // Imagen del fierro dañada: el PDF se genera igual, sin ella.
    final roto = File('${Directory.systemTemp.createTempSync('vacatec_cert').path}/fierro.png')
      ..writeAsBytesSync([1, 2, 3]);
    final pdf = await certificadoPdf(datos, Rancho(nombre: 'Los Cocos', upp: 'VER-1', fierroFoto: roto.path),
        comprimir: false);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    final texto = latin1.decode(pdf, allowInvalid: true);
    // El PDF dibuja cada palabra por separado: se buscan palabras, no frases.
    for (final t in ['Cocos', 'VER-1', 'Roble', 'GV-77', 'GV-78', '4455', 'XA-1234', 'Caballo', 'trámite']) {
      expect(texto, contains(t), reason: t);
    }
    // Normal (comprimido), sin imagen del fierro.
    expect((await certificadoPdf(datos, const Rancho())).take(5), '%PDF-'.codeUnits);
  });

  // Depende de las pruebas anteriores: Luna está vendida y Becerrito murió.
  testWidgets('el certificado se abre desde Reportes y solo lista el ganado actual', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Animales'));
    await tester.pumpAndSettle();
    expect(find.text('Modo Campo'), findsNothing);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Reportes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Certificado Oficial de Movilización'));
    await tester.tap(find.text('Certificado Oficial de Movilización'));
    await tester.pumpAndSettle();
    expect(find.text('Certificado de movilización'), findsOneWidget);
    expect(find.textContaining('GV-001'), findsNothing); // vendida
    expect(find.textContaining('Becerrito'), findsNothing); // murió

    await tester.ensureVisible(find.text('Generar certificado PDF'));
    await tester.tap(find.text('Generar certificado PDF'));
    await tester.pump();
    expect(find.text('Selecciona al menos un animal'), findsOneWidget);

    await tester.tap(find.text('Seleccionar todos'));
    await tester.pump();
    final n = animales.value.where(enHato).length;
    expect(find.text('$n seleccionados'), findsOneWidget);
    await tester.tap(find.text('Generar certificado PDF'));
    await tester.pump();
    expect(find.text('Indica el destino'), findsOneWidget);
  });

  test('ResumenHato calcula las cifras del reporte', () {
    const vaca = Animal('GV-1', 'A', 'Hembra', '3 años', 'Holstein', '1', 'X', color: '');
    const toro = Animal('GV-2', 'B', 'Macho', '2 años', 'Angus', null, 'X', color: '');
    const cria = Animal('GV-3', 'C', 'Hembra', '6 meses', 'Jersey', '3', 'X', color: '', enTratamiento: true);
    const novillo = Animal('GV-4', 'D', 'Macho', '2 años', 'Angus', null, 'X', color: '');
    final hoy = DateTime(2026, 11, 8);
    final r = ResumenHato([vaca, toro, cria, novillo], [
      Movimiento(folio: 'M1', tipo: 'Venta', fecha: DateTime(2026, 11, 2), animal: toro),
      Movimiento(folio: 'M2', tipo: 'Venta', fecha: DateTime(2026, 11, 3), animal: toro), // misma baja
      Movimiento(folio: 'M3', tipo: 'Compra', fecha: DateTime(2026, 11, 4), animal: vaca),
      Movimiento(folio: 'M4', tipo: 'Compra', fecha: DateTime(2026, 10, 30), animal: vaca), // otro mes
      Movimiento(folio: 'M5', tipo: 'Traslado', fecha: DateTime(2026, 9, 1), animal: novillo), // otro mes
    ], periodoDelMes(hoy));

    // El toro (vendido) y el novillo (trasladado) ya no cuentan en el ganado.
    expect([r.registrados, r.total, r.ordeno, r.engorda, r.crias], [4, 2, 1, 0, 1]);
    expect([r.hembras, r.machos, r.pct(r.hembras)], [2, 0, 100]);
    expect([r.bajas, r.activos, r.pctActivos], [2, 2, '50.0%']);
    expect(r.delPeriodo.length, 3);
    expect(r.desglose, '2 ventas, 1 compra');
    expect([r.pendientes, r.desglosePendientes], [1, '1 tratamiento']); // los sin arete que salieron no cuentan

    final vacio = ResumenHato([], [], periodoDelMes(hoy));
    expect([vacio.pct(0), vacio.pctActivos, vacio.desglose], [0, '0%', 'Sin movimientos en el periodo']);
  });

  test('edadDesde', () {
    expect(edadDesde(DateTime(2024, 2, 15), DateTime(2026, 11, 15)), '2 años 9 m');
    expect(edadDesde(DateTime(2024, 2, 15), DateTime(2026, 11, 14)), '2 años 8 m');
    expect(edadDesde(DateTime(2025, 11, 1), DateTime(2026, 11, 1)), '1 año');
    expect(edadDesde(DateTime(2026, 5, 1), DateTime(2026, 11, 8)), '6 meses');
    expect(edadDesde(DateTime(2026, 11, 1), DateTime(2026, 11, 8)), '0 meses');
  });

  testWidgets('incidencia desde Inicio reemplaza el arete y cuenta como atendida', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.text('Reportar incidencia'));
    await tester.pumpAndSettle();
    expect(find.text('Guardar Incidencia'), findsOneWidget);

    await tester.tap(find.text('Guardar Incidencia'));
    await tester.pump();
    expect(find.text('Selecciona el animal afectado'), findsOneWidget);
    expect(incidencias.value.where((i) => i.animal.codigo == 'GV-002'), isEmpty); // no se guardó nada

    await tester.tap(find.byType(DropdownButton<Animal>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GV-002 - Rayo (Macho, Pardo Suizo)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Ej. 2890-B'), '2890-B');
    await tester.tap(find.text('Guardar Incidencia'));
    await tester.pumpAndSettle();

    expect(incidencias.value.last.atendida, isTrue);
    expect(animales.value.firstWhere((a) => a.codigo == 'GV-002').arete, '2890-B');
    expect(find.text('Buen día, Don Juan 👋'), findsOneWidget); // volvió a Inicio
  });

  // Depende de las pruebas anteriores: Luna tiene una venta y Rayo una incidencia.
  testWidgets('historial del animal muestra sus movimientos e incidencias', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Animales'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GV-002'));
    await tester.pumpAndSettle();
    expect(find.text('Pérdida de arete'), findsOneWidget); // último evento en la ficha
    expect(find.text('0 reg.'), findsOneWidget);

    await tester.ensureVisible(find.text('Historial de movimientos'));
    await tester.tap(find.text('Historial de movimientos'));
    await tester.pumpAndSettle();
    expect(find.text('Sin movimientos registrados'), findsOneWidget);
    await tester.tap(find.text('Incidencias (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Pérdida de arete'), findsOneWidget);
    expect(find.text('Atendida'), findsOneWidget);
    expect(find.textContaining('Nuevo arete: 2890-B'), findsOneWidget);

    // Luna: la venta aparece en su línea de tiempo.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('GV-001'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Historial de movimientos'));
    await tester.tap(find.text('Historial de movimientos'));
    await tester.pumpAndSettle();
    expect(find.text('Venta definitiva'), findsOneWidget);
    expect(find.text('Egreso'), findsOneWidget);

    await tester.tap(find.textContaining('Incidencias ('));
    await tester.pumpAndSettle();
    expect(find.text('Añadir Nueva Incidencia'), findsOneWidget);
  });

  test('periodo por defecto y fechas dentro del periodo (ambos extremos incluidos)', () {
    final p = periodoDelMes(DateTime(2026, 11, 11, 15, 30));
    expect([p.start, p.end], [DateTime(2026, 11, 1), DateTime(2026, 11, 11)]);
    expect(enPeriodo(DateTime(2026, 11, 1), p), isTrue);
    expect(enPeriodo(DateTime(2026, 11, 11, 23, 59), p), isTrue); // todo el último día cuenta
    expect(enPeriodo(DateTime(2026, 10, 31, 23, 59), p), isFalse);
    expect(enPeriodo(DateTime(2026, 11, 12), p), isFalse);
    final enero = periodoDelMes(DateTime(2027, 1, 1));
    expect([enero.start, enero.end], [DateTime(2027, 1, 1), DateTime(2027, 1, 1)]);
  });

  testWidgets('Resumen del periodo se abre desde Reportes y "Ver inventario" lleva a Animales', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Reportes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver desglose'));
    await tester.pumpAndSettle();
    expect(find.text('Resumen del Hato'), findsOneWidget);
    final p = periodoDelMes(DateTime.now());
    expect(find.text('${fechaCorta(p.start)}  –  ${fechaCorta(p.end)}'), findsOneWidget);
    expect(find.text('Distribución General'), findsOneWidget);

    await tester.tap(find.text('Ver inventario'));
    await tester.pumpAndSettle();
    expect(find.text('animales en rancho'), findsOneWidget);
  });

  testWidgets('tarjeta de Inicio abre la ficha del animal', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    final a = inspeccionReciente(2).first; // depende de la actividad de las pruebas anteriores
    await tester.tap(find.text('${a.codigo} · ${a.nombre}'));
    await tester.pumpAndSettle();
    expect(find.text('Ficha De Animal'), findsOneWidget);
    expect(find.text('Historiales de ${a.nombre}'), findsOneWidget);
  });

  testWidgets('registrar un caballo: razas de su especie y filtro por especie', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Animales'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Agregar animal'));
    await tester.pumpAndSettle();
    expect(find.text('Holstein (Lechera)'), findsOneWidget); // por defecto, bovino

    await tester.tap(find.text('Caballo'));
    await tester.pumpAndSettle();
    expect(find.text('Cuarto de Milla'), findsOneWidget); // la raza cambia con la especie
    expect(find.text('Holstein (Lechera)'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Ej. Sol, La Pinta, Trueno'), 'Relámpago');
    await tester.tap(find.text('dd/mm/aaaa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar animal'));
    await tester.pumpAndSettle();
    final caballo = animales.value.last;
    expect([caballo.nombre, caballo.especie, caballo.raza], ['Relámpago', 'Equino', 'Cuarto de Milla']);
    expect(categoria(caballo), 'Cría');

    await tester.ensureVisible(find.text('Caballos (1)')); // la fila de especies se desplaza de lado
    await tester.tap(find.text('Caballos (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Relámpago'), findsOneWidget);
    expect(find.text('Luna'), findsNothing);
    expect(find.text('Todos (1)'), findsOneWidget); // los conteos por sexo son de la especie elegida
  });

  testWidgets('la ficha muestra el documento del animal y permite abrirlo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sinDoc = Animal('GV-901', 'Sin', 'Hembra', '2 años', 'Jersey', '1', 'X', color: '');
    await tester.pumpWidget(const MaterialApp(home: FichaAnimalPage(sinDoc)));
    expect(find.text('Sin documento (agrégalo con Editar)'), findsOneWidget);
    expect(find.text('Abrir'), findsNothing);

    const conDoc = Animal('GV-902', 'Con', 'Hembra', '2 años', 'Jersey', '1', 'X',
        color: '', documento: 'C:/docs/1731400000000_certificado.pdf');
    await tester.pumpWidget(const MaterialApp(home: FichaAnimalPage(conDoc)));
    expect(find.text('certificado.pdf'), findsOneWidget); // sin la marca de tiempo de la copia
    expect(find.text('Abrir'), findsOneWidget);
  });

  test('nombre del documento sin la marca de tiempo de la copia', () {
    expect(nombreDocumento('/a/b/1731400000000_factura 2024.pdf'), 'factura 2024.pdf');
    expect(nombreDocumento('/a/b/guia.pdf'), 'guia.pdf');
    expect(nombreDocumento('/a/b/2024_ventas.xlsx'), '2024_ventas.xlsx'); // solo quita la marca de la copia
    expect(nombreDocumento('/a/b/1731400000000_2024_ventas.xlsx'), '2024_ventas.xlsx');
  });

  testWidgets('editar un animal desde su ficha conserva su código', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Animales'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GV-003'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar Registro'), findsOneWidget);
    expect(find.text('GV-003'), findsOneWidget); // el código no cambia

    await tester.enterText(find.widgetWithText(TextField, 'Estrella'), 'Estrellita');
    await tester.ensureVisible(find.text('Guardar animal'));
    await tester.tap(find.text('Guardar animal'));
    await tester.pumpAndSettle();
    final a = animales.value.firstWhere((x) => x.codigo == 'GV-003');
    expect([a.nombre, a.edad, a.raza], ['Estrellita', '1 año', 'Jersey']);
    expect(animales.value.where((x) => x.codigo == 'GV-003'), hasLength(1));
  });

  testWidgets('datos del rancho editables desde el perfil', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      rancho.value = const Rancho();
    });
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.bySemanticsLabel('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Datos del rancho'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '30'), '0');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('La capacidad debe ser un número mayor a 0'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Rancho San José'), 'Rancho El Roble');
    await tester.enterText(find.widgetWithText(TextField, 'Don Juan Pérez'), 'Doña Ana López');
    await tester.enterText(find.widgetWithText(TextField, '0'), '40');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Rancho El Roble'), findsOneWidget); // tarjeta del perfil
    expect(rancho.value.capacidad, 40);
    expect(rancho.value.saludo, 'Doña Ana');
  });

  test('padrón en Excel: una hoja "Padrón" con encabezado y una fila por animal', () {
    const a = Animal('GV-9', 'Luna', 'Macho', '2 años', 'Angus', null, 'X', color: 'Negro');
    const b = Animal('GV-10', 'Mora', 'Hembra', '6 meses', 'Duroc', '77', 'Y',
        color: '', enTratamiento: true, especie: 'Porcino');
    // Se vuelve a abrir el archivo generado, como lo haría Excel.
    final libro = Excel.decodeBytes(padronExcel([a, b]));
    expect(libro.tables.keys, ['Padrón']);
    final filas = [
      for (final f in libro.tables['Padrón']!.rows) [for (final c in f) c?.value.toString()],
    ];
    expect(filas, hasLength(3));
    expect(filas[0].first, 'Código');
    expect(filas[1], ['GV-9', 'Luna', 'Bovino', 'Macho', '2 años', 'Angus', 'Negro', 'En trámite', 'X', 'Engorda', 'Activo']);
    expect([filas[2][0], filas[2][2], filas[2][7], filas[2][9], filas[2][10]], ['GV-10', 'Cerdo', '77', 'Cría', 'En tratamiento']);
  });

  // ---- Base de datos y login. Van al final y en este orden: enlazan los datos globales con una base real. ----
  final ruta = '${Directory.systemTemp.createTempSync('vacatec').path}/prueba.db';

  test('base de datos: migra lo de la versión anterior, guarda cada cambio y lo recarga', () async {
    // Datos que dejó la versión que guardaba en SharedPreferences; uno está dañado.
    SharedPreferences.setMockInitialValues({
      'flutter.rancho': jsonEncode({
        'nombre': 'Migrado',
        'propietario': 'Ana López',
        'ubicacion': '',
        'upp': '',
        'fierro': '',
        'capacidad': 12,
      }),
      'flutter.animales': '{dañado',
    });
    final codigosAntes = animales.value.map((a) => a.codigo).toList();
    await iniciarDatos(ruta: ruta);
    expect([rancho.value.nombre, rancho.value.capacidad], ['Migrado', 12]);
    expect(animales.value.map((a) => a.codigo), codigosAntes); // el dato dañado no borra los animales
    expect((await SharedPreferences.getInstance()).getString('rancho'), isNull); // ya se pasó a la base

    final nuevo = animales.value.first.copyWith(arete: 'X-1');
    actualizarAnimal(nuevo);
    movimientos.value = [
      Movimiento(folio: 'MOV-9', tipo: 'Compra', fecha: DateTime(2026, 1, 2), animal: nuevo, monto: 10),
    ];
    incidencias.value = [
      Incidencia(tipo: 'Enfermedad', fecha: DateTime(2026, 1, 3), animal: nuevo, accion: 'Curación en campo'),
    ];
    await guardadoPendiente();

    // Se lee el archivo directamente: los cambios están en sus tablas.
    final db = await databaseFactoryFfi.openDatabase(ruta, options: OpenDatabaseOptions(singleInstance: false));
    expect((await db.query('animales', where: 'codigo = ?', whereArgs: [nuevo.codigo])).single['arete'], 'X-1');
    expect((await db.query('animales')).length, codigosAntes.length);
    final mov = (await db.query('movimientos')).single;
    expect([mov['folio'], mov['animal_codigo'], mov['monto']], ['MOV-9', nuevo.codigo, 10.0]);
    expect((await db.query('incidencias')).single['accion'], 'Curación en campo');
    expect((await db.query('rancho')).single['nombre'], 'Migrado');
    await db.close();

    // Al reabrir la app se recarga lo mismo, ligado al animal por su código.
    await iniciarDatos(ruta: ruta);
    expect(movimientos.value.single.animal.arete, 'X-1');
    expect(incidencias.value.single.fecha, DateTime(2026, 1, 3));
  });

  test('usuarios: registro, contraseña cifrada, inicio y cierre de sesión', () async {
    usuarioActual.value = null;
    expect(await hayUsuarios(), isFalse);
    expect(await registrar('juan', 'Juan', '123'), 'La contraseña debe tener al menos 6 caracteres');
    expect(await registrar('Juan ', 'Juan Pérez', 'secreta1'), isNull);
    expect(usuarioActual.value, 'juan');
    expect(await registrar('JUAN', 'Otro', 'secreta2'), 'Ese usuario ya existe');

    final db = await databaseFactoryFfi.openDatabase(ruta, options: OpenDatabaseOptions(singleInstance: false));
    final fila = (await db.query('usuarios')).single;
    expect(fila['hash'], isNot(contains('secreta1')));
    await db.close();

    await cerrarSesion();
    expect(usuarioActual.value, isNull);
    expect(await iniciarSesion('juan', 'incorrecta'), isFalse);
    expect(await iniciarSesion('otro', 'secreta1'), isFalse);
    expect(await iniciarSesion(' JUAN ', 'secreta1'), isTrue);
    expect(usuarioActual.value, 'juan');
    await cerrarSesion();
  });

  testWidgets('sin sesión se muestra el login y con la contraseña correcta entra a la app', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    usuarioActual.value = null;
    // La base de datos es real: se le da tiempo real a cada operación.
    Future<void> esperar() async {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(const MiGanadoApp());
    await esperar();
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Crea tu cuenta'), findsNothing); // ya hay un usuario: no se puede registrar otro aquí

    await tester.enterText(find.widgetWithText(TextField, 'Ej. juan'), 'juan');
    await tester.enterText(find.widgetWithText(TextField, 'Tu contraseña'), 'incorrecta');
    await tester.tap(find.text('Iniciar sesión'));
    await esperar();
    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Tu contraseña'), 'secreta1');
    await tester.tap(find.text('Iniciar sesión'));
    await esperar();
    expect(find.textContaining('Buen día'), findsOneWidget);
  });

  test('una base de la versión 1 se actualiza y guarda la imagen del fierro', () async {
    // Base como la dejó la versión anterior: sin la columna fierro_foto.
    final rutaV1 = '${Directory.systemTemp.createTempSync('vacatec_v1').path}/v1.db';
    final v1 = await databaseFactoryFfi.openDatabase(rutaV1, options: OpenDatabaseOptions(singleInstance: false));
    await v1.execute('CREATE TABLE config (clave TEXT PRIMARY KEY, valor TEXT)');
    await v1.execute('''CREATE TABLE rancho (id INTEGER PRIMARY KEY CHECK (id = 1), nombre TEXT NOT NULL,
        propietario TEXT NOT NULL, ubicacion TEXT, upp TEXT, fierro TEXT, capacidad INTEGER NOT NULL)''');
    for (final t in ['animales (codigo TEXT PRIMARY KEY, nombre TEXT, sexo TEXT, edad TEXT, raza TEXT, arete TEXT, '
        'ubicacion TEXT, color TEXT, nota TEXT, en_tratamiento INTEGER NOT NULL DEFAULT 0, foto TEXT)',
        'movimientos (folio TEXT PRIMARY KEY, tipo TEXT, fecha TEXT, animal_codigo TEXT, notas TEXT, '
            'origen_destino TEXT, monto REAL, guia TEXT, documento TEXT)',
        'incidencias (id INTEGER PRIMARY KEY AUTOINCREMENT, tipo TEXT, fecha TEXT, animal_codigo TEXT, accion TEXT, '
            'arete_nuevo TEXT, notas TEXT)',
        'usuarios (usuario TEXT PRIMARY KEY, nombre TEXT, salt TEXT, hash TEXT)']) {
      await v1.execute('CREATE TABLE $t');
    }
    await v1.insert('rancho', {'id': 1, 'nombre': 'Viejo', 'propietario': 'Ana', 'fierro': 'AV-1', 'capacidad': 5});
    // Animal con el formato de código anterior (VG) y un movimiento que apunta a él.
    await v1.insert('animales', {'codigo': 'VG-007', 'nombre': 'Canela', 'sexo': 'Hembra', 'en_tratamiento': 0});
    await v1.insert('movimientos',
        {'folio': 'MOV-1', 'tipo': 'Compra', 'fecha': '2026-01-05T00:00:00.000', 'animal_codigo': 'VG-007'});
    await v1.insert('config', {'clave': 'iniciado', 'valor': '1'});
    await v1.setVersion(1);
    await v1.close();

    await iniciarDatos(ruta: rutaV1);
    expect([rancho.value.nombre, rancho.value.fierroFoto], ['Viejo', null]); // los datos viejos siguen ahí
    expect(animales.value.single.codigo, 'GV-007'); // VG pasa a GV
    expect(animales.value.single.especie, 'Bovino'); // v3: los que ya existían son bovinos
    expect([movimientos.value.single.animal.codigo, movimientos.value.single.animal.nombre], ['GV-007', 'Canela']);

    rancho.value = Rancho(nombre: 'Viejo', propietario: 'Ana', fierro: 'AV-1', capacidad: 5, fierroFoto: 'C:/fierro.png');
    await guardadoPendiente();
    final db = await databaseFactoryFfi.openDatabase(rutaV1, options: OpenDatabaseOptions(singleInstance: false));
    expect(await db.getVersion(), 5);
    expect((await db.query('animales')).single.containsKey('documento'), isTrue); // v4
    expect((await db.query('rancho')).single['fierro_foto'], 'C:/fierro.png');
    await db.close();
    rancho.value = const Rancho();
  });
}
