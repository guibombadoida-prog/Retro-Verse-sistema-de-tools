# REGRA — TOOL REMASTERIZADA **≠** TOOL NOVA
**Retro-Verse / Studios** · regra de origem do trabalho

---

## O enunciado

> **Tool remasterizada** reaproveita a **mesma estrutura** do modelo de origem —
> só a habilidade melhora.
>
> **Tool nova** não tem modelo de origem. Ela é autorada a partir da **lógica**
> que o Acervo ensina, e é livre para ser completamente diferente.

São duas encomendas diferentes. Confundir as duas é o erro que já aconteceu
aqui: pedido de Tool nova sendo respondido com cópia de modelo.

---

## A tabela que decide

| | **REMASTERIZADA** | **NOVA** |
|---|---|---|
| Tem modelo de origem? | Sim, e ele manda | Não |
| Estrutura (Handle, malha, hierarquia) | **A mesma.** Não se redesenha | Autoral, ou colhida do Acervo |
| Habilidades | **As mesmas**, melhoradas | Inventadas |
| Movelist | A do modelo, respeitada | Não existe até alguém escrever |
| Animação | A do modelo, convertida | **Autorada pela gramática** (§abaixo) |
| VFX | O do modelo + reuso do Acervo | Montado do zero, com o vocabulário do Acervo |
| Números (dano, raio, tempo) | Do original, citados com a linha | Decisão de balanceamento, declarada |
| O que o relatório diz | "de onde veio cada número" | "por que cada número é esse" |

---

## Remasterizada — o que "melhorar" quer dizer

Melhorar **não** é trocar a habilidade. É a mesma habilidade funcionando melhor:

- o que era `math.random` vira determinístico
- o que era `:Destroy()` vira `Parent = nil` / `Debris`
- o que o servidor movia por quadro passa a ser beat + desenho no cliente
- o que matava por deleção passa a usar `TakeDamage` e credita o abate pela etiqueta `creator`
- o que era invisível para os outros jogadores passa a aparecer
- VFX e SFX ganham camada, sem trocar de identidade

**O que NÃO se mexe sem pedido:** Handle, malha, modelo, silhueta, e o
*conceito* da habilidade. Se o modelo tinha uma carta que vira escudo, a
remasterização entrega uma carta que vira escudo — melhor, não outra coisa.

---

## Nova — a matéria-prima é a LÓGICA, não o arquivo

Uma Tool nova não copia nada. Ela é escrita por quem **estudou** o Acervo:

1. Ler `ACERVO_RETROVERSE/_INDICE.md` e as gramáticas
   (`R6_CFRAME/GRAMATICA_R6.md`, e a de VFX quando existir).
2. Autorar a habilidade a partir das **regras medidas**, não dos números
   copiados.
3. Reusar asset — malha, som, emissor, efeito do pack — porque asset é
   vocabulário. **Pose e lógica de habilidade, não.**

> A diferença prática: copiar a pose do Saitama é plágio de silhueta. Saber que
> o soco dele gasta 59% do tempo em antecipação e 41% em recuo, e autorar uma
> pose nova com essa proporção, é ofício.

---

## O teste que separa as duas

Pergunte: **existe um `.rbxmx` de origem que alguém mandou converter?**

- **Sim** → remasterizada. A estrutura dele é lei, e o relatório cita a linha
  de onde cada número veio.
- **Não** → nova. Nada é lei além das diretrizes, e o relatório explica cada
  escolha em vez de citar origem.

---

## No relatório de entrega

```
## Origem do trabalho
  Tipo: REMASTERIZADA | NOVA
  (remaster) Modelo:      [arquivo]  — estrutura preservada: [Handle, malha, ...]
  (remaster) Melhorias:   [o que mudou, por habilidade]
  (nova)     Gramática:   [qual regra medida gerou qual decisão]
  (nova)     Reuso:       [asset do Acervo, e de onde]
```
