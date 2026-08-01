import 'package:flutter/material.dart';

/// Abre [urlImagen] en pantalla completa con zoom/pan (ej. QR bancario,
/// comprobante de pago) -- toque afuera de la imagen para cerrar.
void mostrarImagenPantallaCompleta(BuildContext context, String urlImagen) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, _, _) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(urlImagen),
            ),
          ),
        ),
      ),
    ),
  );
}
