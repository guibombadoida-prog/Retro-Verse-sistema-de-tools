# Modelo: Guest Tools — 7 Tools de rua

- Autor original:            **a confirmar** ⚠️ — parte já passou por mão deste projeto (ver abaixo)
- Origem:                    `guesdttools.rbxmx` (5 Tools) + `Guest_Tools_2_more.rbxmx` (2 Tools)
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **LIMPO** — passe §12.12.2 executado nas 7; falta licença
- Onde vive:                 `MODELOS_ENTRADA/Guest_Tools/` · as 7 Tools em `Tools/`

---

## O que é

**Sete `Tool` prontas**, em dois arquivos. As cinco primeiras chegaram no primeiro
(129 instâncias, 1463 linhas, 16 `Sound`, 79 `Weld`); `Diamond` e `A arma` chegaram no
segundo (299 instâncias, 1561 linhas, 118 `Motor6D`).

| Tool | Instâncias | Linhas | O que faz | Sons |
|---|---|---|---|---|
| `Taco de Baseball` | 15 | 676 | combo corpo a corpo, 2 tipos de golpe | 6 |
| `Cano De Rua` | 19 | 509 | golpe de cano, animação de porrada | 6 |
| `Abacate (roubado) do mexico` | 78 | 93 | consumível — cura 3 HP em 3 s | 2 |
| `Energetico` | 8 | 71 | consumível — cura 2 HP + `WalkSpeed` 22 por 5 s | 2 |
| `Humilhador` | 9 | 114 | provocação — sprite sobre a cabeça, 1.25 s | 1 (criado no código) |
| `Diamond` | 20 | 130 | tapa que arremessa + "virar pedra" | 1 |
| `A arma` | 279 | 1431 | revólver de seis tiros, por Rufus14 | 0 ⚠️ |

Na origem, **uma habilidade cada, quase zero `KeyCode`** (só o `Taco` tem `ButtonR2` e o
`Diamond` escuta `e` por `mouse.KeyDown`, que é depreciado). Sete cai **exato no teto** da
regra de distribuição — nenhuma se funde, nenhuma vira Extra de outra. Na entrega cada uma
ganhou uma habilidade **Extra**, com botão de toque.

---

## Este é o melhor candidato a conversão que já entrou aqui

Três motivos, e nenhum deles vale para os modelos anteriores.

### 1. A animação R6 já está na convenção do animator canônico

O `LeadpipeServer` abre soldando o rig **exatamente** como o `R6CFrameAnimator` V2 faz:

```lua
local rightarm = Instance.new("Weld", owner.Torso)
rightarm.Part0 = owner.Torso
rightarm.Part1 = owner["Right Arm"]
rightarm.C0 = CFrame.new(1.5, 0.5, 0)
rightarm.C1 = CFrame.new(0, 0.5, 0)
rightarm.Name = "RightArmWelde"
```

`RightArmWelde`, `LeftArmWelde`, `HeadWelde`, `HumanoidRootPartWelde` — `Weld` próprio a
partir do `Torso`, com o pivô do ombro em `C1`. É **o mesmo desenho** do animator do
repositório.

**78 escritas em `C0`/`C1` nas duas Tools de porrada, e ZERO `Motor6D`.** Compare com o
`Trident`, que faz 214 escritas direto em `Motor6D.C0` — as poses de lá precisam ser
convertidas de convenção; as daqui **entram direto**.

E o `Weld` nasce no servidor, que é onde ele precisa nascer: `Weld` criado em `LocalScript`
não replica, e isso já custou um bug de visibilidade neste repositório.

### 2. Parte já foi conformada por alguém para este projeto

Os cabeçalhos são em português e citam o projeto:

```
-- ServerScript_TacoDeBaseball_V1.1.lua
-- MODIFICAÇÕES V1.1: Dano NERFADO · Morte instantânea REMOVIDA · NPC não ataca dono/aliados
-- PROPRIEDADES OBRIGATÓRIAS DO PROJETO
tool.CanBeDropped = false
tool.RequiresHandle = true
```

```
-- Cano De Rua - Server script (LeadpipeServer) - VERSÃO NERFADA
humanoiddd.Health = humanoiddd.Health - math.random(10,15) -- Dano reduzido de 20-25 para 10-15
```

O `Taco` **já usa `TakeDamage`** (3 vezes) e já declara `CanBeDropped`/`RequiresHandle`.
As cinco já têm recarga e teto de uso por minuto. Não é modelo cru de Toolbox — é modelo
meio-caminho.

### 3. Os `Grip*` são escritos no servidor, que é o lugar certo

O `Abacate` e o `Energetico` animam o gesto de beber só com `GripForward` / `GripPos` /
`GripRight` / `GripUp`, do `Script` de servidor. Está certo: **`Grip*` não replica do
cliente.** É animação de graça, sem rig nenhum, e serve de molde para qualquer consumível.

---

## O que precisava mudar — e mudou

Tudo abaixo foi trocado na conversão. Ver o passe, no fim desta ficha.

