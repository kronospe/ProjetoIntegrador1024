import io

from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from PIL import Image
from rest_framework.test import APITestCase

from .chatbot import NAO_ENTENDI, encontrar_resposta
from .models import Aluno, Item, Reivindicacao

import tempfile
MEDIA_TMP = tempfile.mkdtemp()


def foto_fake(nome='f.png'):
    buf = io.BytesIO()
    Image.new('RGB', (10, 10), 'red').save(buf, 'PNG')
    return SimpleUploadedFile(nome, buf.getvalue(), content_type='image/png')


def novo_usuario(email, senha='senha12345', nome='Maria Silva'):
    p, *r = nome.split()
    return User.objects.create_user(username=email, email=email, password=senha,
                                    first_name=p, last_name=' '.join(r))


def item_payload(**kw):
    base = {
        'nome': 'Mochila preta', 'descricao': 'Com um chaveiro azul',
        'local': 'biblioteca', 'situacao_item': 'encontrado',
        'icone': 'fa-backpack', 'data_encontro': '2026-10-01',
    }
    base.update(kw)
    return base


@override_settings(MEDIA_ROOT=MEDIA_TMP)
class AuthTests(APITestCase):
    def test_cadastro_e_login(self):
        r = self.client.post('/api/auth/cadastro/', {
            'nome': 'Ana Souza', 'email': 'ANA@x.com',
            'senha': 'senha12345', 'confirmar_senha': 'senha12345'}, format='json')
        self.assertEqual(r.status_code, 201, r.data)
        self.assertIn('access', r.data)
        self.assertEqual(r.data['usuario']['email'], 'ana@x.com')
        self.assertFalse(r.data['usuario']['perfil_completo'])

        r = self.client.post('/api/auth/login/',
                             {'email': 'ana@x.com', 'senha': 'senha12345'}, format='json')
        self.assertEqual(r.status_code, 200)
        self.assertIn('refresh', r.data)

    def test_cadastro_validacoes(self):
        novo_usuario('dup@x.com')
        r = self.client.post('/api/auth/cadastro/', {
            'nome': 'X', 'email': 'dup@x.com',
            'senha': 'curta', 'confirmar_senha': 'outra'}, format='json')
        self.assertEqual(r.status_code, 400)
        self.assertIn('email', r.data)
        self.assertIn('senha', r.data)

    def test_login_invalido(self):
        novo_usuario('a@x.com')
        r = self.client.post('/api/auth/login/',
                             {'email': 'a@x.com', 'senha': 'errada'}, format='json')
        self.assertEqual(r.status_code, 401)

    def test_refresh(self):
        novo_usuario('a@x.com')
        r = self.client.post('/api/auth/login/',
                             {'email': 'a@x.com', 'senha': 'senha12345'}, format='json')
        r2 = self.client.post('/api/auth/refresh/', {'refresh': r.data['refresh']}, format='json')
        self.assertEqual(r2.status_code, 200)
        self.assertIn('access', r2.data)

    def test_perfil_requer_auth_e_atualiza(self):
        self.assertEqual(self.client.get('/api/perfil/').status_code, 401)
        u = novo_usuario('a@x.com')
        self.client.force_authenticate(u)
        r = self.client.put('/api/perfil/', {
            'nome': 'Ana Maria Souza', 'email': 'ana2@x.com', 'telefone': '81999990000',
            'matricula': 123, 'curso': 'Física', 'avatar': '🦊', 'bio': 'oi'}, format='json')
        self.assertEqual(r.status_code, 200, r.data)
        self.assertTrue(r.data['perfil_completo'])
        u.refresh_from_db()
        self.assertEqual(u.last_name, 'Maria Souza')
        self.assertEqual(u.username, 'ana2@x.com')
        # login com o novo e-mail funciona
        self.client.force_authenticate(None)
        r = self.client.post('/api/auth/login/',
                             {'email': 'ana2@x.com', 'senha': 'senha12345'}, format='json')
        self.assertEqual(r.status_code, 200)

    def test_perfil_telefone_matricula_unicos(self):
        a = novo_usuario('a@x.com')
        b = novo_usuario('b@x.com')
        Aluno.objects.create(usuario=a, telefone='111', matricula=1, curso='Física')
        self.client.force_authenticate(b)
        r = self.client.put('/api/perfil/', {
            'nome': 'B B', 'email': 'b@x.com', 'telefone': '111',
            'matricula': 1, 'curso': 'Física'}, format='json')
        self.assertEqual(r.status_code, 400)
        self.assertIn('telefone', r.data)
        self.assertIn('matricula', r.data)


