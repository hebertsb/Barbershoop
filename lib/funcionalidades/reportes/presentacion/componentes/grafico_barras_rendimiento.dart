import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';

/// Una fila del ranking de rendimiento (por servicio, barbero o cliente
/// frecuente) -- unifica los 3 shapes distintos en uno solo para que
/// `GraficoBarrasRendimiento` no necesite saber de cuál se trata.
class ItemRendimiento {
  const ItemRendimiento({
    required this.id,
    required this.nombre,
    required this.citas,
    required this.ingresos,
  });

  final String id;
  final String nombre;
  final int citas;
  final double ingresos;
}

/// Ranking de barras horizontales ordenado por ingresos descendente --
/// usado para "Rendimiento por Servicio"/"por Barbero"/"Clientes
/// Frecuentes" en `PantallaReportesIngresos`.
class GraficoBarrasRendimiento extends StatelessWidget {
  const GraficoBarrasRendimiento({
    super.key,
    required this.titulo,
    required this.items,
  });

  final String titulo;
  final List<ItemRendimiento> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            titulo,
            style: TipografiaApp.bodyMd.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final ordenados = [...items]..sort((a, b) => b.ingresos.compareTo(a.ingresos));
    final maximo = ordenados.first.ingresos <= 0 ? 1 : ordenados.first.ingresos;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TipografiaApp.bodyMd.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...ordenados.take(10).map((item) {
              final proporcion = (item.ingresos / maximo).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.nombre,
                            style: TipografiaApp.bodySm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatoMoneda(item.ingresos),
                          style: TipografiaApp.bodySm.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: proporcion,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.citas} citas',
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
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
