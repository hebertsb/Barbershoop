import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../datos/repositorio_reservas.dart';
import '../../dominio/calculo_precio_combo.dart';
import '../../dominio/modelo_horario_disponible.dart';
import '../../dominio/modelo_slot_grilla.dart';
import '../componentes/cuerpo_grilla_horario.dart';
import '../componentes/cuerpo_solo_libres_horario.dart';
import '../controladores/controlador_reserva.dart';

class PantallaSeleccionHorario extends ConsumerStatefulWidget {
  const PantallaSeleccionHorario({super.key});

  @override
  ConsumerState<PantallaSeleccionHorario> createState() =>
      _PantallaSeleccionHorarioState();
}

class _PantallaSeleccionHorarioState
    extends ConsumerState<PantallaSeleccionHorario> {
  late DateTime _fechaSeleccionada;
  Future<List<ModeloHorarioDisponible>>? _horariosFuture;
  Future<List<ModeloSlotGrilla>>? _grillaFuture;

  static const List<String> _diasSemana = [
    'DOM',
    'LUN',
    'MAR',
    'MIÉ',
    'JUE',
    'VIE',
    'SÁB',
  ];

  static const List<String> _meses = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
  ];

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _fechaSeleccionada = DateTime(hoy.year, hoy.month, hoy.day);
    _consultarHorarios();
  }

  void _consultarHorarios() {
    final estado = ref.read(controladorReservaProvider);
    if (estado.sucursalId == null || estado.servicioId == null) return;

    final repo = ref.read(repositorioReservasProvider);

    if (!estado.cualquieraSeleccionado && estado.barberoId != null) {
      setState(() {
        _horariosFuture = null;
        _grillaFuture = repo.obtenerGrillaHorarios(
          sucursalId: estado.sucursalId!,
          servicioId: estado.servicioId!,
          fecha: _fechaSeleccionada,
          barberoId: estado.barberoId!,
          promocionId: estado.promocion?.id,
        );
      });
    } else {
      setState(() {
        _grillaFuture = null;
        _horariosFuture = repo.obtenerHorariosDisponibles(
          sucursalId: estado.sucursalId!,
          servicioId: estado.servicioId!,
          fecha: _fechaSeleccionada,
          barberoId: null,
          promocionId: estado.promocion?.id,
        );
      });
    }
  }

  Future<void> _abrirCalendario() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(
        hoy.year,
        hoy.month,
        hoy.day,
      ).add(const Duration(days: 60)),
    );
    if (elegida == null) return;
    setState(
      () => _fechaSeleccionada = DateTime(
        elegida.year,
        elegida.month,
        elegida.day,
      ),
    );
    _consultarHorarios();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final estado = ref.watch(controladorReservaProvider);
    final servicios = ref.watch(controladorServiciosProvider).value ?? [];
    final servicioActual = servicios
        .where((s) => s.id == estado.servicioId)
        .toList();
    final promocion = estado.promocion;
    final esCombo = promocion != null && promocion.esCombo;
    // Para un combo, el bloque real a reservar es la suma de TODOS los
    // servicios del combo (mismo criterio que reservar_cita, 0040), no solo
    // la duración de estado.servicioId (el servicio "ancla" del combo) --
    // evita mostrarle al cliente un mensaje de duración engañoso (0047).
    final duracionMin = esCombo
        ? duracionTotalCombo(promocion.serviciosIds ?? [], servicios)
        : (servicioActual.isEmpty ? null : servicioActual.first.duracionMin);

    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona el Horario')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selecciona un día',
                  style: TipografiaApp.labelSm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _abrirCalendario,
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Elegir una fecha del calendario',
                ),
              ],
            ),
          ),
          // Tira Horizontal de 7 Días
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 7,
              itemBuilder: (context, index) {
                final hoy = DateTime.now();
                final dia = DateTime(
                  hoy.year,
                  hoy.month,
                  hoy.day,
                ).add(Duration(days: index));
                final seleccionado =
                    dia.year == _fechaSeleccionada.year &&
                    dia.month == _fechaSeleccionada.month &&
                    dia.day == _fechaSeleccionada.day;

                final nombreDia = _diasSemana[dia.weekday % 7];
                final nombreMes = _meses[dia.month - 1];

                return GestureDetector(
                  onTap: () {
                    setState(() => _fechaSeleccionada = dia);
                    _consultarHorarios();
                  },
                  child: Container(
                    width: 68,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: seleccionado
                          ? ColoresApp.primario
                          : colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: seleccionado
                            ? ColoresApp.primario
                            : colorScheme.outlineVariant,
                      ),
                      boxShadow: seleccionado
                          ? [
                              BoxShadow(
                                color: ColoresApp.primario.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          nombreDia,
                          style: TipografiaApp.labelSm.copyWith(
                            color: seleccionado
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dia.day}',
                          style: TipografiaApp.headlineSm.copyWith(
                            color: seleccionado
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          nombreMes,
                          style: TipografiaApp.labelSm.copyWith(
                            color: seleccionado
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: _grillaFuture != null
                ? CuerpoGrillaHorario(future: _grillaFuture!)
                : CuerpoSoloLibresHorario(future: _horariosFuture),
          ),
          if (duracionMin != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Este horario reservará un bloque de $duracionMin '
                        'minutos. Por favor, llegue 10 minutos antes de su '
                        'cita.',
                        style: TipografiaApp.bodySm.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}