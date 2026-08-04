# _INDICE — Acervo Retro-Verse

Catálogo geral de VFX · SFX · R6 CFrame. **Ler isto antes de criar qualquer efeito novo** (§12.16.2).

> Se já existe algo equivalente aqui, **reusar e adaptar** — não recriar. Esse é o único motivo
> pelo qual o Acervo existe.

---

## VFX

### Emissores — `ParticleEmitter` de verdade

| Efeito | Origem | Emissores | Status | Usado em |
|---|---|---|---|---|
| `RAIO_TEMPORAL` | Jupiter | `Plasma` + `Clarao` | LIMPO | PulsoGravitacional, MaoTelecinetica, LancaVetorial |
| `ESTILHACO_ESTELAR` | Cosmic Entity | `Estrelas` + `Cintilar` | LIMPO | CampoZeroG, MarionetePsi |
| `BRASA` | Cosmic Entity | `Brasa` + `Fumaca` | LIMPO | PocoDeMassa |
| `FAISCA` | Cosmic + Jupiter | `Faisca` + `Anel` | LIMPO | MaoTelecinetica, OrbitaPsi, LancaVetorial, MarionetePsi |
| `AURA` | Jupiter | `Aura` | LIMPO | as 7 do conjunto Gravidade / Telecinese, Bloqueador, Proteção, Salvador |
| `ESTILHACO_ESCUDO` | **Saitama** / Death Counter | `Estilhaco` | LIMPO | Bumerangue, Skate, Partido |
| `CLARAO_ESCUDO` | **Saitama** / Normal Uppercut | `Clarao` | LIMPO | Bloqueador, Proteção, Salvador, Partido |
| `ONDA_ESCUDO` | **Saitama** / Serious Punch | `Onda` | LIMPO | Ciclone, Partido |
| `IMPACTO_ESCUDO` | **Saitama** / Death Counter | `Impacto` | LIMPO | as 7 do conjunto Escudos |
| `POEIRA_ESCUDO` | **Saitama** / Serious Mode | `Poeira` | LIMPO | Skate, Ciclone |

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
| `IMPACTO` | **autoral** | Estilhaços subindo do ponto de contato | LIMPO | as 7 de Gravidade / Telecinese |
| `IMPACTO_NOVA` | **autoral** | Anel de choque expandindo no plano do chão | LIMPO | as 7 de Gravidade / Telecinese |
| `ESCUDO` | **autoral** | Disco que aparece, gira e some | LIMPO | Bloqueador |
| `LAMINA` | **autoral** | Risco de corte, ângulo por índice sequencial | LIMPO | Bumerangue, Partido |
| `ANEL` | **autoral** | Anel de choque no plano do chão | LIMPO | conjunto Escudos (fallback) |
| `ESTILHACOS` | **autoral** | 10 cacos em ângulo áureo, com queda parabólica | LIMPO | Ciclone, Partido |

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
| _(21 sons)_ | Jupiter_Great_Pressure_Sword | Raio, espada, invocação, impacto | LIMPO (parcial) | conjunto Gravidade / Telecinese |
| _(15 sons)_ | Sword_of_Cosmic_Entity | Supernova, shuriken, teleporte, corte | LIMPO (parcial) | conjunto Gravidade / Telecinese |
| _(7 sons)_ | Danilo_Escudos | Bloqueio, impacto, equipar, proteção, sacrifício | LIMPO | conjunto Escudos |
| _(3 sons)_ | Judgement_Cut_End | Corte, sentença, estilhaço | LIMPO (parcial) | EscudoPartido |

Cada Tool do conjunto Gravidade / Telecinese usa **um** som de golpe, escolhido destes dois
catálogos. O resto segue depositado e disponível.

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
| `Poses_GravidadeTelecinese_*_V1` | **autoral** (do molde) | 4 · 2+2+2 quadros | LIMPO | as 7 do conjunto |
| `Poses_Escudos_*_V1` | **autoral** | 4–6 · 3 a 6 poses por Tool | LIMPO | as 7 do conjunto Escudos |
| `R6CFrameAnimator_V2` | **autoral** (superset do V1) | infra | **APROVADO** | as 14 Tools + o molde |
| `R6CFrameAnimator_V1` | **His Cube** (produção) | infra | APROVADO | referência histórica |
| `SaitamaAnimacoes_Originais_V1` | Saitama_Animacoes_Referencia | 2417 kf · 9 seq + 1 câmera | **CRU** | nada — é consulta |

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
| `SeriousMode_CutsceneCam_V1` | **autoral** | órbita bezier + contraste de FOV | LIMPO | molde do `EscudoPartido/CutsceneCam` |

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
