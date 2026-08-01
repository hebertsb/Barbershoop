import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_barbero.dart';

void main() {
  group('ModeloBarbero', () {
    test('desdeJson y aJson hacen roundtrip completo con campos planos', () {
      final json = {
        'id': 'barbero-1',
        'perfil_id': 'perfil-1',
        'sucursal_id': 'sucursal-1',
        'barberia_id': 'barberia-1',
        'especialidades': ['corte', 'barba'],
        'activo': true,
        'nombre_perfil': 'Carlos Barbero',
        'url_foto_perfil': 'https://ejemplo.com/foto.png',
        'email_perfil': 'carlos@barberapp.com',
      };

      final barbero = ModeloBarbero.desdeJson(json);

      expect(barbero.id, 'barbero-1');
      expect(barbero.perfilId, 'perfil-1');
      expect(barbero.sucursalId, 'sucursal-1');
      expect(barbero.barberiaId, 'barberia-1');
      expect(barbero.especialidades, ['corte', 'barba']);
      expect(barbero.activo, true);
      expect(barbero.nombrePerfil, 'Carlos Barbero');
      expect(barbero.urlFotoPerfil, 'https://ejemplo.com/foto.png');
      expect(barbero.emailPerfil, 'carlos@barberapp.com');
      expect(barbero.aJson(), json);
    });

    test('desdeJson soporta join anidado de perfiles', () {
      final json = {
        'id': 'barbero-2',
        'perfil_id': 'perfil-2',
        'sucursal_id': 'sucursal-1',
        'barberia_id': 'barberia-1',
        'especialidades': [],
        'activo': true,
        'perfiles': {
          'nombre': 'Jorge Barbero',
          'url_foto': 'https://ejemplo.com/jorge.png',
          'email': 'jorge@barberapp.com',
        },
      };

      final barbero = ModeloBarbero.desdeJson(json);

      expect(barbero.id, 'barbero-2');
      expect(barbero.nombrePerfil, 'Jorge Barbero');
      expect(barbero.urlFotoPerfil, 'https://ejemplo.com/jorge.png');
      expect(barbero.emailPerfil, 'jorge@barberapp.com');
    });

    test('copyWith crea copia modificando atributos permitidos', () {
      final original = ModeloBarbero(
        id: 'barbero-3',
        perfilId: 'perfil-3',
        sucursalId: 'sucursal-1',
        barberiaId: 'barberia-1',
        especialidades: ['cejas'],
        activo: true,
      );

      final copia = original.copyWith(
        sucursalId: 'sucursal-2',
        especialidades: ['cejas', 'corte'],
        activo: false,
      );

      expect(copia.id, 'barbero-3');
      expect(copia.sucursalId, 'sucursal-2');
      expect(copia.especialidades, ['cejas', 'corte']);
      expect(copia.activo, false);
    });

    test('nivel es opcional y solo aparece en aJson si no es null', () {
      final sinNivel = ModeloBarbero(
        id: 'barbero-4',
        perfilId: 'perfil-4',
        sucursalId: 'sucursal-1',
        barberiaId: 'barberia-1',
        especialidades: const [],
        activo: true,
      );
      expect(sinNivel.nivel, isNull);
      expect(sinNivel.aJson().containsKey('nivel'), isFalse);

      final conNivel = ModeloBarbero.desdeJson({
        'id': 'barbero-5',
        'perfil_id': 'perfil-5',
        'sucursal_id': 'sucursal-1',
        'barberia_id': 'barberia-1',
        'especialidades': [],
        'activo': true,
        'nivel': 'master',
      });
      expect(conNivel.nivel, 'master');
      expect(conNivel.aJson()['nivel'], 'master');
    });

    test('copyWith con limpiarNivel:true limpia el nivel a null', () {
      final conNivel = ModeloBarbero(
        id: 'barbero-6',
        perfilId: 'perfil-6',
        sucursalId: 'sucursal-1',
        barberiaId: 'barberia-1',
        especialidades: const [],
        activo: true,
        nivel: 'senior',
      );
      final limpiado = conNivel.copyWith(limpiarNivel: true);
      expect(limpiado.nivel, isNull);
    });

    test(
      'copyWith con limpiarDescripcion:true limpia la descripcion a null',
      () {
        final conDescripcion = ModeloBarbero(
          id: 'barbero-9',
          perfilId: 'perfil-9',
          sucursalId: 'sucursal-1',
          barberiaId: 'barberia-1',
          especialidades: const [],
          activo: true,
          descripcion: 'Especialista en fades',
        );
        final limpiado = conDescripcion.copyWith(limpiarDescripcion: true);
        expect(limpiado.descripcion, isNull);
      },
    );

    test(
      'descripcion/calificacionPromedio/calificacionCantidad son opcionales y solo aparecen en aJson si no son null',
      () {
        final sinDatos = ModeloBarbero(
          id: 'barbero-8',
          perfilId: 'perfil-8',
          sucursalId: 'sucursal-1',
          barberiaId: 'barberia-1',
          especialidades: const [],
          activo: true,
        );
        expect(sinDatos.descripcion, isNull);
        expect(sinDatos.calificacionPromedio, isNull);
        expect(sinDatos.calificacionCantidad, isNull);
        expect(sinDatos.aJson().containsKey('descripcion'), isFalse);
        expect(sinDatos.aJson().containsKey('calificacion_promedio'), isFalse);
        expect(sinDatos.aJson().containsKey('calificacion_cantidad'), isFalse);

        final conDatos = ModeloBarbero.desdeJson({
          'id': 'barbero-7',
          'perfil_id': 'perfil-7',
          'sucursal_id': 'sucursal-1',
          'barberia_id': 'barberia-1',
          'especialidades': [],
          'activo': true,
          'descripcion': 'Especialista en fades',
          'calificacion_promedio': 4.8,
          'calificacion_cantidad': 12,
        });
        expect(conDatos.descripcion, 'Especialista en fades');
        expect(conDatos.calificacionPromedio, 4.8);
        expect(conDatos.calificacionCantidad, 12);
      },
    );

    test('telefonoPerfil se lee del JOIN anidado perfiles.telefono', () {
      final barbero = ModeloBarbero.desdeJson({
        'id': 'b1',
        'perfil_id': 'p1',
        'sucursal_id': 's1',
        'barberia_id': 'ba1',
        'especialidades': <String>[],
        'activo': true,
        'perfiles': {'nombre': 'Juan', 'telefono': '59171234567'},
      });
      expect(barbero.telefonoPerfil, '59171234567');
    });

    test(
      'telefonoPerfil cae al fallback plano telefono_perfil (RPC obtener_barberos_publicos)',
      () {
        final barbero = ModeloBarbero.desdeJson({
          'id': 'b1',
          'perfil_id': 'p1',
          'sucursal_id': 's1',
          'barberia_id': 'ba1',
          'especialidades': <String>[],
          'activo': true,
          'telefono_perfil': '59171234567',
        });
        expect(barbero.telefonoPerfil, '59171234567');
      },
    );

    test('telefonoPerfil sin ninguno de los dos queda null', () {
      final barbero = ModeloBarbero.desdeJson({
        'id': 'b1',
        'perfil_id': 'p1',
        'sucursal_id': 's1',
        'barberia_id': 'ba1',
        'especialidades': <String>[],
        'activo': true,
      });
      expect(barbero.telefonoPerfil, isNull);
    });
  });
}
