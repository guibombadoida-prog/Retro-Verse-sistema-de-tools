# REGRA DE DISTRIBUIÇÃO — QUANTAS TOOLS SAEM DE UM MODELO
**Retro-Verse / Studios** · regra de conversão

---

## O enunciado

> Um modelo vira **no mínimo 3 e no máximo 7 Tools**.
> Se tiver mais de 7 habilidades, o excedente entra como **habilidade Extra** dentro de uma Tool.
> Se tiver menos, o número de Tools é o número de habilidades — respeitado o mínimo de 3.

---

## A tabela de decisão

| Habilidades no modelo | Tools | O que fazer com o resto |
|---|---|---|
| 1 ou 2 | **3** | Desdobrar: separar fases, ou criar variação autoral até fechar 3 |
| 3 a 7 | **= nº de habilidades** | Uma habilidade primária por Tool |
| 8 ou mais | **7** | O excedente vira habilidade **Extra** dentro da Tool de tema mais próximo |

**Piso 3, teto 7. Sempre.**

---

## Como o excedente é alocado

Cada Tool comporta **duas** habilidades:

| Posição | Como dispara | Regra |
|---|---|---|
| **Primária** | `Tool.Activated` | Nunca por botão (§9) |
| **Extra** | tecla via `ContextActionService` + `AcaoRemote` | Botão na tela é permitido **só** aqui (§9) |

O excedente vai para a Tool **de tema mais próximo**, não para a primeira que tiver vaga.
Aceleração de movimento acompanha a Tool de deslocamento; provocação acompanha a Tool de
ultimate. O agrupamento é decisão autoral e **é declarada no relatório de entrega**.

Teto real: 7 Tools × 2 habilidades = **14 habilidades**. Passando disso, cortar — e declarar
o que foi cortado e por quê.

---

## O que conta como habilidade

| Conta | Não conta |
|---|---|
| Golpe, projétil, área, invocação | Animação de `Idle` e de caminhada |
| Deslocamento (dash, teleporte, avanço) | Efeito passivo sem entrada do jogador |
| Buff / debuff acionado pelo jogador | Variação de combo da mesma habilidade |
| Provocação / emote com entrada dedicada | Código de suporte (câmera, HUD, som ambiente) |
| Alternância de estado (ex.: acelerar) | Lógica de combate importada — **descartada** (§12.12.1) |

Combo de três golpes na **mesma** entrada é **uma** habilidade, não três.

---

## Consequência para os `Value`s

Cada Tool declara os seus próprios (§12.4). Tools que **dividem recarga** usam a mesma
`ChaveRecarga` — é o que impede o jogador de trocar de Tool na mochila para burlar a recarga
de uma habilidade que deveria ser única.

```
Tool A  ChaveRecarga = "GravidadeTelecinese_Ultimate"
Tool B  ChaveRecarga = "GravidadeTelecinese_Ultimate"   → uma recarga para as duas
```

---

## No relatório de entrega

```
## Distribuição de Tools
  Habilidades encontradas no modelo: N
  Tools geradas: M   (piso 3, teto 7)
  Primárias:  [Tool] ← [habilidade]
  Extras:     [Tool] ← [habilidade excedente]   (motivo do agrupamento)
  Cortadas:   [habilidade] — [motivo]
```
