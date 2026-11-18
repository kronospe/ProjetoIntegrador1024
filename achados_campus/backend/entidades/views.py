from django.shortcuts import render, get_object_or_404, redirect
from .models import Aluno, Item, Reivindicacao
from django.contrib.auth import login, logout, authenticate
from django.contrib.auth.models import User
from django.contrib import messages
from .forms import ItemForm, ReivindicacaoForm
from django.contrib.auth.decorators import login_required
import json
from . import chatbot
from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.http import require_POST


CURSOS = [
    "Ciência da Computação", "Engenharia de Software",
    "Sistemas de Informação", "Engenharia Elétrica",
    "Engenharia Civil", "Administração", "Matemática", "Física", "Outro",
]


def home(request):
    itens_perdidos = Item.objects.filter(status_Item='ativo')[:6]
    aluno = None
    if request.user.is_authenticated:
        aluno = Aluno.objects.filter(usuario=request.user).first()
    return render(request, 'entidades/home.html', {
        'itens_perdidos': itens_perdidos,
        'aluno': aluno,
    })

def login_view(request):
    if request.user.is_authenticated:
        return redirect('entidades:home')

    if request.method == 'POST':
        usuario = request.POST.get('usuario')
        senha = request.POST.get('senha')

        user = authenticate(request, username=usuario, password=senha)

        if user:
            login(request, user)
            messages.success(request, 'Bem Vindo!!')
            return redirect('entidades:home')
        else:
            messages.error(request, 'Usuário ou Senha incorretos')

    return render(request, 'entidades/login.html')

def logout_view(request):
    logout(request)
    messages.info(request, 'Você saiu da sua Conta')
    return redirect('entidades:login')

def lista_itensPerdidos(request):
    busca = request.GET.get('q', '')
    situacao = request.GET.get('situacao', '')
    local = request.GET.get('local', '')

    itens = Item.objects.filter(status_Item='ativo')

    if busca:
        itens = itens.filter(nome__icontains=busca)
    if situacao:
        itens = itens.filter(situacao_Item=situacao)
    if local:
        itens = itens.filter(local=local)

    contexto = {
        'itens': itens,
        'busca': busca,
        'situacao': situacao,
        'local': local,
    }

    return render(request, 'entidades/lista_itens.html', contexto)

def detalhe_item(request, pk):
    item = get_object_or_404(Item, pk=pk)
    contexto = {'item': item}
    return render(request, 'entidades/detalhe_item.html', contexto)

@login_required
def cadastrar_item(request):
    if request.method == 'POST':
        forms = ItemForm(request.POST, request.FILES)

        if forms.is_valid():
            item = forms.save(commit=False)
            item.cadastrado_por = request.user
            item.save()
            messages.success(request, 'Item cadastrado com sucesso')
            return redirect('entidades:detalhe_item', pk=item.pk)
        else:
            print("ERROS DO FORM:", forms.errors)
            messages.error(request, 'Dados inválidos. Tente novamente')
    else:
        forms = ItemForm()

    return render(request, 'entidades/forms_item.html', {'forms': forms, 'acao': 'Cadastrar'})

@login_required
def editar_item(request, pk):
    item = get_object_or_404(Item, pk=pk)

    if item.cadastrado_por != request.user and not request.user.is_staff:
        messages.error(request, 'Você não tem permissão para editar esse item')
        return redirect('entidades:detalhe_item', pk=pk)

    if request.method == 'POST':
        forms = ItemForm(request.POST, request.FILES, instance=item)

        if forms.is_valid():
            forms.save()
            messages.success(request, 'Item atualizado')
            return redirect('entidades:detalhe_item', pk=item.pk)
        else:
            messages.error(request, 'Dados inválidos. Tente novamente')
    else:
        forms = ItemForm(instance=item)

    return render(request, 'entidades/forms_item.html', {'forms': forms, 'acao': 'Editar'})

@login_required
def excluir_item(request, pk):
    item = get_object_or_404(Item, pk=pk)

    if item.cadastrado_por != request.user and not request.user.is_staff:
        messages.error(request, 'Você não tem permissão para excluir esse item')
        return redirect('entidades:detalhe_item', pk=pk)

    if request.method == 'POST':
        item.delete()
        messages.success(request, 'Item excluído com sucesso')
        return redirect('entidades:lista_itens')

    return render(request, 'entidades/confirma_exclusao.html', {'item': item})

