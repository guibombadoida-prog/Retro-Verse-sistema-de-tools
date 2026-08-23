# REGRA DA AUTOCONTENÇÃO ABSOLUTA
**Retro-Verse / Studios** · **Regra nº 1 — vence todas as outras**

---

## O enunciado

> **A Tool é a fronteira.** Todo script, VFX, SFX, mesh, MeshPart, textura, som, pose e
> módulo **nasce dentro dela**, e nada do que ela precisa vem de fora.

O que ela **põe** no mundo é outra história — ver a `REGRA_CICLO_DE_VIDA_DO_VFX.md`, que é
a nº 2. Escrever no mundo é saída; **ler** dele é dependência, e dependência é o que esta
regra proíbe.

---

## O teste que decide

**Arraste a Tool sozinha para um place vazio. Ela funciona por inteiro.**

Um place sem `ACERVO_RETROVERSE`, sem `ServerStorage`, sem `ReplicatedStorage` povoado,
sem nenhuma pasta do projeto. Só a Tool na `StarterPack`.

Se faltar **uma** partícula, **um** som, **uma** pose ou **um** mesh, a Tool violou.

**Isto não mudou com a regra nº 2.** A Tool instala o depósito dela no primeiro `Equipped`,
e até lá lê de dentro de si mesma. O place vazio continua bastando.

---

## O que é proibido dentro de qualquer script de Tool

| ❌ Proibido | Por quê |
|---|---|
| Ler de `ReplicatedStorage` **pasta que a Tool não criou** | Referência fora da Tool |
| `game:GetService("ServerStorage")` e qualquer descendente | Idem |
| `game:GetService("ServerScriptService")` e qualquer descendente | Idem |
| `Lighting` / `StarterGui` / `StarterPack` para buscar asset | Idem |
| `workspace:FindFirstChild(...)` para buscar asset | Idem |
| `InsertService:LoadAsset(...)` | Traz instância de fora em runtime |
| `require(<id numérico>)` | Código de fora, não auditável |
| `ServerStorage.ACERVO_RETROVERSE:FindFirstChild(...)` | O Acervo é prateleira de edição |
| `:Clone()` de molde que não é da Tool nem do depósito dela | Referência fora da Tool |
| `SoundService` guardando os `Sound` da Tool | O SFX é filho da Tool |
| **`require` de qualquer sistema central** | A Tool não conhece sistema nenhum |

## O que é obrigatório

| ✅ Correto | Como |
|---|---|
| Molde de VFX | `Tool/Efeitos/` na entrega; depósito próprio em runtime (regra nº 2) |
| Som | `Sound` dentro de `Tool/SFX/`, clonado em runtime |
| Mesh / MeshPart / textura | Dentro da Tool — no `Handle` ou em `Tool/Efeitos/` |
| Pose / animação | Tabela CFrame no ModuleScript `Poses`, dentro da Tool |
| Módulo | ModuleScript filho da Tool: `Poses`, `VFXModule`, `R6CFrameAnimator` |
| `require` | Só `require(Tool:WaitForChild("<módulo da própria Tool>"))` |

---

## As quatro coisas que NÃO são violação

Esta regra proíbe **depender de instância que a Tool não trouxe nem criou**. Quatro coisas
se parecem com isso e não são. O que as quatro têm em comum: **nenhuma faz o teste do place
vazio falhar.**

### 1. Escrever no mundo

```lua
parte.Parent = workspace
```

Saída, não entrada. VFX tem de existir no mundo para ser visto. O que não pode é **ler**
o mundo procurando asset.

### 2. O depósito que a PRÓPRIA Tool montou

```lua
local deposito = ReplicatedStorage:FindFirstChild("RetroVerse_VFX")
local meu = deposito and deposito:FindFirstChild(Tool.ChaveVFX.Value)
local molde = (meu and meu.Efeitos:FindFirstChild(nome))
    or Tool.Efeitos:FindFirstChild(nome)
```

A pasta veio de dentro da Tool, posta lá pela Tool, e some com ela. Não é dependência: é a
própria Tool, guardada num lugar onde replica melhor. **A segunda porta é obrigatória** —
é ela que mantém o teste do place vazio verdadeiro.

Ler pasta de `ReplicatedStorage` que a Tool **não** criou continua proibido.

### 3. `rbxassetid://` dentro de instância que já é filha da Tool

```lua
emissor.Texture = "rbxassetid://11283087951"
```

Id de catálogo não é caminho de hierarquia. A instância que o carrega é filha da Tool.

### 4. `workspace.CurrentCamera`, em `LocalScript` / `RunContext = Client`

Singleton por cliente, como `Players.LocalPlayer`. Não é depósito de asset. Câmera em
Server Script continua proibida — ver `REGRA_CAMERA_DE_CUTSCENE.md`.

---

## ⛔ O que saiu desta regra: o Núcleo de Combate

A versão anterior abria exceção para `_G.Combate` — global opcional, sempre com guarda.

**Essa exceção não existe mais, porque o Núcleo não existe mais.**

Ele foi removido do repositório inteiro: das regras, das 94 Tools e do `ServerScriptService`.
Mesmo sendo opcional e mesmo com guarda, ele criava um segundo dono da regra de combate — e
uma Tool que se comporta diferente conforme exista ou não um script em outro lugar do place
**não é a Tool que o modelo de origem era**. O legado da Tool original vale mais que o bônus.

O que era fallback virou **o caminho único**:

| Era | Virou |
|---|---|
| `_G.Combate.calcular(...) or bruto` | `bruto` |
| `_G.Combate.detectarHumanoides(...)` | `workspace:GetPartBoundsInRadius` com `OverlapParams` |
| `_G.Combate.registrarAtaque(...)` | a etiqueta `creator` escrita na vítima |
| `_G.Combate.registrarReducao(...)` | mecânica própria da Tool |

Nenhuma Tool perdeu habilidade: os quatro fallbacks já estavam escritos e testados em todas
as 94. O que sumiu foi o caminho alternativo.

---

## Verificação

```bash
bash    TESTES/verificar_autocontencao.sh
python3 TESTES/verificar_deposito_vfx.py
python3 TESTES/verificar_rbxmx.py
```

O `verificar_autocontencao.sh` recusa, entre outras coisas:

- `require` que não aponte para módulo da própria Tool;
- **qualquer** menção a `_G.Combate` — a global foi aposentada;
- leitura de `ReplicatedStorage` fora do padrão do depósito;
- servidor movendo geometria por quadro.
