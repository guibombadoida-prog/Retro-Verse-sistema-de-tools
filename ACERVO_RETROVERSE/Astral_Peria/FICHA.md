# Modelo: AstralPeriastron

- Autor original:            não declarado ⚠️  (espada conhecida do Toolbox)
- Origem:                    `astral_peria.rbxmx` — Tool completa, 260 instâncias
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-06
- Status:                    **LIMPO** — passe §12.12.2 executado
- Onde vive:                 `MODELOS_ENTRADA/Astral_Peria/` · clonado em `Tools/`

## O que saiu daqui

As **5 Tools** do conjunto Astral. A primeira leva as habilidades ORIGINAIS; as
outras quatro são clones com duas habilidades novas cada, no mesmo tema.

| Tool | M1 | X |
|---|---|---|
| `Astral Periastron` | Golpe / investida (semeia orbes) | Q redireciona · E detona · X Pulsar |
| `Astral Nova` | Nova Estelar (cone) | Colapso Anão |
| `Astral Cometa` | Cometa (projétil) | Chuva Sideral |
| `Astral Singularidade` | Horizonte de Eventos | Espaguetificação (cutscene) |
| `Astral Constelacao` | Traço Sideral (marca) | Sentença da Constelação |

## Números do original, preservados

| | |
|---|---|
| Golpe | 27 de dano · clique duplo ≤ 0.2 s vira investida |
| Orbe | 2 por investida · vida 25 s · raio 20 · dano 25 |
| Redirecionar | CD 1 s · velocidade 100 |
| Pulsar | CD 60 s · duração 30 s · alcance 200 · 15 por pulso · fere o portador em 34 |

## Passe de conformidade §12.12.2 — EXECUTADO

**Nenhuma linha dos 4826 do modelo entrou em Tool.** O código é autoral; o que
veio foram os números e a cadência. Violações medidas no original:

| Violação | Ocorrências |
|---|---|
| `AncestryChanged` | 82 |
| `wait/spawn/delay` | 63 |
| `:Destroy()` / `:Remove()` | 46 |
| `math.random` | 33 |
| `ScreenGui` / `PlayerGui` | 23 |
| `ServerStorage` / `ServerScriptService` | 23 |
| `+=` / `continue` | 17 |
| `ReplicatedStorage` | 13 |
| `Animation` / `LoadAnimation` | 12 assets + 1 chamada |
| `tick()` | 10 |
| `workspace:FindFirstChild` | 4 |
| `require(<id>)` | 2 |
| `Instance.new("Explosion")` | 1 |
| `Humanoid.Health =` | 1 |

Correções que mudam comportamento, e por quê:

- **`Humanoid.Health = 10` → `TakeDamage`.** Escrever em `Health` ignora
  `ForceField` e a redução registrada pelo Núcleo. O original matava quem tinha
  acabado de nascer.
- **`IsTeamMate` / `TagHumanoid` → `_G.Combate`.** Regra de combate tem uma
  porta só (§12.2).
- **RemoteFunction de mira → `AcaoRemote` (RemoteEvent).** RemoteFunction
  cliente→servidor pendura a thread do servidor se o cliente não responde.
- **`math.random` → ângulo áureo e índice sequencial.** A paleta de 9 cores do
  original virou índice sequencial: mesma variedade, e os dois clientes veem a
  mesma cor.

## O que foi RESGATADO de dentro dos scripts

O modelo guardava a identidade visual dentro do código. Antes de podar os
scripts, saiu tudo para `Tool/Moldes/`, guardado **apagado**:

`Pulsar` (mesh, trail, 4 emissores, luz, highlight) · `OrbCore` · `OrbOutline` ·
`Particles/Astral Pulsar` (2 emissores) · `Sounds/Astral Pulsar` (2 sons) ·
`OrbSpawns` · `CelestialCircle` (SurfaceGui — GUI de mundo 3D, pode ficar)

Dois `Sound` do original vinham **sem `SoundId`** e não foram resgatados: som
morto é peso morto.

## O que foi REMOVIDO, e por quê

| Removido | Motivo |
|---|---|
| 5 `ScreenGui` (Astral_UI, cooldowns de Q/E/X) | "efeito só no mundo 3D" |
| 12 `Animation` (R6 e R15) | REGRA_ANIMACAO_R6 — pose é tabela CFrame |
| 47 scripts (4826 linhas) | código de terceiro não entra em Tool |
| `MouseInput` (RemoteFunction) | vetor de trava do servidor |

## Para sair de LIMPO e virar APROVADO

Falta **autor**, **licença** e o teste em jogo.
