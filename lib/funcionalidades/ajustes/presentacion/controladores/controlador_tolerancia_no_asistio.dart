import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_ajustes.dart';

/// Minutos de tolerancia tras la `fecha_hora` de una cita `pendiente` antes
/// de que el cron `marcar_no_asistio_vencidas` (`0028`) la marque
/// automticamente como `no_asistio`. Independiente de la configuracin de
/// pagos (`ModeloConfiguracionPagos`): no es un ajuste de pago, es de
/// asistencia/reservas, aunque comparta la tabla `configuraciones_barberia`.
class ControladorToleranciaNoAsistio extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() {
    return ref
        .read(repositorioAjustesProvider)
        .obtenerMinutosToleranciaNoAsistio();
  }

  Future<void> guardar(int minutos) async {
    state = const AsyncLoading<int>();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositorioAjustesProvider)
          .guardarMinutosToleranciaNoAsistio(minutos);
      return minutos;
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorToleranciaNoAsistioProvider =
    AsyncNotifierProvider<ControladorToleranciaNoAsistio, int>(
      ControladorToleranciaNoAsistio.new,
    );
