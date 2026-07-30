# Guardião do Tempo — SFX

14 IDs catalogados do `Convert`. Volume e pitch são os do modelo original, já dentro das
faixas de `_PADROES.md`. No Studio, cada um vira um `Sound` **dentro da Tool**, em `Tool/SFX/`.

## `IMPACTO_TEMPORAL` — golpe, corte, onda

| ID | Volume | Pitch | Onde era usado |
|---|---|---|---|
| `rbxassetid://588694531` | 5 | 1.0 · 0.6 | TemporalTemper, ChronosCannon, GrandfatherTime |
| `rbxassetid://588738949` | 5 | 1.0 | Chronostasis, onda de TemporalTemper |
| `rbxassetid://782199941` | 6 | 1.5 | Chronostasis, TemporalTrap |
| `rbxassetid://588697034` | 5 | 1.0 | `WACKYEFFECT` SoundID |
| `rbxassetid://588736245` | 5 | 1.0 | `WACKYEFFECT` SoundID |
| `rbxassetid://908895929` | 2 | 1.5 | ChronosCannon |

## `ENGRENAGEM` — mecanismo, tique, aceleração

| ID | Volume | Pitch | Onde era usado |
|---|---|---|---|
| `rbxassetid://743521450` | 2 – 10 | 0.8 · 1.5 · 3.0 | Aceleração, FastForward, Temporalysis, ChronosCannon |
| `rbxassetid://447682521` | 0 – 10 | 0.7 | FastForward, Temporalysis, TemporalTrap |
| `rbxassetid://765590102` | 7 | 0.6 | GrandfatherTime |
| `rbxassetid://782353117` | 6 | 1.8 | GrandfatherTime |
| `rbxassetid://782202168` | 5 | 1.0 | Chronostasis — retorno ao ponto marcado |

> `Volume = 0` no original é som de **loop** ligado depois, não som mudo. Ao montar no Studio,
> começar em 0 e subir por código, ou deixar 0.4 se o loop não for usado.

## `BADALADA` — relógio, ultimate

| ID | Volume | Pitch | Onde era usado |
|---|---|---|---|
| `rbxassetid://850256806` | 10 | 1.0 | GrandfatherTime |
| `rbxassetid://1208650519` | 8 | 1.0 | GrandfatherTime |
| `rbxassetid://228343433` | 0 | 0.5 | GrandfatherTime — camada grave de fundo |
| `rbxassetid://198360470` | 10 | 1.5 | GrandfatherTime |
| `rbxassetid://231917744` | 6 | 1.0 | GrandfatherTime |
| `rbxassetid://233856097` | 6 | 0.8 | GrandfatherTime |

## `VOZ_GUARDIAO` — fala

| ID | Volume | Pitch | Onde era usado |
|---|---|---|---|
| `rbxassetid://819312817` | 7 | 1.0 | `Vocal` em GrandfatherTime |
| `rbxassetid://819373088` | 7 | 1.0 | `Vocal` em Taunt |

## Montagem

- `RollOffMaxDistance` **60** para golpe, **80** para ultimate — `_PADROES.md`.
- O `Sound` é **clonado** de `Tool/SFX/<nome>`; o script nunca cria `SoundId` solto (Regra nº 1).
- Ordem de impacto: **SFX primeiro**, antes de física, VFX e dano (§8 V2).

## Onde já foi usado

| Tool | SFX |
|---|---|
| TemperoTemporal_V1 | `Golpe` (588694531), `Onda` (588738949) |
| Cronostase_V1 | `Marca` (588738949), `Retorno` (782202168) |
| AvancoRapido_V1 | `Avanco` (447682521), `Aceleracao` (743521450) |
| CanhaoCronos_V1 | `Carga` (743521450), `Disparo` (908895929) |
| Temporalise_V1 | `Parada` (447682521), `Retomada` (743521450) |
| ArmadilhaTemporal_V1 | `Plantar` (447682521), `Disparo` (782199941) |
| AvoDoTempo_V1 | `Badalada` (850256806), `Voz` (819312817), `Provocacao` (819373088) |
