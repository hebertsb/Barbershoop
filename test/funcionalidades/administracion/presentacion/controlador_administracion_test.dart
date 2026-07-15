import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/administracion/datos/repositorio_administracion.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_barbero.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_horario_barbero.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_servicio.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_sucursal.dart';
import 'package:barber_app/funcionalidades/administracion/presentacion/controladores/controlador_barberos.dart';
import 'package:barber_app/funcionalidades/administracion/presentacion/controladores/controlador_horarios_barbero.dart';
import 'package:barber_app/funcionalidades/administracion/presentacion/controladores/controlador_servicios.dart';
import 'package:barber_app/funcionalidades/administracion/presentacion/controladores/controlador_sucursales.dart';
import 'package:barber_app/nucleo/errores/excepciones_app.dart';

class RepositorioAdministracionFalso implements RepositorioAdministracion {
  List<ModeloSucursal> sucursales = [];
  List<ModeloServicio> servicios = [];
  List<ModeloBarbero> barberos = [];
  Map<String, List<ModeloHorarioBarbero>> horarios = {};
  
  Object? errorSimulado;

  @override
  Future<List<ModeloSucursal>> obtenerSucursales() async {
    if (errorSimulado != null) throw errorSimulado!;
    return sucursales;
  }

  @override
  Future<ModeloSucursal> guardarSucursal(ModeloSucursal sucursal) async {
    if (errorSimulado != null) throw errorSimulado!;
    final index = sucursales.indexWhere((element) => element.id == sucursal.id);
    if (index != -1) {
      sucursales[index] = sucursal;
    } else {
      sucursales.add(sucursal);
    }
    return sucursal;
  }

  @override
  Future<List<ModeloServicio>> obtenerServicios() async {
    if (errorSimulado != null) throw errorSimulado!;
    return servicios;
  }

  @override
  Future<ModeloServicio> guardarServicio(ModeloServicio servicio) async {
    if (errorSimulado != null) throw errorSimulado!;
    final index = servicios.indexWhere((element) => element.id == servicio.id);
    if (index != -1) {
      servicios[index] = servicio;
    } else {
      servicios.add(servicio);
    }
    return servicio;
  }

  @override
  Future<List<ModeloBarbero>> obtenerBarberos() async {
    if (errorSimulado != null) throw errorSimulado!;
    return barberos;
  }

  @override
  Future<void> invitarBarbero({
    required String email,
    required String sucursalId,
    required List<String> especialidades,
  }) async {
    if (errorSimulado != null) throw errorSimulado!;
    barberos.add(ModeloBarbero(
      id: 'barbero-nuevo',
      perfilId: 'perfil-nuevo',
      sucursalId: sucursalId,
      barberiaId: 'barberia-1',
      especialidades: especialidades,
      activo: true,
      nombrePerfil: 'Nuevo Barbero',
      emailPerfil: email,
    ));
  }

  @override
  Future<void> actualizarEstadoBarbero(String barberoId, bool activo) async {
    if (errorSimulado != null) throw errorSimulado!;
    final index = barberos.indexWhere((element) => element.id == barberoId);
    if (index != -1) {
      barberos[index] = barberos[index].copyWith(activo: activo);
    }
  }

  @override
  Future<List<ModeloHorarioBarbero>> obtenerHorariosBarbero(String barberoId) async {
    if (errorSimulado != null) throw errorSimulado!;
    return horarios[barberoId] ?? [];
  }

  @override
  Future<void> guardarHorariosBarbero(String barberoId, List<ModeloHorarioBarbero> nuevosHorarios) async {
    if (errorSimulado != null) throw errorSimulado!;
    horarios[barberoId] = nuevosHorarios;
  }
}

