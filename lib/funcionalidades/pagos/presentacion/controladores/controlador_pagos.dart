import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_pagos.dart';
import '../../dominio/modelo_pago.dart';

/// Pago de una cita puntual (o null si todavía no se subió comprobante).
/// Family por `citaId`, usado por `PantallaPagoQr`/`TarjetaMiCita`.
class ControladorPagoDeCita
    extends AutoDisposeFamilyAsyncNotifier<ModeloPago?, String> {
  @override
  FutureOr<ModeloPago?> build(String arg) {
    return ref.read(repositorioPagosProvider).obtenerPagoDeCita(arg);
  }

  Future<void> subirComprobante({
    required double monto,
    required String urlComprobante,
  }) async {
    state = const AsyncLoading<ModeloPago?>();
    state = await AsyncValue.guard(() {
      return ref
          .read(repositorioPagosProvider)
          .subirComprobante(
            citaId: arg,
            monto: monto,
            urlComprobante: urlComprobante,
          );
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorPagoDeCitaProvider = AsyncNotifierProvider.autoDispose
    .family<ControladorPagoDeCita, ModeloPago?, String>(
      ControladorPagoDeCita.new,
    );

/// Bandeja de pagos `por_verificar` del admin.
class ControladorPagosPorVerificar
    extends AutoDisposeAsyncNotifier<List<ModeloPago>> {
  @override
  FutureOr<List<ModeloPago>> build() {
    return ref.read(repositorioPagosProvider).obtenerPagosPorVerificar();
  }

  Future<void> confirmarPago(String pagoId) async {
    state = const AsyncLoading<List<ModeloPago>>();
    state = await AsyncValue.guard(() async {
      await ref.read(repositorioPagosProvider).confirmarPago(pagoId);
      return ref.read(repositorioPagosProvider).obtenerPagosPorVerificar();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> rechazarPago(String pagoId) async {
    state = const AsyncLoading<List<ModeloPago>>();
    state = await AsyncValue.guard(() async {
      await ref.read(repositorioPagosProvider).rechazarPago(pagoId);
      return ref.read(repositorioPagosProvider).obtenerPagosPorVerificar();
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorPagosPorVerificarProvider =
    AsyncNotifierProvider.autoDispose<
      ControladorPagosPorVerificar,
      List<ModeloPago>
    >(ControladorPagosPorVerificar.new);
