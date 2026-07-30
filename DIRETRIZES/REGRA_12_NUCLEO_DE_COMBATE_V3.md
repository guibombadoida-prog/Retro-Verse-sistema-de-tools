# REGRA 12 — NÚCLEO DE COMBATE COMPARTILHADO **V3**
**Retro-Verse / Studios | Extensão das DIRETRIZES — SISTEMA DE TOOL v2.1**
Substitui integralmente a REGRA 12 V2 (e, por consequência, a V1)

---

## 12.-1 O QUE MUDOU DA V2 PARA A V3

| Mudança | Antes (V2) | Agora (V3) |
|---|---|---|
| **VFX de terceiros** | ❌ proibido ("assets alheios") | ✅ **permitido**, após passe de conformidade (§12.12) |
| **SFX de terceiros** | ❌ proibido | ✅ **permitido**, após passe de conformidade |
| **Animações R6 CFrame de terceiros** | ❌ proibido | ✅ **permitido**, após passe de conformidade |
| **Onde o material fica** | espalhado dentro de cada Tool | ✅ **ACERVO central obrigatório** (§12.16) — reuso em Tools futuras |
| Núcleo de combate | inalterado | inalterado |

O que **não** mudou: lógica de combate, NPCs, módulos de gear e `require(<id numérico>)` de terceiros continuam **proibidos**. Liberou-se o **material audiovisual**, não a **regra de jogo**.

---

## 12.0 POR QUE A V1 FOI REESCRITA

A V1 exigia que **toda Tool** desse `require` num ModuleScript:

```lua
local Nucleo = require(
	ServerScriptService:WaitForChild("RetroVerse"):WaitForChild("NucleoCombate_V1")
)
```

Três problemas apareceram na prática:

| Problema | Consequência |
|---|---|
| Exige **editar cada Tool** | Gear carregada por `InsertService` não é editável no Studio |
| Exige que a Tool **lembre** de chamar | A primeira que esquecer cria buraco de balanceamento silencioso |
| Acopla a Tool a um **caminho de instância** | Renomear a pasta `RetroVerse` quebra todas as Tools de uma vez |

E a auditoria mostrou que **nada disso é necessário**. Um Script central consegue, de fora, sem tocar em nenhuma Tool:

- descobrir toda Tool que entra na Backpack ou no Character;
- escutar `Activated`, `Equipped` e `Unequipped` de todas elas;
- saber **qual** Tool foi usada e **quando**;
- observar dano em qualquer Humanoid e atribuir a quem atacou;
- bloquear a Tool por recarga, escrevendo em `Tool.Enabled`.

> ⚠️ **A V2 inverteu o controle.** Na V1, a Tool chamava o Núcleo. Da V2 em diante, o Núcleo observa a Tool. **Nenhuma Tool precisa de `require`, de ModuleScript, ou de qualquer edição de código.**

---

## 12.1 PRINCÍPIO — A TOOL DECLARA INTENÇÃO, O NÚCLEO APLICA REGRA

A §10.11 protege o que deve ser **diferente** entre Tools: pose, ritmo, dramaturgia.
A §12 protege o que deve ser **idêntico**: quem pode ser atingido, quanto dano chega, quanto tempo até poder de novo.

| Camada | Regime | Onde vive |
|---|---|---|
| Pose, timing, VFX, SFX, lore | **Autoral** | Dentro da Tool — **com cópia no Acervo (§12.16)** |
| Dano, escudo, redução, crédito, recarga | **Compartilhado** | Script central, fora da Tool |
| Números de balanceamento | **Autoral** | `Value`s dentro da Tool (§12.4) |
| Material audiovisual reutilizável | **Arquivo** | Acervo central, **nunca dependência de runtime** (§12.16) |

**A Tool nunca escreve regra de combate. Ela declara o que é, e o Núcleo faz o resto.**

---

## 12.2 LOCALIZAÇÃO

