# Requisitos Não Funcionais — Campus Achados Mobile Edition

Associados às características da ISO/IEC 25010. RNF-01 a RNF-05 vêm de `arquitetura.md`; **RNF-06 a RNF-08 são propostas** (cobrem manutenibilidade, portabilidade e recuperabilidade pedidas na atividade) e devem ser validadas pelo grupo.

| ID | Requisito | ISO/IEC 25010 | Métrica | Verificação | Prioridade |
|---|---|---|---|---|---|
| RNF-01 | Desempenho | Eficiência de desempenho (comportamento temporal) | Listagem e busca com p95 ≤ 2 s com 5.000 objetos, em 4G | Teste de carga k6/JMeter em `GET /objetos` | Could (backlog) |
| RNF-02 | Disponibilidade | Confiabilidade (disponibilidade) | ≥ 99% de uptime mensal | Health check `/saude` a cada minuto | Should (backlog) |
| RNF-03 | Escalabilidade | Eficiência de desempenho (capacidade) | 500 a 5.000 usuários ativos; p95 ≤ 2 s a 50 req/s | Rampa de carga 10 a 50 req/s | Won't no MVP (requisito futuro) |
| RNF-04 | Segurança e privacidade | Segurança (confidencialidade, autenticidade) | 100% dos endpoints (exceto login/cadastro) exigem autenticação; senhas com bcrypt; contato só após aprovação; 0 vulnerabilidades altas/críticas | Teste de acesso sem token (401) + OWASP ZAP | Must |
| RNF-05 | Usabilidade | Usabilidade (operabilidade) | Cadastro de objeto encontrado ≤ 60 s para ≥ 90% de 5 participantes | Teste de usabilidade cronometrado | Should |
| RNF-06 | Manutenibilidade | Manutenibilidade (modularidade, testabilidade) | Módulos sem dependência cíclica; cobertura de testes unitários ≥ 70% nas regras de negócio | Análise estática (lint/dependency-cruiser) + relatório de cobertura | Should |
| RNF-07 | Portabilidade | Portabilidade (adaptabilidade, instalabilidade) | App roda em Android e iOS a partir de uma base de código; backend em contêiner executável em qualquer provedor | Execução em um dispositivo de cada plataforma; `docker run` do backend | Should |
| RNF-08 | Recuperabilidade | Confiabilidade (recuperabilidade, tolerância a falhas) | Backup diário do banco, restauração testada; notificações com falha reenviadas em até 3 tentativas | Teste de restauração; teste com serviço de push simulado fora do ar | Should |

> **Atenção:** no backlog, Desempenho, Disponibilidade e Escalabilidade estão como Could/Should/Won't, mas `arquitetura.md` os trata como os três atributos mais críticos. Explique no relatório que o backlog prioriza *entrega de funcionalidade no MVP*, enquanto a arquitetura já *prepara* a solução para atender esses atributos.
