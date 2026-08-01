/// Una fila del ranking calculado por el RPC `obtener_ranking_barberos`:
/// el puesto general del barbero más el puesto individual que sacó en cada
/// uno de los 5 factores (para el desglose expandible del podio).
class ModeloResultadoRankingBarbero {
  const ModeloResultadoRankingBarbero({
    required this.barberoId,
    required this.nombre,
    required this.puesto,
    required this.puntaje,
    required this.citasCompletadas,
    required this.puestoCitas,
    required this.ingresosGenerados,
    required this.puestoIngresos,
    required this.clientesDistintos,
    required this.puestoClientes,
    required this.tasaNoShow,
    required this.puestoPuntualidad,
    required this.calificacionPromedio,
    required this.puestoCalificacion,
  });

  final String barberoId;
  final String nombre;
  final int puesto;
  final double puntaje;
  final int citasCompletadas;
  final int puestoCitas;
  final double ingresosGenerados;
  final int puestoIngresos;
  final int clientesDistintos;
  final int puestoClientes;
  final double tasaNoShow;
  final int puestoPuntualidad;
  final double calificacionPromedio;
  final int puestoCalificacion;

  factory ModeloResultadoRankingBarbero.desdeJson(Map<String, dynamic> json) {
    return ModeloResultadoRankingBarbero(
      barberoId: json['barbero_id'] as String,
      nombre: json['nombre'] as String,
      puesto: json['puesto'] as int,
      puntaje: (json['puntaje'] as num).toDouble(),
      citasCompletadas: json['citas_completadas'] as int,
      puestoCitas: json['puesto_citas'] as int,
      ingresosGenerados: (json['ingresos_generados'] as num).toDouble(),
      puestoIngresos: json['puesto_ingresos'] as int,
      clientesDistintos: json['clientes_distintos'] as int,
      puestoClientes: json['puesto_clientes'] as int,
      tasaNoShow: (json['tasa_no_show'] as num).toDouble(),
      puestoPuntualidad: json['puesto_puntualidad'] as int,
      calificacionPromedio: (json['calificacion_promedio'] as num).toDouble(),
      puestoCalificacion: json['puesto_calificacion'] as int,
    );
  }
}