```
ServerScriptService
└── NucleoCombate            (Script — não ModuleScript)
```

**Um Script comum, sozinho, sem pasta obrigatória.** Ele se registra em `_G.Combate` na inicialização.

### ❌ Proibido

| Prática | Por quê |
|---|---|
| `require` do Núcleo dentro de uma Tool | A Tool não deve conhecer o Núcleo |
| Copiar lógica de combate para dentro da Tool | Divergência de regra entre Tools |
| Reimplementar `canDamage` / `IsTeamMate` / `TagHumanoid` na Tool | A porta é única |
| `require(<id numérico>)` de módulo externo | Código não auditável no servidor |
| Clonar qualquer coisa para `ServerStorage` / `ReplicatedStorage` no load | Efeito colateral global fora da Tool |
| A Tool ler o Acervo em runtime | O Acervo é prateleira de edição, não dependência (§12.16.4) |

---

## 12.3 O QUE O NÚCLEO FAZ SOZINHO

Sem uma linha dentro da Tool:

| Capacidade | Como |
|---|---|
| **Descobrir Tools** | Varre Backpack e Character; escuta `ChildAdded`. Pega gear de `InsertService` também |
| **Saber quem atacou** | `Tool.Activated` + janela de tempo + alcance. Quem está parado do lado não recebe crédito |
| **Saber com o quê** | Guarda a Tool ativada, então conhece a classe de dano e o custo |
| **Aplicar aumento e redução** | Observa a vida dos Humanoids e corrige (ver §12.5 e o aviso da §12.8) |
| **Escudo** | Absorve antes de a vida cair abaixo do limite |
| **Crédito de abate** | Cria a tag `creator` com `Name` e `Value` **antes** do `Parent` (§12.7) |
| **Recarga global** | Trava `Tool.Enabled` por jogador + chave, imune a clone na mochila |
| **Custo de energia** | Lê `EnergyCost` da Tool e desconta |

---

## 12.4 COMO A TOOL DECLARA INTENÇÃO — `Value`s, NÃO CÓDIGO

A Tool declara o que ela **é** com objetos `Value` dentro dela. Adicionar um `Value` no Studio **não é editar código** — funciona em gear que você não pode reescrever.

```
Tool
 ├── Handle
 ├── DamageClass    (StringValue)  "Melee" | "Ranged" | "Magic" | "Summon" | "Debuff"
 ├── EnergyCost     (NumberValue)  custo por ativação
 ├── RecargaGlobal  (NumberValue)  segundos; 0 ou ausente = sem recarga
 └── ChaveRecarga   (StringValue)  opcional — Tools irmãs que compartilham recarga
```

**Todo `Value` é opcional.** Ausente, o Núcleo usa o padrão:

| `Value` | Padrão se ausente |
|---|---|
| `DamageClass` | `"Melee"` |
| `EnergyCost` | valor global do sistema de energia |
| `RecargaGlobal` | sem recarga (só o `Tool.Enabled` da própria Tool) |
| `ChaveRecarga` | o nome da Tool |

> ⚠️ **Sem `DamageClass`, todo bônus por classe fica inerte.** Um personagem com arquétipo "Lutador (Melee)" não recebe nada — o bônus aparece certo na tela e não acontece em jogo. É a etiqueta mais barata e a mais esquecida.

---

## 12.5 PIPELINE DE DANO

```
dano que a Tool aplicou
  → × (1 + aumento + Σ modificadores)   [aditivo, teto 300%]
  → × (1 − redução do alvo)             [multiplicativo, teto 90%]
  → − escudo do alvo                    [consome pontos, em ordem]
  → correção da vida do alvo
  → tag creator
  → avisa os ouvintes (Vampírico, XP, telemetria)
```

