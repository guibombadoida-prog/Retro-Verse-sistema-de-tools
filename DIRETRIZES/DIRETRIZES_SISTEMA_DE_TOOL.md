# DIRETRIZES — SISTEMA DE TOOL
**Retro-Verse / Studios | Roblox Studio**
Base do sistema · estendida e parcialmente substituída pela [REGRA 12 V3](REGRA_12_NUCLEO_DE_COMBATE_V3.md)

> ⚠️ Em qualquer conflito entre este documento e a REGRA 12 V3, **a REGRA 12 V3 vence**.
> Ela move para fora da Tool tudo que é regra de combate, e libera material audiovisual de terceiros.

---

## 1. DEFINIÇÃO DA CLASSE TOOL

Um **Tool** é um objeto equipável por um `Humanoid`. Representa armas, ferramentas e objetos
interativos que personagens podem segurar e utilizar.

```
Object → Instance → PVInstance → Model → BackpackItem → Tool → Flag
```

---

## 2. PROPRIEDADES

| Propriedade | Tipo | Valor no projeto | Descrição |
|---|---|---|---|
| `CanBeDropped` | boolean | **SEMPRE `false`** | Impede que o jogador solte a Tool |
| `RequiresHandle` | boolean | **SEMPRE `true`** | Exige Handle para funcionar |
| `Enabled` | boolean | `true` por padrão | Debounce da habilidade primária |
| `Grip` | CFrame | Configurável | Como o personagem segura a Tool |
| `GripPos` / `GripForward` / `GripRight` / `GripUp` | Vector3 | Configurável | Componentes contidos em `Grip` |
| `ManualActivationOnly` | boolean | Opcional | `true` = só `Tool:Activate()` dispara o evento |
| `ToolTip` | string | Obrigatório | Texto exibido ao passar o mouse na Backpack |

> ⚠️ Propriedades `Grip*` são **não replicadas** — configurar sempre no servidor.

---

## 3. REGRAS OBRIGATÓRIAS

### `CanBeDropped = false` — sempre
Toda Tool fica permanentemente no inventário. Jogadores **não podem** descartar Tools.
Exceção somente com autorização explícita.

### `RequiresHandle = true` — sempre
Toda Tool **deve** ter um `Handle`, nomeado **exatamente** `"Handle"` (case-sensitive),
do tipo `Part` ou `MeshPart`.

Sem Handle: a Tool não funciona e os eventos `Equipped` / `Unequipped` **não disparam**.

---

## 4. ESTRUTURA HIERÁRQUICA

A estrutura mínima da base é ampliada pela §12.10 da REGRA 12 V3:

```
Tool
├── Handle (Part ou MeshPart)                  ← OBRIGATÓRIO
├── DamageClass / EnergyCost / RecargaGlobal   ← Values (§12.4)
├── [NomeDaTool]_Server_V[X]                   ← Server Script — SEM require do Núcleo
├── Client                                     ← LocalScript — input + recepção de VFX
├── VFXRemote                                  ← RemoteEvent unidirecional
├── R6CFrameAnimator                           ← ModuleScript
├── Poses                                      ← ModuleScript
└── VFXModule                                  ← ModuleScript
```

Configuração mínima do Handle:

```lua
local handle = Instance.new("Part") -- ou "MeshPart"
handle.Name = "Handle"              -- OBRIGATÓRIO, case-sensitive
handle.Size = Vector3.new(1, 1, 3)
handle.Parent = tool
```

---

## 5. MÉTODOS

| Método | Descrição |
|---|---|
| `Tool:Activate()` | Ativação programática (Tool deve estar equipada) |
| `Tool:Deactivate()` | Desativação programática (Tool deve estar equipada) |

---

## 6. EVENTOS

```lua
Tool.Activated:Connect(function() end)        -- clique com a Tool equipada; requer Enabled = true
Tool.Deactivated:Connect(function() end)      -- soltar o clique; requer Enabled = true
Tool.Equipped:Connect(function(mouse) end)    -- requer Handle quando RequiresHandle = true
Tool.Unequipped:Connect(function() end)       -- requer Handle quando RequiresHandle = true
```

---

## 7. CONFIGURAÇÃO BASE OBRIGATÓRIA

```lua
local tool = script.Parent

tool.CanBeDropped = false
tool.RequiresHandle = true
tool.ToolTip = "NomeDaTool - Descrição breve"
tool.Enabled = true

local handle = tool:WaitForChild("Handle")
```

---

## 8. DEBOUNCE E ORDEM DE IMPACTO

`Tool.Enabled` é o debounce da habilidade **primária**:

```lua
tool.Activated:Connect(function()
	if not tool.Enabled then
		return
	end
	tool.Enabled = false
	-- lógica da habilidade
	task.wait(CFG.RECARGA)
	tool.Enabled = true
end)
```

> ⚠️ **`Tool.Enabled` NÃO é resetado em `Unequipped`.** Resetar em `Unequipped` transforma
> desequipar/reequipar num cancelamento de recarga — é exploit. (§10.7 / §12.9)

**Ordem de impacto (§8 V2), sem exceção:**

```
SFX → física → VFX → dano
```

