# Changelog

## Update Pack 01

### Estado do pacote

Este pacote foi validado como documentação e auditoria de estado do projeto, com base no código existente e nos testes executados.

### O que foi verificado

- Estrutura real do projeto em Godot 4.x
- Fluxo principal de combate e preparação
- Arquitetura de scripts, cenas, recursos e testes
- Estado de mobile/local e de segurança
- Suítes headless executadas com sucesso

### O que foi preservado

- Combat local por turnos
- Sistema de terreno destrutível
- Loadouts e catálogo de personagens/equipamentos
- HUD, câmera e regras de combate
- Segurança de escopo offline

### O que foi documentado

- Estado de arquitetura em [docs/ARCHITECTURE.md](ARCHITECTURE.md)
- Estado de auditoria em [docs/AUDIT.md](AUDIT.md)
- Estado de gameplay em [docs/GAMEPLAY.md](GAMEPLAY.md)
- Estado de mobile em [docs/MOBILE.md](MOBILE.md)
- Sistema de save em [docs/SAVE_SYSTEM.md](SAVE_SYSTEM.md)
- Política de segurança em [docs/SECURITY.md](SECURITY.md)
- Registro de testes em [docs/TESTING.md](TESTING.md)
- Estratégia de backend em [docs/BACKEND.md](BACKEND.md)

### Limitações declaradas

- Nenhum backend implementado
- Nenhuma persistência de progresso online
- Nenhuma validação em Android real executada neste ambiente
- O projeto continua sendo um jogo local e offline em sua fase atual

### Resultado

O projeto já está em um estado alinhado com o escopo do pacote de atualização, e a documentação foi complementada para refletir a realidade do código e dos testes executados.
