import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_estado_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final colores = Theme.of(context).extension<ColoresEstadoApp>()!;

    return switch (item) {
      ItemAgendaCita(:final cita) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule_outlined,
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatoHora(cita.fechaHora),
                          style: TipografiaApp.headlineSm.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cita.nombreCliente ?? 'Cita reservada',
                          style: TipografiaApp.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (cita.telefonoCliente != null &&
                            cita.telefonoCliente!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cita.telefonoCliente!,
                                style: TipografiaApp.bodySm.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  EtiquetaEstado(
                    texto: textoEstadoCita(cita.estado),
                    color: colorParaEstadoCita(cita.estado, colores),
                  ),
                ],
              ),
              if (cita.estado == EstadoCita.pendiente) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (cita.fechaHora.toLocal().isBefore(DateTime.now()))
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colores.cancelada,
                          side: BorderSide(color: colores.cancelada),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => alMarcarNoAsistio(cita.id),
                        icon: const Icon(Icons.person_off_outlined, size: 18),
                        label: const Text('No asistió'),
                      ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => alConfirmarLlegada(cita.id),
                      icon: const Icon(Icons.person_pin_circle_outlined, size: 18),
                      label: const Text('Cliente llegó'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      ItemAgendaTurno(:final turno) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        color: colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        turno.citaId != null
                            ? 'Reservado · Turno #${turno.numero}'
                            : 'Turno #${turno.numero}',
                        style: TipografiaApp.headlineSm.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  EtiquetaEstado(
                    texto: textoEstadoTurno(turno.estado),
                    color: colorParaEstadoTurno(turno.estado, colores),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (turno.estado == EstadoTurno.esperando)
                    turno.citaId != null && turno.barberoId != null
                        ? FilledButton.icon(
                            onPressed: () => alLlamar(turno.id, turno.barberoId!),
                            icon: const Icon(Icons.notifications_active_outlined, size: 18),
                            label: const Text('Atender'),
                          )
                        : PopupMenuButton<String>(
                            enabled: disponibilidadBarberos.isNotEmpty,
                            onSelected: (barberoId) =>
                                alLlamar(turno.id, barberoId),
                            itemBuilder: (context) => disponibilidadBarberos
                                .map(
                                  (estado) => PopupMenuItem(
                                    value: estado.barbero.id,
                                    enabled: !estado.ocupado && !estado.fueraDeHorario,
                                    child: Text(
                                      '${estado.barbero.nombrePerfil ?? 'Sin nombre'}'
                                      '${estado.ocupado || estado.fueraDeHorario ? ' · ${textoDisponibilidadBarbero(estado)}' : ''}',
                                    ),
                                  ),
                                )
                                .toList(),
                            child: Chip(
                              avatar: const Icon(Icons.person_search_outlined, size: 16),
                              label: Text(
                                disponibilidadBarberos.isEmpty
                                    ? 'Sin barberos'
                                    : 'Llamar',
                              ),
                            ),
                          ),
                  if (turno.estado == EstadoTurno.enAtencion)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => alCompletar(turno.id),
                      icon: const Icon(Icons.check_circle_outlined, size: 18),
                      label: const Text('Completar'),
                    ),
                  if (turno.estado == EstadoTurno.esperando ||
                      turno.estado == EstadoTurno.enAtencion)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colores.cancelada,
                        side: BorderSide(color: colores.cancelada),
                      ),
                      onPressed: () => alCancelar(turno.id),
                      icon: const Icon(Icons.close_outlined, size: 18),
                      label: const Text('Cancelar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    };
  }
}
