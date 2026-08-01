enum FiltroPeriodo {
  hoy,
  estaSemana,
  esteMes,
  esteAnio,
  personalizado;

  String get etiqueta {
    switch (this) {
      case FiltroPeriodo.hoy:
        return 'Hoy';
      case FiltroPeriodo.estaSemana:
        return 'Esta semana';
      case FiltroPeriodo.esteMes:
        return 'Este mes';
      case FiltroPeriodo.esteAnio:
        return 'Este año';
      case FiltroPeriodo.personalizado:
        return 'Personalizado';
    }
  }

  /// Calcula el rango (inicio, fin) correspondiente a este período, en hora
  /// local. Para `personalizado`, usa [fechaInicioCustom]/[fechaFinCustom]
  /// si vienen (si no, cae al día de hoy como valor por defecto).
  (DateTime, DateTime) obtenerRangoFechas({
    DateTime? fechaInicioCustom,
    DateTime? fechaFinCustom,
  }) {
    final ahora = DateTime.now();
    final hoyInicio = DateTime(ahora.year, ahora.month, ahora.day);
    final hoyFin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);

    switch (this) {
      case FiltroPeriodo.hoy:
        return (hoyInicio, hoyFin);
      case FiltroPeriodo.personalizado:
        return (fechaInicioCustom ?? hoyInicio, fechaFinCustom ?? hoyFin);
      case FiltroPeriodo.estaSemana:
        final inicioSemana = hoyInicio.subtract(
          Duration(days: ahora.weekday - 1),
        );
        return (inicioSemana, hoyFin);
      case FiltroPeriodo.esteMes:
        return (DateTime(ahora.year, ahora.month), hoyFin);
      case FiltroPeriodo.esteAnio:
        return (DateTime(ahora.year), hoyFin);
    }
  }
}
