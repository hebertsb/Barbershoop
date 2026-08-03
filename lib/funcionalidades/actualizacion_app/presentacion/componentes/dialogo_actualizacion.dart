import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dominio/modelo_version_app.dart';

/// Dilogo de nueva versin disponible. Si [version].obligatoria es `true`
/// se envuelve en [PopScope] con `canPop: false` para que ni el botn atrs
/// del sistema ni tocar afuera lo cierren -- solo queda el botn
/// "Descargar" (bloquea el uso de la app hasta actualizar).
class DialogoActualizacion extends StatelessWidget {
  const DialogoActualizacion({super.key, required this.version});

  final ModeloVersionApp version;

  Future<void> _abrirDescarga() async {
    final uri = Uri.tryParse(version.urlApk);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final notas = version.notasCambios;
    final dialogo = AlertDialog(
      title: const Text('Nueva versin disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hay una nueva versin de la app (${version.version}).'),
          if (notas != null && notas.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(notas),
          ],
          if (version.obligatoria) ...[
            const SizedBox(height: 12),
            const Text(
              'Esta actualizacin es obligatoria para seguir usando la app.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
      actions: [
        if (!version.obligatoria)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ahora no'),
          ),
        FilledButton(onPressed: _abrirDescarga, child: const Text('Descargar')),
      ],
    );

    if (!version.obligatoria) return dialogo;

    return PopScope(canPop: false, child: dialogo);
  }
}