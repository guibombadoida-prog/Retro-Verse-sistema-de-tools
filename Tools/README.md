# Tools

**59 Tools, em oito conjuntos.**

## Conjunto BOMBAS — 6 Tools, de `bomba_v4.rbxmx`

Habilidade **única** em cada, no `Tool.Activated`. Nenhuma tem Extra — por isso
nenhuma tem `AcaoRemote` nem botão de toque: o ícone da Tool já é o botão.

| Tool | Habilidade | Entrega |
|---|---|---|
| `Multiplas Bombas` | 1 bomba → **3** mini bombas *(a do original)* | [`.rbxmx`](Multiplas%20Bombas/Multiplas%20Bombas.rbxmx) |
| `Bomba Nuclear` | nuke — cogumelo, clarão e **3 anéis** de dano expandindo | [`.rbxmx`](Bomba%20Nuclear/Bomba%20Nuclear.rbxmx) |
| `Bomba Meteorica` | meteoro na diagonal, **1 s** de queda com áudio, **10** mini para cima | [`.rbxmx`](Bomba%20Meteorica/Bomba%20Meteorica.rbxmx) |
| `Bomba Basquete` | quica **3** vezes e estoura | [`.rbxmx`](Bomba%20Basquete/Bomba%20Basquete.rbxmx) |
| `Bomba Doida` | **2** bombas-NPC R6 kamikaze; sem alvo, ficam bravas e aceleram | [`.rbxmx`](Bomba%20Doida/Bomba%20Doida.rbxmx) |
| `Bomba Gelada` | congela e deixa **chão de gelo** escorregadio | [`.rbxmx`](Bomba%20Gelada/Bomba%20Gelada.rbxmx) |

As 6 juntas: [`Bombas_6_Tools.rbxmx`](Bombas_6_Tools.rbxmx)

Números do original preservados: dano **20**, raio **20**, 3 mini a **20%** em
raio **15**, delay **1 s**, recarga **1 s**, explode ao tocar Humanoid ou por prazo.

O original fazia `require(8199013483)` — **id numérico é execução de código
remoto**, e não entra em Tool nenhuma. Ver
[`ACERVO_RETROVERSE/Bomba_V4/FICHA.md`](../ACERVO_RETROVERSE/Bomba_V4/FICHA.md).

---

## Conjunto ASTRAL — 5 Tools, de `astral_peria.rbxmx`

A primeira leva as habilidades **originais** do modelo; as outras quatro são
clones com **duas habilidades novas** cada, no mesmo tema.

| Tool | M1 | Tecla | Entrega |
|---|---|---|---|
| `Astral Periastron` | Golpe / investida que semeia orbes | **Q** redireciona · **E** detona · **X** Pulsar | [`.rbxmx`](Astral%20Periastron/Astral%20Periastron.rbxmx) |
| `Astral Nova` | Nova Estelar (cone, empurra) | **X** Colapso Anão | [`.rbxmx`](Astral%20Nova/Astral%20Nova.rbxmx) |
| `Astral Cometa` | Cometa (projétil com cauda) | **X** Chuva Sideral | [`.rbxmx`](Astral%20Cometa/Astral%20Cometa.rbxmx) |
| `Astral Singularidade` | Horizonte de Eventos (retarda e drena) | **X** Espaguetificação (cutscene) | [`.rbxmx`](Astral%20Singularidade/Astral%20Singularidade.rbxmx) |
| `Astral Constelacao` | Traço Sideral (marca o alvo) | **X** Sentença da Constelação | [`.rbxmx`](Astral%20Constelacao/Astral%20Constelacao.rbxmx) |

As 5 juntas: [`Astral_5_Tools.rbxmx`](Astral_5_Tools.rbxmx)

### Mobile: os botões são nativos

Entrada por `ContextActionService:BindAction(nome, fn, **true**, tecla, botão)`.
O terceiro argumento é `createTouchButton` — **o Roblox desenha o botão de toque
sozinho**, com o tamanho e a área de acerto que o jogador de celular espera. O
mesmo bind cobre teclado, controle e toque.

Não é `ScreenGui`: a do modelo original (`Astral_UI`, com os cooldowns de Q/E/X)
saiu porque a regra proíbe — efeito só no mundo 3D. `ContextActionService` já
está na lista de serviços que a Regra nº 1 permite, por ser serviço de
**comportamento**, que não traz asset de fora.

Quais botões cada Tool cria sai do `StringValue` **`Acoes`** dela:

