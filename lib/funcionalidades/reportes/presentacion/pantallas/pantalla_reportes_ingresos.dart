import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../../administracion/presentacion/controladores/controlador_tendencia_ingresos.dart';
import '../../dominio/enum_filtro_periodo.dart';
import '../componentes/dialogo_conexion_powerbi.dart';
import '../componentes/grafico_barras_rendimiento.dart';
import '../componentes/selector_periodo_reporte.dart';
import '../componentes/tarjeta_kpi_reporte.dart';
import '../controladores/controlador_reportes.dart';

/// Mapea el filtro de Reportes al `p_periodo` que espera el RPC
/// `obtener_tendencia_ingresos` ('semana' | 'mes' | 'anio'). 'hoy' no tiene
/// una serie diaria con sentido (sería un solo punto) y 'personalizado' es
/// un rango arbitrario que no calza con ninguna serie predefinida -- ambos
/// devuelven null y la tarjeta de ingresos se ve sin sparkline.
String? _mapearPeriodoATendencia(FiltroPeriodo filtro) {
  switch (filtro) {
    case FiltroPeriodo.estaSemana:
      return 'semana';
    case FiltroPeriodo.esteMes:
      return 'mes';
    case FiltroPeriodo.esteAnio:
      return 'anio';
    case FiltroPeriodo.hoy:
    case FiltroPeriodo.personalizado:
      return null;
  }
}

class PantallaReportesIngresos extends ConsumerWidget {
  const PantallaReportesIngresos({super.key});

  Future<void> _seleccionarRangoPersonalizado(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final estado = ref.read(controladorReportesProvider);
    final iniciales = estado.filtro.obtenerRangoFechas(
      fechaInicioCustom: estado.fechaInicioCustom,
      fechaFinCustom: estado.fechaFinCustom,
    );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: iniciales.$1, end: iniciales.$2),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      final inicio = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
        0,
        0,
        0,
      );
      final fin = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
      ref
          .read(controladorReportesProvider.notifier)
          .cambiarFiltro(
            FiltroPeriodo.personalizado,
            inicioCustom: inicio,
            finCustom: fin,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorReportesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final resumen = estado.resumen;
    final (inicio, fin) = estado.filtro.obtenerRangoFechas(
      fechaInicioCustom: estado.fechaInicioCustom,
      fechaFinCustom: estado.fechaFinCustom,
    );

    // Sparkline real de ingresos: solo cuando el filtro actual mapea a un
    // período soportado por `obtener_tendencia_ingresos` (ver comentario de
    // `_mapearPeriodoATendencia`). El provider es family por período, así
    // que solo se observa cuando hay un período válido.
    final periodoTendencia = _mapearPeriodoATendencia(estado.filtro);
    final sparklineIngresos = periodoTendencia == null
        ? null
        : ref
              .watch(controladorTendenciaIngresosProvider(periodoTendencia))
              .value
              ?.map((p) => p.monto)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Ingresos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Power BI / Integración',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const DialogoConexionPowerBi(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(controladorReportesProvider.notifier).cargar(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filtro por Período
            SelectorPeriodoReporte(
              filtroActual: estado.filtro,
              rangoFechas: (inicio, fin),
              alCambiarFiltro: (f) => ref
                  .read(controladorReportesProvider.notifier)
                  .cambiarFiltro(f),
              alElegirPersonalizado: () =>
                  _seleccionarRangoPersonalizado(context, ref),
            ),
            const SizedBox(height: 16),

            if (estado.cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (estado.error != null)
              Center(child: Text(estado.error!))
            else ...[
              // Grid de KPIs. Alto fijo (no `childAspectRatio`): con pocas
              // columnas en pantallas anchas, un aspect ratio fijo estira la
              // celda hacia arriba junto con el ancho, dejando una tarjeta
              // enorme casi vacía (bug real reportado en tablet). El
              // contenido de `TarjetaKpiReporte` ya se distribuye con
              // `mainAxisAlignment.spaceBetween`, así que tolera un alto
              // fijo sin desbordarse.
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 160,
                ),
                children: [
                  TarjetaKpiReporte(
                    titulo: 'Total Ingresos',
                    valor: formatoMoneda(resumen?.totalIngresos ?? 0),
                    icono: Icons.attach_money_outlined,
                    colorIcono: colorScheme.primary,
                    sparklineData: sparklineIngresos,
                  ),
                  TarjetaKpiReporte(
                    titulo: 'Citas Atendidas',
                    valor: '${resumen?.citasCompletadas ?? 0}',
                    icono: Icons.check_circle_outline,
                    colorIcono: Colors.green,
                    subtitulo: '${resumen?.citasCanceladas ?? 0} canceladas',
                  ),
                  TarjetaKpiReporte(
                    titulo: 'Ticket Promedio',
                    valor: formatoMoneda(resumen?.ticketPromedio ?? 0),
                    icono: Icons.receipt_long_outlined,
                    colorIcono: Colors.orange,
                  ),
                  TarjetaKpiReporte(
                    titulo: 'Descuentos Promos',
                    valor: formatoMoneda(resumen?.totalDescuentos ?? 0),
                    icono: Icons.local_offer_outlined,
                    colorIcono: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Gráfico por Servicios
              GraficoBarrasRendimiento(
                titulo: 'Rendimiento por Servicio',
                items: estado.servicios
                    .map(
                      (s) => ItemRendimiento(
                        id: s.servicioId,
                        nombre: s.servicioNombre,
                        citas: s.cantidadCitas,
                        ingresos: s.ingresosTotales,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Gráfico por Barberos
              GraficoBarrasRendimiento(
                titulo: 'Rendimiento por Barbero',
                items: estado.barberos
                    .map(
                      (b) => ItemRendimiento(
                        id: b.barberoId,
                        nombre: b.barberoNombre,
                        citas: b.cantidadCitas,
                        ingresos: b.ingresosTotales,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Ranking de Clientes Frecuentes
              GraficoBarrasRendimiento(
                titulo: 'Clientes Frecuentes',
                items: estado.clientesFrecuentes
                    .map(
                      (c) => ItemRendimiento(
                        id: c.clienteId,
                        nombre: c.clienteNombre,
                        citas: c.cantidadCitas,
                        ingresos: c.montoTotal,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
