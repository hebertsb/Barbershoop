import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../componentes/podio_ranking.dart';
import '../controladores/controlador_ranking_barbero.dart';

/// Pantalla del barbero: su podio (top 3 de su sucursal) y su vitrina
/// histrica de insignias ganadas. Accesible desde el men "Ms".
class PantallaRankingBarbero extends ConsumerWidget {
  const PantallaRankingBarbero({super.key});

  String _medalla(int puesto) => switch (puesto) {
    1 => '',
    2 => '',
    _ => '',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorMiRankingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (datos) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (datos.programa == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Tu sucursal no tiene ningn programa de ranking.',
                    ),
                  ),
                )
              else ...[
                Text(
                  datos.programa!.titulo,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${formatoFechaCorta(datos.programa!.fechaInicio)} a '
                  '${formatoFechaCorta(datos.programa!.fechaFin)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                PodioRanking(resultados: datos.resultados),
              ],
              const SizedBox(height: 32),
              Text(
                ' Mis insignias (${datos.misInsignias.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (datos.misInsignias.isEmpty)
                const Text('Todava no ganaste ninguna insignia.')
              else
                for (final insignia in datos.misInsignias)
                  ListTile(
                    leading: Text(
                      _medalla(insignia.puesto),
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(insignia.tituloPrograma),
                    subtitle: Text(formatoFechaCorta(insignia.otorgadaEn)),
                  ),
            ],
          );
        },
      ),
    );
  }
}
