# Roadmap

A Fase 1 foi concluída e validada no aparelho Android alvo em Godot 4.7.2.
As Fases 1 e 2, incluindo o HUD de `781b8a0`, foram validadas no Android pelo usuário.
A tarefa atual autoriza **personagens, atributos, equipamentos e preparação local
da Fase 3**, preservando terreno e combate validados.

| Fase | Objetivo | Estado |
|---|---|---|
| 1 | Combate básico 2D, 1v1 local, touch, turnos, mira, força, vento, dano e vitória | Concluída e validada no Android |
| 2 | Terreno destrutível e múltiplas armas | Concluída e validada no Android em 781b8a0 |
| 3 | Personagens e equipamentos | Núcleo local implementado; validação Android pendente |
| A | Polimento do combate: solver, vento, feedback, mira, debug, câmera (spec §57) | Implementado; validação Android pendente |
| B | Game feel: VFX, shake, hit-stop, áudio, vibração | Implementado; validação Android e tela de opções pendentes |
| C | Menus, HUD mobile, resultado, REMATCH | Implementado; validação Android e telas ARSENAL/PERSONAGEM/etc. pendentes |
| D–I | Progressão, arsenal, PvE, ranked, multiplayer, social | Não iniciadas |
| 4 | Lobby e salas | Não iniciada |
| 5 | Multiplayer online com servidor autoritativo | Não iniciada |
| 6 | Contas e banco de dados | Não iniciada |
| 7 | PvE e bosses | Não iniciada |
| 8 | Guildas e social | Não iniciada |
| 9 | Economia e loja | Não iniciada |
| 10 | Otimização Android e PC | Não iniciada |

## Fase 1 — validação concluída

No Android alvo, o projeto abriu e executou em Godot 4.7.2. Foram confirmados
movimento, mira, carga/soltura do disparo, projétil, câmera, turnos, dano,
multitouch e fluxo básico da partida.

## Fase 2 — incrementos

1. **Fase 2.1 — Explosão e dano em área:** commit `953b0fc`, concluído e
   validado fisicamente no Godot 4.7.2 Android pelo usuário. Preservado neste incremento.
2. **Fase 2.2 — Terreno destrutível:** concluído e validado fisicamente no Android
   pelo usuário no commit `8149fd1`, após corrigir a inicialização de `343ff96`.
3. **Núcleo de armas:** implementado neste pacote: Pulso, Lastro, Risco, Trinca e
   Sonda; perfis Resource, seleção touch modal, dano configurável, salvas completas,
   câmera estável e recorte com raio por arma. 279 verificações Linux headless
   aprovadas. Validado fisicamente no Android, incluindo HUD corrigido em `781b8a0`.
4. **Fechamento da Fase 2:** confirmado pelo usuário; preservar regressões.

## Fase 3 — pacote local atual

Implementados quatro personagens, nove equipamentos, cinco atributos com limites,
loadouts por IDs, preparação touch com confirmação de ambos e integração com as
cinco armas. Reinício conserva loadouts; PREPARAR permite nova configuração.
Sem arte final, progressão ou inventário persistente.

374 verificações Linux headless aprovadas; aguarda roteiro físico Android do README.
Próximo marco: confirmar a preparação, atributos, feedback e desempenho no aparelho.
Fase 4 e posteriores seguem fora do escopo; não iniciar sem autorização.
