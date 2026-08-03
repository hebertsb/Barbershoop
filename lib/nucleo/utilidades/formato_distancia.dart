String formatoDistancia(double? metros) {
  if (metros == null) return '';
  if (metros < 1000) {
    return '\ m';
  }
  final km = metros / 1000;
  return '\ km';
}
