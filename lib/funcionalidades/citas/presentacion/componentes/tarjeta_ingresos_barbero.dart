import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administracion/presentacion/componentes/tarjeta_ingresos.dart';
import '../controladores/controlador_resumen_ingresos_barbero.dart';

/// Tarjeta con los ingresos propios del barbero autenticado (hoy/semana/mes),
/// para su panel de Inicio. Reusa [TarjetaIngresos] (mismo componente que el
/// dashboard de administracin) para que ambos paneles luzcan consistentes.
class TarjetaIngresosBarbero extends ConsumerWidget {
  const TarjetaIngresosBarbero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorResumenIngresosBarberoProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return estado.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text(
        error.toString(),
        style: TextStyle(color: colorScheme.error),
      ),
      data: (resumen) => Row(
        children: [
          Expanded(
            child: TarjetaIngresos(titulo: 'Hoy', monto: resumen.ingresosHoy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TarjetaIngresos(
              titulo: 'Semana',
              monto: resumen.ingresosSemana,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TarjetaIngresos(titulo: 'Mes', monto: resumen.ingresosMes),
          ),
        ],
      ),
    );
  }
}