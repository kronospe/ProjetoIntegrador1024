# ADR-0002 — Usar PostgreSQL como banco de dados principal

- **Status:** Aceito
- **Data:** 2026-10-12
- **Decisores:** Arthur Henrique Souza Barros, Guilherme Pereira dos Santos
- **Atributos relacionados:** Desempenho, Segurança, Escalabilidade

## Contexto

O sistema armazena usuários, objetos (perdidos e encontrados) e solicitações de devolução. Esses dados têm relações claras entre si: um objeto pertence a quem o cadastrou, e uma solicitação liga um objeto a um solicitante. As consultas mais frequentes combinam filtros por categoria, local, data e palavra-chave, e precisam responder com p95 ≤ 2 s.

Há também regras de integridade importantes: uma solicitação de devolução não pode existir sem um objeto, e o status do objeto precisa mudar de forma consistente quando a devolução é aprovada.

## Decisão

Usar **PostgreSQL** como banco de dados principal, em instância gerenciada, com backup automático. Serão criados índices nas colunas de categoria, local e data, e busca textual (*full-text search*) nativa do PostgreSQL para a palavra-chave. As fotos **não** ficam no banco: são guardadas em armazenamento de objetos, e o banco guarda apenas a referência (URL).

## Alternativas consideradas

### 1. MongoDB (banco de documentos)

- **Prós:** esquema flexível; modelo de documento simples para um objeto com atributos variáveis.
- **Contras:** as relações entre usuário, objeto e solicitação ficam por conta da aplicação, sem integridade referencial. Transações multi-documento são possíveis, mas menos naturais para o fluxo de aprovação da devolução. O time tem menos familiaridade com consultas combinadas nesse modelo.
- **Motivo do descarte:** o domínio é naturalmente relacional e a integridade entre devolução e objeto é requisito de segurança. O ganho de flexibilidade de esquema não compensa.

### 2. Firebase / Firestore (BaaS)

- **Prós:** integração rápida com apps mobile, autenticação e push embutidos, pouco código de backend.
- **Contras:** consultas com múltiplos filtros combinados são limitadas e exigem índices compostos pré-definidos. Há forte dependência do fornecedor e custo imprevisível por leitura conforme o uso cresce. Substituiria a API do backend, conflitando com o [ADR-0001](0001-estilo-arquitetural-monolito-modular.md).
- **Motivo do descarte:** a pesquisa com filtros combinados é central ao produto, e o modelo de custo por leitura é arriscado com crescimento de uso.

### 3. SQLite (banco embarcado em arquivo)

- **Prós:** zero configuração, ótimo para protótipo.
- **Contras:** não suporta bem múltiplas instâncias da API acessando o mesmo banco, o que impede a escala horizontal prevista. Tem limitações de concorrência de escrita.
- **Motivo do descarte:** incompatível com a meta de escalabilidade e disponibilidade (várias instâncias da API).

## Consequências

**Positivas**

- Integridade referencial e transações garantem consistência no fluxo de devolução (segurança).
- Índices e busca textual nativa atendem a meta de p95 ≤ 2 s sem adicionar um motor de busca separado.
- Tecnologia madura, bem documentada e gratuita, com opções de hospedagem gerenciada.
- O mesmo banco atende o MVP e o crescimento até a meta de 5.000 usuários.

**Negativas / riscos**

- Alterações de esquema exigem migrações versionadas e cuidado.
- A busca textual nativa é menos sofisticada que um motor dedicado (ex.: tolerância a erros de digitação). Se a busca virar gargalo, será preciso reavaliar.
- A escrita fica concentrada em uma instância principal; a escala de leitura exigirá réplicas se o volume crescer muito.

## Revisão

Reavaliar se os testes de carga mostrarem p95 de busca acima de 2 s mesmo com índices otimizados, caso em que um motor de busca dedicado (ex.: OpenSearch) pode ser considerado como complemento.
