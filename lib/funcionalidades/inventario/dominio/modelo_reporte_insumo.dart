import 'enum_estado_reporte_insumo.dart';
import 'enum_tipo_reporte_insumo.dart';

class ModeloReporteInsumo {
  const ModeloReporteInsumo({
    required this.id,
    required this.insumoId,
    required this.barberoId,
    required this.cantidad,
    required this.motivo,
    required this.estado,
    required this.fecha,
    this.tipoReporteCache,
    this.nombreInsumoCache,
    this.nombreBarberoCache,
    this.descripcionCache,
    this.urlFotoCache,
  });

  final String id;
  final String insumoId;
  final String barberoId;
  final double cantidad;
  final String motivo;
  final EstadoReporteInsumo estado;
  final DateTime fecha;
  final TipoReporteInsumo? tipoReporteCache;
  final String? nombreInsumoCache;
  final String? nombreBarberoCache;
  final String? descripcionCache;
  final String? urlFotoCache;

  /// Tipo de reporte.
  TipoReporteInsumo get tipo => tipoReporteCache ?? TipoReporteInsumo.perdido;
  TipoReporteInsumo get tipoReporte => tipo;

  /// Nombre del insumo reportado.
  String get nombreInsumo => nombreInsumoCache ?? 'Insumo';

  /// Nombre del barbero que hizo el reporte.
  String get nombreBarbero => nombreBarberoCache ?? 'Barbero';

  /// Descripción / observaciones del reporte.
  String? get descripcion => descripcionCache ?? (motivo.isNotEmpty ? motivo : null);

  /// Foto adjunta del daño/reporte.
  String? get urlFoto => urlFotoCache;

  factory ModeloReporteInsumo.desdeJson(Map<String, dynamic> json) {
    String? barberoNombre;
    if (json['barberos'] is Map) {
      final barbMap = json['barberos'] as Map<String, dynamic>;
      final perfilMap = barbMap['perfiles'];
      if (perfilMap is Map) {
        barberoNombre = perfilMap['nombre'] as String?;
      }
    }

    String? insumoNombre;
    if (json['insumos'] is Map) {
      final insMap = json['insumos'] as Map<String, dynamic>;
      insumoNombre = insMap['nombre'] as String?;
    }

    final fechaStr = json['creado_en'] ?? json['fecha'] ?? json['creado_el'];
    final fechaParsed = fechaStr != null
        ? DateTime.tryParse(fechaStr.toString()) ?? DateTime.now()
        : DateTime.now();

    return ModeloReporteInsumo(
      id: json['id'] as String? ?? '',
      insumoId: json['insumo_id'] as String? ?? '',
      barberoId: json['barbero_id'] as String? ?? '',
      cantidad: (json['cantidad'] as num? ?? 0).toDouble(),
      motivo: json['descripcion'] as String? ?? json['motivo'] as String? ?? '',
      estado: EstadoReporteInsumo.desdeTexto(json['estado'] as String? ?? ''),
      fecha: fechaParsed,
      tipoReporteCache: json['tipo'] != null
          ? TipoReporteInsumo.desdeTexto(json['tipo'] as String)
          : null,
      nombreInsumoCache: insumoNombre ?? (json['nombre_insumo'] ?? json['insumo_nombre']) as String?,
      nombreBarberoCache: barberoNombre ?? (json['nombre_barbero'] ?? json['barbero_nombre']) as String?,
      descripcionCache: json['descripcion'] as String?,
      urlFotoCache: (json['url_foto'] ?? json['foto_url']) as String?,
    );
  }
}
