import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'menu_mas_barbero.dart';

class EsqueletoBarbero extends StatelessWidget {
  const EsqueletoBarbero({
    super.key,
    required this.indice,
    required this.child,
  });

  final int indice;
  final Widget child;

  static const _rutas = ['/', '/mi-agenda', '/mis-insumos'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: (nuevoIndice) {
          if (nuevoIndice == 3) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const MenuMasBarbero(),
            );
            return;
          }
          if (nuevoIndice == indice) return;
          context.go(_rutas[nuevoIndice]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Insumos',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}