# Modelo: Stella's VFX Addon

- Autor original:            **Stellabotrus** (declarado no cabeçalho dos módulos)
- Origem:                    `vfx_module.rbxmx` — addon do *Takeo's VFX System*
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-05
- Status:                    **LIMPO** — passe §12.12.2 executado nos 10 efeitos em uso
- Onde vive:                 `VFX/` aqui no Acervo · copiado PARA DENTRO de cada Tool

## Onde este material roda

Dentro da Tool, em `VFXModule/Pack/`. **Nada é lido de `ReplicatedStorage`** — o Acervo é
prateleira de edição, e o material é copiado para dentro na montagem
(`FERRAMENTAS/clonar_tool.py`, função `enxertar_pack`).

> **Correção de rumo registrada.** Numa primeira versão eu pus este pack em
> `ReplicatedStorage` e declarei uma exceção à Regra nº 1, com o argumento de que ele não
> cabia dentro da Tool. O argumento valia para o `MainModule` — que se muda para lá sozinho
> e manda requerer por id — e eu generalizei do loader para o pack inteiro. Os módulos de
> efeito não dependem de nada e cabiam desde o começo. A exceção foi desfeita.
> Ver `DIRETRIZES/REGRA_AUTOCONTENCAO_ABSOLUTA.md`, "Um caso real".

## Os 10 efeitos em uso

Medido em cada arquivo: **zero `require`, zero `ReplicatedStorage`, zero `ServerStorage`,
zero dependência do Takeo.** Cada um é um `return function(...)` com os próprios moldes como
filhos.

| Efeito | Reforça, na ponte do `VFXModule` |
|---|---|
| `Shockwave` | `IMPACTO`, `IMPACTO_NOVA`, `ONDA_CHOQUE`, `RAJADA` |
| `Shockwave_2` | `IMPACTO_NOVA` |
| `Small_Nova` | `IMPACTO_NOVA` |
| `Smoky_Explosion` | `IMPACTO_NOVA`, `DESTROCOS`, `POEIRA` |
| `Shockwave_Explosion` | `DOMO` |
| `Small_Slash` | `CORTE`, `RETALHO`, `CORTE_X`, `GRADE_CORTES` |
| `Sonar_Ring` | `BLOQUEIO`, `PULSO_TRACAO`, `CICLONE`, `TEMPO_PARADO` |
| `Floor_Crack` | `RACHADURA_SOLO`, `DESTROCOS` |
| `Laser_Shot` | `FEIXE` |
| `Spiral_Effect` | `AURA`, `CICLONE` |

## Passe de conformidade §12.12.2 — EXECUTADO

`python3 FERRAMENTAS/conformar_pack_vfx.py`

| Módulo | O que foi corrigido |
|---|---|
| `Smoky_Explosion` | 3 `math.random(-360,360)` → ângulo áureo · 6 `math.random(-100,100)/100` → jitter senoidal · 1 `WaitForChild` → acesso direto |
| `Laser_Shot` | alias morto `random = math.random` / `Foreach = table.foreach` removido (nenhum dos dois era usado) |
| `Floor_Crack` | `workspace:FindFirstChild("Terrain")` → `workspace.Terrain` |
| `Shockwave`, `Shockwave_2`, `Small_Nova`, `Shockwave_Explosion`, `Sonar_Ring` | 1 `WaitForChild` → acesso direto, cada |
| `Small_Slash`, `Spiral_Effect` | nada a corrigir |

Restante após o passe, conferido pelo próprio script: **zero** `math.random`, `Random.new`,
`:Destroy()`, `wait/spawn/delay`, `tick()`, `continue`, `ReplicatedStorage`, `require(`,
`Lighting`/`ScreenGui`/`ColorCorrection`.

## Efeitos do pack que ficaram de fora

| Efeito | Por quê |
|---|---|
| `Flung_Debris`, `Particle_Debris` | `Part` não-ancorada com `AssemblyLinearVelocity` e `CanCollide` (o parâmetro é inerte — o módulo faz `CanCollide or true`). Detrito sólido no cliente empurra o próprio personagem: **VFX não mexe em gameplay** |
| `Impact_Frame` | troca o `Sky`, liga `ColorCorrection`, põe `ScreenGui` — as três proibidas dentro de Tool |
| `Sharp_Crater`, `Smooth_Crater` | varrem `workspace:GetDescendants()` a cada chamada |
| `Wind_Effect`, `Wind_Spiral` | exigem uma `Instance` de fora como âncora |
| `Fire_Circle` | contrato quebrado no próprio pack: usa `Size` como `Vector3` e chama `:Emit(Size)`, que espera número |

O `MainModule` e o `LightningBolt` **não entram**: o primeiro existe só para pôr o pack em
`ReplicatedStorage`, que é o que não queremos.

## Já usado em

As 7 Tools de `Tools/` (`Salvador`, `Proteção`, `Escudo Skate`, `Escudo Bumerangue`,
`Escudo Bloqueador`, `Escudo Cyclone`, `Escudo Partido`).

## Para sair de CRU/LIMPO e virar APROVADO

Falta a **licença** e o teste em jogo.
