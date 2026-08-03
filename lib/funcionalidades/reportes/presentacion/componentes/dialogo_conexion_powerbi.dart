import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';

class DialogoConexionPowerBi extends StatelessWidget {
  const DialogoConexionPowerBi({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.analytics_outlined, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Conexión Power BI'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Supabase ofrece conexión PostgreSQL directa para Power BI Desktop sin necesidad de servidores intermedios.',
              style: TipografiaApp.bodySm.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pasos para conectar:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Abre Power BI Desktop → Obtener Datos → PostgreSQL database.',
            ),
            const SizedBox(height: 4),
            const Text(
              '2. Ingresa los datos de conexión de tu proyecto Supabase:',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Server: db.<PROJECT_REF>.supabase.co'),
                  Text('• Port: 5432'),
                  Text('• Database: postgres'),
                  Text('• Data Connectivity mode: DirectQuery o Import'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '3. Autentícate con el usuario lector_reportes_powerbi '
              '(nunca con la cuenta postgres: es superusuario y salta la '
              'seguridad por barbería).',
            ),
            const SizedBox(height: 12),
            const Text(
              'Vistas disponibles para tus dashboards:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '• vista_reportes_citas (fecha, precio cobrado, descuento, '
              'estado, servicio, barbero, sucursal)',
            ),
            const Text(
              '• vista_reportes_servicios (ingresos y citas por servicio)',
            ),
            const Text(
              '• vista_reportes_barberos (ingresos y citas por barbero)',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este acceso hoy muestra solo tu barbería. La '
                      'contraseña del usuario lector_reportes_powerbi se '
                      'configura desde el dashboard de Supabase (Database → '
                      'Roles) — no se muestra acá.',
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}