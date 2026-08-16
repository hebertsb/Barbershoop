import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../configuracion/colores_app.dart';
import '../../funcionalidades/administracion/dominio/modelo_barbero.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_mas_administracion.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_administracion_dashboard.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_configurar_horarios.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_barberos.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_secretarias.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_servicios.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_sucursales.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_mi_perfil_barbero.dart';
import '../../funcionalidades/ajustes/presentacion/pantallas/pantalla_ajustes_marca.dart';
import '../../funcionalidades/ajustes/presentacion/pantallas/pantalla_ajustes_pagos.dart';
import '../../funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import '../../funcionalidades/autenticacion/dominio/modelo_perfil.dart';
import '../../funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_bienvenida_provisional.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_seleccion_barberia.dart';
import '../../funcionalidades/citas/presentacion/componentes/esqueleto_barbero.dart';
import '../../funcionalidades/citas/presentacion/pantallas/pantalla_agenda.dart';
import '../../funcionalidades/citas/presentacion/pantallas/pantalla_agenda_barbero.dart';
import '../../funcionalidades/citas/presentacion/pantallas/pantalla_mis_citas.dart';
import '../../funcionalidades/fidelidad/presentacion/componentes/pildora_fidelidad_flotante.dart';
import '../../funcionalidades/fidelidad/presentacion/pantallas/pantalla_gestion_programas_fidelidad.dart';
import '../../funcionalidades/inventario/presentacion/pantallas/pantalla_almacen.dart';
import '../../funcionalidades/inventario/presentacion/pantallas/pantalla_bandeja_reportes.dart';
import '../../funcionalidades/inventario/presentacion/pantallas/pantalla_inicio_barbero.dart';
import '../../funcionalidades/inventario/presentacion/pantallas/pantalla_mis_insumos.dart';
import '../../funcionalidades/inventario/presentacion/pantallas/pantalla_reportar_insumo.dart';
import '../../funcionalidades/pagos/presentacion/pantallas/pantalla_pago_qr.dart';
import '../../funcionalidades/pagos/presentacion/pantallas/pantalla_verificacion_pagos.dart';
import '../../funcionalidades/promociones/presentacion/pantallas/pantalla_gestion_promociones.dart';
import '../../funcionalidades/ranking_barberos/presentacion/pantallas/pantalla_gestion_ranking_barberos.dart';
import '../../funcionalidades/ranking_barberos/presentacion/pantallas/pantalla_ranking_barbero.dart';
import '../../funcionalidades/reportes/presentacion/pantallas/pantalla_actividad_diaria.dart';
import '../../funcionalidades/reportes/presentacion/pantallas/pantalla_control_auditoria.dart';
import '../../funcionalidades/reportes/presentacion/pantallas/pantalla_reportes_ingresos.dart';
import '../../funcionalidades/resenas/presentacion/pantallas/pantalla_mis_resenas.dart';
import '../../funcionalidades/reservas/presentacion/pantallas/pantalla_confirmacion_reserva.dart';
import '../../funcionalidades/reservas/presentacion/pantallas/pantalla_inicio_cliente.dart';
import '../../funcionalidades/reservas/presentacion/pantallas/pantalla_seleccion_barbero.dart';
import '../../funcionalidades/reservas/presentacion/pantallas/pantalla_seleccion_horario.dart';
import '../../funcionalidades/reservas/presentacion/pantallas/pantalla_seleccion_servicio.dart';
import '../../funcionalidades/reservas/presentacion/pantallas/pantalla_seleccion_sucursal.dart';
import '../configuracion/cliente_supabase.dart';
import '../configuracion/navegador_raiz.dart';
import '../utilidades/layout_responsivo.dart';
import 'notificador_sesion.dart';
import 'sidebar_administracion.dart';

// ---------------------------------------------------------------------------
// Helpers de navegación de cliente
// ---------------------------------------------------------------------------

/// Convierte un índice de rama (navigationShell.currentIndex) al índice
/// visible del NavigationBar del cliente (2 pestañas: Inicio=0, Agenda=1).
/// La rama 0 → tab 0 (Inicio), la rama 2 → tab 1 (Agenda), el resto → 0.
int tabVisibleParaRamaCliente(int ramaActual) {
  switch (ramaActual) {
    case 2:
      return 1;
    default:
      return 0;
  }
}

