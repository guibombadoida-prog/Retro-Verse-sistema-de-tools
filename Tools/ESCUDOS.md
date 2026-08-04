# Conjunto Escudos — 7 Tools

Entrega: **`Tools/Escudos_7_Tools.rbxmx`** — as 7 Tools na raiz do arquivo. Arraste para a
`StarterPack` e as sete chegam ao jogador. Um `.rbxmx` individual por Tool também existe.

**5 convertidas** do modelo `Danilo_Escudos` + **2 autorais**, pedidas nesta entrega.
Piso 3, teto 7 — o conjunto fecha exatamente no teto.

## As 7

| Tool | Classe | Recarga | Primária | Extra (X) |
|---|---|---|---|---|
| `EscudoBloqueador` | Defense | 8 s | postura de bloqueio: −25% de dano, 15% volta no atacante | barreira em cúpula: −52% para aliados no raio 15 |
| `EscudoBumerangue` | Ranged | 3 s | arremessa o disco; ele vai a 50 studs e **volta** | três discos em leque de 15° |
| `EscudoSkate` | Mobility | 8 s | monta no escudo: +35 de velocidade por 5 s, atropela por 10 | — |
| `EscudoProtecao` | Defense | 7 s | o escudo orbita 4 s e rebate projétil em quem atirou | — |
| `EscudoSalvador` | Support | 10 s | vincula a um aliado 7 s: o dano dele vem para você | — |
| **`EscudoCiclone`** | Debuff | 14 s | **cinco escudos orbitam e puxam** quem entra no raio 22, por 8 s | colapsa o ciclone: 62 no raio 14 |
| **`EscudoPartido`** | Melee | 22 s | lâmina que vai reto até 62 studs e **não volta** | **cutscene**: 6 cortes + golpe mortal de **299** |

As duas em negrito são as novas.

---

## As duas habilidades novas

### `EscudoCiclone` — cinco escudos que puxam

Cinco discos orbitam o portador a 7,5 studs de raio, 1,15 volta por segundo, por 8 s. Quem
entrar no raio de 22 é **puxado para dentro**; quem encostar na faixa da órbita leva 9, com
recarga de 0,7 s por alvo.

Duas decisões que mudam como a habilidade joga:

**O puxão é radial, nunca vertical.** Levantar o alvo do chão tiraria o controle dele por
completo, e a habilidade viraria um stun. Puxando só no plano, o alvo continua lutando contra
— que é o que a torna interessante.

**O puxão é pulsado, não contínuo.** Um `BodyVelocity` de vida curta renovado a cada 0,2 s, em
vez de escrever velocidade todo frame. Escrever `AssemblyLinearVelocity` a 60 Hz briga com o
`Humanoid` do alvo, que também escreve — é o mesmo erro de dois donos que bugou a animação R6.

Os cinco ficam a 72° um do outro (360/5), com a fase avançando por acumulador `dt`. Sem
`math.random`: dois usos seguidos dão a mesma órbita.

### `EscudoPartido` — a lâmina que não volta, e a sentença

**Primária:** o mesmo voo do Bumerangue, **sem o retorno**. A lâmina sai, atravessa até 62
studs acertando quem estiver no caminho, e estilhaça no fim. É literalmente o bumerangue menos
uma condição — e é essa condição que separa as duas Tools.

**Extra — a sentença.** Dois escudos giram em volta do alvo dando 6 cortes de 12, e o último
golpe tira **299**. Roda numa cutscene.

> **A condição É a habilidade.** "SE pegar o dano" não é detalhe de implementação: sem alvo
> válido no alcance de 26, a Extra **não acontece e não gasta recarga**. Uma cutscene que roda
> no vazio é o pior caso possível — prende a câmera do jogador por três segundos para não
> mostrar nada. O alvo é escolhido **antes** de qualquer beat.

Os 299 saem por `registrarAtaque`, pelo Núcleo — nunca `Health = 0`. Assim `ForceField`,
escudo e redução registrada continuam valendo. Um golpe mortal que ignora `ForceField` é um
golpe que mata quem acabou de nascer.

