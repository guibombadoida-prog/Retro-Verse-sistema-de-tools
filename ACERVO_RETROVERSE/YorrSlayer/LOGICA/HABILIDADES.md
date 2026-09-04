# YorrSlayer — inventário de lógica

> ⚠️ **Isto é CONSULTA, não material de reuso.** Lógica de combate de
> terceiro **não entra em Tool** (§12.12.1). Está catalogada para se saber
> o que cada habilidade fazia, e então reimplementá-la conforme, pelo Núcleo.

## Teclas encontradas

`ButtonR1`, `ButtonY`, `E`, `Q`, `X`

## Dano aplicado

| Script | Chamada |
|---|---|
| `Server` | `DAMAGE` |
| `Server` | `DAMAGE` |
| `Server` | `100` |
| `Server` | `35` |
| `Server` | `Health = 0` |

## Achados do passe §12.12.2

| Achado | Ocorrências | Situação |
|---|---|---|
| `Animation` — asset de Animation é proibido — virar pose CFrame (§10) | 8 | ❌ excluir |
| `ColorCorrectionEffect` — efeito de tela — proibido (§12.12.1) | 1 | ❌ excluir |
| `ScreenGui` — ScreenGui é proibido dentro da Tool (§12.12.4) | 1 | ❌ excluir |
| math.random em gameplay — proibido (§10) | 23 | ❌ corrigir |
| :Destroy() em instância — usar Parent = nil / Debris | 14 | ❌ corrigir |
| tick() — usar acumulador dt / os.clock | 11 | ❌ corrigir |
| :Emit no servidor — o servidor transmite, não emite | 7 | ❌ corrigir |
| LoadAnimation — virar pose CFrame | 7 | ❌ corrigir |
| wait() — usar task.wait | 5 | ❌ corrigir |
| IsTeamMate reimplementado — a porta é o Núcleo | 4 | ❌ corrigir |
| require de id numérico — proibido (§12.12.1) | 2 | ❌ corrigir |

## Scripts

| Linhas | Classe | Caminho |
|---|---|---|
| 1076 | `Script` | `YorrSlayer/Server` |
| 227 | `LocalScript` | `YorrSlayer/Client` |
| 140 | `Script` | `YorrSlayer/Server/Curse_of_Defenseless` |
| 79 | `Script` | `YorrSlayer/Server/CharacterBoostStats` |
| 53 | `Script` | `YorrSlayer/Server/Vine_Trap` |
| 49 | `Script` | `YorrSlayer/Yorr the Jungle Dragon v1.5/Die` |
| 32 | `Script` | `YorrSlayer/Yorr the Jungle Dragon v1.5/Appear/Tween2` |
| 32 | `Script` | `YorrSlayer/Server/Tween2` |
| 13 | `Script` | `YorrSlayer/Server/SlashTween` |
| 21 | `Script` | `YorrSlayer/Yorr the Jungle Dragon v1.5/Appear/tween1` |
| 18 | `Script` | `YorrSlayer/Server/TweenSord` |
| 15 | `LocalScript` | `YorrSlayer/Server/ShakeCam` |
| 18 | `Script` | `YorrSlayer/remove` |
| 7 | `Script` | `YorrSlayer/Yorr the Jungle Dragon v1.5/Appear` |
| 11 | `Script` | `YorrSlayer/Server/fade` |
| 12 | `Script` | `YorrSlayer/Server/FakeDebris` |

