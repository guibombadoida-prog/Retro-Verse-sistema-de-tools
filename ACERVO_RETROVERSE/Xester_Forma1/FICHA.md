# Modelo: Xester_Forma1

- **Autor original:** não declarado no material — o `Handler` traz `-- made by WRENCH#0104`, que é o autor do *wrapper* de FE, não necessariamente o do movelist. O cabeçalho do `un` diz que o script foi vazado (*"skidcentric leaked it"*)
- **Origem:** `Xester.rbxmx`, enviado pelo autor do projeto em 2026-08-07
- **Licença / permissão:** material de terceiro obtido e enviado pelo autor do
  projeto para conversão; uso interno no Retro-Verse. A procedência que o próprio
  material declara está registrada na triagem, no fim desta ficha.
- **Data de entrada:** 2026-08-07
- **Status: LIMPO** — passe §12.12.2 executado   (CRU | LIMPO | APROVADO)
- **Violações corrigidas:** todo script da origem foi removido, não convertido —
  `MainModule`, `replicator`, `Handler`, `Weld`, `ai`, `core`, `skullscript`.
  A lógica das habilidades foi reescrita do zero conforme as diretrizes.
  Também saíram: `Animation`, `ScreenGui`/`BillboardGui`, e os Sound padrão de
  personagem (`rbxasset://sounds/...`) cujo script disparador foi removido.
- **Excluído do acervo:** os scripts acima. O que entrou nas Tools foi ASSET —
  cartas, cajado, machado, malhas, sons e as poses R6 extraídas do CFrame.
- **Já usado em:** as 14 Tools do Xester (7 por forma)

> Os quatro campos de §12.12.3 estão preenchidos. Nenhum script da origem
> entrou nas Tools — a lógica é reescrita, e da origem vem asset e número.

Tool de origem no modelo: `(sem Tool na raiz)`

---

## Conteúdo depositado

| Pasta | O que tem |
|---|---|
| `VFX/NOTAS.md` | Emissores com os parâmetros de verdade |
| `SFX/ids.md` | Sons com id, volume, pitch e rolloff |
| `MALHAS/ids.md` | `MeshId` e `TextureId` |
| `LOGICA/HABILIDADES.md` | Inventário do que os scripts faziam — **consulta, não reuso** |

## Como usar isto numa Tool nova

1. Ler o `VFX/NOTAS.md` e escolher o efeito.
2. Reescrever o efeito conforme (`_PADROES.md`): sem `math.random`, sem `wait`,
   sem `:Destroy()`, rodando **no cliente** por `VFXRemote`.
3. Copiar o `Sound` e o emitter **para dentro da Tool** (`SFX/` e `Efeitos/`).
4. Marcar o status na ficha: CRU → LIMPO → APROVADO.

---

## Triagem de segurança — feita antes de qualquer conversão

O formato deste material levanta suspeita legítima, então ele foi lido antes de
entrar em qualquer Tool. O resultado está aqui para ninguém precisar refazer a
leitura.

`MainModule.load(alvo)` clona um `Script` de 3477 linhas para dentro da
`PlayerGui` de um jogador **nomeado**, e um `replicator` faz proxy de
`UserInputService`, `SetCore`, `SetCoreGuiEnabled`, `CaptureFocus` e
`GetTextboxCode` por 24 Remotes. O `Handler` que fecha o circuito no cliente
está assinado `-- made by WRENCH#0104`.

**Marcadores procurados e NÃO encontrados nos dois arquivos:** `loadstring`,
`require(<id numérico>)`, `HttpService`, `getfenv`, `setfenv`,
`MarketplaceService`, `GetAsync`, `PostAsync`, webhook, Discord.

Os 8 casamentos de `https?://` são todos `http://www.roblox.com/asset/?id=`
de malha e textura.

**Conclusão:** não é backdoor. É o wrapper "FE bypass" da era pré-FilteringEnabled: um script de
free model antigo, empacotado para rodar num jogo com FilteringEnabled ligado.
O próprio autor deixou isso escrito no cabeçalho — *"This was made before FE so
using this may or may not lag the server"*.

Mesmo assim, **nenhum script da origem entrou nas Tools.** Toda a lógica foi
reescrita conforme as diretrizes; da origem vieram os números e os assets.


---

## Correção de 2026-08-14 — quatro coisas escritas e nunca chamadas

