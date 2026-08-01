import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constantes {
  Constantes._();

  static String get urlSupabase =>
      dotenv.maybeGet('SUPABASE_URL') ?? '';
  static String get claveAnonSupabase =>
      dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';
  static String get googleWebClientId =>
      dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID') ?? '';

  /// Bucket público de Supabase Storage para fotos de perfil, logos y QR
  /// bancario.
  static const String bucketImagenesApp = 'imagenes-app';
}
