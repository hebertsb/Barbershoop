import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_promociones.dart';
import '../../dominio/modelo_promocion.dart';

final controladorPromocionesClienteProvider =
    FutureProvider<List<ModeloPromocion>>((ref) async {
      final repo = ref.read(repositorioPromocionesProvider);
      final promociones = await repo.obtenerPromocionesActivas();
      return promociones.where((p) => p.estaVigente).toList();
    });
