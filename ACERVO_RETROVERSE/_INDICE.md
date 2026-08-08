# _INDICE — Acervo Retro-Verse

> **38 Tools no repositório**: 7 de `Danilo_Escudos_V4`, 5 de `Astral_Peria`,
> 6 de `Bomba_V4`, 7 de `Xester_Forma1`, 7 de `Xester_Forma2_O_Despertar` e as
> **6 do conjunto SUBMUNDO — o primeiro AUTORAL do repositório**, que não sai de
> modelo nenhum: sai daqui. Ver `Tools/README.md`.
>
> A única entrada do Acervo que elas consomem é o **`Stella_VFX_Addon`**, cujos
> 10 efeitos conformados são **copiados para dentro** de cada Tool na montagem
> (`VFXModule/Pack/`). Nenhuma Tool lê o Acervo em runtime — nem ele, nem nada.
>
> Nas 14 do Xester o pack não é reforço: é **quem desenha**. Onda, nova,
> explosão, corte, anel, rachadura, feixe e espiral saem dele. O que sobrou de
> código próprio no `VFXModule` delas é a carta — que o pack não tem, porque é a
> assinatura do personagem — e o fallback de cada efeito.

Catálogo geral de VFX · SFX · R6 CFrame. **Ler isto antes de criar qualquer efeito novo** (§12.16.2).

> Se já existe algo equivalente aqui, **reusar e adaptar** — não recriar. Esse é o único motivo
> pelo qual o Acervo existe.

---

## VFX

### Emissores — `ParticleEmitter` de verdade

| Efeito | Origem | Emissores | Status | Usado em |
|---|---|---|---|---|
| `RAIO_TEMPORAL` | Jupiter | `Plasma` + `Clarao` | LIMPO | — (nenhuma Tool no repositório) |
| `ESTILHACO_ESTELAR` | Cosmic Entity | `Estrelas` + `Cintilar` | LIMPO | — (nenhuma Tool no repositório) |
| `BRASA` | Cosmic Entity | `Brasa` + `Fumaca` | LIMPO | — (nenhuma Tool no repositório) |
| `FAISCA` | Cosmic + Jupiter | `Faisca` + `Anel` | LIMPO | — (nenhuma Tool no repositório) |
| `AURA` | Jupiter | `Aura` | LIMPO | — (nenhuma Tool no repositório) |
| `ESTILHACO_ESCUDO` | **Saitama** / Death Counter | `Estilhaco` | LIMPO | — (nenhuma Tool no repositório) |
| `CLARAO_ESCUDO` | **Saitama** / Normal Uppercut | `Clarao` | LIMPO | — (nenhuma Tool no repositório) |
| `ONDA_ESCUDO` | **Saitama** / Serious Punch | `Onda` | LIMPO | — (nenhuma Tool no repositório) |
| `IMPACTO_ESCUDO` | **Saitama** / Death Counter | `Impacto` | LIMPO | — (nenhuma Tool no repositório) |
| `POEIRA_ESCUDO` | **Saitama** / Serious Mode | `Poeira` | LIMPO | — (nenhuma Tool no repositório) |

Vivem em `Tool/Efeitos/<TIPO>` e são ligados por `Enabled` + `Rate` — **zero `:Emit()`**.
`:Emit()` dispara uma leva fixa e ignora o `Rate` autorado; a curva extraída do modelo de
origem se perde, e o efeito fica com outra cara.

As curvas (Size, Transparency, Rate, Speed, Lifetime) são as do modelo de origem; a **cor**
foi trocada para a paleta do repositório, que é o que costura material de dois modelos
diferentes no mesmo conjunto.

> **Dois dos cinco do Saitama NÃO são tingidos** — e é de propósito.
> `ESTILHACO_ESCUDO` é escuro porque é isso que faz ler como metal quebrando, e
> `POEIRA_ESCUDO` guarda o cinza `100,102,115` do original. Tingir os dois de azul
> viraria caco de escudo em faísca mágica, e fumaça em névoa.

> ⚠️ Ter o molde dentro da Tool **não basta**: alguém tem de ligá-lo. Os emissores de
> `RAIO_TEMPORAL` e `AURA` estavam dentro das 7 Tools de gravidade sem nenhuma função no
> `VFXModule` que os acendesse. `VFX.executar` faz `VFX[tipo]`, não acha, e volta calado.
> `TESTES/verificar_rbxmx.py` agora pega isso.

