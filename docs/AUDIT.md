# Auditoria do projeto (base para a migração)

Escopo: leitura de `project.godot`, `scripts/`, `scenes/`, `resources/`, `tests/` e docs.
Validação: Godot 4.5.1 headless (Linux). Nada aqui comprova comportamento no Android.

## Sistemas existentes (preservar)

| Sistema | Onde | Estado |
|---|---|---|
| Turnos e fases | `turn_manager.gd` | Sólido, pequeno |
| Entrada multitouch | `input_controller.gd`, `hud.gd` | Sólido; fontes por dedo, cancelamento por foco |
| Jogador/física | `player.gd`, `player.tscn` | Sólido; colisão 40×52 |
| Armas (dados) | `weapon_profile.gd`, `resources/weapons/*.tres`, `arsenal.gd` | Bom: orientado a dados, `valid()` |
| Projétil | `projectile.gd`, `*_behavior.gd` | Sólido; raio varrido, sem tunelamento |
| Terreno destrutível | `destructible_terrain.gd`, `test_map.gd` | Sólido e bem testado |
| Dano | `explosion_resolver.gd`, `stat_rules.gd` | Correto; regras centralizadas |
| Personagens/equipamentos | `character_*`, `equipment_profile.gd`, `combat_loadout.gd` | Bom |
| Testes | `tests/` | Forte: ~450 verificações |

## Problemas encontrados

| # | Problema | Gravidade | Situação |
|---|---|---|---|
| 1 | Vento com seed fixa: toda partida repetia o mesmo vento | Alta (gameplay) | **Corrigido** (`MatchRandom`, `WindSystem`) |
| 2 | Cinemática duplicada (projétil, arma, gerente) e sem previsão | Alta | **Corrigido** (`BallisticSolver`) |
| 3 | Sem feedback do porquê de errar | Alta (game feel) | **Corrigido** (`ShotFeedback`, números de dano, marcador) |
| 4 | Câmera mostrava vazio fora do mapa; física a 60 Hz sem interpolação | Média | **Corrigido** (limites, interpolação) |
| 5 | REINICIAR/PREPARAR com 1 toque e lado a lado | Média (UX) | **Corrigido** (2 toques) |
| 6 | `game_manager.gd` acumula turno, salva, apresentação e troca de cena (~250 linhas) | Média (manutenção) | Parcial: solver, preview, feedback extraídos; falta `MatchController`/`VFXController` |
| 7 | `hud.gd` mistura layout, hit-test e estado (~310 linhas) | Média | Pendente (Fase de HUD mobile) |
| 8 | Constantes mortas em `CombatConfig` (`PLAYER_SPEED`, `PLAYER_GRAVITY`, `MAX_HP`) | Baixa | Pendente (remover junto com `BalanceConfig`) |
| 9 | `game_manager.splash_damage()` morto (usa `PROFILES[0]`) | Baixa | Pendente |
| 10 | Sem cronômetro de turno; movimento ilimitado | Média (ritmo) | Pendente (decisão de design) |
| 11 | Sem áudio, partículas nem screen shake | Alta (game feel) | **Corrigido** (`FeelController`, `VFXController`, `AudioManager`, `HapticManager`, `BattleCamera`) |
| 12 | `player.gd` redesenha todo frame | Baixa (perf) | Pendente |
| 13 | HUD só se adapta a `visible_rect`; com `stretch aspect=keep` há barras pretas | Média (mobile) | **Corrigido** (`stretch/aspect=expand` + `SafeArea`) |
| 14 | Configuração de mira não persiste fora do reinício | Baixa | Depende de `SaveManager` |

## Riscos

- **Android não validado** para nada desta lista. Testes headless não medem FPS, toque real nem calor.
- Mover scripts para subpastas mexe em `.uid`, `.tscn` e `preload`; fazer uma vez só, no fim, com suíte completa.
- `BalanceConfig` global pode invalidar asserts exatos das suítes (dano 20, 33 HP etc.); introduzir com multiplicadores = 1.0.
- Determinismo total (replay/servidor) exige que toda física rode em passo fixo e que nada leia `randi()` fora de `MatchRandom`. Hoje só o sorteio de seed usa entropia.
- Risco (`max_speed` 1300, gravidade 500) alcança ~3380 px a 45° com força total, mais que o mapa (2000 px). Pode ser intencional, mas precisa de decisão de balanceamento.

## Migração proposta (ordem = prioridade do spec: gameplay → física → game feel → UX → perf → progressão)

1. **Fase A — Polimento do combate**: solver, vento, feedback, mira, debug, câmera. *(feito nesta entrega, falta validar no aparelho)*
2. **Fase B — Game feel**: `VFXController` (partículas pooled, shake curto, hit-stop 50–100 ms), `BattleCamera` com estados, `AudioManager`/`HapticManager` com fallback.
3. **Fase C — Menus e HUD mobile**: safe area, `stretch expand`, menu, tela de resultado, REMATCH direto.
4. **Fase D+ — Progressão, arsenal, PvE, ranked, multiplayer, social**, cada uma só depois da anterior estável.

Regra de execução: rodar as suítes antes e depois de cada mudança; nenhuma fase começa com suíte vermelha.
