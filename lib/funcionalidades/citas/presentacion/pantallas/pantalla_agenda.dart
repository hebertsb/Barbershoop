import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/layout_responsivo.dart';
import '../../../administracion/presentacion/controladores/controlador_barberos.dart';
import '../../../administracion/presentacion/controladores/controlador_horarios_barbero.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../../administracion/presentacion/controladores/controlador_sucursales.dart';
import '../../../autenticacion/dominio/enum_rol_usuario.dart';
import '../../../autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../../turnos/presentacion/componentes/formulario_turno.dart';
import '../../../turnos/presentacion/controladores/controlador_turnos.dart';
import '../../dominio/disponibilidad_barbero.dart';
import '../../dominio/item_agenda.dart';
import '../componentes/panel_disponibilidad_barberos.dart';
import '../componentes/tarjeta_agenda_item.dart';
import '../controladores/controlador_citas.dart';
import '../utilidades/completar_turno_con_cobro.dart';

class PantallaAgenda extends ConsumerStatefulWidget {
  const PantallaAgenda({super.key});

  @override
  ConsumerState<PantallaAgenda> createState() => _PantallaAgendaState();
}

class _PantallaAgendaState extends ConsumerState<PantallaAgenda> {
  String? _sucursalSeleccionadaId;
  String? _sucursalIdVisible;
  String? _itemSeleccionadoId;
  Timer? _timerRefresco;

  @override
  void initState() {
    super.initState();
    _timerRefresco = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final sucursalId = _sucursalIdVisible;
      if (sucursalId == null) return;
      ref.invalidate(controladorCitasProvider(sucursalId));
      ref.invalidate(controladorTurnosProvider(sucursalId));
      ref.invalidate(horariosDeSucursalProvider(sucursalId));
    });
  }

  @override
  void dispose() {
    _timerRefresco?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(controladorAutenticacionProvider).value;
    final sucursalesState = ref.watch(controladorSucursalesProvider);
    final esSecretaria = perfil?.rol == RolUsuario.secretaria;

    final sucursalesActivas = (sucursalesState.value ?? [])
        .where((s) => s.activo)
        .toList();
    if (_sucursalSeleccionadaId != null &&
        !sucursalesActivas.any((s) => s.id == _sucursalSeleccionadaId)) {
      _sucursalSeleccionadaId = null;
    }
    final primeraActivaId = sucursalesActivas.isEmpty
        ? null
        : sucursalesActivas.first.id;
    final sucursalId = esSecretaria
        ? perfil?.sucursalId
        : (_sucursalSeleccionadaId ?? primeraActivaId);

    if (sucursalId == null) {
      if (sucursalesState.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const Scaffold(
        body: Center(child: Text('No hay una sucursal disponible.')),
      );
    }
    _sucursalIdVisible = sucursalId;

    ref.listen(controladorTurnosProvider(sucursalId), (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });
    ref.listen(controladorCitasProvider(sucursalId), (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });

    final citasState = ref.watch(controladorCitasProvider(sucursalId));
    final turnosState = ref.watch(controladorTurnosProvider(sucursalId));
    final serviciosState = ref.watch(controladorServiciosProvider);
    final barberosState = ref.watch(controladorBarberosProvider);
    final horariosState = ref.watch(horariosDeSucursalProvider(sucursalId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          if (!esSecretaria && sucursalesActivas.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sucursalId,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    style: TipografiaApp.labelMd.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    items: sucursalesActivas
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.store_outlined,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(s.nombre),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _sucursalSeleccionadaId = val),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: citasState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (citas) => turnosState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (turnos) {
            final items = combinarAgendaDelDia(citas: citas, turnos: turnos);
            Future<void> refrescar() async {
              ref.invalidate(controladorCitasProvider(sucursalId));
              ref.invalidate(controladorTurnosProvider(sucursalId));
              ref.invalidate(horariosDeSucursalProvider(sucursalId));
            }

            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: refrescar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 64,
                      ),
                      child: Center(
                        child: Text(
                          'No hay citas ni turnos para hoy.',
                          style: TipografiaApp.bodyMd.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            final barberosDeLaSucursal = (barberosState.value ?? [])
                .where((b) => b.sucursalId == sucursalId && b.activo)
                .toList();
            final disponibilidadBarberos = calcularDisponibilidadBarberos(
              barberos: barberosDeLaSucursal,
              citas: citas,
              turnos: turnos,
              servicios: serviciosState.value ?? [],
              horarios: horariosState.value ?? [],
              ahora: DateTime.now(),
            );

            Widget construirTarjeta(ItemAgenda item) {
              return TarjetaAgendaItem(
                item: item,
                disponibilidadBarberos: disponibilidadBarberos,
                alLlamar: (turnoId, barberoId) {
                  ref
                      .read(controladorTurnosProvider(sucursalId).notifier)
                      .llamarTurno(turnoId: turnoId, barberoId: barberoId)
                      .catchError((_) {});
                },
                alCompletar: (turnoId) => completarTurnoConCobro(
                  context: context,
                  ref: ref,
                  sucursalId: sucursalId,
                  turnoId: turnoId,
                  turnos: turnos,
                  servicios: serviciosState.value ?? [],
                  citas: citas,
                ),
                alCancelar: (turnoId) {
                  ref
                      .read(controladorTurnosProvider(sucursalId).notifier)
                      .cancelarTurno(turnoId)
                      .catchError((_) {});
                },
                alConfirmarLlegada: (citaId) {
                  ref
                      .read(controladorTurnosProvider(sucursalId).notifier)
                      .confirmarLlegadaCita(citaId)
                      .then(
                        (_) => ref.invalidate(
                          controladorCitasProvider(sucursalId),
                        ),
                      )
                      .catchError((_) {});
                },
                alMarcarNoAsistio: (citaId) {
                  ref
                      .read(controladorCitasProvider(sucursalId).notifier)
                      .marcarNoAsistio(citaId)
                      .catchError((_) {});
                },
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                if (esPantallaAncha(constraints.maxWidth)) {
                  final seleccionados = items
                      .where(
                        (i) => idDeItemAgenda(i) == _itemSeleccionadoId,
                      )
                      .toList();
                  final panelDetalle = seleccionados.isEmpty
                      ? Text(
                          'Eleg una cita de la lista para ver el detalle.',
                          style: TipografiaApp.bodyMd.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : construirTarjeta(seleccionados.first);

                  return Row(
                    children: [
                      SizedBox(
                        width: 380,
                        child: Column(
                          children: [
                            PanelDisponibilidadBarberos(
                              disponibilidad: disponibilidadBarberos,
                            ),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: refrescar,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    final seleccionado =
                                        idDeItemAgenda(item) ==
                                        _itemSeleccionadoId;
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => setState(
                                        () => _itemSeleccionadoId =
                                            idDeItemAgenda(item),
                                      ),
                                      child: Container(
                                        decoration: seleccionado
                                            ? BoxDecoration(
                                                border: Border.all(
                                                  color: colorScheme.primary,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              )
                                            : null,
                                        child: construirTarjeta(item),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 480,
                              ),
                              child: panelDetalle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    PanelDisponibilidadBarberos(
                      disponibilidad: disponibilidadBarberos,
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: refrescar,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, index) =>
                              construirTarjeta(items[index]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final servicios = (serviciosState.value ?? [])
              .where((s) => s.activo)
              .toList();
          if (servicios.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Debes registrar al menos un servicio primero.'),
              ),
            );
            return;
          }
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) =>
                FormularioTurno(sucursalId: sucursalId, servicios: servicios),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}