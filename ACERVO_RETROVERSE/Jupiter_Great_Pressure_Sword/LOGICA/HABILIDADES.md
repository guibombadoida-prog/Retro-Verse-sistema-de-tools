# Jupiter_Great_Pressure_Sword — inventário de lógica

> ⚠️ **Isto é CONSULTA, não material de reuso.** Lógica de combate de
> terceiro **não entra em Tool** (§12.12.1). Está catalogada para se saber
> o que cada habilidade fazia, e então reimplementá-la conforme, pelo Núcleo.

## Teclas encontradas

`ButtonL1`, `ButtonX`, `ButtonY`, `E`, `Q`, `X`

## Dano aplicado

| Script | Chamada |
|---|---|
| `Disintegration` | `Health = 0;` |
| `GearObject` | `Object,Damage` |
| `GearObject` | `Damage` |
| `GearScript` | `45` |
| `GearScript` | `99` |
| `JupiterOmni` | `1` |
| `JupiterOmni` | `750` |
| `Disintegrate` | `Health = 0` |
| `New_Lightning` | `11` |

## Achados do passe §12.12.2

| Achado | Ocorrências | Situação |
|---|---|---|
| `Animation` — asset de Animation é proibido — virar pose CFrame (§10) | 6 | ❌ excluir |
| `BillboardGui` — GUI de mundo: revisar caso a caso | 1 | ❌ excluir |
| `ColorCorrectionEffect` — efeito de tela — proibido (§12.12.1) | 4 | ❌ excluir |
| `ScreenGui` — ScreenGui é proibido dentro da Tool (§12.12.4) | 2 | ❌ excluir |
| `Sky` — Sky é proibido (§12.12.1) | 2 | ❌ excluir |
| :Destroy() em instância — usar Parent = nil / Debris | 69 | ❌ corrigir |
| wait() — usar task.wait | 37 | ❌ corrigir |
| math.random em gameplay — proibido (§10) | 16 | ❌ corrigir |
| TagHumanoid reimplementado — a porta é o Núcleo | 12 | ❌ corrigir |
| require de id numérico — proibido (§12.12.1) | 11 | ❌ corrigir |
| LoadAnimation — virar pose CFrame | 6 | ❌ corrigir |
| IsTeamMate reimplementado — a porta é o Núcleo | 5 | ❌ corrigir |
| :Emit no servidor — o servidor transmite, não emite | 4 | ❌ corrigir |
| AncestryChanged — usar Tool.Destroying | 4 | ❌ corrigir |
| spawn() — usar task.spawn | 4 | ❌ corrigir |
| tick() — usar acumulador dt / os.clock | 1 | ❌ corrigir |
| BreakJoints — fura ForceField | 1 | ❌ corrigir |

## Scripts

