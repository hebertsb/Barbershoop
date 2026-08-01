import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controladores/controlador_resena_de_cita.dart';
import 'formulario_calificacion.dart';

/// Botón "Calificar" pensado como pie de `TarjetaMiCita` para citas
/// `completada`. Si la cita ya tiene reseña, no dibuja nada.
class ResenaCita extends ConsumerWidget {
  const ResenaCita({super.key, required this.citaId});

  final String citaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tieneResenaState = ref.watch(controladorResenaDeCitaProvider(citaId));
    final tieneResena = tieneResenaState.valueOrNull;

    if (tieneResenaState.isLoading && !tieneResenaState.hasValue) {
      return const SizedBox.shrink();
    }
    if (tieneResena == true) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => FormularioCalificacion(
              alConfirmar: (calificacion, comentario) => ref
                  .read(controladorResenaDeCitaProvider(citaId).notifier)
                  .calificar(
                    calificacion: calificacion,
                    comentario: comentario,
                  ),
            ),
          );
        },
        icon: const Icon(Icons.star_outline, size: 18),
        label: const Text('Calificar'),
      ),
    );
  }
}
