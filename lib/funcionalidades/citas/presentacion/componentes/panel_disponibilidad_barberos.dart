import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_estado_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../dominio/disponibilidad_barbero.dart';
import 'etiqueta_estado.dart';

String _formatoHuecos(List<HuecoLibre> huecos) {
  if (huecos.isEmpty) return 'Sin huecos libres hoy';
  return huecos
      .map(
        (h) =>
            '${formatoHora(h.inicio.toLocal())}–${formatoHora(h.fin.toLocal())}',
      )
      .join(', ');
}

/// Texto legible del estado de disponibilidad de un barbero.
String textoDisponibilidadBarbero(EstadoDisponibilidadBarbero estado) {
  if (!estado.ocupado) return 'Libre';
  if (estado.libreDesde != null) {
    return 'Libre a las ${formatoHora(estado.libreDesde!.toLocal())}';
  }
  return 'Ocupado';
}

/// Color según disponibilidad del barbero para el badge de la UI.
Color colorDisponibilidadBarbero(
  EstadoDisponibilidadBarbero estado,
  dynamic colores,
) {
  if (!estado.ocupado) return Colors.green;
  return Colors.orange;
}

/// Panorama de disponibilidad de todos los barberos de la sucursal, para que
/// la secretaria/admin vea de un vistazo quién está libre y quién ocupado
/// (y hasta cuándo), y qué huecos libres le quedan hoy — sin tener que abrir
/// el menú "Llamar" de cada turno.
class PanelDisponibilidadBarberos extends StatelessWidget {
  const PanelDisponibilidadBarberos({super.key, required this.disponibilidad});

  final List<EstadoDisponibilidadBarbero> disponibilidad;

  @override
  Widget build(BuildContext context) {
    if (disponibilidad.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final colores = Theme.of(context).extension<ColoresEstadoApp>()!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disponibilidad de barberos',
            style: TipografiaApp.labelMd.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final estado in disponibilidad)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  estado.barbero.nombrePerfil ?? 'Sin nombre',
                                  style: TipografiaApp.bodyMd.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              EtiquetaEstado(
                                texto: textoDisponibilidadBarbero(estado),
                                color: colorDisponibilidadBarbero(
                                  estado,
                                  colores,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatoHuecos(estado.huecosLibres),
                            style: TipografiaApp.bodySm.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}