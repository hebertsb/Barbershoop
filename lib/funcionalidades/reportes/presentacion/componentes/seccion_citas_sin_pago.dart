import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../dominio/modelo_cita_sin_pago.dart';

/// Sección "Citas sin pago completo" de Control y Auditoría: citas
/// `completada` donde lo realmente cobrado (pagos confirmados) es menor al
/// `precio_cobrado` registrado -- señal de plata no reportada o cobrada de
/// menos. Una lista vacía es una BUENA noticia, no un estado vacío neutro.
class SeccionCitasSinPago extends StatelessWidget {
  const SeccionCitasSinPago({super.key, required this.citas});

  final List<ModeloCitaSinPago> citas;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hayAlertas = citas.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: hayAlertas ? Colors.orange : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Citas sin pago completo',
                    style: TipografiaApp.headlineSm.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hayAlertas)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Todas las citas completadas tienen su pago '
                        'registrado correctamente.',
                        style: TipografiaApp.bodySm.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...citas.map((cita) => _FilaCitaSinPago(cita: cita)),
          ],
        ),
      ),
    );
  }
}

class _FilaCitaSinPago extends StatelessWidget {
  const _FilaCitaSinPago({required this.cita});

  final ModeloCitaSinPago cita;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  cita.clienteNombre,
                  style: TipografiaApp.bodyMd.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatoFechaHora(cita.fechaHora),
                style: TipografiaApp.labelSm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Barbero: ${cita.barberoNombre}',
            style: TipografiaApp.bodySm.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cobrado: ${formatoMoneda(cita.precioCobrado)} · '
                'Pagado: ${formatoMoneda(cita.montoPagado)}',
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '- ${formatoMoneda(cita.diferencia)}',
                style: TipografiaApp.bodyMd.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}