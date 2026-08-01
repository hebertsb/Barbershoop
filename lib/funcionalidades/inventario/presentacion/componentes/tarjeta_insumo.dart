import 'package:flutter/material.dart';

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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      insumo.nombre,
                      style: TipografiaApp.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (insumo.bajoMinimo)
                    Icon(
                      Icons.warning_amber_outlined,
                      color: colorScheme.error,
                      size: 18,
                    ),
                  ?trailing,
                ],
              ),
              if (insumo.categoria != null) ...[
                const SizedBox(height: 4),
                Text(
                  insumo.categoria!,
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Stock: ${insumo.stock} (mín. ${insumo.stockMinimo})',
                style: TipografiaApp.bodySm.copyWith(
                  color: insumo.bajoMinimo
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                  fontWeight: insumo.bajoMinimo ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
