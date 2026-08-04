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

### Acrescentados ao Guardião do Tempo na V2 — emissores de verdade

| Efeito | Origem | Emissores | Status | Usado em |
|---|---|---|---|---|
| `RAIO_TEMPORAL` | Jupiter | `Plasma` + `Clarao` | LIMPO | CanhaoCronos, AvoDoTempo |
| `ESTILHACO_ESTELAR` | Cosmic Entity | `Estrelas` + `Cintilar` | LIMPO | TemperoTemporal, Cronostase, Temporalise, AvoDoTempo |
| `BRASA` | Cosmic Entity | `Brasa` + `Fumaca` | LIMPO | AvancoRapido, Temporalise, ArmadilhaTemporal, AvoDoTempo |
| `FAISCA` | Cosmic + Jupiter | `Faisca` + `Anel` | LIMPO | TemperoTemporal, AvancoRapido, CanhaoCronos, ArmadilhaTemporal, AvoDoTempo |
| `AURA` | Jupiter | `Aura` | LIMPO | as 7 Tools |

Estes usam `ParticleEmitter` **de verdade**, dentro de `Tool/Efeitos/<TIPO>`, ligados por
`Enabled` — zero `:Emit()`. As curvas (Size, Transparency, Rate, Speed, Lifetime) são as do
modelo de origem; a **cor** foi trocada para a paleta do Guardião, que é o que costura
material de dois modelos diferentes no mesmo conjunto.

### `VFX_Library_V2` — a maior entrada do Acervo, ainda CRU

| | |
|---|---|
| Habilidades | **38**, em 7 pastas de personagem |
| Emissores | **782** `ParticleEmitter` (416 únicos), 81 `Trail`, 14 `Beam` |
| Malhas | 87 `MeshPart` · 15 `SpecialMesh` · 32 `UnionOperation` |
| Catálogo | [`CATALOGO_POR_HABILIDADE.md`](VFX_Library_V2/CATALOGO_POR_HABILIDADE.md) diz qual efeito é de qual habilidade |
| Status | **CRU** — nada entrou em Tool ainda |

> ⚠️ **Não rode o arquivo cru num place de produção.** Tem 13 `require(<id numérico>)`
> — execução de código remoto — além de 152 `BreakJoints` e 1113 `math.random`.
> Ver a `FICHA.md`. O material **visual** é excelente; o código que vem junto, não.

### O que sobrou CRU nos dois modelos

| Origem | Total | Aproveitado na V2 | Segue CRU |
|---|---|---|---|
| `Jupiter_Great_Pressure_Sword` | 19 `ParticleEmitter` · 3 `Highlight` · 1 `Trail` | 4 emissores | o resto, inclusive o `LightningBolt` completo |
| `Sword_of_Cosmic_Entity` | 26 `ParticleEmitter` · 6 `Trail` · 1 `Highlight` | 5 emissores | o resto, inclusive `Nova_Circle`, `MegaWave`, `ShurikenModel` |

Os parâmetros de verdade (Rate, Lifetime, Speed, Size, Transparency, Color, Texture)
estão em `VFX/NOTAS.md` de cada pasta — dá para reconstruir o efeito só com a tabela.

> **CRU não entra em Tool.** Falta o passe §12.12.2 e faltam dois dos quatro campos
> de origem (autor e licença). Ver a `FICHA.md` de cada um.

## SFX

| Efeito | Modelo de origem | Tipo | Status | Já usado em |
|---|---|---|---|---|
| `IMPACTO_TEMPORAL` | Guardiao_Do_Tempo | 6 IDs — golpe, corte, onda | LIMPO | TemperoTemporal, Cronostase, CanhaoCronos, ArmadilhaTemporal |
| `ENGRENAGEM` | Guardiao_Do_Tempo | 5 IDs — mecanismo, tique | LIMPO | AvancoRapido, CanhaoCronos, Temporalise, ArmadilhaTemporal |
| `BADALADA` | Guardiao_Do_Tempo | 6 IDs — relógio, ultimate | LIMPO | AvoDoTempo |
| `VOZ_GUARDIAO` | Guardiao_Do_Tempo | 2 IDs — fala | LIMPO | AvoDoTempo |
| _(21 sons)_ | Jupiter_Great_Pressure_Sword | Raio, espada, invocação, impacto | LIMPO (4 em uso) | CanhaoCronos, AvancoRapido, AvoDoTempo |
| _(15 sons)_ | Sword_of_Cosmic_Entity | Supernova, shuriken, teleporte, corte | LIMPO (7 em uso) | as 7 Tools |

