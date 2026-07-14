import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constantes {
  Constantes._();

  static String get urlSupabase => dotenv.get('SUPABASE_URL');
  static String get claveAnonSupabase => dotenv.get('SUPABASE_ANON_KEY');
}
