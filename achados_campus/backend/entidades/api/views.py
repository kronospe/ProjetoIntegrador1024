from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .. import chatbot, services
from ..models import Item
from .serializers import (
    CURSOS, CadastroSerializer, ItemSerializer, LoginSerializer,
    PerfilSerializer, ReivindicacaoSerializer, usuario_payload,
)


def _tokens(user):
    refresh = RefreshToken.for_user(user)
    return {'access': str(refresh.access_token), 'refresh': str(refresh)}


def _erro(mensagem, codigo=status.HTTP_400_BAD_REQUEST):
    return Response({'detail': mensagem}, status=codigo)


def _erro_servico(e: services.ServicoErro):
    corpo = {e.campo: [e.mensagem]} if e.campo else {'detail': e.mensagem}
    return Response(corpo, status=e.status)


def _itens_qs():
    return (Item.objects.select_related('cadastrado_por')
            .prefetch_related('reivindicacoes__requerente'))


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
        user = services.autenticar(request, ser.validated_data['email'],
                                   ser.validated_data['senha'])
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
        qs = _itens_qs()
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
    queryset = _itens_qs()

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
        item = get_object_or_404(_itens_qs(), pk=pk)
        try:
            reiv = services.criar_reivindicacao(
                item, request.user, request.data.get('descricao_prova'))
        except services.ServicoErro as e:
            return _erro_servico(e)
        return Response(ReivindicacaoSerializer(reiv, context={'request': request}).data,
                        status=status.HTTP_201_CREATED)


class DecidirReivindicacaoView(APIView):
    """O dono do item (ou staff) aprova ou recusa a reivindicação."""

    def post(self, request, pk):
        item = get_object_or_404(_itens_qs(), pk=pk)
        try:
            item = services.decidir_reivindicacao(item, request.user, request.data.get('decisao'))
        except services.ServicoErro as e:
            return _erro_servico(e)
        item = get_object_or_404(_itens_qs(), pk=item.pk)
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
