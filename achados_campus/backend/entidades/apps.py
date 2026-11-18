from django.apps import AppConfig


class EntidadesConfig(AppConfig):
    name = 'entidades'

    def ready(self):
        # Registra os signals (antes nunca eram carregados, então aprovar/recusar
        # uma reivindicação no admin não atualizava o status do item).
        from . import signals  # noqa: F401
