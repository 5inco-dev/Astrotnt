# Arquitetura — combate local, terreno e loadouts

## Preparação e loadout — Fase 3

A cena inicial agora é `preparation.tscn`; `main.tscn` continua a composição de
combate. Preparação monta dois `CombatLoadout` com IDs de personagem, cabeça,
corpo, acessório e arma inicial. Confirmação dos dois habilita início; cópias são
atribuídas ao jogo antes de entrar na árvore. Aberta isoladamente, main usa o
loadout neutro, preservando as suítes anteriores sem alteração.

`CharacterProfile`/`EquipmentProfile` são Resources, separados de `WeaponProfile`.
`CharacterCatalog` e `Arsenal` carregam os recursos uma vez no primeiro acesso,
após inicialização das classes. Isso evita ciclos de carregamento de script/resource
introduzidos pelas referências entre loadout, jogador e arsenal.
`StatRules` centraliza soma, limites, validação de números finitos e fórmula de dano.
`CombatLoadout` valida IDs/slots e suporta dicionário com cópia, sem persistência.

Player recebe loadout e snapshot de stats, HP máximo e personagem antes do primeiro
turno. Colisão original não muda. Mobilidade afeta movimento, potência é copiada
para o projétil no lançamento e controle reduz apenas aceleração do vento.
ExplosionResolver combina potência do projétil e resistência do alvo, arredondando
uma única vez. Não altera recursos de armas, crateras ou comportamento da salva.
Fórmulas, tabelas e contratos em [CHARACTERS.md](CHARACTERS.md).

REINICIAR instancia uma nova main com cópias dos loadouts originais; descarta
mundo, projéteis, filas, controles, efeitos e câmera antigos. PREPARAR faz o mesmo
para a tela de configuração, levando as escolhas anteriores. Transições são
deferidas e protegidas contra chamadas duplicadas. Não há autoload de persistência.

HUD mantém CanvasLayer 10 e root explicitamente dimensionado pelo viewport, como
na correção 781b8a0. Âncoras no canto superior esquerdo evitam sobrescrever o tamanho
manual. Preparação segue o mesmo contrato, com conteúdo escalado/centralizado.
Seleção ocorre ao soltar dentro do botão; foco/arrasto cancelam o contato.

## Núcleo balístico e feedback (pós-Fase 3)

`BallisticSolver` (`scripts/combat/`) é a única fonte de cinemática: aceleração (gravidade +
vento × controle), velocidade de lançamento, ângulos da salva, passo exato por tick e `predict()`.
`CombatProjectile` e `CombatWeapon` o usam; `AimPreview` e o overlay de debug também, então a
previsão não diverge do voo real (testado: passo 1 = impacto real, <0,5 px).
`WindSystem` e `MatchRandom` (`scripts/core/`) concentram o vento e a aleatoriedade; `TurnManager`
apenas consulta. `ShotFeedback` classifica cada impacto sem alterar dano. `AimAssist` define os
modos de mira. `AimPreview` é somente leitura e recalcula só quando entradas mudam.
`DebugOverlay` existe apenas em builds de debug. Dependência: UI → sistemas, nunca o contrário.

## Fluxo

`InputController` agrega fontes de entrada identificadas (cada dedo e tecla).
A cada passo de física, `GameManager` consome um comando com movimento, ajuste de
mira, início/fim de carga e cancelamento. Eventos de pressionar/soltar são retidos
até o consumo, inclusive se o toque ocorrer entre dois passos.

`GameManager` aplica o comando somente ao jogador ativo antes de sua física
(`process_physics_priority = -10`). `Player` é um `CharacterBody2D`: gravidade,
colisões, rampas e limites. A posição, direção, HP, ângulo e flag de turno ficam
no jogador. A força e o estado de carga ficam em seu `Weapon`.

Ao soltar, `Weapon` fornece velocidade do perfil selecionado. `GameManager` cria
1 ou 3 projéteis e guarda a lista da salva. Cada projétil emite `finished` uma única
vez, é removido da lista e tem seu impacto resolvido por `ExplosionResolver`.
Somente quando a lista esvazia se decide vitória/empate ou transição. Mortes durante
a salva não descartam os projéteis restantes. Expiração/limites não explodem.

