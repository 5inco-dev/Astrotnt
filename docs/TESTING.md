# Testing

## Estado atual

O projeto usa testes Godot headless para validar arquitetura, combate, terreno e integração de interfaces. A suíte está organizada em scripts dentro de [tests/](../tests).

## Validação executada

A validação foi executada no ambiente local com a engine Godot disponível no sistema:

- Godot: 4.7.2.stable.official.ed1daf0bf
- Execução: headless
- Plataforma: Windows local

Comando executado:

```powershell
$godot = 'C:\Users\juninho\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
$tests = @(
  'tests/combat_test.gd',
  'tests/terrain_startup_test.gd',
  'tests/terrain_test.gd',
  'tests/arsenal_test.gd',
  'tests/phase3_test.gd',
  'tests/mobile_test.gd',
  'tests/feedback_test.gd',
  'tests/ballistic_test.gd',
  'tests/feel_test.gd',
  'tests/menu_test.gd'
)
foreach ($t in $tests) {
  & $godot --headless --path 'c:\Users\juninho\OneDrive\Desktop\Astrotnt-backend' --script $t --fixed-fps 60
}
```

## Resultados observados

Os resultados mostraram sucesso com zero falha em várias suítes críticas:

- `tests/combat_test.gd`: cobertura de turno, fases e combate; 0 falha
- `tests/terrain_startup_test.gd`: inicialização e suporte do mapa; 0 falha
- `tests/terrain_test.gd`: destruição do terreno e colisão; 0 falha
- `tests/arsenal_test.gd`: armas, dano, efeito e cenário de stress; 0 falha
- `tests/phase3_test.gd`: personagens, equipamentos, loadouts e reprodução de partida; 0 falha

Os logs também registraram PASS para os cenários principais e resultados como:

- `RESULT: 46 startup checks, 0 failure(s)`
- `RESULT: 32 checks, 0 failure(s)`
- `RESULT: 127 arsenal checks, 0 failure(s)`

## Limitações

- Testes headless não substituem validação real em Android.
- O ambiente não mede temperatura, FPS real em dispositivo móvel, toque físico nem performance em hardware limitado.
- O projeto ainda não inclui backend para autenticação, inventário ou partidas online.

## Recomendação

Manter a suíte headless como checagem de regressão principal, e complementar com validação manual em Android para ergonomia, touch, safe area, câmera e estabilidade real de renderização.
