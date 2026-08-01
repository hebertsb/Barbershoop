import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_estado_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../administracion/dominio/modelo_servicio.dart';
import '../../../turnos/dominio/enum_estado_turno.dart';
import '../../dominio/enum_estado_cita.dart';
import '../../dominio/item_agenda.dart';
import 'etiqueta_estado.dart';

/// Tarjeta de la agenda del propio barbero: mezcla citas y turnos en un
/// timeline hora + tarjeta, con las acciones que le corresponden a cada
/// tipo (completar turno con cobro, confirmar llegada de una cita).
class TarjetaAgendaBarbero extends StatelessWidget {
  const TarjetaAgendaBarbero({
    super.key,
    required this.item,
    required this.servicios,
    required this.alCompletar,
    required this.alConfirmarLlegada,
    required this.alMarcarNoAsistio,
  });

  final ItemAgenda item;
  final List<ModeloServicio> servicios;
  final void Function(String turnoId) alCompletar;
  final Future<void> Function(String citaId) alConfirmarLlegada;
  final void Function(String citaId) alMarcarNoAsistio;

  String _nombreServicio(String servicioId) {
    final candidatos = servicios.where((s) => s.id == servicioId).toList();
    return candidatos.isEmpty ? 'Servicio' : candidatos.first.nombre;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colores = Theme.of(context).extension<ColoresEstadoApp>()!;

    return switch (item) {
      ItemAgendaCita(:final cita) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Text(
            formatoHora(cita.fechaHora),
            style: TipografiaApp.bodySm.copyWith(fontWeight: FontWeight.bold),
          ),
          title: Text(_nombreServicio(cita.servicioId)),
          subtitle: Text(cita.nombreCliente ?? 'Cliente'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cita.estado == EstadoCita.confirmada)
                OutlinedButton(
                  onPressed: () => alConfirmarLlegada(cita.id),
                  child: const Text('Llegó'),
                )
              else
                EtiquetaEstado(
                  texto: cita.estado.aTexto(),
                  color: colores.pendiente,
                ),
              if (cita.estado == EstadoCita.pendiente ||
                  cita.estado == EstadoCita.confirmada)
                PopupMenuButton<void>(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => alMarcarNoAsistio(cita.id),
                      child: const Text('No asistió'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      ItemAgendaTurno(:final turno) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Text(
            formatoHora(turno.horaLlegada),
            style: TipografiaApp.bodySm.copyWith(fontWeight: FontWeight.bold),
          ),
          title: Text(_nombreServicio(turno.servicioId)),
          subtitle: Text('Turno #${turno.numero}'),
          trailing: turno.estado == EstadoTurno.enAtencion
              ? FilledButton(
                  onPressed: () => alCompletar(turno.id),
                  child: const Text('Completar'),
                )
              : EtiquetaEstado(
                  texto: textoEstadoTurno(turno.estado),
                  color: colorScheme.primary,
                ),
        ),
      ),
    };
  }
}
