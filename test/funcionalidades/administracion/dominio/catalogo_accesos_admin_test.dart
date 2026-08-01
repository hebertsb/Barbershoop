import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/catalogo_accesos_admin.dart';

void main() {
  group('elegirAccesosRapidos', () {
    test(
      'con 4 rutas top devueltas, el resultado son esos 4 accesos en ese orden',
      () {
        final rutasTop = [
          '/administracion/reportes',
          '/administracion/almacen',
          '/administracion/sucursales',
          '/administracion/barberos',
        ];

        final resultado = elegirAccesosRapidos(rutasTop);

        expect(resultado.length, 4);
        expect(resultado.map((a) => a.ruta).toList(), rutasTop);
      },
    );

    test(
      'con 0 rutas top (admin nuevo), el resultado son las primeras 4 del catálogo en orden',
      () {
        final resultado = elegirAccesosRapidos(const []);

        expect(resultado.length, 4);
        expect(
          resultado.map((a) => a.ruta).toList(),
          catalogoAccesosAdmin.take(4).map((a) => a.ruta).toList(),
        );
      },
    );

    test(
      'con 2 rutas top, esas 2 van primero y se completa con el catálogo sin duplicar, hasta 4',
      () {
        // Elegidas deliberadamente para que NO sean las primeras del
        // catálogo, así se puede distinguir "top" de "relleno".
        final rutasTop = [
          '/administracion/ajustes-marca',
          '/administracion/promociones',
        ];

        final resultado = elegirAccesosRapidos(rutasTop);

        expect(resultado.length, 4);
        expect(resultado[0].ruta, '/administracion/ajustes-marca');
        expect(resultado[1].ruta, '/administracion/promociones');

        // El relleno son las primeras 2 del catálogo que todavía no
        // estaban incluidas (ninguna de las 2 rutas top coincide con las
        // primeras entradas del catálogo).
        final relleno = catalogoAccesosAdmin
            .where((a) => !rutasTop.contains(a.ruta))
            .take(2)
            .map((a) => a.ruta)
            .toList();
        expect(resultado[2].ruta, relleno[0]);
        expect(resultado[3].ruta, relleno[1]);

        // Sin duplicados.
        expect(resultado.map((a) => a.ruta).toSet().length, 4);
      },
    );
  });

  group('agruparAccesosPorCategoria', () {
    test(
      'el grupo Equipo contiene exactamente Barberos, Secretarias y Ranking '
      'de Barberos, en ese orden',
      () {
        final grupos = agruparAccesosPorCategoria(catalogoAccesosAdmin);
        final grupoEquipo = grupos.firstWhere((g) => g.key == 'Equipo');

        expect(
          grupoEquipo.value.map((a) => a.titulo).toList(),
          ['Barberos', 'Secretarias', 'Ranking de Barberos'],
        );
      },
    );

    test(
      'el grupo Sucursales y Servicios contiene exactamente Sucursales y Servicios, en ese orden',
      () {
        final grupos = agruparAccesosPorCategoria(catalogoAccesosAdmin);
        final grupoSucursales = grupos.firstWhere(
          (g) => g.key == 'Sucursales y Servicios',
        );

        expect(
          grupoSucursales.value.map((a) => a.titulo).toList(),
          ['Sucursales', 'Servicios'],
        );
      },
    );

    test(
      'con categorías repetidas y no contiguas, el agrupado junta los repetidos '
      'preservando el orden de primera aparición',
      () {
        const a = AccesoAdmin(
          titulo: 'A',
          subtitulo: 'sub a',
          icono: Icons.abc,
          ruta: '/a',
          categoria: 'Uno',
        );
        const b = AccesoAdmin(
          titulo: 'B',
          subtitulo: 'sub b',
          icono: Icons.abc,
          ruta: '/b',
          categoria: 'Dos',
        );
        const c = AccesoAdmin(
          titulo: 'C',
          subtitulo: 'sub c',
          icono: Icons.abc,
          ruta: '/c',
          categoria: 'Uno',
        );

        final grupos = agruparAccesosPorCategoria([a, b, c]);

        expect(grupos.map((g) => g.key).toList(), ['Uno', 'Dos']);
        expect(
          grupos.firstWhere((g) => g.key == 'Uno').value,
          [a, c],
        );
        expect(
          grupos.firstWhere((g) => g.key == 'Dos').value,
          [b],
        );
      },
    );
  });

  group('filtrarAccesosAdmin', () {
    const uno = AccesoAdmin(
      titulo: 'Barberos',
      subtitulo: 'Equipo de trabajo y horarios',
      icono: Icons.groups_outlined,
      ruta: '/administracion/barberos',
      categoria: 'Equipo',
    );
    const dos = AccesoAdmin(
      titulo: 'Servicios',
      subtitulo: 'Catálogo de cortes y precios',
      icono: Icons.content_cut_outlined,
      ruta: '/administracion/servicios',
      categoria: 'Sucursales y Servicios',
    );
    const tres = AccesoAdmin(
      titulo: 'Marca',
      subtitulo: 'Nombre, slogan, logo y color',
      icono: Icons.palette_outlined,
      ruta: '/administracion/ajustes-marca',
      categoria: 'Marca',
    );
    final catalogoPrueba = [uno, dos, tres];

    test('con consulta vacía, devuelve la lista completa sin cambios', () {
      final resultado = filtrarAccesosAdmin('', catalogoPrueba);
      expect(resultado, catalogoPrueba);
    });

    test('un prefijo exacto de un título devuelve ese resultado primero', () {
      final resultado = filtrarAccesosAdmin('barb', catalogoPrueba);
      expect(resultado.first, uno);
    });

    test(
      'una palabra que solo aparece en el subtítulo también lo encuentra',
      () {
        final resultado = filtrarAccesosAdmin('cortes', catalogoPrueba);
        expect(resultado, [dos]);
      },
    );

    test('una consulta sin coincidencias devuelve lista vacía', () {
      final resultado = filtrarAccesosAdmin('zzz-no-existe', catalogoPrueba);
      expect(resultado, isEmpty);
    });

    test('la búsqueda es case-insensitive', () {
      final resultado = filtrarAccesosAdmin('MARCA', catalogoPrueba);
      expect(resultado, [tres]);
    });
  });
}