| Decisão | Razão |
|---|---|
| Redução empilha **multiplicativamente** | Três reduções de 40% dão 78,4%, nunca 120%. Imunidade por acidente é impossível |
| Aumento empilha **aditivamente com teto** | Buffs somam de forma legível, mas não explodem |
| Modificadores entram **no mesmo grupo aditivo** | Se cada um multiplicasse por fora, Frenesi + Duelista + fraqueza elemental matariam um chefe num golpe |
| Escudo consome **antes** de a vida assentar | Escudo é HP paralelo, não redução percentual |

### Modificadores dinâmicos

Três efeitos dependem da **relação** atacante×alvo, não de um número fixo:

| Efeito | Depende de |
|---|---|
| Frenesi | vida **atual** do atacante |
| Duelista | nível do atacante **vs.** nível do alvo |
| Vampírico | dano **final**, depois de tudo |

Eles são registrados **por sistemas**, uma vez, na inicialização — nunca por Tool:

```lua
_G.Combate.registrarModificador("Passiva_Frenesi", function(contexto)
	-- devolve CONTRIBUIÇÃO DE AUMENTO (0.25 = +25%), nunca multiplicador
end)

_G.Combate.aoAplicarDano(function(contexto, danoFinal)
	-- Vampírico, XP, contadores
end)
```

**Convenção de nome:** `[Sistema]_[Efeito]` — ex.: `Passiva_Frenesi`, `Elemento_Fraqueza`.

**Proibido uma Tool registrar modificador.** Modificador é regra global: uma Tool registrando alteraria o dano de todas as outras.

---

## 12.6 MODO PRECISO — OPCIONAL, SEM ModuleScript

Uma Tool **pode** pedir o dano calculado antes de aplicar. Não é obrigatório, não usa `require`, não depende de caminho de instância:

```lua
--// ❌ V1 — exigia ModuleScript e caminho
local Nucleo = require(ServerScriptService.RetroVerse.NucleoCombate_V1)
Nucleo.aplicarDano(alvo, 40, jogador, personagem)

--// ✅ V2/V3 — uma linha, sem require
local final = _G.Combate and _G.Combate.calcular(jogador, alvoHumanoid, 40) or 40
alvoHumanoid:TakeDamage(final)
```

**Ganho do modo preciso:** o escudo absorve de verdade em vez de devolver vida, e a barra não pisca.
**Se a Tool não fizer isso, tudo continua funcionando** — só com a imprecisão da §12.8.

Também disponível sem `require`:

```lua
_G.Combate.detectarHumanoides(posicao, raio, ignorar, jogador, humanoideDono, limite)
_G.Combate.podeCausarDano(jogador, humanoideAlvo, humanoideDono)
_G.Combate.recargaGlobal(jogador, "NomeTool_Habilidade", 12)
_G.Combate.registrarEscudo(personagem, 120, 8)   -- devolve função de cancelar
_G.Combate.registrarReducao(personagem, 0.35)
_G.Combate.registrarAumento(personagem, 0.20, 5)
```

Todo registro devolve **a própria função de cancelamento** — sem `:Destroy()`, sem `AncestryChanged`, sem `Folder` de `NumberValue`. Registro sem duração **obriga** cancelamento em `Tool.Destroying` e em `Humanoid.Died`. Registro órfão é escudo permanente: falha grave.

---

## 12.7 CRÉDITO DE ABATE — ORDEM DAS PROPRIEDADES

O Núcleo cria a tag assim, e a ordem **não é estilo**:

```lua
local credito = Instance.new("ObjectValue")
credito.Name = "creator"      -- 1º
credito.Value = jogador       -- 2º
credito.Parent = humanoide    -- 3º, SEMPRE por último
```

**Por quê:** `Instance.new("ObjectValue", pai)` e laços com `pairs()` definem o `Parent` antes do `Name`. Quando isso acontece, quem escuta `ChildAdded` no Humanoid vê um objeto ainda chamado `"Value"` e vazio — e ignora. Foi assim que uma tag corretamente criada ficou invisível para o sistema inteiro.

