/// Parsea un String de fecha/hora proveniente de Supabase garantizando UTC.
///
/// Supabase devuelve timestamps PostgreSQL en formato ISO 8601 como:
///   - "2026-08-04T09:00:00"        (sin sufijo → DateTime.parse lo toma como local)
///   - "2026-08-04T09:00:00Z"       (con Z → correcto UTC)
///   - "2026-08-04T09:00:00+00:00"  (con offset → correcto UTC)
///
/// Cuando la cadena carece de zona horaria, [DateTime.parse] la interpreta
/// como hora local del dispositivo, lo que provoca que [toLocal()] en la UI
/// aplique la conversión dos veces (doble resta de offset).
/// Esta función garantiza que el resultado siempre sea UTC, de modo que
/// [toLocal()] convierta exactamente una vez en la capa de presentación.
///
/// Retorna [fallback] si [raw] es nulo o no parseable.
DateTime parsearFechaUtc(String? raw, {DateTime? fallback}) {
  if (raw == null || raw.isEmpty) return fallback ?? DateTime.now();
  final dt = DateTime.tryParse(raw);
  if (dt == null) return fallback ?? DateTime.now();
  // Si ya tiene info de zona (isUtc = true para 'Z' o '+00:00'), ok.
  if (dt.isUtc) return dt;
  // Si no, asumir UTC: los datos de Supabase/PostgreSQL siempre están en UTC.
  return DateTime.utc(
    dt.year,
    dt.month,
    dt.day,
    dt.hour,
    dt.minute,
    dt.second,
    dt.millisecond,
  );
}
