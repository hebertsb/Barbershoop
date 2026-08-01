import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/citas/datos/repositorio_citas.dart';
import 'package:barber_app/funcionalidades/citas/dominio/enum_estado_cita.dart';
import 'package:barber_app/funcionalidades/citas/dominio/modelo_cita.dart';
import 'package:barber_app/funcionalidades/citas/dominio/modelo_resumen_ingresos_barbero.dart';
import 'package:barber_app/funcionalidades/citas/presentacion/controladores/controlador_mis_citas.dart';
import 'package:barber_app/funcionalidades/reservas/datos/repositorio_reservas.dart';
import 'package:barber_app/funcionalidades/reservas/dominio/modelo_horario_disponible.dart';
import 'package:barber_app/funcionalidades/reservas/dominio/modelo_slot_grilla.dart';

class RepositorioCitasFalso implements RepositorioCitas {
  List<ModeloCita> misCitas = [];

  @override
  Future<List<ModeloCita>> obtenerCitasDelDia(String sucursalId) async => [];

  @override
  Future<List<ModeloCita>> obtenerMisCitas() async => misCitas;

  @override
  Future<ModeloCita> marcarNoAsistio(String citaId) async =>
      throw UnimplementedError();

  @override
  Future<ModeloResumenIngresosBarbero> obtenerResumenIngresosBarbero() async =>
      throw UnimplementedError();
}

class RepositorioReservasFalso implements RepositorioReservas {
  String? citaCanceladaId;
  Exception? errorCancelacion;

  @override
  Future<List<ModeloHorarioDisponible>> obtenerHorariosDisponibles({
    required String sucursalId,
    required String servicioId,
    required DateTime fecha,
    String? barberoId,
    String? promocionId,
  }) async => throw UnimplementedError();

  @override
  Future<List<ModeloSlotGrilla>> obtenerGrillaHorarios({
    required String sucursalId,
    required String servicioId,
    required DateTime fecha,
    required String barberoId,
    String? promocionId,
  }) async {
    return [];
  }

  @override
  Future<ModeloCita> reservarCita({
    required String sucursalId,
    required String servicioId,
    String? barberoId,
    required DateTime fechaHora,
    String? promocionId,
  }) async => throw UnimplementedError();

  @override
  Future<void> cancelarCita(String citaId) async {
    citaCanceladaId = citaId;
    if (errorCancelacion != null) throw errorCancelacion!;
  }
}

