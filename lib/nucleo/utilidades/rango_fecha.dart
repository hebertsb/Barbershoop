class RangoFecha {
  const RangoFecha({required this.inicio, required this.fin});
  final DateTime inicio;
  final DateTime fin;
}

RangoFecha rangoDeHoyEnUtc(DateTime fecha) {
  final inicio = DateTime.utc(fecha.year, fecha.month, fecha.day);
  final fin = inicio.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
  return RangoFecha(inicio: inicio, fin: fin);
}
