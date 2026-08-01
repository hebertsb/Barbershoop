import '../../administracion/dominio/modelo_barbero.dart';

/// Disponibilidad de un barbero en un momento dado -- usada por la agenda
/// (`TarjetaAgendaItem`) para saber a quién se le puede asignar un turno
/// que llega, y si está ocupado, hasta cuándo.
class EstadoDisponibilidadBarbero {
  const EstadoDisponibilidadBarbero({
    required this.barbero,
    required this.ocupado,
    this.libreDesde,
  });

  final ModeloBarbero barbero;
  final bool ocupado;

  /// Hora estimada en que termina su cita/turno actual -- `null` si está
  /// ocupado pero no se pudo calcular una estimación.
  final DateTime? libreDesde;
}
