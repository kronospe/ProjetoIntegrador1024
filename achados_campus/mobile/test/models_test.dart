import 'package:achados_campus/core/telefone.dart';
import 'package:achados_campus/models/item.dart';
import 'package:achados_campus/services/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _itemJson({Map<String, dynamic>? reivindicacao}) => {
      'id': 7,
      'nome': 'Mochila preta',
      'descricao': 'Com chaveiro azul',
      'local': 'biblioteca',
      'local_display': 'Biblioteca',
      'situacao_item': 'encontrado',
      'status_item': 'ativo',
      'icone': 'fa-backpack',
      'foto': null,
      'data_encontro': '2026-10-01',
      'cadastrado_por_id': 3,
      'cadastrado_por_nome': 'Maria Silva',
      'pode_editar': false,
      'pode_reivindicar': true,
      'pode_decidir': false,
      'reivindicacao': reivindicacao,
    };

DioException _erroHttp(int status, dynamic data) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: status, data: data),
  );
}

void main() {
  group('Item.fromJson', () {
    test('lê os campos básicos', () {
      final item = Item.fromJson(_itemJson());
      expect(item.id, 7);
      expect(item.localDisplay, 'Biblioteca');
      expect(item.situacao, 'encontrado');
      expect(item.dataEncontro, DateTime(2026, 10, 1));
      expect(item.foto, isNull);
      expect(item.reivindicacao, isNull);
      expect(item.podeReivindicar, isTrue);
    });

    test('reivindicação só com status (visão de terceiros)', () {
      final item = Item.fromJson(_itemJson(reivindicacao: {'status': 'pendente'}));
      expect(item.reivindicacao!.status, 'pendente');
      expect(item.reivindicacao!.detalhada, isFalse);
    });

    test('reivindicação completa com contato', () {
      final item = Item.fromJson(_itemJson(reivindicacao: {
        'status': 'aprovada',
        'descricao_prova': 'tem meu nome',
        'requerente_nome': 'Ana',
        'contato': '(81) 99999-9999',
      }));
      expect(item.reivindicacao!.detalhada, isTrue);
      expect(item.reivindicacao!.contato, '(81) 99999-9999');
    });
  });

  group('ApiException.from', () {
    test('sem resposta = erro de conexão', () {
      final e = ApiException.from(DioException(requestOptions: RequestOptions(path: '/x')));
      expect(e.message, contains('conectar'));
      expect(e.statusCode, isNull);
    });

    test('usa "detail" como mensagem geral', () {
      final e = ApiException.from(_erroHttp(401, {'detail': 'Usuário ou senha incorretos.'}));
      expect(e.message, 'Usuário ou senha incorretos.');
      expect(e.statusCode, 401);
    });

    test('separa erros por campo', () {
      final e = ApiException.from(_erroHttp(400, {
        'email': ['Este e-mail já está cadastrado.'],
        'senha': ['Muito curta.', 'Muito comum.'],
      }));
      expect(e.fieldErrors['email'], 'Este e-mail já está cadastrado.');
      expect(e.fieldErrors['senha'], 'Muito curta. Muito comum.');
    });
  });

  group('telefone', () {
    test('formatarTelefone', () {
      expect(formatarTelefone('81999998888'), '(81) 99999-8888');
      expect(formatarTelefone('8133334444'), '(81) 3333-4444');
      expect(formatarTelefone('819'), '(81) 9');
      expect(formatarTelefone('819999988889999'), '(81) 99999-8888');
    });

    test('whatsappUrl', () {
      expect(whatsappUrl('(81) 99999-8888'), 'https://wa.me/5581999998888');
      expect(whatsappUrl('5581999998888'), 'https://wa.me/5581999998888');
      expect(whatsappUrl('123'), isNull);
      expect(whatsappUrl(null), isNull);
    });

    test('TelefoneFormatter permite apagar símbolos da máscara', () {
      final f = TelefoneFormatter();
      const antigo = TextEditingValue(text: '(81) ');
      const novo = TextEditingValue(text: '(81)'); // apagou o espaço
      expect(f.formatEditUpdate(antigo, novo).text, '(8');
    });
  });
}
