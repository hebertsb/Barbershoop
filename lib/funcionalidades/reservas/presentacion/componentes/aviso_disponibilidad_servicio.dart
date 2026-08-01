import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administracion/dominio/modelo_servicio.dart';
import '../../../administracion/presentacion/controladores/controlador_barberos.dart';
import '../../../administracion/presentacion/controladores/controlador_horarios_barbero.dart';
import '../../../citas/dominio/disponibilidad_barbero.dart';
import '../../../citas/presentacion/controladores/controlador_citas.dart';
import '../../../turnos/presentacion/controladores/controlador_turnos.dart';

/// Aviso corto, debajo del selector de servicio en `FormularioTurno`, de qué
/// barberos de [sucursalId] tienen AHORA MISMO un hueco libre suficiente
/// para la duración del servicio [servicioSeleccionadoId].
///
/// Mira los mismos providers que ya usa `PantallaAgenda` para su panel de
/// disponibilidad (citas, turnos, barberos, horarios de la sucursal) — como
/// son providers `family` ya activos mientras la agenda está montada detrás
/// del bottom sheet, no dispara ninguna consulta nueva, solo reutiliza el
/// estado ya cargado. Puramente informativo: nunca bloquea el registro del
/// walk-in, que igual puede anotarse en la cola aunque nadie tenga hueco.
class AvisoDisponibilidadServicio extends ConsumerWidget {
  const AvisoDisponibilidadServicio({
    super.key,
    required this.sucursalId,
    required this.servicios,
    required this.servicioSeleccionadoId,
  });

  final String sucursalId;
  final List<ModeloServicio> servicios;
  final String? servicioSeleccionadoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicioId = servicioSeleccionadoId;
    if (servicioId == null) return const SizedBox.shrink();
    final candidatos = servicios.where((s) => s.id == servicioId);
    if (candidatos.isEmpty) return const SizedBox.shrink();
    final duracionMin = candidatos.first.duracionMin;

    final citasAsync = ref.watch(controladorCitasProvider(sucursalId));
    final turnosAsync = ref.watch(controladorTurnosProvider(sucursalId));
    final barberosAsync = ref.watch(controladorBarberosProvider);
    final horariosAsync = ref.watch(horariosDeSucursalProvider(sucursalId));

    // "Sin datos todavía" = primera carga en curso o error: no hay base real
    // para afirmar que nadie tiene hueco, así que esa conclusión negativa se
    // omite y se muestra un aviso neutro en su lugar.
    final datosIncompletos = [
      citasAsync,
      turnosAsync,
      barberosAsync,
      horariosAsync,
    ].any((async) => (async.isLoading && !async.hasValue) || async.hasError);

    final citas = citasAsync.value ?? [];
    final turnos = turnosAsync.value ?? [];
    final barberos = barberosAsync.value ?? [];
    final horarios = horariosAsync.value ?? [];

    final barberosDeLaSucursal = barberos
        .where((b) => b.sucursalId == sucursalId && b.activo)
        .toList();
    final disponibilidad = calcularDisponibilidadBarberos(
      barberos: barberosDeLaSucursal,
      citas: citas,
      turnos: turnos,
      servicios: servicios,
      horarios: horarios,
      ahora: DateTime.now(),
    );
    final barberosLibres = disponibilidad
        .where(
          (e) => e.huecosLibres.any(
            (h) => h.fin.difference(h.inicio).inMinutes >= duracionMin,
          ),
        )
        .map((e) => e.barbero)
        .toList();

    final colorScheme = Theme.of(context).colorScheme;

    if (barberosLibres.isEmpty && datosIncompletos) {
      return const SizedBox.shrink();
    }

    if (barberosLibres.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ningún barbero tiene hueco libre ahora para este servicio.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        Text(
          'Libre ahora:',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        for (final barbero in barberosLibres)
          Chip(
            label: Text(barbero.nombrePerfil ?? 'Sin nombre'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
