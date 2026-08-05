# Tools

**7 Tools, clonadas da `DANILO_TOOLS_ESCUDOS_V4.rbxmx`.**

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

## O que foi tocado, e o que não foi

**Uma única coisa mudou em relação ao arquivo que você enviou: o `Source` do `VFXModule`.**

| | |
|---|---|
| Handle, `SpecialMesh`, Model | **intactos, da origem** |
| `Sound` (79), `StringValue` (14), `NumberValue` (14), `RemoteEvent` (14) | **intactos, da origem** |
| `Poses`, `R6CFrameAnimator`, `Client`, os 7 `_Server_V*` | **intactos, da origem** |
| `VFXModule` | ponte nova para o pack compartilhado, no fim do arquivo |

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

## O VFX

Cada `VFXModule` roda **primeiro** o efeito próprio da Tool, inteiro, e **depois** sobrepõe o
reforço do pack compartilhado (`ReplicatedStorage/VFX_Module.rbxmx`), dentro de `pcall`.

Sem o pack no place, o reforço não acha nada e o efeito próprio já aconteceu:
**a Tool empobrece, não quebra.** É a exceção declarada da Regra nº 1 — ver
[`DIRETRIZES/REGRA_AUTOCONTENCAO_ABSOLUTA.md`](../DIRETRIZES/REGRA_AUTOCONTENCAO_ABSOLUTA.md),
seção "A exceção declarada".

O reforço é **camada nova, não repetição**: o `IMPACTO` próprio faz flash, anel, linhas e
faíscas e nenhum disco — é o disco que o pack acrescenta, em 0.26 s, tempo diferente das
outras camadas de propósito (duas camadas com a mesma duração leem como borrão).

Para desligar tudo e voltar ao VFX próprio: `PACK.LIGADO = false`, no topo da ponte.

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
já cobra isso, e é a única checagem vermelha do repositório hoje.

---

## Verificação

```bash
bash    TESTES/verificar_autocontencao.sh   # Regra nº 1 + a exceção declarada
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

1. `ReplicatedStorage/VFX_Module.rbxmx` e `VFX_Meshes.rbxmx` → `ReplicatedStorage`
2. `ServerScriptService/NucleoCombate.lua` → Script `NucleoCombate` em `ServerScriptService`
3. As Tools → `StarterPack`

Os passos 1 e 2 são **opcionais**: sem o 1 a Tool perde o reforço de VFX, sem o 2 perde os
bônus de combate. Em nenhum dos dois casos ela quebra.
