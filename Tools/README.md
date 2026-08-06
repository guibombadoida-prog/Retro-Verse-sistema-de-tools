# Tools

**12 Tools, em dois conjuntos.**

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
