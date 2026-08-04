class RangoFecha {
  const RangoFecha({required this.inicio, required this.fin});
  final DateTime inicio;
  final DateTime fin;
}

/// Convierte el día completo (00:00:00 a 23:59:59) en hora local a su rango UTC exacto.
RangoFecha rangoDeHoyEnUtc(DateTime fecha) {
  final local = fecha.toLocal();
  final inicioLocal = DateTime(local.year, local.month, local.day, 0, 0, 0);
  final finLocal = DateTime(local.year, local.month, local.day, 23, 59, 59, 999);
  return RangoFecha(inicio: inicioLocal.toUtc(), fin: finLocal.toUtc());
}
