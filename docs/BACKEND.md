# Backend Strategy

## Estado atual

O projeto atual continua sendo um jogo local e offline em Godot. Não há backend em execução, não há banco de dados, não há autenticação e não há API pública implementada.

Isso é consistente com a arquitetura segura e com a ideia de evoluir um jogo de combate local antes de adicionar a camada online.

## Arquitetura futura esperada

A arquitetura desejada, quando o projeto crescer para partidas online ou persistência compartilhada, segue a estrutura:

```text
Godot Android
      │
      │ HTTPS / WSS
      ▼
Backend / API
      │
      ▼
PostgreSQL
```

A regra principal é simples: o cliente nunca acessa diretamente o PostgreSQL.

## O que está preparado

- Documentação de segurança em [docs/security/README.md](docs/security/README.md)
- Conceito de autoridade do servidor em [docs/security/SECURITY_ARCHITECTURE.md](docs/security/SECURITY_ARCHITECTURE.md)
- Separação proposta para autenticação, perfis, inventário e partidas em futuras fases

## O que não foi implementado

- Autenticação real
- Inventário persistente
- Loja digital
- Economia e progressão online
- Ranking competitivo
- API de partidas
- Prisma, ORM ou PostgreSQL em uso

## Recomendação

A próxima etapa, quando houver necessidade real de backend, deve começar por:

1. autenticação e autorização;
2. perfis e partidas;
3. inventário e economia;
4. ranking e recompensas;
5. validação de resultados no servidor.

Cada etapa deve ser testada de forma real antes de adicionar a próxima camada.

## Conclusão

O projeto está correto ao manter o backend ausente no momento, preservando a jogabilidade local e a segurança do cliente. O backend é uma evolução futura, não uma dependência atual.
