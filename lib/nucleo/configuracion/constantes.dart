import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constantes {
  Constantes._();

  static String get urlSupabase => dotenv.get('SUPABASE_URL');
  static String get claveAnonSupabase => dotenv.get('SUPABASE_ANON_KEY');
  static String get googleWebClientId => dotenv.get('GOOGLE_WEB_CLIENT_ID');

  /// Bucket público de Supabase Storage para fotos de sucursales, servicios,
  /// y (a futuro) promociones/banners.
  static const bucketImagenesApp = 'imagenes-app';
}