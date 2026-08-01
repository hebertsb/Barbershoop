import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/citas/datos/repositorio_citas.dart';
import 'package:barber_app/funcionalidades/citas/dominio/enum_estado_cita.dart';
import 'package:barber_app/funcionalidades/citas/dominio/modelo_cita.dart';
import 'package:barber_app/funcionalidades/citas/dominio/modelo_resumen_ingresos_barbero.dart';
import 'package:barber_app/funcionalidades/citas/presentacion/controladores/controlador_citas.dart';

class RepositorioCitasFalso implements RepositorioCitas {
  List<ModeloCita> citas = [];
  String? citaMarcadaNoAsistio;

  @override
  Future<List<ModeloCita>> obtenerCitasDelDia(String sucursalId) async {
    return citas.where((c) => c.sucursalId == sucursalId).toList();
  }

  @override
  Future<List<ModeloCita>> obtenerMisCitas() async => citas;

  @override
  Future<ModeloCita> marcarNoAsistio(String citaId) async {
    citaMarcadaNoAsistio = citaId;
    final indice = citas.indexWhere((c) => c.id == citaId);
    citas[indice] = citas[indice].copyWith(estado: EstadoCita.noAsistio);
    return citas[indice];
  }

  @override
  Future<ModeloResumenIngresosBarbero> obtenerResumenIngresosBarbero() async =>
      throw UnimplementedError();
}

void main() {
  group('ControladorCitas', () {
    test('build carga las citas de la sucursal solicitada', () async {
      final falso = RepositorioCitasFalso()
        ..citas = [
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
          ModeloCita(
            id: 'c2',
            barberiaId: 'b1',
            sucursalId: 's2',
            barberoId: 'bar1',
            servicioId: 'serv1',
            fechaHora: DateTime(2026, 7, 17, 11),
            duracionMin: 30,
            estado: EstadoCita.pendiente,
          ),
        ];
      final contenedor = ProviderContainer(
        overrides: [repositorioCitasProvider.overrideWithValue(falso)],
      );
      addTearDown(contenedor.dispose);

      final resultado = await contenedor.read(
        controladorCitasProvider('s1').future,
      );

      expect(resultado.length, 1);
      expect(resultado.first.id, 'c1');
    });

    test('marcarNoAsistio llama al repositorio y refresca la lista', () async {
      final falso = RepositorioCitasFalso()
        ..citas = [
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
      final contenedor = ProviderContainer(
        overrides: [repositorioCitasProvider.overrideWithValue(falso)],
      );
      addTearDown(contenedor.dispose);

      await contenedor.read(controladorCitasProvider('s1').future);
      await contenedor
          .read(controladorCitasProvider('s1').notifier)
          .marcarNoAsistio('c1');

      expect(falso.citaMarcadaNoAsistio, 'c1');
      final estado = contenedor.read(controladorCitasProvider('s1'));
      expect(estado.value!.first.estado, EstadoCita.noAsistio);
    });
  });
}
