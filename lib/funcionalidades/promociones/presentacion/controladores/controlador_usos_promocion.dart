import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_promociones.dart';
import '../../dominio/modelo_uso_promocion.dart';

/// Cuntas veces cada cliente us una promocin especfica. Solo admin
/// (`obtener_usos_promocion_por_cliente`, 0043).
final controladorUsosPromocionProvider =
    FutureProvider.family<List<ModeloUsoPromocion>, String>((ref, promocionId) {
      return ref
          .read(repositorioPromocionesProvider)
          .obtenerUsosPromocionPorCliente(promocionId);
    });
