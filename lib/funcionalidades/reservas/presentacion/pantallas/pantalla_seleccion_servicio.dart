import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../controladores/controlador_reserva.dart';

class PantallaSeleccionServicio extends ConsumerStatefulWidget {
  const PantallaSeleccionServicio({super.key});

  @override
  ConsumerState<PantallaSeleccionServicio> createState() =>
      _PantallaSeleccionServicioState();
}

class _PantallaSeleccionServicioState
    extends ConsumerState<PantallaSeleccionServicio> {
  @override
  void initState() {
    super.initState();
    // Ver comentario equivalente en PantallaSeleccionSucursal: diferir a
    // addPostFrameCallback evita la carrera con el Timer.periodic de
    // PantallaInicioCliente (sigue montada debajo de este push) invalidando
    // el mismo provider mientras este widget todavia se esta inicializando.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(controladorServiciosProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviciosState = ref.watch(controladorServiciosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona un Servicio')),
      body: serviciosState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (servicios) {
          final activos = servicios.where((s) => s.activo).toList();
          if (activos.isEmpty) {
            return const Center(child: Text('No hay servicios disponibles.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activos.length,
            itemBuilder: (context, index) {
              final servicio = activos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    ref
                        .read(controladorReservaProvider.notifier)
                        .seleccionarServicio(servicio.id);
                    context.push('/reservar/barbero');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (servicio.urlImagen != null)
                        CachedNetworkImage(
                          imageUrl: servicio.urlImagen!,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            height: 100,
                            color: colorScheme.surfaceContainerHigh,
                            child: const Center(
                              child: Icon(Icons.content_cut_outlined, size: 40),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    servicio.nombre,
                                    style: TipografiaApp.headlineSm.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColoresApp.primario,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    formatoMoneda(servicio.precio),
                                    style: TipografiaApp.labelMd.copyWith(
                                      color: ColoresApp.onPrimario,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Duración: ${servicio.duracionMin} min',
                                  style: TipografiaApp.labelSm.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (servicio.descripcion != null &&
                                servicio.descripcion!.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                servicio.descripcion!,
                                style: TipografiaApp.bodySm.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(controladorReservaProvider.notifier)
                                      .seleccionarServicio(servicio.id);
                                  context.push('/reservar/barbero');
                                },
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: const Text('Elegir Servicio'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor:
                                      colorScheme.onPrimaryContainer,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
