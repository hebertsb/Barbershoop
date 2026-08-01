import 'package:flutter/material.dart';

/// Un acceso del menú de administración: usado tanto en el dashboard
/// ("Acceso Rápido", máximo 4, rotativos) como en el menú "Más" (catálogo
/// completo).
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
}

/// Catálogo único de todos los accesos de administración -- unifica lo que
/// antes vivía por separado (y desincronizado) en el dashboard y en el menú
/// "Más". El orden acá define el orden de relleno de `elegirAccesosRapidos`
/// y el agrupado de `agruparAccesosPorCategoria`.
const catalogoAccesosAdmin = <AccesoAdmin>[
  AccesoAdmin(
    titulo: 'Sucursales',
    subtitulo: 'Locales, horarios y ubicación',
    icono: Icons.store_outlined,
    ruta: '/administracion/sucursales',
    categoria: 'Sucursales y Servicios',
  ),
  AccesoAdmin(
    titulo: 'Servicios',
    subtitulo: 'Catálogo de cortes y precios',
    icono: Icons.content_cut_outlined,
    ruta: '/administracion/servicios',
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
    titulo: 'Secretarias',
    subtitulo: 'Acceso del personal de mostrador',
    icono: Icons.support_agent_outlined,
    ruta: '/administracion/secretarias',
    categoria: 'Equipo',
  ),
  AccesoAdmin(
    titulo: 'Ranking de Barberos',
    subtitulo: 'Incentivos y medallas por desempeño',
    icono: Icons.emoji_events_outlined,
    ruta: '/administracion/ranking-barberos',
    categoria: 'Equipo',
  ),
  AccesoAdmin(
    titulo: 'Reportes',
    subtitulo: 'Ingresos, servicios y clientes frecuentes',
    icono: Icons.bar_chart_outlined,
    ruta: '/administracion/reportes',
    categoria: 'Reportes',
  ),
  AccesoAdmin(
    titulo: 'Actividad Diaria',
    subtitulo: 'Citas atendidas y clientes nuevos por día',
    icono: Icons.event_note_outlined,
    ruta: '/administracion/actividad-diaria',
    categoria: 'Reportes',
  ),
  AccesoAdmin(
    titulo: 'Control y Auditoría',
    subtitulo: 'Pagos, ausentismo y actividad por usuario',
    icono: Icons.fact_check_outlined,
    ruta: '/administracion/control-auditoria',
    categoria: 'Reportes',
  ),
  AccesoAdmin(
    titulo: 'Almacén',
    subtitulo: 'Insumos, stock y asignaciones',
    icono: Icons.inventory_2_outlined,
    ruta: '/administracion/almacen',
    categoria: 'Inventario',
  ),
  AccesoAdmin(
    titulo: 'Promociones',
    subtitulo: 'Descuentos y combos vigentes',
    icono: Icons.local_offer_outlined,
    ruta: '/administracion/promociones',
    categoria: 'Promociones y Fidelidad',
  ),
  AccesoAdmin(
    titulo: 'Fidelidad',
    subtitulo: 'Programas de puntos por citas',
    icono: Icons.card_giftcard_outlined,
    ruta: '/administracion/fidelidad',
    categoria: 'Promociones y Fidelidad',
  ),
  AccesoAdmin(
    titulo: 'Marca',
    subtitulo: 'Nombre, slogan, logo y color',
    icono: Icons.palette_outlined,
    ruta: '/administracion/ajustes-marca',
    categoria: 'Marca',
  ),
  AccesoAdmin(
    titulo: 'Pagos',
    subtitulo: 'QR bancario y modo de cobro',
    icono: Icons.qr_code_outlined,
    ruta: '/administracion/ajustes-pagos',
    categoria: 'Marca',
  ),
];

/// Máximo 4 accesos: primero las rutas más usadas por el admin (en el
/// orden que llegan, ya vienen ordenadas por uso), rellenando con el
/// catálogo (en su orden) hasta completar 4, sin duplicar.
List<AccesoAdmin> elegirAccesosRapidos(List<String> rutasTop) {
  final elegidos = <AccesoAdmin>[];
  final rutasElegidas = <String>{};

  for (final ruta in rutasTop) {
    if (elegidos.length >= 4) break;
    final candidatos = catalogoAccesosAdmin.where((a) => a.ruta == ruta);
    if (candidatos.isEmpty) continue;
    elegidos.add(candidatos.first);
    rutasElegidas.add(ruta);
  }

  for (final acceso in catalogoAccesosAdmin) {
    if (elegidos.length >= 4) break;
    if (rutasElegidas.contains(acceso.ruta)) continue;
    elegidos.add(acceso);
    rutasElegidas.add(acceso.ruta);
  }

  return elegidos;
}

/// Agrupa por `categoria`, preservando el orden de primera aparición tanto
/// de las categorías como de los accesos dentro de cada una.
List<MapEntry<String, List<AccesoAdmin>>> agruparAccesosPorCategoria(
  List<AccesoAdmin> accesos,
) {
  final grupos = <String, List<AccesoAdmin>>{};
  for (final acceso in accesos) {
    grupos.putIfAbsent(acceso.categoria, () => []).add(acceso);
  }
  return grupos.entries.toList();
}

/// Filtra por título o subtítulo, sin distinguir mayúsculas/minúsculas.
/// Consulta vacía devuelve la lista completa sin cambios.
List<AccesoAdmin> filtrarAccesosAdmin(
  String consulta,
  List<AccesoAdmin> catalogo,
) {
  if (consulta.trim().isEmpty) return catalogo;
  final consultaNormalizada = consulta.toLowerCase();
  return catalogo
      .where(
        (a) =>
            a.titulo.toLowerCase().contains(consultaNormalizada) ||
            a.subtitulo.toLowerCase().contains(consultaNormalizada),
      )
      .toList();
}
