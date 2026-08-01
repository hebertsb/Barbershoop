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

/// Selector del `nivel` del barbero (junior/senior/master), usado en las
/// tarjetas de `PantallaGestionBarberos`.
///
/// [bloqueado]: cuando el buscador de la pantalla tiene texto, se
/// deshabilita para evitar guardar sobre una lista que puede reordenarse
/// mientras el admin todavía está escribiendo.
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
    return DropdownButton<String?>(
      value: barbero.nivel,
      hint: const Text('Sin nivel'),
      isDense: true,
      underline: const SizedBox.shrink(),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Sin nivel')),
        ..._niveles.map(
          (n) => DropdownMenuItem<String?>(
            value: n,
            child: Text(_etiquetasNivel[n]!),
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
