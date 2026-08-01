/// Una medalla ganada por un barbero al quedar en el top 3 de un programa
/// de ranking ya cerrado. `tituloPrograma` viene de un embed de Supabase.
class ModeloInsigniaRankingBarbero {
  const ModeloInsigniaRankingBarbero({
    required this.id,
    required this.programaId,
    required this.barberoId,
    required this.puesto,
    required this.otorgadaEn,
    required this.tituloPrograma,
  });

  final String id;
  final String programaId;
  final String barberoId;

  /// 1 = oro, 2 = plata, 3 = bronce.
  final int puesto;
  final DateTime otorgadaEn;
  final String tituloPrograma;

  factory ModeloInsigniaRankingBarbero.desdeJson(Map<String, dynamic> json) {
    final programaJson =
        json['programas_ranking_barberos'] as Map<String, dynamic>?;
    return ModeloInsigniaRankingBarbero(
      id: json['id'] as String,
      programaId: json['programa_id'] as String,
      barberoId: json['barbero_id'] as String,
      puesto: json['puesto'] as int,
      otorgadaEn: DateTime.parse(json['otorgada_en'] as String),
      tituloPrograma: (programaJson?['titulo'] as String?) ?? '',
    );
  }
}
