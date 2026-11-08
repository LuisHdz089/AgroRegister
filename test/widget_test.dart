import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vaca_tec/main.dart';

void main() {
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

  testWidgets('tocar el avatar abre el perfil', (tester) async {
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.bySemanticsLabel('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Rancho San José'), findsOneWidget);
  });

  testWidgets('animales: filtro por sexo y búsqueda', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MiGanadoApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Animales'));
    await tester.pumpAndSettle();
    expect(find.text('VG-002'), findsOneWidget);

    await tester.tap(find.text('Hembras (3)'));
    await tester.pump();
    expect(find.text('VG-001'), findsOneWidget);
    expect(find.text('VG-002'), findsNothing);

    await tester.tap(find.text('Todos (5)'));
    await tester.enterText(find.byType(TextField), 'rayo');
    await tester.pump();
    expect(find.text('VG-002'), findsOneWidget);
    expect(find.text('VG-001'), findsNothing);
  });
}
