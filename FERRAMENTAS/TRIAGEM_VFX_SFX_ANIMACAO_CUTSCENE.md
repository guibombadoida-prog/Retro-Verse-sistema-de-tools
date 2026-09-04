# Triagem — VFX, SFX, animação e cutscene

Data: 2026-08-29 · **onze repositórios clonados e lidos no código**, não pelo README.
Pedido: pesquisa profunda em repositórios do GitHub sobre lógica de VFX, SFX, animação e
cutscene, obrigatoriamente de Roblox Studio.

O critério é o de sempre, e é a **regra nº 1**: o que a biblioteca produz precisa caber
**dentro da Tool**, funcionando sozinho num place vazio. Biblioteca de runtime é julgada
mais duro que ferramenta de autoria, porque ela roda junto com a habilidade.

E o critério novo, que esta leva impôs: **nenhuma destas onze entra inteira.** Copiar 800
linhas de terceiro em 129 Tools são 100 mil linhas de código que ninguém escreveu aqui.
O que se colhe é **método**, e o que este documento entrega de mais útil não são as
bibliotecas — são **seis defeitos do repositório atual** que só ficaram visíveis ao ler
como outra gente resolveu o mesmo problema.

---

## O quadro

| Repositório | Eixo | Licença | Último commit | Tamanho | Veredito |
|---|---|---|---|---|---|
| [Fraktality/spr](https://github.com/Fraktality/spr) | animação | **MIT** | 2024-07-30 | 838 | ✅ **adotar o método** |
| [Pyseph/ObjectCache](https://github.com/Pyseph/ObjectCache) | VFX | **MIT** | 2025-03-19 | 173 | ✅ **adotar o método** |
| [Roblox EventSequencer](https://create.roblox.com/docs/resources/modules/event-sequencer) | cutscene | Roblox | vivo | — | ✅ **adotar duas ideias** |
| [Hasnain123Raza/ROBLOX-Audio-Manager](https://github.com/Hasnain123Raza/ROBLOX-Audio-Manager) | SFX | ⚠️ **nenhuma** | 2020-07-21 | 231 | ⚠️ **ideia sim, código não** |
| [timoursfoil/Easy-Roblox-Cutscenes](https://github.com/timoursfoil/Easy-Roblox-Cutscenes) | cutscene | **MIT** | 2025-06-03 | 273 | ⚠️ **uma ideia; o resto é contraexemplo** |
| [RAMPAGELLC/RBLXKeyframePlayer](https://github.com/RAMPAGELLC/RBLXKeyframePlayer) | animação | **MIT** | 2024-11-04 | 621 | ⚠️ **a estrada não tomada** |
| [Khaomi/Animator](https://github.com/Khaomi/Animator) | animação | **MIT** | 2023-01-01 | 1 448 | ⚠️ idem, e ele **admite** o problema |
| [rbxrootx/Spark](https://github.com/rbxrootx/Spark) | VFX | ⚠️ **nenhuma** | 2025-03-06 | 93 | ⚠️ **ideia sim; o código não roda** |
| [TARNATlON/roblox-vfx](https://github.com/TARNATlON/roblox-vfx) | VFX | **MIT** | 2020-08-07 | 901 | ❌ **incompatível** (troca o motor) |
| [datlass/fabrik-ik-motor6d](https://github.com/datlass/fabrik-ik-motor6d) | animação | **MIT** | 2020-11-12 | 2 973 | ❌ **incompatível** (`InsertService`) |
| [janisfox/cutsceneModule_seraphicLabs](https://github.com/janisfox/cutsceneModule_seraphicLabs) | cutscene | nenhuma | 2025-07-21 | **0** | ❌ **não há código** |

Os três da triagem anterior — `vfx-editor`, `Lumina`, `grims-cutscene-engine` — continuam
em `FERRAMENTAS/TRIAGEM_FERRAMENTAS_EXTERNAS.md` e não são reavaliados aqui.

---

# PARTE I — o que a leitura revelou sobre ESTE repositório

Esta parte vem primeiro de propósito. As bibliotecas são interessantes; os defeitos são
acionáveis, e todos foram **medidos**, não supostos.

## 1. ⛔ As 129 Tools tocam UMA amostra por ação, e há 76 variantes paradas na gaveta

**Medido.** Nenhum Server do repositório sorteia som:

```
Servers com math.random perto de tocar():   0
assinatura de tocar():                      tocar(nome, pitch, corte)  — nome EXATO
```

E os modelos de entrada estão cheios de variação que nunca foi importada:

| Modelo de entrada | Grupo | Variantes |
|---|---|---|
| `DANILO_TOOLS_ESCUDOS_V4` | `block` | **22** |
| `DANILO_TOOLS` | `block` | 16 |
| `swordfs` | `Lightning` | 7 |
| `reality_tools` | `Hit` · `Swing` · `M` · `Death` | 6 · 5 · 5 · 4 |
| `calebe_tools` / `Gravidade_7_Tools` | `Launch` | 5 |
| `guest_tools` | `Swoosh` | 2 |

**São pelo menos 76 `Sound` de variação nos modelos, e o repositório usa um de cada grupo.**
Eu mesmo fiz isso ontem: no `preparar_reality_v2.py` importei `MetalHit` e ignorei
`MetalHit2`, importei `Swoosh` e `Swoosh2` mas os pus em papéis **diferentes** (`GIRO` e
`QUICA`) em vez de tratá-los como o que são — duas gravações da mesma coisa.

O `ROBLOX-Audio-Manager` resolve isso em nove linhas, com **peso**:

```lua
local randomNumber = Random.new():NextNumber(0, sumOfWeights)
for _, sound in pairs(group) do
    local weight = self:GetSoundWeight(sound)      -- NumberValue "Weight", ou 1
    if (randomNumber < weight) then return sound end
    randomNumber = randomNumber - weight
end
```

O peso não é firula: ele deixa o som "bom" sair 3× mais que o som "esquisito" sem apagar o
esquisito. Quem escuta um golpe cem vezes por partida ouve a repetição antes de ouvir
qualquer outra coisa — é a reclamação nº 1 de áudio em jogo de porrada, e o conserto aqui
não custa asset nenhum novo, porque **as gravações já estão nos modelos**.

> **Proposta:** `tocar(nome, ...)` passa a aceitar um nome de GRUPO. Se `Tool/SFX/TAPA` for
> uma `Folder` em vez de um `Sound`, ele sorteia entre os filhos, com peso. Um `Sound`
> avulso continua funcionando igual — a mudança é retrocompatível com as 129.
>
> `math.random` é permitido pelas regras novas. **E o sorteio tem de ser no SERVIDOR** —
> se cada cliente sortear, duas pessoas ouvem sons diferentes para o mesmo golpe.
>
> **Correção do que eu escrevi acima na primeira versão deste documento:** eu disse que o
> nome escolhido precisaria viajar no payload. **Não precisa.** O `tocar()` daqui clona o
> `Sound` e o parenteia no `Handle` *pelo servidor* — a INSTÂNCIA replica, e todo mundo
> ouve exatamente aquela. O sorteio no servidor já basta, e a implementação ficou mais
> simples do que a proposta.

> **IMPLEMENTADO** em 2026-08-29, nos 17 geradores. `Tool/SFX/TAPA` ou `Handle/TAPA` pode
> ser um `Sound` (como sempre) ou uma `Folder` com vários; `Folder` sorteia com peso.
> Retrocompatível: nenhuma das 129 Tools mudou de comportamento, porque todas ainda têm
> `Sound` avulso. O que mudou é que agora **dá para** aproveitar as 76 variantes.

## 2. ⛔ `LockCharacter` zera `JumpPower` e não zera `JumpHeight`

**Medido.** O `R6CFrameAnimator` canônico, em 129 Tools:

```lua
self.SavedJump = hum.JumpPower
hum.JumpPower  = 0            -- e nada sobre JumpHeight
```

`Humanoid` tem **dois** modos de pulo, e quem manda é `UseJumpPower`. Em place criado com
os padrões recentes do Studio ele vem **falso**, e aí quem governa é `JumpHeight` — que
este código não toca. **O jogador pula no meio da cutscene.**

Não é hipótese distante: 27 arquivos do repositório já mencionam `UseJumpPower` e 16 já
mexem em `JumpHeight` (o conjunto TEMPO trata os três, porque lá o congelamento é a
habilidade). O animator compartilhado ficou para trás.

O `Easy-Roblox-Cutscenes` usa o caminho certo, e é uma linha:

```lua
local playerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
local controls = playerModule:GetControls()
controls:Disable()   -- mata andar, pular, e o joystick do celular, de uma vez
```

> **Proposta:** `LockCharacter` guarda e zera **`JumpHeight` também**. E o `Client` chama
> `controls:Disable()`/`:Enable()` nas Tools com cutscene — é o único jeito de o polegar do
> celular parar de andar por baixo do cinema. `PlayerModule` é do próprio jogador, não é
> depósito de asset: mesma categoria de `Players.LocalPlayer`.

## 3. 2 243 `Instance.new("Part")`, e zero `BulkMoveTo`

**Medido:** 2 243 chamadas de `novaParte(` nos 33 `VFXModule`, e **nenhuma** ocorrência de
`workspace:BulkMoveTo` no repositório.

O `ObjectCache` mostra o porquê de isso importar:

```lua
workspace:BulkMoveTo(MovingParts, MovingCFrames, Enum.BulkMoveMode.FireCFrameChanged)
```

Uma chamada ao motor para N peças, em vez de N escritas de propriedade. E o resto do
desenho dele é igualmente barato:

- **`FAR_AWAY_CFRAME = CFrame.new(2^24, 2^24, 2^24)`** — peça "morta" é MOVIDA para longe,
  não destruída nem reparentada. Reparent custa; mover não.
- **lote adiado**: `task.defer` com uma trava `ScheduledUpdate`, então N pedidos no mesmo
  quadro viram UM flush.

> **Proposta:** o `camadaDestroco` (16 cacos por estouro, com dois tweens cada) é o
> candidato óbvio. Ele é o mais caro do repositório e o mais fácil de converter, porque os
> cacos já são cosméticos e ancorados. **Não proponho o cache inteiro** — pool de peça
> dentro de uma Tool esbarra na regra nº 1, já que o pool teria de viver em algum lugar; o
> `BulkMoveTo` sozinho não tem esse problema.

## 4. O beat só cai em borda de passo; o `when` normalizado cai onde quiser

Hoje o beat é uma `marca` numa etapa do `Poses.lua`, e etapa tem duração própria. Um som
que deveria tocar **no meio** de um passo de 0.9 s não tem onde ser escrito — vira um passo
extra só para ter onde pendurar a marca.

O `Easy-Roblox-Cutscenes` agenda por **fração**:

```lua
task.delay(duration * anim.when, function() ... end)   -- when ∈ [0,1]
```

Mudou a duração do plano? Os beats andam junto, sozinhos. E o EventSequencer da Roblox vai
além, ancorando no **áudio**:

```lua
SyncToAudio = { Audio = audioRef, StartAtAudioTime = 2.5, EndAtAudioTime = 10 }
```

Isso é uma inversão que vale dizer em voz alta: **hoje o SFX é escravo da animação; ali a
animação é escrava do som.** Áudio não perde quadro; animação perde. Onde existe uma fala
ou um pulso musical, quem deve mandar no relógio é o som.

## 5. O emissor devia carregar o próprio tempo

Hoje `acender(peca, fator)` multiplica o `Rate` do autor por um número escrito no Server. O
`Spark` põe o tempo em **atributos da própria instância**:

```lua
local Count    = Emitter:GetAttribute("EmitCount")    or 1
local DelayTime= Emitter:GetAttribute("EmitDelay")    or 0
local Duration = Emitter:GetAttribute("EmitDuration") or 0
```

Quem faz o efeito ajusta no painel de propriedades, e o Server não precisa saber o nome de
nada. É a mesma separação que o `Poses.lua` já tem entre dado e executor — só que aplicada
ao VFX, onde hoje o número mora no lugar errado.

E os atributos **viajam com a instância**, o que quer dizer que atravessam o depósito da
regra nº 2 sem nenhum trabalho extra.

## 6. Todo efeito do repositório desenha igual a 5 e a 500 studs

O `roblox-vfx` corta partícula por distância de câmera:

```lua
local Distance = (Camera.CFrame.Position - position).Magnitude
if Distance > Constants.RENDER_DISTANCE_START then
    amount = amount / (Distance / 20)
end
```

Meus módulos têm teto (`LIMITE_VIVOS = 260`) mas o teto é **por módulo**: 33 módulos × 260
= 8 580 peças possíveis, e todas desenhadas com a mesma densidade esteja o efeito no seu
rosto ou do outro lado do mapa. Numa briga de sete pessoas com Tools diferentes, é isso que
derruba o quadro — e o jogador nem está olhando para a maioria delas.

---

# PARTE II — as bibliotecas, uma a uma

## ✅ `spr` — a mola ANALÍTICA (MIT)

O achado técnico mais bonito da leva. `spr` resolve a EDO do oscilador harmônico amortecido
em **forma fechada**, com três casos:

```
f²·(X[t] − g) + 2·d·f·X′[t] + X″[t] = 0
```

`d == 1` (crítico), `d < 1` (subamortecido), `d > 1` (superamortecido). E a solução é
avaliada **direto no `dt`** — não é integração passo a passo.

**Por que isso importa aqui:** integração ingênua (`v += -k*x*dt`) *explode* quando o `dt`
cresce. Um pico de lag de 200 ms e a mola arremessa o objeto para o infinito. A forma
fechada é estável em qualquer `dt`, porque ela não simula: ela calcula onde a mola estaria.

Duas outras coisas que ele faz e o repositório não:

- **`canSleep`** — a mola para de ser atualizada quando está perto o bastante *e* devagar o
  bastante (`SLEEP_OFFSET_SQ_LIMIT`, `SLEEP_VELOCITY_SQ_LIMIT`). Meus laços de `Heartbeat`
  rodam até o prazo vencer, mesmo quando não há mais nada a mover.
- **expansão de Maclaurin** para evitar divisão por `c ≈ 0` quando o amortecimento tende a
  1. É cuidado numérico de quem já viu o `NaN` acontecer.

> **Veredito:** ✅ adotar o **método** — o caso crítico (`d == 1`) cabe em ~12 linhas e é o
> que se quer em 90% dos casos. Não copiar as 838: elas cobrem sete tipos de dado
> (`UDim2`, `Color3`, `CFrame`…) que nenhuma Tool usa em mola.

## ✅ `ObjectCache` — `BulkMoveTo`, e o estacionamento longe (MIT)

Coberto na Parte I §3. 173 linhas, `--!native`, escrito com cuidado. O que **não** vem
junto: o cache em si, porque um pool tem de morar em algum lugar e "algum lugar" é fora da
Tool.

## ✅ EventSequencer (Roblox oficial) — `SyncToAudio` e `seek`

Não é do GitHub, é módulo oficial, e as duas ideias que valem estão na Parte I §4. Uma
terceira merece nota: **`seek(time)`** — poder pular para o segundo 8 da cutscene ao testar.
Toda cutscene deste repositório só pode ser vista do começo, e isso torna caro ajustar o
último beat de uma cena de 12 s.

O modelo de dados dele é declarativo e legível:

```lua
Schema:audio   { StartTime = 1,  SoundId = "...", OnStart = fn, OnEnd = fn }
Schema:tween   { StartTimes = {5, 10}, Tween = { Object = o, Info = i, Properties = p } }
Schema:schedule{ StartTimes = {5, 27.25}, OnStart = fn, Skippable = false }
```

`Skippable` é uma coluna que a `CutsceneCam` daqui não tem.

## ⚠️ `ROBLOX-Audio-Manager` — a ideia certa, sem licença

O grupo de variação com peso (Parte I §1) e o id por caminho:

```lua
for match in string.gmatch(Id, "/?([^/]+)/?") do assetDictionary = assetDictionary[match] end
--  PlaySoundEffect("Combat/Impact/Metal")
```

Também converge com o repositório num ponto que vale registrar: o `PlaySoundEffectAtPosition`
dele cria uma `Part` ancorada só para segurar o `Sound` — que é exatamente o que o
`tocarEm()` daqui faz, e pelo mesmo motivo (som só toca enquanto tem pai no DataModel).
Duas pessoas chegando à mesma solução em separado é bom sinal.

**Não copiar:** sem arquivo de licença — o código é "todos os direitos reservados" por
omissão. Além disso usa `wait()`, `tick()`, `Instance.new("Folder", workspace)` (a forma de
dois argumentos, obsoleta) e escreve pastas em `workspace` e `SoundService` na hora do
`require`.

## ⚠️ `Easy-Roblox-Cutscenes` — uma ideia boa, e um contraexemplo caro

O `when` normalizado e o `controls:Disable()` valem (Parte I §2 e §4). O resto é um
catálogo do que a `REGRA_CAMERA_DE_CUTSCENE` daqui existe para impedir:

```lua
local function playNextTween()
    local currentPart = parts[index]
    if not currentPart then
        Camera.CameraType = Enum.CameraType.Custom   -- ⛔ ÚNICO caminho de volta
        controls:Enable()
        return
    end
    ...
    tween.Completed:Connect(function()  ...  playNextTween() end)   -- ⛔ nunca desconecta
end
```

**A câmera só é devolvida quando a cutscene termina bem.** Morreu no meio, deu reset,
errou um `FindFirstChild` — a câmera fica `Scriptable` e os controles desligados **para
sempre**. Não há tecla que resolva isso do lado do jogador; ele precisa sair do servidor.

É por isso que a regra daqui diz "quem escreve `CameraType` liga `Tool.Unequipped` **e**
`Tool.Destroying`". Ler este arquivo é ver o bug que a regra descreve, escrito por extenso.

Além disso: `tween.Completed:Connect` dentro da função recursiva **vaza uma conexão por
plano**, e `humanoid:LoadAnimation` é obsoleto (o certo é `humanoid.Animator:LoadAnimation`).

## ⚠️ `RBLXKeyframePlayer` e `Khaomi/Animator` — a estrada não tomada, e por que não

Estes dois merecem a seção mais longa, porque atacam **exatamente** o problema que fez o
`R6CFrameAnimator` existir: animar sem subir um `Animation` para a Roblox.

A solução deles é ler um `KeyframeSequence` — que **pode ser feito no Animation Editor e
salvo no place, sem upload** — e escrever nas juntas:

```lua
motorOrBone.Transform = pose.CFrame       -- KeyframePlayer, linha 307
```

**`Motor6D.Transform` é o canal sancionado.** É onde o `Animator` da própria Roblox escreve,
todo quadro, e é **separado do `C0`**. A proibição daqui — "zero escrita em `Motor6D.C0`" —
continua certíssima, mas ela nunca foi sobre `Transform`.

E o `Khaomi/Animator` resolve a briga com o script padrão do jeito certo, guardando e
devolvendo:

```lua
local AnimateScript = self.Character:FindFirstChild("Animate")
if AnimateScript then AnimateScript.Disabled = true end
...
if AnimateScript and AnimateScript.Disabled then AnimateScript.Disabled = false end
```

**Então por que não migrar?** Porque o próprio autor escreve, no README:

> *"This doesn't replicate out of the box, You will need a re-animate script"*

`Motor6D.Transform` **não replica**. Escrito no cliente, só aquele cliente vê; escrito no
servidor todo quadro, é exatamente a proibição "servidor não move geometria por frame", com
outra roupa. O `Weld` que o `R6CFrameAnimator` cria replica porque `C0` de um `Weld` criado
no servidor é propriedade replicada como qualquer outra.

> **Veredito:** ⚠️ **a arquitetura daqui está certa, e esta leitura é a evidência disso** —
> não o contrário. Fica registrado por dois motivos: (a) para ninguém "descobrir"
> `Transform` daqui a seis meses e refazer o caminho, e (b) porque **o repositório descartou
> `KeyframeSequence` de modelos de entrada** por não ter como tocá-los — o `a-train` trazia
> 40 keyframes e o `kick dance`, 361. Se um dia entrar um leitor de `KeyframeSequence`, ele
> deve **converter para a tabela de poses** na etapa de preparação (offline, em Python),
> não tocar keyframe em runtime.

## ⚠️ `Spark` — a ideia dos atributos, e um código que não roda

A ideia está na Parte I §5. O código tem três problemas, e o primeiro é fatal:

```lua
Emitter._CancelEmission = false          -- ⛔ ParticleEmitter não aceita campo arbitrário
```

Não se pode escrever um campo qualquer numa `Instance` do Roblox. Esta linha **lança**
`_CancelEmission is not a valid member of ParticleEmitter`. Ou seja: `EmitFromEmitter` erra
na primeira linha útil, e `CancelEmission` nunca funcionou. Precisaria de `SetAttribute` ou
de uma tabela lateral.

Os outros dois: `tick()` (banido aqui), e —

```lua
task.wait(1 / Emitter.Rate)
```

— se `Rate` for `0`, isso é `task.wait(math.huge)`, que **pendura a thread para sempre**. E
`Rate = 0` é o valor normal de um emissor que só serve para `:Emit()`.

Sem licença, além de tudo.

## ❌ `roblox-vfx` — troca o motor de partículas inteiro

901 linhas que substituem o `ParticleEmitter` por partículas próprias com cache e atualização
manual. O LOD por distância vale (Parte I §6), mas adotar o resto significaria abandonar o
`ParticleEmitter` — e o pack do Acervo, os moldes dos modelos de entrada e o depósito da
regra nº 2 são todos feitos de emissor nativo. `wait()` 8×, `:Destroy()` 6×.

## ❌ `fabrik-ik-motor6d` — `InsertService` na linha 100

Solver FABRIK sério, 2 973 linhas, MIT. Morre na varredura de quarentena:

```lua
local InsertService = game:GetService("InsertService")
cone = InsertService:LoadAsset(assetId):WaitForChild("EnhancedCone")
```

Carregar asset de fora em runtime é a violação mais direta possível da regra nº 1 — e é a
mesma família do backdoor do `reality_tools`. Não é malicioso aqui (é um cone de debug de
restrição), mas o caminho é o mesmo e a regra não abre exceção por intenção.

## ❌ `cutsceneModule_seraphicLabs` — o repositório não tem código

Clonado: um `README.md`, e mais nada. **Zero linha de Lua.** A distribuição é por `.rbxm`
fora do Git. Nada a triar.

---

# O que este documento propõe

Nenhuma mudança foi feita. São propostas, em ordem de retorno pelo custo:

| # | Proposta | Onde | Custo |
|---|---|---|---|
| 1 | ✅ **FEITO** — `tocar()` aceita grupo de variação com peso | 17 geradores | — |
| 2 | ✅ **FEITO** — `LockCharacter` guarda e zera `JumpHeight` | animator, 129 Tools + o do Acervo | — |
| 3 | `controls:Disable()` nas Tools com cutscene | `Client` das Tools com `CutsceneCam` | baixo |
| 4 | `when` ∈ [0,1] no keyframe, além da `marca` | `Poses.lua` + despachante | médio |
| 5 | `BulkMoveTo` no `camadaDestroco` | um `VFXModule` de cada vez | baixo |
| 6 | Atributos `EmitCount`/`EmitDelay`/`EmitDuration` nos moldes | `acender()` | baixo |
| 7 | Corte de densidade por distância de câmera | `novaParte` / `registrar` | médio |
| 8 | Mola analítica como alternativa ao tween em `PlayTrack` | `R6CFrameAnimator` | alto |

A nº 2 é a mais barata e a mais grave: um arquivo, quatro linhas, e ela conserta um pulo no
meio da cutscene em todas as Tools que travam o personagem.

---

## O que NÃO foi verificado

Tudo aqui é leitura estática de código clonado. **Nada rodou no Studio**, nem o que eu
escrevi nem o que li.

Especificamente sem confirmação em jogo:

- Se `controls:Disable()` de fato cobre o joystick do celular **nas versões atuais** do
  `PlayerModule` — li a chamada no repositório de terceiro, não a implementação da Roblox.
- Se `Humanoid.UseJumpPower` vem falso por padrão no place DESTE projeto. A afirmação de que
  o pulo escapa vale **quando** ele é falso; o defeito de `LockCharacter` não tratar
  `JumpHeight` é certo de qualquer forma, mas o sintoma depende dessa configuração.
- Se o ganho de `BulkMoveTo` é perceptível na escala de 16 cacos. O ganho é documentado para
  milhares de peças; para dezenas, pode ser ruído.
- Se `Motor6D.Transform` realmente não replica no comportamento atual do motor — a evidência
  é o README do autor do `Khaomi/Animator` e a arquitetura do `Animator` nativo, não um
  teste meu.
- O `Spark` eu afirmo que **não roda** com base na regra de que `Instance` não aceita campo
  arbitrário. É uma regra firme do motor, mas eu não executei a linha.
