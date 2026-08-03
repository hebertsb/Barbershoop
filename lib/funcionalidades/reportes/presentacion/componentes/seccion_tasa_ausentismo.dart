import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_tasa_ausentismo_barbero.dart';

/// Sección "Tasa de Ausentismo por Barbero" de Control y Auditoría: % de
/// citas canceladas/no-asistidas de cada barbero en el rango, con un badge
/// de color según qué tan alta es la tasa -- el barbero con más ausentismo
/// necesita más atención del dueño.
class SeccionTasaAusentismo extends StatelessWidget {
  const SeccionTasaAusentismo({super.key, required this.tasas});

  final List<ModeloTasaAusentismoBarbero> tasas;

  Color _colorSegunTasa(double tasa) {
    if (tasa >= 25) return ColoresApp.estadoCancelada;
    if (tasa >= 10) return ColoresApp.estadoPendiente;
    return ColoresApp.estadoCompletada;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasa de Ausentismo por Barbero',
              style: TipografiaApp.headlineSm.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (tasas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Sin citas registradas en este período')),
              )
            else
              ...tasas.map((tasa) {
                final color = _colorSegunTasa(tasa.tasaAusentismo);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tasa.barberoNombre,
                              style: TipografiaApp.bodyMd.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${tasa.totalCitas} citas · '
                              '${tasa.canceladas} canceladas · '
                              '${tasa.noAsistio} no asistió',
                              style: TipografiaApp.labelSm.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${tasa.tasaAusentismo.toStringAsFixed(1)}%',
                          style: TipografiaApp.bodyMd.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}