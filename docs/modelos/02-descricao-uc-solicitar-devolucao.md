# UC-04 — Solicitar devolução

**Projeto:** Campus Achados Mobile Edition

## Identificação

| Campo | Conteúdo |
|---|---|
| **ID / Nome** | UC-04 — Solicitar devolução |
| **Justificativa da criticidade** | Conclui o objetivo do produto (devolver o objeto ao dono, meta de 80% de recuperação) e concentra as regras sensíveis de proteção de dados (RNF-04, RD-01). |
| **Ator principal** | Usuário que perdeu |
| **Atores secundários** | Serviço de Notificações (sistema externo); Usuário que encontrou (responsável pelo cadastro do objeto, destinatário da notificação) |
| **Requisitos relacionados** | RF-04, RF-07, RF-08, RNF-04, RD-01 |
| **História de usuário** | US-04 |
| **Prioridade** | Must |

## Pré-condições

- O usuário está autenticado.
- O objeto existe e possui status `ENCONTRADO`.

## Gatilho

O usuário visualiza o detalhe de um objeto encontrado e seleciona a opção "Solicitar devolução".

## Fluxo principal

1. O usuário abre o detalhe de um objeto com status "encontrado".
2. O sistema exibe o formulário de comprovação de posse.
3. O usuário informa os dados de comprovação (por exemplo: características não visíveis na foto, marcas, conteúdo do objeto).
4. O usuário confirma a solicitação.
5. O sistema valida que há informações de comprovação.
6. O sistema registra a solicitação com status `PENDENTE`.
7. O sistema atualiza o status do objeto para `EM_DEVOLUCAO`.
8. O sistema envia um evento ao Serviço de Notificações para avisar o responsável pelo cadastro do objeto.
9. O sistema confirma ao usuário que a solicitação foi registrada.

## Fluxos alternativos

**A1 — Usuário não autenticado (no passo 1)**
1. O sistema redireciona o usuário para a tela de login.
2. Após autenticar-se, o fluxo retorna ao passo 1.

**A2 — Objeto indisponível (no passo 1 ou 5)**
1. O objeto deixou de estar com status `ENCONTRADO` (por exemplo, já existe uma solicitação em análise).
2. O sistema informa que o objeto não está disponível para solicitação e encerra o caso de uso.

## Fluxos de exceção

**E1 — Comprovação não informada (no passo 5)**
1. O usuário confirma a solicitação sem preencher as informações de comprovação.
2. O sistema solicita o preenchimento das informações.
3. Nenhuma solicitação é registrada. O fluxo retorna ao passo 3.

**E2 — Serviço de Notificações indisponível (no passo 8)**
1. O sistema não consegue enviar a notificação (erro ou timeout).
2. A solicitação permanece registrada como `PENDENTE`.
3. O sistema registra a notificação para reenvio posterior.
4. O fluxo segue para o passo 9.

## Pós-condições

- **Sucesso:** a solicitação está salva com status `PENDENTE`; o objeto está com status `EM_DEVOLUCAO`; o responsável pelo cadastro foi notificado (ou a notificação está agendada para reenvio).
- **Falha:** nenhuma solicitação é registrada e o status do objeto permanece inalterado.

## Regras de negócio

- **RN-01:** os dados de comprovação só podem ser vistos pelo responsável pelo objeto e pela operação, nunca publicamente (RNF-04).
- **RN-02:** somente dados relacionados ao objeto podem ser solicitados como comprovação; dados pessoais desnecessários não devem ser coletados (RD-01).
- **RN-03:** uma solicitação nasce sempre com status `PENDENTE` (RF-07).
- **RN-04:** o responsável pelo cadastro do objeto deve ser notificado a cada nova solicitação (RF-08).

## Critérios de aceite (US-04)

- **Cenário feliz:** dado que estou logado e visualizo um objeto com status "encontrado", quando informo os dados de comprovação e confirmo a solicitação, então o sistema registra a solicitação com status "pendente" e notifica o responsável pelo objeto.
- **Cenário de exceção:** dado que estou visualizando um objeto encontrado, quando tento solicitar a devolução sem informações de comprovação, então o sistema solicita o preenchimento das informações e não registra a solicitação.
