import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/pagos/dominio/enum_metodo_pago.dart';
import 'package:barber_app/nucleo/errores/excepciones_app.dart';
import 'package:barber_app/funcionalidades/turnos/datos/repositorio_turnos.dart';
import 'package:barber_app/funcionalidades/turnos/dominio/enum_estado_turno.dart';
import 'package:barber_app/funcionalidades/turnos/dominio/enum_modo_cobro_caja.dart';
import 'package:barber_app/funcionalidades/turnos/dominio/modelo_cliente_walkin.dart';
import 'package:barber_app/funcionalidades/turnos/dominio/modelo_turno.dart';
import 'package:barber_app/funcionalidades/turnos/presentacion/controladores/controlador_turnos.dart';

ModeloTurno _turno(String id, {EstadoTurno estado = EstadoTurno.esperando}) =>
    ModeloTurno(
      id: id,
      barberiaId: 'b1',
      sucursalId: 's1',
      numero: 1,
      clienteWalkinId: 'walkin1',
      servicioId: 'serv1',
      estado: estado,
      horaLlegada: DateTime(2026, 7, 17, 9),
    );

class RepositorioTurnosFalso implements RepositorioTurnos {
  List<ModeloTurno> turnos = [];
  Exception? errorSimulado;
  Map<String, String>? ultimoLlamado;
  String? ultimoCompletadoId;

  @override
  Future<List<ModeloTurno>> obtenerTurnosDelDia(String sucursalId) async {
    if (errorSimulado != null) throw errorSimulado!;
    return turnos;
  }

  @override
  Future<ModeloClienteWalkin?> buscarClienteWalkinPorTelefono(
    String telefono,
  ) async => null;

  @override
  Future<Map<String, String>?> buscarClientePorEmail(String email) async =>
      null;

  @override
  Future<ModeloTurno> crearTurnoConCuenta({
    required String sucursalId,
    required String servicioId,
    required String clienteId,
    double? montoPrecobrado,
    MetodoPago? metodoPrecobrado,
  }) async {
    final turno = _turno('nuevo');
    turnos = [...turnos, turno];
    return turno;
  }

  @override
  Future<ModeloTurno> crearTurnoWalkin({
    required String sucursalId,
    required String servicioId,
    required String nombre,
    required String telefono,
    double? montoPrecobrado,
    MetodoPago? metodoPrecobrado,
  }) async {
    final turno = _turno('nuevo');
    turnos = [...turnos, turno];
    return turno;
  }

  @override
  Future<void> llamarTurno({
    required String turnoId,
    required String barberoId,
  }) async {
    ultimoLlamado = {'turnoId': turnoId, 'barberoId': barberoId};
  }

  @override
  Future<String> completarTurno({
    required String turnoId,
    double? monto,
    MetodoPago? metodo,
  }) async {
    if (errorSimulado != null) throw errorSimulado!;
    ultimoCompletadoId = turnoId;
    return 'cita-generada';
  }

  @override
  Future<void> cancelarTurno(String turnoId) async {}

  @override
  Future<ModoCobroCaja> obtenerModoCobroCaja() async => ModoCobroCaja.alFinal;

  @override
  Future<ModeloTurno> confirmarLlegadaCita(String citaId) async {
    if (errorSimulado != null) throw errorSimulado!;
    final turno = _turno(
      'turno-confirmado',
    ).copyWith(citaId: citaId, barberoId: 'bar1');
    turnos = [...turnos, turno];
    return turno;
  }
}

void main() {
  group('ControladorTurnos', () {
    test('build carga los turnos de la sucursal', () async {
      final falso = RepositorioTurnosFalso()..turnos = [_turno('t1')];
      final contenedor = ProviderContainer(
        overrides: [repositorioTurnosProvider.overrideWithValue(falso)],
      );
      addTearDown(contenedor.dispose);

      final resultado = await contenedor.read(
        controladorTurnosProvider('s1').future,
      );

      expect(resultado.length, 1);
    });

    test('llamarTurno llama al repositorio con los datos correctos', () async {
      final falso = RepositorioTurnosFalso();
      final contenedor = ProviderContainer(
        overrides: [repositorioTurnosProvider.overrideWithValue(falso)],
      );
      addTearDown(contenedor.dispose);

      await contenedor.read(controladorTurnosProvider('s1').future);
      await contenedor
          .read(controladorTurnosProvider('s1').notifier)
          .llamarTurno(turnoId: 't1', barberoId: 'bar1');

      expect(falso.ultimoLlamado, {'turnoId': 't1', 'barberoId': 'bar1'});
    });

    test('completarTurno con error lo expone en el estado', () async {
      final falso = RepositorioTurnosFalso();
      final contenedor = ProviderContainer(
        overrides: [repositorioTurnosProvider.overrideWithValue(falso)],
      );
      addTearDown(contenedor.dispose);

      await contenedor.read(controladorTurnosProvider('s1').future);
      falso.errorSimulado = const ExcepcionPermiso(
        'El turno debe estar en atención.',
      );

      await expectLater(
        () => contenedor
            .read(controladorTurnosProvider('s1').notifier)
            .completarTurno(turnoId: 't1'),
        throwsA(isA<ExcepcionPermiso>()),
      );

      final estado = contenedor.read(controladorTurnosProvider('s1'));
      expect(estado.hasError, isTrue);
    });
  });
}
