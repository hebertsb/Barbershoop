import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/citas/dominio/item_agenda.dart';
import 'package:barber_app/funcionalidades/citas/dominio/modelo_cita.dart';
import 'package:barber_app/funcionalidades/citas/dominio/enum_estado_cita.dart';
import 'package:barber_app/funcionalidades/turnos/dominio/modelo_turno.dart';
import 'package:barber_app/funcionalidades/turnos/dominio/enum_estado_turno.dart';

ModeloCita _cita(
  String id,
  DateTime hora, {
  EstadoCita estado = EstadoCita.pendiente,
}) => ModeloCita(
  id: id,
  barberiaId: 'b1',
  sucursalId: 's1',
  barberoId: 'bar1',
  clienteId: 'cli1',
  servicioId: 'serv1',
  fechaHora: hora,
  duracionMin: 30,
  estado: estado,
);

ModeloTurno _turno(String id, DateTime hora) => ModeloTurno(
  id: id,
  barberiaId: 'b1',
  sucursalId: 's1',
  numero: 1,
  clienteWalkinId: 'walkin1',
  servicioId: 'serv1',
  estado: EstadoTurno.esperando,
  horaLlegada: hora,
);

void main() {
  test('combinarAgendaDelDia ordena citas y turnos por hora', () {
    final citas = [_cita('c1', DateTime(2026, 7, 17, 11))];
    final turnos = [
      _turno('t1', DateTime(2026, 7, 17, 9)),
      _turno('t2', DateTime(2026, 7, 17, 10)),
    ];

    final items = combinarAgendaDelDia(citas: citas, turnos: turnos);

    expect(items.length, 3);
    expect((items[0] as ItemAgendaTurno).turno.id, 't1');
    expect((items[1] as ItemAgendaTurno).turno.id, 't2');
    expect((items[2] as ItemAgendaCita).cita.id, 'c1');
  });

  test('combinarAgendaDelDia con listas vacias devuelve lista vacia', () {
    expect(combinarAgendaDelDia(citas: const [], turnos: const []), isEmpty);
  });

  test(
    'combinarAgendaDelDia con misma hora exacta ordena por id de forma deterministica',
    () {
      final mismaHora = DateTime(2026, 7, 17, 10);
      final citas = [_cita('c-z', mismaHora)];
      final turnos = [_turno('t-a', mismaHora)];

      final resultado1 = combinarAgendaDelDia(citas: citas, turnos: turnos);
      final resultado2 = combinarAgendaDelDia(citas: citas, turnos: turnos);

      expect(resultado1.length, 2);
      // Mismo orden en llamadas repetidas, y ordenado por id ('c-z' < 't-a').
      expect(resultado1[0], isA<ItemAgendaCita>());
      expect(resultado1[1], isA<ItemAgendaTurno>());
      expect(
        resultado1.map(
          (i) =>
              i is ItemAgendaCita ? i.cita.id : (i as ItemAgendaTurno).turno.id,
        ),
        resultado2.map(
          (i) =>
              i is ItemAgendaCita ? i.cita.id : (i as ItemAgendaTurno).turno.id,
        ),
      );
    },
  );

  test('combinarAgendaDelDia incluye pendiente/confirmada/completada y excluye '
      'cancelada/no_asistio', () {
    final citas = [
      _cita('c-pendiente', DateTime(2026, 7, 17, 9)),
      _cita(
        'c-confirmada',
        DateTime(2026, 7, 17, 10),
        estado: EstadoCita.confirmada,
      ),
      _cita(
        'c-completada',
        DateTime(2026, 7, 17, 11),
        estado: EstadoCita.completada,
      ),
      _cita(
        'c-no-asistio',
        DateTime(2026, 7, 17, 12),
        estado: EstadoCita.noAsistio,
      ),
      _cita(
        'c-cancelada',
        DateTime(2026, 7, 17, 13),
        estado: EstadoCita.cancelada,
      ),
    ];

    final items = combinarAgendaDelDia(citas: citas, turnos: const []);

    expect(items.length, 3);
    expect(items.map((i) => (i as ItemAgendaCita).cita.id), [
      'c-pendiente',
      'c-confirmada',
      'c-completada',
    ]);
  });
}