Nunca usar `Health = Health - dano` para matar: `TakeDamage` respeita `ForceField` nativo.

---

## 12.8 ⚠️ O QUE SE PERDE SEM COOPERAÇÃO DA TOOL

**Esta seção existe para que a limitação esteja escrita, e não seja descoberta em bug.**

O motor do Roblox **não informa quem causou dano**. Isso foi pedido em 2014 (`TakeDamage(dano, jogadorAtacante)`) e nunca implementado. Também não é possível sobrescrever `TakeDamage`. Portanto, sem cooperação da Tool, o Núcleo **observa e corrige**, em vez de calcular antes.

| Limitação | Efeito prático | Contorno |
|---|---|---|
| Correção é **depois** do golpe | A vida cai e volta no mesmo instante. Em ping alto, dá pra ver | Modo preciso (§12.6) |
| Escudo **devolve** vida em vez de absorver | Cosmético, mas visível | Modo preciso |
| Atribuição por janela **erra em multidão** | Dois jogadores atacando o mesmo alvo no mesmo instante podem trocar de crédito | Tag `creator` na Tool |
| Detecção em área não é substituível | Se a Tool usa `Instance.new("Explosion")`, o Núcleo não intercepta | A Tool usar `_G.Combate.detectarHumanoides` |
| Dano de habilidade que não usa Tool | Não é rastreado | A Tool avisar com `_G.Combate.registrarAtaque` |

**Regra de decisão:** gear que você **pode** editar deveria usar o modo preciso. Gear que você **não pode** (`InsertService`, terceiros) funciona no modo observado, com essas imprecisões aceitas conscientemente.

---

## 12.9 RECARGA GLOBAL — ANTI-EXPLOIT DE CLONES

`Tool.Enabled` é por instância. Três cópias da mesma Tool na mochila disparam a habilidade três vezes.

A recarga é registrada **no Jogador**, por chave nomeada:

```lua
local liberado, restante = _G.Combate.recargaGlobal(jogador, "AstralPulsar_X", 12)
if not liberado then return end
```

Sem tocar na Tool, o Núcleo faz isso sozinho lendo `RecargaGlobal` e `ChaveRecarga` (§12.4) — ele trava e destrava o `Tool.Enabled` de todas as cópias.

Usa `os.clock()`, monotônico, que **nunca alimenta `CFrame`**. Isto **não** revoga a proibição de `tick()` nem substitui acumulador `dt` em animação (§10.11.7).

`Tool.Enabled` continua sendo debounce da habilidade primária, e continua **sem ser resetado em `Unequipped`** (§8 / §10.7).

---

## 12.10 ESTRUTURA MÍNIMA DE TOOL

```
Tool
 ├── Handle
 ├── DamageClass / EnergyCost / RecargaGlobal   (Values — §12.4)
 ├── [NomeDaTool]_Server_V[X]   (Server Script — SEM require do Núcleo)
 ├── Client                     (LocalScript — input + recepção de VFX)
 ├── VFXRemote                  (RemoteEvent — unidirecional)
 ├── R6CFrameAnimator           (ModuleScript — V1 ou V2)
 ├── Poses                      (ModuleScript — autoral ou de terceiros, §12.12)
 └── VFXModule                  (ModuleScript — autoral ou de terceiros, §12.12)
```

**Sai da Tool:** `canDamage`, `IsTeamMate`, `TagHumanoid`, escudo, redução, aumento, recarga global.
**Permanece na Tool:** poses, sequências, VFX, SFX, números de balanceamento e lore.
**Vai também para o Acervo:** cópia de todo VFX, SFX e pose R6 CFrame usados (§12.16).

Números de balanceamento em bloco único no topo, junto do `ARQUETIPO` (§10.11):

```lua
local ARQUETIPO = "HIBRIDO"

local CFG = {
	DANO_BASE       = 28,
	DANO_HABILIDADE = 65,
	RAIO_AREA       = 24,
	RECARGA_X       = 18,
}
```

