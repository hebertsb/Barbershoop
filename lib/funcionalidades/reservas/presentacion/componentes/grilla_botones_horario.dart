import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controladores/controlador_reserva.dart';

/// Un ítem de la grilla de horarios: la hora concreta a reservar, el texto
/// ya formateado a mostrar y si está libre (si no lo está, se pinta
/// tachado y deshabilitado). Tanto la grilla con bloqueados
/// (`CuerpoGrillaHorario`) como la de solo libres (`CuerpoSoloLibresHorario`)
/// arman una lista de este tipo antes de delegar el pintado aquí.
typedef ItemGrillaHorario = ({DateTime hora, String texto, bool libre});

/// Grilla de 3 columnas con los botones de horario. Los ítems libres son
/// botones que, al presionarlos, seleccionan la hora y avanzan a confirmar;
/// los bloqueados se muestran tachados y sin acción.
class GrillaBotonesHorario extends ConsumerWidget {
  const GrillaBotonesHorario({super.key, required this.items});

  final List<ItemGrillaHorario> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (!item.libre) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              item.texto,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        return OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.primary),
            foregroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          icon: const Icon(Icons.schedule, size: 14),
          label: Text(
            item.texto,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            ref
                .read(controladorReservaProvider.notifier)
                .seleccionarHorario(item.hora);
            context.push('/reservar/confirmar');
          },
        );
      },
    );
  }
}