### Procedurais — sem molde, feitos em código

| Efeito | Origem | Tipo | Status | Usado em |
|---|---|---|---|---|
| `IMPACTO` | **autoral** | Estilhaços subindo do ponto de contato | LIMPO | — (nenhuma Tool no repositório) |
| `IMPACTO_NOVA` | **autoral** | Anel de choque expandindo no plano do chão | LIMPO | — (nenhuma Tool no repositório) |
| `ESCUDO` | **autoral** | Disco que aparece, gira e some | LIMPO | — (nenhuma Tool no repositório) |
| `LAMINA` | **autoral** | Risco de corte, ângulo por índice sequencial | LIMPO | — (nenhuma Tool no repositório) |
| `ANEL` | **autoral** | Anel de choque no plano do chão | LIMPO | — (nenhuma Tool no repositório) |
| `ESTILHACOS` | **autoral** | 10 cacos em ângulo áureo, com queda parabólica | LIMPO | — (nenhuma Tool no repositório) |

Dispersão por **ângulo áureo (Vogel)** por índice sequencial — nunca `math.random`.

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

### O que sobrou CRU nos modelos de VFX

| Origem | Total | Já aproveitado | Segue CRU |
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
| _(21 sons)_ | Jupiter_Great_Pressure_Sword | Raio, espada, invocação, impacto | LIMPO | — (nenhuma Tool no repositório) |
| _(15 sons)_ | Sword_of_Cosmic_Entity | Supernova, shuriken, teleporte, corte | LIMPO | — (nenhuma Tool no repositório) |
| _(7 sons)_ | Danilo_Escudos | Bloqueio, impacto, equipar, proteção, sacrifício | LIMPO | — (nenhuma Tool no repositório) |
| _(3 sons)_ | Judgement_Cut_End | Corte, sentença, estilhaço | LIMPO | — (nenhuma Tool no repositório) |

Catálogo com volume, pitch e rolloff: o `SFX/ids.md` de cada pasta.

> ⚠️ **Esta tabela e as fichas se contradizem.** Aqui os SFX de Jupiter e de
> Cosmic Entity aparecem como **LIMPO**; o `SFX/ids.md` de cada um diz **CRU**
> no cabeçalho. Enquanto os dois não concordarem, nenhuma Tool puxa som de lá —
> o conjunto SUBMUNDO usa os ids do `Xester_Forma1`, cuja ficha está fechada
> nos quatro campos de §12.12.3.

> ⚠️ **`Explode` do `bomba_v4` aponta para `rbxassetid://200`.** Não é id
> válido de som — vem assim da origem, não da conversão. As 6 Tools de bomba e
> o `Atraso Mortal` carregam esse Sound mudo. Trocar o id resolve; está aqui
> para não se perder.

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
| `R6CFrameAnimator_V2` | **autoral** (superset do V1) | infra | **APROVADO** | toda Tool nova nasce nele |
| `R6CFrameAnimator_V1` | **His Cube** (produção) | infra | APROVADO | referência histórica |
| `SaitamaAnimacoes_Originais_V1` | Saitama_Animacoes_Referencia | 2417 kf · 9 seq + 1 câmera | **CRU** | nada — é consulta |
| `Poses_Xester_Forma1_V1` | Xester_Forma1 (extraída) | 12 seq · guarda + ação | **LIMPO** | 7 Tools da Forma 1 |
| `Poses_Xester_Forma2_V1` | Xester_Forma2 (extraída) | 8 seq · guarda de cajado | **LIMPO** | 7 Tools da Forma 2 |
| `Poses_Submundo_V1` | **autoral** | 6 seq · conjurador com cajado | **APROVADO** | 6 Tools do Submundo |

> ⚠️ **`R6CFrameAnimator_V2` é O animator do projeto. Não escreva outro.**
> Ele cria `Weld`s próprios; escrever em `Motor6D.C0` briga com o script `Animate`
> padrão do Roblox e **buga a animação** — dois donos por junta, e a pose treme e volta
> sozinha. Já aconteceu neste repositório.
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
| `SeriousMode_CutsceneCam_V1` | **autoral** | órbita bezier + contraste de FOV | LIMPO | — (nenhuma Tool no repositório) |

