from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .. import chatbot
from ..models import Item, Reivindicacao
from .serializers import (
    CURSOS, CadastroSerializer, ItemSerializer, LoginSerializer,
    PerfilSerializer, ReivindicacaoCriarSerializer, ReivindicacaoSerializer,
    usuario_payload,
)


def _tokens(user):
    refresh = RefreshToken.for_user(user)
    return {'access': str(refresh.access_token), 'refresh': str(refresh)}


def _erro(mensagem, codigo=status.HTTP_400_BAD_REQUEST):
    return Response({'detail': mensagem}, status=codigo)


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
class CadastroView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'auth'

    def post(self, request):
        ser = CadastroSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        user = ser.save()
        return Response({**_tokens(user), 'usuario': usuario_payload(user)},
                        status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'auth'

    def post(self, request):
        ser = LoginSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        ident = ser.validated_data['email'].strip()

        # o login é o e-mail (username == e-mail), mas aceita também o username
        user = authenticate(request, username=ident, password=ser.validated_data['senha'])
        if user is None:
            achado = User.objects.filter(email__iexact=ident).first()
            if achado:
                user = authenticate(
                    request, username=achado.username, password=ser.validated_data['senha'])
        if user is None:
            return _erro('Usuário ou senha incorretos.', status.HTTP_401_UNAUTHORIZED)
        return Response({**_tokens(user), 'usuario': usuario_payload(user)})


class PerfilView(APIView):
    def get(self, request):
        if not request.user.is_authenticated:
            return _erro('Autenticação necessária.', status.HTTP_401_UNAUTHORIZED)
        return Response(usuario_payload(request.user))

    def put(self, request):
        if not request.user.is_authenticated:
            return _erro('Autenticação necessária.', status.HTTP_401_UNAUTHORIZED)
        ser = PerfilSerializer(data=request.data, context={'request': request})
        ser.is_valid(raise_exception=True)
        user = ser.save()
        return Response(usuario_payload(user))


class OpcoesView(APIView):
    """Listas de opções para montar formulários e filtros no app."""
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return Response({
            'cursos': CURSOS,
            'locais': [{'valor': v, 'nome': n} for v, n in Item.LOCAL_ENCONTRADO],
            'situacoes': [{'valor': v, 'nome': n} for v, n in Item.SITUACAO_ITEM],
            'status': [{'valor': v, 'nome': n} for v, n in Item.STATUS_ITEM],
            'icones': [{'valor': v, 'nome': n} for v, n in Item.ICONE_CHOICES],
            'sugestoes_chatbot': chatbot.SUGESTOES,
        })


# ---------------------------------------------------------------------------
# Itens
# ---------------------------------------------------------------------------
class ItemListCreateView(generics.ListCreateAPIView):
    serializer_class = ItemSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        qs = Item.objects.select_related('cadastrado_por', 'reivindicacao__requerente')
        p = self.request.query_params

        if p.get('meus') in ('1', 'true') and self.request.user.is_authenticated:
            qs = qs.filter(cadastrado_por=self.request.user)
        else:
            # como no site: por padrão só itens ativos
            qs = qs.filter(status_Item=p.get('status') or 'ativo')

        if p.get('q'):
            qs = qs.filter(nome__icontains=p['q'])
        if p.get('situacao'):
            qs = qs.filter(situacao_Item=p['situacao'])
        if p.get('local'):
            qs = qs.filter(local=p['local'])
        return qs

    def perform_create(self, serializer):
        serializer.save(cadastrado_por=self.request.user)


class ItemDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = ItemSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    queryset = Item.objects.select_related('cadastrado_por', 'reivindicacao__requerente')

    def _checar_dono(self, item):
        user = self.request.user
        if item.cadastrado_por_id != user.id and not user.is_staff:
            self.permission_denied(
                self.request, message='Você não tem permissão para alterar esse item.')

    def perform_update(self, serializer):
        self._checar_dono(serializer.instance)
        serializer.save()

    def perform_destroy(self, instance):
        self._checar_dono(instance)
        instance.delete()


class ReivindicarView(APIView):
    def post(self, request, pk):
        item = get_object_or_404(Item, pk=pk)

        if item.cadastrado_por_id == request.user.id:
            return _erro('Você não pode reivindicar um item que você mesmo cadastrou.',
                         status.HTTP_403_FORBIDDEN)
        if hasattr(item, 'reivindicacao') or item.status_Item != 'ativo':
            return _erro('Este item já possui uma reivindicação.', status.HTTP_409_CONFLICT)

        ser = ReivindicacaoCriarSerializer(data=request.data)
        ser.is_valid(raise_exception=True)

        with transaction.atomic():
            reiv = Reivindicacao.objects.create(
                item=item, requerente=request.user,
                descricao_prova=ser.validated_data['descricao_prova'])
            item.status_Item = 'reivindicado'
            item.save(update_fields=['status_Item'])

        return Response(ReivindicacaoSerializer(reiv, context={'request': request}).data,
                        status=status.HTTP_201_CREATED)


class DecidirReivindicacaoView(APIView):
    """O dono do item (ou staff) aprova ou recusa a reivindicação."""

    def post(self, request, pk):
        item = get_object_or_404(Item, pk=pk)
        if item.cadastrado_por_id != request.user.id and not request.user.is_staff:
            return _erro('Apenas quem cadastrou o item pode decidir.', status.HTTP_403_FORBIDDEN)

        reiv = getattr(item, 'reivindicacao', None)
        if reiv is None:
            return _erro('Este item não possui reivindicação.', status.HTTP_404_NOT_FOUND)
        if reiv.status_Reivindicacao != 'pendente':
            return _erro('Esta reivindicação já foi decidida.', status.HTTP_409_CONFLICT)

        decisao = request.data.get('decisao')
        if decisao not in ('aprovada', 'recusada'):
            return _erro('Decisão inválida. Use "aprovada" ou "recusada".')

        reiv.status_Reivindicacao = decisao
        reiv.save()  # o signal atualiza o status do item (entregue / ativo)

        item.refresh_from_db()
        return Response(ItemSerializer(item, context={'request': request}).data)


# ---------------------------------------------------------------------------
# Chatbot
# ---------------------------------------------------------------------------
class ChatbotView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'chatbot'

    def post(self, request):
        mensagem = str(request.data.get('mensagem', '')).strip()
        if not mensagem:
            return _erro('Mensagem vazia.')
        return Response({'resposta': chatbot.encontrar_resposta(mensagem)})
