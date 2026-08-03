import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelo_barbero.dart';
import '../controladores/controlador_barberos.dart';

const _niveles = ['junior', 'senior', 'master'];

const _etiquetasNivel = {
  'junior': 'Junior',
  'senior': 'Senior',
  'master': 'Master',
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

    return DropdownButton<String?>(
      value: nivelValido,
      hint: Text(barbero.nivel != null && barbero.nivel!.isNotEmpty
          ? barbero.nivel!
          : 'Sin nivel'),
      isDense: true,
      underline: const SizedBox.shrink(),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Sin nivel')),
        ..._niveles.map(
          (n) => DropdownMenuItem<String?>(
            value: n,
            child: Text(_etiquetasNivel[n] ?? n.toUpperCase()),
          ),
        ),
      ],
      onChanged: bloqueado
          ? null
          : (nivel) {
              ref
                  .read(controladorBarberosProvider.notifier)
                  .guardarNivel(barbero.id, nivel);
            },
    );
  }
}
