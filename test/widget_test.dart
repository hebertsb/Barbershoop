import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('la pantalla de inicio provisional muestra el nombre de la app',
      (WidgetTester tester) async {
    final enrutador = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (contexto, estado) => const Scaffold(
            body: Center(child: Text('BarberApp')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: enrutador));

    expect(find.text('BarberApp'), findsOneWidget);
  });
}
