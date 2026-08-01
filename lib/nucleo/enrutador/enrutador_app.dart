import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../funcionalidades/administracion/dominio/modelo_barbero.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_administracion_dashboard.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_configurar_horarios.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_barberos.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_secretarias.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_servicios.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_sucursales.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_mi_perfil_barbero.dart';
import '../../funcionalidades/ajustes/presentacion/pantallas/pantalla_ajustes_pagos.dart';
import '../../funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import '../../funcionalidades/autenticacion/dominio/modelo_perfil.dart';
import '../../funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_bienvenida_provisional.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_seleccion_barberia.dart';
import '../../funcionalidades/citas/presentacion/pantallas/pantalla_agenda_barbero.dart';
import '../../funcionalidades/citas/presentacion/pantallas/pantalla_mis_citas.dart';
import '../../funcionalidades/fidelidad/presentacion/pantallas/pantalla_gestion_programas_fidelidad.dart';
import '../../funcionalidades/inventario/presentacion/pantallas/pantalla_almacen.dart';
import '../../funcionalidades/inventario/presentacion/pantallas/pantalla_reportar_insumo.dart';
import '../../funcionalidades/pagos/presentacion/pantallas/pantalla_pago_qr.dart';
import '../../funcionalidades/pagos/presentacion/pantallas/pantalla_verificacion_pagos.dart';
import '../../funcionalidades/ranking_barberos/presentacion/pantallas/pantalla_gestion_ranking_barberos.dart';
import '../../funcionalidades/ranking_barberos/presentacion/pantallas/pantalla_ranking_barbero.dart';
import '../../funcionalidades/reportes/presentacion/pantallas/pantalla_reportes_ingresos.dart';
import '../../funcionalidades/resenas/presentacion/pantallas/pantalla_mis_resenas.dart';
import '../../funcionalidades/reservas/presentacion/pantallas/pantalla_confirmacion_reserva.dart';
import '../../funcionalidades/reservas/presentacion/pantallas/pantalla_seleccion_barbero.dart';
import '../../funcionalidades/reservas/presentacion/pantallas/pantalla_seleccion_servicio.dart';
import '../../funcionalidades/turnos/presentacion/pantallas/pantalla_gestion_turnos.dart';
import '../configuracion/cliente_supabase.dart';
import 'notificador_sesion.dart';

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

  // Protección de rutas administrativas
  if (ubicacionActual.startsWith('/administracion')) {
    if (perfil.rol != RolUsuario.admin && perfil.rol != RolUsuario.superadmin) {
      return '/';
    }
  }

  final enSeleccion = ubicacionActual == '/seleccion-barberia';
  if (perfil.barberiaId == null) {
    return enSeleccion ? null : '/seleccion-barberia';
  }

  if (enLogin || enSeleccion) return '/';

  return null;
}

final enrutadorAppProvider = Provider<GoRouter>((ref) {
  final notificador = NotificadorSesion();

  final suscripcionAuth =
      ClienteSupabase.instancia.auth.onAuthStateChange.listen((_) {
    notificador.notificar();
  });
  ref.listen(controladorAutenticacionProvider, (anterior, siguiente) {
    notificador.notificar();
  });

  ref.onDispose(() {
    suscripcionAuth.cancel();
    notificador.dispose();
  });

  return GoRouter(
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
      // ─── Autenticación ─────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const PantallaInicioSesion(),
      ),
      GoRoute(
        path: '/seleccion-barberia',
        builder: (context, state) => const PantallaSeleccionBarberia(),
      ),

      // ─── Raíz: despacha según rol ───────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const _PantallaInicio(),
      ),

      // ─── Reservas (cliente) ─────────────────────────────────────────────
      GoRoute(
        path: '/reservas/servicio',
        builder: (context, state) => const PantallaSeleccionServicio(),
      ),
      GoRoute(
        path: '/reservas/barbero',
        builder: (context, state) => const PantallaSeleccionBarbero(),
      ),
      GoRoute(
        path: '/reservas/confirmacion',
        builder: (context, state) => const PantallaConfirmacionReserva(),
      ),

      // ─── Citas ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/citas',
        builder: (context, state) => const PantallaMisCitas(),
      ),
      GoRoute(
        path: '/agenda',
        builder: (context, state) => const PantallaAgendaBarbero(),
      ),

      // ─── Pagos ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/pagos/qr',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PantallaPagoQr(
            citaId: extra['citaId'] as String,
            monto: extra['monto'] as double,
            urlQrBanco: extra['urlQrBanco'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/pagos/verificacion',
        builder: (context, state) => const PantallaVerificacionPagos(),
      ),

      // ─── Reseñas ────────────────────────────────────────────────────────
      GoRoute(
        path: '/resenas',
        builder: (context, state) => const PantallaMisResenas(),
      ),

      // ─── Turnos / Caja ──────────────────────────────────────────────────
      GoRoute(
        path: '/turnos',
        builder: (context, state) => const PantallaGestionTurnos(),
      ),

      // ─── Inventario ─────────────────────────────────────────────────────
      GoRoute(
        path: '/inventario/almacen',
        builder: (context, state) => const PantallaAlmacen(),
      ),
      GoRoute(
        path: '/inventario/reportar',
        builder: (context, state) => const PantallaReportarInsumo(),
      ),

      // ─── Perfil del barbero ──────────────────────────────────────────────
      GoRoute(
        path: '/perfil-barbero',
        builder: (context, state) => const PantallaMiPerfilBarbero(),
      ),

      // ─── Administración ─────────────────────────────────────────────────
      GoRoute(
        path: '/administracion',
        builder: (context, state) => const PantallaAdministracionDashboard(),
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
        path: '/administracion/secretarias',
        builder: (context, state) => const PantallaGestionSecretarias(),
      ),
      GoRoute(
        path: '/administracion/reportes',
        builder: (context, state) => const PantallaReportesIngresos(),
      ),
      GoRoute(
        path: '/administracion/almacen',
        builder: (context, state) => const PantallaAlmacen(),
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
        path: '/administracion/fidelidad',
        builder: (context, state) =>
            const PantallaGestionProgramasFidelidad(),
      ),
      GoRoute(
        path: '/administracion/promociones',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Promociones')),
          body: const Center(child: Text('Selecciona una promoción del menú.')),
        ),
      ),
      GoRoute(
        path: '/administracion/ranking-barberos',
        builder: (context, state) =>
            const PantallaGestionRankingBarberos(),
      ),
      GoRoute(
        path: '/administracion/ranking-barberos/:id',
        builder: (context, state) => const PantallaRankingBarbero(),
      ),
    ],
  );
});

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

    if (perfil?.rol == RolUsuario.barbero) {
      return const PantallaAgendaBarbero();
    }

    return PantallaBienvenidaProvisional(
      rol: perfil?.rol ?? RolUsuario.cliente,
      nombre: perfil?.nombre,
    );
  }
}
