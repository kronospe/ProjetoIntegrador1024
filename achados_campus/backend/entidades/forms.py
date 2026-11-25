from django import forms
from django.core.files.uploadedfile import UploadedFile
from .imagens import processar_foto
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
            'icone',
            'foto',
            'data_encontro',
        ]

    def clean_foto(self):
        foto = self.cleaned_data.get('foto')
        # só processa uploads novos (limita a 1280 px e converte para JPEG)
        if isinstance(foto, UploadedFile):
            return processar_foto(foto)
        return foto

class ReivindicacaoForm(forms.ModelForm):
    class Meta:
        model = Reivindicacao
        fields = [
            'descricao_prova',
        ]