| Tool | `Acoes` | Botões no celular |
|---|---|---|
| `Astral Periastron` | `Q:Redirecionar\|E:Detonar\|X:Pulsar` | 3 |
| as outras quatro | `X:<nome da extra>` | 1 |

Sem esse Value o Client criaria os três em toda Tool, e na Nova dois não fariam
nada — no celular, botão que não responde é pior que botão nenhum.

O **M1** não precisa de botão: `Tool.Activated` já dispara no toque do próprio
ícone da Tool, em qualquer plataforma.

Números do original preservados: golpe **27**, orbe **25** em raio **20**,
redirecionar CD **1 s** a **100** de velocidade, Pulsar CD **60 s** por **30 s**
em alcance **200** a **15** por pulso, ferindo o portador em **34**.

**Nenhuma das 4826 linhas do modelo entrou.** O código é autoral; o que veio
foram os números e a cadência. Ver
[`ACERVO_RETROVERSE/Astral_Peria/FICHA.md`](../ACERVO_RETROVERSE/Astral_Peria/FICHA.md)
para o passe §12.12.2 completo, o que foi resgatado de dentro dos scripts e o
que foi removido.

---

## Conjunto ESCUDOS — 7 Tools, da `DANILO_TOOLS_ESCUDOS_V4.rbxmx`

| Tool | Entrega |
|---|---|
| `Salvador` | [`Salvador.rbxmx`](Salvador/Salvador.rbxmx) |
| `Proteção` | [`Proteção.rbxmx`](Proteção/Proteção.rbxmx) |
| `Escudo Skate` | [`Escudo Skate.rbxmx`](Escudo%20Skate/Escudo%20Skate.rbxmx) |
| `Escudo Bumerangue` | [`Escudo Bumerangue.rbxmx`](Escudo%20Bumerangue/Escudo%20Bumerangue.rbxmx) |
| `Escudo Bloqueador` | [`Escudo Bloqueador.rbxmx`](Escudo%20Bloqueador/Escudo%20Bloqueador.rbxmx) |
| `Escudo Cyclone` | [`Escudo Cyclone.rbxmx`](Escudo%20Cyclone/Escudo%20Cyclone.rbxmx) |
| `Escudo Partido` | [`Escudo Partido.rbxmx`](Escudo%20Partido/Escudo%20Partido.rbxmx) |

As 7 juntas: [`Escudos_7_Tools.rbxmx`](Escudos_7_Tools.rbxmx)

---

## Conjunto GUEST — 7 Tools, de `guest_tools.rbxmx` + `guest_tools_2_more.rbxmx`

**Cinco remasterizadas** (o primeiro arquivo) e **duas que entraram depois** (o
segundo). Sete cai exato no teto da regra de distribuição: nenhuma se funde,
nenhuma vira Extra de outra.

Cada uma tem primária no clique e **uma Extra**, com botão de toque desenhado
pelo `ContextActionService` — celular e controle entram pelo mesmo caminho.

| Tool | M1 | Extra | Entrega |
|---|---|---|---|
| `Taco de Baseball` | dois golpes que revezam (16 / 22) | **R** Vibe Check — 55 em raio 11, tomba | [`.rbxmx`](Taco%20de%20Baseball/Taco%20de%20Baseball.rbxmx) |
| `Cano De Rua` | dois golpes; o segundo cobra mais (13 / 19) | **R** Concussão — 34 em raio 13 + lentidão 3.5 s | [`.rbxmx`](Cano%20De%20Rua/Cano%20De%20Rua.rbxmx) |
| `Abacate (roubado) do mexico` | come e cura **14** | **R** Caroço — arremesso, 12 de dano | [`.rbxmx`](Abacate%20%28roubado%29%20do%20mexico/Abacate%20%28roubado%29%20do%20mexico.rbxmx) |
| `Energetico` | bebe: cura **10** + `WalkSpeed` 26 por 6 s | **R** Lata — arremesso, 15 de dano | [`.rbxmx`](Energetico/Energetico.rbxmx) |
| `Humilhador` | provoca — **zero dano**, de propósito | **R** Roda — afrouxa a 60% em raio 22 | [`.rbxmx`](Humilhador/Humilhador.rbxmx) |
| `Diamond` | tapa que arremessa (18 + empurrão 78) | **E** Pedra — 4.5 s trancado, abre com 30 em raio 13 | [`.rbxmx`](Diamond/Diamond.rbxmx) |
| `A arma` | revólver, 6 tiros (24 · **46 na cabeça**) | **R** Recarregar | [`.rbxmx`](A%20arma/A%20arma.rbxmx) |

