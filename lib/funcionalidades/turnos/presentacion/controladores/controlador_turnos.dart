import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pagos/dominio/enum_metodo_pago.dart';
import '../../datos/repositorio_turnos.dart';
import '../../dominio/enum_modo_cobro_caja.dart';
import '../../dominio/modelo_cliente_walkin.dart';
import '../../dominio/modelo_turno.dart';

class ControladorTurnos
    extends AutoDisposeFamilyAsyncNotifier<List<ModeloTurno>, String> {
  @override
  FutureOr<List<ModeloTurno>> build(String arg) {
    return ref.read(repositorioTurnosProvider).obtenerTurnosDelDia(arg);
  }

  Future<void> crearTurnoConCuenta({
    required String servicioId,
    required String clienteId,
    double? montoPrecobrado,
    MetodoPago? metodoPrecobrado,
  }) async {
    state = const AsyncLoading<List<ModeloTurno>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioTurnosProvider)
          .crearTurnoConCuenta(
            sucursalId: arg,
            servicioId: servicioId,
            clienteId: clienteId,
            montoPrecobrado: montoPrecobrado,
            metodoPrecobrado: metodoPrecobrado,
          );
      return ref.read(repositorioTurnosProvider).obtenerTurnosDelDia(arg);
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> crearTurnoWalkin({
    required String servicioId,
    required String nombre,
    required String telefono,
    double? montoPrecobrado,
    MetodoPago? metodoPrecobrado,
  }) async {
    state = const AsyncLoading<List<ModeloTurno>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioTurnosProvider)
          .crearTurnoWalkin(
            sucursalId: arg,
            servicioId: servicioId,
            nombre: nombre,
            telefono: telefono,
            montoPrecobrado: montoPrecobrado,
            metodoPrecobrado: metodoPrecobrado,
          );
      return ref.read(repositorioTurnosProvider).obtenerTurnosDelDia(arg);
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> llamarTurno({
    required String turnoId,
    required String barberoId,
  }) async {
    state = const AsyncLoading<List<ModeloTurno>>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioTurnosProvider)
          .llamarTurno(turnoId: turnoId, barberoId: barberoId);
      return ref.read(repositorioTurnosProvider).obtenerTurnosDelDia(arg);
    });
    if (state.hasError) throw state.error!;
  }

  Future<String> completarTurno({
    required String turnoId,
    double? monto,
    MetodoPago? metodo,
  }) async {
    state = const AsyncLoading<List<ModeloTurno>>();
    late String citaId;
    state = await AsyncValue.guard(() async {
      citaId = await ref
          .read(repositorioTurnosProvider)
          .completarTurno(turnoId: turnoId, monto: monto, metodo: metodo);
      return ref.read(repositorioTurnosProvider).obtenerTurnosDelDia(arg);
    });
    if (state.hasError) throw state.error!;
    return citaId;
  }

  Future<void> cancelarTurno(String turnoId) async {
    state = const AsyncLoading<List<ModeloTurno>>();
    state = await AsyncValue.guard(() async {
      await ref.read(repositorioTurnosProvider).cancelarTurno(turnoId);
      return ref.read(repositorioTurnosProvider).obtenerTurnosDelDia(arg);
    });
    if (state.hasError) throw state.error!;
  }

  Future<ModeloTurno> confirmarLlegadaCita(String citaId) async {
    state = const AsyncLoading<List<ModeloTurno>>();
    late ModeloTurno turnoCreado;
    state = await AsyncValue.guard(() async {
      turnoCreado = await ref
          .read(repositorioTurnosProvider)
          .confirmarLlegadaCita(citaId);
      return ref.read(repositorioTurnosProvider).obtenerTurnosDelDia(arg);
    });
    if (state.hasError) throw state.error!;
    return turnoCreado;
  }

  Future<ModeloClienteWalkin?> buscarClienteWalkinPorTelefono(String telefono) {
    return ref
        .read(repositorioTurnosProvider)
        .buscarClienteWalkinPorTelefono(telefono);
  }

  Future<Map<String, String>?> buscarClientePorEmail(String email) {
    return ref.read(repositorioTurnosProvider).buscarClientePorEmail(email);
  }
}

final controladorTurnosProvider = AsyncNotifierProvider.autoDispose
    .family<ControladorTurnos, List<ModeloTurno>, String>(
      ControladorTurnos.new,
    );

final modoCobroCajaProvider = FutureProvider.autoDispose<ModoCobroCaja>((ref) {
  return ref.read(repositorioTurnosProvider).obtenerModoCobroCaja();
});
