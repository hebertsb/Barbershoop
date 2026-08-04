import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../dominio/enum_filtro_periodo.dart';

/// Selector de perodo compartido por las pantallas de reportes
/// (`PantallaReportesIngresos` y `PantallaControlAuditoria`).
///
/// Reemplaza la fila horizontal de `FilterChip` con scroll por un
/// `SegmentedButton` de Material 3 con las 4 opciones fijas de
/// [FiltroPeriodo] (excluye [FiltroPeriodo.personalizado], que se elige
/// aparte con el cono de calendario).
///
/// No depende de ningn provider especfico: recibe el estado ya resuelto
/// por parmetro y expone callbacks, para poder usarse con controladores
/// distintos (`controladorReportesProvider`, `controladorControlAuditoriaProvider`)
/// sin duplicar este widget.
class SelectorPeriodoReporte extends StatelessWidget {
  const SelectorPeriodoReporte({
    super.key,
    required this.filtroActual,
    required this.rangoFechas,
    required this.alCambiarFiltro,
    required this.alElegirPersonalizado,
  });

  /// Filtro seleccionado actualmente (incluye [FiltroPeriodo.personalizado]).
  final FiltroPeriodo filtroActual;

  /// Rango de fechas ya resuelto (va `FiltroPeriodo.obtenerRangoFechas`),
  /// usado solo para mostrar el texto del rango cuando el filtro es
  /// personalizado.
  final (DateTime inicio, DateTime fin) rangoFechas;

  /// Se invoca al tocar una de las 4 opciones fijas del segmented button.
  final void Function(FiltroPeriodo filtro) alCambiarFiltro;

  /// Se invoca al tocar el cono de calendario (abre `showDateRangePicker`).
  final Future<void> Function() alElegirPersonalizado;

  static const _opcionesFijas = [
    FiltroPeriodo.hoy,
    FiltroPeriodo.estaSemana,
    FiltroPeriodo.esteMes,
    FiltroPeriodo.esteAnio,
  ];

  /// Etiqueta corta para que las 4 opciones entren en una sola fila sin
  /// scroll. `FiltroPeriodo.etiqueta` (ms larga, ej. "Esta semana") se
  /// sigue usando en otros lugares de la app; esto es solo cosmtico de
  /// este selector.
  String _etiquetaCorta(FiltroPeriodo filtro) {
    switch (filtro) {
      case FiltroPeriodo.hoy:
        return 'Hoy';
      case FiltroPeriodo.estaSemana:
        return 'Semana';
      case FiltroPeriodo.esteMes:
        return 'Mes';
      case FiltroPeriodo.esteAnio:
        return 'Año';
      case FiltroPeriodo.personalizado:
        return 'Personalizado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final esPersonalizado = filtroActual == FiltroPeriodo.personalizado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<FiltroPeriodo>(
                segments: _opcionesFijas
                    .map(
                      (f) => ButtonSegment<FiltroPeriodo>(
                        value: f,
                        label: Text(_etiquetaCorta(f)),
                      ),
                    )
                    .toList(),
                // Cuando el filtro activo es "personalizado" no se resalta
                // ninguna de las 4 opciones fijas.
                selected: esPersonalizado ? const {} : {filtroActual},
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                onSelectionChanged: (seleccion) {
                  if (seleccion.isNotEmpty) {
                    alCambiarFiltro(seleccion.first);
                  }
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: colorScheme.primary.withValues(
                    alpha: 0.2,
                  ),
                  selectedForegroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: TipografiaApp.labelMd,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Rango de fechas personalizado',
              icon: Icon(
                esPersonalizado ? Icons.date_range : Icons.date_range_outlined,
              ),
              style: IconButton.styleFrom(
                backgroundColor: esPersonalizado
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : null,
                foregroundColor: esPersonalizado
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              onPressed: () => alElegirPersonalizado(),
            ),
          ],
        ),
        if (esPersonalizado) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${formatoFechaCorta(rangoFechas.$1)} - '
              '${formatoFechaCorta(rangoFechas.$2)}',
              style: TipografiaApp.labelSm.copyWith(color: colorScheme.primary),
            ),
          ),
        ],
      ],
    );
  }
}
