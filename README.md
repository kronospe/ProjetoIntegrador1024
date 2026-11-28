# CampusAchados — Django (API) + Flutter

```
achados_campus/
├── backend/   Django 6 + Django REST Framework + JWT (o site antigo continua funcionando)
└── mobile/    App Flutter (Android / iOS / web)
```

## 1. Backend

```bash
cd backend
python -m venv .venv && source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env          # ajuste SECRET_KEY (e o Postgres, se quiser)
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
python manage.py test         # 33 testes (API + site)
```

Sem as variáveis `DB_*` o projeto usa SQLite, ótimo para desenvolvimento.
Com `DB_NAME` preenchido, usa o PostgreSQL como antes.

### Endpoints (`/api/`)

| Método | Rota | Descrição |
|---|---|---|
| POST | `auth/cadastro/` | `{nome, email, senha, confirmar_senha}` → tokens + usuário |
| POST | `auth/login/` | `{email, senha}` → `{access, refresh, usuario}` |
| POST | `auth/refresh/` | `{refresh}` → novo `access` |
| GET/PUT | `perfil/` | perfil do aluno (nome, email, telefone, matrícula, curso, avatar, bio) |
| GET | `opcoes/` | cursos, locais, situações, ícones, sugestões do chatbot |
| GET | `itens/` | `?q=&situacao=&local=&status=&meus=1&page=` (paginado, público) |
| POST | `itens/` | multipart: nome, descricao, local, situacao_item, icone, data_encontro, foto |
| GET/PATCH/DELETE | `itens/<id>/` | detalhe / editar / excluir (só dono ou staff) |
| POST | `itens/<id>/reivindicar/` | `{descricao_prova}` |
| POST | `itens/<id>/decidir/` | `{decisao: "aprovada" \| "recusada"}` (só dono ou staff) |
| POST | `chatbot/` | `{mensagem}` → `{resposta}` |

Autenticação: header `Authorization: Bearer <access>`.

### Regras compartilhadas (`entidades/services.py`)
Site e API usam as mesmas funções para login, perfil e reivindicações
(`autenticar`, `erros_perfil`/`salvar_perfil`, `criar_reivindicacao`, `decidir_reivindicacao`),
então uma regra só existe em um lugar. As fotos passam por `entidades/imagens.py`
(valida o conteúdo, corrige a rotação, limita a 1280 px e converte para JPEG).

### Reivindicações
`Reivindicacao.item` agora é `ForeignKey`: uma reivindicação **recusada** fica no histórico e o item
pode ser reivindicado de novo. Só pode existir **uma ativa** (pendente ou aprovada) por item
(constraint no banco). Depois de atualizar, rode `python manage.py migrate`.

### O que mudou no backend
- `settings.py`: `SECRET_KEY`, `DEBUG` e `ALLOWED_HOSTS` vêm do ambiente; DRF, JWT e CORS configurados.
- `apps.py` agora registra os signals (antes `signals.py` nunca era carregado).
- Chatbot movido para `entidades/chatbot.py` (usa `rapidfuzz`); o site antigo também usa esse módulo.
- `requirements.txt` limpo (saíram `pywin32`, `selenium`, `playsound3`, `google-genai`...).
- Regras novas na API: aprovar/recusar reivindicação pelo app, `status` do item só muda por reivindicação,
  a prova só aparece para dono, requerente e staff, e o telefone da outra parte é liberado após aprovada.
- Migração `0006` gerada para o campo `icone` (já estava pendente no repositório).

## 2. App Flutter

Pré-requisito: Flutter 3.22+ (Dart 3.4+).

```bash
cd mobile
flutter create . --project-name achados_campus --org br.edu.campus   # gera android/ ios/ web/
flutter pub get
flutter run                                   # emulador Android: usa http://10.0.2.2:8000
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000   # celular físico (IP do seu PC)
```

### Ajustes de plataforma (depois do `flutter create .`)

**Android** — `android/app/src/main/AndroidManifest.xml`, na tag `<application>` (apenas em desenvolvimento, para HTTP sem TLS):
```xml
android:usesCleartextTraffic="true"
```
Em produção use HTTPS e remova isso.

**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key><string>Para fotografar o item.</string>
<key>NSPhotoLibraryUsageDescription</key><string>Para escolher a foto do item.</string>
<key>NSAppTransportSecurity</key><dict><key>NSAllowsLocalNetworking</key><true/></dict>
```

**Web** (`flutter run -d chrome`): defina `CORS_ALLOWED_ORIGINS` no `.env` do backend ou deixe `DEBUG=True`.

### Estrutura do app
```
lib/
├── main.dart, router.dart        (go_router + redirecionamento por login)
├── core/                         (tema, config da URL, formatação)
├── models/                       (Usuario, Item, Reivindicacao, Opcoes)
├── services/                     (Dio + JWT com refresh automático, Api, token seguro)
├── state/providers.dart          (Riverpod: auth, api, opções)
├── screens/                      (login, cadastro, itens, detalhe, formulário, reivindicar, perfil, assistente)
└── widgets/common.dart           (cards, tags, campos, ícones)
```
