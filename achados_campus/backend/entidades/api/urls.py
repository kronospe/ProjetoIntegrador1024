from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from . import views

urlpatterns = [
    path('auth/cadastro/', views.CadastroView.as_view(), name='api_cadastro'),
    path('auth/login/', views.LoginView.as_view(), name='api_login'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='api_refresh'),
    path('perfil/', views.PerfilView.as_view(), name='api_perfil'),
    path('opcoes/', views.OpcoesView.as_view(), name='api_opcoes'),
    path('itens/', views.ItemListCreateView.as_view(), name='api_itens'),
    path('itens/<int:pk>/', views.ItemDetailView.as_view(), name='api_item'),
    path('itens/<int:pk>/reivindicar/', views.ReivindicarView.as_view(), name='api_reivindicar'),
    path('itens/<int:pk>/decidir/', views.DecidirReivindicacaoView.as_view(), name='api_decidir'),
    path('chatbot/', views.ChatbotView.as_view(), name='api_chatbot'),
]
