# Modelo: Saitama_Animacoes_Referencia

- **Autor original:** **não declarado no arquivo** — pack de animação de toolbox.
  ⚠️ Campo obrigatório de §12.12.3: **você precisa preencher** antes de usar em Tool.
- **Origem:** `ea5e25ca-SaitamaAnimacoes_Originais_V1.rbxmx`
- **Licença / permissão:** **a confirmar**.
  ⚠️ Campo obrigatório de §12.12.3.
- **Data de entrada:** 2026-08-04
- **Status: CRU**   (CRU | LIMPO | APROVADO)
- **Violações corrigidas:** nenhuma — nada foi reescrito, porque nada disto roda.
- **Já usado em:** nada. É material de consulta.

> ⚠️ **Sem os quatro campos acima — autor, origem, licença, data — este material
> fica CRU e NÃO pode entrar em Tool** (§12.12.3).

## O que é, e o que não é

**É** a extração integral das animações de um pack de referência, já convertida do
formato `KeyframeSequence`/`Pose` para o formato `Weld.C0` que o projeto usa. 2417
keyframes, 9 sequências de corpo + 1 trajetória de câmera, sem redução, sem
suavização, sem retiming.

**Não é** runtime. O módulo devolve uma tabela e nada mais — não cria instância, não
conecta evento, não toca nada. Existe para consulta ao autorar animação nova: silhueta,
timing, ritmo de golpe.

O status **CRU** é literal e é o desfecho certo: sem autor e sem licença, o dado não
entra em Tool. Como ele nunca ia entrar em Tool de qualquer jeito — é referência —, CRU
não estorva nada. **Copiar keyframe daqui para dentro de uma Tool é usar o material**, e
aí a ficha precisa fechar primeiro.

## O que tem dentro

| Sequência | Tool original | Arquétipo | Keyframes | Duração |
|---|---|---|---|---|
| `NORMAL_SHOVE` | Normal Shove | MELEE | 49 | 0,800 s |
| `NORMAL_PUNCH` | Normal Punch | MELEE | 71 | 1,167 s |
| `NORMAL_UPPERCUT` | Normal Uppercut | MELEE | 73 | 1,200 s |
| `CONSECUTIVE_PUNCHES` | Consecutive Normal Punches | MELEE | 111 | 1,833 s |
| `SERIOUS_MODE` | Serious Mode | CUTSCENE | 121 | 2,000 s |
| `DEATH_COUNTER` | Death Counter | CUTSCENE | 421 | 7,000 s |
| `TABLE_FLIP` | Table Flip | HÍBRIDO | 498 | 8,283 s |
| `SERIOUS_PUNCH` | Serious Punch | CUTSCENE | 548 | 9,117 s |
| `SERIOUS_PUNCH_CAMERA` | (rig de câmera) | CÂMERA | 525 | 8,733 s |

Juntas presentes: `HRP` · `Head` · `RightArm` · `LeftArm` · `RightLeg` · `LeftLeg` —
exatamente as seis do `R6CFrameAnimator_V2`.

## Conferido na entrada

| | |
|---|---|
| `luac5.4 -p` | compila |
| `math.random` · `tick()` · `wait(` · `spawn(` | **zero** ocorrências |
| Escrita em `Motor6D` | zero — só citação no cabeçalho, explicando a conversão |
| `Animation` / `LoadAnimation` | zero — só citação no cabeçalho |
| Keyframe de repouso | bate com as seis bases de Weld do animator |

O último item é o que importa: `RightArm = CFrame.new(1.5, 0, 0)`,
`RightLeg = CFrame.new(0.5, -2, 0)`, `HRP = CFrame.new()` etc. Qualquer valor daqui pode
ser colado direto numa tabela `Poses` sem nova conversão.

## Como usar isto numa Tool nova

1. Fechar a ficha primeiro — autor e licença. Sem isso, para aqui.
2. Ler a sequência e achar o **pico de velocidade** anotado no cabeçalho dela: é o frame
   de impacto, e é ali que o dano entra, não no fim da animação.
3. Reautorar com **poucos keyframes e easing certo** (Back/In na carga, Quint/Out no
   golpe). O bake é linear a 60 fps; copiar os 548 keyframes crus lê pior que 8 bons.
4. Se a sequência realmente precisar do bake inteiro, é `PlayTrack` — não `PlaySequence`.
5. Depositar a tabela final em `Tools/<Nome>/Poses_<Modelo>_V1.lua`, dentro da Tool.
