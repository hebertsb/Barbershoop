/// Formatea una distancia en metros para mostrar al cliente: por debajo de
/// 1000m se muestra en metros redondeados ("350 m"), de 1000m en adelante
/// en kilómetros con 1 decimal ("2.4 km").
String formatoDistancia(double metros) {
  if (metros < 1000) {
    return '${metros.round()} m';
  }
  final km = metros / 1000;
  return '${km.toStringAsFixed(1)} km';
}
