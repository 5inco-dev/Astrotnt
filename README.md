# Astrotnt — Fase 3: personagens e equipamentos locais

Artilharia 2D original, 1v1 local, desenvolvida em Godot/GDScript sem assets externos ou plugins.
Foco principal: Android Godot 4.7.2, Compatibility, resolução paisagem 1280×720.
A base do commit 781b8a0, incluindo arsenal e correção do HUD, foi validada fisicamente no Android pelo usuário. Este pacote da Fase 3 aguarda confirmação de validação final. Nenhuma funcionalidade de Fase 4 foi iniciada.

## Segurança do projeto

A arquitetura do jogo foi documentada com foco em segurança por design e autoridade do servidor.

- [docs/security/README.md](docs/security/README.md)
- [docs/security/SECURITY_ARCHITECTURE.md](docs/security/SECURITY_ARCHITECTURE.md)
- [docs/security/THREAT_MODEL.md](docs/security/THREAT_MODEL.md)
- [docs/security/AUTHORIZATION.md](docs/security/AUTHORIZATION.md)
- [docs/security/API_SECURITY.md](docs/security/API_SECURITY.md)

## Executar no Android

1. Feche o projeto no editor e pare a sessão em execução.
2. No Termux, dentro do repositório, execute `git status` e `git pull --ff-only origin main`.
   Se o Git bloquear a atualização por alterações locais, preserve o trabalho e não use `force` ou `reset`.
3. Abra ou importe o arquivo `project.godot` no Godot Android e aguarde a importação.
4. Use a orientação paisagem. A cena inicial é `scenes/preparation.tscn`; configure P1 e P2, confirme os dois e toque em INICIAR PARTIDA. Não é necessário exportar APK.

## Controles

| Ação | Touch | Desktop |
|---|---|---|
| Andar/virar | Segurar ← / → | A/D ou ←/→ |
| Ajustar ângulo | ÂNGULO − / + | S/W ou ↓/↑ |
| Carregar e disparar | Segurar e soltar DISPARAR | Espaço |
| Selecionar arma | ARMA → nome desejado | Clique nos mesmos botões |
| Fechar painel | FECHAR | Clique |
| Repetir batalha com os mesmos loadouts | REINICIAR (2 toques durante a partida; 1 toque após o fim) | Clique (idem) |
| Voltar à configuração | PREPARAR (2 toques durante a partida; 1 toque após o fim) | Clique (idem) |
| Alterar opções pré-partida | Toque na opção para alternar | Clique |

O sistema preserva multitouch. Ao sair do botão de disparo, a carga é cancelada; abrir o arsenal, perder foco ou trocar turno também interrompe comandos. O painel bloqueia movimento, mira e disparo, inclusive no teclado. A troca de arma só é permitida antes do disparo. Cada jogador mantém a arma entre turnos; o reinício restaura o equipamento inicial do loadout. O botão PREPARAR permite alterar personagem e equipamentos. O HUD exibe personagem, HP atual e máximo, arma, turno, ângulo, vento e direção, força e estado da partida.

## Personagens, atributos e equipamentos

A Fase 3 inclui quatro perfis: Naro (equilibrado), Brumo (resistente e lento), Vexa (rápida e frágil) e Lume (controle). Há nove equipamentos, distribuídos em três slots: cabeça, corpo e acessório. Cada jogador possui loadout independente, com arma inicial definida.

- HP: 70–160; mobilidade: 130–230 px/s.
- Potência: 85–120%; resistência: 0–25%; controle: 0–25%.
- Os atributos finais são calculados como base + equipamentos, com limites centralizados.
- Dano positivo: `max(1, round(base × potência/100 × (1 − resistência/100)))`.
- O controle multiplica a aceleração do vento por `1 − controle/100`.
- A regra não altera velocidade, gravidade, crateras, Trinca ou Sonda.

