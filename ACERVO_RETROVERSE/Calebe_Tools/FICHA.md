# Modelo: Calebe Tools — 5 Tools de gravidade → **7 Tools telecinéticas**

- Autor original:            **a confirmar** ⚠️
- Origem:                    `calebe_tools.rbxmx`, enviado no lote de 2026-08-13
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **LIMPO** — passe §12.12.2 executado; falta licença
- Onde vive:                 `MODELOS_ENTRADA/Calebe_Tools/` · as **7 Tools** de gravidade em `Tools/`

---

## O que é

**Cinco `Tool` prontas** na raiz, e as cinco têm o mesmo tema: **gravidade e física**.
198 instâncias, 2037 linhas, **28 `Sound`**, 11 `ParticleEmitter`, 6 `ReverbSoundEffect`.

| Tool | Linhas | O que faz | Sons |
|---|---|---|---|
| `CosmosStaff` | 340 | cajado de força — ergue e arremessa | 4 |
| `Gravitron 1000` | 321 | alterna a gravidade do servidor em três níveis | 3 |
| `GravityHammer` | 690 | o martelo de gravidade clássico | 4 |
| `Quake Hammer` | 224 | martelo que abre ruptura no chão | 3 |
| `detainer` | 638 | **garra que pega, segura e arremessa** | **14** |

**Cinco cai exato** no piso 3 / teto 7 — nenhuma se funde, nenhuma vira Extra. E o tema é
coeso de verdade: é o primeiro modelo a chegar aqui já como *conjunto*, não como sortido.

Zero `KeyCode` nas cinco: tudo no clique.

---

## ⚠️ O achado que mudou a conversão: `workspace.Gravity`

Duas das cinco escrevem **`workspace.Gravity`** — que é propriedade **global do servidor**,
não estado da Tool.

O `Gravitron 1000` cicla em três níveis a cada clique:

```lua
game.Workspace.Gravity = 21.2    -- low
game.Workspace.Gravity = 471.2   -- high
game.Workspace.Gravity = 196.2   -- default
```

E o `onUnequipped` dele faz **isto**, e só isto:

```lua
function onUnequipped()
	tool.Handle.Shift:Stop()
	tool.Handle.Beep:Stop()
	tool.Handle.BillboardGui.TextLabel["Random Text"].Enabled = false
end
```

Para os sons, apaga o rótulo, e **não devolve a gravidade**. Não existe `Tool.Destroying`.

**Equipar, clicar uma vez e guardar deixa o servidor inteiro em gravidade 21.2 para sempre.**
É exatamente a família de bug que a regra da câmera chama de *"o pior do repertório"*: estado
global tomado e não devolvido. A diferença é que câmera presa incomoda um jogador, e gravidade
presa quebra o mapa para todo mundo.

Na conversão isso não virou "guardar e devolver": virou **não tocar**. Gravidade é propriedade
global, e a resposta certa não é sequestrá-la com cuidado — é não sequestrar. Cada alvo ganha o
seu `BodyPosition`/`BodyVelocity`, com prazo no `Debris`. Ver a seção do passe, no fim.

O `GravityHammer` só **lê** `workspace.Gravity` para calcular o impulso, e reage a
`GetPropertyChangedSignal("Gravity")`. Esse é o uso certo, e fica.

### E a UI que ele clona para todo mundo

```lua
local playerguis = game:GetService("Players"):GetChildren()
for i, players in pairs(playerguis) do
	newui.Parent = players.PlayerGui
	...
end
```

Duas coisas erradas na mesma linha. `PlayerGui` de outro jogador é depósito fora da Tool — e
o clone é **um só**, reparentado no laço: cada volta *move* a mesma instância, então só o
último jogador da lista fica com ela. O resto do servidor não vê nada.

---

## O `detainer` é o melhor construído do lote

É a única Tool que já entrou aqui usando **física por constraint** em vez de `BodyVelocity`:

```
LineForce "Pulley" · AlignPosition "HoldPos" · AlignOrientation "HoldRot"
Motor6D "rotatingmotor" · 4 MeshPart decorativos + claws + motor
```

