import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../dominio/modelo_ingreso_por_metodo.dart';

/// Sección "Ingresos por Método de Pago" de Control y Auditoría: cuánto de
/// lo cobrado es efectivo (más fácil de no reportar) vs QR/otros métodos
/// digitales. Es dinero, no citas -- se muestra como lista de tarjetas con
/// monto + porcentaje del total, en vez de reusar el gráfico de rendimiento
/// de citas.
class SeccionIngresosMetodoPago extends StatelessWidget {
  const SeccionIngresosMetodoPago({super.key, required this.ingresos});

  final List<ModeloIngresoPorMetodo> ingresos;

  static const Map<String, String> _etiquetas = {
    'efectivo': 'Efectivo',
    'qr_manual': 'QR Manual',
    'pasarela': 'Pasarela',
  };

  static const Map<String, IconData> _iconos = {
    'efectivo': Icons.payments_outlined,
    'qr_manual': Icons.qr_code_2_outlined,
    'pasarela': Icons.credit_card_outlined,
  };

  String _etiquetaDe(String metodo) => _etiquetas[metodo] ?? metodo;

  IconData _iconoDe(String metodo) =>
      _iconos[metodo] ?? Icons.attach_money_outlined;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final montoTotal = ingresos.fold<double>(
      0,
      (suma, item) => suma + item.montoTotal,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos por Método de Pago',
              style: TipografiaApp.headlineSm.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (ingresos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Sin pagos confirmados en este período')),
              )
            else
              ...ingresos.map((item) {
                final porcentaje = montoTotal > 0
                    ? (item.montoTotal / montoTotal) * 100
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconoDe(item.metodo),
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _etiquetaDe(item.metodo),
                              style: TipografiaApp.bodyMd.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${item.cantidadPagos} pagos · '
                              '${porcentaje.toStringAsFixed(1)}% del total',
                              style: TipografiaApp.labelSm.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatoMoneda(item.montoTotal),
                        style: TipografiaApp.bodyMd.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
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