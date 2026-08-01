import 'package:flutter/material.dart';

/// Instrucciones para conectar Power BI de solo lectura contra las vistas
/// curadas de reportes (`vista_reportes_citas`/`vista_reportes_servicios`/
/// `vista_reportes_barberos`), usando el rol `lector_reportes_powerbi`
/// (nunca la cuenta `postgres`) -- ver `0048_rol_lectura_powerbi.sql`.
class DialogoConexionPowerBi extends StatelessWidget {
  const DialogoConexionPowerBi({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conectar Power BI'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para conectar Power BI (u otra herramienta de análisis) a '
              'esta barbería, usá el rol de solo lectura '
              '"lector_reportes_powerbi" -- nunca la cuenta de '
              'administrador de la base de datos.',
            ),
            SizedBox(height: 12),
            Text(
              'Ese rol solo puede leer 3 vistas ya preparadas, sin datos '
              'personales de clientes:',
            ),
            SizedBox(height: 8),
            Text('• vista_reportes_citas'),
            Text('• vista_reportes_servicios'),
            Text('• vista_reportes_barberos'),
            SizedBox(height: 12),
            Text(
              'La contraseña de ese rol se configura desde el panel de '
              'Supabase (Database → Roles) y se comparte solo con quien '
              'vaya a conectar el reporte -- no queda guardada en el '
              'código de la app.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
