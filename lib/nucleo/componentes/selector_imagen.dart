import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../configuracion/cliente_supabase.dart';
import '../configuracion/colores_app.dart';

/// Selector de imagen genérico: muestra la [urlActual] (o un placeholder),
/// permite tocar para elegir una nueva desde galería, la sube al [bucket]/
/// [carpeta] indicados en Supabase Storage y llama [alSubir] con la URL
/// pública resultante.
///
/// [altura] por defecto 160 (fotos de perfil/logos cuadrados-ish); pantallas
/// con una imagen naturalmente más alta (QR bancario, logo de marca) pasan
/// un valor mayor. Envuelto en `ConstrainedBox(maxWidth: 400)` para que no
/// se estire enorme en pantallas anchas (tablet/laptop).
class SelectorImagen extends StatefulWidget {
  const SelectorImagen({
    super.key,
    required this.bucket,
    required this.carpeta,
    this.urlActual,
    required this.alSubir,
    this.altura = 160,
  });

  final String bucket;
  final String carpeta;
  final String? urlActual;
  final ValueChanged<String> alSubir;
  final double altura;

  @override
  State<SelectorImagen> createState() => _SelectorImagenState();
}

class _SelectorImagenState extends State<SelectorImagen> {
  bool _subiendo = false;

  Future<void> _seleccionarYSubir() async {
    final picker = ImagePicker();
    final archivo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (archivo == null || !mounted) return;

    setState(() => _subiendo = true);
    try {
      final cliente = ClienteSupabase.instancia;
      final nombreArchivo =
          '${widget.carpeta}/${DateTime.now().millisecondsSinceEpoch}_${archivo.name}';
      await cliente.storage
          .from(widget.bucket)
          .upload(nombreArchivo, File(archivo.path));
      final url = cliente.storage.from(widget.bucket).getPublicUrl(
        nombreArchivo,
      );
      widget.alSubir(url);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: GestureDetector(
        onTap: _subiendo ? null : _seleccionarYSubir,
        child: Container(
          height: widget.altura,
          decoration: BoxDecoration(
            border: Border.all(color: ColoresApp.primario),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: _subiendo
              ? const Center(child: CircularProgressIndicator())
              : (widget.urlActual != null
                    ? Image.network(widget.urlActual!, fit: BoxFit.contain)
                    : Center(
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )),
        ),
      ),
    );
  }
}
