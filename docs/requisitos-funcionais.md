# Requisitos Funcionais — Campus Achados Mobile Edition

**Convenção:** IDs `RF-xx` (mesmos usados nos diagramas UML). Prioridade MoSCoW conforme o backlog.
**Origem:** RF-01 a RF-05 vêm do backlog; RF-06 a RF-10 foram **derivados** dos diagramas e do UC-04 (marcados com ‡) e precisam ser validados pelo grupo.

| ID | Nome | Prioridade | História |
|---|---|---|---|
| RF-01 | Cadastrar objeto encontrado | Must | US-01 |
| RF-02 | Cadastrar objeto perdido | Must | US-05 |
| RF-03 | Consultar objetos | Must | US-02 |
| RF-04 | Solicitar devolução | Must | US-04 |
| RF-05 | Pesquisar por palavra-chave | Should | US-03 |
| RF-06 | Filtrar por categoria, local e data | Should | US-03 |
| RF-07 ‡ | Registrar e acompanhar status das solicitações | Must | US-04 |
| RF-08 ‡ | Notificar o responsável pelo cadastro | Could | US-08 |
| RF-09 ‡ | Autenticar usuário | Must | US-06 |
| RF-10 ‡ | Analisar solicitação de devolução (aprovar/rejeitar) | Must | US-07 |

---

## RF-01 — Cadastrar objeto encontrado (Must)
**Descrição:** o usuário que encontrou um item o cadastra informando descrição, categoria, local, data e ao menos uma foto. O objeto é salvo com status `ENCONTRADO`.
**Critérios de aceite:**
- Dado que estou logado e na tela de cadastro, quando preencho descrição, categoria, local, data, anexo ≥ 1 foto e confirmo, então o objeto é salvo com status "encontrado" e aparece na lista de consulta.
- Dado que deixo "descrição" ou "local" em branco, quando confirmo, então o sistema indica os campos pendentes e não salva.
- Dado que não anexo nenhuma foto, quando confirmo, então o cadastro é recusado (RN-05).

## RF-02 — Cadastrar objeto perdido (Must)
**Descrição:** o usuário que perdeu um item o registra para que outros o identifiquem. Status inicial `PERDIDO`.
**Critérios de aceite:**
- Dado que estou logado, quando informo descrição, categoria, local e data e confirmo, então o objeto é salvo com status "perdido" e aparece na consulta.
- Dado que deixo descrição ou local em branco, então o sistema indica os campos obrigatórios e não salva.

## RF-03 — Consultar objetos (Must)
**Descrição:** listagem paginada de objetos perdidos e encontrados, com acesso ao detalhe.
**Critérios de aceite:**
- Dado que estou logado, quando abro a consulta, então vejo a lista paginada com foto, descrição, local, data e status.
- Dado que seleciono um objeto, então vejo o detalhe, sem exibir contato do cadastrante (RN-01/RD-02).
- A listagem responde com p95 ≤ 2 s (RNF-01).

## RF-04 — Solicitar devolução (Must)
**Descrição:** o usuário que reconhece um objeto `ENCONTRADO` envia dados de comprovação de posse. Detalhado no UC-04.
**Critérios de aceite:**
- Dado que visualizo um objeto "encontrado", quando informo a comprovação e confirmo, então a solicitação é registrada como "pendente", o objeto passa a `EM_DEVOLUCAO` e o responsável é notificado.
- Dado que confirmo sem comprovação, então o sistema pede o preenchimento e não registra nada.
- Dado que o objeto já não está `ENCONTRADO`, então o sistema informa indisponibilidade.

## RF-05 — Pesquisar por palavra-chave (Should)
**Critérios de aceite:**
- Dado que pesquiso uma palavra presente na descrição de objetos, então a lista exibe somente os correspondentes.
- Dado que a palavra não corresponde a nada, então o sistema informa "nenhum resultado" e sugere ajustar filtros ou termos.

## RF-06 — Filtrar por categoria, local e data (Should)
**Critérios de aceite:**
- Dado que existem objetos na categoria "eletrônicos", quando filtro por ela, então só objetos dessa categoria são exibidos.
- Filtros combináveis (categoria + local + data + palavra-chave) devolvem a interseção.

## RF-07 ‡ — Registrar e acompanhar status das solicitações (Must)
**Descrição:** toda solicitação nasce `PENDENTE` (RN-03) e seu status pode ser acompanhado pelo solicitante, pelo cadastrante e pela operação.
**Critérios de aceite:**
- Dado que criei uma solicitação, quando abro "Minhas solicitações", então vejo o status atual.
- Dado que sou o responsável pelo objeto ou da operação, então vejo as solicitações recebidas; terceiros não as veem (RN-01).

## RF-08 ‡ — Notificar o responsável pelo cadastro (Could)
**Descrição:** a cada nova solicitação, o responsável recebe push. Falha no envio não impede a solicitação (UC-04, E2); a notificação fica registrada para reenvio.
**Critérios de aceite:**
- Dada uma nova solicitação, então um evento é enviado ao serviço de notificações com destinatário e id da solicitação.
- Dado que o serviço está indisponível, então a solicitação permanece `PENDENTE` e a notificação é reenviada depois.

## RF-09 ‡ — Autenticar usuário (Must)
**Critérios de aceite:**
- Dado credenciais válidas, então o sistema emite token de acesso.
- Dado credenciais inválidas, então retorna erro sem revelar qual campo falhou.
- Dado requisição sem token a endpoint protegido, então retorna 401.

## RF-10 ‡ — Analisar solicitação de devolução (Must)
**Descrição:** o cadastrante do objeto (ou a operação) aprova ou rejeita a solicitação com base na comprovação.
**Critérios de aceite:**
- Ao aprovar e confirmar a entrega, a solicitação vai a `APROVADA` e o objeto a `DEVOLVIDO`; só então o contato é liberado ao solicitante (RD-02).
- Ao rejeitar, a solicitação vai a `REJEITADA` e o objeto volta a `ENCONTRADO`.
- Usuário que não é o responsável nem da operação recebe 403.