Mais `SetNetworkOwner` ×2 — que é o que faz o objeto carregado não picotar para os outros
jogadores. É o mesmo cuidado que as bombas deste repositório tiveram de aprender.

E são **14 `Sound`** para uma Tool só: `ClawsOpen`, `ClawsClose`, `Pickup`, `Drop`, `Pull`,
`Holding`, `DryFire`, `Launch1..4`, `equip`, `unequip`. É o vocabulário sonoro mais completo
que já chegou — a maioria das Tools daqui tem três.

---

## O resto do que precisava mudar — e mudou

| Achado | Quantos | Onde |
|---|---|---|
| `wait()` | 35 | todas |
| `math.random` | 18 | todas |
| `:Destroy()` | 9 | todas |
| `spawn(` | 5 | todas |
| `LoadAnimation` + 6 `Animation` | 4 | `CosmosStaff`, `GravityHammer` |
| `ScreenGui` (5 instâncias) | 5 | `Gravitron 1000`, `Quake Hammer` |
| `IsTeamMate` na própria Tool | 1 | `GravityHammer` |
| `BreakJoints` | 1 | `GravityHammer` |
| `workspace:GetDescendants()` | 1 | — |

O `IsTeamMate` é invariante do `CLAUDE.md`: regra de combate tem uma porta só, o Núcleo.

**A favor:** as cinco já usam `TakeDamage` (8 chamadas) — nenhuma mexe em `Health` na mão.
É o segundo modelo a chegar assim, depois do Guest.

## Segurança

Zero `loadstring`, zero `require(<id numérico>)`, zero `HttpService`, zero webhook, zero
`getfenv`/`setfenv`, zero `ReplicatedStorage`/`ServerStorage`. Limpo.

## Passe de conformidade §12.12.2 — EXECUTADO

```bash
python3 FERRAMENTAS/preparar_gravidade.py        # 5 Handles -> 7 Tools
python3 FERRAMENTAS/gerar_poses_gravidade.py     # 7 Poses.lua
python3 FERRAMENTAS/gerar_servers_gravidade.py   # Server · Client · VFXModule
python3 FERRAMENTAS/clonar_tool.py montar ...    # os .rbxmx
python3 FERRAMENTAS/converter_para_rbxm.py ...   # a entrega
```

O conjunto saiu com **7 Tools** — `Gravidade_7_Tools.rbxm`. Duas clonam o Handle
de uma irmã (`Asas Telecineticas` ← CosmosStaff, `Terremoto` ← Quake Hammer): o
que se clona é a **geometria**, e a habilidade de cada uma foi escrita do zero.

### O que a origem manteve, intacto

Handle, mesh, `Attachment`, `ParticleEmitter`, `Beam`, `Motor6D`, os constraints
do `detainer` (`LineForce`, `AlignPosition`, `AlignOrientation`) e os 28 `Sound`.

### O que foi corrigido de defeito da ORIGEM

| Defeito | Conserto |
|---|---|
| `workspace.Gravity` trocada e **não devolvida** | força **por alvo**, com prazo no `Debris`; e o `desmontar()` está nas duas portas |
| UI clonada no `PlayerGui` de todos — e o clone era **um só** | beat de VFX no mundo 3D |
| 3 `SoundId` com **espaço no fim** (`...48577295 `) | `strip()` — espaço em URL não dá erro, o som só não toca |
| 6 ids no formato antigo `http://www.roblox.com/asset/?id=` | normalizados para `rbxassetid://` |

Os dois últimos são defeitos que só apareceriam em jogo, como som mudo. O
verificador não os pegava porque cobrava `rbxassetid://` e eles **não existiam**
nesse formato — foi o próprio passe que os expôs.

### A regra nova que este conjunto trouxe

`TESTES/verificar_autocontencao.sh` ganhou **`✓ sem escrever workspace.Gravity`**
e `✓ sem escrever Lighting global`. A Regra nº 1 vale nos dois sentidos: a Tool
não lê de fora, e não sequestra o que é de fora. **Ler** `workspace.Gravity`
continua permitido — as Tools de gravidade fazem isso para calcular impulso.

## Para sair de LIMPO e virar APROVADO

Falta a **licença** e o teste em jogo. Nada aqui rodou no Studio — a verificação
é toda estática.
