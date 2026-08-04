import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_estado_app.dart';
import '../../../turnos/dominio/enum_estado_turno.dart';
import '../../dominio/disponibilidad_barbero.dart';
import '../../dominio/enum_estado_cita.dart';
import '../../dominio/item_agenda.dart';
import 'etiqueta_estado.dart';
import 'panel_disponibilidad_barberos.dart';

class TarjetaAgendaItem extends StatelessWidget {
  const TarjetaAgendaItem({
    super.key,
    required this.item,
    required this.disponibilidadBarberos,
    required this.alLlamar,
    required this.alCompletar,
    required this.alCancelar,
    required this.alConfirmarLlegada,
    required this.alMarcarNoAsistio,
  });

  final ItemAgenda item;
  final List<EstadoDisponibilidadBarbero> disponibilidadBarberos;
  final void Function(String turnoId, String barberoId) alLlamar;
  final void Function(String turnoId) alCompletar;
  final void Function(String turnoId) alCancelar;
  final void Function(String citaId) alConfirmarLlegada;
  final void Function(String citaId) alMarcarNoAsistio;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).extension<ColoresEstadoApp>()!;

    return switch (item) {
      ItemAgendaCita(:final cita) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatoHora(cita.fechaHora)} ${cita.nombreCliente ?? 'Cita reservada'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (cita.telefonoCliente != null)
                          Text(cita.telefonoCliente!),
                      ],
                    ),
                  ),
                  EtiquetaEstado(
                    texto: textoEstadoCita(cita.estado),
                    color: colorParaEstadoCita(cita.estado, colores),
                  ),
                ],
              ),
              if (cita.estado == EstadoCita.pendiente)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cita.fechaHora.toLocal().isBefore(DateTime.now()))
                        TextButton(
                          onPressed: () => alMarcarNoAsistio(cita.id),
                          child: Text(
                            'No asisti',
                            style: TextStyle(color: colores.cancelada),
                          ),
                        ),
                      TextButton(
                        onPressed: () => alConfirmarLlegada(cita.id),
                        child: const Text('Cliente lleg'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      ItemAgendaTurno(:final turno) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    turno.citaId != null
                        ? 'Reservado  Turno #${turno.numero}'
                        : 'Turno #${turno.numero}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  EtiquetaEstado(
                    texto: textoEstadoTurno(turno.estado),
                    color: colorParaEstadoTurno(turno.estado, colores),
                  ),
                ],
              ),
              if (turno.estado == EstadoTurno.esperando)
                Align(
                  alignment: Alignment.centerRight,
                  child: turno.citaId != null && turno.barberoId != null
                      ? TextButton(
                          onPressed: () => alLlamar(turno.id, turno.barberoId!),
                          child: const Text('Atender'),
                        )
                      : PopupMenuButton<String>(
                          enabled: disponibilidadBarberos.isNotEmpty,
                          onSelected: (barberoId) =>
                              alLlamar(turno.id, barberoId),
                          itemBuilder: (context) => disponibilidadBarberos
                              .map(
                                (estado) => PopupMenuItem(
                                  value: estado.barbero.id,
                                  enabled: !estado.ocupado,
                                  child: Text(
                                    '${estado.barbero.nombrePerfil ?? 'Sin nombre'}'
                                    '${estado.ocupado ? '  ${textoDisponibilidadBarbero(estado)}' : ''}',
                                  ),
                                ),
                              )
                              .toList(),
                          child: Chip(
                            label: Text(
                              disponibilidadBarberos.isEmpty
                                  ? 'Sin barberos'
                                  : 'Llamar',
                            ),
                          ),
                        ),
                ),
              if (turno.estado == EstadoTurno.enAtencion)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => alCompletar(turno.id),
                    child: const Text('Completar'),
                  ),
                ),
              if (turno.estado == EstadoTurno.esperando ||
                  turno.estado == EstadoTurno.enAtencion)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => alCancelar(turno.id),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: colores.cancelada),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    };
  }
}
