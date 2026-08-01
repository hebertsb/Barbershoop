import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../dominio/modelo_resultado_ranking_barbero.dart';

/// Podio visual del top 3 (orden 2-1-3). Tocar un puesto expande inline el
/// desglose por factor (citas, ingresos, clientes, puntualidad, calificación
/// de clientes) debajo.
class PodioRanking extends StatefulWidget {
  const PodioRanking({super.key, required this.resultados});

  final List<ModeloResultadoRankingBarbero> resultados;

  @override
  State<PodioRanking> createState() => _PodioRankingState();
}

class _PodioRankingState extends State<PodioRanking> {
  String? _barberoExpandidoId;

  ModeloResultadoRankingBarbero? _buscar(int puesto) {
    for (final r in widget.resultados) {
      if (r.puesto == puesto) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primero = _buscar(1);
    final segundo = _buscar(2);
    final tercero = _buscar(3);
    final expandido = widget.resultados
        .where((r) => r.barberoId == _barberoExpandidoId)
        .toList();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (segundo != null)
              _puestoPodio(segundo, alto: 60, colorScheme: colorScheme),
            const SizedBox(width: 8),
            if (primero != null)
              _puestoPodio(
                primero,
                alto: 84,
                colorScheme: colorScheme,
                destacado: true,
              ),
            const SizedBox(width: 8),
            if (tercero != null)
              _puestoPodio(tercero, alto: 46, colorScheme: colorScheme),
          ],
        ),
        if (expandido.isNotEmpty) ...[
          const SizedBox(height: 12),
          _desglose(expandido.first, colorScheme),
        ],
      ],
    );
  }

  Widget _puestoPodio(
    ModeloResultadoRankingBarbero r, {
    required double alto,
    required ColorScheme colorScheme,
    bool destacado = false,
  }) {
    return GestureDetector(
      onTap: () => setState(() {
        _barberoExpandidoId = _barberoExpandidoId == r.barberoId
            ? null
            : r.barberoId;
      }),
      child: Column(
        children: [
          CircleAvatar(
            radius: destacado ? 28 : 22,
            backgroundColor: colorScheme.surfaceContainerHigh,
            child: Text(r.puesto.toString()),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 72,
            child: Text(
              r.nombre,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 64,
            height: alto,
            decoration: BoxDecoration(
              color: destacado
                  ? ColoresApp.primario.withValues(alpha: 0.25)
                  : colorScheme.surfaceContainerHigh,
              border: destacado
                  ? Border.all(color: ColoresApp.primario, width: 2)
                  : null,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${r.puesto}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: destacado
                    ? ColoresApp.primario
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desglose(ModeloResultadoRankingBarbero r, ColorScheme colorScheme) {
    Widget fila(String etiqueta, String valor, int puesto) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              etiqueta,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            Text(
              '$valor · $puesto° lugar',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: ColoresApp.primario),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${r.nombre} — Puntaje ${r.puntaje.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          fila('Citas completadas', '${r.citasCompletadas}', r.puestoCitas),
          fila(
            'Ingresos generados',
            'Bs ${r.ingresosGenerados.toStringAsFixed(0)}',
            r.puestoIngresos,
          ),
          fila(
            'Clientes distintos',
            '${r.clientesDistintos}',
            r.puestoClientes,
          ),
          fila(
            'Puntualidad',
            '${(100 - r.tasaNoShow * 100).toStringAsFixed(0)}%',
            r.puestoPuntualidad,
          ),
          fila(
            'Calificación de clientes',
            r.calificacionPromedio > 0
                ? '${r.calificacionPromedio.toStringAsFixed(1)} ⭐'
                : 'Sin reseñas',
            r.puestoCalificacion,
          ),
        ],
      ),
    );
  }
}