void main() {
  group('ControladorSucursales', () {
    test('Carga sucursales exitosamente', () async {
      final falso = RepositorioAdministracionFalso()
        ..sucursales = [
          ModeloSucursal(id: 's1', barberiaId: 'b1', nombre: 'Sucursal A', activo: true),
        ];
      final contenedor = ProviderContainer(overrides: [
        repositorioAdministracionProvider.overrideWithValue(falso),
      ]);
      addTearDown(contenedor.dispose);

      final lista = await contenedor.read(controladorSucursalesProvider.future);
      expect(lista.length, 1);
      expect(lista.first.nombre, 'Sucursal A');
    });

    test('Guardar sucursal actualiza el estado', () async {
      final falso = RepositorioAdministracionFalso();
      final contenedor = ProviderContainer(overrides: [
        repositorioAdministracionProvider.overrideWithValue(falso),
      ]);
      addTearDown(contenedor.dispose);

      await contenedor.read(controladorSucursalesProvider.future);
      final nueva = ModeloSucursal(id: 's2', barberiaId: 'b1', nombre: 'Sucursal B', activo: true);
      
      await contenedor.read(controladorSucursalesProvider.notifier).guardarSucursal(nueva);
      
      final estado = contenedor.read(controladorSucursalesProvider);
      expect(estado.value?.length, 1);
      expect(estado.value?.first.nombre, 'Sucursal B');
    });
  });

  group('ControladorServicios', () {
    test('Guardar servicio agrega nuevo e inyecta en lista', () async {
      final falso = RepositorioAdministracionFalso();
      final contenedor = ProviderContainer(overrides: [
        repositorioAdministracionProvider.overrideWithValue(falso),
      ]);
      addTearDown(contenedor.dispose);

      await contenedor.read(controladorServiciosProvider.future);
      final serv = ModeloServicio(id: 'serv1', barberiaId: 'b1', nombre: 'Corte', precio: 50.0, duracionMin: 30, activo: true);
      
      await contenedor.read(controladorServiciosProvider.notifier).guardarServicio(serv);
      
      final lista = contenedor.read(controladorServiciosProvider).value;
      expect(lista?.length, 1);
      expect(lista?.first.nombre, 'Corte');
    });
  });

  group('ControladorBarberos', () {
    test('Invitar barbero recarga la lista', () async {
      final falso = RepositorioAdministracionFalso();
      final contenedor = ProviderContainer(overrides: [
        repositorioAdministracionProvider.overrideWithValue(falso),
      ]);
      addTearDown(contenedor.dispose);

      await contenedor.read(controladorBarberosProvider.future);
      await contenedor.read(controladorBarberosProvider.notifier).invitarBarbero(
        email: 'juan@barberia.com',
        sucursalId: 's1',
        especialidades: ['corte'],
      );

      final lista = contenedor.read(controladorBarberosProvider).value;
      expect(lista?.length, 1);
      expect(lista?.first.emailPerfil, 'juan@barberia.com');
      expect(lista?.first.nombrePerfil, 'Nuevo Barbero');
    });

    test('Cambiar estado activo del barbero actualiza estado inmutablemente', () async {
      final falso = RepositorioAdministracionFalso()
        ..barberos = [
          ModeloBarbero(id: 'b1', perfilId: 'p1', sucursalId: 's1', barberiaId: 'tenant1', especialidades: [], activo: true),
        ];
      final contenedor = ProviderContainer(overrides: [
        repositorioAdministracionProvider.overrideWithValue(falso),
      ]);
      addTearDown(contenedor.dispose);

      await contenedor.read(controladorBarberosProvider.future);
      await contenedor.read(controladorBarberosProvider.notifier).actualizarEstadoBarbero('b1', false);

      final lista = contenedor.read(controladorBarberosProvider).value;
      expect(lista?.first.activo, isFalse);
    });
  });

  group('ControladorHorariosBarbero', () {
    test('Cargar y guardar horarios de un barbero familiar', () async {
      final falso = RepositorioAdministracionFalso();
      final contenedor = ProviderContainer(overrides: [
        repositorioAdministracionProvider.overrideWithValue(falso),
      ]);
      addTearDown(contenedor.dispose);

      final barberoId = 'barb-99';
      final horariosFuturo = await contenedor.read(controladorHorariosBarberoProvider(barberoId).future);
      expect(horariosFuturo, isEmpty);

      final nuevos = [
        ModeloHorarioBarbero(id: 'h1', barberoId: barberoId, barberiaId: 'b1', diaSemana: 1, horaInicio: '09:00', horaFin: '17:00'),
      ];

      await contenedor.read(controladorHorariosBarberoProvider(barberoId).notifier).guardarHorarios(nuevos);

      final guardados = contenedor.read(controladorHorariosBarberoProvider(barberoId)).value;
      expect(guardados?.length, 1);
      expect(guardados?.first.diaSemana, 1);
      expect(guardados?.first.horaInicio, '09:00');
    });
  });
}
