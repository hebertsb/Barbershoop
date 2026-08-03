import 'package:flutter/material.dart';
import '../../../../nucleo/utilidades/contacto_whatsapp.dart';

class BotonContactoWhatsapp extends StatelessWidget {
  const BotonContactoWhatsapp({
    super.key,
    required this.telefono,
    this.mensaje,
    this.etiqueta,
    this.icono = Icons.chat,
    this.chipsMensaje = const [],
  });

  final String telefono;
  final String? mensaje;
  final String? etiqueta;
  final IconData icono;
  final List<String> chipsMensaje;

  void _abrir(BuildContext context, String msg) {
    abrirWhatsapp(telefono, mensaje: msg).catchError((e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir WhatsApp: $e')),
        );
      }
    });
  }

  void _mostrarOpciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta ?? 'Contactar por WhatsApp',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in chipsMensaje)
                  ActionChip(
                    label: Text(chip),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _abrir(context, chip);
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.edit, size: 16),
                  label: const Text('Escribir mensaje libre'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _abrir(context, mensaje ?? '');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (etiqueta != null) {
      return OutlinedButton.icon(
        icon: Icon(icono, size: 18),
        label: Text(etiqueta!, overflow: TextOverflow.ellipsis),
        onPressed: () {
          if (chipsMensaje.isNotEmpty) {
            _mostrarOpciones(context);
          } else {
            _abrir(context, mensaje ?? '');
          }
        },
      );
    }
    return IconButton(
      icon: Icon(icono, color: Colors.green),
      onPressed: () => _abrir(context, mensaje ?? ''),
    );
  }
}
