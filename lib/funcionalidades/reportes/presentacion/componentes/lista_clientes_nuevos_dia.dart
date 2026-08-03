import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../dominio/modelo_cliente_nuevo_dia.dart';

/// Lista de clientes (perfiles `rol = 'cliente'`) registrados en un da, para
/// la pantalla de Actividad del Da. Muestra nombre, telfono y hora de alta.
class ListaClientesNuevosDia extends StatelessWidget {
  const ListaClientesNuevosDia({super.key, required this.clientes});

  final List<ModeloClienteNuevoDia> clientes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (clientes.isEmpty) {
      return _MensajeVacio(
        texto: 'No se registraron clientes nuevos este da.',
        colorScheme: colorScheme,
      );
    }

    return Column(
      children: clientes
          .map(
            (cliente) => Card(
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
                        formatoHora(cliente.horaRegistro.toLocal()),
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
                            cliente.nombre,
                            style: TipografiaApp.bodyMd.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (cliente.telefono != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              cliente.telefono!,
                              style: TipografiaApp.bodySm.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
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
