# Métricas de Qualidade Adotadas

| Métrica | Meta | Fonte | Associada a |
|---|---|---|---|
| Latência p95 de listagem/busca | ≤ 2 s (5.000 objetos, 4G) | k6 | RNF-01 |
| Uptime mensal | ≥ 99% | Monitor `/saude` | RNF-02 |
| p95 a 50 req/s | ≤ 2 s | k6 (rampa) | RNF-03 |
| Endpoints protegidos sem token | 100% retornam 401 | Teste automatizado | RNF-04 |
| Vulnerabilidades altas/críticas | 0 | OWASP ZAP | RNF-04 |
| Tempo de cadastro de objeto encontrado | ≤ 60 s para ≥ 90% | Teste de usabilidade | RNF-05 |
| Cobertura de testes (regras de negócio) | ≥ 70% | Jest `--coverage` | RNF-06 |
| Casos de teste Must aprovados | 100% | `casos-de-teste.md` | Todos os Must |
| Defeitos críticos abertos na entrega | 0 | Issues do GitHub | Qualidade geral |
