import 'package:url_launcher/url_launcher.dart';

/// Normaliza un número de teléfono a formato internacional para WhatsApp.
/// Retorna el número con prefijo '+591' si es boliviano, o null si inválido.
String? normalizarTelefonoWhatsapp(String telefono) {
  // Limpia todo lo que no sea dígito o '+'
  final limpio = telefono.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (limpio.isEmpty) return null;

  // Ya tiene prefijo internacional
  if (limpio.startsWith('+')) {
    final soloDigitos = limpio.substring(1).replaceAll(RegExp(r'\D'), '');
    if (soloDigitos.length < 8) return null;
    return '+$soloDigitos';
  }

  // Sin prefijo: asume Bolivia (+591), 8 dígitos
  final soloDigitos = limpio.replaceAll(RegExp(r'\D'), '');
  if (soloDigitos.length == 8) {
    return '+591$soloDigitos';
  }
  if (soloDigitos.length > 8) {
    return '+$soloDigitos';
  }
  return null;
}

/// Abre WhatsApp con el número dado y un mensaje opcional.
Future<void> abrirWhatsapp(String telefono, {String mensaje = ''}) async {
  final numLimpio = telefono.replaceAll(RegExp(r'\D'), '');
  final uri = Uri.parse(
    'https://wa.me/$numLimpio${mensaje.isNotEmpty ? '?text=${Uri.encodeComponent(mensaje)}' : ''}',
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('No se pudo abrir WhatsApp');
  }
}