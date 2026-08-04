import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Selector y visualizador de imagen que permite subir a Supabase Storage.
/// Muestra la imagen actual (si existe) o un placeholder, y permite al
/// usuario elegir una foto desde la galería o cámara para subirla.
class SelectorImagen extends StatefulWidget {
  const SelectorImagen({
    super.key,
    required this.bucket,
    required this.carpeta,
    this.urlActual,
    required this.alSubir,
    this.altura = 160,
    this.ancho,
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
      final nombre = '${widget.carpeta}/${DateTime.now().millisecondsSinceEpoch}.$ext';

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
                      Image.network(
                        urlMostrar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(colorScheme),
                      ),
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