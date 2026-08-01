/// Deja solo dígitos (quita "+", espacios, guiones, paréntesis). Devuelve
/// `null` si el resultado tiene menos de 8 dígitos (número inválido) --
/// mismo umbral con el que se valida en `PantallaMiPerfilBarbero`.
String? normalizarTelefonoWhatsapp(String telefono) {
  final soloDigitos = telefono.replaceAll(RegExp(r'[^0-9]'), '');
  if (soloDigitos.length < 8) return null;
  return soloDigitos;
}

/// Arma el link `wa.me` con [telefonoNormalizado] (ya sin "+", ver
/// [normalizarTelefonoWhatsapp]) y un [mensaje] opcional codificado. Un
/// mensaje vacío o solo espacios se trata igual que "sin mensaje".
String construirUrlWhatsapp(String telefonoNormalizado, {String? mensaje}) {
  final base = 'https://wa.me/$telefonoNormalizado';
  final mensajeLimpio = mensaje?.trim();
  if (mensajeLimpio == null || mensajeLimpio.isEmpty) return base;
  return '$base?text=${Uri.encodeComponent(mensajeLimpio)}';
}
