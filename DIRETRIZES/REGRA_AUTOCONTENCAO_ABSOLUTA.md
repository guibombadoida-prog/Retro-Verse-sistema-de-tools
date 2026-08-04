# REGRA DA AUTOCONTENÇÃO ABSOLUTA
**Retro-Verse / Studios** · **Regra nº 1 — vence todas as outras, inclusive a REGRA 12 V3**

---

## O enunciado

> **Nada de referência de script FORA da Tool.**
> Todo script, animação, VFX, SFX, mesh, MeshPart, textura, som, pose e módulo é
> **obrigatoriamente, absolutamente** filho da Tool.

Não há exceção, não há "só esse caso", não há pasta compartilhada de conveniência.

---

## O teste que decide

**Arraste a Tool sozinha para um place vazio. Ela funciona por inteiro.**

Um place sem `ACERVO_RETROVERSE`, sem `ServerStorage`, sem `ReplicatedStorage` povoado,
sem `NucleoCombate`, sem nenhuma pasta do projeto. Só a Tool na `StarterPack`.

Se faltar **uma** partícula, **um** som, **uma** pose ou **um** mesh, a Tool violou esta regra.

---

## O que é proibido dentro de qualquer script de Tool

| ❌ Proibido | Por quê |
|---|---|
| `game:GetService("ReplicatedStorage")` e qualquer descendente | Referência fora da Tool |
| `game:GetService("ServerStorage")` e qualquer descendente | Idem |
| `game:GetService("ServerScriptService")` e qualquer descendente | Idem |
| `game:GetService("Lighting")` / `StarterGui` / `StarterPack` para buscar asset | Idem |
| `workspace:FindFirstChild(...)` / `workspace:WaitForChild(...)` para buscar asset | Idem |
| `InsertService:LoadAsset(...)` | Traz instância de fora em runtime |
| `require(<id numérico>)` | Código de fora, não auditável |
| `ServerStorage.ACERVO_RETROVERSE:FindFirstChild(...)` | O Acervo é prateleira de edição |
| Qualquer `:Clone()` de molde que não seja descendente da Tool | Referência fora da Tool |
| `SoundService` guardando os `Sound` da Tool | O SFX é filho da Tool |

## O que é obrigatório

| ✅ Correto | Como |
|---|---|
| Molde de VFX | `Instance` dentro de `Tool/Efeitos/`, clonada em runtime |
| Som | `Sound` dentro de `Tool/SFX/`, clonado em runtime |
| Mesh / MeshPart / textura | Dentro da Tool — no `Handle` ou em `Tool/Efeitos/` |
| Pose / animação | Tabela CFrame no ModuleScript `Poses`, dentro da Tool |
| Módulo | ModuleScript filho da Tool: `Poses`, `VFXModule`, `R6CFrameAnimator` |
| `require` | Só `require(tool:WaitForChild("<módulo da própria Tool>"))` |

---

## As quatro coisas que NÃO são violação

Esta regra proíbe **referenciar instância fora da Tool**. Quatro coisas se parecem com isso e não são:

### 1. `_G.Combate` — o Núcleo
```lua
local final = _G.Combate and _G.Combate.calcular(jogador, alvo, 40) or 40
```
Não é referência a instância nem caminho de hierarquia: é uma variável global **opcional**, sempre
com guarda. Foi exatamente para isso que a REGRA 12 V2 inverteu o controle (§12.0). **Apague o
`NucleoCombate` do place e a Tool continua funcionando**, só sem os bônus de combate.

Continua valendo: `require` do Núcleo é proibido (§12.2).

### 2. Parentear o efeito no mundo 3D
```lua
parte.Parent = workspace
```
O VFX **precisa** existir no mundo para ser visto. O que a regra proíbe é o caminho inverso:
**buscar** algo em `workspace`. Escrever em `workspace` é saída; ler de `workspace` é dependência.

### 3. `rbxassetid://` dentro de uma instância da Tool
Um `Sound` com `SoundId`, um `MeshPart` com `MeshId`, uma textura com `TextureId` — desde que a
instância seja **filha da Tool**, o conteúdo vem do asset e a Tool é autocontida. Um `rbxassetid`
não é caminho de hierarquia.

Proibido continua sendo `require(<id numérico>)`: isso é **código** de fora, não conteúdo.

### 4. `workspace.CurrentCamera` — só no cliente
```lua
local camera = workspace.CurrentCamera   -- LocalScript
```
Parece leitura de `workspace`, que o item 2 acabou de proibir. A diferença é o que se lê:

| | |
|---|---|
| `workspace:FindFirstChild("Efeitos")` | **dependência** — se o place não tiver a pasta, a Tool quebra |
| `workspace.CurrentCamera` | **singleton por cliente** — existe em todo place, sempre, sem depósito |

É acesso de serviço, da mesma natureza que `Players.LocalPlayer`. O teste do place vazio
continua passando: a Tool sozinha roda a cutscene inteira.

Duas condições, e não são negociáveis:

- **Só em `LocalScript`.** Câmera em Server Script é violação — não existe "a câmera do
  jogo", existe uma por cliente. Ver `REGRA_CAMERA_DE_CUTSCENE.md`.
- **Sempre restaurada.** `CameraType` e `FieldOfView` voltam ao valor guardado em
  `Unequipped`, `Destroying` e morte. Câmera presa é bug sem saída para o jogador.

### Serviços que a Tool pode usar

`Players`, `Debris`, `RunService`, `ContextActionService`, `UserInputService`, `TweenService`,
`CollectionService`. São **serviços de comportamento**, não depósitos de asset. Nenhum deles
traz instância de fora para dentro.

---

## Por que esta regra é absoluta

| Sem ela | Com ela |
|---|---|
| Renomear uma pasta quebra várias Tools de uma vez | Renomear qualquer coisa fora não afeta Tool nenhuma |
| Entregar uma Tool é entregar uma Tool + N dependências ocultas | Entregar uma Tool é arrastar um arquivo |
| A Tool funciona no place de teste e falha no de produção | O que funciona em qualquer place funciona em todos |
| O Acervo vira dependência de runtime, e some quando alguém limpa | O Acervo permanece o que é: prateleira de edição |

O Acervo (§12.16) e esta regra não se contradizem — se completam. O material **fica guardado**
no Acervo para reuso na próxima Tool, e é **copiado para dentro** da Tool na montagem.
O Acervo é fonte de edição. Nunca de runtime.

---

## Verificação

```bash
bash TESTES/verificar_autocontencao.sh
```

Roda a varredura sobre `Tools/` e falha se qualquer script referenciar algo fora da Tool.
**Executar antes de fechar qualquer entrega.**

Manual, no Studio:

- [ ] Tool sozinha em place vazio → funciona por inteiro
- [ ] `ACERVO_RETROVERSE` deletado → funciona
- [ ] `NucleoCombate` deletado → funciona, sem os bônus
- [ ] `ReplicatedStorage` e `ServerStorage` vazios → funciona
- [ ] Todo `Sound`, mesh, textura e molde de VFX é descendente da Tool