As 7 juntas: [`Guest_7_Tools.rbxmx`](Guest_7_Tools.rbxmx) · binário
[`Guest_7_Tools.rbxm`](Guest_7_Tools.rbxm)

### Os bugs que vieram nos originais, e o que foi feito

| Onde | O que era | O que ficou |
|---|---|---|
| `Diamond` | `tool:WaitForChild("AbilityActivateButton")` — **essa GUI não existe no modelo**. `WaitForChild` sem timeout trava para sempre: o CLIENT morria na linha 10 e a Tool inteira era inerte | botão pelo `ContextActionService` |
| `Diamond` | `require(ReplicatedFirst.Ragdoll)` — dependência de fora, e num place vazio a Tool erra na primeira ativação | `PlatformStand` com prazo, dentro da Tool |
| `Diamond` | `Touched` decidindo acerto no **cliente** | quem decide dano é o servidor |
| `Taco de Baseball` | soldava as duas pernas e zerava `WalkSpeed` no finalizador; o `Unequipped` soltava braço, cabeça e raiz e **não as pernas** — desequipar no meio deixava o personagem soldado e parado, sem volta | perna é do `R6CFrameAnimator`, sob demanda, com `ReleaseLegs` nas **duas** portas |
| `Taco de Baseball` | `isAlly()` decidindo aliado dentro da Tool | o Núcleo, sob guarda |
| `Cano De Rua` | `Health = Health - math.random(10,15)` | `TakeDamage`, que respeita `ForceField` |
| `Cano De Rua` | `Instance.new("ScreenGui")` na cara de quem apanhava — proibida, e só quem levou via | lentidão com prazo, legível para a sala |
| `Abacate` | `OpenSound` com `SoundId` **em branco**, e o `Equipped` chamando `:Play()` nele | id preenchido |
| `Humilhador` · `A arma` | chegaram **mudas** — a primeira criava o `Sound` no código, a segunda não tinha nenhum | `Sound` como instância dentro da Tool |
| `A arma` | **121 peças, nenhuma `Massless`** — todas penduradas no braço direito por Motor6D. O `Humanoid` carregava a massa das 121, e caminhada, pulo e o próprio equipar saíam do lugar | 120 peças `Massless`; só o `Handle` mantém massa |
| `A arma` | sem `Tool.Grip`. O original tinha `RequiresHandle = false` e soldava o modelo à mão pelo próprio LocalScript, que saiu — sem Grip o revólver é segurado pela origem local do Handle, atravessado na mão | `Grip` **derivado** do `barrelend` (ver abaixo) |
| todas | 47 `wait()` · 41 `math.random` · 12 `tick()` · 11 `spawn(` · 1 `delay(` · 2 `:Destroy()` | trocados |

### O `Grip` de `A arma` é derivado, não chutado

No espaço local do `Handle`, o `barrelend` está em **(-1.679, 0.000, 1.607)** — a 2.325
studs, e com **y exatamente zero**, o que quer dizer que o cano vive no plano XZ do Handle e
um *yaw* puro basta para apontá-lo.

```
quero  Grip:Inverse() * v = (0, 0, -1)          o "para frente" da mão
logo   v = Grip * (0, 0, -1) = (-sen θ, 0, -cos θ)
de     v = (-0.722, 0, 0.691)   ->   sen θ = 0.722,  cos θ = -0.691
θ = 133.74°
```

⚠️ Isso acerta a **direção** do cano. O rolamento e o encaixe fino na palma **não dá para
medir daqui** — precisam de olho no Studio. A mecânica do tiro não depende disso: o Server
calcula o disparo do `barrelend` ao vivo, seja como for que a arma esteja sendo segurada.

### Os SFX são todos do próprio Guest

`Humilhador` e `A arma` chegaram mudas. Os quatro sons que a conversão acrescentou vêm
**do próprio `guest_tools.rbxmx`** — `Tiro` é o `MetalHit2` do Cano, `Tambor` é o `MetalHit`,
`Fecha` é o `Equip` do Taco, e `Provoca` é o id que o Humilhador criava no próprio código.
Uma primeira versão puxou três ids do Xester e foi corrigida: o conjunto tem de soar como ele
mesmo.

### O tempo das poses foge da tabela, e está declarado

