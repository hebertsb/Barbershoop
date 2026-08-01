import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/nucleo/utilidades/contacto_whatsapp.dart';

void main() {
  group('normalizarTelefonoWhatsapp', () {
    test('con + y espacios se limpia a solo dígitos', () {
      expect(normalizarTelefonoWhatsapp('+591 712 34567'), '59171234567');
    });

    test('sin + también funciona si ya viene completo', () {
      expect(normalizarTelefonoWhatsapp('59171234567'), '59171234567');
    });

    test('con guiones y paréntesis se limpia', () {
      expect(normalizarTelefonoWhatsapp('(591) 71-234-567'), '59171234567');
    });

    test('número inválido por muy corto devuelve null', () {
      expect(normalizarTelefonoWhatsapp('1234'), null);
    });

    test('vacío devuelve null', () {
      expect(normalizarTelefonoWhatsapp(''), null);
    });
  });

  group('construirUrlWhatsapp', () {
    test('sin mensaje abre el chat vacío', () {
      expect(construirUrlWhatsapp('59171234567'), 'https://wa.me/59171234567');
    });

    test('con mensaje simple lo agrega codificado', () {
      expect(
        construirUrlWhatsapp('59171234567', mensaje: 'Voy en camino'),
        'https://wa.me/59171234567?text=Voy%20en%20camino',
      );
    });

    test('con mensaje que tiene símbolos lo codifica bien', () {
      expect(
        construirUrlWhatsapp('59171234567', mensaje: 'Llego ~10 min tarde'),
        'https://wa.me/59171234567?text=Llego%20~10%20min%20tarde',
      );
    });

    test('mensaje vacío o solo espacios se trata como sin mensaje', () {
      expect(
        construirUrlWhatsapp('59171234567', mensaje: '   '),
        'https://wa.me/59171234567',
      );
    });
  });
}
