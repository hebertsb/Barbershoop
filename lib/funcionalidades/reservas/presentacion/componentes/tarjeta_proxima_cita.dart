import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/colores_estado_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../citas/dominio/modelo_cita.dart';
import '../../../citas/presentacion/componentes/etiqueta_estado.dart';

class TarjetaProximaCita extends StatelessWidget {
  const TarjetaProximaCita({
    super.key,
    required this.cita,
    required this.nombreServicio,
    this.nombreBarbero,
    this.onReprogramar,
    this.onVerInstrucciones,
  });

  final ModeloCita cita;
  final String nombreServicio;
  final String? nombreBarbero;
  final VoidCallback? onReprogramar;
  final VoidCallback? onVerInstrucciones;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colores = Theme.of(context).extension<ColoresEstadoApp>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Resplandor dorado decorativo sutil en la esquina superior derecha
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColoresApp.primario.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.content_cut,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreServicio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TipografiaApp.headlineSm.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (nombreBarbero != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'con $nombreBarbero',
                              style: TipografiaApp.bodySm.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    EtiquetaEstado(
                      estado: cita.estado,
                      texto: textoEstadoCita(cita.estado),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatoFechaCorta(
                          cita.fechaHora.toLocal(),
                        ).toUpperCase(),
                        style: TipografiaApp.labelSm.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 1,
                        height: 14,
                        color: colorScheme.outlineVariant,
                      ),
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatoHora(cita.fechaHora.toLocal()),
                        style: TipografiaApp.labelSm.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onReprogramar != null || onVerInstrucciones != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (onReprogramar != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onReprogramar,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colorScheme.outline),
                              foregroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Reprogramar'),
                          ),
                        ),
                      if (onReprogramar != null && onVerInstrucciones != null)
                        const SizedBox(width: 10),
                      if (onVerInstrucciones != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onVerInstrucciones,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'INSTRUCCIONES',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}