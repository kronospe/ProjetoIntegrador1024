# Matriz de Rastreabilidade

Liga requisito → história → modelagem → implementação → teste. A coluna **Código** deve ser preenchida com os caminhos reais em `/src` conforme o desenvolvimento avança.

| RF | US | Caso de uso / diagrama | Entidades (modelo/DER) | Endpoint API | Módulo | Código (`/src`) | Casos de teste |
|---|---|---|---|---|---|---|---|
| RF-01 | US-01 | 01-casos-de-uso; 05-estados | Objeto, Foto, Categoria, Local | `POST /objetos` | Objetos | _a preencher_ | CT-01 a CT-03 |
| RF-02 | US-05 | 01-casos-de-uso; 05-estados | Objeto, Categoria, Local | `POST /objetos` | Objetos | _a preencher_ | CT-04, CT-05 |
| RF-03 | US-02 | 01-casos-de-uso | Objeto, Foto | `GET /objetos`, `GET /objetos/{id}` | Objetos | _a preencher_ | CT-06, CT-07 |
| RF-04 | US-04 | UC-04; 04-sequência; 05-estados | SolicitacaoDevolucao, InformacaoComprovacao, Objeto | `POST /solicitacoes` | Devoluções | _a preencher_ | CT-08 a CT-11 |
| RF-05 | US-03 | 01-casos-de-uso | Objeto | `GET /objetos?q=` | Busca | _a preencher_ | CT-12, CT-13 |
| RF-06 | US-03 | 01-casos-de-uso | Objeto, Categoria, Local | `GET /objetos?categoria=&local=&data=` | Busca | _a preencher_ | CT-14, CT-15 |
| RF-07 | US-04 | UC-04; 05-estados | SolicitacaoDevolucao | `GET /solicitacoes` | Devoluções | _a preencher_ | CT-16, CT-17 |
| RF-08 | US-08 | UC-04 (E2); 04-sequência | Notificacao | evento interno → push | Notificações | _a preencher_ | CT-18, CT-19 |
| RF-09 | US-06 | 01-casos-de-uso | Usuario | `POST /auth/login`, `POST /auth/cadastro` | Autenticação | _a preencher_ | CT-20 a CT-22 |
| RF-10 | US-07 | 01-casos-de-uso; 05-estados | SolicitacaoDevolucao, Objeto | `PATCH /solicitacoes/{id}` | Devoluções | _a preencher_ | CT-23 a CT-25 |

| RNF | Decisão arquitetural | Verificação (teste) |
|---|---|---|
| RNF-01 | ADR-0001, ADR-0002 (índices + full-text) | CT-NF-01 |
| RNF-02 | ADR-0001 (stateless, várias instâncias) | CT-NF-02 |
| RNF-03 | ADR-0001 (escala horizontal) | CT-NF-03 |
| RNF-04 | Autenticação central; RN-10 | CT-NF-04, CT-NF-05 |
| RNF-05 | API sob medida para o app | CT-NF-06 |
| RNF-06 | Monólito modular | CT-NF-07 |
| RNF-07 | Flutter; contêiner | CT-NF-08 |
| RNF-08 | Backup; reenvio de notificação | CT-NF-09, CT-19 |