Números mágicos espalhados pelo corpo do script são violação.

---

## 12.11 VFX — O SERVIDOR TRANSMITE, NUNCA EMITE

```lua
--// ❌  Particulas:Emit(80)
--// ✅
_G.Combate.transmitirVFX(VFXRemote, "IMPACTO", {
	posicao = ponto, escala = 2.4, cor = Color3.fromRGB(140, 90, 255),
})
```

Payload é **dado**, nunca `Instance` — mandar `Instance` força replicação e anula o ganho.
**Ordem de impacto (§8 V2):** SFX → física → VFX → dano.

Esta regra vale **igualmente** para VFX de terceiros: o módulo importado roda no **cliente**, disparado por `VFXRemote`. Módulo de terceiro que emite no servidor é reescrito antes de entrar (§12.12.2).

---

## 12.12 MATERIAL DE TERCEIROS — **AGORA PERMITIDO**

### 12.12.1 O que é permitido

| Material | Status V3 | Condição |
|---|---|---|
| **VFX** (ParticleEmitter, Beam, Trail, meshes, módulos de efeito) | ✅ **Permitido** | Passe de conformidade §12.12.2 + entrada no Acervo §12.16 |
| **SFX** (sons, IDs de áudio, camadas de impacto) | ✅ **Permitido** | Idem |
| **Animações R6 em CFrame** (tabelas de pose, sequências de junta) | ✅ **Permitido** | Idem + rodar sob `R6CFrameAnimator` |
| Lógica de combate / dano / status de terceiros | ❌ Proibido | O Núcleo é a única porta (§12.2) |
| NPCs e módulos de gear de terceiros | ❌ Proibido | Regra de jogo alheia |
| `require(<id numérico>)` externo | ❌ Proibido | Código não auditável em runtime |
| `Animation` / `AnimationTrack` asset | ❌ Proibido | §10 — animação é CFrame procedural |
| `ScreenGui` / `ColorCorrection` / `Sky` embutidos no efeito | ❌ Proibido | Removidos no passe de conformidade |

> 📌 **A fronteira é simples:** entra o que se **vê e se ouve**. Não entra o que **decide dano, alvo ou estado**.

### 12.12.2 Passe de conformidade — obrigatório antes de usar

Nenhum material de terceiro vai direto para a Tool. Ele passa por esta lista, e o resultado é registrado na ficha do Acervo:

| Achado | Correção |
|---|---|
| `:Emit(n)` no servidor | `Enabled = true/false` + `Rate`; burst pré-criado e reusado |
| `require(<id numérico>)` | Módulo copiado para dentro da Tool, ou efeito reescrito |
| `math.random` em gameplay | Vogel/ângulo áureo, jitter senoidal por contador, módulo sequencial |
| `wait()` / `spawn()` / `delay()` | `task.wait` / `task.spawn` / `task.delay` |
| `tick()` | acumulador `dt` local a partir de zero (§10.11.7) |
| `:Destroy()` em part/bodymover | `Parent = nil` ou `Debris`, registrado em `ActiveEffects` |
| `AncestryChanged` para cleanup | `Tool.Destroying` |
| `Instance.new("Explosion")` | Template §8 V2 + `_G.Combate.detectarHumanoides` |
| `ScreenGui` / overlay de tela | Removido; o efeito permanece só no mundo 3D |
| Clone para `ServerStorage` / `ReplicatedStorage` no load | Material fica **dentro da Tool** |
| `+=` / `continue` | Sintaxe expandida |
| Animação por `LoadAnimation` | Convertida em tabela de poses CFrame para `R6CFrameAnimator` |

Só material com status **APROVADO** entra numa Tool.

### 12.12.3 Crédito e origem

