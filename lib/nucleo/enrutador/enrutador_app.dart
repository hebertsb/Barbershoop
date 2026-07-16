import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../funcionalidades/administracion/dominio/modelo_barbero.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_administracion_dashboard.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_configurar_horarios.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_barberos.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_servicios.dart';
import '../../funcionalidades/administracion/presentacion/pantallas/pantalla_gestion_sucursales.dart';
import '../../funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import '../../funcionalidades/autenticacion/dominio/modelo_perfil.dart';
import '../../funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_bienvenida_provisional.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_seleccion_barberia.dart';
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

  final suscripcionAuth = ClienteSupabase.instancia.auth.onAuthStateChange.listen((_) {
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const PantallaInicioSesion(),
      ),
      GoRoute(
        path: '/seleccion-barberia',
        builder: (context, state) => const PantallaSeleccionBarberia(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const _PantallaInicio(),
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

    if (perfil?.rol == RolUsuario.admin || perfil?.rol == RolUsuario.superadmin) {
      return const PantallaAdministracionDashboard();
    }

    return PantallaBienvenidaProvisional(
      rol: perfil?.rol ?? RolUsuario.cliente,
      nombre: perfil?.nombre,
    );
  }
}
