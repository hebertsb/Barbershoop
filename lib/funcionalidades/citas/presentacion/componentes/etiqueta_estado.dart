import 'package:flutter/material.dart';
import '../../dominio/enum_estado_cita.dart';
import '../../../turnos/dominio/enum_estado_turno.dart';

String textoEstadoCita(EstadoCita estado) {
  switch (estado) {
    case EstadoCita.pendiente:
      return 'Pendiente';
    case EstadoCita.confirmada:
      return 'Confirmada';
    case EstadoCita.enProceso:
      return 'En Proceso';
    case EstadoCita.completada:
      return 'Completada';
    case EstadoCita.cancelada:
      return 'Cancelada';
    case EstadoCita.noAsistio:
      return 'No asistió';
  }
}

Color colorParaEstadoCita(EstadoCita estado, [dynamic colores]) {
  switch (estado) {
    case EstadoCita.pendiente:
      return Colors.orange;
    case EstadoCita.confirmada:
      return Colors.blue;
    case EstadoCita.enProceso:
      return Colors.purple;
    case EstadoCita.completada:
      return Colors.green;
    case EstadoCita.cancelada:
      return Colors.red;
    case EstadoCita.noAsistio:
      return Colors.grey;
  }
}

String textoEstadoTurno(EstadoTurno estado) {
  switch (estado) {
    case EstadoTurno.pendiente:
    case EstadoTurno.esperando:
      return 'Esperando';
    case EstadoTurno.enProceso:
    case EstadoTurno.enAtencion:
      return 'En atención';
    case EstadoTurno.completado:
      return 'Completado';
    case EstadoTurno.cancelado:
      return 'Cancelado';
  }
}

Color colorParaEstadoTurno(EstadoTurno estado, [dynamic colores]) {
  switch (estado) {
    case EstadoTurno.pendiente:
    case EstadoTurno.esperando:
      return Colors.orange;
    case EstadoTurno.enProceso:
    case EstadoTurno.enAtencion:
      return Colors.blue;
    case EstadoTurno.completado:
      return Colors.green;
    case EstadoTurno.cancelado:
      return Colors.red;
  }
}


/// Widget de etiqueta de estado de cita.
/// Acepta dos modos:
/// 1. Con [estado] (obligatorio para citas): calcula texto y color automáticamente.
/// 2. Sin [estado]: usa [texto] y [color] directamente (para mensajes libres).
class EtiquetaEstadoCita extends StatelessWidget {
  const EtiquetaEstadoCita({
    super.key,
    this.estado,
    this.texto,
    this.color,
  }) : assert(
          estado != null || texto != null,
          'Se requiere estado o texto',
        );

  final EstadoCita? estado;
  final String? texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final strTexto =
        texto ?? (estado != null ? textoEstadoCita(estado!) : '');
    final colorFinal =
        color ?? (estado != null ? colorParaEstadoCita(estado!) : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorFinal.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        strTexto,
        style: TextStyle(
          color: colorFinal,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Alias de [EtiquetaEstadoCita] para uso genérico sin pasar estado.
typedef EtiquetaEstado = EtiquetaEstadoCita;

class EtiquetaEstadoTurno extends StatelessWidget {
  const EtiquetaEstadoTurno({super.key, required this.estado});
  final EstadoTurno estado;

  @override
  Widget build(BuildContext context) {
    String txt = textoEstadoTurno(estado);
    Color color = Colors.orange;
    switch (estado) {
      case EstadoTurno.pendiente:
      case EstadoTurno.esperando:
        txt = 'Esperando';
        color = Colors.orange;
      case EstadoTurno.enProceso:
      case EstadoTurno.enAtencion:
        txt = 'En atención';
        color = Colors.blue;
      case EstadoTurno.completado:
        txt = 'Completado';
        color = Colors.green;
      case EstadoTurno.cancelado:
        txt = 'Cancelado';
        color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        txt,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