A medição do próprio Guest está em
[`ACERVO_RETROVERSE/Guest_Tools/R6_CFRAME/NOTAS.md`](../ACERVO_RETROVERSE/Guest_Tools/R6_CFRAME/NOTAS.md):
o combo do `Cano De Rua` original sai em **0.317 s, proporção 42 : 58**.

A proporção **confirma** a regra 3 da gramática (combo bate cedo, 35 : 65) — e
vem de um autor que nunca viu a nossa tabela. A duração **contraria** a regra 1
(golpe rápido entre 0.8 s e 1.2 s).

A leitura registrada: a regra 1 foi medida em bake de anime, onde o golpe é
*encenado*; aqui é porrada de rua, onde ele é *responsivo*. Então o conjunto
fica em **0.50–0.62 s** — mais lento que o original, que não tinha um único
quadro segurado, e mais rápido que a tabela, porque a 0.8 s uma briga de rua
vira coreografia. Ultimate e transformação seguem a tabela sem desconto.

### Duas exceções de geometria, declaradas

| Tool | O quê | Por quê |
|---|---|---|
| `A arma` | o `Handle` **subiu de nível**, de `model/Handle` para filho direto | Tool com `RequiresHandle = true` exige Handle como filho direto — é exigência do Roblox. `Weld` e `Motor6D` apontam por `referent`, não por caminho, então nada se desfez |
| `Humilhador` | ganhou um `Handle` **invisível de 0.4 stud** | a origem não tem nenhum: é provocação pura, só um Script. Sem Handle a Tool não equipa. Não substitui mesh de ninguém — supre o que não existe |

---

## Conjunto GRAVIDADE — 7 Tools, de `calebe_tools.rbxmx`

**Cinco Handles, sete Tools.** O modelo traz 5; duas nascem CLONANDO o Handle de
uma irmã — o mesmo caminho do conjunto Astral. O que se clona é a **geometria**;
a habilidade de cada uma é escrita aqui.

| Tool | Handle vem de | M1 | Extra |
|---|---|---|---|
| `Tremores da Gravidade` | Quake Hammer | onda de tremor no chão (18, raio 22) | **R** Sustentar — 3 pulsos, tomba |
| `Controlador da Gravidade` | Gravitron 1000 | campo de **gravidade invertida** no ponto (raio 16, 3.5 s) | **R** Esmagar — 38, força 140 para baixo |
| `Telecinese Levitacao` | CosmosStaff | ergue **um** alvo e o deixa indefeso; a queda cobra +22 | **R** Levitar — você sobe 26 studs |
| `Lancador de Objetos` | detainer | agarra destroço e arremessa (26) | **R** Rajada — 5 destroços em ângulo áureo |
| `Asas Telecineticas` | CosmosStaff **(clone)** | bate as asas: sobe e empurra (12, raio 14) | **R** Mergulho — 42 em raio 17 |
| `Terremoto` | Quake Hammer **(clone)** | rachadura que **corre** 6 passos à frente | **R** Colapso — ultimate, 78 em raio 44 |
| `Telecinese Gravitacional` | GravityHammer | puxa todos **para** o ponto (raio 30) | **R** Singularidade — junta e estoura, 30+55 |

As 7 juntas: [`Gravidade_7_Tools.rbxm`](Gravidade_7_Tools.rbxm) · XML
[`Gravidade_7_Tools.rbxmx`](Gravidade_7_Tools.rbxmx)

### A regra que manda neste conjunto: ninguém toca em `workspace.Gravity`

O `Gravitron 1000` original ciclava `workspace.Gravity` entre 21.2, 471.2 e
196.2. O `Unequipped` dele parava dois sons, apagava um rótulo — e **não
devolvia a gravidade**. Não havia `Tool.Destroying`.

**Equipar, clicar uma vez e guardar deixava o servidor inteiro em gravidade 21.2
para sempre.** É a família de "câmera presa", e pior de escala: câmera presa
incomoda um jogador, gravidade presa quebra o mapa para todos.

Aqui o efeito é sempre **por alvo**: `BodyVelocity` e `BodyPosition` com prazo no
`Debris`, num `HumanoidRootPart` por vez — e o `Debris` limpa mesmo se o script
morrer no meio. Não existe estado global para vazar.

`TESTES/verificar_autocontencao.sh` passou a cobrar isso por nome
(`✓ sem escrever workspace.Gravity`). **Ler** continua permitido; o que ele barra
é a atribuição.

### O que mais saiu dos originais