Câmera é **100% cliente**: o servidor manda beat nomeado (`START`/`ORBIT`/`CLOSE`/`PUNCH`/
`STOP`), nunca `CFrame`. `workspace.CurrentCamera` é singleton por cliente e **não** viola a
Regra nº 1 — mas só em `LocalScript`, e sempre devolvida em `Unequipped`/`Destroying`.

Ver [`_AUTORAL_RetroVerse/CAMERA/NOTAS.md`](_AUTORAL_RetroVerse/CAMERA/NOTAS.md) e
`DIRETRIZES/REGRA_CAMERA_DE_CUTSCENE.md`.

---

## Modelos no Acervo

| Pasta | Status | Ficha |
|---|---|---|
| `Danilo_Escudos/` | **LIMPO** | [FICHA.md](Danilo_Escudos/FICHA.md) |
| `Judgement_Cut_End/` | **LIMPO** (parcial) | [FICHA.md](Judgement_Cut_End/FICHA.md) |
| `Domain_Expansion_Elemental/` | **CRU** | [FICHA.md](Domain_Expansion_Elemental/FICHA.md) |
| `Jupiter_Great_Pressure_Sword/` | **LIMPO** (parcial) | [FICHA.md](Jupiter_Great_Pressure_Sword/FICHA.md) |
| `Sword_of_Cosmic_Entity/` | **LIMPO** (parcial) | [FICHA.md](Sword_of_Cosmic_Entity/FICHA.md) |
| `VFX_Library_V2/` | **CRU** | [FICHA.md](VFX_Library_V2/FICHA.md) |
| `Saitama_Animacoes_Referencia/` | **CRU** | [FICHA.md](Saitama_Animacoes_Referencia/FICHA.md) |
| `Danilo_Escudos_V4/` | **APROVADO** — base das 7 Tools | [FICHA.md](Danilo_Escudos_V4/FICHA.md) |
| `Astral_Peria/` | **LIMPO** — base das 5 Tools astrais | [FICHA.md](Astral_Peria/FICHA.md) |
| `Bomba_V4/` | **LIMPO** — base das 6 Tools de bomba | [FICHA.md](Bomba_V4/FICHA.md) |
| `Stella_VFX_Addon/` | **LIMPO** — 10 efeitos conformados, dentro das 38 Tools | [FICHA.md](Stella_VFX_Addon/FICHA.md) |
| `VFX_Pack_Meshes/` | **CRU** — só malha, sem script | [FICHA.md](VFX_Pack_Meshes/FICHA.md) |
| `His_Cube/` | **CRU** — referência de CFrame R6, nada extraído | [FICHA.md](His_Cube/FICHA.md) |
| `Xester_Forma1/` | **LIMPO** — base das 7 Tools da Forma 1 | [FICHA.md](Xester_Forma1/FICHA.md) |
| ↳ o baralho `cards` | serve **as duas** formas: Handle e moldes de carta da Forma 1 saem dele | — |
| `Xester_Forma2_O_Despertar/` | **LIMPO** — base das 7 Tools da Forma 2 | [FICHA.md](Xester_Forma2_O_Despertar/FICHA.md) |
| `_AUTORAL_RetroVerse/` | APROVADO | [FICHA.md](_AUTORAL_RetroVerse/FICHA.md) |
| `_MODELO_DE_PASTA/` | molde | — |

> **Xester — os dois estão LIMPO.** Ficha completa nos quatro campos de §12.12.3,
> e nenhum script da origem entrou nas Tools: a lógica foi reescrita, e da origem
> vieram asset e número. A triagem de segurança está na ficha de cada um — são
> wrappers de "FE bypass" de free model antigo, sem `loadstring`, sem
> `require(<id>)`, sem `HttpService` e sem webhook.

> Três das quatro pastas novas são **fichas de registro**, não depósito: o material delas
> vive em `ReplicatedStorage/` (Stella, malhas) ou ficou só em `MODELOS_ENTRADA/` (His Cube).
> O Acervo é prateleira de **edição**; o pack compartilhado é dependência de **runtime**.
> A ficha existe para o §12.12.3 — autor, origem, licença, data — não para reserva.

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
