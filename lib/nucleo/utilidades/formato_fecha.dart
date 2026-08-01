String _dosDigitos(int n) => n.toString().padLeft(2, '0');

String formatoHora(DateTime fecha) {
  return '${_dosDigitos(fecha.hour)}:${_dosDigitos(fecha.minute)}';
}

String formatoFechaCorta(DateTime fecha) {
  return '${_dosDigitos(fecha.day)}/${_dosDigitos(fecha.month)}/${fecha.year}';
}

String formatoFechaHora(DateTime fecha) {
  return '${formatoFechaCorta(fecha)} — ${formatoHora(fecha)}';
}
