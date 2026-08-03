abstract class ExcepcionApp implements Exception {
  const ExcepcionApp([this.mensaje]);
  final String? mensaje;

  @override
  String toString() => mensaje ?? 'Ha ocurrido un error inesperado';
}

class ExcepcionAutenticacion extends ExcepcionApp {
  const ExcepcionAutenticacion([super.mensaje]);
}

class ExcepcionRed extends ExcepcionApp {
  const ExcepcionRed([super.mensaje = 'Error de conexión a internet']);
}

class ExcepcionPermiso extends ExcepcionApp {
  const ExcepcionPermiso([super.mensaje = 'No tienes permiso para realizar esta acción']);
}

class ExcepcionDatosNoEncontrados extends ExcepcionApp {
  const ExcepcionDatosNoEncontrados([super.mensaje = 'Datos no encontrados']);
}

class ExcepcionDesconocida extends ExcepcionApp {
  const ExcepcionDesconocida([super.mensaje = 'Ocurrió un error inesperado']);
}
