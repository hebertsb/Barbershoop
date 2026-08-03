import 'package:flutter/material.dart';

void mostrarImagenPantallaCompleta(BuildContext context, String urlImagen) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Image.network(urlImagen, fit: BoxFit.contain),
    ),
  );
}
