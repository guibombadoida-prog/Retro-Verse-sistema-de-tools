# MAPA DE FIDELIDADE — Guardião do Tempo

Resposta direta à pergunta *"não está 100% fiel às habilidades?"*:

> **Não está, e não pode estar.** Três das nove habilidades terminam em **morte instantânea
> de todo mundo no mapa**, e uma quarta usa efeito de tela proibido. O resto é fiel.

Este documento diz, habilidade por habilidade, **o que o modelo faz**, **o que a Tool faz**, e
**por que** onde há diferença. Sem isso, "conversão fiel" é palavra solta.

| Marca | Significado |
|---|---|
| ✅ | Fiel — mesma mecânica, mesmo ritmo, mesmos números |
| 🔧 | Adaptado — mesma intenção, mecanismo diferente por exigência de regra |
| ⛔ | Não reproduzido — o original é proibido, e o motivo está escrito |

---

## Placar

| | Habilidades |
|---|---|
| ✅ Fiel | 4 — Chronostasis, TemporalTrap, SPEDUP, Taunt |
| 🔧 Adaptado | 2 — TemporalTemper, Temporalysis |
| ⛔ Desfecho não reproduzido | 3 — FastForward, ChronosCannon, GrandfatherTime |

As três do ⛔ são fiéis em **carga, ritmo, som e efeito**. O que muda é só o **desfecho**, que no
original é matar todo mundo.

---

## 1. `TemporalTemper` (Z) → **TemperoTemporal** 🔧

| | Modelo | Tool |
|---|---|---|
| Recolhimento | `ApplyAoE(HITPOS, 35, 0, 0, -15, false)` — puxa, sem dano | idem, puxão 15, raio 35 |
| Pulsos | 3 ondas (`for i = 1, 3`) | 3 pulsos, mesmo intervalo |
| Arremesso | `ApplyAoE(HITPOS, 15, 25, 35, 125, false)` | raio 15, arremesso 125 |
| Dano | `MRANDOM(25, 35)` | **30 fixo** |
| Alvo do golpe | `HITPOS` — raycast até o mouse | **posição do dono** |

**Duas diferenças, ambas declaradas:**

- **Dano fixo 30** no lugar do sorteio 25–35: `math.random` em gameplay é proibido (§10). 30 é a
  média exata do intervalo original.
- **Mira**: o modelo golpeia onde o mouse aponta; a Tool golpeia em volta do dono. Fazer a mira
  exige o cliente mandar o ponto pelo `AcaoRemote`, e isso é mudança de arquitetura — fica para
  uma V2, se você quiser. **Esta é a maior infidelidade que sobrou, e ela é minha, não da regra.**

---

## 2. `Chronostasis` (X) → **Cronostase** ✅

| | Modelo | Tool |
|---|---|---|
| Marca | guarda `TIMESPOT` + `TIMEVELOCITY` | guarda CFrame + `AssemblyLinearVelocity` |
| Retorno | `RootPart.CFrame = TIMESPOT`, devolve a velocidade | idem |
| Som | 782202168 no retorno | idem |
| Dano | nenhum | nenhum |

Fiel. O modelo não anima esta habilidade — as 3 poses da Tool são **autorais**, e estão
declaradas como tal no cabeçalho do arquivo de poses.

---

## 3. `FastForward` (C) → **AvancoRapido** ⛔ no desfecho

**Eu tinha convertido isto errado.** Na primeira entrega virou um *dash* que atropelava.
Não é dash: é uma **carga longa que termina numa detonação**.

| | Modelo | Tool |
|---|---|---|
| Surgimento | relógio na mão, 25 quadros, tique subindo | 0,42 s |
| Pausa | `wait(0.5)` | 0,50 s |
| Aceleração | 120 quadros, pitch do tique subindo | 2,00 s, 6 mostradores crescentes |
| Dono | `Rooted = true` — travado | `WalkSpeed`/`JumpPower` a 0, restaurados na saída |
| Tremor | `CamShake(pos, 125, 7, 35)` | `TREMOR` escala 2,4 |
| Esferas | 3, escala 50 / 100 / 150 | 3, escala 2,0 / 3,5 / 5,0 |
| **Desfecho** | **`workspace:GetDescendants()` → `CHILD:BreakJoints()` em todo Humanoid** | **180 de dano em raio 120, pelo Núcleo** |

⛔ **Por que o desfecho não foi reproduzido:** o original mata todo mundo do servidor, sem filtro
de time, sem checar `ForceField`, e ainda arranca as partes do corpo. É a lista de proibições
inteira de uma vez (§12.12.4: `Health -= dano` + `BreakJoints`). Reproduzir seria entregar uma
Tool que limpa o servidor a cada 60 segundos.

---

## 4. `ChronosCannon` (V) → **CanhaoCronos** ⛔ no dano

| | Modelo | Tool |
|---|---|---|
| Carga | sons 743521450 + 908895929, 2 mostradores | 0,55 s, mesma dupla de sons |
| Feixe | reto, à frente | 22 segmentos, alcance 220 |
| Tremor + detritos | `CamShake` 1×, `Debree` 1× | `TREMOR` + `DETRITOS` |
| **Dano** | **`ApplyDamage(HUM, 600000)`** | **120** |

⛔ 600000 não é dano, é morte garantida — e passava por `Health = Health - dano`, furando
`ForceField`. Aqui são 120 por `TakeDamage`, com o dano calculado pelo Núcleo.

**120 é número meu.** Não havia nada a preservar. É o primeiro que você vai querer revisar.

