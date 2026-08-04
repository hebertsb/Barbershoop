String formatoDistancia(double? metros) {
  if (metros == null) return '';
  if (metros < 1000) {
    return '${metros.round()} m';
  }
  final km = metros / 1000;
  return '${km.toStringAsFixed(1)} km';
}
