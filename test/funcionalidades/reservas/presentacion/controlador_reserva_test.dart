import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/citas/dominio/enum_estado_cita.dart';
import 'package:barber_app/funcionalidades/citas/dominio/modelo_cita.dart';
import 'package:barber_app/funcionalidades/reservas/datos/repositorio_reservas.dart';
import 'package:barber_app/funcionalidades/reservas/dominio/modelo_horario_disponible.dart';
import 'package:barber_app/funcionalidades/reservas/dominio/modelo_slot_grilla.dart';
import 'package:barber_app/funcionalidades/reservas/presentacion/controladores/controlador_reserva.dart';

class RepositorioReservasFalso implements RepositorioReservas {
  Map<String, dynamic>? ultimaReserva;
  Exception? errorSimulado;
  String? citaCanceladaId;
  Exception? errorCancelacion;

  @override
  Future<List<ModeloHorarioDisponible>> obtenerHorariosDisponibles({
    required String sucursalId,
    required String servicioId,
    required DateTime fecha,
    String? barberoId,
    String? promocionId,
  }) async {
    return [];
  }

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
  }) async {
    if (errorSimulado != null) throw errorSimulado!;
    ultimaReserva = {
      'sucursalId': sucursalId,
      'servicioId': servicioId,
      'barberoId': barberoId,
      'fechaHora': fechaHora,
      'promocionId': promocionId,
    };
    return ModeloCita(
      id: 'cita-nueva',
      barberiaId: 'b1',
      sucursalId: sucursalId,
      barberoId: barberoId ?? 'barbero-resuelto',
      servicioId: servicioId,
      fechaHora: fechaHora,
      duracionMin: 30,
      estado: EstadoCita.pendiente,
    );
  }

  @override
  Future<void> cancelarCita(String citaId) async {
    citaCanceladaId = citaId;
    if (errorCancelacion != null) throw errorCancelacion!;
  }
}

