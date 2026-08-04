/// Determina si una sucursal está abierta en este momento según su horario
/// de apertura y cierre almacenado en formato "HH:mm" (ej. "09:00", "21:30").
///
/// Retorna [true] si el horario no está definido (sin restricción configurada)
/// o si la hora actual se encuentra dentro del rango apertura-cierre.
bool estaSucursalAbiertaAhora(
  String? horarioApertura,
  String? horarioCierre,
) {
  // Si no hay horario configurado, se considera siempre abierta.
  if (horarioApertura == null || horarioCierre == null) return true;
  if (horarioApertura.trim().isEmpty || horarioCierre.trim().isEmpty) {
    return true;
  }

  final ahora = DateTime.now();

  final apertura = _parsearHora(horarioApertura, ahora);
  final cierre = _parsearHora(horarioCierre, ahora);
  if (apertura == null || cierre == null) return true;

  // Manejo de cierre al día siguiente (ej. apertura 20:00, cierre 02:00)
  if (cierre.isBefore(apertura)) {
    // El negocio cruza la medianoche
    return ahora.isAfter(apertura) || ahora.isBefore(cierre);
  }

  return ahora.isAfter(apertura) && ahora.isBefore(cierre);
}

DateTime? _parsearHora(String horaStr, DateTime referencia) {
  final partes = horaStr.trim().split(':');
  if (partes.length < 2) return null;
  final horas = int.tryParse(partes[0]);
  final minutos = int.tryParse(partes[1]);
  if (horas == null || minutos == null) return null;
  return DateTime(
    referencia.year,
    referencia.month,
    referencia.day,
    horas,
    minutos,
  );
}
