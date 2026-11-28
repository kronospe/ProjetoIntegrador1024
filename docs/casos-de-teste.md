# Casos de Teste

Colunas **Resultado** e **Evidência** são preenchidas na execução.

| ID | RF | Pré-condição | Passos | Resultado esperado | Resultado | Evidência |
|---|---|---|---|---|---|---|
| CT-01 | RF-01 | Logado | Cadastrar encontrado com todos os campos e 1 foto | 201; status ENCONTRADO; aparece na lista | | |
| CT-02 | RF-01 | Logado | Cadastrar sem descrição ou local | 422 com campos pendentes; nada salvo | | |
| CT-03 | RF-01 | Logado | Cadastrar sem foto | 422; nada salvo (RN-05) | | |
| CT-04 | RF-02 | Logado | Cadastrar perdido completo | 201; status PERDIDO | | |
| CT-05 | RF-02 | Logado | Cadastrar perdido sem local | 422; nada salvo | | |
| CT-06 | RF-03 | 5.000 objetos | Abrir listagem | Lista paginada com foto, descrição, local, data, status | | |
| CT-07 | RF-03 | Objeto existente | Abrir detalhe | Dados do objeto sem contato do cadastrante | | |
| CT-08 | RF-04 | Objeto ENCONTRADO | Solicitar com comprovação | 201; solicitação PENDENTE; objeto EM_DEVOLUCAO | | |
| CT-09 | RF-04 | Objeto ENCONTRADO | Solicitar sem comprovação | 422; nada registrado; objeto inalterado | | |
| CT-10 | RF-04 | Objeto EM_DEVOLUCAO | Solicitar | 409 objeto indisponível | | |
| CT-11 | RF-04 | Objeto ENCONTRADO | Falha forçada ao salvar o objeto | Transação revertida: nenhuma solicitação gravada | | |
| CT-12 | RF-05 | Objetos com "mochila" | Pesquisar "mochila" | Só correspondentes | | |
| CT-13 | RF-05 | Qualquer | Pesquisar termo inexistente | Mensagem de nenhum resultado + sugestão | | |
| CT-14 | RF-06 | Objetos "eletrônicos" | Filtrar categoria = eletrônicos | Só dessa categoria | | |
| CT-15 | RF-06 | Dados variados | Combinar categoria + local + data | Interseção correta | | |
| CT-16 | RF-07 | Solicitação criada | Solicitante abre "Minhas solicitações" | Vê status PENDENTE | | |
| CT-17 | RF-07 | Solicitação de outro usuário | Terceiro tenta ler | 403 | | |
| CT-18 | RF-08 | Push mock ativo | Criar solicitação | Evento enviado ao responsável | | |
| CT-19 | RF-08 | Push mock fora do ar | Criar solicitação | Solicitação PENDENTE mantida; notificação FALHA e reenviada | | |
| CT-20 | RF-09 | Usuário cadastrado | Login válido | 200 + token | | |
| CT-21 | RF-09 | — | Login com senha errada | 401 sem revelar o campo | | |
| CT-22 | RF-09 | — | `GET /objetos` sem token | 401 | | |
| CT-23 | RF-10 | Solicitação PENDENTE | Cadastrante aprova | APROVADA; objeto DEVOLVIDO; contato liberado | | |
| CT-24 | RF-10 | Solicitação PENDENTE | Cadastrante rejeita | REJEITADA; objeto volta a ENCONTRADO | | |
| CT-25 | RF-10 | Solicitação PENDENTE | Usuário não responsável tenta aprovar | 403 | | |
| CT-NF-01 | RNF-01 | 5.000 objetos | k6 em `GET /objetos` | p95 ≤ 2 s | | |
| CT-NF-02 | RNF-02 | Em produção/teste | Monitor em `/saude` por 30 dias | ≥ 99% | | |
| CT-NF-03 | RNF-03 | — | Rampa de 10 a 50 req/s | p95 ≤ 2 s a 50 req/s | | |
| CT-NF-04 | RNF-04 | — | Chamar todos os endpoints sem token | 401 (exceto login/cadastro) | | |
| CT-NF-05 | RNF-04 | — | Varredura OWASP ZAP | 0 alto/crítico | | |
| CT-NF-06 | RNF-05 | 5 participantes | Cronometrar cadastro de encontrado | ≥ 90% concluem em ≤ 60 s | | |
| CT-NF-07 | RNF-06 | Código pronto | Cobertura + análise de dependências | ≥ 70% nas regras; sem ciclos | | |
| CT-NF-08 | RNF-07 | App compilado | Rodar em Android e iOS; `docker run` do backend | Funciona nos dois | | |
| CT-NF-09 | RNF-08 | Backup existente | Restaurar em banco limpo | Dados íntegros | | |
