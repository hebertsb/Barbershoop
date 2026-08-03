import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_insumo.dart';

class TarjetaInsumo extends StatelessWidget {
  const TarjetaInsumo({
    super.key,
    required this.insumo,
    this.onTap,
    this.trailing,
  });

  final ModeloInsumo insumo;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorStock = insumo.bajoMinimo
        ? ColoresApp.estadoCancelada
        : colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          insumo.nombre,
          style: TipografiaApp.bodyMd.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          insumo.categoria ?? 'Sin categoría',
          style: TipografiaApp.bodySm.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing:
            trailing ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${insumo.stock}',
                  style: TipografiaApp.headlineSm.copyWith(color: colorStock),
                ),
                Text(
                  'mín. ${insumo.stockMinimo}',
                  style: TipografiaApp.labelSm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}