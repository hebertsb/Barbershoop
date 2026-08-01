import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_administracion.dart';
import '../../dominio/modelo_barbero.dart';

class ControladorBarberos extends AsyncNotifier<List<ModeloBarbero>> {
  @override
  FutureOr<List<ModeloBarbero>> build() async {
    return ref.read(repositorioAdministracionProvider).obtenerBarberos();
  }

  Future<void> invitarBarbero({
    required String email,
    required String sucursalId,
    required List<String> especialidades,
  }) async {
    state = const AsyncLoading<List<ModeloBarbero>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioAdministracionProvider)
          .invitarBarbero(
            email: email,
            sucursalId: sucursalId,
            especialidades: especialidades,
          );
      // Recargar la lista completa de barberos para obtener la información de perfil
      return ref.read(repositorioAdministracionProvider).obtenerBarberos();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> actualizarEstadoBarbero(String barberoId, bool activo) async {
    final listaAnterior = state.value ?? [];
    state = const AsyncLoading<List<ModeloBarbero>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioAdministracionProvider)
          .actualizarEstadoBarbero(barberoId, activo);
      return listaAnterior
          .map((b) => b.id == barberoId ? b.copyWith(activo: activo) : b)
          .toList();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> guardarNivel(String barberoId, String? nivel) async {
    final listaAnterior = state.value ?? [];
    state = const AsyncLoading<List<ModeloBarbero>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioAdministracionProvider)
          .guardarNivelBarbero(barberoId, nivel);
      return listaAnterior
          .map(
            (b) => b.id == barberoId
                ? b.copyWith(nivel: nivel, limpiarNivel: nivel == null)
                : b,
          )
          .toList();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> guardarSucursalYEspecialidades({
    required String barberoId,
    required String sucursalId,
    required List<String> especialidades,
  }) async {
    final listaAnterior = state.value ?? [];
    state = const AsyncLoading<List<ModeloBarbero>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioAdministracionProvider)
          .guardarSucursalYEspecialidades(
            barberoId: barberoId,
            sucursalId: sucursalId,
            especialidades: especialidades,
          );
      return listaAnterior
          .map(
            (b) => b.id == barberoId
                ? b.copyWith(
                    sucursalId: sucursalId,
                    especialidades: especialidades,
                  )
                : b,
          )
          .toList();
    });
    if (state.hasError) throw state.error!;
  }

  // A diferencia de los métodos anteriores (que actualizan un barbero
  // elegido por el admin), este actúa sobre el propio perfil de quien llama:
  // no hay forma de saber de antemano cuál fila de la lista en memoria le
  // corresponde (puede no estar cargada, o el barbero puede tener más de
  // una fila por multi-sucursal), así que se recarga la lista completa
  // después de guardar, en vez de intentar un update optimista.
  Future<void> guardarMiPerfil({
    String? descripcion,
    required List<String> especialidades,
    String? urlFoto,
    String? telefono,
  }) async {
    state = const AsyncLoading<List<ModeloBarbero>>();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(repositorioAdministracionProvider);
      if (urlFoto != null) {
        await repo.actualizarFotoPerfilPropio(urlFoto);
      }
      await repo.actualizarTelefonoPropio(telefono);
      await repo.guardarPerfilBarbero(
        descripcion: descripcion,
        especialidades: especialidades,
      );
      return repo.obtenerBarberos();
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorBarberosProvider =
    AsyncNotifierProvider<ControladorBarberos, List<ModeloBarbero>>(() {
      return ControladorBarberos();
    });

// Barberos con columnas acotadas, seguro para pantallas cliente-facing
// (RPC `obtener_barberos_publicos`). Trae todos los barberos activos
// del tenant y se filtra por sucursal client-side, mismo patrón que
// `PantallaSeleccionBarbero` ya usa hoy con `controladorBarberosProvider`.
final barberosPublicosProvider =
    FutureProvider.autoDispose<List<ModeloBarbero>>((ref) {
      return ref
          .read(repositorioAdministracionProvider)
          .obtenerBarberosPublicos();
    });
