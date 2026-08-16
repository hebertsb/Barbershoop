import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_insumo.dart';

class TarjetaInsumo extends StatelessWidget {
  const TarjetaInsumo({
    super.key,
    required this.insumo,
    this.onTap,
    this.onEditar,
    this.onAsignar,
  });

  final ModeloInsumo insumo;
  final VoidCallback? onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onAsignar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorStock = insumo.bajoMinimo
        ? ColoresApp.estadoCancelada
        : colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: insumo.bajoMinimo
              ? ColoresApp.estadoCancelada.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      elevation: 0,
      color: insumo.bajoMinimo
          ? ColoresApp.estadoCancelada.withValues(alpha: 0.05)
          : colorScheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icono de Insumo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: insumo.bajoMinimo
                      ? ColoresApp.estadoCancelada.withValues(alpha: 0.15)
                      : colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  insumo.bajoMinimo
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  color: insumo.bajoMinimo
                      ? ColoresApp.estadoCancelada
                      : colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Información del Insumo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            insumo.nombre,
                            style: TipografiaApp.bodyMd.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (insumo.bajoMinimo) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ColoresApp.estadoCancelada,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'STOCK BAJO',
                              style: TipografiaApp.labelSm.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    Row(
                      children: [
                        if (insumo.categoria != null &&
                            insumo.categoria!.isNotEmpty) ...[
                          Text(
                            insumo.categoria!,
                            style: TipografiaApp.bodySm.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        Text(
                          'Mín: ${insumo.stockMinimoFormateado}',
                          style: TipografiaApp.bodySm.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    if (insumo.descripcion != null &&
                        insumo.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        insumo.descripcion!,
                        style: TipografiaApp.bodySm.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Stock Actual y Acciones
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    insumo.stockFormateado,
                    style: TipografiaApp.headlineSm.copyWith(
                      color: colorStock,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onAsignar != null)
                        IconButton(
                          icon: const Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 18,
                          ),
                          tooltip: 'Asignar a barbero',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onAsignar,
                        ),
                      if (onEditar != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Editar insumo',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onEditar,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}