A documentação completa de personagens, equipamentos, fórmulas e exemplos está em [docs/CHARACTERS.md](docs/CHARACTERS.md). Não há inventário persistente, economia, contas ou progressão implementados.

## Arsenal

| Arma | Função | Velocidade px/s | Carga s | Direto | Splash máx/mín | Raio explosão / cratera px |
|---|---|---:|---:|---:|---:|---:|
| Pulso | Padrão amarelo, comportamento anterior | 300–1050 | 1,5 | 20 | 18/4 | 120 / 60 |
| Lastro | Pesado laranja; maior gravidade e explosão | 240–820 | 1,8 | 32 | 30/6 | 160 / 90 |
| Risco | Leve verde; mais rápido e menos influenciado pelo vento | 450–1300 | 1,0 | 14 | 10/2 | 70 / 36 |
| Trinca | Três projéteis roxos, separados por 5° | 300–1050 | 1,5 | 12 cada | 9/2 cada | 75 / 38 cada |
| Sonda | Azul; explosão até 40 px dentro do terreno | 300–1050 | 1,5 | 22 | 20/4 | 95 / 48 |

A Sonda realiza uma varredura adicional no impacto para detectar jogadores e outros obstáculos, sem atravessar paredes indestrutíveis. Não é uma escavação contínua animada. Explosões não somam dano direto e splash ao mesmo impacto; o dano por splash diminui com a distância, pode atingir o atirador e ignora cobertura. Pellets distintos causam danos diferentes. A vitória só é resolvida quando toda a salva termina; a morte dos dois resulta em empate. Expiração (10 s) e saída do mapa encerram projéteis sem explosão.

## Funcionalidades preservadas

- Dois jogadores com HP por loadout, movimento, gravidade, rampas, colisões e limites.
- Mira de 5° a 85°, carga limitada a 100%, balística a 60 Hz e vento com semente fixa.
- Chão e plataformas destrutíveis; crateras reais removem visual e colisão simultaneamente.
- Crateras sobrepostas, tiros pelo terreno removido e queda natural ao perder apoio.
- Câmera suave: projétil único ou centro suavizado da salva, depois aproximação ao jogador.
- Turnos, splash, dano direto, vitória, multitouch, cancelamento por foco e reinício.
- Base inferior e paredes indestrutíveis evitam saída e queda infinita dos jogadores.

## Estrutura do projeto

- `scenes/`: preparação e composição do combate; cenas anteriores preservadas.
- `resources/characters/` e `resources/equipment/`: perfis da Fase 3.
- `scripts/character_profile.gd`, `equipment_profile.gd`, `character_catalog.gd`: dados e catalogação.
- `scripts/combat_loadout.gd`, `stat_rules.gd`: IDs, validação e atributos.
- `scripts/preparation.gd`: preparação local em touch.
- `resources/weapons/*.tres`: cinco perfis editáveis.
- `scripts/weapon_profile.gd`, `arsenal.gd`: dados e catálogo das armas.
- `scripts/weapon.gd`: seleção por jogador, carga, velocidade e direção.
- `scripts/projectile.gd`, `projectile_behavior.gd`, `penetrating_behavior.gd`: voo e impacto.
- `scripts/explosion_resolver.gd`: dano e recorte configurado no impacto.
- `scripts/game_manager.gd`: coordenação da salva, câmera, resultado e reinício.
- `scripts/test_map.gd`, `destructible_terrain.gd`: fila segura e geometria validada.
- `scripts/input_controller.gd`, `player.gd`, `turn_manager.gd`, `camera_controller.gd`, `hud.gd`, `combat_config.gd`: entrada, personagem, turnos, apresentação e limites.
- `tests/`: regressões de combate, nascimento, terreno e arsenal.
- `docs/ARCHITECTURE.md` e `docs/ROADMAP.md`: decisões de arquitetura e escopo futuro.

Arquivos `.gd.uid` acompanham os scripts; `.godot/` e artefatos temporários não são versionados.

