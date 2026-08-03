import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_inventario.dart';

final controladorAlertaStockProvider = FutureProvider<int>((ref) {
  return ref.read(repositorioInventarioProvider).contarInsumosBajoMinimo();
});