String formatoFechaCorta(DateTime dt) {
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString();
  return '$d/$m/$y';
}

String formatoHora(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Devuelve fecha y hora combinadas en hora local: "02/08/2026 · 14:30"
String formatoFechaHora(DateTime dt) {
  final local = dt.toLocal();
  return '${formatoFechaCorta(local)} · ${formatoHora(local)}';
}
