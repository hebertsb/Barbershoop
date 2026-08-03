import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_barbero.dart';
import '../controladores/controlador_barberos.dart';

const _niveles = ['junior', 'senior', 'master'];

const _etiquetasNivel = {
  'junior': 'JUNIOR',
  'senior': 'SENIOR',
  'master': 'MASTER',
};

const _coloresNivel = {
  'junior': Color(0xFF388E3C), // Verde elegante
  'senior': Color(0xFF1976D2), // Azul zafiro
  'master': Color(0xFFD4AF37), // Dorado premium
};

const _iconosNivel = {
  'junior': Icons.star_border,
  'senior': Icons.star_half,
  'master': Icons.star,
};

class SelectorNivelBarbero extends ConsumerWidget {
  const SelectorNivelBarbero({
    super.key,
    required this.barbero,
    required this.bloqueado,
  });

  final ModeloBarbero barbero;
  final bool bloqueado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nivelActual = barbero.nivel?.toLowerCase().trim();
    final nivelValido = (nivelActual != null && _niveles.contains(nivelActual))
        ? nivelActual
        : null;

    final colorBadge = _coloresNivel[nivelValido] ?? Colors.grey.shade600;
    final etiquetaBadge = _etiquetasNivel[nivelValido] ??
        (barbero.nivel != null && barbero.nivel!.isNotEmpty
            ? barbero.nivel!.toUpperCase()
            : 'SIN NIVEL');
    final iconoBadge = _iconosNivel[nivelValido] ?? Icons.workspace_premium;

    return PopupMenuButton<String?>(
      enabled: !bloqueado,
      tooltip: 'Cambiar Nivel de Barbero',
      initialValue: nivelValido,
      onSelected: (nuevoNivel) {
        ref
            .read(controladorBarberosProvider.notifier)
            .guardarNivel(barbero.id, nuevoNivel);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('Sin nivel'),
        ),
        const PopupMenuDivider(),
        ..._niveles.map(
          (n) => PopupMenuItem<String?>(
            value: n,
            child: Row(
              children: [
                Icon(
                  _iconosNivel[n],
                  color: _coloresNivel[n],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _etiquetasNivel[n]!,
                  style: TextStyle(
                    color: _coloresNivel[n],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorBadge.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorBadge, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconoBadge, size: 14, color: colorBadge),
            const SizedBox(width: 5),
            Text(
              etiquetaBadge,
              style: TipografiaApp.labelSm.copyWith(
                color: colorBadge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: colorBadge),
          ],
        ),
      ),
    );
  }
}