## Arsenal orientado a dados

`WeaponProfile` é um Resource; `resources/weapons/*.tres` configura identidade,
velocidades, carga, gravidade, vento, dano direto/splash, raios, quantidade,
dispersão, cor/tamanho e script de comportamento. `Arsenal` registra os cinco
recursos. Cada `Weapon` guarda uma referência de seleção; recursos compartilhados
são tratados como imutáveis em execução. Para adicionar perfil, crie `.tres`,
registre no catálogo e inclua testes de integração; o painel lê o catálogo.
`valid()` verifica limites básicos, inclusive o invariante de raio do terreno.

`Projectile` recebe o perfil no lançamento e instancia seu comportamento.
`projectile_behavior.gd` resolve impacto normal; `penetrating_behavior.gd` varre
até 40 px adicionais somente ao atingir terreno destrutível. Exclui aquele corpo
apenas nesse trecho, mas detecta jogadores/outros obstáculos. A explosão ocorre
imediatamente no ponto resultante, sem simular túnel contínuo. Profundidade menor
que raio mantém comunicação entre entrada e cratera. Paredes não são perfuradas.

`ExplosionResolver` aplica uma única escolha entre direto e splash por jogador,
com queda pela distância; solicita `Map.queue_explosion(point, crater_radius)`.
A fila guarda centro e raio e processa impactos na ordem recebida. Física e terreno
mantêm a implementação de 8149fd1; só o raio passou a ser argumento com padrão 60.

A câmera de tiro único permanece igual. Na Trinca segue um Node2D cujo centro
converge para a média dos projéteis vivos. Não alterna alvo a cada pellet; o alvo
é descartado ao terminar a salva. Cada explosão tem feedback independente.

O arsenal é modal. Abrir/fechar/selecionar limpa contatos e carga, e GameManager
bloqueia consumo de comandos de combate enquanto aberto. Entradas antigas não
reaparecem ao fechar. Seleção em voo é rejeitada também pela lógica, não só HUD.
Reinício recria o combate e destrói salva, filas e efeitos, restaurando os loadouts originais. Perda de foco
fecha o painel e cancela entrada; projéteis em voo continuam quando a física retoma.

## Estados

| Estado | Comandos de combate | Saída |
|---|---|---|
| AIMING | Apenas jogador ativo | Soltar carga → PROJECTILE |
| PROJECTILE | Bloqueados | Último projétil resolvido → TRANSITION ou FINISHED |
| TRANSITION | Bloqueados por 0,65 s | Alternar jogador e vento → AIMING |
| FINISHED | Bloqueados | Reiniciar recria a cena com os mesmos loadouts |

Durante TRANSITION a câmera já viaja ao próximo jogador. REINICIAR está disponível
sempre. Ao perder foco ou cancelar um toque, a entrada é zerada sem gerar tiro.
Ao alternar turnos, entradas antigas são descartadas: é preciso pressionar novamente.

## Balística e determinismo

Parâmetros no `WeaponProfile` e limites em `CombatConfig`, unidades px e segundos, física fixa em 60 Hz:

- `v0 = (cos(ângulo) × direção, −sin(ângulo)) × velocidade`
- `velocidade = lerp(profile.min_speed, profile.max_speed, força)`
- `a = (vento × WIND_ACCELERATION × profile.wind_factor, profile.gravity)`
- `p_next = p + v × dt + 0.5 × a × dt²`
- `v_next = v + a × dt`

Um raycast varre `p → p_next`. A camada 1 contém terreno; a camada 2 jogadores.
O RID do atirador é excluído. O tiro começa no centro da arma/corpo, sem deslocar
artificialmente a origem para além de uma parede próxima. O círculo desenhado
não aumenta o raio físico do projétil.

Vento usa `RandomNumberGenerator` próprio e semente fixa, alterada apenas no início
da partida/turnos. A câmera e a HUD não modificam a simulação. Repetibilidade é
limitada à mesma versão/ambiente; não existe promessa de lockstep entre dispositivos.

## Apresentação e entrada

