from django.db import models
from django.urls import reverse
from django.contrib.auth.models import User

class Aluno(models.Model):

    usuario = models.OneToOneField(

        User,
        on_delete = models.CASCADE,
        related_name = "Aluno" 

    )
    matricula = models.IntegerField('Matrícula', unique=True, null=True, blank=True)
    curso = models.CharField('Curso' ,max_length = 100)
    telefone = models.CharField('Telefone', unique = True, max_length = 15)


    class Meta:

        verbose_name = 'Aluno'
        verbose_name_plural = 'Alunos'

    def __str__(self):

        return f'{self.usuario.get_full_name()} — {self.matricula}'
    avatar = models.CharField('Avatar', max_length=10, default='🧑‍💻')
    bio    = models.TextField('Bio', blank=True, default='')

class Item(models.Model):

    SITUACAO_ITEM = [
        ('perdido', 'Perdido'),
        ('encontrado', 'Encontrado'),
    ]

    STATUS_ITEM = [
        ('ativo', 'Ativo'),
        ('reivindicado', 'Reivindicado'),
        ('entregue', 'Entregue'),
    ]

    LOCAL_ENCONTRADO = [ 
        ('biblioteca', 'Biblioteca'),
        ('cantina', 'Cantina'),
        ('laboratorio', 'Laboratório'),
        ('sala_aula', 'Sala de Aula'),
        ('estacionamento', 'Estacionamento'),
        ('banheiro', 'Banheiro'),
        ('outro', 'Outro'),
        
        ]
    ICONE_CHOICES = [
        ('fa-laptop', 'Eletrônicos/Notebook'),
        ('fa-key', 'Chaves'),
        ('fa-wallet', 'Carteira/Dinheiro'),
        ('fa-book', 'Livros/Cadernos'),
        ('fa-mobile-screen-button', 'Celular'),
        ('fa-shirt', 'Roupas/Casacos'),
        ('fa-glasses', 'Óculos'),
        ('fa-backpack', 'Bolsas/Mochilas'),
    ]

    nome = models.CharField('Nome do item encontrado', max_length = 50)
    descricao = models.TextField('Descrição do item encontrado')
    local = models.CharField('Local onde o item foi encontrado', max_length = 20, choices = LOCAL_ENCONTRADO)
    situacao_Item = models.CharField(max_length =20, choices = SITUACAO_ITEM)
    status_Item = models.CharField(max_length=20, choices=STATUS_ITEM, default='ativo')
    foto = models.ImageField('Imagem do item encontrado', upload_to ='itens/' ,blank = True, null = True)
    data_encontro = models.DateField('Data em que o item foi encontrado')
    data_criacao = models.DateTimeField(auto_now_add = True)
    icone = models.CharField('Ícone do item', max_length = 50, choices = ICONE_CHOICES, default = 'fa-laptop')

    cadastrado_por = models.ForeignKey(

        User,
        on_delete = models.CASCADE,
        related_name = "itens",
        verbose_name = "Cadastrado_por",

     )
    
    class Meta:

        verbose_name = 'Item'
        verbose_name_plural = 'Itens'
        ordering = ['-data_criacao']

    
    def __str__(self):

        return f'[{self.get_situacao_display()}] {self.nome}'
    
class Reivindicacao(models.Model):

    STATUS_REIVINDICACAO = [
        ('pendente', 'Pendente'),
        ('aprovada', 'Aprovada'),
        ('recusada', 'Recusada'),

    ]
         
    item = models.OneToOneField(Item, on_delete = models.CASCADE, related_name = 'reivindicacao', verbose_name = 'Item reivindicacao')
    descricao_prova = models.TextField('Prova que o Item é seu')
    status_Reivindicacao = models.CharField('Status reivindicacao', max_length = 20, choices = STATUS_REIVINDICACAO, default = 'pendente')
    criado_em = models.DateTimeField(auto_now_add = True)

    requerente = models.ForeignKey(

        User,
        on_delete = models.CASCADE,
        related_name = 'reivindicacoes',
        verbose_name = 'Requerente',

    )

    class Meta:

        verbose_name = 'Reivindicação'
        verbose_name_plural = 'Reivindicações'

    def __str__(self):

        return f'{self.requerente} → {self.item}'
