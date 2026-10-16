# FERRO-VELHO: GUERRA DE SOBRAS — Guia de estilo visual

## Resumo

Este jogo foi orientado para uma identidade visual que mistura pós-apocalipse industrial, cultura de ferro-velho e humor sombrio de nicho. A direção visual tenta lembrar brinquedos abandonados, placas de circuito, latas oxidadas, peças de automóvel e restos de eletrônicos transformados em armas criativas e criaturas sobreviventes.

## Direção geral

- Cartun pós-apocalíptico com leitura clara em tela mobile.
- Sucata industrial como linguagem primária.
- Micro-nostalgia de jogos browser e arcade de anos 2000.
- Expressão de improvisação e resistência.
- Paleta industrial e mineral, com toques de energia improvisada.

## Paleta base

- Fundo: #0b1113
- Painel: #172327
- Acento metálico: #a9b7be
- Latão/sucata: #d39858
- Ferrugem: #b75f3d
- Verde reciclado: #7bd2a8
- Aviso: #ffe195
- Perigo: #ff7d5a
- Sombra: #050a0d

## Personagens

### Latão
- Silhueta: robusta, muito larga e com rodas/placas.
- Paleta: latão, ferrugem, carvão.
- Materiais: latas, pneus, placas e encaixes de metal.
- Expressão: olhos pequenos e sobrancelhas de parafuso.

### Zip
- Silhueta: ágil, estreita, quase “mecânica de brinquedo”.
- Paleta: azul claro, cinza e amarelo de alerta.
- Materiais: molas, rodas e partes de brinquedos.
- Expressão: nível de energia agressivo e curioso.

### Tubo
- Silhueta: alta, de circuitos e antenas.
- Paleta: verde “CRT”, cinza e brilho azul.
- Materiais: tubo, sensores, placas e fios.
- Expressão: visor rachado e luz interna de diagnóstico.

### Trapo
- Silhueta: composta por tecido e remendos.
- Paleta: ferrugem, cáqui, creme e couro sintético.
- Materiais: tecido, fita, parafusos e mecânica improvisada.
- Expressão: olhos de botão e postura de sobrevivente.

## Armas

A identidade visual das armas precisa seguir a simulação real do sistema de combate, nunca substituí-la por fantasia visual. Cada arma deve manter o comportamento da arma correspondente, mas receber um verniz visual de sucata.

- Lata-Canhão: corpo de lata estampada e reforços metálicos.
- Bateria Podre: casing de bateria e detalhes de energia corroída.
- Chuva de Parafusos: projétil em cascata com pequenos elementos metálicos.
- Geladeira Voadora: formas arredondadas e ventilação improvisada.
- Micro-ondas: brilho de energia interna e borda rachada.
- Bomba de Chorume: garrafa e detritos tóxicos com filtro improvisado.
- Ímã de Ferro: núcleo metálico com forte brilho de campo.
- O Último Fusível: peça estranha, rara e quase ritualística.

## Mapas

### Aterro Zero
- Base: cinza escuro, latas e resíduos.
- Focos: ferrugem e metal antigo.
- Estética: terrenos planos, manchas de lixo e montes metálicos.

### Fábrica do Fim
- Base: cinza industrial, verde de circuito e metal endurecido.
- Focos: automação quebrada e ruínas de produção.
- Estética: linhas horizontais e elementos de máquina.

### Cidade Descartada
- Base: azulejos duros, rodas e chassis.
- Focos: prédios soterrados e escada metálica.
- Estética: ruínas urbanizadas, restos de cultura apodrecida.

### Pântano Químico
- Base: verde e marrom tóxico.
- Focos: acidez, lama sintética e detritos eletrônicos.
- Estética: vegetação industrial mutante e água metálica.

## Interface

A interface deve parecer um painel improvisado por criaturas de ferro-velho — com placas, etiquetas, fita isolante, lente rachada e ícones de peça. A legibilidade deve prevails sobre a decoração.

- Botões: placas metálicas rebitadas.
- Painéis: neutros e com luz baixa de aviso.
- Indicadores: amarelo de recurso, laranja para alerta, verde para energia e cinza para desligado.
- HUD: informações claras e escaláveis; o toque deve ser grande e fácil no Android.

## Regras visuais

- Nunca misturar excesso de “futurismo limpo” com a estética de sucata.
- Preservar legibilidade em móvel.
- Não usar mais de três cores quentes principais por cena.
- Usar contraste de borda e sombra para manter leitura em telas pequenas.
- Evitar partículas excessivas em cenários de combate saturados.

## Implementação atual

A identidade visual foi iniciada com:

- renome do projeto em [project.godot](project.godot);
- criação da paleta temática em [scripts/core/ferro_velho_theme.gd](../scripts/core/ferro_velho_theme.gd);
- ajustes de menu e HUD para usar a linguagem visual de sucata.

Ainda permanece como placeholder o desenho real de sprites e a criação de sprites finais para criaturas, armas e mapas. Os elementos visuais atuais são prontos para receber um pass de art final, sem quebrar as regras de combate e a lógica do jogo.

## Próximos passos

1. Criar sprites base para Latão, Zip, Tubo e Trapo.
2. Produzir armas em atlas de 2D para o arsenal.
3. Finalizar três versões de mapa com camadas de fundo/foreground.
4. Reaproveitar a paleta em botões, HUD e telas finais.
5. Validar em Android real para ajustar contraste e capacidade de leitura.
