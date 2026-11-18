from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Reivindicacao

@receiver(post_save, sender=Reivindicacao)
def atualizar_status_item(sender, instance, **kwargs):

    if instance.status_Reivindicacao == 'aprovada':
        instance.item.status_Item = 'entregue'
        instance.item.save()

    elif instance.status_Reivindicacao == 'recusada':
        instance.item.status_Item = 'ativo'
        instance.item.save()