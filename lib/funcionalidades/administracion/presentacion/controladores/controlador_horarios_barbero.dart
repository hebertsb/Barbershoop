import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/errores/excepciones_app.dart';
import '../../datos/repositorio_administracion.dart';
import '../../dominio/modelo_horario_barbero.dart';
import 'controlador_barberos.dart';

const _diasNombres = [
  'Domingo',
  'Lunes',
  'Martes',
  'Mircoles',
  'Jueves',
  'Viernes',
  'Sbado',
];

int _minutosDelDia(String hora) {
  final partes = hora.split(':');
  return int.parse(partes[0]) * 60 + int.parse(partes[1]);
}

class ControladorHorariosBarbero
    extends AutoDisposeFamilyAsyncNotifier<List<ModeloHorarioBarbero>, String> {
  @override
  FutureOr<List<ModeloHorarioBarbero>> build(String arg) {
    return ref
        .read(repositorioAdministracionProvider)
        .obtenerHorariosBarbero(arg);
  }

  Future<void> guardarHorarios(List<ModeloHorarioBarbero> horarios) async {
    state = const AsyncLoading<List<ModeloHorarioBarbero>>();
    state = await AsyncValue.guard(() async {
      for (final horario in horarios) {
        if (_minutosDelDia(horario.horaFin) <=
            _minutosDelDia(horario.horaInicio)) {
          throw ExcepcionDesconocida(
            'La hora de cierre debe ser posterior a la de apertura para el da '
            '${_diasNombres[horario.diaSemana]}.',
          );
        }
      }
      await ref
          .read(repositorioAdministracionProvider)
          .guardarHorariosBarbero(arg, horarios);
      return horarios;
    });
    if (state.hasError) throw state.error!;
  }
}

final controladorHorariosBarberoProvider = AsyncNotifierProvider.autoDispose
    .family<ControladorHorariosBarbero, List<ModeloHorarioBarbero>, String>(
      ControladorHorariosBarbero.new,
    );

final horariosDeSucursalProvider = FutureProvider.autoDispose
    .family<List<ModeloHorarioBarbero>, String>((ref, sucursalId) async {
      final barberos = await ref.watch(controladorBarberosProvider.future);
      final ids = barberos
          .where((b) => b.sucursalId == sucursalId && b.activo)
          .map((b) => b.id)
          .toList();
      if (ids.isEmpty) return [];
      return ref
          .read(repositorioAdministracionProvider)
          .obtenerHorariosBarberoDeBarberos(ids);
    });
