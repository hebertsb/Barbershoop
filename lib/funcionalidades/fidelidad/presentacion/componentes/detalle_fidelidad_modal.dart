import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controladores/controlador_progreso_fidelidad.dart';

class DetalleFidelidadModal extends ConsumerWidget {
  const DetalleFidelidadModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorProgresoFidelidadProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tus programas de fidelidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            estado.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString()),
              data: (programas) {
                if (programas.isEmpty) {
                  return const Text(
                    'Todavía no tenés progreso en ningún programa.',
                  );
                }
                return Column(
                  children: programas.map((p) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: p.progresoActual / p.metaCitas,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            const SizedBox(height: 6),
                            Text('${p.progresoActual} / ${p.metaCitas} citas'),
                            if (p.puedeReclamar) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () async {
                                    await ref
                                        .read(
                                          controladorProgresoFidelidadProvider
                                              .notifier,
                                        )
                                        .reclamarPremio(p.programaId);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '¡Premio reclamado! Ya lo tenés '
                                            'disponible para tu próxima '
                                            'reserva.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Reclamar'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
