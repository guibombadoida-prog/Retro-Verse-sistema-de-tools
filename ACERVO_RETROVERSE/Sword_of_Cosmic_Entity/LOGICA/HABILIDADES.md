# Sword_of_Cosmic_Entity — inventário de lógica

> ⚠️ **Isto é CONSULTA, não material de reuso.** Lógica de combate de
> terceiro **não entra em Tool** (§12.12.1). Está catalogada para se saber
> o que cada habilidade fazia, e então reimplementá-la conforme, pelo Núcleo.

## Teclas encontradas

`ButtonL2`, `ButtonR2`, `ButtonX`, `E`, `Q`, `X`

## Dano aplicado

| Script | Chamada |
|---|---|
| `Server` | `30` |
| `Server` | `40` |
| `Server` | `10` |
| `Server` | `5` |
| `Server` | `10` |

## Achados do passe §12.12.2

| Achado | Ocorrências | Situação |
|---|---|---|
| `Animation` — asset de Animation é proibido — virar pose CFrame (§10) | 6 | ❌ excluir |
| math.random em gameplay — proibido (§10) | 39 | ❌ corrigir |
| :Destroy() em instância — usar Parent = nil / Debris | 12 | ❌ corrigir |
| IsTeamMate reimplementado — a porta é o Núcleo | 8 | ❌ corrigir |
| wait() — usar task.wait | 5 | ❌ corrigir |
| :Emit no servidor — o servidor transmite, não emite | 5 | ❌ corrigir |
| LoadAnimation — virar pose CFrame | 4 | ❌ corrigir |
| tick() — usar acumulador dt / os.clock | 3 | ❌ corrigir |
| require de id numérico — proibido (§12.12.1) | 1 | ❌ corrigir |

## Scripts

| Linhas | Classe | Caminho |
|---|---|---|
| 1363 | `Script` | `Sword of Cosmic Entity (Revamped)/Server` |
| 122 | `LocalScript` | `Sword of Cosmic Entity (Revamped)/Client` |
| 33 | `Script` | `Sword of Cosmic Entity (Revamped)/Server/Tween3` |
| 32 | `Script` | `Sword of Cosmic Entity (Revamped)/Server/tweenring` |
| 31 | `Script` | `Sword of Cosmic Entity (Revamped)/Server/Tween2` |
| 13 | `Script` | `Sword of Cosmic Entity (Revamped)/Server/SlashTween` |
| 21 | `Script` | `Sword of Cosmic Entity (Revamped)/Server/tweenball` |
| 21 | `Script` | `Sword of Cosmic Entity (Revamped)/Server/tween4` |
| 15 | `LocalScript` | `Sword of Cosmic Entity (Revamped)/Server/ShakeCam` |
| 20 | `Script` | `Sword of Cosmic Entity (Revamped)/Server/tween1` |
| 16 | `Script` | `Sword of Cosmic Entity (Revamped)/remove` |


---

## As habilidades — o que cada uma fazia

Quase tudo mora num `Server` de **1363 linhas**. O `Client` manda a tecla por
`Remote:FireServer(Enum.KeyCode.X)` e o servidor despacha por `keyCode ==`.

| Tecla | Função | Guarda | Dano | O que faz |
|---|---|---|---|---|
| `E` | `Supernova` | `supernovaOn` e `astralisuse == false` | **30** | Explosão estelar: `Nova_Circle` + `Nova_Wave` + `Core`, som `Supernova` |
| `Q` | bloco de ~300 linhas | `tool.Enabled` | **40**, **10**, **5** | Shuriken: invoca `ShurikenModel`, arremessa com 4 `Trail`, explode (`ShurikenExplode`), corta (`Cut`), estilhaça (`Shatter`) |
| `X` | teleporte + `TpExplode` | `teleportOn` e `astralisuse == false` | **10** | Marca alvo (`Locked On`), teleporta (`TeleportActive`) e detona no destino |

Os `Script`s auxiliares — `tween1`, `Tween2`, `Tween3`, `tween4`, `tweenring`,
`tweenball`, `SlashTween` — são **animação de propriedade por TweenService**, cada um
com `TimeTrans`, `TimeTween` e `Size` em `NumberValue`. São curtos (13 a 33 linhas) e o
padrão é limpo: dá para reaproveitar a ideia direto no `VFXModule`, no cliente.

### O que precisa de decisão na conversão

- **`astralisuse`** é uma trava global de "está usando ultimate" que impede E e X ao
  mesmo tempo. No nosso sistema isso é `ChaveRecarga` compartilhada entre Tools irmãs
  (§12.4) — e fica mais robusto, porque vale por jogador e não por instância.
- **Dano baixo e espalhado** (30 / 40 / 10 / 5) sugere que o modelo aplica dano em
  tique, dentro dos laços. Ao converter, isso vira dano único por alvo com
  `jaAtingidos`, ou fica explicitamente como dano por tique — decisão de jogo.
- **`Camera` e `ShakeCam`** mexem na câmera do jogador. O tremor vira `TREMOR` no
  cliente, via `Humanoid.CameraOffset` (já existe no Acervo, em `Guardiao_Do_Tempo`).
- **`remove`** (16 linhas) é um script de limpeza do próprio modelo — não vai para Tool.

### O que é bom e vale reusar

O acervo visual deste modelo é o maior dos três: **33 efeitos**, com `Nova_Circle`,
`Nova_Wave`, `MegaWave`, `SwirlShockwaveFire`, `WindWave`, `Ring22` e o `ShurikenModel`
com quatro trilhas casadas. Os `MeshId` estão todos catalogados em `MALHAS/ids.md` e
funcionam sem o modelo original — é só recriar a instância dentro da Tool.

`MegaWave` usa `rbxassetid://863344136`, o **mesmo mesh** do `Shockwave_2` do Jupiter.
Primeiro reuso cruzado detectado entre modelos do Acervo.
