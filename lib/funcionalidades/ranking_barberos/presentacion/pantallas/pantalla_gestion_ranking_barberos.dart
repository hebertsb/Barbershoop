import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../administracion/dominio/modelo_sucursal.dart';
import '../../../administracion/presentacion/controladores/controlador_sucursales.dart';
import '../../dominio/modelo_programa_ranking_barberos.dart';
import '../componentes/formulario_programa_ranking.dart';
import '../controladores/controlador_ranking_barberos.dart';

class PantallaGestionRankingBarberos extends ConsumerWidget {
  const PantallaGestionRankingBarberos({super.key});

  void _abrirFormulario(
    BuildContext context,
    WidgetRef ref,
    List<ModeloSucursal> sucursales,
    ModeloProgramaRankingBarberos? programa,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioProgramaRanking(
        programa: programa,
        sucursales: sucursales,
        alGuardar: (p) => ref
            .read(controladorRankingBarberosProvider.notifier)
            .guardarPrograma(p),
      ),
    );
  }

  Future<void> _confirmarCierre(
    BuildContext context,
    WidgetRef ref,
    ModeloProgramaRankingBarberos programa,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar y premiar?'),
        content: Text(
          'Se va a fijar el podio final de "${programa.titulo}" y se '
          'otorgarn las insignias del top 3. Esta accin no se puede '
          'deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar y premiar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      await ref
          .read(controladorRankingBarberosProvider.notifier)
          .cerrarPrograma(programa.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _etiquetaEstado(ModeloProgramaRankingBarberos p) {
    if (p.estaCerrado) return 'Cerrado';
    if (p.listoParaCerrar) return 'Listo para cerrar';
    return 'Activo';
  }

  Color _colorEstado(ModeloProgramaRankingBarberos p) {
    if (p.estaCerrado) return Colors.grey;
    if (p.listoParaCerrar) return ColoresApp.primario;
    return ColoresApp.estadoCompletada;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorRankingBarberosProvider);
    final sucursalesState = ref.watch(controladorSucursalesProvider);
    final sucursales = sucursalesState.value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking de Barberos')),
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (programas) {
          if (programas.isEmpty) {
            return const Center(
              child: Text('Todava no creaste ningn programa de ranking.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: programas.length,
            itemBuilder: (context, index) {
              final p = programas[index];
              final sucursalCoincidente = sucursales
                  .where((s) => s.id == p.sucursalId)
                  .toList();
              final sucursalNombre = sucursalCoincidente.isNotEmpty
                  ? sucursalCoincidente.first.nombre
                  : 'Sucursal';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(_etiquetaEstado(p)),
                            backgroundColor: _colorEstado(
                              p,
                            ).withValues(alpha: 0.15),
                            labelStyle: TextStyle(color: _colorEstado(p)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sucursalNombre  ${formatoFechaCorta(p.fechaInicio)} a '
                        '${formatoFechaCorta(p.fechaFin)}',
                      ),
                      Text(
                        'Premio: ${p.descripcionPremio} (${p.tipoPremio.etiqueta})',
                      ),
                      if (p.estaCerrado) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Ganador: ${p.nombreGanador ?? ""}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!p.estaCerrado)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _abrirFormulario(context, ref, sucursales, p),
                            ),
                          if (p.listoParaCerrar)
                            FilledButton.icon(
                              onPressed: () =>
                                  _confirmarCierre(context, ref, p),
                              icon: const Icon(Icons.emoji_events_outlined),
                              label: const Text('Cerrar y premiar'),
                            ),
                          if (p.estaCerrado && !p.premioEntregado)
                            OutlinedButton(
                              onPressed: () => ref
                                  .read(
                                    controladorRankingBarberosProvider.notifier,
                                  )
                                  .marcarPremioEntregado(p.id),
                              child: const Text('Marcar entregado'),
                            ),
                          if (p.estaCerrado && p.premioEntregado)
                            const Chip(label: Text('Premio entregado ')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColoresApp.primario,
        onPressed: sucursales.isEmpty
            ? null
            : () => _abrirFormulario(context, ref, sucursales, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