| Linhas | Classe | Caminho |
|---|---|---|
| 260 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/New_Lightning/VFXModule/Lightning_Explosion/LightningBolt` |
| 260 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/VFXModule/Lightning_Explosion/LightningBolt` |
| 296 | `Script` | `Jupiter Great Pressure Sword/GearScript` |
| 219 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/VFXModule/Hit/LightningBoltParts` |
| 177 | `Script` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni` |
| 216 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/New_Lightning/VFXModule/Lightning_Explosion/LightningBolt/LightningExplosion` |
| 216 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/VFXModule/Lightning_Explosion/LightningBolt/LightningExplosion` |
| 239 | `LocalScript` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni/Disintegrate/Disintegration` |
| 167 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/VFXModule/Hit/LightningBoltParts/LightningExplosion` |
| 194 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/New_Lightning/VFXModule/Lightning_Explosion/LightningBolt/LightningSparks` |
| 194 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/VFXModule/Lightning_Explosion/LightningBolt/LightningSparks` |
| 164 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/VFXModule/Hit/LightningBoltParts/LightningSparks` |
| 122 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/GearObject` |
| 71 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni/VFXModule/Spiral_Explosion` |
| 120 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni/VFXModule/Orbs` |
| 84 | `LocalScript` | `Jupiter Great Pressure Sword/Client` |
| 60 | `Script` | `Jupiter Great Pressure Sword/GearScript/New_Lightning` |
| 136 | `Script` | `Jupiter Great Pressure Sword/GearScript/Tased` |
| 94 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni/VFXModule/Small_Nova` |
| 87 | `Script` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni/Disintegrate` |
| 89 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni/VFXModule/Impact_Frame` |
| 77 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/VFXModule/Hit` |
| 33 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/New_Lightning/VFXModule/Lightning_Explosion` |
| 33 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/VFXModule/Lightning_Explosion` |
| 40 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni/VFXModule/Shockwave_2` |
| 43 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni/CAMShake/Shake_Camera` |
| 41 | `ModuleScript` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni/VFXModule/ImpactFrameScript` |
| 32 | `LocalScript` | `Jupiter Great Pressure Sword/GearScript/Tased/Trippy` |
| 3 | `LocalScript` | `Jupiter Great Pressure Sword/GearScript/JupiterOmni/CAMShake` |
| 5 | `LocalScript` | `Jupiter Great Pressure Sword/GearScript/SettingFolder/DisableBackpack` |
| 5 | `LocalScript` | `Jupiter Great Pressure Sword/GearScript/SettingFolder/EnableBackpack` |


---

## As habilidades — o que cada uma fazia

Lido de `GearScript` (296 linhas) e dos scripts que ele aciona. O `Client` manda
a tecla por `Remote:FireServer(Enum.KeyCode.X)`; o servidor despacha e trava a
habilidade com um `wait(n)` — que é o modelo antigo de recarga, e vira
`_G.Combate.recargaGlobal` na conversão (§12.9).

| Tecla | Função | Recarga | Dano | O que faz |
|---|---|---|---|---|
| clique | `OnActiavted` → `OnSwordHit` | `Tool.Enabled` | **45** | Golpe pelo `Handle.Hitbox.Touched`; três `Slice` vermelhos no ponto de impacto |
| `E` | `OnUnwing` | 15 s | **99** | Varre humanoides num raio de **1500**, mas só acerta quem está **voando**; raio + `MeteorSmash` em cada alvo |
| `Q` | `OnJupiter` | 50 s | — | Invoca o planeta (`JupiterGearFolder/Jupiter`) com `Highlight` de buraco negro; cilindro de presença por 4,65 s |
| `X` | `OnJupiterNotice` | 75 s | **750** + desintegração | A ultimate: `JupiterOmni`, `Disintegrate` (`Health = 0`), 3 camadas de explosão, `Impact_Frame` |
| — | `Tased` | — | 11 | Efeito de choque com `Shock` e `Trippy`; aplicado por `New_Lightning` |

### O que precisa de decisão na conversão

- **`OnUnwing` só atinge quem voa.** É uma regra de alvo incomum e boa — mas o filtro
  `IsCharacterFlying` é lógica de terceiro. Reimplementar pelo Núcleo, ou trocar por
  alvo normal, é decisão de jogo.
- **`Disintegrate` usa `Health = 0`.** Morte garantida, furando `ForceField`. Vira
  `TakeDamage` com número de balanceamento (§12.7).
- **Raio de 1500 studs** é praticamente o mapa inteiro. Rever ao converter.
- **`Impact_Frame`** é `ScreenGui` + `ColorCorrectionEffect` + `Sky`: os três proibidos
  juntos. O efeito **não** tem equivalente conforme — o que sobra é a versão
  `ImpactFrameScript`, que usa `BillboardGui` (mundo 3D) em vez de `ScreenGui`.
- **`TagHumanoid` e `IsTeamMate`** estão reimplementados no `GearScript`. Saem: a porta
  é o Núcleo (§12.2).

### O que é bom e vale reusar

O `LightningBolt` / `LightningSparks` / `LightningExplosion` (260 + 194 + 216 linhas) é um
gerador de raio procedural completo, com três emissores casados. É o material mais
valioso destes dois modelos. Precisa do passe §12.12.2 — mas a **estrutura** dele é
reaproveitável quase inteira, porque é geometria e partícula, não regra de jogo.
