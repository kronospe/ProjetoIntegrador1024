from django.contrib.auth.models import User
from rest_framework import serializers

from ..models import Aluno, Item, Reivindicacao

CURSOS = [
    'Ciência da Computação', 'Engenharia de Software',
    'Sistemas de Informação', 'Engenharia Elétrica',
    'Engenharia Civil', 'Administração', 'Matemática', 'Física', 'Outro',
]


# ---------------------------------------------------------------------------
# Usuário / perfil
# ---------------------------------------------------------------------------
def usuario_payload(user: User) -> dict:
    aluno = Aluno.objects.filter(usuario=user).first()
    return {
        'id': user.id,
        'nome': user.get_full_name().strip() or user.username,
        'email': user.email,
        'is_staff': user.is_staff,
        'matricula': aluno.matricula if aluno else None,
        'curso': aluno.curso if aluno else '',
        'telefone': aluno.telefone if aluno else '',
        'avatar': aluno.avatar if aluno else '🧑‍💻',
        'bio': aluno.bio if aluno else '',
        'perfil_completo': bool(aluno and aluno.matricula and aluno.telefone),
    }


def _separar_nome(nome: str):
    partes = nome.split()
    return partes[0], ' '.join(partes[1:])


class CadastroSerializer(serializers.Serializer):
    nome = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    senha = serializers.CharField(write_only=True, min_length=8, trim_whitespace=False)
    confirmar_senha = serializers.CharField(write_only=True, trim_whitespace=False)

    def validate_nome(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError('Informe seu nome.')
        return value

    def validate_email(self, value):
        value = value.strip().lower()
        if User.objects.filter(username__iexact=value).exists() or \
                User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError('Este e-mail já está cadastrado.')
        return value

    def validate(self, attrs):
        if attrs['senha'] != attrs['confirmar_senha']:
            raise serializers.ValidationError({'confirmar_senha': 'As senhas não coincidem.'})
        return attrs

    def create(self, validated_data):
        primeiro, resto = _separar_nome(validated_data['nome'])
        return User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['senha'],
            first_name=primeiro,
            last_name=resto,
        )


class LoginSerializer(serializers.Serializer):
    email = serializers.CharField()
    senha = serializers.CharField(write_only=True, trim_whitespace=False)