| Onde | O que era | O que ficou |
|---|---|---|
| `GravityHammer` | `IsTeamMate` decidindo aliado dentro da Tool | o Núcleo, sob guarda |
| `Gravitron`, `Quake` | **5 `ScreenGui`** dentro das Tools | `ContextActionService`, que some no `Unbind` |
| `Gravitron` | UI clonada no `PlayerGui` de **todos** — e o clone era **um só**, reparentado num laço, então só o último da lista recebia | beat de VFX no mundo 3D, que todos veem |
| `Quake Hammer` | `workspace:GetDescendants()` para achar alvo | consulta espacial num raio |
| `detainer` | agarrava geometria **do mapa** | destroço criado pela Tool — o mapa não fica com buraco |
| `GravityHammer` | `BreakJoints` | destruição permanente não é dano |
| todas | 6 `Animation` + 4 `LoadAnimation` | pose CFrame sob `R6CFrameAnimator` |
| todas | 35 `wait()` · 18 `math.random` · 9 `:Destroy()` · 5 `spawn(` | trocados |
| `CosmosStaff` | 3 `SoundId` com **espaço no fim** (`...48577295 `) | `strip()` no preparador — espaço em URL não dá erro, o som só não toca |
| `CosmosStaff`, `GravityHammer` | 6 ids no formato antigo `http://www.roblox.com/asset/?id=` | normalizados para `rbxassetid://` |

**A favor da origem:** as cinco já usavam `TakeDamage` (8 chamadas), nenhuma
mexia em `Health` na mão. Isso ficou.

### O tempo das poses segue a tabela, e aqui não há desconto

Ao contrário do conjunto GUEST, aqui a `GRAMATICA_R6.md` vale quase inteira — e
o motivo é o oposto: **telecinese não é golpe de troca.** Ninguém revida uma
levitação em 0.3 s. É conjuração, que é o caso que a regra 1 mede bem.

| Natureza | Duração | Onde |
|---|---|---|
| conjuração rápida | 0.90 s | Tremor, Inverte, Subir, Arremesso, Batida |
| conjuração pesada | 1.20 s | Esmagar, Rajada, Mergulho, Rachadura, Puxão |
| sustentada | 1.60 s | Sustento, Erguer, Singularidade |
| **ultimate** | **7.20 s** | `Terremoto` / Colapso — 71% de preparação |

O `COLAPSO` é a única sequência do conjunto com **beat de câmera**, e é a própria
regra 5 que exige: ultimate longo sem enquadramento vira tempo morto. O beat
viaja pelo `VFXRemote` como qualquer outro — servidor não toca em `Camera`.

Seis das sete lideram por `RightArm` (telecinese é gesto de mão). As duas
exceções são declaradas no gerador: `Terremoto` e `Asas Telecineticas` lideram
por **HRP**, porque num caso o golpe é o corpo caindo e no outro quem bate asa é
o tronco.

### O vocabulário de pose é compartilhado, e isso é de propósito

As sete dividem as mesmas poses de base — `ABRE_MAO`, `SUSTENTA`, `FECHA`,
`PUXA`, `ESMAGA`, `ERGUE`, `BATE_CHAO`. Sete Tools do mesmo tema têm de **ler
como o mesmo poder**; o que muda entre elas é o que vem depois do gesto, e o
tempo de cada passo.

---

## Conjunto DRAMA — 7 Tools, de `drama.rbxmx`

**Três Tools de origem, e só uma com Handle.** O `Fists` tem 21 instâncias e
nenhum Handle; o `dodge` tem duas — um Script e mais nada. Só o `UpperSword` traz
geometria. As de punho e de olho ganham **Handle invisível de 0.4 stud**, que não
substitui mesh de ninguém: supre o que a origem não tem.

| Tool | Handle vem de | M1 | Extra |
|---|---|---|---|
| `Combate` | Fists (invisível) | combo de **três** (12 / 12 / 22) | **R** Chute Rodado — 32 em raio 10, tomba |
| `Desviar e Empurrar` | dodge (invisível) | empurrão em cone (9, empurra 92) | **R** Esquiva — recua 34 com `ForceField` de 0.42 s |
| `Corte Frio` | UpperSword | corte de lâmina (26) | **R** Execução — 85 · **CUTSCENE** |
| `Impacto Forte` | Fists **(clone)** | soco pesado (40 + arremesso 96) | **R** Rachar o Chão — 52 em raio 20 |
| `Aura` | dodge **(clone)** | liga a aura: `WalkSpeed` 26 e 4 pulsos de 7 | **R** Pulso — 34, ou **54 e apaga a aura** |
| `Olhos Laser` | Fists **(clone)** | feixe pelos olhos (22, alcance 220) | **R** Varredura — leque de **7** feixes |
| `TryHard` | UpperSword **(clone)** | combo de **quatro** (11 / 13 / 16 / 30) | **R** Finalizador — 130 · **CUTSCENE** |

