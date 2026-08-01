import '../../turnos/dominio/modelo_turno.dart';
import 'enum_estado_cita.dart';
import 'modelo_cita.dart';

/// Un ítem de la agenda del día: o una cita reservada, o un turno walk-in.
sealed class ItemAgenda {
  const ItemAgenda();

  DateTime get hora;
}

class ItemAgendaCita extends ItemAgenda {
  const ItemAgendaCita(this.cita);

  final ModeloCita cita;

  @override
  DateTime get hora => cita.fechaHora;
}

class ItemAgendaTurno extends ItemAgenda {
  const ItemAgendaTurno(this.turno);

  final ModeloTurno turno;

  @override
  DateTime get hora => turno.horaLlegada;
}

String idDeItemAgenda(ItemAgenda item) => switch (item) {
  ItemAgendaCita(:final cita) => cita.id,
  ItemAgendaTurno(:final turno) => turno.id,
};

/// Combina citas y turnos del día en una sola lista ordenada por hora --
/// solo citas `pendiente`/`confirmada`/`completada` (excluye
/// `cancelada`/`no_asistio`, que no ocupan un lugar real en la agenda del
/// día). Empate exacto de hora se desempata por id (determinístico entre
/// llamadas).
List<ItemAgenda> combinarAgendaDelDia({
  required List<ModeloCita> citas,
  required List<ModeloTurno> turnos,
}) {
  final citasVisibles = citas.where(
    (c) =>
        c.estado == EstadoCita.pendiente ||
        c.estado == EstadoCita.confirmada ||
        c.estado == EstadoCita.completada,
  );

  final items = <ItemAgenda>[
    ...citasVisibles.map(ItemAgendaCita.new),
    ...turnos.map(ItemAgendaTurno.new),
  ];

  items.sort((a, b) {
    final comparacionHora = a.hora.compareTo(b.hora);
    if (comparacionHora != 0) return comparacionHora;
    return idDeItemAgenda(a).compareTo(idDeItemAgenda(b));
  });

  return items;
}
