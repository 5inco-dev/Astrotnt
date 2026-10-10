# Gameplay

Fórmula central: **ângulo + força + vento + terreno + arma + habilidade**.

## Loop do turno

mover → mirar → ler o vento → carregar (segurar DISPARAR) → soltar → voo → impacto/dano →
terreno deformado → veredito do tiro → próximo jogador.

## Feedback ao jogador

| Momento | Feedback |
|---|---|
| Mirando | Guia do cano; em ASSISTED, arco parcial (0,9 s) enquanto carrega |
| Vento | `←← VENTO MÉDIO (3)`: setas = força; número = valor exato |
| Impacto | Círculo de explosão, número de dano `-20`, veredito |
| Veredito | `DIRECT HIT`, `NEAR HIT -30 px`, `MISS +170 px` (− curto, + longo), `FORA DO MAPA` |
| Próximo turno | X no último impacto e "Último tiro: ângulo · força" |

Trinca mostra o melhor projétil da salva.

## Assistência de mira

| Modo | Efeito |
|---|---|
| OFF | Sem guia |
| NORMAL | Guia do cano (padrão, comportamento original) |
| ASSISTED | Guia + arco parcial ao carregar; **não** mostra o ponto de impacto |

Botão `MIRA:` no HUD alterna e o modo se mantém ao reiniciar. Em ranked deve ser OFF
(`AimAssist.allowed(mode, ranked)`), ainda sem modo ranked implementado.

## Determinismo

Cada partida guarda `match_seed`. A mesma seed reproduz o mesmo vento. Toda aleatoriedade
da partida deve passar por `MatchRandom`.