Todo material de terceiro carrega, na ficha do Acervo (§12.16.3): **autor**, **origem**, **licença ou permissão** e **data de entrada**. Sem esses quatro campos, o material fica em **CRU** e não pode ser usado.

### 12.12.4 O que **não** entra no Núcleo

**Regra de crescimento:** função nova entra no Núcleo só quando **duas ou mais Tools** precisarem. Uma Tool com necessidade única implementa dentro de si.

| Recurso | Status | Motivo |
|---|---|---|
| Lógica de status effect de terceiros | ❌ | Regra de jogo é do Núcleo; o **visual** dela é liberado (§12.12.1) |
| `LocalScript` em `ScreenGui` | ❌ | `ScreenGui` proibido nas Tools |
| Lista de nomes hardcoded | ❌ | Acoplamento por nome de instância; frágil |
| `Health -= dano` + `BreakJoints` | ❌ | Fura `ForceField`; `TakeDamage` cobre |
| Voo, câmera, posição de mouse | ⏸️ | Só quando houver Tool que exija |

---

## 12.13 MIGRAÇÃO

**Nenhuma Tool precisa migrar para o sistema funcionar.** Instalado o Núcleo, todas passam a receber crédito, aumento, redução, escudo e recarga automaticamente.

Migrar é **opcional**, e só vale para gear que você controla:

1. Adicionar `DamageClass` — 1 `Value`, sem código. **Maior ganho pelo menor esforço.**
2. Adicionar `RecargaGlobal` se a habilidade precisar — 1 `Value`.
3. Trocar `Instance.new("Explosion")` por `_G.Combate.detectarHumanoides`.
4. Adotar o modo preciso (§12.6) — 1 linha antes do `TakeDamage`.
5. **Depositar VFX / SFX / poses R6 da Tool no Acervo** (§12.16) — não muda nada em jogo, mas é o que evita reconstruir o mesmo efeito na próxima Tool.

**Prioridade:** passo 1 em todas as gears primeiro. Sem ele, todo bônus por classe do jogo está desligado.

---

## 12.14 CHECKLIST DE CONFORMIDADE

**Núcleo**
- [ ] `NucleoCombate` (Script) em `ServerScriptService`, um só, não Disabled
- [ ] `_G.Combate` disponível — confirmado no Output na inicialização
- [ ] Zero ModuleScript de combate exigido por Tool

**Todas as Tools**
- [ ] Zero `require` do Núcleo
- [ ] Zero `require(<id numérico>)` externo
- [ ] `DamageClass` declarado
- [ ] Zero `canDamage` / `IsTeamMate` / `TagHumanoid` reimplementados
- [ ] Bloco `CFG` no topo; zero números mágicos
- [ ] `Tool.Enabled` não resetado em `Unequipped`
- [ ] Zero efeito colateral fora da Tool
- [ ] Zero leitura do Acervo em runtime

**Tools no modo preciso (opcional)**
- [ ] `_G.Combate.calcular` antes do `TakeDamage`, com guarda `_G.Combate and`
- [ ] `Instance.new("Explosion")` substituído por `detectarHumanoides`

**Tools com escudo, redução ou buff**
- [ ] Registro via `_G.Combate.registrar*`
- [ ] Função de cancelamento guardada em variável local
- [ ] Cancelamento em `Tool.Destroying`, `Humanoid.Died` e em todo caminho de saída

**Sistemas que registram modificador**
- [ ] Registro uma vez na inicialização — nunca por jogador nem por golpe
- [ ] Devolve **contribuição de aumento**, nunca multiplicador
- [ ] Função barata — roda a cada golpe de cada Tool
- [ ] Comportamento definido quando o alvo é NPC

**VFX**
- [ ] `VFXRemote` unidirecional, zero `OnServerEvent`
- [ ] Payload de dados puros, zero `Instance`
- [ ] Zero `:Emit()` no servidor
- [ ] Ordem §8 V2 respeitada