Recarga que precisa sobreviver a clones na mochila é **recarga global**, no Núcleo (§12.9),
não `Tool.Enabled`.

---

## 9. SISTEMA DE BOTÕES (GUI)

- ✅ Botão **apenas** para habilidade **Extra**.
- ❌ Nunca botão para a habilidade primária — essa é `Tool.Activated`.
- ❌ `ScreenGui` completo dentro da Tool é proibido (§12.12.4).

---

## 10. RESTRIÇÕES — PROIBIÇÕES ABSOLUTAS

| Proibido | Alternativa |
|---|---|
| `part:Destroy()` / `object:Remove()` | `part.Parent = nil` ou `Debris:AddItem` |
| `math.random()` em gameplay | Ângulo áureo / Vogel, jitter senoidal por contador, índice sequencial |
| Destruir Humanoides diretamente | `TakeDamage` — respeita `ForceField` |
| `Health = Health - dano` | `TakeDamage` |
| GUIs completas (`ScreenGui` + Frames) | Botão simples, só para habilidade Extra |
| `wait()` / `spawn()` / `delay()` | `task.wait` / `task.spawn` / `task.delay` |
| `tick()` | `os.clock()` para recarga; acumulador `dt` para animação (§10.11.7) |
| `AncestryChanged` para cleanup | `Tool.Destroying` |
| `Animation` / `LoadAnimation` | Poses CFrame sob `R6CFrameAnimator` |
| `+=` / `-=` / `continue` | Sintaxe expandida |

### §10.11 — Animação é autoral

Pose, ritmo e dramaturgia devem ser **diferentes** entre Tools. O que deve ser **idêntico** é
regra de combate, e isso vive no Núcleo (§12.1).

**§10.11.7 — acumulador `dt`:** toda animação procedural acumula tempo a partir de **zero**,
localmente. `tick()` e `os.time()` nunca alimentam `CFrame`: são valores grandes e absolutos,
e a perda de precisão em ponto flutuante faz a animação tremer.

```lua
local t = 0
conexao = RunService.Heartbeat:Connect(function(dt)
	t = t + dt
	-- usar t
end)
```

---

## 11. CONVENÇÕES DE NOMENCLATURA

```
[NomeDaTool]_[Função]_V[Versão].lua

Espada_Ataque_V1.lua
Arco_Municao_V2.lua
Varinha_Magia_V3.lua
```

Versionamento sequencial: V1 → V2 → V3. Incrementar a cada modificação.
Ver §12.15 para as chaves de recarga, modificadores, tipos de VFX e pastas do Acervo.

---

## 12. NÚCLEO DE COMBATE

Ver [`REGRA_12_NUCLEO_DE_COMBATE_V3.md`](REGRA_12_NUCLEO_DE_COMBATE_V3.md) — documento completo.

Resumo operacional:

- A Tool **declara intenção** com `Value`s; o Núcleo **aplica regra**.
- Zero `require` do Núcleo dentro da Tool. A porta é `_G.Combate`, sempre com guarda.
- `DamageClass` é a etiqueta mais barata e a mais esquecida. Sem ela, todo bônus por classe
  do jogo fica inerte.

---

## 13. FORMATO DE ENTREGA

```
## Scripts Entregues — [Nome da Tool]
Versão Atual: V[X]

Scripts Novos:
  - [NomeScript]_V[X].lua — [Função]

Scripts Modificados:
  - [NomeScript]_V[X-1].lua → [NomeScript]_V[X].lua
    Mudanças: [Descrição]

Scripts Substituídos:
  - [ScriptAntigo]_V[X-1].lua → substituído por [ScriptNovo]_V[X].lua
    Remover: [ScriptAntigo]_V[X-1].lua

Scripts Reutilizados:
  - [NomeScript] — Origem: [Tool de Origem] — Função: [Descrição]

## Delta do Acervo            ← §12.16.2, obrigatório
  Entrou:    [efeito] — [modelo de origem] — [status]
  Reusado:   [efeito] — [de onde]
  Status:    [efeito]: CRU → LIMPO → APROVADO
```

---

## 14. CHECKLIST DE CONFORMIDADE (base)

- [ ] `CanBeDropped = false`
- [ ] `RequiresHandle = true`
- [ ] Handle presente (`Part` ou `MeshPart`) nomeado `"Handle"`
- [ ] `ToolTip` definido e descritivo
- [ ] Debounce com `Enabled`, **não** resetado em `Unequipped`
- [ ] Eventos `Equipped` / `Unequipped` tratados
- [ ] Nenhuma função proibida (§10)
- [ ] Versionamento e nomenclatura corretos
- [ ] Propriedades `Grip` configuradas no servidor
- [ ] Tool testada em equip / unequip / activate

O checklist completo, incluindo Núcleo e Acervo, está em
[`CHECKLIST_ENTREGA.md`](CHECKLIST_ENTREGA.md).

---

## REFERÊNCIAS

- `Tool`: https://create.roblox.com/docs/pt-br/reference/engine/classes/Tool
- Classes relacionadas: `Humanoid`, `Backpack`, `Mouse`, `Player.Character`
