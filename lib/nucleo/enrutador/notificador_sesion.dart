import 'package:flutter/foundation.dart';

/// ChangeNotifier plano usado como `refreshListenable` de go_router.
/// Se dispara manualmente desde donde haga falta re-evaluar el redirect:
/// eventos de auth de Supabase y cambios en el estado del controlador.
class NotificadorSesion extends ChangeNotifier {
  void notificar() => notifyListeners();
  void notificarCambio() => notifyListeners();
}