| Achado | Quantos | Onde | O que a regra manda |
|---|---|---|---|
| `Health = Health - math.random(10,15)` | 2 | `Cano De Rua` | `TakeDamage` — respeita `ForceField` |
| `Health = Health + N` | 4 | `Abacate`, `Energetico` | cura também passa pelo Núcleo |
| `Instance.new("ScreenGui")` | 2 | `Cano De Rua` | proibido — efeito só no mundo 3D |
| `BreakJoints` | 1 | `Taco de Baseball` | destruição permanente não é dano |
| `workspace:GetDescendants()` | 2 | `Taco de Baseball` | ler o mundo é dependência (Regra nº 1) |
| `isAlly()` na própria Tool | 1 | `Taco de Baseball` | **regra de combate só no `NucleoCombate.lua`** |
| `math.random` | 41 | todas | ângulo áureo / jitter senoidal / índice sequencial |
| `wait()` | 47 | todas | `task.wait` |
| `spawn(` / `delay(` | 11 / 1 | todas | `task.spawn` / `task.delay` |
| `tick()` | 12 | todas | `os.clock()` para recarga |
| `:Destroy()` | 2 | — | `Parent = nil` / `Debris` |

O `isAlly` é o mais importante da lista: é um invariante do `CLAUDE.md`
(*"Zero `canDamage` / `IsTeamMate` / `TagHumanoid` fora de `NucleoCombate.lua`"*). Hoje o
`Taco` decide sozinho quem é aliado; isso tem de subir para o Núcleo, com fallback sob
guarda como em toda chamada.

### O `BillboardGui` do Humilhador — não é violação

A proibição é de `ScreenGui`, e a razão dela é *"efeito só no mundo 3D"*. Um `BillboardGui`
**vive no mundo 3D**, preso a uma parte. O `Humilhador` põe um sprite animado sobre a cabeça
por 1.25 s e some. Passa.

O que não passa é o `mainz` que anima o sprite: `spawn` + `wait(.05)` num `while true` sem
saída, e `script.Parent:Destroy()` no fim. O `Debris:AddItem(part, 5)` do servidor cobre o
vazamento, mas o laço tem de virar `task.wait` com contador e fim declarado.

---

## Os 16 sons

Todos com id de verdade, todos dentro do `Handle`. É a primeira entrada de **som de porrada**
do Acervo — o repertório até aqui era explosão, corte e feixe.

| Tool | Sons |
|---|---|
| `Taco de Baseball` | `Swoosh` `3755636638` · `Equip` `769464514` · `Hit` `175024455` · `Hit2` `3932505023` · `Ouch` `4306991691` · `Ouch2` `4459572527` |
| `Cano De Rua` | `Swoosh` `1489705211` · `Swoosh2` `181894961` · `MetalHit` `933780081` · `MetalHit2` `546410481` · `Hit` `743886825` · `unequip` `769464514` |
| `Energetico` | `DrinkSound` `1489917733` · `OpenSound` `7244308623` |
| `Abacate` | `DrinkSound` `2834628644` · `OpenSound` **vazio** ⚠️ |
| `Humilhador` | `7995127481`, criado no código com `PlayOnRemove` |

⚠️ O `OpenSound` do `Abacate` está com `SoundId` **em branco** — o `Tool.Equipped` chama
`:Play()` nele e não sai nada. Defeito de origem, e é o mesmo tipo de bug mudo que já foi
consertado nas bombas.

Cada `Ouch`/`Hit` tem par (`Hit` + `Hit2`), o que dá alternância de golpe sem `math.random`:
**índice sequencial**, que é justamente o que a regra manda usar no lugar do sorteio.

---

## Segurança

Zero `loadstring`, zero `require(<id numérico>)`, zero `HttpService`, zero webhook, zero
`getfenv`/`setfenv`. Limpo.

## Passe de conformidade §12.12.2 — EXECUTADO

`python3 FERRAMENTAS/preparar_guest.py` · `gerar_poses_guest.py` ·
`gerar_servers_guest.py` · `clonar_tool.py montar`

As **7 Tools** estão em `Tools/`, uma por arquivo mais o conjunto
`Guest_7_Tools.rbxmx`. Todas passam em `verificar_rbxmx`, `verificar_poses` e
`verificar_pack_vfx`.

O que a conversão trocou está na tabela de `Tools/README.md`, seção
*Conjunto GUEST*. O resumo: `require` externo, `ScreenGui`, `Animation`,
`isAlly` próprio, `Health = Health - x`, `Touched` no cliente, `BreakJoints`,
`workspace:GetDescendants()`, e 114 chamadas de sintaxe proibida.

### O que a origem manteve, intacto

Handle, mesh, `Sound`, `Weld`, `Motor6D`, `Texture`, hierarquia. É remaster:
`clonar_tool.py` só reescreve o `Source` dos scripts.

Duas exceções de geometria, e as duas estão declaradas em
`FERRAMENTAS/preparar_guest.py`: o `Handle` de `A arma` subiu de `model/Handle`
para filho direto (exigência do Roblox para `RequiresHandle`), e o `Humilhador`
ganhou um `Handle` invisível porque a origem não tem nenhum.

## Para sair de LIMPO e virar APROVADO

Falta a **licença** e o teste em jogo. Nada aqui rodou no Studio — a verificação
é toda estática.