As 7 juntas: [`Drama_7_Tools.rbxm`](Drama_7_Tools.rbxm) · XML
[`Drama_7_Tools.rbxmx`](Drama_7_Tools.rbxmx)

### A cutscene finalmente enquadra POR ESPECTADOR

A regra 2 da [`GRAMATICA_CUTSCENE.md`](../ACERVO_RETROVERSE/_AUTORAL_RetroVerse/CAMERA/GRAMATICA_CUTSCENE.md)
foi escrita a partir do YorrSlayer e **nunca tinha sido implementada aqui**:

```
quem invoca  ->  vê o golpe de fora, com o alvo no quadro
quem é alvo  ->  vê a SI MESMO sendo alcançado
```

O motivo de nunca ter saído do papel é simples: a `CutsceneCam` era `LocalScript`,
e LocalScript dentro de Tool **só roda para quem a segura**. O alvo nunca
executava o arquivo, então a metade da cena que era dele não existia.

Aqui ela é `Script` com `RunContext = Client`, e o servidor manda **um
`FireClient` por espectador** com o papel de cada um no payload. Só o portador e
o alvo entram na cena — quem está do outro lado do mapa não perde a câmera por
causa de briga alheia.

As outras cinco regras também estão implementadas: FOV como técnica principal
(44 → 96 no `Corte Frio`, 40 → 104 no `TryHard`), aproximação **exponencial**
`k = 1 - math.exp(-3.2 * dt)`, estágio por tempo dentro do `RenderStepped`,
tremor com envelope nas frequências 24 e 41, e pular segurando **E** por 1.5 s —
só visual, o servidor segue no tempo dele.

**Seis portas devolvem a câmera:** `Unequipped`, `Destroying`,
`CharacterRemoving`, `Died`, prazo estourado e o pulo. A de prazo existe porque o
servidor pode morrer no meio da cena e nunca mandar o `FIM`.

### O que saiu do `drama.rbxmx`

| Onde | O que era | O que ficou |
|---|---|---|
| `Fists` | 2078 linhas com **um único `TakeDamage`**, contra 9 `Health = Health - x` e 4 `BreakJoints` | `TakeDamage` pelo Núcleo; `PlatformStand` com prazo no lugar do `BreakJoints` |
| `dodge` | dois `workspace.DescendantAdded`/`Removing` **globais**, mantendo uma tabela de todo `Humanoid` do jogo, ligados para sempre | `detectarHumanoides`, que é consulta espacial sob demanda |
| todas | **31 `tick()`** — `tick()` alimentando geometria foi o que picotou a animação das bombas | `os.clock()` para recarga, acumulador `dt` para animação |
| `Fists`, `UpperSword` | 2 `ScreenGui` (`fistgui` com as barras de combo, `FlashScreen`) | `ContextActionService`, e o combo é estado do Server |
| `UpperSword` | 5 `Animation` com `LoadAnimation` | pose CFrame sob `R6CFrameAnimator` |
| `UpperSword` | um `Sound` chamado literalmente `Sound`, repetido 4 vezes no mesmo pai | 4 papéis com nome de papel — `FindFirstChild` com nome repetido devolve o primeiro que achar |
| todas | 39 `math.random` · 18 `:Destroy()` · 9 `wait()` · 3 `delay()` · 3 `workspace:GetDescendants()` | trocados |

### O que veio da origem, e é dela

O `dhtime = 0.65` do `dodge` — a duração da esquiva, medida pelo autor original
(Rufus14, o mesmo de `A arma`). É o único número do conjunto abaixo da faixa da
regra 1, e está declarado: **esquiva lenta não é esquiva.**

E os quatro sons, todos do próprio modelo: `powerup`, o `Sound` do `SlashPart`, e
os dois `rbxasset://sounds/` — que são conteúdo do **cliente Roblox**, mais
"dentro" que qualquer id de catálogo. O verificador foi ensinado a aceitar essa
forma por causa deles.

