import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_estado_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../turnos/dominio/enum_estado_turno.dart';
import '../../dominio/disponibilidad_barbero.dart';
import '../../dominio/enum_estado_cita.dart';

Color colorParaEstadoCita(EstadoCita estado, ColoresEstadoApp colores) {
  switch (estado) {
    case EstadoCita.pendiente:
      return colores.pendiente;
    case EstadoCita.confirmada:
      return colores.confirmada;
    case EstadoCita.completada:
      return colores.completada;
    case EstadoCita.cancelada:
    case EstadoCita.noAsistio:
      return colores.cancelada;
  }
}

Color colorParaEstadoTurno(EstadoTurno estado, ColoresEstadoApp colores) {
  switch (estado) {
    case EstadoTurno.esperando:
      return colores.pendiente;
    case EstadoTurno.enAtencion:
      return colores.confirmada;
    case EstadoTurno.completado:
      return colores.completada;
    case EstadoTurno.cancelado:
      return colores.cancelada;
  }
}

String textoEstadoCita(EstadoCita estado) {
  switch (estado) {
    case EstadoCita.pendiente:
      return 'Pendiente';
    case EstadoCita.confirmada:
      return 'Confirmada';
    case EstadoCita.completada:
      return 'Completada';
    case EstadoCita.cancelada:
      return 'Cancelada';
    case EstadoCita.noAsistio:
      return 'No asistió';
  }
}

String textoEstadoTurno(EstadoTurno estado) {
  switch (estado) {
    case EstadoTurno.esperando:
      return 'Esperando';
    case EstadoTurno.enAtencion:
      return 'En atención';
    case EstadoTurno.completado:
      return 'Completado';
    case EstadoTurno.cancelado:
      return 'Cancelado';
  }
}

String textoDisponibilidadBarbero(EstadoDisponibilidadBarbero estado) {
  if (!estado.ocupado) return 'Libre';
  if (estado.libreDesde == null) return 'Ocupado';
  final hora = estado.libreDesde!.toLocal();
  final horaTexto =
      '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  return 'Ocupado hasta $horaTexto';
}

Color colorDisponibilidadBarbero(
  EstadoDisponibilidadBarbero estado,
  ColoresEstadoApp colores,
) {
  return estado.ocupado ? colores.pendiente : colores.completada;
}

class EtiquetaEstado extends StatelessWidget {
  const EtiquetaEstado({super.key, required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(texto, style: TipografiaApp.labelSm.copyWith(color: color)),
    );
  }
}
