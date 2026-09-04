# Modelo: Time_Tools — 3 Tools de tempo → **7 Tools**

- Autor original:            **a confirmar** ⚠️ — nenhum dos 26 scripts traz assinatura
- Origem:                    `timetools.rbxmx`, enviado no lote de 2026-08-27
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-27
- Status:                    **LIMPO** — passe §12.12.2 executado; falta licença
- Onde vive:                 `MODELOS_ENTRADA/Time_Tools/` · as **7 Tools** em `Tools/`

---

## ⛔ Primeiro o que importa: ele NÃO tem backdoor

O `reality_tools` deixou o repositório desconfiado, e com razão. Este modelo foi varrido pelos
mesmos critérios e passou limpo:

| Procurado | Achado |
|---|---|
| `require(<id numérico>)` | **zero** |
| `HttpService` / `http` / domínio externo | **zero** |
| `loadstring` / `getfenv` | **zero** |
| `MarketplaceService` | **zero** |

Os 26 scripts são todos locais. **Pode abrir no Studio sem medo** — ao contrário do
`reality_tools`, que continua em quarentena.

---

## O que é

**Três `Tool`**, e as três são mecânicas de tempo de verdade — não são reskin.

| Tool | Instâncias | Linhas | O que faz |
|---|---|---|---|
| `Celestial Staff` | ~120 | **1837** | cajado com portão de **Sol/Lua**: o M1 muda conforme a hora do dia |
| `Para o tempo` | 21 | 946 | **parada do tempo** — ancora, muda `TimeScale`, zera `PlaybackSpeed` |
| `reverter!!` | 6 | **353** | **rebobinar** — grava `CFrame` por 600 quadros e devolve |

Três cai exato no PISO da regra de distribuição, e o pedido foi 7 com três habilidades cada.

---

## A LÓGICA QUE VALE, E QUE FOI ESTUDADA (§12.12.1)

A lógica de terceiro não entra em Tool. O que entra é o que ela ENSINA, e este modelo ensina
seis coisas que o repositório não tinha:

### 1. Parar o tempo é mexer em quatro eixos, não um

`Para o tempo/Main` faz quatro coisas ao mesmo tempo, e é a soma que lê como tempo parado:

```lua
v.Anchored = true                     -- as peças
v.TimeScale = 0                       -- os ParticleEmitter, Smoke, Fire, Sparkles
tween(v, {PlaybackSpeed = 0})         -- os Sound que estavam tocando
stopScript.Parent = char              -- os outros Humanoid
```

**Congelar só as peças não lê como tempo parado** — lê como lag. O que vende é a partícula
travada no ar e o som escorregando para o grave.

### 2. Rebobinar é gravar `CFrame` num vetor e devolvê-lo

`reverter!!` grava 600 quadros (`table.insert(positions, frame, obj.CFrame)`) e depois
percorre o vetor devolvendo cada um. Simples, e é a implementação certa.

### 3. O FANTASMA é o que faz a reversão ser legível

O detalhe que salva a habilidade: um clone semitransparente vermelho, 40 quadros À FRENTE do
objeto que está voltando.

```lua
beforeimage.CFrame = positions[frame + 40]
```

Sem ele o jogador vê um objeto teleportando; com ele vê de onde ele está voltando. Esse
fantasma virou o eixo de uma Tool inteira no conjunto novo (`Paradoxo`).

### 4. O portão Sol/Lua é tempo, não é céu

`SunIsVisible` / `MoonIsVisible` usam `Lighting:GetSunDirection()` e um raycast para cima. O M1
do cajado **é outra habilidade** conforme a hora do dia: chuva de fótons no sol, lâmina no
luar. É a única mecânica de HORA que já entrou aqui, e ela ficou.

### 5. Peça criada DURANTE a parada também tem de parar

`Para o tempo/Main/Parts` liga `workspace.ChildAdded` e ancora o que nascer no meio. Detalhe
que quase todo tempo-parado esquece.

### 6. O `Timestop` é um `BoolValue` que outros scripts leem

Estado publicado em vez de escondido. A ideia ficou; a forma virou tabela no Server.

---

## O QUE NÃO PRESTA, E POR QUE NÃO ENTRA

| Na origem | Por quê |
|---|---|
| `workspace:GetDescendants()` em três lugares | varredura do mundo inteiro; ancora o mapa de todo mundo |
| `ColorCorrectionEffect` + `BlurEffect` em `Lighting` | **proibido** — os dois são estado global do place |
| `ScreenGui` (`BlindGuiPhoton`, `Controls UI`) | **proibido** dentro de Tool |
| 6 `Animation` + 8 `LoadAnimation` | **proibido** — asset de animação |
| `ServerStorage` para `CelestialStaffIntances` | Regra nº 1; e não replica, então o cliente não vê |
| `DirectionInvoker:InvokeClient` **dentro de laço** | o servidor ESPERA o cliente, três vezes por fóton |
| `v:Destroy()` em descendente de personagem | desmonta personagem alheio sem volta |
| `:Emit(` no servidor | não replica |
| `math.random(1,#Times)` para a cadência | cada cliente veria outra chuva |
| `wait()` e `delay()` | proibidos |
| Restauração sem guarda | Tool destruída no meio deixa o mapa ancorado **para sempre** |

O último é o pior e é o motivo de o conjunto novo ter `restaurar()` em `Tool.Destroying`.

---

## SFX — 14 ids, todos catalogados em `SFX/ids.md`

## MALHAS — 6 ids, todos catalogados em `MALHAS/ids.md`

## Texturas

`84102386` (Celestial Staff) · `200182847` (Core) · `282305485` (Shatter) ·
`4601913854` (Trail) · `11427939947` (ícone de `Para o tempo`)
