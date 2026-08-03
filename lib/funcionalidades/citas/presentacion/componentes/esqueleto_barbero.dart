import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'menu_mas_barbero.dart';

/// Bottom nav compartido entre las 4 pestaas del rol barbero (Inicio,
/// Agenda, Mis Insumos, Ms). No usa StatefulShellRoute (el shell de
/// admin/cliente ya causo varios bugs de router esta sesion) -- son 3 rutas
/// top-level normales navegadas con context.go(), cada una se refresca al
/// volver a visitarla (aceptable, son pantallas livianas); la 4ta pestaa
/// ("Ms") no navega, abre un modal con Mis Reseas y Mi Perfil -- mismo
/// patrn que "Ms" en el nav de administracin.
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
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Mis Insumos',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Ms',
          ),
        ],
      ),
    );
  }
}