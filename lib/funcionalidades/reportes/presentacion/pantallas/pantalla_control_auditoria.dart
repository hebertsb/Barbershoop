import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/enum_filtro_periodo.dart';
import '../componentes/seccion_actividad_usuario.dart';
import '../componentes/seccion_citas_sin_pago.dart';
import '../componentes/seccion_ingresos_metodo_pago.dart';
import '../componentes/seccion_tasa_ausentismo.dart';
import '../componentes/selector_periodo_reporte.dart';
import '../controladores/controlador_control_auditoria.dart';

/// Pantalla "Control y Auditora": para que el dueo, viajando o no, pueda
/// detectar remotamente si la secretaria/barberos le estn reportando bien
/// la plata y las citas reales. Separada de `PantallaReportesIngresos`
/// (esa muestra KPIs de negocio; esta busca seales de fraude/descuido).
class PantallaControlAuditoria extends ConsumerWidget {
  const PantallaControlAuditoria({super.key});

  Future<void> _seleccionarRangoPersonalizado(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final estado = ref.read(controladorControlAuditoriaProvider);
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
          .read(controladorControlAuditoriaProvider.notifier)
          .cambiarFiltro(
            FiltroPeriodo.personalizado,
            inicioCustom: inicio,
            finCustom: fin,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorControlAuditoriaProvider);
    final (inicio, fin) = estado.filtro.obtenerRangoFechas(
      fechaInicioCustom: estado.fechaInicioCustom,
      fechaFinCustom: estado.fechaFinCustom,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Control y Auditora')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(controladorControlAuditoriaProvider.notifier).cargar(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filtro por Perodo (mismo componente que Reportes de Ingresos)
            SelectorPeriodoReporte(
              filtroActual: estado.filtro,
              rangoFechas: (inicio, fin),
              alCambiarFiltro: (f) => ref
                  .read(controladorControlAuditoriaProvider.notifier)
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
              SeccionCitasSinPago(citas: estado.citasSinPago),
              const SizedBox(height: 16),
              SeccionIngresosMetodoPago(ingresos: estado.ingresosPorMetodo),
              const SizedBox(height: 16),
              SeccionTasaAusentismo(tasas: estado.tasaAusentismo),
              const SizedBox(height: 16),
              SeccionActividadUsuario(actividad: estado.actividadUsuarios),
            ],
          ],
        ),
      ),
    );
  }
}
