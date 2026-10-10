# Mobile (Android, Godot GL Compatibility)

## Configuração relevante

| Ajuste | Valor | Motivo |
|---|---|---|
| `physics/common/physics_ticks_per_second` | 60 | Física fixa e determinística |
| `physics/common/physics_interpolation` | true | Suavidade em telas 90/120 Hz |
| Câmera | fora da interpolação, criada com `_init()` | Ela é suavizada em `_process`; senão o Godot a força para modo de física |
| Limites da câmera | `CombatConfig.CAMERA_LIMITS` | Não mostrar o vazio |
| Orientação | paisagem | Único modo suportado |
| Mouse/touch | `emulate_*_from_touch=false` | Evita evento duplicado |

## Controles e toque

Multitouch por dedo; sair do botão DISPARAR cancela a carga; perder foco, abrir arsenal ou trocar
turno cancela comandos. REINICIAR/PREPARAR: 2 toques durante a partida (3 s, ignora <0,25 s);
1 toque após o fim.

## Debug

Só em builds de debug (editor ou export debug). **F3** ou **4 toques simultâneos** abrem o overlay
(FPS, física, memória, posição, velocidade, ângulo, força, vento, projéteis, revisão do terreno,
turno, fase, seed) e ligam a visão de balística (trajetória completa, ponto e raio de impacto,
vetores de velocidade e vento).

## Pendente

Safe area/notch, `stretch aspect=expand`, `max_fps`, áudio, vibração (exige permissão `VIBRATE` em APK
exportado; no editor Android não vibra), medição de FPS/calor no aparelho, rotação.

## Checklist manual (spec §60)

toque único · multitouch · toque interrompido · troca de foco · minimizar/voltar · resoluções diferentes ·
aparelho lento · sem áudio · sem vibração.
