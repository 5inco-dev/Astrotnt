# Balanceamento

Valores lidos de `resources/weapons/*.tres` (fonte única). Alcance plano = `v²/g` a 45°, sem vento.

| Arma | Vel. mín–máx | Gravidade | Vento | Carga s | Direto | Splash máx/mín | Raio expl./cratera | Alcance máx (px) |
|---|---|---|---|---|---|---|---|---|
| Pulso | 300–1050 | 650 | 1,00 | 1,5 | 20 | 18/4 | 120/60 | ~1696 |
| Lastro | 240–820 | 800 | 1,00 | 1,8 | 32 | 30/6 | 160/90 | ~841 |
| Risco | 450–1300 | 500 | 0,65 | 1,0 | 14 | 10/2 | 70/36 | ~3380 |
| Trinca | 300–1050 | 650 | 1,00 | 1,5 | 12 ×3 (5°) | 9/2 | 75/38 | ~1696 |
| Sonda | 300–1050 | 650 | 1,00 | 1,5 | 22 | 20/4 | 95/48 (+40 px) | ~1696 |

Mapa: 2000 px de largura; jogadores nascem a ~1110 px um do outro.

## Vento

Aceleração = `vento × 18 × wind_factor × (1 − controle/100)`. Vento sorteado a cada turno em
[−5, 5] por `WindSystem`: fraco (1–2), médio (3–4), forte (5). Controle máx. do personagem: 25%.

## Observações para decisão

- Risco passa do mapa com força total; o "teto" útil é ~60% de força. Avaliar reduzir `max_speed`.
- Lastro tem alcance menor que a distância inicial (841 < 1110): exige aproximação. Intencional?
- Trinca: 3×12 = 36 direto máx., contra 20 do Pulso; a dispersão de 5° precisa de teste de jogo.
- Nenhum multiplicador global existe ainda; `BalanceConfig` deve nascer com todos = 1,0.

## Teste de jogo (a fazer no aparelho)

10 partidas seguidas, anotando: primeiro tiro interessante? erro ensina? vento importa? terreno importa?
cada arma tem identidade? tempo morto entre turnos? Qualquer "não" tem prioridade sobre novos sistemas.
