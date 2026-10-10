# Placeholders de progressão (decisão de escopo — Fase C)

O spec (§23, §53–54) pede um menu com ARSENAL, PERSONAGEM, INVENTÁRIO, MISSÕES, PERFIL e um
rodapé de nível/XP, além de uma tela de resultado com "+XP +COINS".

Nada disso foi implementado com dados reais nesta fase porque **não existe** `PlayerProfile`,
`SaveManager` nem economia de XP/moedas no projeto (Fases D+ do roadmap). Duas opções:

1. Mostrar esses elementos com valores inventados (ex: "LV 12", "+50 XP") só para bater com o
   mockup do spec.
2. Deixar os botões visíveis, mas desabilitados com "EM BREVE", e omitir XP/moedas da tela de
   resultado até existir um sistema real por trás.

Escolhi a opção 2. Dado "não hardcodar conteúdo" (spec §59) e o princípio de não inventar
números que pareçam reais, prefiro isso a criar uma progressão de fachada que o jogador
percebe como falsa assim que tentar usá-la. Quando a Fase D (progressão) entrar, os botões
passam a navegar de verdade e a tela de resultado ganha XP/moedas reais.