`HUD` cria controles ancorados com retângulos de toque; cada índice de dedo é uma
fonte distinta. Teclado e touch convergem em `InputController`. A emulação de mouse
por touch fica desativada para não duplicar ações. Reinício touch é tratado
explicitamente; o botão também aceita mouse em desktop.

A HUD não calcula dano ou turnos; lê estado para exibir. A câmera recebe um alvo
Node2D e faz interpolação exponencial apenas visual. Formas dos jogadores e mapa
são placeholders originais; nenhuma textura/font externa é necessária.

## Futuro servidor autoritativo (não implementado)

A fronteira de comandos pode futuramente receber comandos validados pelo servidor.
Posições, tiros, vento, dano, turnos e resultado deverão ser decididos pelo servidor;
clientes apresentarão snapshots. Será necessário separar a apresentação hoje
embutida em Player e formalizar snapshots e IDs. Não há RPC, autenticação,
predição, transporte, banco de dados nem servidor na Fase 1.

## Validação

`tests/combat_test.gd` carrega a cena completa, injeta eventos touch em coordenadas
do viewport, avança passos reais de física e verifica o ciclo de combate. Casos de
acerto reposicionam o projétil para testar colisão/dano sem automatizar a mira humana.
Teste analítico separado verifica os endpoints balísticos com gravidade e vento.
Veja README para comandos e testes manuais obrigatórios no dispositivo alvo.


## Terreno destrutível — Fase 2.2

`test_map.gd` preserva os pontos originais do chão e das plataformas. O mapa carrega explicitamente o script com `preload`. As três
superfícies usam `DestructibleTerrain` (`StaticBody2D`, camada 1), enquanto as duas
paredes e a base inferior y=920…960 são estáticas e indestrutíveis. A base previne
queda infinita sem introduzir novas regras de morte ou modificar `Player`.

### Dados e recorte

Cada superfície é particionada em regiões de 64 × 64 px. O contorno original é
normalizado e triangulado; cada triângulo é recortado contra os quatro planos da
região (Sutherland–Hodgman), preservando as rampas sem operações booleanas na
inicialização. As peças já são convexas. Vértices consecutivos repetidos e o
vértice de fechamento duplicado são removidos; o sentido é normalizado para CCW. Cada região
mantém uma lista de polígonos convexos e um shape owner no corpo estático.

A explosão usa um polígono circular de 32 vértices com raio do perfil (36–90 px no arsenal atual). Só as regiões
que interceptam sua caixa delimitadora são visitadas. `Geometry2D.clip_polygons`
subtrai o círculo de cada peça restante; `decompose_polygon_in_convex` gera peças
apropriadas para `ConvexPolygonShape2D`. Apenas regiões que perderam área recebem
novas shapes; regiões vazias são removidas, sem guardar histórico de crateras.

**Invariante importante:** o diâmetro do círculo deve ser maior que a largura da
região (`2 * crater_radius > CHUNK_SIZE`). O círculo de corte nunca cabe por
inteiro dentro de uma peça. Assim a diferença não devolve um contorno interno de
buraco que acabaria erroneamente preenchido como sólido. Cavidades internas ao
mapa inteiro são formadas pela união das regiões recortadas. Há teste específico.
Não diminuir o raio para 32 px ou menos sem rever essa representação.

Peças com área inferior a 0,25 px² são descartadas igualmente na colisão e no
visual. As mesmas listas alimentam `_draw` e `shape_owner_add_shape`, evitando
buracos apenas aparentes ou paredes invisíveis. O teste compara os pontos das
shapes aos polígonos desenhados e verifica a triangulação após cada recorte.

### Momento da atualização

Na inicialização, `build()` prepara os shape owners antes de `add_child(terrain)`;
a física recebe um corpo já configurado. `_ready()` solicita o primeiro desenho.
A área gerada é comparada à área original e falhas deixam diagnóstico no log.
O desenho continua usando os mesmos polígonos das shapes convexas; não foram
introduzidos Polygon2D/CollisionPolygon2D duplicados nem chão de fachada.

