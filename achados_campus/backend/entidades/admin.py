from django.contrib import admin

# Register your models here.
from django.contrib import admin
from .models import Aluno, Item, Reivindicacao

admin.site.register(Aluno)
admin.site.register(Item)
admin.site.register(Reivindicacao)