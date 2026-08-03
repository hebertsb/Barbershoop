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

/// Tarjeta de barbero en formato lista (una fila por barbero), usada en
/// `PantallaGestionBarberos` cuando el admin elige la vista "Lista".
class TarjetaBarberoLista extends ConsumerWidget {
  const TarjetaBarberoLista({
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ColoresApp.primario),
          ),
          child: ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: barbero.urlFotoPerfil != null &&
                      barbero.urlFotoPerfil!.isNotEmpty
                  ? Image.network(
                      barbero.urlFotoPerfil!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        child: Icon(
                          Icons.person,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      child: Icon(
                        Icons.person,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
        title: Text(
          barbero.nombrePerfil ?? 'Sin Nombre',
          style: TipografiaApp.bodyMd.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sucursal: $sucursalNombre',
              style: TipografiaApp.bodySm.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
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
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
              tooltip: 'Editar sucursal y especialidades',
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
              icon: Icon(Icons.calendar_month, color: colorScheme.primary),
              tooltip: 'Horarios',
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
      ),
    );
  }
}
