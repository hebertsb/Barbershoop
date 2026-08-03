import 'package:flutter/material.dart';

/// Un acceso a una sección de administración (ruta de navegación), usado
/// tanto por la sección "Acceso Rápido" rotativa del dashboard como por el
/// menú "Más". La igualdad se define únicamente por [ruta] -- es el
/// identificador natural de un acceso, y es lo que compara
/// [elegirAccesosRapidos] para no duplicar entradas.
class AccesoAdmin {
  const AccesoAdmin({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.ruta,
    required this.categoria,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final String ruta;
  final String categoria;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccesoAdmin && other.ruta == ruta);

  @override
  int get hashCode => ruta.hashCode;
}

/// Catálogo único de todas las secciones de administración accesibles desde
/// "Acceso Rápido" (rotativo, según uso) y el menú "Más". El orden de esta
/// lista es también el orden de respaldo cuando todavía no hay suficiente
/// historial de uso para completar los 4 accesos rápidos.
const List<AccesoAdmin> catalogoAccesosAdmin = [
  AccesoAdmin(
    titulo: 'Sucursales',
    subtitulo: 'Ubicaciones y teléfonos',
    icono: Icons.store_outlined,
    ruta: '/administracion/sucursales',
    categoria: 'Sucursales y Servicios',
  ),
  AccesoAdmin(
    titulo: 'Barberos',
    subtitulo: 'Equipo de trabajo y horarios',
    icono: Icons.groups_outlined,
    ruta: '/administracion/barberos',
    categoria: 'Equipo',
  ),
  AccesoAdmin(
    titulo: 'Almacén',
    subtitulo: 'Insumos, stock y asignaciones',
    icono: Icons.inventory_2_outlined,
    ruta: '/administracion/almacen',
    categoria: 'Inventario',
  ),
  AccesoAdmin(
    titulo: 'Reportes e ingresos',
    subtitulo: 'KPIs, servicios y Power BI',
    icono: Icons.analytics_outlined,
    ruta: '/administracion/reportes',
    categoria: 'Finanzas',
  ),
  AccesoAdmin(
    titulo: 'Actividad del Día',
    subtitulo: 'Citas y movimientos de hoy',
    icono: Icons.today_outlined,
    ruta: '/administracion/actividad-diaria',
    categoria: 'Operación y Control',
  ),
  AccesoAdmin(
    titulo: 'Control y Auditoría',
    subtitulo: 'Registro de acciones del equipo',
    icono: Icons.shield_outlined,
    ruta: '/administracion/control-auditoria',
    categoria: 'Operación y Control',
  ),
  AccesoAdmin(
    titulo: 'Servicios',
    subtitulo: 'Catálogo de cortes y precios',
    icono: Icons.content_cut_outlined,
    ruta: '/administracion/servicios',
    categoria: 'Sucursales y Servicios',
  ),
  AccesoAdmin(
    titulo: 'Secretarias',
    subtitulo: 'Recepción y acceso a caja',
    icono: Icons.badge_outlined,
    ruta: '/administracion/secretarias',
    categoria: 'Equipo',
  ),
  AccesoAdmin(
    titulo: 'Ranking de Barberos',
    subtitulo: 'Competencias, premios e insignias',
    icono: Icons.emoji_events_outlined,
    ruta: '/administracion/ranking-barberos',
    categoria: 'Equipo',
  ),
  AccesoAdmin(
    titulo: 'Reportes de insumos',
    subtitulo: 'Dañados, agotados o perdidos',
    icono: Icons.report_problem_outlined,
    ruta: '/administracion/reportes-insumos',
    categoria: 'Inventario',
  ),
  AccesoAdmin(
    titulo: 'Promociones y eventos',
    subtitulo: 'Descuentos, fechas y validez',
    icono: Icons.local_offer_outlined,
    ruta: '/administracion/promociones',
    categoria: 'Clientes e Incentivos',
  ),
  AccesoAdmin(
    titulo: 'Programas de Fidelidad',
    subtitulo: 'Premios por citas acumuladas',
    icono: Icons.loyalty_outlined,
    ruta: '/administracion/programas-fidelidad',
    categoria: 'Clientes e Incentivos',
  ),
  AccesoAdmin(
    titulo: 'Verificar pagos',
    subtitulo: 'Comprobantes QR por revisar',
    icono: Icons.qr_code_scanner_outlined,
    ruta: '/administracion/verificacion-pagos',
    categoria: 'Finanzas',
  ),
  AccesoAdmin(
    titulo: 'Ajustes de pago',
    subtitulo: 'QR del banco y modo de pago',
    icono: Icons.settings_outlined,
    ruta: '/administracion/ajustes-pagos',
    categoria: 'Finanzas',
  ),
  AccesoAdmin(
    titulo: 'Marca',
    subtitulo: 'Nombre, slogan, logo y color',
    icono: Icons.palette_outlined,
    ruta: '/administracion/ajustes-marca',
    categoria: 'Marca',
  ),
];

/// Elige como mucho [maximo] accesos rápidos: primero las rutas de
/// [rutasTop] (más usadas por el admin en los últimos 30 días, ya vienen
/// ordenadas de mayor a menor uso) mapeadas a su [AccesoAdmin] en
/// [catalogoAccesosAdmin] -- ignorando rutas que ya no existan en el
/// catálogo -- y, si no alcanzan [maximo], completa recorriendo el
/// catálogo EN ORDEN con las que todavía no estén incluidas. Así un admin
/// nuevo (sin historial) siempre ve las primeras [maximo] del catálogo, y
/// uno con poco historial ve su(s) ruta(s) usada(s) primero.
List<AccesoAdmin> elegirAccesosRapidos(
  List<String> rutasTop, {
  int maximo = 4,
}) {
  final resultado = <AccesoAdmin>[];

  for (final ruta in rutasTop) {
    AccesoAdmin? acceso;
    for (final candidato in catalogoAccesosAdmin) {
      if (candidato.ruta == ruta) {
        acceso = candidato;
        break;
      }
    }
    if (acceso != null && !resultado.contains(acceso)) {
      resultado.add(acceso);
    }
    if (resultado.length == maximo) break;
  }

  if (resultado.length < maximo) {
    for (final acceso in catalogoAccesosAdmin) {
      if (!resultado.contains(acceso)) {
        resultado.add(acceso);
      }
      if (resultado.length == maximo) break;
    }
  }

  return resultado;
}

/// Agrupa el catálogo por categoría, preservando el orden: cada grupo
/// aparece en la posición de la PRIMERA aparición de su categoría en
/// [catalogo], y dentro de cada grupo los accesos mantienen su orden
/// original. Así no hace falta reordenar `catalogoAccesosAdmin` para
/// que la UI muestre las secciones agrupadas correctamente.
List<MapEntry<String, List<AccesoAdmin>>> agruparAccesosPorCategoria(
  List<AccesoAdmin> catalogo,
) {
  final grupos = <String, List<AccesoAdmin>>{};
  for (final acceso in catalogo) {
    grupos.putIfAbsent(acceso.categoria, () => []).add(acceso);
  }
  return grupos.entries.toList();
}

/// Filtra el catálogo por [consulta] (case-insensitive, sin acentos no
/// hace falta manejar), buscando coincidencias en título y subtítulo.
/// Los resultados cuyo título EMPIEZA con la consulta van primero (más
/// relevantes), seguidos del resto de coincidencias -- en ambos casos
/// preservando el orden original del catálogo dentro de cada grupo.
List<AccesoAdmin> filtrarAccesosAdmin(
  String consulta,
  List<AccesoAdmin> catalogo,
) {
  final query = consulta.trim().toLowerCase();
  if (query.isEmpty) return catalogo;

  final empiezanConQuery = <AccesoAdmin>[];
  final contienenQuery = <AccesoAdmin>[];

  for (final acceso in catalogo) {
    final titulo = acceso.titulo.toLowerCase();
    final subtitulo = acceso.subtitulo.toLowerCase();
    if (titulo.startsWith(query)) {
      empiezanConQuery.add(acceso);
    } else if (titulo.contains(query) || subtitulo.contains(query)) {
      contienenQuery.add(acceso);
    }
  }

  return [...empiezanConQuery, ...contienenQuery];
}