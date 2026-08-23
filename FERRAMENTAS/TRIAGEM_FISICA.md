# Triagem — quatro motores de física

Data: 2026-08-23 · quatro repositórios avaliados a pedido, **clonados e lidos no código**,
não pelo README.

O critério é o mesmo da triagem anterior, e é a **regra nº 1**: o que a ferramenta produz
precisa caber **dentro da Tool**, funcionando sozinho num place vazio. A diferença é que
aqui não são ferramentas de autoria — são bibliotecas de **runtime**. Elas não param no
Studio: elas rodam junto com a habilidade. O escrutínio é mais duro por isso.

| Repositório | Licença | Último commit | Tamanho | Veredito |
|---|---|---|---|---|
| [LeoStormer/ragdoll-system](https://github.com/LeoStormer/ragdoll-system) | **MIT** | 2026-07-19 | 1 813 linhas | ✅ **ADOTAR o método** |
| [Ecliptorhizes/Hooksystem](https://github.com/Ecliptorhizes/Hooksystem) | **MIT** | 2026-03-09 | 3 891 linhas | ⚠️ **técnica sim, arquitetura não** |
| [jaipack17/Nature2D](https://github.com/jaipack17/Nature2D) | **MIT** | 2025-12-11 | 5 222 linhas | ❌ **incompatível** (2D em UI) |
| [birds3345/PaperPhysics](https://github.com/birds3345/PaperPhysics) | ⛔ **GPL-3.0** | 2024-07-05 | 1 476 linhas | ⛔ **não tocar no código** |

---

## ⛔ O achado legal, antes de tudo: PaperPhysics é GPL-3.0

Os outros três são MIT — licença permissiva, resolve o §12.12.3 sozinha, é o caso do
`vfx-editor`.

**`PaperPhysics` é GNU GPL v3.** Isso não é um detalhe de rodapé: a GPL é **copyleft**.
Copiar código dela para dentro de uma Tool obriga a Tool inteira — e discutivelmente o
place que a distribui — a sair sob GPL também, com código-fonte aberto para quem receber.

Não é "arriscado". É o que a licença diz que acontece.

> **Recomendação:** o `PaperPhysics` fica fora do fluxo de material do Acervo, e não como
> **CRU** — como **RECUSADO**. CRU quer dizer "ainda não passou pelo §12.12.2"; este não
> vai passar nunca, porque o problema não é conformidade, é licença. As regras novas
> ganham um estado a mais para isso, e é a única mudança de processo que este documento
> considera obrigatória.

Ler o repositório para aprender é legítimo e não contamina nada. Copiar linha, não.

---

## ✅ `ragdoll-system` — adotar o método

**É o repositório mais útil dos quatro, e por um motivo que já está escrito no CLAUDE.md:**
a proibição de `BreakJoints`.

O `BreakJoints` está banido porque desmonta o personagem sem volta. O substituto que este
repositório adotou foi **`PlatformStand`** — e ele é um ragdoll **falso**: o personagem
fica mole e cai, mas as juntas continuam rígidas. É um boneco de pau tombando, não um
corpo desabando.

**Hoje: `PlatformStand` aparece 143 vezes, em 70 das 94 Tools.** Toda vez que uma
habilidade "derruba" alguém, é isso que acontece.

### O que o `ragdoll-system` faz de diferente

Ele desliga o `Motor6D` e liga um **`BallSocketConstraint`** por junta, com limite de
ângulo e torque de atrito. O corpo passa a ser resolvido pelo motor de física da Roblox.

O blueprint R6 é **tabela de dados pura** — nenhuma linha de lógica:

```lua
socketSettings = {
    Neck            = { MaxFrictionTorque = 150, UpperAngle = 45, TwistLowerAngle = -30, TwistUpperAngle = 30 },
    RootJoint       = { MaxFrictionTorque = 50,  UpperAngle = 20, TwistLowerAngle = 0,   TwistUpperAngle = 30 },
    ["Right Shoulder"] = SHOULDER_SOCKET_SETTINGS,   -- 150 · 50 · -70 · 160
    ["Right Hip"]      = HIP_SOCKET_SETTINGS,        -- 150 · 40 · -60 ·  80
}
```

Seis juntas, quatro números cada. É **exatamente o formato do `Poses.lua`** deste
repositório: tabela de junta com valores, lida por um executor. A ficha do Acervo já
cataloga tabela de pose; esta é a mesma coisa para o corpo mole.

### E ele VOLTA — que é a parte que interessa

`deactivateRagdollPhysics()` restaura de `_originalSettings`: `WalkSpeed`, `AutoRotate`,
`CanCollide` de cada membro, `CustomPhysicalProperties`, o `Enabled` de cada `Motor6D` e de
cada socket. Guarda antes de mexer e devolve **aquilo**, nunca um valor fixo.

É o mesmo princípio do `afrouxar()` e do `atordoar()` que este repositório já escreve — e
foi por não guardar antes que o `atordoar` quase virou lentidão permanente empilhável.
Convergência independente: dois autores chegaram na mesma regra pelo mesmo motivo.

### Autocontenção: passa

`Ragdoll.new(character, blueprint)` cria uma `Folder` **dentro do personagem** e trabalha
só nas instâncias dele. Os `require` são relativos (`script.Parent.Parent.Types`). Nada de
`ReplicatedStorage`.

O que **não** passa são o `RagdollService.server.lua` e o `RagdollController` — camada de
distribuição, com `CollectionService:GetTagged("Ragdoll")` e Remotes num lugar central.
Essa camada fica de fora; a Tool não precisa dela.

⚠️ **Dependências:** `Trove` e `Signal` (sleitnick, MIT). Copiáveis, mas são ~300 linhas a
mais **por Tool**, em 70 Tools. Este repositório já resolve limpeza com `ativos` /
`guardar()` e não usa Signal em lugar nenhum.

> **Recomendação:** reimplementar em ~80 linhas nos padrões da casa, com o blueprint R6
> copiado como **dado** (a licença MIT permite, e dado é o que o Acervo sabe catalogar).
> Não é a mesma situação do `grims-cutscene-engine`, onde reimplementar era obrigatório
> por falta de licença — aqui é escolha de tamanho e consistência, e a atribuição MIT
> entra na ficha do mesmo jeito.

⚠️ **Interação com o `R6CFrameAnimator` V2, e ela não é opcional.** O animator solda
`Weld`s próprios; o ragdoll desliga `Motor6D`. São dois donos das mesmas juntas. Qualquer
ragdoll neste repositório tem de chamar `rig:CancelSequence()` e `rig:ReleaseLegs()` antes
de ligar, e o `Weld` da perna tem de sair — senão a perna soldada trava o corpo mole
exatamente como já trava a caminhada.

---

## ⚠️ `Hooksystem` — a técnica serve, a arquitetura não

**A arquitetura é incompatível, e por três motivos independentes:**

1. **78 referências a `ReplicatedStorage`.** É um framework de serviços, não um módulo.
2. **8 referências a `HttpService`** — o servidor de tuning ao vivo, por WebSocket. Dentro
   de uma Tool isso é inaceitável em qualquer leitura.
3. **O projétil voa por `RunService.Heartbeat` + `Workspace:Raycast` no SERVIDOR.** É
   literalmente a checagem vermelha que o `verificar_autocontencao.sh` já cobra neste
   repositório — "servidor não move geometria por frame" —, e que hoje falha em três
   escudos.

**Mas a técnica de amarrar é o que falta aqui.** O gancho dele é:

```
Attachment no braço  →  RopeConstraint (ou SpringConstraint)  →  Attachment no alvo
```

Duas instâncias e uma constraint. O motor de física da Roblox resolve o pêndulo, a
tensão e o comprimento sozinho, **sem uma linha por quadro**.

### O que isso resolve neste repositório

**55 Tools puxam ou prendem alguém hoje**, e todas fazem por `BodyPosition` reposicionado
em tique — `atrair()`, `prender()`, `suspender()`, `puxar()`. Um tique a cada 0.3–0.6 s,
com o alvo interpolando entre eles. É por isso que corrente e telecinese ficam "borrachudas".

Candidatas diretas: `Raio Joviano/Cadeia`, `Escudo Bumerangue`, `Telecinese Levitacao`,
`Telecinese Gravitacional`, `Lancador de Objetos`, `Colar das Trevas`.

Os números dele (`SpringStiffness = 8000`, `SpringDamping = 200`, `PullForceSingle = 20`)
são **daquele jogo**, com aquela escala e aquele peso. Servem de ponto de partida, não de
tabela para copiar.

---

## ❌ `Nature2D` — incompatível com a regra nº 1

Não é uma biblioteca de física 3D. É física **2D sobre elementos de UI**, e ela exige uma
`ScreenGui` na construção:

```lua
-- src/Engine.lua:33
if not typeof(screengui) == "Instance" or not screengui:IsA("Instance") then
    error("Invalid Argument #1. 'screengui' must be a ScreenGui.", 2)
end
```

Tudo o que ela simula é `GuiObject`. **`ScreenGui` dentro da Tool é proibido** — §12.12.4,
e é a regra que tirou as duas `ScreenGui` do `Fists` do Drama. Tool briga no mundo 3D.

Ainda: 3 `wait()`, 2 `spawn()`, 8 `:Destroy()`, e o laço é `RenderStepped`. Nada
insuperável isoladamente, mas irrelevante — o bloqueio é o `ScreenGui`, e ele não tem
contorno.

**O que vale ler:** ela resolve por **integração de Verlet** e restrições — posição
atual/anterior em vez de velocidade, e as amarras corrigidas em passes por iteração. É o
método certo para **corrente e corda desenhadas com `Part`** em 3D, que é o que a `Cadeia`
do Raio Joviano e o rastro do Bumerangue querem ser. Ler o método e escrever 40 linhas em
3D é barato; adotar a biblioteca é impossível.

---

## ⛔ `PaperPhysics` — não tocar no código

Além da GPL, os mesmos dois problemas do Nature2D: é **2D**, e o renderer desenha em
`Frame` com `UICorner` (`src/Renderer/BodyGraphics.luau`).

Uma observação de arquitetura, e só: o `Solver` tem **zero** referências a `Instance`. O
motor é headless e o renderer é separado — desenho limpo, e é a única coisa que dá para
levar daqui, como ideia, sem tocar em linha nenhuma.

---

# O que o repositório ganha, em números

Medido no código real das 94 Tools (linhas de comentário fora):

| Hoje | Quantas | Substituto moderno |
|---|---|---|
| `BodyVelocity` | **160 chamadas · 92 Tools** | `LinearVelocity` |
| `BodyPosition` | **84 chamadas · 55 Tools** | `AlignPosition` |
| `PlatformStand` como "ragdoll" | **143 chamadas · 70 Tools** | `BallSocketConstraint` |
| `RopeConstraint` · `SpringConstraint` · `BallSocketConstraint` | **0 · 0 · 0** | — |
| `LinearVelocity` | 8 chamadas · 5 Tools | — |
| `AlignPosition` | 1 chamada · 1 Tool | — |

**O padrão salta:** o repositório inteiro roda na família `BodyMover`, que a Roblox
**depreciou** em favor das constraints. Elas ainda funcionam — nada está quebrado hoje —
mas os quatro repositórios estudados, escritos entre 2021 e 2026, usam a API nova, e
nenhum usa a antiga.

E `BreakJoints` aparece **90 vezes em comentário e zero no código**. A proibição pegou.

---

# As decisões que as regras novas precisam tomar

Você disse que vai refazer as regras depois da análise. Estas são as decisões que a
análise põe na mesa — **propostas, não mudanças**: não mexi em nenhuma regra.

### 1. Um estado a mais no Acervo: `RECUSADO`

Hoje há CRU → LIMPO → APROVADO, e os três são sobre *conformidade*. Não há como registrar
"este material é bom e não pode entrar por causa da licença". O `PaperPhysics` é o primeiro
caso, e não será o último.

### 2. Migrar `BodyMover` → constraint, ou declarar que não migra

São 244 chamadas em 92 Tools. É a maior mudança mecânica que o repositório pode sofrer, e
ela tem de ser uma decisão explícita, não uma deriva Tool a Tool. As duas saídas honestas:

- **migrar tudo**, num passe só, com verificador que proíbe `BodyVelocity`/`BodyPosition` novos; ou
- **declarar `BodyMover` como o padrão da casa** e escrever o porquê, para parar de ser
  dívida silenciosa.

Meio a meio é o pior dos três — é o estado atual, com 8 `LinearVelocity` perdidos no meio
de 160 `BodyVelocity`.

### 3. `tombar()` vira ragdoll de verdade, ou fica declarado como tombo

A regra atual diz "nunca `BreakJoints`" e para aí. Ela não diz o que É um tombo. Com
`BallSocketConstraint` disponível e MIT, a pergunta deixa de ser técnica e vira de projeto:
70 Tools derrubam gente — todas com o mesmo peso, ou existe tombo leve e desabamento?

### 4. Corda e corrente ganham forma própria

`RopeConstraint` e `SpringConstraint` não têm equivalente na família `BodyMover`. As 55
Tools que puxam ou prendem hoje aproximam isso com `BodyPosition` em tique. Se corda entrar,
ela vira um ajudante do preâmbulo — `amarrar(alvo, ponto, comprimento)` — como `atrair` e
`suspender` são hoje.

### 5. A regra do animator ganha um parágrafo sobre juntas

`R6CFrameAnimator` V2 e ragdoll disputam as mesmas juntas. Hoje a regra diz "zero escrita
em `Motor6D.C0`" e "perna volta ao `Humanoid`". Falta: **quem desliga o animator antes de
entregar o corpo à física, e quem o religa depois.** Sem isso, a primeira Tool com ragdoll
vai reproduzir o bug de dois donos por junta que já aconteceu aqui.

### 6. Onde a linha de "biblioteca de runtime" fica

A triagem anterior era de ferramenta de autoria: roda no Studio, o artefato é o que
importa. Estes rodam **junto com a habilidade**. A regra nº 1 já responde na prática
(cabe dentro da Tool ou não cabe), mas vale dizer isso explicitamente — e dizer que
dependência transitiva conta: `Trove` + `Signal` são MIT e cabem, mas são 300 linhas
copiadas 70 vezes.

---

## O que NÃO foi verificado

Nada disto rodou no Studio. As leituras são estáticas: licença, `require`, quem constrói o
quê, e contagem no código das 94 Tools.

Especificamente sem confirmação em jogo:

- se o `BallSocketConstraint` do blueprint R6 dá um tombo **bom** com a escala e a massa
  deste repositório — os números são de outro jogo;
- se `RopeConstraint` replica bem para os outros clientes quando o alvo é um personagem;
- se trocar `BodyVelocity` por `LinearVelocity` muda a sensação dos 160 empurrões
  existentes. A API é diferente na unidade (`Velocity` vs `VectorVelocity` + `MaxForce`),
  então **não é substituição um-para-um**.
