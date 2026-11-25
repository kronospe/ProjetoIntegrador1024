"""Regras de negócio compartilhadas entre o site (views.py) e a API (api/).

Assim, uma regra só existe em um lugar.
"""
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.validators import validate_email
from django.db import IntegrityError, transaction

from .models import Aluno, Item, Reivindicacao


class ServicoErro(Exception):
    """Erro de regra de negócio, com código HTTP sugerido para a API."""

    def __init__(self, mensagem, status=400, campo=None):
        super().__init__(mensagem)
        self.mensagem = mensagem
        self.status = status
        self.campo = campo


# --------------------------------------------------------------------------
# Autenticação
# --------------------------------------------------------------------------
def autenticar(request, identificador, senha):
    """Login pelo e-mail (que é o username), ignorando maiúsculas/minúsculas."""
    ident = (identificador or '').strip()
    user = authenticate(request, username=ident, password=senha)
    if user is None:
        achado = (User.objects.filter(email__iexact=ident).first()
                  or User.objects.filter(username__iexact=ident).first())
        if achado:
            user = authenticate(request, username=achado.username, password=senha)
    return user


# --------------------------------------------------------------------------
# Perfil
# --------------------------------------------------------------------------
def erros_perfil(user, dados):
    """Valida os dados do perfil. Retorna {campo: mensagem} (vazio se ok)."""
    erros = {}
    aluno = Aluno.objects.filter(usuario=user).first()

    if not (dados.get('nome') or '').strip():
        erros['nome'] = 'Nome obrigatório.'

    email = (dados.get('email') or '').strip().lower()
    try:
        validate_email(email)
    except DjangoValidationError:
        erros['email'] = 'E-mail inválido.'
    else:
        if (User.objects.filter(username__iexact=email).exclude(pk=user.pk).exists()
                or User.objects.filter(email__iexact=email).exclude(pk=user.pk).exists()):
            erros['email'] = 'Este e-mail já está em uso.'

    telefone = (dados.get('telefone') or '').strip()
    if not telefone:
        erros['telefone'] = 'Telefone obrigatório.'
    else:
        qs = Aluno.objects.filter(telefone=telefone)
        if aluno:
            qs = qs.exclude(pk=aluno.pk)
        if qs.exists():
            erros['telefone'] = 'Este telefone já está cadastrado.'

    try:
        matricula = int(str(dados.get('matricula')).strip())
    except (TypeError, ValueError):
        erros['matricula'] = 'Matrícula obrigatória (somente números).'
    else:
        qs = Aluno.objects.filter(matricula=matricula)
        if aluno:
            qs = qs.exclude(pk=aluno.pk)
        if qs.exists():
            erros['matricula'] = 'Esta matrícula já está cadastrada.'

    if not (dados.get('curso') or '').strip():
        erros['curso'] = 'Selecione seu curso.'
    return erros


@transaction.atomic
def salvar_perfil(user, dados):
    """Grava o perfil. Assume que `erros_perfil` já foi checado."""
    partes = dados['nome'].split()
    email = dados['email'].strip().lower()
    user.first_name = partes[0]
    user.last_name = ' '.join(partes[1:])
    user.email = email
    user.username = email  # o e-mail é o login: mantém em sincronia
    user.save()

    aluno = Aluno.objects.filter(usuario=user).first() or Aluno(usuario=user)
    aluno.telefone = dados['telefone'].strip()
    aluno.matricula = int(str(dados['matricula']).strip())
    aluno.curso = dados['curso']
    aluno.avatar = dados.get('avatar') or '🧑‍💻'
    aluno.bio = dados.get('bio') or ''
    aluno.save()
    return user


# --------------------------------------------------------------------------
# Reivindicações
# --------------------------------------------------------------------------
def criar_reivindicacao(item, user, prova):
    prova = (prova or '').strip()
    if len(prova) < 10:
        raise ServicoErro('Descreva melhor a prova (mínimo de 10 caracteres).',
                          400, campo='descricao_prova')
    if item.cadastrado_por_id == user.id:
        raise ServicoErro('Você não pode reivindicar um item que você mesmo cadastrou.', 403)
    if item.status_Item != 'ativo' or item.reivindicacao is not None:
        raise ServicoErro('Este item já possui uma reivindicação.', 409)

    try:
        with transaction.atomic():
            reiv = Reivindicacao.objects.create(
                item=item, requerente=user, descricao_prova=prova)
            item.status_Item = 'reivindicado'
            item.save(update_fields=['status_Item'])
    except IntegrityError:  # duas pessoas reivindicaram ao mesmo tempo
        raise ServicoErro('Este item já possui uma reivindicação.', 409)
    return reiv


def decidir_reivindicacao(item, user, decisao):
    """O dono do item (ou staff) aprova ou recusa a reivindicação pendente."""
    if item.cadastrado_por_id != user.id and not user.is_staff:
        raise ServicoErro('Apenas quem cadastrou o item pode decidir.', 403)

    reiv = item.reivindicacao
    if reiv is None:
        raise ServicoErro('Este item não possui reivindicação.', 404)
    if reiv.status_Reivindicacao != 'pendente':
        raise ServicoErro('Esta reivindicação já foi decidida.', 409)
    if decisao not in ('aprovada', 'recusada'):
        raise ServicoErro('Decisão inválida. Use "aprovada" ou "recusada".', 400)

    reiv.status_Reivindicacao = decisao
    reiv.save()  # o signal atualiza o status do item (entregue / ativo)
    return Item.objects.get(pk=item.pk)


def telefone_de(user):
    aluno = Aluno.objects.filter(usuario=user).first()
    return aluno.telefone if aluno else ''


def contato_liberado(reiv, user):
    """Telefone da outra parte, só após aprovada e só para os envolvidos."""
    if reiv is None or reiv.status_Reivindicacao != 'aprovada':
        return None
    dono = reiv.item.cadastrado_por
    if user == dono:
        return telefone_de(reiv.requerente)
    if user == reiv.requerente:
        return telefone_de(dono)
    return None


def whatsapp_url(telefone):
    """Link wa.me a partir de um telefone brasileiro (com ou sem máscara)."""
    digitos = ''.join(c for c in (telefone or '') if c.isdigit())
    if len(digitos) < 10:
        return None
    if not digitos.startswith('55'):
        digitos = '55' + digitos
    return f'https://wa.me/{digitos}'