**Material de terceiros (§12.12)**
- [ ] Só VFX, SFX e pose R6 CFrame — zero lógica de combate importada
- [ ] Passe de conformidade §12.12.2 executado e registrado
- [ ] Ficha com autor, origem, licença e data
- [ ] Status **APROVADO** antes de entrar na Tool

**Acervo (§12.16) — obrigatório em toda entrega**
- [ ] Busca no Acervo feita **antes** de criar efeito novo
- [ ] Todo VFX, SFX e pose R6 da entrega depositado na pasta do modelo
- [ ] `FICHA.md` preenchida e `_INDICE.md` atualizado
- [ ] Acervo não referenciado por nenhum script em runtime

---

## 12.15 NOMENCLATURA

- `NucleoCombate.lua` — Script central (nome do objeto **sem versão**, senão os sistemas não o encontram)
- `[NomeDaTool]_Server_V[X].lua` — script da Tool
- Chave de recarga: `"[NomeDaTool]_[Habilidade]"` — ex.: `"AstralPulsar_X"`
- Modificador: `"[Sistema]_[Efeito]"` — ex.: `"Passiva_Frenesi"`
- Tipo de VFX: `MAIUSCULA_COM_UNDERSCORE` — ex.: `"IMPACTO_NOVA"`
- Pasta de modelo no Acervo: `Nome_Do_Modelo_De_Origem/` — ex.: `Jupiter_Great_Pressure_Sword/`
- Entrada de efeito no Acervo: `NOME_DO_EFEITO/` em `MAIUSCULA_COM_UNDERSCORE` — ex.: `SPIRAL_EXPLOSION/`
- Poses: `Poses_[Modelo]_V[X].lua` — ex.: `Poses_Jupiter_V1.lua`

---

## 12.16 ⭐ ACERVO COMPARTILHADO DE VFX · SFX · R6 CFRAME — **REGRA NOVA (V3)**

> **Regra dura, sem exceção:** todo VFX, SFX e animação R6 em CFrame que passar pelo projeto — autoral **ou** de terceiro — é **guardado no Acervo**, dentro da **pasta do modelo de origem**, dentro da **pasta principal**. O objetivo é um só: **nunca reconstruir do zero um efeito que já existe.**

### 12.16.1 Estrutura obrigatória

```
ACERVO_RETROVERSE/                          ← PASTA PRINCIPAL (única)
├── _INDICE.md                              ← catálogo geral: efeito · origem · tipo · status
├── _PADROES.md                             ← convenções e armadilhas conhecidas
│
├── Jupiter_Great_Pressure_Sword/           ← PASTA DO MODELO (uma por origem)
│   ├── FICHA.md                            ← autor, origem, licença, data, status
│   ├── VFX/
│   │   ├── SPIRAL_EXPLOSION/
│   │   │   ├── Spiral_Explosion.lua
│   │   │   ├── Spiral_Explosion.rbxmx      ← instâncias (emitters, meshes, attachments)
│   │   │   └── NOTAS.md                    ← parâmetros, escala, custo, onde já foi usado
│   │   ├── SMALL_NOVA/
│   │   └── SHOCKWAVE_2/
│   ├── SFX/
│   │   └── IMPACTO_GRAVE/
│   │       ├── ids.md                      ← rbxassetid + volume/pitch/rolloff padrão
│   │       └── Impacto_Grave.rbxmx
│   └── R6_CFRAME/
│       ├── Poses_Jupiter_V1.lua
│       └── NOTAS.md                        ← juntas usadas, duração, easing
│
├── Sword_of_Cosmic_Entity/
│   ├── FICHA.md
│   ├── VFX/  SFX/  R6_CFRAME/
│
└── _AUTORAL_RetroVerse/                    ← efeitos criados internamente
    ├── FICHA.md
    ├── VFX/  SFX/  R6_CFRAME/
```

