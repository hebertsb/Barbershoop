import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../ranking_barberos/dominio/resumen_medallas_barbero.dart';
import '../../../ranking_barberos/presentacion/controladores/controlador_resumen_medallas.dart';
import '../../dominio/modelo_barbero.dart';
import '../../dominio/modelo_sucursal.dart';
import '../controladores/controlador_barberos.dart';
import 'formulario_editar_barbero.dart';
import 'selector_nivel_barbero.dart';

class TarjetaBarberoCuadro extends ConsumerWidget {
  const TarjetaBarberoCuadro({
    super.key,
    required this.barbero,
    required this.sucursalNombre,
    required this.sucursales,
    required this.bloqueadoSelector,
  });

  final ModeloBarbero barbero;
  final String sucursalNombre;
  final List<ModeloSucursal> sucursales;
  final bool bloqueadoSelector;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final resumenMedallas =
        ref.watch(controladorResumenMedallasProvider).asData?.value;
    final medallas = resumenMedallas?[barbero.id] ?? const ResumenMedallas();

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de Foto Superior (Estilo TarjetaSucursal)
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                color: colorScheme.surfaceContainerHigh,
                child: barbero.urlFotoPerfil != null &&
                        barbero.urlFotoPerfil!.isNotEmpty
                    ? Image.network(
                        barbero.urlFotoPerfil!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.person,
                            size: 54,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.person,
                          size: 54,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              // Badge de Estado ACTIVO / INACTIVO
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (barbero.activo
                            ? ColoresApp.estadoCompletada
                            : ColoresApp.estadoCancelada)
                        .withAlpha(220),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    barbero.activo ? 'ACTIVO' : 'INACTIVO',
                    style: TipografiaApp.labelSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Detalles y Acciones del Barbero
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barbero.nombrePerfil ?? 'Barbero',
                  style: TipografiaApp.bodyMd.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        sucursalNombre,
                        style: TipografiaApp.bodySm.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SelectorNivelBarbero(
                      barbero: barbero,
                      bloqueado: bloqueadoSelector,
                    ),
                    if (medallas.total > 0)
                      Text(
                        '🏅 ${medallas.total}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      tooltip: 'Editar sucursal y especialidades',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => FormularioEditarBarbero(
                            barbero: barbero,
                            sucursales: sucursales,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.calendar_month_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      tooltip: 'Horarios',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        context.push(
                          '/administracion/barberos/${barbero.id}/horarios',
                          extra: barbero,
                        );
                      },
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: barbero.activo,
                        onChanged: (val) {
                          ref
                              .read(controladorBarberosProvider.notifier)
                              .actualizarEstadoBarbero(barbero.id, val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
