import 'package:flutter/material.dart';

import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../dominio/modelo_slot_grilla.dart';
import 'encabezado_seccion_horario.dart';
import 'grilla_botones_horario.dart';
import 'leyenda_libre_bloqueado.dart';
import 'sin_horarios_disponibles.dart';

/// Cuerpo cuando hay un barbero especfico elegido: libres + bloqueados
/// tachados, agrupados en Maana/Tarde, con leyenda.
class CuerpoGrillaHorario extends StatelessWidget {
  const CuerpoGrillaHorario({super.key, required this.future});

  final Future<List<ModeloSlotGrilla>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ModeloSlotGrilla>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final slots = snapshot.data ?? [];
        if (slots.isEmpty) {
          return const SinHorariosDisponibles();
        }
        final manana = slots
            .where((s) => s.horaInicio.toLocal().hour < 12)
            .toList();
        final tarde = slots
            .where((s) => s.horaInicio.toLocal().hour >= 12)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const LeyendaLibreBloqueado(),
            const SizedBox(height: 16),
            if (manana.isNotEmpty) ...[
              const EncabezadoSeccionHorario(texto: 'MAANA'),
              const SizedBox(height: 8),
              GrillaBotonesHorario(items: _aItems(manana)),
              const SizedBox(height: 20),
            ],
            if (tarde.isNotEmpty) ...[
              const EncabezadoSeccionHorario(texto: 'TARDE'),
              const SizedBox(height: 8),
              GrillaBotonesHorario(items: _aItems(tarde)),
            ],
          ],
        );
      },
    );
  }

  List<ItemGrillaHorario> _aItems(List<ModeloSlotGrilla> slots) {
    return slots
        .map(
          (s) => (
            hora: s.horaInicio.toLocal(),
            texto: formatoHora(s.horaInicio.toLocal()),
            libre: s.libre,
          ),
        )
        .toList();
  }
}