## Validação executada

Ambiente de validação: Godot 4.5.1.stable.official.f62fdbde1, Linux headless, fora do Android.

- Importação e parsing da cena principal por 180 frames.
- Combate: 74 verificações; terreno: 32; nascimento: 46; arsenal: 127.
- Fase 3: 95 verificações, incluindo 540 combinações de catálogo, 20 cenários com disparos físicos e 500 alterações de opções pré-partida.
- Resultado: 374 verificações aprovadas e zero falhas; suítes anteriores preservadas.
- Estresse: 160 crateras originais + 150 recortes com raios mistos, 15 salvas, 300 trocas de arma e reinícios repetidos; inclui dispersão física, Sonda, bloqueio modal, foco, expiração, morte durante salva e empate.
- Sem erros ou warnings nos logs finais. Testes headless não comprovam imagem, ergonomia, temperatura, FPS ou comportamento em Android.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/combat_test.gd --fixed-fps 60
godot --headless --path . --script tests/terrain_startup_test.gd --fixed-fps 60
godot --headless --path . --script tests/terrain_test.gd --fixed-fps 60
godot --headless --path . --script tests/arsenal_test.gd --fixed-fps 60
godot --headless --path . --script tests/phase3_test.gd --fixed-fps 60
godot --headless --path . --script tests/mobile_test.gd --fixed-fps 60
godot --headless --path . --script tests/feedback_test.gd --fixed-fps 60
godot --headless --path . --script tests/ballistic_test.gd --fixed-fps 60
godot --headless --path . --script tests/feel_test.gd --fixed-fps 60
godot --headless --path . --script tests/menu_test.gd --fixed-fps 60
godot --headless --path . --quit-after 180
godot --headless --path . res://scenes/main.tscn --quit-after 180
```

## Roteiro obrigatório de validação Android

1. Pare a sessão, execute `git pull --ff-only origin main`, reabra `project.godot` e aguarde a importação.
2. Em paisagem, confirme que a preparação está visível, os botões estão inteiros e o toque está alinhado, inclusive com barra de navegação e notch.
3. P1: escolha Brumo, Viseira de foco, Placa flexível, Núcleo de pulso e Lastro. Confirme os valores: 120 HP, 140 mobilidade, 106 potência, 10 resistência e 2 controle.
4. P2: escolha Lume, Faixa lisa, Malha simples, Presilha lisa e Trinca. Confirme: 95 HP, 175 mobilidade, 98 potência, 2 resistência e 15 controle.
5. Confirme P2. Revise P1 pela aba; a mudança de opção deve exigir nova confirmação. Restaure o exemplo e confirme. Em seguida, toque em INICIAR PARTIDA.
6. Antes do primeiro disparo, verifique terreno, apoio dos dois jogadores, emblemas, equipamentos geométricos e HUD com 120/120 e 95/95.
7. Ande pelas rampas. Use dois dedos para andar e mirar; nada pode permanecer pressionado.
8. Teste Lastro contra Lume: um acerto direto causa 33 HP nesse exemplo. O splash varia com a distância. Abrir o arsenal durante a carga deve cancelar o tiro.
9. A Trinca deve lançar três projéteis e trocar de turno somente após o último. Teste a troca para Pulso, Risco e Sonda, mantendo os atributos do personagem.
10. Confirme crateras pequenas, grandes e sobrepostas, novos tiros pelo buraco, perfuração limitada da Sonda e queda dos jogadores ao perder apoio.
11. Use REINICIAR com uma salva em andamento: o terreno, P1 com 120 HP/Lastro e P2 com 95 HP/Trinca, turno 1, câmera e controles devem ser restaurados. Repita após a vitória.
12. Use PREPARAR: escolhas anteriores devem reaparecer. Teste Vexa, Naro e outros equipamentos; confirme e inicie nova partida. Encerre partidas e valide o resultado.
13. Na preparação, pressione uma opção, troque de aplicativo e solte ao voltar. Não deve haver seleção involuntária. Repita durante carga e arsenal aberto.
14. Teste outra proporção ou resolução paisagem disponível. Jogue alguns minutos com salvas e crateras e observe fluidez, aquecimento e erros. Registre a primeira mensagem de erro e a versão completa do Godot em caso de problema.

## Pacote mobile (pós-Fase 3)

- `physics/common/physics_interpolation=true`: movimento suave em telas de 90/120 Hz com física fixa em 60 Hz. A câmera é suavizada em `_process` e permanece fora da interpolação.
- Câmera com limites (`CombatConfig.CAMERA_LIMITS`): não mostra vazio além das paredes laterais nem abaixo do leito rochoso.
- REINICIAR e PREPARAR pedem segundo toque (`CONFIRMAR?`, 3 s; ignora toque duplo em menos de 0,25 s) durante a partida. Após vitória ou empate, basta um toque.
- Validação Linux headless (Godot 4.5.1): 15 verificações novas em `tests/mobile_test.gd`; suítes anteriores sem alteração de resultado. Isso não substitui a validação em Android.

## Determinismo e feedback de tiro

- `MatchRandom` (`scripts/core/`): única fonte de aleatoriedade da partida. Cada partida sorteia e armazena `game.match_seed`; a mesma seed reproduz o mesmo vento e permite replay/depuração.
- `WindSystem` (`scripts/combat/`): sorteio, força (calmo, fraco, médio, forte) e texto (`←← VENTO MÉDIO (3)`). O HUD apenas consulta essa fonte.
- `ShotFeedback`: veredito por salva (DIRECT HIT / NEAR HIT / MISS) com desvio em px no eixo do tiro (negativo = curto, positivo = longo). No caso da Trinca, vale o melhor projétil.
- Números de dano (`FloatingText`), marcador X do último impacto do jogador ativo e linha "Último tiro: ângulo · força" no HUD. Dano e regras de combate permanecem inalterados.
- Validação Linux headless (Godot 4.5.1): `feedback_test.gd` com 30 verificações; suítes anteriores repetidas com diferentes sementes, sem falhas.

## Balística, mira e debug

- `BallisticSolver` é a fonte única de cinemática; projétil, previsão e debug compartilham a mesma base.
- Botão MIRA no HUD: OFF, NORMAL (padrão) e ASSISTED (arco parcial ao carregar).
- Debug somente em builds de desenvolvimento: `F3` ou 4 toques simultâneos.
- `ballistic_test.gd`: 39 verificações, cobrindo previsão x impacto real, modos de mira e overlay.
- Novos documentos: [docs/AUDIT.md](docs/AUDIT.md), [docs/GAMEPLAY.md](docs/GAMEPLAY.md), [docs/BALANCE.md](docs/BALANCE.md) e [docs/MOBILE.md](docs/MOBILE.md).

## Game feel (Fase B)

- `FeelController` (`scripts/combat/`) reage a tiros e impactos sem alterar dano ou regras: partículas (`VFXController`, pool fixo de 200), áudio procedural (`AudioManager` + `ProceduralSounds`, sintetizado em código, sem assets externos), vibração curta (`HapticManager`, silenciosa quando não há suporte) e hit-stop de 50–90 ms proporcional à força do impacto.
- `BattleCamera` (antes `CameraController`) tem 5 estados (PLAYER, AIM, PROJECTILE, IMPACT, RESULT), zoom dinâmico e screen shake por trauma; nunca há corte brusco.
- `FeelSettings` centraliza volume, vibração e intensidade de shake/partículas (valor 0 desativa cada sistema). Ainda não há tela de opções para ajuste do jogador.
- Aviso conhecido e não crítico: em suítes que terminam logo após tocar som, pode aparecer `ObjectDB instances leaked at exit` para `AudioStreamPlaybackWAV`. Esse fenômeno acontece quando o processo sai antes do `AudioServer` liberar o buffer; não ocorre durante o jogo real e não afeta os resultados dos testes.
- Validação Linux headless (Godot 4.5.1): `feel_test.gd` com 40 verificações; as 8 suítes anteriores repetidas sem alteração de resultado.

## Menu, HUD mobile e tela de resultado (Fase C)

- Fluxo: o jogo abre em `scenes/main_menu.tscn`. JOGAR leva à preparação; ARSENAL, PERSONAGEM, INVENTÁRIO, MISSÕES e PERFIL ficam desabilitados e exibem "EM BREVE" — não há progressão implementada, então não é criado XP ou nível falso.
- Safe area: `SafeArea` (`scripts/core/`) lê `DisplayServer.get_display_safe_area()` e desloca o HUD, a preparação e o menu para dentro da área segura (notch, câmera furo, cantos arredondados). Em desktop, os insets são zero e não têm efeito.
- `stretch/aspect = "expand"`: as barras pretas em telas 18:9/19.5:9 foram removidas; cada tela recalcula o layout a partir do retângulo visível.
- Orientação: `sensor_landscape` (anteriormente era fixa).
- Tela de resultado (`ResultScreen`): aparece ao fim da partida, exibindo apenas dados reais do confronto — tiros, acertos diretos, precisão, dano causado por jogador e terreno destruído em px² (antes e depois de `DestructibleTerrain.solid_area()`). Não há +XP ou +COINS fictícios, porque o sistema de progressão ainda não existe. Empates exibem "EMPATE!" e nunca inventam um vencedor. Os botões são REVANCHE, PREPARAR e MENU.
- Cada toque em `main_menu.gd` e `result_screen.gd` segue o padrão manual do restante do HUD (`mouse_filter = IGNORE` + hit-test em `_input`). O sinal `Button.pressed` não reage a toque neste projeto (emulação mouse↔touch desligada), então não é usado em lugar nenhum.
- Validação Linux headless (Godot 4.5.1): `menu_test.gd` com 27 verificações. As 9 suítes anteriores foram repetidas sem alteração de resultado; o boot de `main_menu.tscn` e `main.tscn` não gerou erros.

## Limitações e bugs conhecidos

- Nenhum bug conhecido foi reproduzido nas suítes finais.
- A Fase 3 ainda não foi validada em Android; combate, arsenal e HUD anteriores foram confirmados em 781b8a0.
- O defeito de nascimento da versão 343ff96 foi corrigido em 8149fd1 e confirmado pelo usuário; o algoritmo de inicialização foi preservado.
- Sem pulo: crateras profundas podem impedir a saída andando; novos tiros abrem caminho.
- Fragmentos ficam estáticos, sem desabamento. Recortes de 32 lados descartam peças menores que 0,25 px². Raios devem ficar entre 32 px e 128 px no catálogo.
- Lastro pode atualizar até 16 regiões por superfície; Trinca faz até três recortes.
- Custo está concentrado nos impactos; reconstrução por frame não ocorre. O desempenho em Android precisa ser medido.
- O projétil é um ponto físico com círculo visual; o atirador é excluído do voo, mas continua vulnerável ao splash.
- A física não garante resultados bit a bit entre versões.
- O jogo é paisagem, sem IA, rede, arte final, persistência ou áudio final.
- Movimento por turno é ilimitado, sem cronômetro ou munição limitada; o balanceamento é provisório.
- A câmera é limitada às paredes e ao leito rochoso; em tiros altos, pode mostrar vazio. O centro da salva pode deixar pellets extremos fora da tela.
- Nenhum sistema de Fase 4+ foi implementado.
- Equipamentos básicos são neutros; as colisões dos quatro personagens têm o mesmo tamanho.
- Alterações de atributos só entram em vigor ao iniciar a partida e não persistem após fechar o jogo.
