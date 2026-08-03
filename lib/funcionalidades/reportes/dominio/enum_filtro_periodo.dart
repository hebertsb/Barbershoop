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

  (DateTime inicio, DateTime fin) obtenerRangoFechas({
    DateTime? fechaInicioCustom,
    DateTime? fechaFinCustom,
  }) {
    final ahora = DateTime.now();
    switch (this) {
      case FiltroPeriodo.hoy:
        final inicio = DateTime(ahora.year, ahora.month, ahora.day, 0, 0, 0);
        final fin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        return (inicio, fin);
      case FiltroPeriodo.estaSemana:
        final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
        final inicio = DateTime(
          inicioSemana.year,
          inicioSemana.month,
          inicioSemana.day,
          0,
          0,
          0,
        );
        final fin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        return (inicio, fin);
      case FiltroPeriodo.esteMes:
        final inicio = DateTime(ahora.year, ahora.month, 1, 0, 0, 0);
        final fin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        return (inicio, fin);
      case FiltroPeriodo.esteAnio:
        final inicio = DateTime(ahora.year, 1, 1, 0, 0, 0);
        final fin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        return (inicio, fin);
      case FiltroPeriodo.personalizado:
        final inicio =
            fechaInicioCustom ?? DateTime(ahora.year, ahora.month, 1);
        final fin =
            fechaFinCustom ??
            DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        return (inicio, fin);
    }
  }
}