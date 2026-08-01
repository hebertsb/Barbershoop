import 'enum_estado_reporte_insumo.dart';
import 'enum_tipo_reporte_insumo.dart';

class ModeloReporteInsumo {
  const ModeloReporteInsumo({
    required this.id,
    required this.barberoId,
    required this.insumoId,
    required this.tipo,
    required this.cantidad,
    this.descripcion,
    this.urlFoto,
    required this.estado,
    required this.creadoEn,
    required this.nombreBarbero,
    required this.nombreInsumo,
  });

  final String id;
  final String barberoId;
  final String insumoId;
  final TipoReporteInsumo tipo;
  final int cantidad;
  final String? descripcion;
  final String? urlFoto;
  final EstadoReporteInsumo estado;
  final DateTime creadoEn;
  final String nombreBarbero;
  final String nombreInsumo;

  factory ModeloReporteInsumo.desdeJson(Map<String, dynamic> json) {
    final barberoMap = json['barberos'] as Map<String, dynamic>?;
    final perfilMap = barberoMap?['perfiles'] as Map<String, dynamic>?;
    final insumoMap = json['insumos'] as Map<String, dynamic>?;

    return ModeloReporteInsumo(
      id: json['id'] as String,
      barberoId: json['barbero_id'] as String,
      insumoId: json['insumo_id'] as String,
      tipo: TipoReporteInsumo.desdeTexto(json['tipo'] as String),
      cantidad: json['cantidad'] as int,
      descripcion: json['descripcion'] as String?,
      urlFoto: json['url_foto'] as String?,
      estado: EstadoReporteInsumo.desdeTexto(json['estado'] as String),
      creadoEn: DateTime.parse(json['creado_en'] as String),
      nombreBarbero:
          (perfilMap?['nombre'] ?? json['nombre_barbero'] ?? 'Barbero')
              as String,
      nombreInsumo:
          (insumoMap?['nombre'] ?? json['nombre_insumo'] ?? 'Insumo') as String,
    );
  }
}
