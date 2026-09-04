# Modelo: Judgement_Cut_End

- **Autor original:** **não declarado no arquivo** — pendente (§12.12.3)
- **Origem:** `judgement_cut_end.rbxmx`
- **Licença / permissão:** **a confirmar** (§12.12.3)
- **Data de entrada:** 2026-08-04
- **Status: LIMPO (parcial)**
  Passe §12.12.2 executado **só sobre os 3 sons** que entraram em Tool.
  Todo o resto segue **CRU**.
- **Já usado em:** `EscudoPartido` — 3 sons

## O que tem dentro

**193 itens:** 46 `MeshPart` · 34 `RemoteEvent` · 20 `Motor6D` · 17 `Model` ·
16 `ModuleScript` · 12 `ParticleEmitter` · 8 `Sound` · 6 `ColorCorrectionEffect` ·
2 `Animation` · 2 `Highlight`.

**Zero `require(<id numérico>)`** — os 26 `require` são de módulo local. O
material tem 104 `math.random` e 8 `:Emit()`, ambos proibidos, e por isso
**nenhum script foi aproveitado**.

## Aproveitado — 3 sons

| Som | Id | Volume | Virou |
|---|---|---|---|
| `Hit4` | `220834019` | 1 | `Corte` do EscudoPartido |
| `Judgement Cut End Start` | `5989940114` | 6 | `Sentenca` — o golpe mortal |
| `ChangeE` | `10555593530` | 3 | `Estilhaco` |

O quarto som, `Judgement Cut End End`, tem `SoundId = rbxassetid://0` — está
vazio no arquivo de origem, e foi descartado.

## Segue CRU

| | |
|---|---|
| 46 `MeshPart` | lâmina, katana (`11179657725/8005/8468`), `SlashTimeStop` (`8879875562`), gradientes |
| 12 `ParticleEmitter` | texturas `7994629137`, `7216848832`, `2866648598`, `3916186365` |
| 6 `ColorCorrectionEffect` | **proibidos por regra** — pós-processamento é global e vaza da Tool |
| 2 `Animation` | **proibidos por regra** — animação é tabela de poses CFrame |
| 16 `ModuleScript` | 104 `math.random`, 8 `:Emit()` |

Os meshes de lâmina são o material mais interessante aqui e valem uma passada
futura — mas `MeshId` de terceiro sem licença declarada não entra em Tool.
