# Fase 3 — personagens, atributos e equipamentos locais

Base preservada: `781b8a0`, validada pelo usuário no Godot 4.7.2 Android.
Este pacote ainda precisa de validação física Android. Sem arte final, inventário,
progressão implementada, persistência, rede ou sistemas da Fase 4.

## Personagens

| Personagem | Perfil | HP | Mobilidade px/s | Potência % | Resistência % | Controle % |
|---|---|---:|---:|---:|---:|---:|
| Naro | Equilibrado, referência do combate anterior | 100 | 180 | 100 | 0 | 0 |
| Brumo | Resistente/lento | 125 | 150 | 100 | 5 | 0 |
| Vexa | Rápida/frágil | 85 | 210 | 98 | 0 | 5 |
| Lume | Controle do vento | 95 | 175 | 98 | 2 | 15 |

Cada `CharacterProfile` define ID, nome, descrição, cor, emblema, atributos e gravidade.
Todos usam gravidade 1000 px/s²; dados aceitam 900–1100. Colisão 40×52 preservada:
não há diferença de tamanho físico nesta fase. Cores e emblemas distinguem personagens;
contorno azul identifica P1 e laranja P2 mesmo com personagens iguais. Cabeça,
corpo e acessório aparecem como pequenos traços, placas ou círculos, sem colisão.

## Equipamentos

Três presets por slot, todos disponíveis localmente e sem custo. Os básicos são
neutros para permitir comparar o combate anterior. Os demais têm bônus e custo.

| Slot | ID | Nome | Modificadores |
|---|---|---|---|
| Cabeça | faixa | Faixa lisa | Neutro |
| Cabeça | viseira | Viseira de foco | Controle +5; HP −5 |
| Cabeça | capuz | Capuz firme | HP +10; mobilidade −5 |
| Corpo | malha | Malha simples | Neutro |
| Corpo | placa | Placa flexível | Resistência +5; mobilidade −10 |
| Corpo | colete | Colete ágil | Mobilidade +12; HP −8 |
| Acessório | presilha | Presilha lisa | Neutro |
| Acessório | nucleo | Núcleo de pulso | Potência +6; controle −3 |
| Acessório | aleta | Aleta de ajuste | Controle +5; potência −3 |

Modificadores são pontos aditivos, incluindo os atributos expressos em porcentagem.
Não existe bônus por conjunto, aleatoriedade, raridade ou modificador oculto.

## Fórmulas e limites

`StatRules` é a única fonte das regras. Para dados válidos:

`atributo final = clamp(base do personagem + soma dos três equipamentos, mínimo, máximo)`

| Atributo | Mínimo | Máximo | Efeito |
|---|---:|---:|---|
| HP | 70 | 160 | HP inicial/máximo, arredondado ao inteiro mais próximo |
| Mobilidade | 130 | 230 | Velocidade horizontal, px/s |
| Potência | 85 | 120 | Multiplicador de dano, dividido por 100 |
| Resistência | 0 | 25 | Redução percentual do dano recebido |
| Controle | 0 | 25 | Redução percentual da aceleração causada pelo vento |

Cada equipamento aceita no máximo ±20 HP, ±15 mobilidade, ±8 potência,
±5 resistência e ±5 controle. IDs desconhecidos, slots errados, campos numéricos
inválidos, NaN/INF e dados fora do contrato são rejeitados por `valid()`.
`calculate()` também limita entradas defensivamente; valores não finitos de base
usam a referência neutra, e modificadores não finitos são ignorados.

O dano-base continua sendo direto **ou** splash da arma, sem somar ambos:

`dano final = max(1, round(dano-base × potência/100 × (1 − resistência/100)))`

Dano-base zero/negativo resulta em zero. Arredonda uma única vez, após potência e
resistência. Impactos separados da Trinca causam dano separadamente. Resistência
aplica-se também ao próprio splash. Nenhuma combinação torna o jogador invulnerável.

`aceleração horizontal = vento × 18 × influência da arma × (1 − controle/100)`

Controle nunca zera vento. Não muda mira, dispersão angular, gravidade, força,
velocidade inicial, raio de explosão/cratera, quantidade de projéteis ou perfuração.
A potência é copiada para cada projétil ao disparar; um recurso WeaponProfile
nunca é duplicado nem alterado por equipamento. Física continua a 60 Hz.

Exemplo: Brumo + Viseira + Placa + Núcleo = **120 HP, 140 px/s, 106% potência,
10% resistência, 2% controle**. Contra Lume neutro, Lastro direto causa
`round(32 × 1,06 × 0,98) = 33 HP`.

## Loadout e ciclo de vida

`CombatLoadout` guarda somente cinco IDs: personagem, cabeça, corpo, acessório e
arma inicial. `to_dict/from_dict` permitem transporte futuro, com validação, mas
nenhum arquivo, conta ou banco é criado. `copy()` produz instâncias independentes.
Os catálogos carregam os recursos uma vez, no primeiro acesso após inicialização
dos scripts, evitando ciclos de carregamento de Resource/GDScript.

O projeto abre `scenes/preparation.tscn`. Configure P1, confirme, configure P2,
confirme e toque INICIAR PARTIDA. Toque numa opção para alternar circularmente.
As abas permitem rever qualquer jogador; alterar uma opção invalida sua confirmação.
A prévia mostra nome/cor e atributos já somados/limitados. Botões mostram cada
item e arma escolhidos. A transição cria a cena de combate com cópias dos loadouts.

`scenes/main.tscn` continua sendo a composição de combate. Aberta isoladamente,
usa Naro/equipamento neutro/Pulso para os dois jogadores. Assim as quatro suítes
anteriores continuam intactas, testando exatamente o contrato neutro anterior.
A nova suíte cobre o caminho de produção desde a preparação.

REINICIAR repete a batalha com os **mesmos loadouts originais**, HP cheio, terreno
restaurado, turno 1, vento inicial, câmera e controles resetados. A arma inicial
volta mesmo que o jogador tenha trocado de arma durante a batalha.
PREPARAR volta à configuração com as escolhas anteriores e novas confirmações.
Nada é salvo após fechar o projeto. Vitória/empate aguardam todos os projéteis.

## Android e validação

Preparação e HUD usam CanvasLayer 10 acima do mundo, com root explicitamente
dimensionado pelo viewport. Âncoras do root ficam no canto superior esquerdo para
não sobrescrever esse tamanho; a correção do HUD Android permanece. A preparação
escala e centraliza seu conteúdo 1280×720 em paisagem; hitboxes usam o retângulo
transformado. Touch não depende de emulação de mouse. A preparação ativa no soltar;
arrastar para fora ou perder foco cancela. As duas telas não coexistem durante jogo.

Godot **4.5.1.stable.official.f62fdbde1 Linux headless**:

- Quatro suítes antigas sem alterações: 279 verificações.
- `phase3_test.gd`: 95 verificações, incluindo 540 combinações num caso agregado,
  preparação real por touch, aplicação de stats, dano, movimento, vento, HUD,
  queda, vitória, empate e reinício. Inclui 20 combinações reais personagem/arma
  com impactos físicos e 500 trocas de opções na preparação.
- Total: **374 verificações aprovadas, zero falhas**, sem erros/warnings finais.
- Importação sem cache, recursos, UID, cenas de preparação e combate verificados.

Headless não valida renderização, ergonomia, notch, desempenho ou a engine Android.
Balanceamento provisório, sem pulo, sem progressão, sem cosméticos finais. As
limitações de crateras/câmera da Fase 2 permanecem. Consulte o roteiro no README.
