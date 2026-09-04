# GRAMÁTICA R6 — como um golpe é construído
**Retro-Verse / Studios** · regras MEDIDAS no `SaitamaAnimacoes_Originais_V1`

---

## Para que serve este arquivo

O pack do Saitama tem 2417 keyframes em 9 sequências. Copiá-los é plágio de
silhueta e não ensina nada. O que vale é a **lógica de construção** — e ela é
medível.

Tudo abaixo saiu de medição no arquivo, não de opinião. A conta está em
`FERRAMENTAS/medir_gramatica_r6.py`, e dá para refazer.

> **Nenhuma pose daqui deve ser copiada.** Este documento entrega PROPORÇÕES.
> Quem escreve a pose nova é o autor, obedecendo às proporções.

---

## A medição

| Sequência | kf | duração | antecipação : recuo | junta que lidera | quadros parados |
|---|---|---|---|---|---|
| `NORMAL_SHOVE` | 49 | 0.80 s | **50 : 50** | **HRP (56%)** | 73% |
| `NORMAL_PUNCH` | 71 | 1.17 s | **59 : 41** | RightArm (28%) | 40% |
| `NORMAL_UPPERCUT` | 73 | 1.20 s | **49 : 51** | RightArm (32%) | 56% |
| `CONSECUTIVE_PUNCHES` | 111 | 1.83 s | **35 : 65** | **HRP (32%)** | 15% |
| `SERIOUS_MODE` | 121 | 2.00 s | **2 : 98** | RightArm (51%) | 62% |
| `DEATH_COUNTER` | 421 | 7.00 s | **86 : 14** | RightArm (24%) | 78% |
| `TABLE_FLIP` | 498 | 8.28 s | **74 : 26** | RightArm (30%) | **90%** |
| `SERIOUS_PUNCH` | 548 | 9.12 s | **64 : 36** | RightArm (27%) | 48% |

"Impacto" = o quadro de maior velocidade angular somada; "antecipação : recuo" =
a fração do tempo antes e depois dele. "Parado" = quadros abaixo de 5% da
velocidade de pico.

---

## As sete regras que saem disso

### 1. Golpe rápido vive entre 0.8 s e 1.2 s

Shove, punch e uppercut: 0.80, 1.17, 1.20. Nada de golpe corpo a corpo passa de
1.2 s. Acima disso o jogador sente travamento, não peso.

### 2. O impacto cai na METADE, não no fim

49%, 50%, 59%. A intuição errada é gastar o tempo todo carregando e bater no
último quadro — aí o golpe não tem recuo, e sem recuo ele não tem peso.
**Metade para carregar, metade para voltar.**

### 3. Combo inverte a proporção: 35 : 65

`CONSECUTIVE_PUNCHES` bate cedo (35%) porque o resto do tempo são os golpes
seguintes. Regra: **quanto mais golpes na mesma entrada, mais cedo o primeiro
impacto.**

### 4. Transformação não é golpe: 2 : 98

`SERIOUS_MODE` atinge o pico em 0.05 s e passa os outros 98% sustentando. Uma
mudança de estado abre **imediatamente** e depois só respira. Tratar
transformação com timing de soco é o erro clássico.

### 5. Ultimate é 7–9 s com 64–86% de preparação

`DEATH_COUNTER` 86%, `TABLE_FLIP` 74%, `SERIOUS_PUNCH` 64%. Ultimate é
**construção longa e liberação curta** — o oposto do golpe rápido. E é por isso
que ultimate pede câmera: 7 segundos de preparação sem enquadramento é tempo
morto.

### 6. O corpo lidera o empurrão; o braço lidera o soco

`NORMAL_SHOVE` e `CONSECUTIVE_PUNCHES` são conduzidos pelo **HRP** (56% e 32%
do movimento total). Os outros seis, pelo **RightArm**.

Regra: **empurrão, avanço e combo saem do tronco. Soco, corte e conjuração saem
do braço.** Animar um empurrão só com o braço é o que faz ele parecer um tapa.

### 7. Estas animações são, em maioria, PARADAS

Este foi o número que mais me surpreendeu ao medir, e é o mais útil:

| | parado |
|---|---|
| `TABLE_FLIP` | **90%** |
| `DEATH_COUNTER` | 78% |
| `NORMAL_SHOVE` | 73% |
| `SERIOUS_MODE` | 62% |
| `NORMAL_UPPERCUT` | 56% |
| `SERIOUS_PUNCH` | 48% |
| `NORMAL_PUNCH` | 40% |
| `CONSECUTIVE_PUNCHES` | 15% |

Mesmo o empurrão de 0.8 s passa 73% do tempo praticamente imóvel. **O movimento
está concentrado em rajadas curtas, separadas por quadros segurados.**

É o oposto do instinto de quem autora animação procedural, que é fazer tudo se
mexer o tempo todo — foi exatamente o erro das poses que escrevi antes desta
medição. Movimento contínuo lê como flutuação; movimento em rajada lê como
força.

Consequência prática para o `R6CFrameAnimator`: um passo de sequência com
`time` longo e pose quase igual à anterior **não é desperdício** — é o quadro
segurado. Ele é obrigatório em ultimate e recomendado em golpe pesado.

---

## A câmera do `SERIOUS_PUNCH`

525 keyframes, 8.73 s, e o que ela faz é quase nada — de propósito:

- **parada em 42% dos quadros**
- primeiro movimento só em **t = 0.87 s** (deixa a pose se estabelecer antes)
- último movimento em **t = 6.32 s** (para antes do fim; os 2.4 s finais são
  estáticos)
- **exatamente 1 corte** em toda a cutscene, em t = 3.08 s, de 10.8 studs

Regra: **câmera de cutscene fica parada mais do que se move, e corta uma vez
só.** Câmera que passeia o tempo todo tira o peso do golpe em vez de dar.

---

## Como autorar uma sequência nova com isto

1. Classifique: golpe rápido, combo, transformação ou ultimate.
2. Pegue a duração e a proporção da tabela — **não invente**.
3. Escolha a junta que lidera pela natureza do golpe (regra 6).
4. Escreva **3 a 5 poses**: guarda → antecipação → impacto → recuo → guarda.
   O Saitama usa dezenas de keyframes porque é bake de 60 fps; o
   `R6CFrameAnimator` interpola, então 3–5 poses bem colocadas bastam.
5. Distribua o `time` de cada passo segundo a proporção medida.
6. Ultimate: acrescente um passo **segurado** antes do impacto (regra 7) e
   marque o beat de câmera.

### Exemplo — soco pesado autoral, 1.1 s

```
antecipação 59%  ->  0.65 s   (2 passos: guarda -> carga, carga -> segura)
recuo       41%  ->  0.45 s   (2 passos: impacto -> recuo, recuo -> guarda)
lidera: RightArm
```

Isso não é a pose do Saitama. É a **proporção** dele, com silhueta própria.

---

## O que este documento NÃO resolve

Ele mede tempo, proporção e condução. **Não mede a beleza da silhueta** — o
ângulo exato de um cotovelo continua sendo escolha de quem autora. E não medi
`easing` por segmento, porque o pack é bake de 60 fps: não existe curva
declarada nele, a curva está diluída nos keyframes. Para autorar, `Back/Out` na
carga e `Quint/Out` no impacto continuam sendo a escolha do projeto, não uma
medição.