@override_settings(MEDIA_ROOT=MEDIA_TMP)
class ItemTests(APITestCase):
    def setUp(self):
        self.dono = novo_usuario('dono@x.com', nome='Dono Item')
        self.outro = novo_usuario('outro@x.com', nome='Outra Pessoa')
        Aluno.objects.create(usuario=self.dono, telefone='8111', matricula=1, curso='Física')
        Aluno.objects.create(usuario=self.outro, telefone='8222', matricula=2, curso='Física')

    def criar_item(self, **kw):
        self.client.force_authenticate(self.dono)
        r = self.client.post('/api/itens/', item_payload(**kw), format='multipart')
        self.assertEqual(r.status_code, 201, r.data)
        return r.data

    def test_listagem_publica_so_ativos_e_filtros(self):
        a = self.criar_item(nome='Chave do lab', local='laboratorio', icone='fa-key')
        self.criar_item(nome='Mochila', local='biblioteca')
        Item.objects.filter(pk=a['id']).update(status_Item='entregue')
        self.client.force_authenticate(None)

        r = self.client.get('/api/itens/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data['count'], 1)
        self.assertEqual(r.data['results'][0]['nome'], 'Mochila')

        self.assertEqual(self.client.get('/api/itens/?q=moch').data['count'], 1)
        self.assertEqual(self.client.get('/api/itens/?q=zzz').data['count'], 0)
        self.assertEqual(self.client.get('/api/itens/?local=cantina').data['count'], 0)
        self.assertEqual(self.client.get('/api/itens/?situacao=perdido').data['count'], 0)
        self.assertEqual(self.client.get('/api/itens/?status=entregue').data['count'], 1)

    def test_criar_exige_login_e_valida(self):
        self.client.force_authenticate(None)
        r = self.client.post('/api/itens/', item_payload(), format='multipart')
        self.assertEqual(r.status_code, 401)
        self.client.force_authenticate(self.dono)
        r = self.client.post('/api/itens/', item_payload(icone='fa-nope'), format='multipart')
        self.assertEqual(r.status_code, 400)
        self.assertIn('icone', r.data)

    def test_criar_com_foto_e_remover(self):
        self.client.force_authenticate(self.dono)
        r = self.client.post('/api/itens/', item_payload(foto=foto_fake()), format='multipart')
        self.assertEqual(r.status_code, 201, r.data)
        self.assertTrue(r.data['foto'].startswith('http'))
        r2 = self.client.patch(f"/api/itens/{r.data['id']}/", {'remover_foto': 'true'},
                               format='multipart')
        self.assertEqual(r2.status_code, 200, r2.data)
        self.assertIsNone(r2.data['foto'])

    def test_editar_e_excluir_somente_dono(self):
        item = self.criar_item()
        url = f"/api/itens/{item['id']}/"
        self.client.force_authenticate(self.outro)
        self.assertEqual(self.client.patch(url, {'nome': 'X'}, format='json').status_code, 403)
        self.assertEqual(self.client.delete(url).status_code, 403)

        self.client.force_authenticate(self.dono)
        r = self.client.patch(url, {'nome': 'Novo nome'}, format='json')
        self.assertEqual(r.status_code, 200, r.data)
        self.assertEqual(r.data['nome'], 'Novo nome')
        self.assertEqual(self.client.delete(url).status_code, 204)

    def test_status_nao_editavel_pelo_cliente(self):
        item = self.criar_item()
        r = self.client.patch(f"/api/itens/{item['id']}/", {'status_item': 'entregue'},
                              format='json')
        self.assertEqual(r.data['status_item'], 'ativo')

    def test_fluxo_reivindicacao_aprovada(self):
        item = self.criar_item()
        url_reiv = f"/api/itens/{item['id']}/reivindicar/"

        # dono não pode reivindicar o próprio item
        self.assertEqual(self.client.post(url_reiv, {'descricao_prova': 'é meu mesmo, juro'},
                                          format='json').status_code, 403)

        self.client.force_authenticate(self.outro)
        # prova curta demais
        self.assertEqual(self.client.post(url_reiv, {'descricao_prova': 'meu'},
                                          format='json').status_code, 400)
        r = self.client.post(url_reiv, {'descricao_prova': 'Tem meu nome na etiqueta interna'},
                             format='json')
        self.assertEqual(r.status_code, 201, r.data)
        self.assertEqual(Item.objects.get(pk=item['id']).status_Item, 'reivindicado')
        # segunda reivindicação é barrada
        self.assertEqual(self.client.post(url_reiv, {'descricao_prova': 'também é meu, vejam'},
                                          format='json').status_code, 409)

        # o requerente não pode decidir
        url_dec = f"/api/itens/{item['id']}/decidir/"
        self.assertEqual(self.client.post(url_dec, {'decisao': 'aprovada'},
                                          format='json').status_code, 403)

        # terceiros não veem a prova; envolvidos veem
        terceiro = novo_usuario('t@x.com')
        self.client.force_authenticate(terceiro)
        det = self.client.get(f"/api/itens/{item['id']}/").data
        self.assertEqual(det['reivindicacao'], {'status': 'pendente'})
        self.client.force_authenticate(self.outro)
        det = self.client.get(f"/api/itens/{item['id']}/").data
        self.assertIn('descricao_prova', det['reivindicacao'])

        # dono aprova → entregue + contatos liberados
        self.client.force_authenticate(self.dono)
        det = self.client.get(f"/api/itens/{item['id']}/").data
        self.assertTrue(det['pode_decidir'])
        r = self.client.post(url_dec, {'decisao': 'aprovada'}, format='json')
        self.assertEqual(r.status_code, 200, r.data)
        self.assertEqual(r.data['status_item'], 'entregue')
        self.assertEqual(r.data['reivindicacao']['contato'], '8222')
        self.client.force_authenticate(self.outro)
        det = self.client.get(f"/api/itens/{item['id']}/").data
        self.assertEqual(det['reivindicacao']['contato'], '8111')
        # decidir de novo é barrado
        self.client.force_authenticate(self.dono)
        self.assertEqual(self.client.post(url_dec, {'decisao': 'recusada'},
                                          format='json').status_code, 409)

    def test_reivindicacao_recusada_volta_a_ativo(self):
        item = self.criar_item()
        self.client.force_authenticate(self.outro)
        self.client.post(f"/api/itens/{item['id']}/reivindicar/",
                         {'descricao_prova': 'prova bem detalhada aqui'}, format='json')
        self.client.force_authenticate(self.dono)
        r = self.client.post(f"/api/itens/{item['id']}/decidir/",
                             {'decisao': 'recusada'}, format='json')
        self.assertEqual(r.data['status_item'], 'ativo')

    def test_decisao_invalida(self):
        item = self.criar_item()
        self.client.force_authenticate(self.outro)
        self.client.post(f"/api/itens/{item['id']}/reivindicar/",
                         {'descricao_prova': 'prova bem detalhada aqui'}, format='json')
        self.client.force_authenticate(self.dono)
        r = self.client.post(f"/api/itens/{item['id']}/decidir/",
                             {'decisao': 'talvez'}, format='json')
        self.assertEqual(r.status_code, 400)

    def test_meus_itens(self):
        self.criar_item(nome='Meu 1')
        self.client.force_authenticate(self.outro)
        self.assertEqual(self.client.get('/api/itens/?meus=1').data['count'], 0)
        self.client.force_authenticate(self.dono)
        self.assertEqual(self.client.get('/api/itens/?meus=1').data['count'], 1)


class ChatbotTests(APITestCase):
    def test_respostas(self):
        self.assertIn('cadastrar', encontrar_resposta('como cadastrar um item?'))
        self.assertIn('Ativo', encontrar_resposta('quais os status do item'))
        self.assertEqual(encontrar_resposta('qwxzyk jhgfd lorem'), NAO_ENTENDI)

    def test_endpoint(self):
        r = self.client.post('/api/chatbot/', {'mensagem': 'como reivindicar um item'},
                             format='json')
        self.assertEqual(r.status_code, 200)
        self.assertIn('Reivindicar', r.data['resposta'])
        self.assertEqual(self.client.post('/api/chatbot/', {'mensagem': ' '},
                                          format='json').status_code, 400)

    def test_opcoes(self):
        r = self.client.get('/api/opcoes/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(len(r.data['icones']), 8)
