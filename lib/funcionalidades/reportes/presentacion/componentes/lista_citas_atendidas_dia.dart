import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../dominio/modelo_cita_atendida_dia.dart';

/// Lista de citas `completada` de un da, para la pantalla de Actividad del
/// Da. Muestra hora, cliente, servicio (o combo), barbero y monto cobrado.
class ListaCitasAtendidasDia extends StatelessWidget {
  const ListaCitasAtendidasDia({super.key, required this.citas});

  final List<ModeloCitaAtendidaDia> citas;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (citas.isEmpty) {
      return _MensajeVacio(
        texto: 'No hubo citas atendidas este da.',
        colorScheme: colorScheme,
      );
    }

    return Column(
      children: citas
          .map(
            (cita) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        formatoHora(cita.hora.toLocal()),
                        style: TipografiaApp.labelMd.copyWith(
                          color: ColoresApp.primario,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cita.clienteNombre,
                            style: TipografiaApp.bodyMd.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cita.servicioNombre}  ${cita.barberoNombre}',
                            style: TipografiaApp.bodySm.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatoMoneda(cita.monto),
                      style: TipografiaApp.bodyMd.copyWith(
                        color: ColoresApp.estadoCompletada,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MensajeVacio extends StatelessWidget {
  const _MensajeVacio({required this.texto, required this.colorScheme});

  final String texto;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TipografiaApp.bodySm.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