void main() {
  group('ControladorReserva', () {
    test('acumula las selecciones a traves de los pasos del wizard', () {
      final contenedor = ProviderContainer(
        overrides: [
          repositorioReservasProvider.overrideWithValue(
            RepositorioReservasFalso(),
          ),
        ],
      );
      addTearDown(contenedor.dispose);

      final notificador = contenedor.read(controladorReservaProvider.notifier);
      notificador.seleccionarSucursal('sucursal-1');
      notificador.seleccionarServicio('servicio-1');
      notificador.seleccionarBarberoEspecifico('barbero-1');

      final estado = contenedor.read(controladorReservaProvider);
      expect(estado.sucursalId, 'sucursal-1');
      expect(estado.servicioId, 'servicio-1');
      expect(estado.barberoId, 'barbero-1');
      expect(estado.cualquieraSeleccionado, isFalse);
    });

    test(
      'seleccionarCualquiera limpia un barbero especifico elegido antes',
      () {
        final contenedor = ProviderContainer(
          overrides: [
            repositorioReservasProvider.overrideWithValue(
              RepositorioReservasFalso(),
            ),
          ],
        );
        addTearDown(contenedor.dispose);

        final notificador = contenedor.read(
          controladorReservaProvider.notifier,
        );
        notificador.seleccionarBarberoEspecifico('barbero-1');
        notificador.seleccionarCualquiera();

        final estado = contenedor.read(controladorReservaProvider);
        expect(estado.barberoId, isNull);
        expect(estado.cualquieraSeleccionado, isTrue);
      },
    );

    test('confirmar llama al repositorio con los datos acumulados', () async {
      final falso = RepositorioReservasFalso();
      final contenedor = ProviderContainer(
        overrides: [repositorioReservasProvider.overrideWithValue(falso)],
      );
      addTearDown(contenedor.dispose);

      final notificador = contenedor.read(controladorReservaProvider.notifier);
      final fecha = DateTime(2026, 7, 20, 13, 0);
      notificador.seleccionarSucursal('sucursal-1');
      notificador.seleccionarServicio('servicio-1');
      notificador.seleccionarBarberoEspecifico('barbero-1');
      notificador.seleccionarHorario(fecha);

      final resultado = await notificador.confirmar();

      expect(falso.ultimaReserva!['sucursalId'], 'sucursal-1');
      expect(falso.ultimaReserva!['servicioId'], 'servicio-1');
      expect(falso.ultimaReserva!['barberoId'], 'barbero-1');
      expect(falso.ultimaReserva!['fechaHora'], fecha);
      expect(resultado.cita.id, 'cita-nueva');
      expect(resultado.cancelacionAnteriorFallo, isFalse);
    });

    test(
      'confirmar sin sucursal/servicio/horario elegidos lanza excepcion',
      () {
        final contenedor = ProviderContainer(
          overrides: [
            repositorioReservasProvider.overrideWithValue(
              RepositorioReservasFalso(),
            ),
          ],
        );
        addTearDown(contenedor.dispose);

        final notificador = contenedor.read(
          controladorReservaProvider.notifier,
        );

        expect(() => notificador.confirmar(), throwsException);
      },
    );

    test(
      'iniciarReprogramacion precarga sucursal/servicio y deja barbero/horario en null',
      () {
        final contenedor = ProviderContainer(
          overrides: [
            repositorioReservasProvider.overrideWithValue(
              RepositorioReservasFalso(),
            ),
          ],
        );
        addTearDown(contenedor.dispose);

        final notificador = contenedor.read(
          controladorReservaProvider.notifier,
        );
        notificador.seleccionarBarberoEspecifico('barbero-viejo');
        notificador.iniciarReprogramacion(
          sucursalId: 'sucursal-1',
          servicioId: 'servicio-1',
          citaIdAReemplazar: 'cita-vieja',
        );

        final estado = contenedor.read(controladorReservaProvider);
        expect(estado.sucursalId, 'sucursal-1');
        expect(estado.servicioId, 'servicio-1');
        expect(estado.barberoId, isNull);
        expect(estado.cualquieraSeleccionado, isFalse);
        expect(estado.fechaHora, isNull);
        expect(estado.citaIdAReemplazar, 'cita-vieja');
      },
    );

    test(
      'confirmar tras iniciarReprogramacion cancela la cita vieja luego de crear la nueva',
      () async {
        final falso = RepositorioReservasFalso();
        final contenedor = ProviderContainer(
          overrides: [repositorioReservasProvider.overrideWithValue(falso)],
        );
        addTearDown(contenedor.dispose);

        final notificador = contenedor.read(
          controladorReservaProvider.notifier,
        );
        notificador.iniciarReprogramacion(
          sucursalId: 'sucursal-1',
          servicioId: 'servicio-1',
          citaIdAReemplazar: 'cita-vieja',
        );
        notificador.seleccionarBarberoEspecifico('barbero-1');
        notificador.seleccionarHorario(DateTime(2026, 7, 20, 13, 0));

        final resultado = await notificador.confirmar();

        expect(resultado.cita.id, 'cita-nueva');
        expect(falso.citaCanceladaId, 'cita-vieja');
        expect(resultado.cancelacionAnteriorFallo, isFalse);
      },
    );

    test(
      'confirmar tras iniciarReprogramacion no falla si la cancelacion de la cita vieja falla',
      () async {
        final falso = RepositorioReservasFalso()
          ..errorCancelacion = Exception('boom');
        final contenedor = ProviderContainer(
          overrides: [repositorioReservasProvider.overrideWithValue(falso)],
        );
        addTearDown(contenedor.dispose);

        final notificador = contenedor.read(
          controladorReservaProvider.notifier,
        );
        notificador.iniciarReprogramacion(
          sucursalId: 'sucursal-1',
          servicioId: 'servicio-1',
          citaIdAReemplazar: 'cita-vieja',
        );
        notificador.seleccionarBarberoEspecifico('barbero-1');
        notificador.seleccionarHorario(DateTime(2026, 7, 20, 13, 0));

        final resultado = await notificador.confirmar();

        expect(resultado.cita.id, 'cita-nueva');
        expect(falso.citaCanceladaId, 'cita-vieja');
        expect(
          resultado.cancelacionAnteriorFallo,
          isTrue,
          reason:
              'confirmar() debe reportar que el cancelado de la cita vieja '
              'fallo, para que la UI pueda avisarle al cliente.',
        );
      },
    );

    test('confirmar sin citaIdAReemplazar no llama a cancelarCita', () async {
      final falso = RepositorioReservasFalso();
      final contenedor = ProviderContainer(
        overrides: [repositorioReservasProvider.overrideWithValue(falso)],
      );
      addTearDown(contenedor.dispose);

      final notificador = contenedor.read(controladorReservaProvider.notifier);
      notificador.seleccionarSucursal('sucursal-1');
      notificador.seleccionarServicio('servicio-1');
      notificador.seleccionarBarberoEspecifico('barbero-1');
      notificador.seleccionarHorario(DateTime(2026, 7, 20, 13, 0));

      await notificador.confirmar();

      expect(falso.citaCanceladaId, isNull);
    });
  });
}
