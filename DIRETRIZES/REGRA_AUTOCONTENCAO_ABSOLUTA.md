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

## As cinco coisas que NÃO são violação

Esta regra proíbe **referenciar instância fora da Tool**. Cinco coisas se parecem com isso e não são.
O que as cinco têm em comum: **nenhuma delas faz o teste do place vazio falhar.** É esse o
critério — não "é pequeno", não "é conveniente", não "o pack foi escrito assim".

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

### 5. Resolver quem está em campo

```lua
local modelo = workspace:FindFirstChild(nome)   -- `nome` veio do servidor, no payload
```

Parece o `workspace:FindFirstChild` proibido no item 2, e a diferença de novo é **o que se lê**:

| | |
|---|---|
| `workspace:FindFirstChild("Efeitos")` | **depósito de asset** — se o place não tiver a pasta, a Tool quebra |
| `workspace:FindFirstChild(nome)` | **entidade viva** — o personagem que o servidor acabou de nomear |

Não existe Tool que acerte alguém sem localizar esse alguém, e o personagem não é asset que
possa viajar dentro da Tool: ele nasce no place, em runtime. Mesma natureza de
`Players.LocalPlayer` e `workspace.CurrentCamera`, já aceitas acima. **O teste do place vazio
continua passando** — é por isso que isto entra na lista, e o pack de VFX não entrava.

A linha entre as duas é o **literal**. Buscar `"MeuEfeito"` é depósito; buscar `nome`, que
chegou pelo `RemoteEvent`, é resolver quem está em campo. O verificador corta exatamente aí.

Duas condições:

- **O payload carrega dado, não `Instance`.** Manda-se o nome ou o `UserId`; quem resolve é
  o cliente. Passar `Character` por `RemoteEvent` é outro problema (§12.10).
- **Falha em silêncio.** Não achou, retorna — nunca `WaitForChild`, que penduraria a thread
  por um personagem que já morreu.

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

---

## Um caso real: o pack de VFX que "não cabia"

Vale registrar, porque o erro é fácil de repetir.

Chegou o pack `Stella's VFX Addon`. Eu abri o `MainModule` dele e vi isto:

```lua
Script.Parent = ReplicatedStorage     -- o módulo se muda para lá sozinho
-- "make sure to require via ID!"     -- o cabeçalho manda requerer por id
```

Concluí que o pack não cabia dentro da Tool e propus uma **exceção** à Regra nº 1: o pack
viveria em `ReplicatedStorage` e cada `VFXModule` o leria de lá. Escrevi o custo, escrevi as
condições, escrevi três verificadores para manter a exceção estreita. Tudo isso estava certo,
e tudo isso era resposta para a pergunta errada.

**O erro:** eu li o *loader* e generalizei para o pack inteiro. Os **módulos de efeito** não
dependem de nada. Medido, nos 10 que as Tools usam:

| | `require` | `ReplicatedStorage` | `ServerStorage` | Takeo |
|---|---|---|---|---|
| todos os 10 | 0 | 0 | 0 | 0 |

Cada um é um `return function(...)` com os próprios moldes como filhos. Copiados para dentro
da Tool, funcionam igual. Cabiam desde o começo.

O loader é que não cabe — e o loader **não precisa entrar**: ele existe só para pôr o pack em
`ReplicatedStorage`, que é justamente o que não queremos.

### O que ficou disso

1. **A regra não tem exceção.** Quando parecer que precisa de uma, o mais provável é que a
   medição esteja errada — não a regra.
2. **Medir por módulo, não por pacote.** O `_INDICE` do Acervo conta violações por arquivo
   por isso.
3. **Ficou uma ferramenta:** `FERRAMENTAS/conformar_pack_vfx.py` tira do pack só o que se
   usa, roda o passe §12.12.2 e deposita no Acervo pronto para ser copiado para dentro.
4. **O teste do place vazio é o critério, e é ele que decide** o que entra na lista das
   coisas que não são violação. Se o teste falha, é violação — por mais bem documentada que
   a justificativa esteja.