#### A cutscene segue a regra de câmera

Zero `Camera` no Server Script. O que sai de lá é **beat nomeado** por `CutsceneRemote`:
`START` → `CORTE` → `SENTENCA` → `STOP`. Quem enquadra é a `CutsceneCam`, LocalScript da
própria Tool.

| Obrigação | Onde está |
|---|---|
| Guarda e restaura o `CameraType` anterior | `pararCutscene()` — o valor guardado, não `Custom` chutado |
| Restaura o `FieldOfView` | idem |
| Desliga em `Unequipped` e `Destroying` | últimas duas linhas do arquivo |
| É pulável | segurar **E** por 1,5 s |
| O pulo é **puramente visual** | solta a câmera e não fala com o servidor |

A última linha é a que importa para o balanço: os 6 cortes e os 299 acontecem no mesmo tempo,
pulando ou não. Se o skip encurtasse a timeline, pular a cutscene viraria vantagem de combate
e todo mundo pularia sempre.

Técnica de lente: órbita em dois estágios (11 studs na abertura → 6,5 nos cortes) e contraste
de FOV — 70 base, fecha a **42** durante os cortes, estoura a **98** no golpe mortal. É o
contraste que vende o golpe, não o valor absoluto.

---

## VFX — o pack do Saitama

Cinco emissores novos entraram, extraídos do `01_Saitama` da `VFX_Library_V2` com os
parâmetros do arquivo cru:

| Efeito | Habilidade de origem | O que é | Usado em |
|---|---|---|---|
| `ESTILHACO_ESCUDO` | Death Counter | cacos escuros e rápidos — coisa **quebrando** | Bumerangue, Skate, Partido |
| `CLARAO_ESCUDO` | Normal Uppercut | flash que abre e fecha girando a 250°/s | Bloqueador, Proteção, Salvador, Partido |
| `ONDA_ESCUDO` | Serious Punch | anel de choque que abre até 120 studs | Ciclone, Partido |
| `IMPACTO_ESCUDO` | Death Counter | rajada curta presa ao ponto (`Drag` 10) | as 7 |
| `POEIRA_ESCUDO` | Serious Mode | poeira pesada que cai (aceleração −15 em Y) | Skate, Ciclone |

Todos ligados por `Enabled` + `Rate` — **zero `:Emit()`**. `:Emit()` dispara uma leva fixa e
ignora o `Rate` autorado; a curva extraída do original se perde, e é justamente a curva que
faz o efeito ser aquele efeito.

Dois deles **não são tingidos** de propósito: `ESTILHACO_ESCUDO` é escuro porque é isso que faz
ler como metal, e `POEIRA_ESCUDO` guarda o cinza `100,102,115` do original. Tingir os dois de
azul transformaria caco de escudo em faísca mágica e fumaça em névoa.

Os outros três foram recolorizados para a paleta do conjunto no passe §12.12.2.

---

## O que veio do Judgement Cut End

Modelo analisado, **três sons aproveitados**, nada de código:

| Som | Id | Onde |
|---|---|---|
| Hit4 | `220834019` | `Corte` do Escudo Partido |
| Judgement Cut End Start | `5989940114` | `Sentenca` — o golpe mortal |
| ChangeE | `10555593530` | `Estilhaco` |

O modelo tem 46 `MeshPart` de lâmina e katana, 12 `ParticleEmitter` e 6
`ColorCorrectionEffect`. Os meshes ficam **CRU** no Acervo: são bonitos, mas `MeshId` de
terceiro sem licença declarada não entra em Tool. Os `ColorCorrectionEffect` são proibidos por
regra — pós-processamento é global ao cliente e vaza para fora da Tool.

O `Domain_Expansion_Elemental` foi depositado e **não rendeu nada aproveitável para escudos**:
é um pack elemental (fogo, gelo) com 1800 `Part` e 28 `Fire`, tematicamente longe. Fica no
Acervo para um conjunto elemental futuro.

---

## O que a conversão corrigiu no modelo Danilo

