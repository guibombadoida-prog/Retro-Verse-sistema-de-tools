# Xester_Forma2_O_Despertar — inventário de lógica

> ⚠️ **Isto é CONSULTA, não material de reuso.** Lógica de combate de
> terceiro **não entra em Tool** (§12.12.1). Está catalogada para se saber
> o que cada habilidade fazia, e então reimplementá-la conforme, pelo Núcleo.

## Teclas encontradas

`Name`

## Dano aplicado

| Script | Chamada |
|---|---|
| `xesterv2` | `Health = victim.Health - damage` |
| `xesterv2` | `Health = math.huge` |
| `xesterv2` | `Health = math.huge` |
| `Health` | `Health = math.min(Humanoid.Health + dh, Humanoid.MaxHealth)` |
| `core` | `Health = 375` |
| `core` | `Health = 375` |
| `core` | `Health = victim.Health - damage` |

## Achados do passe §12.12.2

| Achado | Ocorrências | Situação |
|---|---|---|
| `Animation` — asset de Animation é proibido — virar pose CFrame (§10) | 9 | ❌ excluir |
| `ScreenGui` — ScreenGui é proibido dentro da Tool (§12.12.4) | 1 | ❌ excluir |
| math.random em gameplay — proibido (§10) | 216 | ❌ corrigir |
| :Destroy() em instância — usar Parent = nil / Debris | 100 | ❌ corrigir |
| wait() — usar task.wait | 63 | ❌ corrigir |
| BreakJoints — fura ForceField | 5 | ❌ corrigir |
| tick() — usar acumulador dt / os.clock | 3 | ❌ corrigir |
| AncestryChanged — usar Tool.Destroying | 2 | ❌ corrigir |
| LoadAnimation — virar pose CFrame | 2 | ❌ corrigir |

## Scripts

| Linhas | Classe | Caminho |
|---|---|---|
| 2366 | `Script` | `xesterv2` |
| 979 | `Script` | `enemy/core` |
| 538 | `LocalScript` | `char/Animate` |
| 398 | `LocalScript` | `char/Sound/LocalSound` |
| 321 | `Script` | `skullscript` |
| 91 | `LocalScript` | `die/LocalScript` |
| 85 | `Script` | `char/Sound` |
| 37 | `Script` | `enemy/ai` |
| 28 | `LocalScript` | `mousthingy` |
| 20 | `Script` | `char/Health` |
| 29 | `Script` | `skully/Weld` |
| 29 | `Script` | `head/Weld` |
| 29 | `Script` | `secondhead/Weld` |
| 29 | `Script` | `energb/Weld` |
| 29 | `Script` | `staff/Weld` |
| 26 | `Script` | `enemy/core/hammrmodel/Weld` |
| 26 | `Script` | `enemy/core/head/Weld` |
| 24 | `Script` | `Weld` |
| 7 | `ModuleScript` | `MainModule` |
| 1 | `LocalScript` | `camerascript` |