---

## 5. `Temporalysis` (B) → **Temporalise** 🔧

| | Modelo | Tool |
|---|---|---|
| Duração | `wait(7)` | 7,0 s |
| Raio | varredura ampla | 34 studs |
| Como prende | `PART.Anchored = true` + `BodyPosition` "TimeStopPosition" em cada parte | `WalkSpeed = 0` e `JumpPower = 0` no `Humanoid` |
| Visual da vítima | `Permachrome` — `ColorCorrectionEffect` cinza | removido |
| Soltura | `Undo.Value = true`, desancora | função de cancelamento guardada, chamada em `Died` e `Destroying` |

🔧 **Duas adaptações:**

- **Ancorar partes de outro jogador** deixa o personagem dele quebrado se qualquer coisa falhar
  no meio — e o modelo não tinha nenhuma rede de segurança. A parada no `Humanoid` é reversível
  e tem cancelamento obrigatório.
- **`ColorCorrectionEffect`** é proibido (§12.12.1): efeito de tela, não do mundo 3D.

---

## 6. `TemporalTrap` (G) → **ArmadilhaTemporal** ✅

| | Modelo | Tool |
|---|---|---|
| Dano de gatilho | `ApplyDamage(..., 65)` | **65** |
| Dano de respingo | `ApplyDamage(..., 15)` | **15** |
| Sons | 447682521, 782199941 | idem |
| Mostradores | 3 `ClockEffect` | 3 `MOSTRADOR_TEMPORAL` |

Fiel, inclusive nos dois números de dano. A Tool acrescenta teto de 2 armadilhas simultâneas e
recolhimento em `Died`/`Destroying` — o modelo não recolhia nada.

---

## 7. `GrandfatherTime` (Q) → **AvoDoTempo** ⛔ no desfecho

A maior sequência do modelo: 525 linhas, 11 camadas de som, `Vocal`, 2 `CamShake`.

| | Modelo | Tool |
|---|---|---|
| Voz | `Vocal(819312817)` | som `Voz`, mesmo ID |
| Tremor | `CamShake(HITPOS, 8.88e30, 8, 25)` — alcance efetivamente infinito | `TREMOR` escala 1,6 e 2,0 |
| Badalada | sons 850256806 / 1208650519 | som `Badalada`, 12 vezes |
| Trava | `GFT = true` até terminar | recarga global de 45 s |
| **Dano** | **`HUM.Health = HUM.Health - 0.0928` por quadro, depois `HUM.Health = 0`** | **55 × 12 badaladas, raio 46** |

⛔ O original **drena e depois zera a vida** — morte garantida, sem `TakeDamage`. A Tool troca
por 12 pulsos de 55, que preserva o **ritmo** (o dreno lento vira as doze horas batendo) sem
preservar a morte automática.

A redução de 45% no dono enquanto a ultimate corre é **acréscimo meu** — o modelo não tinha, mas
uma ultimate que trava o dono por ~3 s sem nenhuma proteção é armadilha para quem usa.

---

## 8. `SPEDUP` (M) → **Extra do AvancoRapido** ✅

| | Modelo | Tool |
|---|---|---|
| Velocidade | 16 ↔ 48 | **16 ↔ 48** |
| Som | 743521450, pitch 1.5 | idem |
| Efeito | `ClockEffect(pos, 12, 12)` | `MOSTRADOR_TEMPORAL` |

Fiel. A Tool acrescenta restauração obrigatória em `Unequipped`, `Died` e `Destroying` — sem
isso, o jogador ficaria com 48 de velocidade para sempre ao largar a Tool.

---

## 9. `Taunt` (T) → **Extra do AvoDoTempo** ✅

| | Modelo | Tool |
|---|---|---|
| Voz | `Vocal(819373088)` | som `Provocacao`, mesmo ID |
| Pose | 2 quadros | os mesmos 2 quadros, extraídos |
| Dano | nenhum | nenhum |

Fiel.

---

## O que foi perdido em todas, por regra

| Perdido | Onde estava | Motivo |
|---|---|---|
| `require(4395650693)` | 1ª linha do `Convert` | Execução de código remoto |
| `TotalNil` | ao matar alguém | Apagava a `PlayerGui` da vítima |
| `WEAPONGUI` (`ScreenGui`) | HUD da arma | `ScreenGui` proibido na Tool |
| `Permachrome` (`ColorCorrection`) | Temporalysis, FastForward | Efeito de tela proibido |
| `ROBLOXIDLEANIMATION` | Idle | `Animation` asset proibido — virou pose CFrame |
| Sorteio de dano (`MRANDOM`) | TemporalTemper, ApplyAoE | `math.random` em gameplay proibido |
| Mira por `Mouse.Hit` | TemporalTemper e outras | Arquitetura: exige o cliente mandar o ponto |

---

## Se você quiser mais fidelidade

Três coisas dependem só de decisão sua:

1. **Mira pelo mouse** — o `Client` manda o ponto pelo `AcaoRemote`, o servidor valida distância.
   Devolve o `HITPOS` original ao `TemperoTemporal` e ao `CanhaoCronos`. É a que mais muda o jogo.
2. **Números de dano** — 180, 120 e 55×12 são meus. Diga os que você quer e eu troco no `CFG`.
3. **Cinza da Temporálise** — se você aceitar um efeito no mundo 3D em vez de `ColorCorrection`
   (por exemplo, esmaecer o material das vítimas), dá para recuperar a leitura visual sem
   quebrar a §12.12.1.
