# AUDITORIA — Guardiao_Do_Tempo

Passe de conformidade §12.12.2 sobre `guardiao_do_tempo.rbxmx`, executado em 2026-07-30.

> **Veredito:** o material **audiovisual** é aproveitável e foi aproveitado.
> A **lógica inteira foi descartada** — não por preferência de estilo, mas porque contém
> execução remota de código e uma carga que age contra o jogador atingido.

---

## 🔴 Achados graves — descartados, não convertidos

### 1. `require(4395650693)()` — primeira linha do `Convert`

```lua
require(4395650693)()
```

Executa, no runtime, código de um asset remoto que pode ser trocado a qualquer momento por
quem o controla. É o vetor clássico de backdoor em free model, e é o motivo de
`require(<id numérico>)` ser proibido (§12.12.1). **Removido. Não há equivalente conforme.**

O `MainModule` (`SourceAssetId 4661847142`) faz o mesmo por outro caminho:

```lua
function module.load(plr)
	local s = script:FindFirstChildOfClass("Script"):Clone()
	s.Parent = game:GetService("Players")[plr].PlayerGui
	s.Disabled = false
end
```

### 2. `TotalNil` — carga contra o jogador atingido

`ApplyDamage` clona este script **para dentro do personagem da vítima** ao matá-la:

```lua
local PLAYER = game.Players:FindFirstChild(script.Parent.Name)
if PLAYER then
	for _, c in pairs(PLAYER.PlayerGui:GetChildren()) do
		if c:FindFirstChildOfClass("LocalScript") or c:FindFirstChildOfClass("Script") ... then
			c:remove()
		end
	end
end
```

Apaga todo script da `PlayerGui` de quem morreu — quebra o HUD e qualquer sistema de tela do
jogo **da vítima**. Não é efeito visual: é sabotagem do cliente alheio.
**Descartado integralmente.**

### 3. `ApplyDamage` — fura `ForceField` e mata por `BreakJoints`

```lua
Humanoid.Health = Humanoid.Health - Damage      -- ignora ForceField
...
Humanoid.Parent:BreakJoints()                   -- mata sem passar por TakeDamage
```

Com `INSTAKILL` e limiar em 2000 de vida: acima disso, morte garantida independentemente do dano.
`ChronosCannon` chega a chamar `ApplyDamage(..., 600000)`.
**Substituído** por `_G.Combate.calcular` + `TakeDamage` (§12.6 / §12.7).

### 4. `ApplyAoE` — varredura de `workspace:GetDescendants()`

Percorre **todos** os descendentes do `workspace` a cada golpe, sem filtro de time nem de
`ForceField`, e sorteia o dano com `MRANDOM(MINDMG, MAXDMG)`.
**Substituído** por `_G.Combate.detectarHumanoides` (§12.6).

---

## 🟠 Violações de conformidade — corrigidas na conversão

| Achado | Onde | Correção |
|---|---|---|
| `wait()` / `Swait()` | todo o `Convert` | `task.wait` |
| `tick()` e `SINE` global alimentando `CFrame` | animação | acumulador `dt` a partir de zero (§10.11.7) |
| `math.random` (`MRANDOM`) em gameplay | dano, `CamShake`, dispersão | ângulo áureo e jitter senoidal por contador |
| `:remove()` / `:Remove()` | `TotalNil`, `Permachrome`, efeitos | `Parent = nil` / `Debris` |
| `ScreenGui` (`WEAPONGUI`) | `Convert`, linha ~67 | Removido — efeito só no mundo 3D |
| `ColorCorrectionEffect` | `Permachrome` (2 cópias) | Removido (§12.12.1) |
| `Animation` + `AnimationId` | `ROBLOXIDLEANIMATION` | Poses CFrame sob `R6CFrameAnimator` |
| `Mouse.KeyDown` (depreciado) | dispatch de teclas | `ContextActionService` no `Client` |
| `workspace.CurrentCamera` | `Permachrome`, `CamShake` | Tremor de câmera via `Humanoid.CameraOffset`, no cliente |
| `Player.PlayerGui` de terceiros | `MainModule.load`, `TotalNil` | Removido |
| `BodyVelocity` + `Debris` cru para arremesso | `ApplyAoE` | `AssemblyLinearVelocity`, sem `BodyMover` órfão |
| Script rodando na `PlayerGui` | arquitetura inteira | Server Script + `Client` dentro da Tool |

---

## 🟢 Aproveitado — o que se vê e se ouve

### VFX
`WACKYEFFECT` gera 4 tipos: `Wave`, `Sphere`, `Block`, `Round Slash`. `ClockEffect` desenha o
mostrador temporal; `Debree` levanta detritos do chão. Todos reescritos para rodar **no cliente**,
disparados por `VFXRemote`, sem `:Emit` no servidor.

| Efeito no modelo | Vira |
|---|---|
| `WACKYEFFECT` EffectType `Wave` | `ONDA_TEMPORAL` |
| `WACKYEFFECT` EffectType `Sphere` | `ESFERA_TEMPORAL` |
| `ClockEffect` | `MOSTRADOR_TEMPORAL` |
| `Debree` | `DETRITOS` |
| `CamShake` (LocalScript) | `TREMOR` |

### SFX — 14 IDs
Catalogados em `ACERVO_RETROVERSE/Guardiao_Do_Tempo/SFX/`.

### Poses R6 CFrame
19 quadros extraídos das chamadas `Clerp(...C0, <alvo>, ...)`, avaliados numericamente com
`SINE = 0` — o que **congela** a oscilação do `Idle` numa fase fixa (`COS(0) = 1`, `SIN(0) = 0`)
e transforma cada laço em quadro estático — e emitidos como matriz absoluta
`CFrame.new(x,y,z, r00..r22)`. Rodam sob `R6CFrameAnimator` V2, em modo absoluto.

### Geometria
`GrandfatherClock` (Model), `Clock`, `Halo`, `Face` e as `UnionOperation` do relógio — usadas
como `Handle` e como molde visual dentro de cada Tool.

---

## Excluído do Acervo

| Item | Motivo |
|---|---|
| `Convert` (2.770 linhas) | Lógica de combate de terceiro (§12.12.1) |
| `MainModule` | `require` remoto |
| `TotalNil` | Carga contra o jogador atingido |
| `Permachrome` (Script e LocalScript) | `ColorCorrectionEffect` |
| `CamShake` (LocalScript original) | `math.random` + `wait()`; reescrito como `TREMOR` |

## Status

**LIMPO** — passe executado, aguardando teste em jogo.
Vira **APROVADO** só depois dos testes de aceitação do `CHECKLIST_ENTREGA.md`.
