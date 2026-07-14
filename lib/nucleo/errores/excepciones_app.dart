sealed class ExcepcionApp implements Exception {
  const ExcepcionApp(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

class ExcepcionRed extends ExcepcionApp {
  const ExcepcionRed([super.mensaje = 'Error de conexión. Verifica tu internet.']);
}

class ExcepcionPermiso extends ExcepcionApp {
  const ExcepcionPermiso([super.mensaje = 'No tienes permiso para realizar esta acción.']);
}

class ExcepcionDatosNoEncontrados extends ExcepcionApp {
  const ExcepcionDatosNoEncontrados([super.mensaje = 'No se encontraron los datos solicitados.']);
}

class ExcepcionDesconocida extends ExcepcionApp {
  const ExcepcionDesconocida([super.mensaje = 'No se pudo completar la acción. Intenta de nuevo.']);
}