class PerfilSerializer(serializers.Serializer):
    nome = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    telefone = serializers.CharField(max_length=15)
    matricula = serializers.IntegerField()
    curso = serializers.CharField(max_length=100)
    avatar = serializers.CharField(max_length=10, required=False, default='🧑‍💻')
    bio = serializers.CharField(required=False, allow_blank=True, default='')

    def validate_nome(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError('Nome obrigatório.')
        return value

    def validate_email(self, value):
        value = value.strip().lower()
        user = self.context['request'].user
        if User.objects.filter(username__iexact=value).exclude(pk=user.pk).exists() or \
                User.objects.filter(email__iexact=value).exclude(pk=user.pk).exists():
            raise serializers.ValidationError('Este e-mail já está em uso.')
        return value

    def _aluno_atual(self):
        return Aluno.objects.filter(usuario=self.context['request'].user).first()

    def validate_telefone(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError('Telefone obrigatório.')
        aluno = self._aluno_atual()
        qs = Aluno.objects.filter(telefone=value)
        if aluno:
            qs = qs.exclude(pk=aluno.pk)
        if qs.exists():
            raise serializers.ValidationError('Este telefone já está cadastrado.')
        return value

    def validate_matricula(self, value):
        aluno = self._aluno_atual()
        qs = Aluno.objects.filter(matricula=value)
        if aluno:
            qs = qs.exclude(pk=aluno.pk)
        if qs.exists():
            raise serializers.ValidationError('Esta matrícula já está cadastrada.')
        return value

    def save(self, **kwargs):
        user = self.context['request'].user
        d = self.validated_data
        primeiro, resto = _separar_nome(d['nome'])
        user.first_name, user.last_name = primeiro, resto
        user.email = d['email']
        # o e-mail é o login: mantém o username em sincronia
        user.username = d['email']
        user.save()

        aluno = self._aluno_atual() or Aluno(usuario=user)
        aluno.telefone = d['telefone']
        aluno.matricula = d['matricula']
        aluno.curso = d['curso']
        aluno.avatar = d.get('avatar') or '🧑‍💻'
        aluno.bio = d.get('bio', '')
        aluno.save()
        return user


# ---------------------------------------------------------------------------
# Reivindicação
# ---------------------------------------------------------------------------
class ReivindicacaoCriarSerializer(serializers.Serializer):
    descricao_prova = serializers.CharField()

    def validate_descricao_prova(self, value):
        value = value.strip()
        if len(value) < 10:
            raise serializers.ValidationError(
                'Descreva melhor a prova (mínimo de 10 caracteres).')
        return value


def _telefone(user):
    aluno = Aluno.objects.filter(usuario=user).first()
    return aluno.telefone if aluno else ''


class ReivindicacaoSerializer(serializers.ModelSerializer):
    status = serializers.CharField(source='status_Reivindicacao', read_only=True)
    requerente_id = serializers.IntegerField(source='requerente.id', read_only=True)
    requerente_nome = serializers.SerializerMethodField()
    contato = serializers.SerializerMethodField()

    class Meta:
        model = Reivindicacao
        fields = ['id', 'descricao_prova', 'status', 'criado_em',
                  'requerente_id', 'requerente_nome', 'contato']

    def get_requerente_nome(self, obj):
        return obj.requerente.get_full_name().strip() or obj.requerente.username

    def get_contato(self, obj):
        """Telefone da outra parte, só depois de aprovada e só para os envolvidos."""
        if obj.status_Reivindicacao != 'aprovada':
            return None
        user = self.context['request'].user
        dono = obj.item.cadastrado_por
        if user == dono:
            return _telefone(obj.requerente)
        if user == obj.requerente:
            return _telefone(dono)
        return None


# ---------------------------------------------------------------------------
# Item
# ---------------------------------------------------------------------------
class ItemSerializer(serializers.ModelSerializer):
    situacao_item = serializers.ChoiceField(
        source='situacao_Item', choices=Item.SITUACAO_ITEM)
    status_item = serializers.CharField(source='status_Item', read_only=True)
    local_display = serializers.CharField(source='get_local_display', read_only=True)
    cadastrado_por_id = serializers.IntegerField(source='cadastrado_por.id', read_only=True)
    cadastrado_por_nome = serializers.SerializerMethodField()
    pode_editar = serializers.SerializerMethodField()
    pode_reivindicar = serializers.SerializerMethodField()
    pode_decidir = serializers.SerializerMethodField()
    reivindicacao = serializers.SerializerMethodField()
    remover_foto = serializers.BooleanField(write_only=True, required=False, default=False)
    foto = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = Item
        fields = [
            'id', 'nome', 'descricao', 'local', 'local_display',
            'situacao_item', 'status_item', 'icone', 'foto', 'remover_foto',
            'data_encontro', 'data_criacao',
            'cadastrado_por_id', 'cadastrado_por_nome',
            'pode_editar', 'pode_reivindicar', 'pode_decidir', 'reivindicacao',
        ]
        read_only_fields = ['id', 'data_criacao']

    # -- helpers ------------------------------------------------------------
    def _user(self):
        request = self.context.get('request')
        return request.user if request and request.user.is_authenticated else None

    def _reivindicacao(self, obj):
        return getattr(obj, 'reivindicacao', None)

    # -- campos calculados --------------------------------------------------
    def get_cadastrado_por_nome(self, obj):
        return obj.cadastrado_por.get_full_name().strip() or 'Usuário'

    def get_pode_editar(self, obj):
        user = self._user()
        return bool(user and (obj.cadastrado_por_id == user.id or user.is_staff))

    def get_pode_reivindicar(self, obj):
        user = self._user()
        return bool(
            user
            and obj.cadastrado_por_id != user.id
            and obj.status_Item == 'ativo'
            and self._reivindicacao(obj) is None
        )

    def get_pode_decidir(self, obj):
        user = self._user()
        reiv = self._reivindicacao(obj)
        return bool(
            user and reiv
            and reiv.status_Reivindicacao == 'pendente'
            and (obj.cadastrado_por_id == user.id or user.is_staff)
        )

    def get_reivindicacao(self, obj):
        """Detalhes completos só para dono do item, requerente e staff.
        Os demais só veem o status, sem a prova."""
        reiv = self._reivindicacao(obj)
        if reiv is None:
            return None
        user = self._user()
        envolvido = bool(user and (
            user.is_staff or user.id in (obj.cadastrado_por_id, reiv.requerente_id)))
        if envolvido:
            return ReivindicacaoSerializer(reiv, context=self.context).data
        return {'status': reiv.status_Reivindicacao}

    # -- validação / escrita ------------------------------------------------
    def validate_icone(self, value):
        if value not in dict(Item.ICONE_CHOICES):
            raise serializers.ValidationError('Selecione um ícone válido.')
        return value

    def validate_foto(self, value):
        if value and value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError('A foto deve ter no máximo 5 MB.')
        return value

    def create(self, validated_data):
        validated_data.pop('remover_foto', None)
        return super().create(validated_data)

    def update(self, instance, validated_data):
        if validated_data.pop('remover_foto', False) and instance.foto:
            instance.foto.delete(save=False)
            instance.foto = None
        return super().update(instance, validated_data)
