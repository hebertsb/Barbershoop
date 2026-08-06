import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

void mostrarImagenPantallaCompleta(BuildContext context, String urlImagen) {
  showDialog(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: _construirImagenVisor(urlImagen, colorScheme),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _construirImagenVisor(String url, ColorScheme colorScheme) {
  final urlLimpia = url.trim();
  if (urlLimpia.startsWith('http://') || urlLimpia.startsWith('https://')) {
    return CachedNetworkImage(
      imageUrl: urlLimpia,
      fit: BoxFit.contain,
      placeholder: (context, u) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, u, error) => Image.network(
        urlLimpia,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
              SizedBox(height: 8),
              Text(
                'No se pudo cargar la imagen',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    try {
      final String base64Content = urlLimpia.contains(',')
          ? urlLimpia.split(',').last
          : urlLimpia;
      final bytes = base64Decode(base64Content.replaceAll(RegExp(r'\s+'), ''));
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
        ),
      );
    } catch (_) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
      );
    }
  }
}
