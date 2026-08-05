# REGRA DA AUTOCONTENÇÃO ABSOLUTA
**Retro-Verse / Studios** · **Regra nº 1 — vence todas as outras, inclusive a REGRA 12 V3**

---

## O enunciado

> **Nada de referência de script FORA da Tool.**
> Todo script, animação, VFX, SFX, mesh, MeshPart, textura, som, pose e módulo é
> **obrigatoriamente, absolutamente** filho da Tool.

Não há "só esse caso" e não há pasta compartilhada de conveniência.

Há **uma** exceção, e ela é declarada, nominal e verificada: o pack de VFX compartilhado
(ver [A exceção declarada](#a-exceção-declarada--o-pack-de-vfx-compartilhado), no fim deste
documento). Qualquer outra coisa fora da Tool continua sendo violação — inclusive outro
pack, inclusive "o mesmo pack, mas com um som junto".

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
| `game:GetService("ReplicatedStorage")` e qualquer descendente | Referência fora da Tool — salvo a [exceção declarada](#a-exceção-declarada--o-pack-de-vfx-compartilhado) |
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
O que as cinco têm em comum: nenhuma delas faz o teste do place vazio falhar.

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

Não existe Tool que acerte alguém sem localizar esse alguém. O personagem não é asset que
possa viajar dentro da Tool: ele nasce no place, em runtime. É a mesma natureza de
`Players.LocalPlayer` e `workspace.CurrentCamera`, já aceitas nos itens anteriores.

A linha entre as duas é o **literal**. Buscar `"MeuEfeito"` é depósito; buscar `nome`, que
chegou pelo `RemoteEvent`, é resolver quem está em campo. O verificador corta exatamente aí:

```bash
checar "sem buscar asset em workspace"   # só a forma com string literal
```

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

- [ ] Tool sozinha em place vazio → funciona por inteiro, **sem os efeitos do pack**
- [ ] `ACERVO_RETROVERSE` deletado → funciona
- [ ] `NucleoCombate` deletado → funciona, sem os bônus
- [ ] `ReplicatedStorage` e `ServerStorage` vazios → funciona, **sem os efeitos do pack**
- [ ] Todo `Sound`, mesh, textura e molde de VFX é descendente da Tool

---

## A exceção declarada — o pack de VFX compartilhado

Esta é a **única** exceção à Regra nº 1. Não é um caso especial descoberto depois: é uma
decisão tomada com o custo na mesa, e escrita aqui para que ninguém precise adivinhar
depois se aquilo era permitido.

### O que é

O pack `Stella's VFX Addon` (116 ModuleScripts) vive em `ReplicatedStorage`, e cada
`VFXModule` de Tool pode lê-lo — **só ele, e só de lá**.

### Por que não coube dentro

Não é preferência de estilo. É como o pack funciona:

| | |
|---|---|
| `Script.Parent = ReplicatedStorage` | o `MainModule` **se muda para lá sozinho**, na primeira execução |
| `require(<id>)` × 36 | o próprio cabeçalho manda: *"make sure to require via ID!"* |
| Dependência externa | é addon do **Takeo's VFX System**, que é outro módulo |

Copiar os 116 módulos para dentro de cada uma das 7 Tools daria 7 cópias do mesmo pack — e
o `MainModule` continuaria tentando se mudar para `ReplicatedStorage` no primeiro uso.
A cópia resolveria o tamanho do arquivo e nada mais.

### O que a exceção custa, dito claramente

**O teste do place vazio deixa de valer para o VFX, e só para o VFX.**

Arraste uma Tool sozinha para um place sem o pack: ela funciona — golpe, dano, som,
animação, cutscene, tudo — mas sem os efeitos do pack. O `VFXModule` cai nos efeitos
próprios da Tool, que continuam lá dentro, filhos dela.

> **A Tool não quebra. A Tool empobrece.** É essa a diferença que a exceção compra, e é
> por isso que ela é aceitável.

### As três condições que a mantêm estreita

Não basta declarar a exceção; ela tem de ser **estruturalmente incapaz** de crescer.

1. **Não yielda.** `game:FindService` + `FindFirstChild`, jamais `WaitForChild`. Sem o pack,
   a busca devolve `nil` no mesmo frame. `WaitForChild` penduraria a thread para sempre — e
   aí sim a Tool quebraria, não empobreceria.
2. **Não derruba o efeito próprio.** O efeito da Tool roda **primeiro e inteiro**; o reforço
   do pack vem depois, dentro de `pcall`. Pack ausente, quebrado ou de outra versão não
   encosta no que a Tool desenha sozinha.
3. **Só sai forma, cor e tempo.** Dano, alvo e estado continuam sendo assunto do servidor e
   do Núcleo. Um pack de terceiro nunca decide regra de jogo (§12.12).

### O que a exceção NÃO autoriza

- depositar `Sound`, `Mesh`, `Texture` ou pose de Tool em `ReplicatedStorage`
- `require(<id numérico>)` dentro de script de Tool — continua proibido, sem ressalva
- qualquer outro `ReplicatedStorage` em script de Tool que não seja o pack declarado
- um **segundo** pack compartilhado: a exceção é nominal, não é categoria

### Como isso é verificado

Três checagens em `TESTES/verificar_autocontencao.sh`, e elas falham sozinhas se alguém
alargar a exceção sem passar por aqui:

```
✓ ReplicatedStorage só no VFXModule, e só via FindService
✓ o VFXModule não espera por nada
✓ do depósito só sai o nome declarado em PACK.DEPOSITO
```

A terceira segue a variável que recebeu o serviço e exige que **tudo** lido nela seja
`PACK.DEPOSITO`. Um `Sound` puxado de lá cai na hora.

### Efeitos do pack que ficaram de fora

A lista não é preguiça — foi lida no código de cada módulo, e cada linha tem motivo:

| Efeito | Por que não entra |
|---|---|
| `Flung_Debris`, `Particle_Debris` | criam `Part` não-ancorada com `AssemblyLinearVelocity` e `CanCollide` (o parâmetro é inerte: o módulo faz `CanCollide or true`). Detrito sólido no cliente empurra o próprio personagem — **VFX não mexe em gameplay** |
| `Impact_Frame` | troca o `Sky`, liga `ColorCorrection` e põe `ScreenGui` — as três proibidas dentro de Tool |
| `Sharp_Crater`, `Smooth_Crater` | varrem `workspace:GetDescendants()` a cada chamada; numa arena cheia é engasgo de frame no impacto, justo onde não pode |
| `Wind_Effect`, `Wind_Spiral` | exigem uma `Instance` de fora como âncora |
| `Fire_Circle` | contrato quebrado no próprio pack: usa `Size` como `Vector3` e depois chama `:Emit(Size)`, que espera número |

O que sobrou é o que é ancorado, movido a `Tween` e fechado nos argumentos.

### Origem (§12.12.3)

| Campo | Valor |
|---|---|
| Autor | **Stellabotrus** (declarado no cabeçalho dos módulos) |
| Base | addon do *Takeo's VFX System* |
| Licença | **a confirmar** ⚠️ |
| Data de entrada | 2026-08-05 |

Enquanto a licença não estiver preenchida, o pack está **CRU** pela §12.12.2: entra como
reforço opcional, e nenhuma Tool depende dele para funcionar — que é exatamente o estado
que esta exceção já garante.