As 7 Tools desta forma passavam nos cinco verificadores e traziam quatro
defeitos da mesma família: **código entregue e nunca invocado**.

| Defeito | Alcance nas 14 | O sintoma no jogo |
|---|---|---|
| `animar()` definido e **nunca chamado** | 14 de 14 | o personagem executava a habilidade **parado**; dano, VFX e empurrão saíam no mesmo quadro do clique |
| `tocar()` **inexistente** | 14 de 14, 34 `Sound` | os sons estavam dentro da Tool, nomeados por papel, e **mudos** |
| `passa_mira` calculado e **nunca substituído** | 5 de 14 | a primária recebia `nil` e saía **sempre reta à frente**, no alcance cheio |
| `desmontarRig()` definido e **nunca chamado** | 14 de 14 | o rig sobrevivia ao respawn apontando para o corpo morto |

O `Poses.lua` e o `R6CFrameAnimator` estavam nas Tools desde a primeira leva,
com as sequências extraídas corretamente e as marcas `CARGA` e `GOLPE` no
lugar. Nada disso estava errado — **faltava o fio** entre eles e a habilidade.

### O que mudou

A habilidade sai **no beat**, não no clique: `CARGA` toca o som de preparação,
`GOLPE` solta o golpe. Se a sequência não tiver `GOLPE`, o disparo acontece no
fim — habilidade que não sai é a falha que este repositório já pagou uma vez, e
não há caminho em que ela simplesmente não aconteça.

A trava `ocupado` entra **antes** da recarga: barrá-la depois de
`ultimoUso = os.clock()` cobraria a espera por um golpe que não saiu.

`CARGA` toca no Handle, que acompanha o portador; `GOLPE` toca numa âncora no
mundo, para o som não morrer se a Tool for guardada no meio do efeito.

### O verificador aprendeu dois testes

`TESTES/verificar_rbxmx.py` ganhou:

- **6c** — Tool com `P.SEQUENCIAS` e nenhum `PlaySequence`/`PlayTrack`/`animar()`
  é **erro**. Era exatamente este defeito.
- **6d** — `Sound` dentro da Tool que nenhum script cita é **aviso**. A checagem
  é nova e encontrou o mesmo problema em 20 Tools de conjuntos antigos que
  ninguém pediu para mexer; contá-las como falha esconderia as falhas de
  verdade no meio do inventário.

### O que continua verdadeiro

Nada rodou no Studio. A verificação é toda estática — que a animação agora é
**chamada** está provado pelo arquivo; que ela **fica bonita** só o jogo diz.

---

## Recriação de 2026-08-19 — as 14 refeitas do zero no pipeline atual

As 14 Tools do Xester eram as mais antigas do repositório. Saíram de um gerador
anterior ao despachante de keyframe, à pasta `SFX/` e ao preâmbulo
compartilhado, e traziam **M1 mais uma Extra**. Agora trazem **quatro
habilidades**: M1 no clique, `R`, `T` e `Y` nas teclas. 14 Tools × 4 = **56
habilidades**.

A M1 de cada Tool é a da origem, mecânica por mecânica — é a habilidade pela
qual a Tool tem nome. As três Extras estendem o mesmo tema; nenhuma abre um
segundo assunto.

### Dois defeitos que só a recriação revelou

**1. A porta do VFXModule estava quebrada nas 14.**

O `VFXModule` do Xester exportava `M.desenhar`, `M.beat` e `M.limpar` — a
assinatura de um `Client.lua` anterior. O `Client` atual chama
`VFX.Executar(tipo, dados)`, `VFX.Parar(id)` e `VFX.LimparTudo()`.

Nenhuma das três existia. **Todo efeito das 14 Tools morria na primeira linha**
do `OnClientEvent`, com `attempt to call a nil value` — e calado, porque quem
falha é a linha do handler, não a habilidade: o dano saía, o som saía, e a tela
ficava vazia.

O módulo ganhou as três portas, mais um **registro por `id`** (`PorId`) e o
efeito `MOVER`, que o tornado da Forma 1 e o escudo orbital chamavam sem que
existisse. `desenhar` e `limpar` continuam lá, apontando para a mesma coisa.

**2. `AcaoRemote` só existia em 6 das 14.**

Ele era criado sob a condição `if extra:` — a Tool tinha zero ou uma Extra.
Agora são três em todas, e o `Server` faz `WaitForChild("AcaoRemote")`: sem o
`RemoteEvent` na árvore ele **trava no `WaitForChild` e a Tool inteira não
liga**. Passou a ser criado nas 14.

