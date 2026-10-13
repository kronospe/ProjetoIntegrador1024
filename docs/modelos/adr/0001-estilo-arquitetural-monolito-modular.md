# ADR-0001 — Adotar monólito modular com API REST

- **Status:** Aceito
- **Data:** 2026-10-12
- **Decisores:** Arthur Henrique Souza Barros, Guilherme Pereira dos Santos
- **Atributos relacionados:** Desempenho, Disponibilidade, Escalabilidade, Segurança

## Contexto

O Campus Achados precisa de um backend que atenda o aplicativo mobile com cadastro de objetos, consulta, pesquisa com filtros e solicitação de devolução. Os atributos mais críticos são desempenho (p95 ≤ 2 s), disponibilidade (≥ 99% mensal) e escalabilidade (de 500 a 5.000 usuários ativos).

As restrições do projeto são:

- Time de duas pessoas, com prazo de um semestre.
- Volume de uso moderado e previsível (comunidade de um campus).
- Pouca experiência prévia do grupo com infraestrutura distribuída.
- Necessidade de entregar o MVP (itens Must Have) rapidamente.

## Decisão

Adotar um **monólito modular**: uma única aplicação backend, implantável como uma unidade, organizada internamente em módulos com fronteiras bem definidas (Autenticação, Objetos, Busca, Devoluções, Notificações), exposta ao app por **API REST** (HTTPS/JSON).

A aplicação será *stateless* (autenticação por token, fotos em armazenamento externo), para permitir escala horizontal com várias instâncias atrás de um balanceador.

## Alternativas consideradas

### 1. Microsserviços

Cada módulo seria um serviço independente, com seu próprio banco e comunicação por rede.

- **Prós:** escala e implantação independentes por serviço; isolamento de falhas.
- **Contras:** exige orquestração, descoberta de serviços, observabilidade distribuída e tratamento de consistência entre serviços. Cada chamada interna vira uma chamada de rede, o que prejudica a latência.
- **Motivo do descarte:** o custo operacional é desproporcional para um time de duas pessoas e para a meta de 5.000 usuários. A complexidade consumiria o prazo do MVP sem trazer ganho mensurável nos atributos críticos.

### 2. Serverless (funções em nuvem, ex.: AWS Lambda ou Cloud Functions)

Cada operação seria uma função acionada sob demanda, sem servidor gerenciado.

- **Prós:** escala automática e pagamento por uso; sem gestão de servidores.
- **Contras:** *cold start* pode estourar o limite de 2 s nas primeiras chamadas após ociosidade. Há dependência forte do provedor, e depuração e testes locais são mais difíceis. O modelo de conexões com banco relacional exige cuidado extra.
- **Motivo do descarte:** o risco de latência variável conflita com a métrica de desempenho, e a dependência do provedor reduz a portabilidade do projeto acadêmico.

### 3. Monólito sem modularização (camadas misturadas)

Uma única aplicação, sem fronteiras internas entre os domínios.

- **Prós:** é o mais rápido de começar.
- **Contras:** o acoplamento cresce rápido, dificultando manutenção e testes, e impedindo extrair partes no futuro.
- **Motivo do descarte:** a modularização custa pouco no início e preserva a opção de evoluir para serviços separados se o uso crescer.

## Consequências

**Positivas**

- Menos componentes para operar e monitorar, favorecendo a disponibilidade.
- Chamadas internas em processo, sem latência de rede, favorecendo o desempenho.
- Ponto único de entrada, o que facilita aplicar autenticação e validação uniformes (segurança).
- Desenvolvimento, teste e implantação simples para o tamanho do time.
- Os módulos podem ser extraídos como serviços no futuro, caso o volume exija.

**Negativas / riscos**

- O monólito escala como um todo: se só a busca for gargalo, será preciso replicar a aplicação inteira.
- Uma falha grave na aplicação pode derrubar todas as funções ao mesmo tempo (mitigação: múltiplas instâncias e health check).
- Exige disciplina para manter as fronteiras dos módulos e evitar acoplamento indevido.

## Revisão

Reavaliar esta decisão se a carga ultrapassar 5.000 usuários ativos ou se um módulo específico (ex.: Busca) se tornar gargalo recorrente nos testes de carga.
