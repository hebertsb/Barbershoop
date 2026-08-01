/// Rango [inicio, fin) que cubre todo el día LOCAL de [local], expresado en
/// instantes UTC -- para comparar contra columnas `timestamptz` de Postgres
/// sin desfasar por zona horaria.
({DateTime inicio, DateTime fin}) rangoDeHoyEnUtc(DateTime local) {
  final inicioLocal = DateTime(local.year, local.month, local.day);
  final finLocal = inicioLocal.add(const Duration(days: 1));
  return (inicio: inicioLocal.toUtc(), fin: finLocal.toUtc());
}
