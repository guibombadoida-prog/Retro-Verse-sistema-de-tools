# Xester_Forma1 — inventário de lógica

> ⚠️ **Isto é CONSULTA, não material de reuso.** Lógica de combate de
> terceiro **não entra em Tool** (§12.12.1). Está catalogada para se saber
> o que cada habilidade fazia, e então reimplementá-la conforme, pelo Núcleo.

## Dano aplicado

| Script | Chamada |
|---|---|
| `un` | `math.random(17,35` |
| `un` | `math.random(17,35` |
| `un` | `math.random(55,85` |
| `un` | `math.random(.1,1` |
| `un` | `math.random(36,55` |
| `un` | `math.random(7,12` |
| `un` | `math.random(23,44` |
| `un` | `math.random(27,48` |
| `un` | `math.random(10,20` |
| `un` | `math.random(4+x,10+x` |
| `un` | `math.random(r/1.1,r` |
| `un` | `Health = math.huge` |
| `un` | `Health = math.huge` |

## Achados do passe §12.12.2

| Achado | Ocorrências | Situação |
|---|---|---|
| math.random em gameplay — proibido (§10) | 109 | ❌ corrigir |
| wait() — usar task.wait | 53 | ❌ corrigir |
| tick() — usar acumulador dt / os.clock | 3 | ❌ corrigir |
| BreakJoints — fura ForceField | 2 | ❌ corrigir |
| AncestryChanged — usar Tool.Destroying | 2 | ❌ corrigir |

## Scripts

| Linhas | Classe | Caminho |
|---|---|---|
| 3477 | `Script` | `un` |
| 107 | `LocalScript` | `Handler` |
| 85 | `ModuleScript` | `replicator` |
| 9 | `ModuleScript` | `MainModule` |

