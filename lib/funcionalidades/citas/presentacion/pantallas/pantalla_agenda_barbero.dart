import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../administracion/presentacion/controladores/controlador_barberos.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../../autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../../turnos/presentacion/controladores/controlador_turnos.dart';
import '../../dominio/item_agenda.dart';
import '../componentes/tarjeta_agenda_barbero.dart';
import '../controladores/controlador_citas.dart';
import '../utilidades/completar_turno_con_cobro.dart';

/// Agenda propia del rol barbero: mezcla sus citas pendientes con sus turnos
/// (check-in) del día, en un timeline hora + punto de color + tarjeta.
/// `citas_select` (RLS) ya limita `obtenerCitasDelDia` a las citas del
/// barbero autenticado; los turnos se filtran client-side por `barberoId`
/// porque `turnos_select` no está acotado por barbero.
class PantallaAgendaBarbero extends ConsumerStatefulWidget {
  const PantallaAgendaBarbero({super.key});

  @override
  ConsumerState<PantallaAgendaBarbero> createState() =>
      _PantallaAgendaBarberoState();
}

class _PantallaAgendaBarberoState extends ConsumerState<PantallaAgendaBarbero> {
  String? _sucursalIdVisible;
  Timer? _timerRefresco;

  @override
  void initState() {
    super.initState();
    _timerRefresco = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      final sucursalId = _sucursalIdVisible;
      if (sucursalId == null) return;
      ref.invalidate(controladorCitasProvider(sucursalId));
      ref.invalidate(controladorTurnosProvider(sucursalId));
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

    // La sucursal se resuelve desde la propia fila del barbero en
    // `barberos` (llenada al invitarlo), no desde `perfiles.sucursal_id`
    // -- esa columna nunca se llena para el rol barbero, solo aplica a
    // secretaria. Un barbero con más de una fila (multi-sucursal) usa la
    // primera, mismo criterio que ya se usaba para `miBarberoId`.
    final barberosState = ref.watch(controladorBarberosProvider);
    final barberosCoincidentes = (barberosState.value ?? [])
        .where((b) => b.perfilId == perfil?.id)
        .toList();
    final miBarbero = barberosCoincidentes.isEmpty
        ? null
        : barberosCoincidentes.first;
    final miBarberoId = miBarbero?.id;
    final sucursalId = miBarbero?.sucursalId;

    if (sucursalId == null) {
      if (barberosState.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const Scaffold(
        body: Center(child: Text('No tenés una sucursal asignada.')),
      );
    }
    _sucursalIdVisible = sucursalId;

    ref.listen(controladorCitasProvider(sucursalId), (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });
    ref.listen(controladorTurnosProvider(sucursalId), (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });

    final citasState = ref.watch(controladorCitasProvider(sucursalId));
    final turnosState = ref.watch(controladorTurnosProvider(sucursalId));
    final serviciosState = ref.watch(controladorServiciosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda del Día')),
      body: citasState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (citas) => turnosState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (turnos) {
            final misTurnos = turnos
                .where((t) => miBarberoId != null && t.barberoId == miBarberoId)
                .toList();
            final items = combinarAgendaDelDia(citas: citas, turnos: misTurnos);
            final servicios = serviciosState.value ?? [];

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(controladorCitasProvider(sucursalId));
                ref.invalidate(controladorTurnosProvider(sucursalId));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    formatoFechaCorta(DateTime.now()),
                    style: TipografiaApp.bodySm.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: Text('No tenés citas para hoy.')),
                    )
                  else
                    for (final item in items)
                      TarjetaAgendaBarbero(
                        item: item,
                        servicios: servicios,
                        alCompletar: (turnoId) => completarTurnoConCobro(
                          context: context,
                          ref: ref,
                          sucursalId: sucursalId,
                          turnoId: turnoId,
                          turnos: misTurnos,
                          servicios: servicios,
                          citas: citas,
                        ),
                        alConfirmarLlegada: (citaId) async {
                          try {
                            final turno = await ref
                                .read(
                                  controladorTurnosProvider(
                                    sucursalId,
                                  ).notifier,
                                )
                                .confirmarLlegadaCita(citaId);
                            ref.invalidate(
                              controladorCitasProvider(sucursalId),
                            );
                            if (!context.mounted) return;
                            await completarTurnoConCobro(
                              context: context,
                              ref: ref,
                              sucursalId: sucursalId,
                              turnoId: turno.id,
                              turnos: [turno],
                              servicios: servicios,
                              citas: citas,
                            );
                          } catch (_) {}
                        },
                        alMarcarNoAsistio: (citaId) {
                          ref
                              .read(
                                controladorCitasProvider(sucursalId).notifier,
                              )
                              .marcarNoAsistio(citaId)
                              .catchError((_) {});
                        },
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
