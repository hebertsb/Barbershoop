import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constantes {
  Constantes._();

  static String get urlSupabase => dotenv.get('SUPABASE_URL');
  static String get claveAnonSupabase => dotenv.get('SUPABASE_ANON_KEY');
  static String get googleWebClientId => dotenv.get('GOOGLE_WEB_CLIENT_ID');

  /// Bucket público de Supabase Storage para fotos de perfil, logos y QR
  /// bancario. NOTA post-recuperación: nombre reconstruido de memoria, sin
  /// un archivo recuperado que lo confirme -- verificar contra el bucket
  /// real en Supabase Storage y corregir si difiere.
  static const String bucketImagenesApp = 'imagenes-app';
}
