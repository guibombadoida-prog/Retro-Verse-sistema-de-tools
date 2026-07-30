# _INDICE — Acervo Retro-Verse

Catálogo geral de VFX · SFX · R6 CFrame. **Ler isto antes de criar qualquer efeito novo** (§12.16.2).

> Se já existe algo equivalente aqui, **reusar e adaptar** — não recriar. Esse é o único motivo
> pelo qual o Acervo existe.

---

## VFX

| Efeito | Modelo de origem | Tipo | Status | Já usado em |
|---|---|---|---|---|
| `ONDA_TEMPORAL` | Guardiao_Do_Tempo | Cilindro em expansão, com giro | LIMPO | TemperoTemporal, AvancoRapido, CanhaoCronos, Temporalise, AvoDoTempo |
| `ESFERA_TEMPORAL` | Guardiao_Do_Tempo | Esfera em expansão | LIMPO | TemperoTemporal, Cronostase, CanhaoCronos, Temporalise, ArmadilhaTemporal, AvoDoTempo |
| `MOSTRADOR_TEMPORAL` | Guardiao_Do_Tempo | 12 marcas + ponteiro girando | LIMPO | Cronostase, AvancoRapido, CanhaoCronos, Temporalise, ArmadilhaTemporal, AvoDoTempo |
| `DETRITOS` | Guardiao_Do_Tempo | Estilhaços em parábola | LIMPO | TemperoTemporal, CanhaoCronos, ArmadilhaTemporal, AvoDoTempo |
| `TREMOR` | Guardiao_Do_Tempo | Tremor de câmera por proximidade | LIMPO | as 7 Tools do conjunto |

Módulo único que serve os cinco: `Guardiao_Do_Tempo/VFX/VFXModule_GuardiaoDoTempo.lua`.

## SFX

| Efeito | Modelo de origem | Tipo | Status | Já usado em |
|---|---|---|---|---|
| `IMPACTO_TEMPORAL` | Guardiao_Do_Tempo | 6 IDs — golpe, corte, onda | LIMPO | TemperoTemporal, Cronostase, CanhaoCronos, ArmadilhaTemporal |
| `ENGRENAGEM` | Guardiao_Do_Tempo | 5 IDs — mecanismo, tique | LIMPO | AvancoRapido, CanhaoCronos, Temporalise, ArmadilhaTemporal |
| `BADALADA` | Guardiao_Do_Tempo | 6 IDs — relógio, ultimate | LIMPO | AvoDoTempo |
| `VOZ_GUARDIAO` | Guardiao_Do_Tempo | 2 IDs — fala | LIMPO | AvoDoTempo |

Catálogo com volume, pitch e rolloff: `Guardiao_Do_Tempo/SFX/ids.md`.

## R6 CFRAME

| Pose / sequência | Modelo de origem | Juntas | Status | Já usado em |
|---|---|---|---|---|
| `Poses_GuardiaoDoTempo_TemperoTemporal_V1` | Guardiao_Do_Tempo | 6 · 5 quadros | LIMPO | TemperoTemporal |
| `Poses_GuardiaoDoTempo_Cronostase_V1` | **autoral** | 3 · 3 quadros | LIMPO | Cronostase |
| `Poses_GuardiaoDoTempo_AvancoRapido_V1` | Guardiao_Do_Tempo + autoral | 6 · 4+2 quadros | LIMPO | AvancoRapido |
| `Poses_GuardiaoDoTempo_CanhaoCronos_V1` | Guardiao_Do_Tempo | 6 · 2 quadros | LIMPO | CanhaoCronos |
| `Poses_GuardiaoDoTempo_Temporalise_V1` | Guardiao_Do_Tempo | 6 · 1 quadro | LIMPO | Temporalise |
| `Poses_GuardiaoDoTempo_ArmadilhaTemporal_V1` | Guardiao_Do_Tempo | 6 · 2 quadros | LIMPO | ArmadilhaTemporal |
| `Poses_GuardiaoDoTempo_AvoDoTempo_V1` | Guardiao_Do_Tempo | 6 · 3+2 quadros | LIMPO | AvoDoTempo |
| `R6CFrameAnimator_V2` | **autoral** | infra | APROVADO | as 7 Tools do conjunto |

`R6CFrameAnimator` V2 acrescenta o modo `absoluto = true`, que é o que permite rodar pose de
terceiro sem reinterpretar a convenção de base de quem a escreveu.

---

## Modelos no Acervo

| Pasta | Status | Ficha |
|---|---|---|
| `Guardiao_Do_Tempo/` | **LIMPO** | [FICHA.md](Guardiao_Do_Tempo/FICHA.md) |
| `_AUTORAL_RetroVerse/` | APROVADO | [FICHA.md](_AUTORAL_RetroVerse/FICHA.md) |
| `_MODELO_DE_PASTA/` | molde | — |

---

## Status

| Status | Significado |
|---|---|
| **CRU** | Recém-importado. **Não pode entrar em Tool** |
| **LIMPO** | Passe §12.12.2 executado, aguardando teste em jogo |
| **APROVADO** | Testado. Livre para reuso em qualquer Tool |

## Como depositar

1. `ACERVO_RETROVERSE/[Modelo_De_Origem]/` — criar se não existir, com `FICHA.md` preenchida.
2. `VFX/[NOME_DO_EFEITO]/` ou `SFX/[NOME_DO_EFEITO]/` ou `R6_CFRAME/`.
3. Dentro: o `.lua`, o `.rbxmx` das instâncias e um `NOTAS.md` com parâmetros, escala e custo.
4. Acrescentar a linha na tabela acima.
5. Na entrega, declarar a seção **Delta do Acervo**.

## Convenções de nome (§12.15)

```
Nome_Do_Modelo_De_Origem/      pasta de modelo
NOME_DO_EFEITO/                pasta de efeito — MAIUSCULA_COM_UNDERSCORE
Poses_[Modelo]_V[X].lua        poses R6 CFrame
```
