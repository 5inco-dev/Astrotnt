# Save System

## Estado atual

O projeto atual não implementa um sistema de salvamento persistente de progresso, inventário, economia ou ranking. A lógica de combate, preparação e loadout é local e efêmera, sendo reutilizada por cena e reinício de partida.

A arquitetura de jogo foi desenhada para manter a lógica local e a experiência offline funcional, sem simular backend ou estado persistente sensível. O único armazenamento local que faz sentido no estado atual é um `SaveManager` futuro, usando `user://` para dados não críticos.

## Regras vigentes

- O cliente não deve ser tratado como fonte confiável para moeda, XP, recompensas ou resultados competitivos.
- Não há senhas, tokens, segredos ou credenciais no repositório.
- O jogo não armazena inventário, contas ou progresso em disco.
- A partida de combate reinicia a partir dos loadouts escolhidos na preparação, não de um arquivo local de progresso.
- Qualquer salvamento futuro deve ser versionado, validado e resgatável em caso de arquivo corrompido.

## Arquitetura recomendada futura

Quando o sistema de persistência for necessário, a estrutura ideal é:

- `SaveManager` como camada responsável por serialização, validação e migração.
- `user://` como diretório de dados locais.
- Estrutura versionada do payload.
- Validação dos campos lidos antes de aplicar ao estado do jogo.
- Escrita atômica com backup simples em caso de falha.
- Tratamento explícito para arquivo ausente, inválido ou incompatível.

## Limitações conhecidas

- Não há persistência de personagens, armas, equipamento ou progresso.
- Não há economia online e não há dados competitivos armazenados localmente.
- Recomeçar o jogo restaura somente o estado da cena de preparação e do loadout atual, e não um perfil persistente.

## Conclusão

O estado atual é seguro por design para o escopo atual: nenhum dado sensível é salvo em disco e o jogo funciona de forma offline. O próximo passo, se necessário, é adicionar um `SaveManager` pequeno e versionado, sem expor qualquer valor de economia ou reputação ao cliente.
