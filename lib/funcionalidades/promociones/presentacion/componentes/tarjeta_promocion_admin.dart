import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../dominio/enum_tipo_descuento.dart';
import '../../dominio/modelo_promocion.dart';

class TarjetaPromocionAdmin extends StatelessWidget {
  const TarjetaPromocionAdmin({
    super.key,
    required this.promocion,
    required this.onEditar,
    required this.onCambiarEstado,
    required this.onEliminar,
    required this.onVerUsos,
  });

  final ModeloPromocion promocion;
  final VoidCallback onEditar;
  final ValueChanged<bool> onCambiarEstado;
  final VoidCallback onEliminar;
  final VoidCallback onVerUsos;

  String _estadoTexto() {
    if (!promocion.activo) return 'Inactiva';
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    if (promocion.fechaInicio != null) {
      final inicio = DateTime(
        promocion.fechaInicio!.year,
        promocion.fechaInicio!.month,
        promocion.fechaInicio!.day,
      );
      if (inicio.isAfter(inicioHoy)) return 'Programada';
    }
    if (promocion.fechaFin != null) {
      final fin = DateTime(
        promocion.fechaFin!.year,
        promocion.fechaFin!.month,
        promocion.fechaFin!.day,
        23,
        59,
        59,
      );
      if (hoy.isAfter(fin)) return 'Vencida';
    }
    return 'Vigente';
  }

  Color _colorEstado() {
    switch (_estadoTexto()) {
      case 'Vigente':
        return ColoresApp.estadoCompletada;
      case 'Programada':
        return ColoresApp.estadoPendiente;
      case 'Vencida':
      case 'Inactiva':
      default:
        return ColoresApp.contorno;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final estado = _estadoTexto();
    final colorEst = _colorEstado();

    final textoDescuento = promocion.tipoDescuento == TipoDescuento.porcentaje
        ? '-${promocion.descuento.toStringAsFixed(0)}%'
        : '-Bs. ${promocion.descuento.toStringAsFixed(0)}';

    final rangoFechas =
        promocion.fechaInicio == null && promocion.fechaFin == null
        ? 'Sin limite de fecha'
        : '${promocion.fechaInicio != null ? formatoFechaCorta(promocion.fechaInicio!) : "Inicio"} '
              'a ${promocion.fechaFin != null ? formatoFechaCorta(promocion.fechaFin!) : "Indefinido"}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (promocion.imagen != null)
            CachedNetworkImage(
              imageUrl: promocion.imagen!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (context, error, stackTrace) => Container(
                height: 100,
                color: colorScheme.surfaceContainerHigh,
                child: const Center(
                  child: Icon(Icons.local_offer_outlined, size: 36),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges de estado y descuento en Wrap para evitar overflow
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Badge estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorEst.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        estado,
                        style: TipografiaApp.labelSm.copyWith(color: colorEst),
                      ),
                    ),
                    // Badge descuento
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        textoDescuento,
                        style: TipografiaApp.labelSm.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Badge COMBO
                    if (promocion.esCombo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ColoresApp.primario.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: ColoresApp.primario,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'COMBO',
                              style: TipografiaApp.labelSm.copyWith(
                                color: ColoresApp.primario,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Switch al final del wrap
                    Switch.adaptive(
                      value: promocion.activo,
                      onChanged: onCambiarEstado,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  promocion.titulo,
                  style: TipografiaApp.headlineSm.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (promocion.descripcion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    promocion.descripcion!,
                    style: TipografiaApp.bodySm.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        rangoFechas,
                        style: TipografiaApp.labelSm.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Servicios del combo
                if (promocion.etiquetaServicios.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        promocion.esCombo
                            ? Icons.auto_awesome
                            : Icons.content_cut_outlined,
                        size: 14,
                        color: ColoresApp.primario,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          promocion.etiquetaServicios,
                          style: TipografiaApp.labelSm.copyWith(
                            color: ColoresApp.primario,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: onVerUsos,
                      icon: const Icon(Icons.groups_outlined, size: 18),
                      label: const Text('Ver usos'),
                    ),
                    TextButton.icon(
                      onPressed: onEditar,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: onEliminar,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Eliminar'),
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
