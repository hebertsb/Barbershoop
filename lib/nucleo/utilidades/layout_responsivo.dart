import 'package:flutter/material.dart';

const double anchoUmbralPantallaAncha = 600.0;

bool esPantallaAncha(dynamic arg) {
  if (arg is BuildContext) {
    return MediaQuery.of(arg).size.width >= anchoUmbralPantallaAncha;
  } else if (arg is num) {
    return arg >= anchoUmbralPantallaAncha;
  }
  return false;
}

int calcularColumnas(BuildContext context, {double anchoMinimoTarjeta = 300.0}) {
  final anchoDisponible = MediaQuery.of(context).size.width;
  final columnas = (anchoDisponible / anchoMinimoTarjeta).floor();
  return columnas.clamp(1, 4);
}
