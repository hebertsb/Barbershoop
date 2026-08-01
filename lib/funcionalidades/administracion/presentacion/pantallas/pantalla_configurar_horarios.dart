import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelo_barbero.dart';
import '../../dominio/modelo_horario_barbero.dart';
import '../controladores/controlador_horarios_barbero.dart';

class PantallaConfigurarHorarios extends ConsumerStatefulWidget {
  const PantallaConfigurarHorarios({
    super.key,
    required this.barberoId,
    this.barbero,
  });

  final String barberoId;
  final ModeloBarbero? barbero;

  @override
  ConsumerState<PantallaConfigurarHorarios> createState() =>
      _PantallaConfigurarHorariosState();
}

class _PantallaConfigurarHorariosState
    extends ConsumerState<PantallaConfigurarHorarios> {
  // Lista de días de la semana (0: Domingo, 1: Lunes, ..., 6: Sábado)
  final List<String> _diasNombres = [
    'Domingo',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];

  // Estado local para los días activos y sus horarios
  final Map<int, bool> _diasActivos = {};
  final Map<int, TimeOfDay> _horasInicio = {};
  final Map<int, TimeOfDay> _horasFin = {};

  bool _inicializado = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Inicializar valores por defecto
    for (int i = 0; i < 7; i++) {
      _diasActivos[i] = false;
      _horasInicio[i] = const TimeOfDay(hour: 9, minute: 0);
      _horasFin[i] = const TimeOfDay(hour: 18, minute: 0);
    }
  }

  void _inicializarConHorariosExistentes(List<ModeloHorarioBarbero> horarios) {
    if (_inicializado) return;

    for (final h in horarios) {
      final dia = h.diaSemana;
      _diasActivos[dia] = true;

      // Parsear horas
      final partesInicio = h.horaInicio.split(':');
      if (partesInicio.length >= 2) {
        _horasInicio[dia] = TimeOfDay(
          hour: int.parse(partesInicio[0]),
          minute: int.parse(partesInicio[1]),
        );
      }

      final partesFin = h.horaFin.split(':');
      if (partesFin.length >= 2) {
        _horasFin[dia] = TimeOfDay(
          hour: int.parse(partesFin[0]),
          minute: int.parse(partesFin[1]),
        );
      }
    }
    _inicializado = true;
  }

  Future<void> _seleccionarHora(
    BuildContext context,
    int dia,
    bool esInicio,
  ) async {
    final horaActual = esInicio ? _horasInicio[dia]! : _horasFin[dia]!;
    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: horaActual,
    );

    if (horaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _horasInicio[dia] = horaSeleccionada;
        } else {
          _horasFin[dia] = horaSeleccionada;
        }
      });
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final horariosNuevos = <ModeloHorarioBarbero>[];
      for (int i = 0; i < 7; i++) {
        if (_diasActivos[i]!) {
          final inicio = _horasInicio[i]!;
          final fin = _horasFin[i]!;
          final inicioStr =
              '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
          final finStr =
              '${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}';

          horariosNuevos.add(
            ModeloHorarioBarbero(
              id: '', // Se generará en la base de datos o se recreará
              barberoId: widget.barberoId,
              barberiaId: widget.barbero?.barberiaId ?? '',
              diaSemana: i,
              horaInicio: inicioStr,
              horaFin: finStr,
            ),
          );
        }
      }

      await ref
          .read(controladorHorariosBarberoProvider(widget.barberoId).notifier)
          .guardarHorarios(horariosNuevos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horarios guardados exitosamente.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horariosState = ref.watch(
      controladorHorariosBarberoProvider(widget.barberoId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Horarios: ${widget.barbero?.nombrePerfil ?? "Cargando..."}',
        ),
      ),
      body: _guardando
          ? const Center(child: CircularProgressIndicator())
          : horariosState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (horarios) {
                // Inicializar estado local si es la primera carga
                _inicializarConHorariosExistentes(horarios);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: 7,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          // En la app ordenamos Lunes a Domingo para comodidad
                          // pero el index sigue mapeado a Lunes=1, ..., Domingo=0.
                          // Convertir: 0: Domingo, 1: Lunes, ..., 6: Sábado.
                          // Haremos orden de Lunes a Domingo.
                          final diaSemana = (index + 1) % 7;
                          final activo = _diasActivos[diaSemana]!;
                          final inicio = _horasInicio[diaSemana]!;
                          final fin = _horasFin[diaSemana]!;

                          final colorScheme = Theme.of(context).colorScheme;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: activo
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            color: activo
                                ? colorScheme.surfaceContainerHigh
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _diasNombres[diaSemana],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Switch(
                                        value: activo,
                                        onChanged: (val) {
                                          setState(() {
                                            _diasActivos[diaSemana] = val;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (activo) ...[
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () => _seleccionarHora(
                                              context,
                                              diaSemana,
                                              true,
                                            ),
                                            icon: const Icon(Icons.access_time),
                                            label: Text(
                                              'Apertura: ${inicio.format(context)}',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () => _seleccionarHora(
                                              context,
                                              diaSemana,
                                              false,
                                            ),
                                            icon: const Icon(Icons.access_time),
                                            label: Text(
                                              'Cierre: ${fin.format(context)}',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _guardar,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Guardar Configuración'),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