/// Convierte un índice de tab visible del NavigationBar del cliente a la rama
/// del StatefulShell. Tab 0 (Inicio) → rama 0, Tab 1 (Agenda) → rama 2.
int ramaParaTabCliente(int tabVisible) {
  switch (tabVisible) {
    case 1:
      return 2;
    default:
      return 0;
  }
}

// ---------------------------------------------------------------------------
// Etiquetas de navegación por rol
// ---------------------------------------------------------------------------

/// Devuelve la lista de etiquetas (label) del NavigationBar según el rol.
/// - Admin / Superadmin / Barbero → 4 destinos
/// - Secretaria → 1 destino (solo agenda)
/// - Cualquier otro → lista vacía (sin navbar)
List<String> etiquetasNavAdministracion(RolUsuario? rol) {
  switch (rol) {
    case RolUsuario.admin:
    case RolUsuario.superadmin:
      return ['Inicio', 'Agenda', 'Métricas', 'Más'];
    case RolUsuario.barbero:
      return ['Inicio', 'Agenda', 'Insumos', 'Más'];
    case RolUsuario.secretaria:
      return ['Agenda'];
    default:
      return [];
  }
}

// ---------------------------------------------------------------------------
// Guard de redirección
// ---------------------------------------------------------------------------

/// Decide a dónde redirigir según sesión, estado del perfil y ubicación actual.
/// Función pura (sin GoRouter/BuildContext) para poder testearla directamente.
String? calcularRedireccion({
  required bool haySesion,
  required AsyncValue<ModeloPerfil?> estadoPerfil,
  required String ubicacionActual,
}) {
  final enLogin = ubicacionActual == '/login';

  if (!haySesion) {
    return enLogin ? null : '/login';
  }

  if (estadoPerfil.isLoading) return null;
  if (estadoPerfil.hasError) return null;

  final perfil = estadoPerfil.valueOrNull;
  if (perfil == null) {
    return enLogin ? null : '/login';
  }

  const rutaAgenda = '/administracion/agenda';

  // Secretaria sin barberiaId (invitacion revertida o incompleta): la manda
  // al flujo normal de seleccion, igual que cualquier otro rol sin
  // barberiaId, en vez de forzarla hacia /administracion/agenda antes de
  // tiempo. Se resuelve antes del guard de abajo para que no compita con el.
  if (perfil.rol == RolUsuario.secretaria && perfil.barberiaId == null) {
    if (ubicacionActual == '/seleccion-barberia') return null;
    return '/seleccion-barberia';
  }

  if (perfil.rol == RolUsuario.secretaria) {
    if (ubicacionActual.startsWith('/administracion')) return null;
    return rutaAgenda;
  }

  if (perfil.barberiaId == null) {
    if (ubicacionActual == '/seleccion-barberia') return null;
    return '/seleccion-barberia';
  }

  if (enLogin || ubicacionActual == '/seleccion-barberia') {
    return '/';
  }

  return null;
}

// ---------------------------------------------------------------------------
// Provider del router
// ---------------------------------------------------------------------------