Catálogo com volume, pitch e rolloff: o `SFX/ids.md` de cada pasta.

## MALHAS E TEXTURAS

| Origem | Itens | Status |
|---|---|---|
| `Jupiter_Great_Pressure_Sword` | 7 `MeshId`/`TextureId` | **CRU** |
| `Sword_of_Cosmic_Entity` | 16 `MeshId`/`TextureId` | **CRU** |

> **Reuso cruzado já detectado:** `rbxassetid://863344136` é o mesmo mesh no
> `Shockwave_2` do Jupiter e no `MegaWave` do Sword of Cosmic Entity. Converter uma vez
> serve as duas — que é exatamente para isso que o Acervo existe (§12.16.5).

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
| `R6CFrameAnimator_V2` | **autoral** (superset do V1) | infra | **APROVADO** | as 7 Tools + o molde |
| `R6CFrameAnimator_V1` | **His Cube** (produção) | infra | APROVADO | referência histórica |
| `SaitamaAnimacoes_Originais_V1` | Saitama_Animacoes_Referencia | 2417 kf · 9 seq + 1 câmera | **CRU** | nada — é consulta |

> ⚠️ **`R6CFrameAnimator_V2` é O animator do projeto. Não escreva outro.**
> Ele cria `Weld`s próprios; escrever em `Motor6D.C0` briga com o script `Animate`
> padrão do Roblox e **buga a animação** — foi o que aconteceu na primeira versão do
> Guardião do Tempo.
>
> V2 é **superset do V1**: mesma API, mesmas bases, mesmos nomes de junta — toda tabela
> de poses do V1 roda no V2 sem alteração. Acrescenta perna sob demanda, `PlaySequence`,
> `PlayTrack`, tremor determinístico e `LockCharacter`. O V1 fica como referência.
>
> Nota: houve um `V2` **meu**, baseado em `Motor6D`, removido do Acervo por ser a versão
> errada. O V2 que está aqui não é aquele — não tem parentesco com o arquivo removido.
>
> Ver [`_AUTORAL_RetroVerse/R6_CFRAME/NOTAS.md`](_AUTORAL_RetroVerse/R6_CFRAME/NOTAS.md)
> e `DIRETRIZES/REGRA_ANIMACAO_R6.md`.

## CÂMERA

| Molde | Origem | Tipo | Status | Já usado em |
|---|---|---|---|---|
| `SeriousMode_CutsceneCam_V1` | **autoral** | órbita bezier + contraste de FOV | LIMPO | nenhuma Tool ainda |

Câmera é **100% cliente**: o servidor manda beat nomeado (`START`/`ORBIT`/`CLOSE`/`PUNCH`/
`STOP`), nunca `CFrame`. `workspace.CurrentCamera` é singleton por cliente e **não** viola a
Regra nº 1 — mas só em `LocalScript`, e sempre devolvida em `Unequipped`/`Destroying`.

Ver [`_AUTORAL_RetroVerse/CAMERA/NOTAS.md`](_AUTORAL_RetroVerse/CAMERA/NOTAS.md) e
`DIRETRIZES/REGRA_CAMERA_DE_CUTSCENE.md`.

---

## Modelos no Acervo

| Pasta | Status | Ficha |
|---|---|---|
| `Guardiao_Do_Tempo/` | **LIMPO** | [FICHA.md](Guardiao_Do_Tempo/FICHA.md) |
| `Jupiter_Great_Pressure_Sword/` | **LIMPO** (parcial) | [FICHA.md](Jupiter_Great_Pressure_Sword/FICHA.md) |
| `Sword_of_Cosmic_Entity/` | **LIMPO** (parcial) | [FICHA.md](Sword_of_Cosmic_Entity/FICHA.md) |
| `VFX_Library_V2/` | **CRU** | [FICHA.md](VFX_Library_V2/FICHA.md) |
| `Saitama_Animacoes_Referencia/` | **CRU** | [FICHA.md](Saitama_Animacoes_Referencia/FICHA.md) |
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

Modelo binário (`.rbxm`) ou XML — a ferramenta faz o depósito inteiro:

```bash
python3 FERRAMENTAS/extrair_rbxm.py <arquivo.rbxm>              # inspecionar
python3 FERRAMENTAS/depositar_no_acervo.py <arquivo> <Nome_Do_Modelo>
```

Ela gera `FICHA.md`, `VFX/NOTAS.md`, `SFX/ids.md`, `MALHAS/ids.md` e
`LOGICA/HABILIDADES.md`. O status sai **CRU** — quem preenche origem e roda o passe
§12.12.2 é gente, não o script.

À mão, se preferir:

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