@login_required
def reivindicar_item(request, pk):
    item = get_object_or_404(Item, pk=pk)

    if item.cadastrado_por == request.user:
        messages.error(request, 'Você não pode reivindicar um item que você mesmo cadastrou.')
        return redirect('entidades:detalhe_item', pk=pk)

    if hasattr(item, 'reivindicacao'):
        messages.warning(request, 'Este item já possui uma reivindicação pendente.')
        return redirect('entidades:detalhe_item', pk=pk)

    if request.method == 'POST':
        form = ReivindicacaoForm(request.POST, request.FILES)

        if form.is_valid():
            reiv = form.save(commit=False)
            reiv.item = item
            reiv.requerente = request.user
            reiv.save()
            item.status_Item = 'reivindicado'
            item.save()
            messages.success(request, 'Reivindicação enviada! Aguarde a confirmação.')
            return redirect('entidades:detalhe_item', pk=pk)
    else:
        form = ReivindicacaoForm()

    return render(request, 'entidades/reivindicar.html', {'form': form, 'item': item})
from django.contrib.auth.forms import UserCreationForm

@login_required
def perfil_view(request):
    try:
        aluno = Aluno.objects.get(usuario=request.user)
    except Aluno.DoesNotExist:
        aluno = None  

    
    if request.method == 'POST':
        nome      = request.POST.get('nome', '').strip()
        email     = request.POST.get('email', '')
        telefone  = request.POST.get('telefone', '')
        matricula = request.POST.get('matricula', '')
        curso     = request.POST.get('curso', '')
        avatar    = request.POST.get('avatar', '🧑‍💻')
        bio       = request.POST.get('bio', '')

        # Validação server-side
        erros = False
        if not nome:             messages.error(request, 'Nome obrigatório.'); erros = True
        if '@' not in email:     messages.error(request, 'E-mail inválido.'); erros = True
        if not matricula:        messages.error(request, 'Matrícula obrigatória.'); erros = True

        if not erros:
            partes = nome.split()
            request.user.first_name = partes[0]
            request.user.last_name  = ' '.join(partes[1:])
            request.user.email      = email
            request.user.save()

            if aluno is None:
                aluno = Aluno(usuario=request.user)

            aluno.telefone  = telefone
            aluno.matricula = matricula
            aluno.curso     = curso
            aluno.avatar    = avatar
            aluno.bio       = bio
            aluno.save()

            messages.success(request, 'Perfil atualizado com sucesso!')
            return redirect('entidades:perfil')

    return render(request, 'entidades/perfil.html', {
        'aluno': aluno,
        'cursos': CURSOS,
    })

def cadastro_view(request):
    if request.user.is_authenticated:
        return redirect('entidades:home')

    if request.method == 'POST':
        nome     = request.POST.get('name', '').strip()
        email    = request.POST.get('email', '')
        password = request.POST.get('password', '')
        confirm  = request.POST.get('confirm', '')

        # Validação server-side (segurança)
        erros = {}
        if not nome:              erros['name']     = 'Informe seu nome.'
        if '@' not in email:      erros['email']    = 'E-mail inválido.'
        if len(password) < 8:     erros['password'] = 'Mínimo de 8 caracteres.'
        if password != confirm:   erros['confirm']  = 'As senhas não coincidem.'

        if not erros:
            if User.objects.filter(username=email).exists():
                messages.error(request, 'Este e-mail já está cadastrado.')
            else:
                user = User.objects.create_user(
                    username=email,
                    email=email,
                    password=password,
                    first_name=nome.split()[0],
                    last_name=' '.join(nome.split()[1:]),
                )
                login(request, user)
                messages.success(request, 'Conta criada com sucesso! Bem-vindo(a)!')
                return redirect('entidades:home')

    return render(request, 'entidades/cadastro.html')

@require_POST
def chatbot_view(request):
    try:
        data = json.loads(request.body)
        mensagem = data.get('mensagem', '').strip()

        if not mensagem:
            return JsonResponse({'erro': 'Mensagem vazia'}, status=400)

        return JsonResponse({'resposta': chatbot.encontrar_resposta(mensagem)})

    except Exception as e:
        return JsonResponse({'erro': str(e)}, status=500)
