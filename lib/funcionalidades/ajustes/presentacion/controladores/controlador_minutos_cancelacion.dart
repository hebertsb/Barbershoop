import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/repositorio_ajustes.dart';

/// Minutos mnimos de anticipacin para cancelar/reprogramar una cita,
/// mismo valor que ya exige `cancelar_cita_cliente` (0031) del lado
/// servidor -- se lee ac solo para ocultar el botn "Reprogramar" en el
/// cliente con el umbral real configurado, sin UI de admin nueva.
final controladorMinutosCancelacionProvider = FutureProvider<int>((ref) {
  return ref
      .read(repositorioAjustesProvider)
      .obtenerMinutosMinimosCancelacion();
});