void main() {
  group('ControladorMisCitas', () {
    test('build carga las citas del cliente logueado', () async {
      final falso = RepositorioCitasFalso()
        ..misCitas = [
          ModeloCita(
            id: 'c1',
            barberiaId: 'b1',
            sucursalId: 's1',
            barberoId: 'bar1',
            servicioId: 'serv1',
            fechaHora: DateTime(2026, 7, 17, 10),
            duracionMin: 30,
            estado: EstadoCita.confirmada,
          ),
        ];
      final contenedor = ProviderContainer(
        overrides: [repositorioCitasProvider.overrideWithValue(falso)],
      );
      addTearDown(contenedor.dispose);

      final resultado = await contenedor.read(
        controladorMisCitasProvider.future,
      );

      expect(resultado.length, 1);
      expect(resultado.first.id, 'c1');
    });

    test(
      'cancelar llama a la RPC de cancelacion y refresca la lista',
      () async {
        final falsoCitas = RepositorioCitasFalso()
          ..misCitas = [
            ModeloCita(
              id: 'c1',
              barberiaId: 'b1',
              sucursalId: 's1',
              barberoId: 'bar1',
              servicioId: 'serv1',
              fechaHora: DateTime(2026, 7, 17, 10),
              duracionMin: 30,
              estado: EstadoCita.pendiente,
            ),
          ];
        final falsoReservas = RepositorioReservasFalso();
        final contenedor = ProviderContainer(
          overrides: [
            repositorioCitasProvider.overrideWithValue(falsoCitas),
            repositorioReservasProvider.overrideWithValue(falsoReservas),
          ],
        );
        addTearDown(contenedor.dispose);

        await contenedor.read(controladorMisCitasProvider.future);
        // La cita ya no está pendiente del lado del servidor tras cancelar:
        // el refresco posterior a la RPC debe reflejarlo.
        falsoCitas.misCitas = [];

        await contenedor
            .read(controladorMisCitasProvider.notifier)
            .cancelar('c1');

        expect(falsoReservas.citaCanceladaId, 'c1');
        final resultado = contenedor.read(controladorMisCitasProvider).value;
        expect(resultado, isEmpty);
      },
    );

    test('cancelar propaga el error de la RPC sin romper el estado', () async {
      final falsoCitas = RepositorioCitasFalso();
      final falsoReservas = RepositorioReservasFalso()
        ..errorCancelacion = Exception('Esta cita ya no se puede cancelar.');
      final contenedor = ProviderContainer(
        overrides: [
          repositorioCitasProvider.overrideWithValue(falsoCitas),
          repositorioReservasProvider.overrideWithValue(falsoReservas),
        ],
      );
      addTearDown(contenedor.dispose);

      await contenedor.read(controladorMisCitasProvider.future);

      await expectLater(
        () => contenedor
            .read(controladorMisCitasProvider.notifier)
            .cancelar('c1'),
        throwsException,
      );
    });
  });

  group('proximaCitaProvider', () {
    ModeloCita crearCita({
      required String id,
      required DateTime fechaHora,
      required EstadoCita estado,
    }) {
      return ModeloCita(
        id: id,
        barberiaId: 'b1',
        sucursalId: 's1',
        barberoId: 'bar1',
        servicioId: 'serv1',
        fechaHora: fechaHora,
        duracionMin: 30,
        estado: estado,
      );
    }

    test('devuelve la cita futura pendiente/confirmada mas cercana', () async {
      final ahora = DateTime.now();
      final falso = RepositorioCitasFalso()
        ..misCitas = [
          // Pasada: no cuenta.
          crearCita(
            id: 'pasada',
            fechaHora: ahora.subtract(const Duration(days: 1)),
            estado: EstadoCita.confirmada,
          ),
          // Cancelada en el futuro: no cuenta.
          crearCita(
            id: 'cancelada',
            fechaHora: ahora.add(const Duration(hours: 1)),
            estado: EstadoCita.cancelada,
          ),
          // Futura lejana: no es la mas cercana.
          crearCita(
            id: 'lejana',
            fechaHora: ahora.add(const Duration(days: 5)),
            estado: EstadoCita.pendiente,
          ),
          // Futura mas cercana: debe ganar.
          crearCita(
            id: 'cercana',
            fechaHora: ahora.add(const Duration(hours: 2)),
            estado: EstadoCita.confirmada,
          ),
          // Futura intermedia.
          crearCita(
            id: 'intermedia',
            fechaHora: ahora.add(const Duration(days: 1)),
            estado: EstadoCita.pendiente,
          ),
        ];
      final contenedor = ProviderContainer(
        overrides: [repositorioCitasProvider.overrideWithValue(falso)],
      );
      addTearDown(contenedor.dispose);

      await contenedor.read(controladorMisCitasProvider.future);
      final proxima = contenedor.read(proximaCitaProvider);

      expect(proxima?.id, 'cercana');
    });

    test('devuelve null cuando no hay citas que califiquen', () async {
      final ahora = DateTime.now();
      final falso = RepositorioCitasFalso()
        ..misCitas = [
          crearCita(
            id: 'pasada',
            fechaHora: ahora.subtract(const Duration(days: 1)),
            estado: EstadoCita.confirmada,
          ),
          crearCita(
            id: 'cancelada',
            fechaHora: ahora.add(const Duration(hours: 1)),
            estado: EstadoCita.cancelada,
          ),
          crearCita(
            id: 'no_asistio',
            fechaHora: ahora.subtract(const Duration(hours: 3)),
            estado: EstadoCita.noAsistio,
          ),
        ];
      final contenedor = ProviderContainer(
        overrides: [repositorioCitasProvider.overrideWithValue(falso)],
      );
      addTearDown(contenedor.dispose);

      await contenedor.read(controladorMisCitasProvider.future);
      final proxima = contenedor.read(proximaCitaProvider);

      expect(proxima, isNull);
    });
  });
}
