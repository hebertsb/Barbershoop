import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final enrutadorApp = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (contexto, estado) => const _PantallaInicioProvisional(),
    ),
  ],
);

class _PantallaInicioProvisional extends StatelessWidget {
  const _PantallaInicioProvisional();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('BarberApp')),
    );
  }
}
