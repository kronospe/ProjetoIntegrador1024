from django.urls import path
from . import views

app_name = "entidades"

urlpatterns = [
    path('', views.home, name='home'),
    path('itens/', views.lista_itensPerdidos, name='lista_itens'),
    path('itens/<int:pk>/', views.detalhe_item, name='detalhe_item'),
    path('itens/cadastrar/', views.cadastrar_item, name='cadastrar_item'),
    path('itens/<int:pk>/editar/', views.editar_item, name='editar_item'),
    path('itens/<int:pk>/excluir/', views.excluir_item, name='excluir_item'),
    path('itens/<int:pk>/reivindicar/', views.reivindicar_item, name='reivindicar_item'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('cadastro/', views.cadastro_view, name='cadastro'),
    path('perfil/', views.perfil_view, name='perfil'),
    path('chatbot/', views.chatbot_view, name='chatbot'),
]