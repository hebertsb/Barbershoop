import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../componentes/tarjeta_reporte_insumo.dart';
import '../controladores/controlador_bandeja_reportes.dart';

class PantallaBandejaReportes extends ConsumerWidget {
  const PantallaBandejaReportes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportesState = ref.watch(controladorBandejaReportesProvider);

    ref.listen(controladorBandejaReportesProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes de insumos')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(controladorBandejaReportesProvider.future),
        child: reportesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (reportes) {
            if (reportes.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: Text('No hay reportes pendientes.')),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reportes.length,
              itemBuilder: (context, index) {
                final reporte = reportes[index];
                return TarjetaReporteInsumo(
                  reporte: reporte,
                  onAprobar: () => ref
                      .read(controladorBandejaReportesProvider.notifier)
                      .revisar(reporteId: reporte.id, aprobar: true),
                  onRechazar: () => ref
                      .read(controladorBandejaReportesProvider.notifier)
                      .revisar(reporteId: reporte.id, aprobar: false),
                );
              },
            );
          },
        ),
      ),
    );
  }
}