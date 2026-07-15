import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../funcionalidades/autenticacion/dominio/enum_rol_usuario.dart';
import '../../funcionalidades/autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_bienvenida_provisional.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart';
import '../../funcionalidades/autenticacion/presentacion/pantallas/pantalla_seleccion_barberia.dart';
import '../configuracion/cliente_supabase.dart';
import 'notificador_sesion.dart';

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
      final enLogin = state.matchedLocation == '/login';

      if (sesion == null) {
        return enLogin ? null : '/login';
      }

      final estadoPerfil = ref.read(controladorAutenticacionProvider);
      if (estadoPerfil.isLoading) return null;

      final perfil = estadoPerfil.valueOrNull;
      if (perfil == null) {
        return enLogin ? null : '/login';
      }

      final enSeleccion = state.matchedLocation == '/seleccion-barberia';
      if (perfil.barberiaId == null) {
        return enSeleccion ? null : '/seleccion-barberia';
      }

      if (enLogin || enSeleccion) return '/';

      return null;
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
        builder: (context, state) {
          final perfil = ref.read(controladorAutenticacionProvider).valueOrNull;
          return PantallaBienvenidaProvisional(
            rol: perfil?.rol ?? RolUsuario.cliente,
            nombre: perfil?.nombre,
          );
        },
      ),
    ],
  );
});
