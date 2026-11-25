from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import Reivindicacao


@receiver(post_save, sender=Reivindicacao)
def atualizar_status_item(sender, instance, **kwargs):
    item = instance.item

    if instance.status_Reivindicacao == 'aprovada':
        item.status_Item = 'entregue'
        item.save(update_fields=['status_Item'])

    elif instance.status_Reivindicacao == 'recusada':
        # só volta a "ativo" se não houver outra reivindicação em andamento
        if item.reivindicacoes.filter(
                status_Reivindicacao__in=Reivindicacao.STATUS_ATIVOS).exists():
            return
        item.status_Item = 'ativo'
        item.save(update_fields=['status_Item'])
