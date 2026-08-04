import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Selector y visualizador de imagen que permite subir a Supabase Storage.
/// Muestra la imagen actual (si existe) o un placeholder, y permite al
/// usuario elegir una foto desde la galería o cámara para subirla.
///
/// Soporta tres tipos de URL al mostrar la imagen:
/// - HTTP/HTTPS: carga con [Image.network].
/// - Data URL Base64 (data:image/...;base64,...): decodifica y usa [Image.memory].
/// - Base64 puro: decodifica y usa [Image.memory].
class SelectorImagen extends StatefulWidget {
  const SelectorImagen({
    super.key,
    required this.bucket,
    required this.carpeta,
    this.urlActual,
    required this.alSubir,
    this.altura = 160,
    this.ancho,
    this.fit = BoxFit.cover,
  });

  /// Nombre del bucket de Supabase Storage donde se subirá la imagen.
  final String bucket;

  /// Carpeta dentro del bucket (ej. 'perfiles', 'servicios', 'logos').
  final String carpeta;

  /// URL de la imagen actual, si existe (para mostrar en el placeholder).
  final String? urlActual;

  /// Callback que recibe la URL pública de la imagen subida.
  final void Function(String url) alSubir;

  /// Altura del selector (px). Por defecto 160.
  final double altura;

  /// Ancho del selector. Si es null, ocupa todo el ancho disponible.
  final double? ancho;

  /// Ajuste visual de la imagen (BoxFit.cover por defecto, BoxFit.contain para comprobantes).
  final BoxFit fit;

  @override
  State<SelectorImagen> createState() => _SelectorImagenState();
}

class _SelectorImagenState extends State<SelectorImagen> {
  bool _subiendo = false;
  String? _urlLocal;

  Future<void> _elegirYSubir() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (imagen == null) return;

    setState(() => _subiendo = true);
    try {
      final bytes = await File(imagen.path).readAsBytes();
      final ext = imagen.path.split('.').last.toLowerCase();
      final nombre =
          '${widget.carpeta}/${DateTime.now().millisecondsSinceEpoch}.$ext';

      final supabase = Supabase.instance.client;
      try {
        await supabase.storage.from(widget.bucket).uploadBinary(
          nombre,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true,
          ),
        );
        final url = supabase.storage.from(widget.bucket).getPublicUrl(nombre);
        setState(() => _urlLocal = url);
        widget.alSubir(url);
      } on StorageException catch (_) {
        // Fallback RLS Storage: Convertir a Data URL Base64
        final base64Str = base64Encode(bytes);
        final dataUrl = 'data:image/$ext;base64,$base64Str';
        setState(() => _urlLocal = dataUrl);
        widget.alSubir(dataUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final urlMostrar = _urlLocal ?? widget.urlActual;

    return GestureDetector(
      onTap: _subiendo ? null : _elegirYSubir,
      child: Container(
        width: widget.ancho ?? double.infinity,
        height: widget.altura,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _subiendo
            ? const Center(child: CircularProgressIndicator())
            : urlMostrar != null && urlMostrar.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _construirImagen(urlMostrar, colorScheme),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  )
                : _placeholder(colorScheme),
      ),
    );
  }

  /// Construye el widget de imagen correcto según el tipo de URL:
  /// - Data URL Base64 o Base64 puro → [Image.memory]
  /// - HTTP/HTTPS → [Image.network]
  Widget _construirImagen(String url, ColorScheme colorScheme) {
    try {
      if (url.startsWith('data:image/')) {
        // Data URL: data:image/jpeg;base64,/9j/4AAQ...
        final commaIndex = url.indexOf(',');
        if (commaIndex != -1) {
          final base64Data = url.substring(commaIndex + 1);
          final bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            fit: widget.fit,
            errorBuilder: (_, __, ___) => _placeholder(colorScheme),
          );
        }
      } else if (!url.startsWith('http')) {
        // Base64 puro sin prefijo data:
        try {
          final bytes = base64Decode(url);
          return Image.memory(
            bytes,
            fit: widget.fit,
            errorBuilder: (_, __, ___) => _placeholder(colorScheme),
          );
        } catch (_) {
          // No es Base64 válido, tratar como red
        }
      }
    } catch (_) {
      // En caso de error de decodificación, usar Image.network
    }

    // URL HTTP/HTTPS normal
    return Image.network(
      url,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => _placeholder(colorScheme),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo_outlined,
          size: 36,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          'Toca para subir imagen',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}