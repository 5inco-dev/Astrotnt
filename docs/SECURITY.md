# Security

## Estado do projeto

Este projeto é um cliente Godot local e offline, com foco em combate de artilharia por turnos. O estado atual não inclui backend, autenticação, banco de dados, web API ou compras digitais.

Isso reduz o risco de exposição de segredos e de manipulação de dados sensíveis em produção. O cliente continua sendo um ambiente não confiável, e a arquitetura foi documentada com esse princípio desde o início.

## Regras aplicadas no estado atual

- Nenhuma credencial de banco, token ou segredo foi incluída no repositório.
- O jogo não persiste dados sensíveis em arquivos locais.
- Não há armazenamento de senhas em texto puro.
- Não há logs de autenticação ou tokens em produção.
- Não há endpoint de API no cliente nem acesso direto a PostgreSQL.
- O projeto usa dados de jogo e balanceamento no cliente apenas como representação local.

## Riscos futuros e limites

O sistema ainda deve ser tratado como não confiável em qualquer expansão online. Qualquer futuro backend deve seguir a regra de que o servidor é a fonte de verdade para:

- moedas;
- XP;
- inventário;
- recompensas;
- progressão;
- resultado de partidas;
- ranking;
- compras e validações de economia.

O cliente nunca deve decidir ou validar ganhos e perdas de progresso competitivo. Isso deve ser feito no servidor, com validação, idempotência e transações quando aplicável.

## Observação de arquitetura

A documentação de segurança do projeto está em [docs/security/README.md](docs/security/README.md) e em seus arquivos complementares. A estratégia atual é manter o jogo funcional offline e preparar uma arquitetura futura autoritativa, sem inventar endpoints ou simular integração concluída.

## Conclusão

A postura atual é segura para o escopo existente: o jogo é offline, não persiste dados sensíveis e não implementa economia online. A próxima expansão de segurança deve ocorrer somente quando a infraestrutura e a camada de backend forem realmente planejadas e validadas.
