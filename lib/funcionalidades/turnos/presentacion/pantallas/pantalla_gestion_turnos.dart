import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../administracion/presentacion/controladores/controlador_barberos.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../../autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../dominio/enum_estado_turno.dart';
import '../../dominio/modelo_turno.dart';
import '../componentes/dialogo_nuevo_turno.dart';
import '../controladores/controlador_turnos.dart';

/// Pantalla de gestión de turnos presenciales (walk-in) para el rol
/// barbero/secretaria. Muestra la cola del día, permite crear nuevos turnos
/// (con cliente registrado o walk-in), llamar al siguiente y completar con cobro.
class PantallaGestionTurnos extends ConsumerWidget {
  const PantallaGestionTurnos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(controladorAutenticacionProvider).value;
    final barberosState = ref.watch(controladorBarberosProvider);

    // Resuelve la sucursal del barbero autenticado
    final barberos = barberosState.value ?? [];
    final miBarbero =
        barberos.where((b) => b.perfilId == perfil?.id).firstOrNull;
    final sucursalId = miBarbero?.sucursalId;

    if (sucursalId == null) {
      if (barberosState.isLoading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return const Scaffold(
        body: Center(
          child: Text('No tenés una sucursal asignada.'),
        ),
      );
    }

    final turnosState = ref.watch(controladorTurnosProvider(sucursalId));
    final servicios = ref.watch(controladorServiciosProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Turnos de Caja'),
            Text(
              formatoFechaCorta(DateTime.now()),
              style: TipografiaApp.bodySm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () =>
                ref.invalidate(controladorTurnosProvider(sucursalId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoNuevoTurno(
          context: context,
          sucursalId: sucursalId,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo turno'),
      ),
      body: turnosState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(error.toString()),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(controladorTurnosProvider(sucursalId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (turnos) {
          if (turnos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.queue_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin turnos para hoy',
                    style: TipografiaApp.bodyLg.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tocá + para agregar un turno de mostrador',
                    style: TipografiaApp.bodySm.copyWith(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(controladorTurnosProvider(sucursalId)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: turnos.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final turno = turnos[i];
                final servicio = servicios
                    .where((s) => s.id == turno.servicioId)
                    .firstOrNull;
                return _TarjetaTurno(
                  turno: turno,
                  nombreServicio: servicio?.nombre ?? '—',
                  barberoId: miBarbero?.id,
                  sucursalId: sucursalId,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarDialogoNuevoTurno({
    required BuildContext context,
    required String sucursalId,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DialogoNuevoTurno(sucursalId: sucursalId),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta individual de turno
// ---------------------------------------------------------------------------

class _TarjetaTurno extends ConsumerWidget {
  const _TarjetaTurno({
    required this.turno,
    required this.nombreServicio,
    required this.barberoId,
    required this.sucursalId,
  });

  final ModeloTurno turno;
  final String nombreServicio;
  final String? barberoId;
  final String sucursalId;

  Color _colorEstado(BuildContext context, EstadoTurno estado) {
    return switch (estado) {
      EstadoTurno.esperando => ColoresApp.estadoPendiente,
      EstadoTurno.enAtencion => ColoresApp.estadoConfirmada,
      EstadoTurno.completado => ColoresApp.estadoCompletada,
      EstadoTurno.cancelado => ColoresApp.estadoCancelada,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final estado = turno.estado;
    final colorEstado = _colorEstado(context, estado);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorEstado.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: número de turno + estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorEstado.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorEstado.withAlpha(100)),
                  ),
                  child: Text(
                    'N° ${turno.numero}',
                    style: TipografiaApp.labelSm.copyWith(
                      color: colorEstado,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _EtiquetaEstado(estado: estado),
                const Spacer(),
                Text(
                  formatoHora(turno.horaLlegada),
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Identificador del cliente
            Text(
              turno.clienteWalkinId != null
                  ? 'Cliente walk-in'
                  : turno.clienteId != null
                      ? 'Cliente registrado'
                      : 'Sin identificar',
              style:
                  TipografiaApp.bodyLg.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              nombreServicio,
              style: TipografiaApp.bodySm.copyWith(
                color: colorScheme.primary,
              ),
            ),
            // Botones de acción según estado
            if (_mostrarBotones(estado)) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (estado == EstadoTurno.esperando && barberoId != null)
                    FilledButton.icon(
                      onPressed: () => _llamar(context, ref),
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                      ),
                      label: const Text('Llamar'),
                    ),
                  if (estado == EstadoTurno.enAtencion)
                    FilledButton.icon(
                      onPressed: () => _completar(context, ref),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Completar'),
                    ),
                  const Spacer(),
                  if (estado == EstadoTurno.esperando ||
                      estado == EstadoTurno.enAtencion)
                    TextButton.icon(
                      onPressed: () => _cancelar(context, ref),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancelar'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _mostrarBotones(EstadoTurno estado) =>
      estado == EstadoTurno.esperando || estado == EstadoTurno.enAtencion;

  Future<void> _llamar(BuildContext context, WidgetRef ref) async {
    if (barberoId == null) return;
    try {
      await ref
          .read(controladorTurnosProvider(sucursalId).notifier)
          .llamarTurno(turnoId: turno.id, barberoId: barberoId!);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _completar(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(controladorTurnosProvider(sucursalId).notifier)
          .completarTurno(turnoId: turno.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _cancelar(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cancelar turno?'),
        content: Text('¿Cancelás el turno N° ${turno.numero}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref
          .read(controladorTurnosProvider(sucursalId).notifier)
          .cancelarTurno(turno.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class _EtiquetaEstado extends StatelessWidget {
  const _EtiquetaEstado({required this.estado});
  final EstadoTurno estado;

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (estado) {
      EstadoTurno.esperando => ('Esperando', ColoresApp.estadoPendiente),
      EstadoTurno.enAtencion => ('En atención', ColoresApp.estadoConfirmada),
      EstadoTurno.completado => ('Completado', ColoresApp.estadoCompletada),
      EstadoTurno.cancelado => ('Cancelado', ColoresApp.estadoCancelada),
    };
    return Text(
      texto,
      style: TipografiaApp.labelSm.copyWith(color: color),
    );
  }
}
