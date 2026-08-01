import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/contacto_whatsapp.dart';

/// Botón que abre un `showModalBottomSheet` con mensajes rápidos (chips,
/// opcionales) más un campo de mensaje libre, y arma el link `wa.me`
/// correspondiente. Puramente presentacional: [telefono] llega ya
/// normalizado (dígitos, sin "+", ver [normalizarTelefonoWhatsapp]) --
/// quien lo instancia decide si corresponde mostrarlo, este widget no lee
/// providers ni valida nada de negocio.
class BotonContactoWhatsapp extends StatelessWidget {
  const BotonContactoWhatsapp({
    super.key,
    required this.telefono,
    required this.etiqueta,
    required this.icono,
    this.chipsMensaje = const [],
  });

  final String telefono;
  final String etiqueta;
  final IconData icono;

  /// Mensajes predefinidos, mostrados como chips. Vacío = solo el campo de
  /// mensaje libre.
  final List<String> chipsMensaje;

  Future<void> _abrirWhatsapp(String? mensaje) async {
    final uri = Uri.parse(construirUrlWhatsapp(telefono, mensaje: mensaje));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _mostrarOpciones(BuildContext context) {
    final mensajeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: TipografiaApp.headlineSm),
            if (chipsMensaje.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chipsMensaje.map((texto) {
                  return ActionChip(
                    label: Text(texto),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _abrirWhatsapp(texto);
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: mensajeCtrl,
              decoration: const InputDecoration(
                labelText: 'Otro mensaje',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  final texto = mensajeCtrl.text.trim();
                  _abrirWhatsapp(texto.isEmpty ? null : texto);
                },
                child: const Text('Enviar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _mostrarOpciones(context),
      icon: Icon(icono, size: 18),
      label: Text(etiqueta, overflow: TextOverflow.ellipsis),
    );
  }
}
