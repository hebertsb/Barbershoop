/// Ancho (px) a partir del cual se considera "pantalla ancha" (tablet en
/// horizontal / laptop) y se activa el layout de sidebar + grillas
/// multi-columna en vez del layout de una sola columna del celular.
const double anchoUmbralPantallaAncha = 840;

bool esPantallaAncha(double ancho) => ancho >= anchoUmbralPantallaAncha;

/// Calcula cuántas columnas entran en [ancho] a [anchoTarjeta] px cada una,
/// acotado entre [minimo] y [maximo].
int calcularColumnas(
  double ancho, {
  double anchoTarjeta = 200,
  int minimo = 2,
  int maximo = 4,
}) {
  final columnas = (ancho / anchoTarjeta).floor();
  if (columnas < minimo) return minimo;
  if (columnas > maximo) return maximo;
  return columnas;
}
