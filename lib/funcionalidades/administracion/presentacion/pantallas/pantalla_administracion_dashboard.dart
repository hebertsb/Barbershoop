import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barber_app/nucleo/configuracion/colores_app.dart';
import 'package:barber_app/nucleo/configuracion/tipografia_app.dart';
import 'package:barber_app/funcionalidades/administracion/datos/repositorio_accesos_admin.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/catalogo_accesos_admin.dart';
import 'package:barber_app/funcionalidades/administracion/presentacion/componentes/tarjeta_grafico_tendencia.dart';
import 'package:barber_app/funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';

/// Dashboard principal de administración.
/// Muestra: saludo con el nombre del admin, gráfico de tendencia de ingresos
/// de la semana, y la grilla de accesos rápidos (primeros 4 del catálogo o
/// los 4 más usados según historial).

/// Provider que obtiene las rutas más usadas por el admin para los accesos
/// rápidos del dashboard.
final _rutasTopProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.read(repositorioAccesosAdminProvider).obtenerRutasTopAccesos();
});

class PantallaAdministracionDashboard extends ConsumerWidget {
  const PantallaAdministracionDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(controladorAutenticacionProvider).value;
    final rutasTopState = ref.watch(_rutasTopProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref
                .read(controladorAutenticacionProvider.notifier)
                .cerrarSesion(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(controladorAutenticacionProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Saludo ────────────────────────────────────────────────────
            if (perfil?.nombre != null) ...[
              Text(
                'Hola, ${perfil!.nombre!} 👋',
                style: TipografiaApp.headlineSm.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aquí está el resumen de tu barbería',
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Gráfico de tendencia ──────────────────────────────────────
            const TarjetaGraficoTendencia(),
            const SizedBox(height: 24),

            // ── Accesos rápidos ───────────────────────────────────────────
            Text(
              'Acceso Rápido',
              style: TipografiaApp.headlineSm.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            rutasTopState.when(
              data: (rutasTop) {
                final accesos = elegirAccesosRapidos(rutasTop);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accesos.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, index) {
                    final acceso = accesos[index];
                    return _TarjetaAccesoRapido(acceso: acceso);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                // Si falla, usar el catálogo completo como fallback
                final accesos = elegirAccesosRapidos([]);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accesos.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, index) {
                    final acceso = accesos[index];
                    return _TarjetaAccesoRapido(acceso: acceso);
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Todas las secciones ───────────────────────────────────────
            Text(
              'Todas las secciones',
              style: TipografiaApp.headlineSm.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            ...agruparAccesosPorCategoria(catalogoAccesosAdmin).map(
              (grupo) => _GrupoAccesos(
                categoria: grupo.key,
                accesos: grupo.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de acceso rápido
// ---------------------------------------------------------------------------

class _TarjetaAccesoRapido extends ConsumerWidget {
  const _TarjetaAccesoRapido({required this.acceso});
  final AccesoAdmin acceso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(repositorioAccesosAdminProvider).registrarAcceso(acceso.ruta);
          context.push(acceso.ruta);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                acceso.icono,
                color: ColoresApp.primario,
                size: 28,
              ),
              const Spacer(),
              Text(
                acceso.titulo,
                style: TipografiaApp.bodyMd.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                acceso.subtitulo,
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grupo de accesos por categoría (para la sección "Todas las secciones")
// ---------------------------------------------------------------------------

class _GrupoAccesos extends ConsumerWidget {
  const _GrupoAccesos({required this.categoria, required this.accesos});
  final String categoria;
  final List<AccesoAdmin> accesos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            categoria,
            style: TipografiaApp.labelMd.copyWith(
              color: ColoresApp.primario,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...accesos.map(
          (acceso) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(acceso.icono, color: ColoresApp.primario, size: 20),
            ),
            title: Text(
              acceso.titulo,
              style: TipografiaApp.bodyMd.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              acceso.subtitulo,
              style: TipografiaApp.bodySm.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              ref
                  .read(repositorioAccesosAdminProvider)
                  .registrarAcceso(acceso.ruta);
              context.push(acceso.ruta);
            },
          ),
        ),
        const Divider(height: 16),
      ],
    );
  }
}