No mesmo passe saiu o `MiraRemote` e a lista `PRECISA_MIRA`. Eles existiam
porque a primária ficava em `Tool.Activated`, que não carrega ponto nenhum:
cinco Tools tinham um terceiro canal só para dizer PARA ONDE. Agora o `Client`
manda `VFXRemote:FireServer(mira())` e as catorze miram com dois remotes.

### O verificador aprendeu a checar a PORTA

`TESTES/verificar_vfx_chamadas.py` conferia só o que estava **dentro** de um
`VFXModule` — helper chamado e nunca definido. Isso não pegava o defeito 1:
todos os helpers do Xester estavam no lugar.

Agora ele faz uma segunda conferência: para cada Tool, o que o `Client.lua`
chama como `VFX.<Nome>(` tem de estar exportado pelo `VFXModule.lua` dela.
**81 Tools cobertas.** Um helper faltando apaga um efeito; a porta faltando
apaga todos.

### O que a origem fazia e aqui não acontece

Ela escrevia em `Health` cinco vezes, chamava `BreakJoints` seis, e o `Banish`
fazia `Foe:Destroy()` — matar por deleção tira o abate do Núcleo e apaga o
personagem do jogador. Tinha 21 `math.random`, que com todos os clientes
desenhando faria cada um ver uma cena diferente. Punha `ws = 120` e nunca
devolvia. O `enemy` da Invocação vinha com os scripts `ai` e `core` ligados.

Nada disso sobreviveu: dano é `TakeDamage` pelo Núcleo, tombo é
`PlatformStand` com prazo, sorteio é ângulo áureo, a corrida do machado volta
por três caminhos, e o servo é o molde **podado**, com a perseguição escrita no
Server da própria Tool.

### Nenhuma fere o portador, nenhuma destrói peça do mundo

`alvosEm` tira o `personagem` da consulta e o Núcleo filtra time. Nenhuma das
56 chama `Destroy`, `Remove`, `BreakJoints` ou `Instance.new("Explosion")`.

### O que continua verdadeiro

Nada rodou no Studio. A verificação é toda estática.

---

## Refazimento de 2026-08-19 — o kit novo, e UMA Tool no lugar de catorze

As 14 Tools do Xester saíram do repositório. No lugar delas entrou **uma Tool
`Xester`, com duas formas e 13 habilidades**, pelo desenho que o autor do
projeto especificou tecla a tecla.

### Por que uma Tool, contra a regra de distribuição

`F` troca de forma: `The Final Deal` leva do baralho ao dragão, `Curtain
Reversal` traz de volta. Com duas Tools, uma teria de **alcançar a outra** —
procurá-la na mochila, no `ReplicatedStorage`, num depósito. É exatamente o que
a **Regra nº 1** proíbe, e ela vence a `REGRA_DISTRIBUICAO_DE_TOOLS` na ordem
de precedência do `CLAUDE.md` (autocontenção é 1, distribuição é 3).

Então a forma virou **estado**, dentro da Tool. O teste do place vazio continua
passando: `Xester` sozinho num place funciona nas duas formas, com as três
cutscenes.

São 13 habilidades — abaixo do teto real da regra de distribuição
(7 Tools × 2 = 14). O que mudou foi o **empacotamento**, não a quantidade.

### O kit

| Tecla | Forma 1 — Mestre do Baralho | Tecla | Forma 2 — Heavenbreaker |
|---|---|---|---|
| `Q` | Curtain Call | `G` | Wyrm Sparks |
| `E` | Four Suits Arsenal | `H` | Crown of Cinders |
| `R` | Joker's Labyrinth | `J` | Dragon's Requiem (segurar) |
| `T` | Ace Gate | `K` | Xester Prism |
| `Y` | House Collapse | `L` | The Final Page of Heaven |
| `U` | Eclipse Deck | `F` | Curtain Reversal |
| `P` | Royal Guard | | |
| `F` | The Final Deal | | |

**Passiva:** a cada três habilidades da Forma 1, nasce a Carta Coringa. A
próxima habilidade a gasta e sai com dano × 1.6 e raio × 1.25. O contador mora
no servidor, que é quem aplica o dano.

