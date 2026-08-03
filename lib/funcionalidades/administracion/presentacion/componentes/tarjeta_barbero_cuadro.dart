import 'package:cached_network_image/cached_network_image.dart';
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

/// Tarjeta de barbero en formato cuadro (grilla 2 columnas), usada en
/// `PantallaGestionBarberos` cuando el admin elige la vista "Cuadros".
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

  /// Ver [SelectorNivelBarbero.bloqueado]: viene desde el buscador de
  /// `PantallaGestionBarberos`, ancestro de esta tarjeta.
  final bool bloqueadoSelector;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final resumenMedallas =
        ref.watch(controladorResumenMedallasProvider).asData?.value;
    final medallas = resumenMedallas?[barbero.id] ?? const ResumenMedallas();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ColoresApp.primario, width: 2),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: barbero.urlFotoPerfil != null &&
                          barbero.urlFotoPerfil!.isNotEmpty
                      ? Image.network(
                          barbero.urlFotoPerfil!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            backgroundColor: colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.person,
                              size: 36,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: colorScheme.surfaceContainerHigh,
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              barbero.nombrePerfil ?? 'Sin Nombre',
              style: TipografiaApp.bodyMd.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              sucursalNombre,
              style: TipografiaApp.bodySm.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            SelectorNivelBarbero(
              barbero: barbero,
              bloqueado: bloqueadoSelector,
            ),
            if (medallas.total > 0) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (medallas.oro > 0) '${medallas.oro}',
                  if (medallas.plata > 0) '${medallas.plata}',
                  if (medallas.bronce > 0) '${medallas.bronce}',
                ].join(' '),
                style: const TextStyle(fontSize: 11),
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  tooltip: 'Editar sucursal y especialidades',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
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
                    Icons.calendar_month,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  tooltip: 'Horarios',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  onPressed: () {
                    context.push(
                      '/administracion/barberos/${barbero.id}/horarios',
                      extra: barbero,
                    );
                  },
                ),
                Switch(
                  value: barbero.activo,
                  onChanged: (val) {
                    ref
                        .read(controladorBarberosProvider.notifier)
                        .actualizarEstadoBarbero(barbero.id, val);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