As 5 Tools originais tinham, somadas: **69** `Animation`/`LoadAnimation`, **35** `wait()`,
**21** `spawn()`, **14** `delay()`, 7 `tick()`, 4 `math.random`, 3 `:Destroy()`, 2 `:Emit()`
no servidor, 1 `ScreenGui` e 1 escrita direta em `Health`.

Três defeitos de comportamento, não só de estilo:

**1. `Salvador` escrevia vida direto.** `targetHumanoid.Health = oldHealth` desfazia o dano do
aliado e jogava em você. Ignora `ForceField`, ignora redução registrada, e briga com qualquer
outro sistema de dano do place — e em alguns caminhos lia `oldHealth` depois do dano, curando
o aliado acima do que ele tinha. Agora o aliado recebe redução de 100% pelo Núcleo e o valor
é aplicado no portador: **o dano nunca chega a assentar**, então não há o que desfazer.

**2. `Skate` deixava a velocidade presa.** `originalSpeed` era restaurado só no fim do laço.
Largar a Tool no meio, ou morrer, deixava o jogador a 51 de velocidade **para sempre**. Agora
a restauração está em `desmontar()`, ligada em `Unequipped`, `Destroying` e `Died` — e restaura
o valor guardado, em vez de subtrair o bônus (subtrair deixa o jogador devendo se outro sistema
mexeu na velocidade no meio).

**3. `Proteção` varria o `workspace` inteiro** todo frame procurando projétil. Agora é consulta
espacial no raio do escudo, com filtro explícito: `Part` solta, leve, rápida, e que não faça
parte de um personagem — sem o último filtro, o escudo rebatia o próprio jogador quando ele
pulava perto.

---

## 🐛 Corrigido depois do primeiro teste em jogo

O relato foi "não funciona o dano contra NPC inimigo e nem a cutscene". Eram
**quatro** erros meus de assinatura da API do Núcleo — nenhum deles dá erro no
Output, porque Lua aceita aridade errada calada.

| Defeito | Efeito |
|---|---|
| `aplicarDano` chamava `registrarAtaque` | **dano zero** nas 7 Tools com o Núcleo instalado — `registrarAtaque(jogador, tool, classe)` só grava atribuição de abate (§12.8), não causa dano. O certo é `calcular()` + `TakeDamage(final)` |
| Fallback varria `Players:GetPlayers()` | **NPC nunca era encontrado** — NPC é `Model` com `Humanoid` no workspace, não é `Player`. Sem o Núcleo, nem dano nem cutscene contra NPC |
| `detectarHumanoides` com 3 argumentos | a função quer 6; `jogador` nil **desliga o filtro de time** do `podeCausarDano` — aliado virava alvo válido |
| `aoAplicarDano(humanoide, fn)` | é ouvinte **global** e recebe só a função; o callback é `(contexto, danoFinal)`. Passar o `Humanoid` fazia o Núcleo ver `type(funcao) ~= "function"` e devolver um no-op — a reflexão do Bloqueador e a transferência do Salvador **nunca dispararam** |

Os dois primeiros explicam os dois sintomas relatados, e juntos explicam por que
a cutscene não abria: `escolherAlvo` não achava o NPC, e a própria guarda
"sem alvo, a Extra não acontece" devolvia calada.

`verificar_autocontencao.sh` ganhou as quatro checagens correspondentes,
testadas contra um violador com os defeitos originais.

## Verificação

```bash
bash    TESTES/verificar_autocontencao.sh
python3 TESTES/verificar_poses.py
python3 FERRAMENTAS/montar_rbxmx.py
python3 TESTES/verificar_rbxmx.py
```

## O que não foi testado

**Nada rodou no Studio.** Em especial a cutscene do `EscudoPartido`, que é o mais frágil deste
conjunto: enquadramento, ritmo dos 6 cortes e o momento do estouro de FOV só se avaliam
jogando. Os testes de aceitação estão em `DIRETRIZES/CHECKLIST_ENTREGA.md`, seção da câmera.
