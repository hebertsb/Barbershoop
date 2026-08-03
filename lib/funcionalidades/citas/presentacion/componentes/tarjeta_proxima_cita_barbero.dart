import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../administracion/dominio/modelo_servicio.dart';
import '../../dominio/enum_estado_cita.dart';
import '../../dominio/modelo_cita.dart';

/// Busca, entre las citas del día del barbero autenticado, la próxima que
/// todavía no ocurrió (fecha_hora en el futuro) y no está cancelada ni
/// marcada como no-asistió. Devuelve `null` si no hay ninguna -- la tarjeta
/// simplemente no se muestra.
ModeloCita? obtenerProximaCita(List<ModeloCita>? citas, String? miBarberoId) {
  if (citas == null || miBarberoId == null) return null;
  final ahora = DateTime.now();
  final candidatas = citas.where((c) {
    return c.barberoId == miBarberoId &&
        c.estado != EstadoCita.cancelada &&
        c.estado != EstadoCita.noAsistio &&
        c.fechaHora.isAfter(ahora);
  }).toList()..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
  return candidatas.isEmpty ? null : candidatas.first;
}

/// Nombre a mostrar para el servicio de la cita: el combo de la promoción
/// aplicada si existe, si no el nombre del servicio base.
String nombreServicioDeCita(ModeloCita cita, List<ModeloServicio> servicios) {
  if (cita.nombresServiciosCombo.isNotEmpty) {
    return cita.nombresServiciosCombo.join(' + ');
  }
  final candidatos = servicios.where((s) => s.id == cita.servicioId).toList();
  return candidatos.isEmpty ? 'Servicio' : candidatos.first.nombre;
}

class TarjetaProximaCitaBarbero extends StatelessWidget {
  const TarjetaProximaCitaBarbero({
    super.key,
    required this.cita,
    required this.nombreServicio,
    required this.colorScheme,
  });

  final ModeloCita cita;
  final String nombreServicio;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final nombreCliente = cita.nombreCliente ?? 'Cliente';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          child: Icon(
            Icons.event_available_outlined,
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          nombreServicio,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TipografiaApp.bodyMd.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$nombreCliente · ${formatoHora(cita.fechaHora.toLocal())}',
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
        onTap: () => context.go('/mi-agenda'),
      ),
    );
  }
}