**O clique é contextual.** §9 manda a primária ficar em `Tool.Activated`, nunca
em botão. Cinco das treze pedem "clicar para confirmar" no desenho — o naipe, o
desabamento, o Rei, as brasas e os três pontos da ultimate. Então o clique
despacha para o que está armado e cai num golpe simples quando não há nada.

### O título escrito não existe, e o motivo é regra

O roteiro pede **"XESTER — HEAVENBREAKER"** na tela no sexto beat. Texto em 3D
no Roblox só existe por `BillboardGui` ou `SurfaceGui`, e a diretriz base
proíbe as duas **dentro de uma Tool**.

O beat `TITULO` existe e é o clímax: a máscara nasce grande, um anel dourado
abre atrás dela e a luz estoura com o FOV em 62 num contra-plongée. O que não
existe é a **letra**. Se o título escrito for obrigatório, ele tem de morar no
sistema de UI do jogo, do lado de fora, ouvindo o `CutsceneRemote` — que já
manda os seis beats nomeados para o cliente do dono.

### As três cutscenes

| Cena | Duração | Beats |
|---|---|---|
| `TRANSFORMAR` (`F`, ida) | 3.00 s | MAO · NAIPES · CORINGA · CONGELA · RASGA · TITULO |
| `REVERTER` (`F`, volta) | 1.80 s | ABSORVE · APAGA · FECHA |
| `CENA_PAGINA` (`L`) | 1.80 s | PARA · RELOGIO · QUEBRA · VOLTA |

As durações são as pedidas: 3 s e 1.8 s. **A cutscene É a sequência de
animação** — os beats saem do `Poses.lua` e viram beat de câmera pelo
`cam = true`. Quem manda o `FIM` é o callback do fim da sequência, não um
`task.wait` paralelo que poderia dessincronizar dela.

A câmera é **100 % cliente e só do dono**: `CutsceneRemote:FireClient(jogador,
…)`, como pedido — a cutscene não é forçada nos outros jogadores. O VFX dela
continua indo para todo mundo por `FireAllClients`: quem está por perto vê o
Xester virar dragão sem perder o controle da própria visão.

Seis portas devolvem a câmera: `Unequipped`, `Destroying`,
`CharacterRemoving`, `Died`, prazo estourado e o pulo (segurar `E` por 1.5 s —
só visual, não encurta a timeline do servidor).

### O que a forma carrega

O **Handle não troca**: `RequiresHandle` exige que ele exista o tempo todo, e
mexer na geometria dele desmonta o `Grip` do `Humanoid`. Quem carrega a forma é
o **Cajado** — `staff/t` da origem, clonado e soldado ao braço direito por um
`Weld` criado no SERVIDOR (no cliente ele não replicaria, e os outros jogadores
veriam o Xester de mãos vazias) — mais a aura de brasas, que tem `id` e é
apagada na volta e nas duas portas de saída.

### Nenhuma fere o portador, nenhuma destrói peça do mundo

`alvosEm` exclui o `personagem` da consulta espacial, e o Núcleo filtra time.
Nenhuma das 13 chama `Destroy`, `Remove`, `BreakJoints` ou
`Instance.new("Explosion")`. A invisibilidade do Curtain Call guarda a
transparência **anterior** de cada peça e devolve aquela.

### Dois verificadores novos, e um consertado

- **`TESTES/verificar_beats.py`** (novo) — confere o fio entre o Server, o
  `Poses.lua` e o `CutsceneCam.lua`: sequência tocada que existe, beat
  despachado que a sequência tem, e beat de câmera com enquadramento. É o
  defeito que custou 14 Tools entregues com dano zero, e que era invisível para
  os cinco verificadores da época. **75 Tools conferidas, zero erro.**

- **`TESTES/verificar_pack_vfx.py`** (consertado) — o padrão de chamada era
  `pk\(\s*"(\w+)"\s*,(.*?)\)\s*then`, e só enxergava `pk` dentro de um
  `if … then`. Chamada solta não casava, e o `.*?` com `re.S` varria o arquivo
  para a frente até achar um `) then` de outra função — conferindo LIXO em vez
  de não conferir. Agora o corpo é lido com contador de parênteses:
  **779 chamadas conferidas contra 267 antes**, todas OK.

### O que continua verdadeiro

Nada rodou no Studio. A verificação é toda estática — que os beats casam está
provado pelo arquivo; que a cutscene **fica bonita** só o jogo diz.

---

## Correção do empacotamento, 2026-08-19 — 7 Tools + 6 Tools, dois arquivos

