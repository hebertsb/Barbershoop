String formatoFechaCorta(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year.toString();
  return '$d/$m/$y';
}

String formatoHora(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Devuelve fecha y hora combinadas: "02/08/2026 · 14:30"
String formatoFechaHora(DateTime dt) {
  return '${formatoFechaCorta(dt)} · ${formatoHora(dt)}';
}
