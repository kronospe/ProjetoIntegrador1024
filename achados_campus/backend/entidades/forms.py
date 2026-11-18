from django import forms
from .models import Item, Reivindicacao

class ItemForm(forms.ModelForm):
    # O campo customizado fica aqui no topo da classe
    icone = forms.ChoiceField(
        choices=Item.ICONE_CHOICES,
        widget=forms.HiddenInput(),
        required=True,  
        error_messages={'required': 'Por favor, selecione um ícone para identificar o item.'}
    )

   
    class Meta:
        model = Item
        fields = [
            'nome',
            'descricao',
            'local',
            'situacao_Item',
            'status_Item',
            'icone',
            'foto',
            'data_encontro',
        ]

class ReivindicacaoForm(forms.ModelForm):
    class Meta:
        model = Reivindicacao
        fields = [
            'descricao_prova',
        ]