final enrutadorAppProvider = Provider<GoRouter>((ref) {
  final notificador = NotificadorSesion();

  final suscripcionAuth =
      ClienteSupabase.instancia.auth.onAuthStateChange.listen((data) {
    ref.invalidate(controladorAutenticacionProvider);
    notificador.notificarCambio();
  });

  ref.listen(controladorAutenticacionProvider, (anterior, siguiente) {
    notificador.notificarCambio();
  });

  ref.onDispose(() {
    suscripcionAuth.cancel();
    notificador.dispose();
  });

  return GoRouter(
    navigatorKey: navegadorRaizKey,
    initialLocation: '/',
    refreshListenable: notificador,
    redirect: (context, state) {
      final sesion = ClienteSupabase.instancia.auth.currentSession;
      final estadoPerfil = ref.read(controladorAutenticacionProvider);
      return calcularRedireccion(
        haySesion: sesion != null,
        estadoPerfil: estadoPerfil,
        ubicacionActual: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const PantallaInicioSesion(),
      ),
      GoRoute(
        path: '/seleccion-barberia',
        builder: (context, state) => const PantallaSeleccionBarberia(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _EsqueletoAdministracion(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const _PantallaInicio(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/administracion/agenda',
                builder: (context, state) => const PantallaAgenda(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mis-citas',
                builder: (context, state) => const PantallaMisCitas(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/administracion/mas',
        builder: (context, state) => const PantallaMasAdministracion(),
      ),
      GoRoute(
        path: '/administracion/sucursales',
        builder: (context, state) => const PantallaGestionSucursales(),
      ),
      GoRoute(
        path: '/administracion/servicios',
        builder: (context, state) => const PantallaGestionServicios(),
      ),
      GoRoute(
        path: '/administracion/barberos',
        builder: (context, state) => const PantallaGestionBarberos(),
      ),
      GoRoute(
        path: '/administracion/secretarias',
        builder: (context, state) => const PantallaGestionSecretarias(),
      ),
      GoRoute(
        path: '/administracion/barberos/:id/horarios',
        builder: (context, state) {
          final barberoId = state.pathParameters['id']!;
          final barbero = state.extra as ModeloBarbero?;
          return PantallaConfigurarHorarios(
            barberoId: barberoId,
            barbero: barbero,
          );
        },
      ),
      GoRoute(
        path: '/reservar/sucursal',
        parentNavigatorKey: navegadorRaizKey,
        builder: (context, state) => const PantallaSeleccionSucursal(),
      ),
      GoRoute(
        path: '/reservar/servicio',
        parentNavigatorKey: navegadorRaizKey,
        builder: (context, state) => const PantallaSeleccionServicio(),
      ),
      GoRoute(
        path: '/reservar/barbero',
        parentNavigatorKey: navegadorRaizKey,
        builder: (context, state) => const PantallaSeleccionBarbero(),
      ),
      GoRoute(
        path: '/reservar/horario',
        parentNavigatorKey: navegadorRaizKey,
        builder: (context, state) => const PantallaSeleccionHorario(),
      ),
      GoRoute(
        path: '/reservar/confirmar',
        parentNavigatorKey: navegadorRaizKey,
        builder: (context, state) => const PantallaConfirmacionReserva(),
      ),
      GoRoute(
        path: '/pago/:citaId',
        parentNavigatorKey: navegadorRaizKey,
        builder: (context, state) {
          final citaId = state.pathParameters['citaId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final monto = (extra?['monto'] as num?)?.toDouble();
          if (monto == null || monto <= 0) {
            return _PantallaErrorPago(citaId: citaId);
          }
          return PantallaPagoQr(
            citaId: citaId,
            monto: monto,
            urlQrBanco: extra?['urlQrBanco'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/administracion/verificacion-pagos',
        builder: (context, state) => const PantallaVerificacionPagos(),
      ),
      GoRoute(
        path: '/administracion/ajustes-pagos',
        builder: (context, state) => const PantallaAjustesPagos(),
      ),
      GoRoute(
        path: '/administracion/ajustes-marca',
        builder: (context, state) => const PantallaAjustesMarca(),
      ),
      GoRoute(
        path: '/administracion/almacen',
        builder: (context, state) => const PantallaAlmacen(),
      ),
      GoRoute(
        path: '/administracion/reportes-insumos',
        builder: (context, state) => const PantallaBandejaReportes(),
      ),
      GoRoute(
        path: '/administracion/promociones',
        builder: (context, state) => const PantallaGestionPromociones(),
      ),
      GoRoute(
        path: '/administracion/programas-fidelidad',
        builder: (context, state) => const PantallaGestionProgramasFidelidad(),
      ),
      GoRoute(
        path: '/administracion/ranking-barberos',
        builder: (context, state) => const PantallaGestionRankingBarberos(),
      ),
      GoRoute(
        path: '/administracion/reportes',
        builder: (context, state) => const PantallaReportesIngresos(),
      ),
      GoRoute(
        path: '/administracion/actividad-diaria',
        builder: (context, state) => const PantallaActividadDiaria(),
      ),
      GoRoute(
        path: '/administracion/control-auditoria',
        builder: (context, state) => const PantallaControlAuditoria(),
      ),
      GoRoute(
        path: '/mi-agenda',
        builder: (context, state) =>
            const EsqueletoBarbero(indice: 1, child: PantallaAgendaBarbero()),
      ),
      GoRoute(
        path: '/mis-insumos',
        builder: (context, state) =>
            const EsqueletoBarbero(indice: 2, child: PantallaMisInsumos()),
      ),
      GoRoute(
        path: '/mis-insumos/reportar',
        builder: (context, state) => const PantallaReportarInsumo(),
      ),
      GoRoute(
        path: '/mis-resenas',
        builder: (context, state) => const PantallaMisResenas(),
      ),
      GoRoute(
        path: '/mi-ranking',
        builder: (context, state) => const PantallaRankingBarbero(),
      ),
      GoRoute(
        path: '/mi-perfil',
        builder: (context, state) => const PantallaMiPerfilBarbero(),
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Pantalla de error de pago
// ---------------------------------------------------------------------------

/// Pantalla mínima mostrada en vez de [PantallaPagoQr] cuando la ruta
/// `/pago/:citaId` se abrió sin un `monto` válido en `state.extra`.
class _PantallaErrorPago extends StatelessWidget {
  const _PantallaErrorPago({required this.citaId});

  final String citaId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar por QR')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                "No se pudo abrir la pantalla de pago. Volvé a 'Mis citas' e "
                'intentá de nuevo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/mis-citas'),
                child: const Text('Ir a Mis citas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pantalla de inicio (despacho por rol)
// ---------------------------------------------------------------------------

class _PantallaInicio extends ConsumerWidget {
  const _PantallaInicio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoPerfil = ref.watch(controladorAutenticacionProvider);
    if (estadoPerfil.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final perfil = estadoPerfil.valueOrNull;

    if (perfil?.rol == RolUsuario.admin ||
        perfil?.rol == RolUsuario.superadmin) {
      return const PantallaAdministracionDashboard();
    }

    if (perfil?.rol == RolUsuario.cliente) {
      return const PantallaInicioCliente();
    }

    if (perfil?.rol == RolUsuario.barbero) {
      return const EsqueletoBarbero(indice: 0, child: PantallaInicioBarbero());
    }

    return PantallaBienvenidaProvisional(
      rol: perfil?.rol ?? RolUsuario.cliente,
      nombre: perfil?.nombre,
    );
  }
}

// ---------------------------------------------------------------------------
// Esqueleto con NavigationBar (admin, barbero, cliente, secretaria)
// ---------------------------------------------------------------------------

class _EsqueletoAdministracion extends ConsumerWidget {
  const _EsqueletoAdministracion({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoPerfil = ref.watch(controladorAutenticacionProvider);

    // Sin navbar mientras carga evita el flash de admin a cualquier otro rol.
    if (estadoPerfil.isLoading) {
      return Scaffold(body: navigationShell);
    }

    final perfil = estadoPerfil.value;

    if (perfil?.rol == RolUsuario.cliente) {
      const destinosCliente = [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Agenda',
        ),
      ];
      final indiceVisible = tabVisibleParaRamaCliente(
        navigationShell.currentIndex,
      );
      return Scaffold(
        body: Stack(
          children: [
            navigationShell,
            const Positioned(
              right: 14,
              bottom: 90,
              child: PildoraFidelidadFlotante(),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: indiceVisible,
          onDestinationSelected: (indice) =>
              navigationShell.goBranch(ramaParaTabCliente(indice)),
          destinations: destinosCliente,
        ),
      );
    }

    final etiquetas = etiquetasNavAdministracion(perfil?.rol);

    if (perfil?.rol == RolUsuario.barbero || etiquetas.length <= 1) {
      // Barbero y Secretaria: usan sus propios esqueletos sin navbar duplicada.
      return navigationShell;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (esPantallaAncha(constraints.maxWidth)) {
          return Scaffold(
            body: Row(
              children: [
                SidebarAdministracion(navigationShell: navigationShell),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }
        // Móvil: NavigationBar de 4 pestañas para admin/barbero
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex < 2
                ? navigationShell.currentIndex
                : 0,
            onDestinationSelected: (indice) {
              switch (indice) {
                case 0:
                  navigationShell.goBranch(0);
                  break;
                case 1:
                  navigationShell.goBranch(1);
                  break;
                case 2:
                  context.push('/administracion/reportes');
                  break;
                case 3:
                  context.push('/administracion/mas');
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_max_outlined),
                selectedIcon: Icon(
                  Icons.home_max,
                  color: ColoresApp.primario,
                ),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(
                  Icons.calendar_today,
                  color: ColoresApp.primario,
                ),
                label: 'Agenda',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(
                  Icons.analytics,
                  color: ColoresApp.primario,
                ),
                label: 'Métricas',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(
                  Icons.grid_view,
                  color: ColoresApp.primario,
                ),
                label: 'Más',
              ),
            ],
          ),
        );
      },
    );
  }
}