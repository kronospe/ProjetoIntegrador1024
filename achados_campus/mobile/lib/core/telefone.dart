import 'package:flutter/services.dart';

/// Só os dígitos de um texto.
String soDigitos(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Aplica a máscara brasileira: (81) 99999-9999 ou (81) 3333-4444.
String formatarTelefone(String texto) {
  var d = soDigitos(texto);
  if (d.length > 11) d = d.substring(0, 11);
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 0) b.write('(');
    if (i == 2) b.write(') ');
    if (d.length <= 10 ? i == 6 : i == 7) b.write('-');
    b.write(d[i]);
  }
  return b.toString();
}

/// Link wa.me para um telefone brasileiro (com ou sem máscara).
/// Retorna null se o número for curto demais.
String? whatsappUrl(String? telefone) {
  var d = soDigitos(telefone ?? '');
  if (d.length < 10) return null;
  if (!d.startsWith('55')) d = '55$d';
  return 'https://wa.me/$d';
}

/// Máscara de telefone para campos de texto.
class TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var digitos = soDigitos(novo.text);
    // apagou só um símbolo da máscara (parêntese, espaço ou hífen): remove o último dígito
    if (novo.text.length < antigo.text.length && digitos == soDigitos(antigo.text)) {
      digitos = digitos.isEmpty ? '' : digitos.substring(0, digitos.length - 1);
    }
    final texto = formatarTelefone(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
