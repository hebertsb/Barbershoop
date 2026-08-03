import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../componentes/tarjeta_resena.dart';
import '../controladores/controlador_mis_resenas.dart';

class PantallaMisResenas extends ConsumerWidget {
  const PantallaMisResenas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resenasState = ref.watch(controladorMisResenasProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reseas')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(controladorMisResenasProvider.future),
        child: resenasState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (resenas) {
            final promedio = resenas.isEmpty
                ? null
                : resenas.map((r) => r.calificacion).reduce((a, b) => a + b) /
                      resenas.length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (promedio != null) ...[
                  Center(
                    child: Column(
                      children: [
                        Text(
                          promedio.toStringAsFixed(1),
                          style: TipografiaApp.headlineMd.copyWith(
                            color: ColoresApp.primario,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 1; i <= 5; i++)
                              Icon(
                                i <= promedio.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 20,
                                color: ColoresApp.primario,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resenas.length == 1
                              ? '1 resea'
                              : '${resenas.length} reseas',
                          style: TipografiaApp.bodySm.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (resenas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Todava no tens reseas.',
                        style: TipografiaApp.bodyMd.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  for (final resena in resenas) TarjetaResena(resena: resena),
              ],
            );
          },
        ),
      ),
    );
  }
}
