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
├── [NomeDaTool]_Server_V[X]                   ← Server Script — sem require de nada de fora
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

Recarga que precisa sobreviver a clones na mochila mora num `Attribute` do PERSONAGEM,
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
| Destruir Humanoides diretamente | `TakeDamage` — respeita `ForceField` |
| `Health = Health - dano` | `TakeDamage` |
| `BreakJoints` | ragdoll por `BallSocketConstraint` — §10.12 |
| GUIs completas (`ScreenGui` + Frames) | Botão simples, só para habilidade Extra |
| `wait()` / `spawn()` / `delay()` | `task.wait` / `task.spawn` / `task.delay` |
| `tick()` | `os.clock()` para recarga; acumulador `dt` para animação (§10.11.7) |
| `AncestryChanged` para cleanup | `Tool.Destroying` |
| `Animation` / `LoadAnimation` | Poses CFrame sob `R6CFrameAnimator` |
| `+=` / `-=` / `continue` | Sintaxe expandida |
| `require` de sistema central | nada — a Tool não conhece sistema nenhum |

### §10.10 — `math.random` é PERMITIDO

Ele era proibido. Não é mais.

O motivo da proibição continua sendo verdade, e vale saber onde ele morde: **num
`VFXModule`, que roda em todo cliente, cada cliente sorteia um número diferente e vê uma
cena diferente.** Não quebra nada; só deixa de ser a mesma cena para todo mundo.

Onde isso importa, o determinismo continua disponível e continua sendo o padrão da casa —
ângulo áureo (`2.399963`), jitter senoidal por contador, índice sequencial. Onde não
importa, `math.random` é mais curto e mais legível, e agora pode.

Regra prática: **servidor sorteia à vontade** (um sorteio, resultado replicado);
**cliente sorteia o que não precisa combinar** (variação de fumaça, sim; posição do
estilhaço que marca onde o golpe caiu, melhor não).

### §10.12 — Ragdoll é PERMITIDO

`BallSocketConstraint` por junta, com `Motor6D.Enabled = false` enquanto durar.

**Sempre reversível.** Guardar o valor de antes e devolver AQUELE, nunca um número fixo —
o mesmo princípio de `afrouxar()` e `atordoar()`. Ragdoll sem volta é `BreakJoints` com
outro nome, e esse continua proibido.

⚠️ **Ragdoll e `R6CFrameAnimator` disputam as mesmas juntas.** Antes de ligar o ragdoll:
`rig:CancelSequence()` e `rig:ReleaseLegs()`. Perna soldada trava o corpo mole do mesmo
jeito que trava a caminhada.

### §10.11 — Animação é autoral

Pose, ritmo e dramaturgia devem ser **diferentes** entre Tools. O que deve ser **idêntico** é
a forma de aplicar dano — `TakeDamage`, etiqueta `creator`, consulta espacial sob demanda —
e isso vive no preâmbulo do Server de cada Tool, copiado, não requerido.

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
Ver `CLAUDE.md` para as chaves de recarga, tipos de VFX e pastas do Acervo.

---

## 12. CICLO DE VIDA DO VFX

Ver [`REGRA_CICLO_DE_VIDA_DO_VFX.md`](REGRA_CICLO_DE_VIDA_DO_VFX.md) — documento completo.

Resumo operacional:

- Na **entrega**, os moldes são filhos da Tool, em `Tool/Efeitos/`.
- Ao chegar ao jogador — mochila ou mão —, o **Server** move os moldes para
  `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`.
- Quem lê tem **duas portas**: o depósito primeiro, o interior da Tool depois.
- A pasta é do **modelo**: **cria ou reutiliza**, e fica até o servidor ser desligado.
  Ninguém a apaga — outro jogador pode estar usando a mesma.

> ⛔ **O que estava aqui antes era o NÚCLEO DE COMBATE, e ele foi removido do repositório.**
> Nem regra, nem `_G.Combate`, nem `ServerScriptService/NucleoCombate.lua`. Uma Tool que se
> comporta diferente conforme exista um script em outro lugar do place não é a Tool que o
> modelo de origem era. O que era fallback virou o caminho único.

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

O checklist completo, incluindo depósito de VFX e Acervo, está em
[`CHECKLIST_ENTREGA.md`](CHECKLIST_ENTREGA.md).

---

## REFERÊNCIAS

- `Tool`: https://create.roblox.com/docs/pt-br/reference/engine/classes/Tool
- Classes relacionadas: `Humanoid`, `Backpack`, `Mouse`, `Player.Character`
