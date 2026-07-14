import 'package:supabase_flutter/supabase_flutter.dart';

import 'constantes.dart';

class ClienteSupabase {
  ClienteSupabase._();

  static Future<void> inicializar() async {
    await Supabase.initialize(
      url: Constantes.urlSupabase,
      publishableKey: Constantes.claveAnonSupabase,
    );
  }

  static SupabaseClient get instancia => Supabase.instance.client;
}
