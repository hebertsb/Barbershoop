/// Disponibilidad del barbero en un momento dado -- usada por
/// `EtiquetaEstado`/`TarjetaAgendaItem` para mostrar si está libre, en
/// atención o de descanso.
enum DisponibilidadBarbero {
  libre,
  enAtencion,
  descanso;

  static DisponibilidadBarbero desdeTexto(String texto) {
    switch (texto) {
      case 'libre':
        return DisponibilidadBarbero.libre;
      case 'en_atencion':
        return DisponibilidadBarbero.enAtencion;
      case 'descanso':
        return DisponibilidadBarbero.descanso;
      default:
        return DisponibilidadBarbero.libre;
    }
  }
}