⚠️ A paleta sonora é **fina**: quatro timbres para sete Tools. Está declarado
para não parecer descuido.

### O tempo das poses segue a tabela ao pé da letra

A gramática foi medida em soco, empurrão, uppercut e combo do Saitama — que é
exatamente o repertório deste conjunto. Aqui não há desconto a pedir:

| Regra | O que diz | Onde |
|---|---|---|
| 1 | golpe rápido entre 0.8 s e 1.2 s | `SOCO_A/B/C`, `CORTE`, `SOCO` |
| 2 | o impacto cai na **metade** | os mesmos, ~50% |
| 3 | combo inverte para **35 : 65** | `COMBO_1..4` do TryHard |
| 5 | ultimate 7–9 s com 64–86% de preparação | `FINALIZADOR`, 7.60 s e 76% |
| 7 | estas animações são, em maioria, **paradas** | quadro segurado em todas |

A ressalva que o conjunto GUEST levantou — golpe de rua vive em 0.3–0.6 s — **não
vale aqui**, e é decisão declarada: `Combate` e `TryHard` são briga **encenada**,
com combo e finalizador, que é o caso que o Saitama mede.

`Olhos Laser` lidera por **`Head`** — a única junta líder que a gramática não
prevê. Está aqui porque a alternativa era pior: um feixe que sai dos olhos
conduzido pelo braço lê como se a mão estivesse atirando.

---

## O que foi tocado, e o que não foi

**Uma única coisa mudou em relação ao arquivo que você enviou: o `Source` do `VFXModule`.**

| | |
|---|---|
| Handle, `SpecialMesh`, Model | **intactos, da origem** |
| `Sound` (79), `StringValue` (14), `NumberValue` (14), `RemoteEvent` (14) | **intactos, da origem** |
| `Poses`, `R6CFrameAnimator`, `Client`, os 7 `_Server_V*` | **intactos, da origem** |
| `VFXModule` | ponte nova para o pack, **mais os 10 efeitos como filhos** |

Conferido contra `MODELOS_ENTRADA/Danilo_Escudos_V4/DANILO_TOOLS_ESCUDOS_V4.rbxmx`:
censo de classes idêntico, `SpecialMesh` iguais propriedade a propriedade.

## Por que existe o `clonar_tool.py`

A leva anterior foi feita **reescrevendo** as Tools do zero. O resultado passava em todo
verificador e ainda assim entregava outra coisa, porque o Handle era remontado com
primitivas em vez de clonado com o `SpecialMesh` do modelo.

`FERRAMENTAS/montar_rbxmx.py` **constrói** Tool autoral, nascida aqui.
`FERRAMENTAS/clonar_tool.py` **clona** Tool que chega pronta — e nele o `.rbxmx` de origem
é a verdade: a única coisa que ele escreve de volta é o `Source` dos scripts.

```bash
python3 FERRAMENTAS/clonar_tool.py extrair <origem.rbxmx>          # .rbxmx -> .lua
python3 FERRAMENTAS/clonar_tool.py montar  <origem.rbxmx> <saída>  # .lua -> .rbxmx
```

A arquitetura agora codifica "não mexa no Handle" — não é mais uma promessa.

---

## O VFX — dentro da Tool

Cada `VFXModule` roda **primeiro** o efeito próprio da Tool, inteiro, e **depois** sobrepõe o
reforço do pack, dentro de `pcall`.

Os 10 módulos do pack são **filhos do `VFXModule`**, em `VFXModule/Pack/`. Nada é lido de
`ReplicatedStorage`, de `ServerStorage` nem do Acervo — **a Regra nº 1 vale inteira, e o
teste do place vazio cobre o VFX junto com o resto.**

> **Isto começou errado.** Eu tinha posto o pack em `ReplicatedStorage` e chamado de "exceção
> declarada", com o argumento de que ele não cabia dentro da Tool. O argumento valia para o
> `MainModule` do pack — que se muda para lá sozinho e manda requerer por id — e eu
> generalizei do loader para o pack inteiro. Medido depois, nos 10 efeitos em uso:
> **zero `require`, zero `ReplicatedStorage`, zero dependência do Takeo.** Cabiam desde o
> começo. A exceção foi desfeita e a regra voltou ao texto original.

Os 10 passaram pelo passe §12.12.2 antes de entrar
(`python3 FERRAMENTAS/conformar_pack_vfx.py`): 9 `math.random` viraram ângulo áureo e jitter
senoidal, um `WaitForChild` por módulo virou acesso direto, e o
`workspace:FindFirstChild("Terrain")` do `Floor_Crack` virou `workspace.Terrain`.

