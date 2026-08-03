import '../../administracion/dominio/modelo_barbero.dart';
import '../../administracion/dominio/modelo_horario_barbero.dart';
import '../../administracion/dominio/modelo_servicio.dart';
import '../../turnos/dominio/enum_estado_turno.dart';
import '../../turnos/dominio/modelo_turno.dart';
import 'enum_estado_cita.dart';
import 'modelo_cita.dart';

class HuecoLibre {
  const HuecoLibre({required this.inicio, required this.fin});

  final DateTime inicio;
  final DateTime fin;
}

/// Disponibilidad de un barbero en un momento dado -- usada por la agenda
/// (`TarjetaAgendaItem`) para saber a quin se le puede asignar un turno
/// que llega, y por `AvisoDisponibilidadServicio` para saber quin tiene
/// hueco libre AHORA para un servicio puntual.
class EstadoDisponibilidadBarbero {
  const EstadoDisponibilidadBarbero({
    required this.barbero,
    required this.ocupado,
    this.libreDesde,
    this.huecosLibres = const [],
  });

  final ModeloBarbero barbero;
  final bool ocupado;

  /// Hora estimada en que termina su cita/turno actual -- `null` si est
  /// ocupado pero no se pudo calcular una estimacin.
  final DateTime? libreDesde;

  /// Huecos libres dentro de su horario de trabajo de hoy, ya descontando
  /// las citas/turnos activos.
  final List<HuecoLibre> huecosLibres;
}

/// Calcula, para cada barbero de [barberos], sus huecos libres HOY dentro
/// de su horario de trabajo (de [horarios]), descontando sus citas
/// (`pendiente`/`confirmada`) y turnos (`esperando`/`enAtencion`) activos.
/// Puramente informativo -- una estimacin con la duracin de [servicios]
/// conocida al momento de reservar, no una fuente de verdad transaccional
/// (eso lo valida `reservar_cita` del lado servidor).
List<EstadoDisponibilidadBarbero> calcularDisponibilidadBarberos({
  required List<ModeloBarbero> barberos,
  required List<ModeloCita> citas,
  required List<ModeloTurno> turnos,
  required List<ModeloServicio> servicios,
  required List<ModeloHorarioBarbero> horarios,
  required DateTime ahora,
}) {
  int duracionDe(String servicioId) {
    final candidatos = servicios.where((s) => s.id == servicioId).toList();
    return candidatos.isEmpty ? 30 : candidatos.first.duracionMin;
  }

  DateTime horaDeHoy(String horaTexto) {
    final partes = horaTexto.split(':');
    return DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
      int.parse(partes[0]),
      int.parse(partes[1]),
    );
  }

  return barberos.map((barbero) {
    final horarioHoy = horarios.where(
      (h) => h.barberoId == barbero.id && h.diaSemana == ahora.weekday % 7,
    );
    if (horarioHoy.isEmpty) {
      return EstadoDisponibilidadBarbero(barbero: barbero, ocupado: true);
    }

    // Bloques ocupados de hoy: citas activas + turnos activos del barbero.
    final bloques = <(DateTime, DateTime)>[
      for (final c in citas)
        if (c.barberoId == barbero.id &&
            (c.estado == EstadoCita.pendiente ||
                c.estado == EstadoCita.confirmada))
          (c.fechaHora, c.fechaHora.add(Duration(minutes: c.duracionMin))),
      for (final t in turnos)
        if (t.barberoId == barbero.id &&
            (t.estado == EstadoTurno.esperando ||
                t.estado == EstadoTurno.enAtencion) &&
            (t.horaLlegada != null || t.creadoEn != null))
          (
            t.horaLlegada ?? t.creadoEn!,
            (t.horaLlegada ?? t.creadoEn!).add(Duration(minutes: duracionDe(t.servicioId ?? ''))),
          ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final ocupadoAhora = bloques.any(
      (b) => !ahora.isBefore(b.$1) && ahora.isBefore(b.$2),
    );

    // Huecos libres dentro del horario de trabajo, restando los bloques.
    final huecos = <HuecoLibre>[];
    for (final h in horarioHoy) {
      var cursor = horaDeHoy(h.horaInicio);
      final finJornada = horaDeHoy(h.horaFin);
      for (final bloque in bloques) {
        if (bloque.$2.isBefore(cursor) || !bloque.$1.isBefore(finJornada)) {
          continue;
        }
        if (bloque.$1.isAfter(cursor)) {
          huecos.add(HuecoLibre(inicio: cursor, fin: bloque.$1));
        }
        if (bloque.$2.isAfter(cursor)) cursor = bloque.$2;
      }
      if (cursor.isBefore(finJornada)) {
        huecos.add(HuecoLibre(inicio: cursor, fin: finJornada));
      }
    }

    // Solo huecos que todava no terminaron.
    final huecosFuturos = huecos
        .where((h) => h.fin.isAfter(ahora))
        .map(
          (h) => HuecoLibre(
            inicio: h.inicio.isBefore(ahora) ? ahora : h.inicio,
            fin: h.fin,
          ),
        )
        .toList();

    DateTime? libreDesde;
    if (ocupadoAhora) {
      final bloqueActual = bloques.firstWhere(
        (b) => !ahora.isBefore(b.$1) && ahora.isBefore(b.$2),
      );
      libreDesde = bloqueActual.$2;
    }

    return EstadoDisponibilidadBarbero(
      barbero: barbero,
      ocupado: ocupadoAhora,
      libreDesde: libreDesde,
      huecosLibres: huecosFuturos,
    );
  }).toList();
}
