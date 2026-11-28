# Plano de Testes — Campus Achados Mobile Edition

## 1. Objetivo e escopo
Verificar que os requisitos funcionais (RF-01 a RF-10) e não funcionais (RNF-01 a RNF-08) foram atendidos. Fora do escopo: login único institucional (evolução futura).

## 2. Níveis e tipos de teste
| Nível | O que cobre | Ferramenta sugerida |
|---|---|---|
| Unitário | Regras de negócio (RN-05 a RN-09), transições de status | Jest |
| Integração | Módulos + PostgreSQL; fluxo de devolução com transação | Jest + Supertest, banco de teste |
| API / sistema | Endpoints REST, códigos 201/401/403/409/422 | Supertest / Postman |
| Desempenho | RNF-01, RNF-03 | k6 |
| Segurança | RNF-04 | Teste de acesso sem token + OWASP ZAP |
| Usabilidade | RNF-05 | Teste moderado com 5 usuários |
| Disponibilidade | RNF-02 | Monitor de uptime em `/saude` |

## 3. Ambiente
Backend em contêiner, PostgreSQL de teste, 5.000 objetos de massa sintética para carga, serviço de push simulado (mock) para RF-08.

## 4. Critérios de entrada e saída
- **Entrada:** funcionalidade implementada e implantada em ambiente de teste.
- **Saída:** 100% dos casos Must aprovados; ≥ 90% dos Should; nenhum defeito crítico aberto; métricas de `metricas.md` atingidas.

## 5. Papéis
Arthur Henrique Souza Barros e Guilherme Pereira dos Santos: execução e registro cruzado (quem implementa não é o único a testar).

## 6. Evidências
Salvar em `/testes/evidencias/` (prints, logs, relatórios k6/ZAP/cobertura) nomeadas com o ID do caso, ex.: `CT-08-resultado.png`.

## 7. Riscos
Massa de dados insuficiente, falta de dispositivo iOS, instabilidade do serviço de push externo.