A fonte é **uma só**, no Acervo (`ACERVO_RETROVERSE/Stella_VFX_Addon/VFX/`), copiada para
dentro das 7 Tools na montagem. `verificar_rbxmx.py` compara as 7 cópias contra ela — é o
que impede de derivarem em silêncio.

O reforço é **camada nova, não repetição**: o `IMPACTO` próprio faz flash, anel, linhas e
faíscas e nenhum disco — é o disco que o pack acrescenta, em 0.26 s, tempo diferente das
outras camadas de propósito (duas camadas com a mesma duração leem como borrão).

Para desligar tudo e voltar ao VFX próprio: `PACK.LIGADO = false`, no topo da ponte.

### O molde fica apagado; quem acende é o clone

Tool equipada vive em `workspace`, e aí **todo `BasePart` descendente dela renderiza** — os
11 moldes do pack apareceriam pendurados no personagem antes de qualquer habilidade rodar.

Duas saídas que **não** servem, e por quê:

| Tentativa | Por que falha |
|---|---|
| Deixar o molde transparente e pronto | todo módulo do pack faz tween de `Transparency` **até 1** como fade-out, e nenhum define a transparência inicial do clone — ela vem do molde. Molde apagado sem mais nada = efeito apagado |
| `Parent = nil` no módulo | roda no cliente **do dono**, no `require`. Os outros jogadores não rodam `LocalScript` da minha Tool — para eles o molde continuaria à mostra |

O que vale: o molde fica guardado **apagado** (`Transparency = 1`, emissor `Enabled = false`),
o que independe de qualquer script rodar, e todo `:Clone()` do pack passa por `_rv_clone`,
que restaura no **clone** os valores originais — tabelados por caminho dentro do módulo.

```lua
local function _rv_clone(molde)
	local copia = molde:Clone()
	_rv_acender(copia, _rv_caminho(molde))   -- devolve Transparency e Enabled
	return copia
end
```

`verificar_rbxmx.py` cobra isso: molde com `Transparency` diferente de 1 dentro de um
ModuleScript é erro, e a checagem foi testada contra molde sabotado de propósito.

---

## Achados que NÃO foram corrigidos

Estão aqui porque são reais, e ficaram de fora por estarem além do que foi autorizado
nesta leva — que era só o VFX. Nenhum deles foi tocado.

| Achado | Onde | O que custa |
|---|---|---|
| `ToolTip` vazio | as 7 Tools | a mochila mostra a Tool sem descrição nenhuma |
| Servidor move `Part` **ancorada** por frame | Bumerangue (`:442`, `:456`), Partido (`:383`, `:536`), Proteção (`:409`, `:440`), Salvador (`:423`) | `Part` ancorada movida por script de servidor replica a **~20 Hz sem interpolação** — é exatamente o "os vfx não estão fluidos" |

O segundo é o mesmo defeito de antes, e continua na V4. A correção é mandar **um beat
nomeado** pelo Remote e deixar o `LocalScript` desenhar a 60 Hz — o `verificar_autocontencao.sh`
já cobra isso, e é a única checagem vermelha da autocontenção hoje.

---

## Verificação

```bash
python3 TESTES/verificar_estrutura_rbxmx.py  # o envelope que o Studio exige
bash    TESTES/verificar_autocontencao.sh   # Regra nº 1, sem exceção
python3 TESTES/verificar_rbxmx.py           # as Tools entregues
python3 TESTES/verificar_poses.py           # poses × animator V2
lua5.4  TESTES/harness_NucleoCombate.lua    # pipeline de dano
```

Entre as checagens, cinco que só existem porque a coisa quebrou em jogo:

- `registrarAtaque` não é aplicador de dano (7 Tools saíram com **dano zero**)
- `Players:GetPlayers()` não enxerga NPC
- servidor não move geometria por frame (**replica a ~20 Hz**)
- sequência de pose inteiramente neutra é animação morta
- VFX transmitido que o `VFXModule` não implementa — `VFX.Executar` **volta calado**

## Instalação no place

1. As Tools → `StarterPack`. **Só isso.**
2. Opcional: `ServerScriptService/NucleoCombate.lua` → Script `NucleoCombate` em
   `ServerScriptService`, para os bônus de combate.

Não há passo de `ReplicatedStorage`. A Tool leva tudo dentro dela.
