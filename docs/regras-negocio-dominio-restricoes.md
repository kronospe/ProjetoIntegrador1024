# Regras de Negócio, Requisitos de Domínio e Restrições

## Regras de negócio (RN)
| ID | Regra | Origem |
|---|---|---|
| RN-01 | Dados de comprovação só podem ser vistos pelo responsável pelo objeto e pela operação, nunca publicamente. | UC-04 / RNF-04 |
| RN-02 | Somente dados relacionados ao objeto podem ser pedidos como comprovação. | UC-04 / RD-01 |
| RN-03 | Toda solicitação nasce com status `PENDENTE`. | UC-04 / RF-07 |
| RN-04 | O responsável pelo cadastro deve ser notificado a cada nova solicitação. | UC-04 / RF-08 |
| RN-05 ‡ | Objeto `ENCONTRADO` exige ao menos uma foto. | RF-01 |
| RN-06 ‡ | Só é possível solicitar devolução de objeto com status `ENCONTRADO`; com solicitação em análise, o objeto fica `EM_DEVOLUCAO` e indisponível. | UC-04 (A2) |
| RN-07 ‡ | Descrição, categoria, local e data são obrigatórios no cadastro de objeto. | RF-01, RF-02 |
| RN-08 ‡ | Apenas o cadastrante do objeto ou a operação podem aprovar/rejeitar solicitações. | RF-10 |
| RN-09 ‡ | Solicitação rejeitada ou cancelada devolve o objeto ao status `ENCONTRADO`. | Diagrama de estados |
| RN-10 ‡ | O contato do cadastrante só é liberado ao solicitante após aprovação. | RNF-04 |

## Requisitos de domínio (RD)
| ID | Requisito |
|---|---|
| RD-01 | Minimização de dados: coletar apenas dados pessoais necessários (alinhado à LGPD). Justificar a coleta de `matricula`. |
| RD-02 | Dados de contato e de comprovação são dados pessoais e só trafegam entre as partes autorizadas. |
| RD-03 ‡ | O domínio distingue dois papéis que um mesmo usuário alterna: quem perdeu e quem encontrou. |

## Restrições (RS)
| ID | Restrição | Origem |
|---|---|---|
| RS-01 | Equipe de 2 pessoas e prazo de um semestre. | ADR-0001 |
| RS-02 | Backend como monólito modular com API REST. | ADR-0001 |
| RS-03 | PostgreSQL como banco principal; fotos em object storage, só a URL no banco. | ADR-0002 |
| RS-04 | Aplicativo mobile para Android/iOS (Flutter sugerido). | arquitetura.md |
| RS-05 | Entrega exclusivamente via GitHub, com histórico de commits de todos os integrantes. | Enunciado |

‡ = derivado; validar com o grupo.
