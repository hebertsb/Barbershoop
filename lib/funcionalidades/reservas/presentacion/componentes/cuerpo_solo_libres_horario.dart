import 'package:flutter/material.dart';

import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../dominio/modelo_horario_disponible.dart';
import 'encabezado_seccion_horario.dart';
import 'grilla_botones_horario.dart';
import 'sin_horarios_disponibles.dart';

/// Cuerpo en modo "cualquiera disponible": solo libres, sin bloqueados,
/// agrupados en Mañana/Tarde (mismo agrupamiento visual, sin leyenda ni
/// tachado porque no hay concepto de "bloqueado" cruzando varios barberos).
class CuerpoSoloLibresHorario extends StatelessWidget {
  const CuerpoSoloLibresHorario({super.key, required this.future});

  final Future<List<ModeloHorarioDisponible>>? future;

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<List<ModeloHorarioDisponible>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final horarios = snapshot.data ?? [];
        final horasUnicas = <String, DateTime>{};
        for (final h in horarios) {
          horasUnicas[formatoHora(h.horaInicio.toLocal())] = h.horaInicio
              .toLocal();
        }
        if (horasUnicas.isEmpty) {
          return const SinHorariosDisponibles();
        }
        final entradas = horasUnicas.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        final manana = entradas.where((e) => e.value.hour < 12).toList();
        final tarde = entradas.where((e) => e.value.hour >= 12).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (manana.isNotEmpty) ...[
              const EncabezadoSeccionHorario(texto: 'MAÑANA'),
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

  List<ItemGrillaHorario> _aItems(List<MapEntry<String, DateTime>> entradas) {
    return entradas
        .map((e) => (hora: e.value, texto: e.key, libre: true))
        .toList();
  }
}
