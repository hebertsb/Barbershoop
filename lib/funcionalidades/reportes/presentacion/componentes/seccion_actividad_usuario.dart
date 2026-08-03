import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../dominio/modelo_actividad_usuario.dart';

/// Sección "Actividad por Usuario" de Control y Auditoría: cuánto completó/
/// canceló cada secretaria/barbero (según `citas.completado_por`/
/// `cancelado_por`, migración 0050). Acciones de un cron automático no
/// generan filas para ningún usuario.
class SeccionActividadUsuario extends StatelessWidget {
  const SeccionActividadUsuario({super.key, required this.actividad});

  final List<ModeloActividadUsuario> actividad;

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
              'Actividad por Usuario',
              style: TipografiaApp.headlineSm.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (actividad.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Sin actividad de usuarios en este período'),
                ),
              )
            else
              ...actividad.map((usuario) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              usuario.usuarioNombre,
                              style: TipografiaApp.bodyMd.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              usuario.rol.toUpperCase(),
                              style: TipografiaApp.labelSm.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${usuario.citasCompletadas} completadas · '
                        '${formatoMoneda(usuario.montoTotalCobrado)} cobrado · '
                        '${usuario.citasCanceladas} canceladas',
                        style: TipografiaApp.bodySm.copyWith(
                          color: colorScheme.onSurfaceVariant,
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