**Três níveis, sempre:** `ACERVO_RETROVERSE/` → `[Modelo_De_Origem]/` → `VFX | SFX | R6_CFRAME/` → `NOME_DO_EFEITO/`.

Espelho opcional no Studio: `ServerStorage/ACERVO_RETROVERSE` — **prateleira de edição**, com todo conteúdo `Archivable`, **nunca** referenciada por script em runtime.

### 12.16.2 Fluxo obrigatório de toda entrega

| Momento | Ação |
|---|---|
| **Antes** de criar qualquer efeito | Ler `_INDICE.md`. Se já existe algo equivalente, **reusar e adaptar**, não recriar |
| Ao importar material de terceiro | Criar a pasta do modelo, depositar em **CRU**, rodar o passe §12.12.2, marcar **APROVADO** |
| Ao criar efeito autoral novo | Depositar em `_AUTORAL_RetroVerse/` no mesmo formato |
| Ao **finalizar** a Tool | Depositar todo VFX/SFX/pose novo ou modificado e atualizar `_INDICE.md` |
| No relatório de entrega | Seção **"Delta do Acervo"**: o que entrou, o que foi reusado, o que mudou de status |

**Entrega sem delta do Acervo é entrega incompleta.**

### 12.16.3 `FICHA.md` — campos mínimos

```markdown
# Modelo: Jupiter Great Pressure Sword
- Autor original: ICAN_REA0 / TakeoHonorable
- Origem: JupiterGreatSword.rbxm (Toolbox)
- Licença / permissão: free model público — uso audiovisual
- Data de entrada: 2026-07-30
- Status: APROVADO   (CRU | LIMPO | APROVADO)
- Violações corrigidas: :Emit server-side, require(125275839196878), math.random, ScreenGui
- Excluído do acervo: Impact_Frame (ScreenGui/ColorCorrection/Sky)
- Já usado em: Tryhard_V3, Cajado_Astral_V1
```

| Status | Significado |
|---|---|
| **CRU** | Recém-importado. Não pode entrar em Tool |
| **LIMPO** | Passe §12.12.2 executado, aguardando teste em jogo |
| **APROVADO** | Testado. Livre para reuso em qualquer Tool |

### 12.16.4 O Acervo **nunca** é dependência de runtime

O Acervo é arquivo de trabalho. A Tool continua **autocontida**: o material é **copiado para dentro dela** na montagem.

| ❌ Proibido | ✅ Correto |
|---|---|
| `ServerStorage.ACERVO_RETROVERSE:FindFirstChild(...)` num script de Tool | Cópia do módulo/instância dentro da própria Tool |
| Tool que quebra se a pasta for renomeada | Tool que funciona com o Acervo inteiro deletado |
| Clonar o Acervo para `ReplicatedStorage` no load | Nada é clonado para fora da Tool |

**Teste de aceitação:** apague o Acervo do place — **toda Tool continua funcionando**. Se alguma quebra, ela violou esta seção.

### 12.16.5 Por que isso existe

| Sem Acervo | Com Acervo |
|---|---|
| O mesmo shockwave é reescrito em 6 Tools, cada uma com um bug diferente | Um shockwave testado, reusado 6 vezes |
| O passe de conformidade é refeito toda vez no mesmo asset | Feito uma vez, registrado na ficha |
| Origem e licença de material de terceiro se perdem | Rastreável na `FICHA.md` |
| "Qual Tool tinha aquele som de impacto grave?" | `_INDICE.md` |

---

> 📌 **Leitura final:** a V1 pedia que toda Tool lembrasse de chamar o Núcleo — bastava uma esquecer para abrir um buraco invisível. A V2 tirou essa responsabilidade da Tool. A **V3** ataca o outro desperdício: material audiovisual bom sendo recusado por origem, e material já resolvido sendo refeito do zero. **Terceiro pode entrar — desde que passe pelo crivo e fique guardado no Acervo.** O que nunca entra é regra de combate de fora: essa porta continua sendo uma só.