`Map.queue_explosion` acumula pontos e raios e agenda um único `call_deferred` para esvaziar
a fila. Isso evita alterar shapes enquanto o projétil está consultando a física.
Colisores antigos são limpos e substituídos no mesmo processamento seguro; o
próximo passo de física vê a geometria atualizada. A transição de turno de 0,65 s
permanece intacta. `CharacterBody2D` perde o apoio antigo e cai usando sua gravidade
original, inclusive quando não está no turno. Não há teleporte ou correção manual
na posição do personagem.

Reiniciar recarrega a cena, descartando também qualquer fila pendente e recriando
as superfícies originais. Nenhuma cratera é salva em disco.

### Custo e limites

Há três corpos estáticos destrutíveis, sem um Node por pixel ou por polígono.
Pulso visita até nove regiões; Lastro até 16 por superfície; só há recálculo no
impacto. As chamadas de desenho ficam armazenadas pela Godot até `queue_redraw`.
Ainda assim o número de peças pode variar com os recortes: o teste de estresse não
é garantia de custo máximo para toda sequência possível de impactos.

O recorte não derruba blocos desconectados nem permite pular para fora de buracos.
Os 32 lados aproximam a circunferência; os limites do mapa não são removidos.
Há cinco armas locais integradas aos loadouts da Fase 3; não há rede ou contas.

### Testes deste incremento

`tests/terrain_test.gd`: 32 verificações, incluindo integração da explosão com
splash/turnos, colisão posterior de projétil, queda/novo apoio, movimento, repetição
idempotente, sobreposição, cavidades internas, destruição completa de plataforma,
limites fixos, reinício e caminhada entre regiões. Inclui 160 recortes com semente
fixa, testando geometria e redução monotônica da área. A suíte original de combate
continua sem alteração, com suas 74 verificações. Executadas em Godot 4.5.1 Linux
headless; teste gráfico e desempenho no Android 4.7.2 dependem do aparelho do usuário.


## Regressão de nascimento (hotfix após 343ff96)

O usuário reportou chão ausente e queda antes do primeiro tiro na Godot 4.7.2
Android. O defeito específico não foi reproduzido em 4.5.1 Linux, e não há evidência
para atribuir a causa a uma mudança específica entre versões da engine.
Eliminamos os pontos frágeis da inicialização: descarte silencioso de contornos
vazios, orientação não normalizada, registro tardio das shapes e dependência do
cache de classes do editor para instanciar o novo terreno.

`terrain_startup_test.gd` testa ambos os sentidos dos vértices e fechamento
duplicado; após carregar a cena verifica polígonos sob os dois spawns, congela
os jogadores, sincroniza a física e lança seis raios que devem atingir y=700,
não a base y=920. Só depois libera a gravidade e verifica repouso em y≈674.
Repete após reinício, sem disparos ou crateras. Suítes: 46 startup + 74 combate +
32 terreno = 152 verificações executadas em Godot 4.5.1 Linux headless.
A correção 8149fd1 foi confirmada fisicamente no Android pelo usuário. O arsenal e o HUD também foram confirmados no aparelho em 781b8a0.
Somente o novo pacote da Fase 3 aguarda validação física.

## Validação do arsenal

`arsenal_test.gd`: 127 verificações de catálogo, seleção touch/modal, parâmetros
reais de lançamento, dano, múltiplos projéteis, câmera, recortes de cada raio,
perfuração com obstáculos, expiração, foco, vitória/empate e reinício em voo.
Estresse adicional: 150 crateras mistas, 15 salvas e 300 seleções, com reinícios.
Total da Fase 2: 279 verificações em Godot 4.5.1.stable.official.f62fdbde1 Linux headless.
Importação e cena principal também executadas; sem erros/warnings finais.


## Validação da Fase 3

95 verificações novas + 279 anteriores = **374 aprovadas**, Godot
4.5.1.stable.official.f62fdbde1 Linux headless, zero falhas/erros/warnings finais.
Inclui 540 combinações de dados num caso agregado, 20 integrações reais
personagem/arma, 500 mudanças na preparação, limites, HP variável, dano, vento,
movimento, queda, câmera, HUD, vitória, empate, foco e restauração de loadouts.
Importação sem cache e execução das duas cenas também verificadas. Nada disso
substitui renderização, ergonomia ou desempenho no Godot 4.7.2 Android.
