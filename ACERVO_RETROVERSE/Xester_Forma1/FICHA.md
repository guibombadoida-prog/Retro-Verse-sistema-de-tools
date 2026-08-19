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
