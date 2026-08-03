import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../funcionalidades/administracion/datos/repositorio_accesos_admin.dart';
import '../../funcionalidades/administracion/dominio/catalogo_accesos_admin.dart';
import '../configuracion/colores_app.dart';
import '../configuracion/tipografia_app.dart';

/// Sidebar fijo para admin/superadmin en pantalla ancha (>= 840dp):
/// reemplaza tanto la barra inferior como el men "Ms" -- muestra los 3
/// accesos fijos de siempre arriba (Inicio, Agenda, Reportes) y TODAS las
/// secciones de `catalogoAccesosAdmin` agrupadas por categora abajo, sin
/// nada oculto detrs de un modal. Reutiliza el mismo catlogo que ya usan
/// el "Acceso Rpido" rotativo y el men "Ms" en pantalla angosta -- cero
/// datos duplicados.
class SidebarAdministracion extends ConsumerWidget {
  const SidebarAdministracion({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _irA(BuildContext context, WidgetRef ref, String ruta) {
    ref.read(repositorioAccesosAdminProvider).registrarAcceso(ruta);
    context.push(ruta);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final rutaActual = GoRouterState.of(context).uri.path;
    final grupos = agruparAccesosPorCategoria(catalogoAccesosAdmin);

    return Container(
      width: 220,
      color: colorScheme.surfaceContainer,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'BarberApp',
                style: TipografiaApp.headlineSm.copyWith(
                  color: ColoresApp.primario,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _ItemSidebar(
              icono: Icons.home_max_outlined,
              titulo: 'Inicio',
              activo: navigationShell.currentIndex == 0,
              onTap: () => navigationShell.goBranch(0),
            ),
            _ItemSidebar(
              icono: Icons.calendar_today_outlined,
              titulo: 'Agenda',
              activo: navigationShell.currentIndex == 1,
              onTap: () => navigationShell.goBranch(1),
            ),
            _ItemSidebar(
              icono: Icons.analytics_outlined,
              titulo: 'Reportes',
              activo: rutaActual == '/administracion/reportes',
              onTap: () => _irA(context, ref, '/administracion/reportes'),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final grupo in grupos)
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: grupo.value.any(
                          (a) => a.ruta == rutaActual,
                        ),
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        childrenPadding: EdgeInsets.zero,
                        iconColor: colorScheme.primary,
                        collapsedIconColor: colorScheme.onSurfaceVariant,
                        title: Text(
                          grupo.key,
                          style: TipografiaApp.bodySm.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          for (final acceso in grupo.value)
                            _ItemSidebar(
                              icono: acceso.icono,
                              titulo: acceso.titulo,
                              activo: rutaActual == acceso.ruta,
                              indentado: true,
                              onTap: () => _irA(context, ref, acceso.ruta),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemSidebar extends StatelessWidget {
  const _ItemSidebar({
    required this.icono,
    required this.titulo,
    required this.activo,
    required this.onTap,
    this.indentado = false,
  });

  final IconData icono;
  final String titulo;
  final bool activo;
  final bool indentado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(indentado ? 28 : 12, 2, 12, 2),
      child: Material(
        color: activo
            ? ColoresApp.primario.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(
                  icono,
                  size: 20,
                  color: activo
                      ? ColoresApp.primario
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaApp.bodyMd.copyWith(
                      color: activo
                          ? ColoresApp.primario
                          : colorScheme.onSurface,
                      fontWeight: activo
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
