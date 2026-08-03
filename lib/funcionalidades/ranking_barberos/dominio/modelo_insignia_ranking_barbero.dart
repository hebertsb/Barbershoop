import 'enum_tipo_premio_ranking.dart';

class ModeloInsigniaRankingBarbero {
  const ModeloInsigniaRankingBarbero({
    required this.id,
    required this.barberiaId,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.tipoPremio,
    required this.valorPremio,
    this.barberoId = '',
    this.puesto = 1,
    this.activo = true,
    this.tituloProgramaCache,
    this.fechaOtorgada,
  });

  final String id;
  final String barberiaId;
  final String nombre;
  final String descripcion;
  final String icono;
  final TipoPremioRanking tipoPremio;
  final double valorPremio;
  final String barberoId;
  final int puesto;
  final bool activo;
  final String? tituloProgramaCache;
  final DateTime? fechaOtorgada;

  /// Título del programa de ranking donde se obtuvo la insignia.
  String get tituloPrograma => tituloProgramaCache ?? nombre;

  /// Fecha en la que fue otorgada la insignia.
  DateTime get otorgadaEn => fechaOtorgada ?? DateTime.now();

  factory ModeloInsigniaRankingBarbero.desdeJson(Map<String, dynamic> json) {
    String? titulo;
    final programaData = json['programas_ranking_barberos'];
    if (programaData is Map<String, dynamic>) {
      titulo = (programaData['titulo'] ?? programaData['nombre']) as String?;
    }

    return ModeloInsigniaRankingBarbero(
      id: json['id'] as String? ?? '',
      barberiaId: json['barberia_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Insignia',
      descripcion: json['descripcion'] as String? ?? '',
      icono: json['icono'] as String? ?? 'emoji_events',
      tipoPremio: TipoPremioRanking.desdeTexto(json['tipo_premio'] as String? ?? ''),
      valorPremio: (json['valor_premio'] as num? ?? 0).toDouble(),
      barberoId: json['barbero_id'] as String? ?? '',
      puesto: json['puesto'] as int? ?? 1,
      activo: json['activo'] as bool? ?? true,
      tituloProgramaCache: titulo ?? json['titulo_programa'] as String?,
      fechaOtorgada: json['otorgada_en'] == null ? null : DateTime.parse(json['otorgada_en'] as String),
    );
  }
}