A seção acima descreve o kit certo e um **empacotamento errado**. Ela entregou
**uma Tool só** com as duas formas dentro; o pedido era 7 Tools na Forma 1 e 6
na Forma 2, em dois arquivos com as Tools dentro. Esta seção substitui aquela
no que toca a empacotamento — o kit, as cutscenes e a nota sobre o título
continuam valendo.

### A distribuição, pela regra

| Forma | Habilidades | Tools | O que fez o excedente |
|---|---|---|---|
| 1 — Mestre do Baralho | 8 (`Q E R T Y U P F`) | **7** | `F The Final Deal` virou **Extra** em `Xester Eclipse Deck` |
| 2 — Heavenbreaker | 6 (`G H J K L F`) | **6** | nenhum — uma Tool por habilidade |

É a `REGRA_DISTRIBUICAO_DE_TOOLS` ao pé da letra: 8 ou mais → 7 Tools com o
excedente como Extra na Tool de tema mais próximo; de 3 a 7 → uma por
habilidade. O agrupamento fica declarado, como a regra exige: `The Final Deal`
foi para o `Eclipse Deck` porque os dois são o **clímax** da Forma 1.

### Como `F` troca de forma sem alcançar outra Tool

Era este o argumento que me levou a empacotar tudo numa Tool só, e ele estava
mal resolvido, não certo.

`F` **não procura** a Tool da outra forma. Ela escreve um **Attribute no
Character**: `XesterForma = 2`. Quem lê, lê sob guarda e com padrão.

Isso é a mesma categoria do `_G.Combate` que a Regra nº 1 já admite: **estado
opcional compartilhado**, não caminho de instância, não depósito de asset. O
teste que decide continua passando — arraste **qualquer uma das 13** sozinha
para um place vazio e ela funciona por inteiro: o atributo não existe, a Tool o
cria com o padrão dela, e a habilidade sai igual.

A passiva atravessa as sete pelo mesmo caminho (`XesterUsos`,
`XesterCoringa`). Numa Tool sozinha o contador conta só os usos dela, e a Carta
Coringa nasce do mesmo jeito: o comportamento **degrada, não quebra**.

### O que carrega a forma entre as Tools

O **Cajado** é clonado para o **Character**, não para a Tool. É por isso que
ele sobrevive à troca de Tool na mochila — vira dragão com o `Eclipse Deck`,
saca o `Wyrm Sparks` e continua de cajado —, e é por isso que ele não precisa
de limpeza: morre com o respawn, junto do personagem. O `Weld` é criado no
**servidor**; no cliente não replicaria, e os outros veriam o Xester de mãos
vazias.

### As três entradas, e nenhum botão fazendo o papel da primária

| Canal | Quem usa | Para quê |
|---|---|---|
| `Tool.Activated` | as 13 | a primária. §9: nunca em botão |
| segundo clique | 5 delas | a metade de trás da mesma habilidade — o portão do Ás, o desabamento, o naipe, o Rei, o estilhaço. **Não paga recarga nova** |
| `Tool.Deactivated` | `Dragons Requiem` | o lado de SOLTAR do sopro carregado |
| `AcaoRemote` + botão | `Eclipse Deck`, `Royal Guard` | a Extra de verdade, com botão de celular |

A mira móvel do `Prism` viaja pelo `VFXRemote` com a fase `MIRA` — não é
habilidade, não paga recarga, e o servidor só a aceita com o prisma de pé.

### O molde entrou magro

A versão de uma Tool só carregava as subárvores `cards`, `staff`, `energb` e
`Effects` inteiras: 76 instâncias e 430 KB. O `VFXModule` procura molde **por
nome**, e os nomes que ele procura são treze — `Carta1..4`, os quatro `As*`,
`Mascara`, `Anel`, `Onda`, `Tempestade`, `Orbe` — mais o `Cajado`. É isso que
viaja agora. Cada Tool ficou em ~318 KB com o pack Stella dentro.

### Verificado

13 Tools ✓ no `verificar_rbxmx`, os dois conjuntos ✓, poses ✓, estrutura ✓,
pack ✓, chamadas de VFX ✓, beats ✓ (88 Tools, zero erro). Cruzado por Tool:
todo `Sound` depositado é citado, todo VFX transmitido tem definição, toda
sequência tocada existe. Zero global acidental nos 13 Servers.

Nada rodou no Studio. A verificação é toda estática.
