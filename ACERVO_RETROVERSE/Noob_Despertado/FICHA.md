# Modelo: Noob Despertado — script de FORMAS, não Tool

- Autor original:            **a confirmar** ⚠️
- Origem:                    `noob_despertado.rbxmx`, enviado em 2026-08-14
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-14
- Status:                    **CRU**
- Onde vive:                 `MODELOS_ENTRADA/Noob_Despertado/`

---

## O que é

**Não é uma `Tool`.** É um `Script` de 2650 linhas solto na raiz, mais props de vestir e uma
`ScreenGui` — o formato de "script showcase" que se cola dentro de um Character. Nenhum item
da raiz é `Tool`:

| Classe | Quantos | O que são |
|---|---|---|
| `ParticleEmitter` | 26 | **13 reais** — a pasta `Effects` está DUPLICADA |
| `Part` | 16 | props de vestir (`Bomb`, `Lava`, `RobotPart`, `dominus`, `hat`, `c`) |
| `UnionOperation` | 6 | geometria das formas |
| `LocalScript` | 6 | **3 reais**, também duplicados |
| `SpecialMesh` | 4 | `dominus` e `hat` |
| `TextLabel` | 4 | **2 reais** — dentro da `ScreenGui` |
| `ScreenGui` | 2 | **1 real**, `Talk` |
| `Script` | 1 | o `noob`, com tudo dentro |

**A duplicação é literal:** `Effects` existe como filha do `Script noob` E como `Folder` na
raiz, com o mesmo conteúdo. Metade do arquivo é cópia.

---

## Seis formas, nove ataques

O `KeyDown` despacha por tecla, e o ataque depende do `mode` que a forma ligou:

| Tecla | Liga a forma | `mode` |
|---|---|---|
| `q` | `BanishForm` | `banish` |
| `e` | `MasterForm` **e** `LightForm` ⚠️ | `light` |
| `r` | `DarkForm` | `dark` |
| `t` | `DominusForm` | `dominus` |
| `f` | `RobotForm` | `robot` |

| Tecla | `banish` | `master` | `dark` | `dominus` |
|---|---|---|---|---|
| `z` | `Shot` | `TimeStop` | `Neckless` | `Lunar_Blast` |
| `x` | `Lava` | `BlackRole` | — | `SuperDominus` |
| `c` | `BlastShoot` | `ClockDestroyer` | — | — |

### ⚠️ Três dos nove ataques são inalcançáveis na origem

O `e` cai em **dois `if` separados**, não num `if/elseif`:

```lua
if Key == "e" and ATTACK == false then
	MasterForm()          -- mode = "master"
end
...
if Key == "e" and ATTACK == false then
	LightForm()           -- mode = "light"   <- este vence
end
```

Os dois rodam, e o `LightForm` escreve por último. O `mode` termina `"light"`, e **não existe
ramo `light`** no despacho de ataque. `TimeStop`, `BlackRole` e `ClockDestroyer` — os três
ataques da forma Master — **nunca disparam** no modelo como ele veio.

`robot` também não tem ataque nenhum: é forma de aparência só.

---

## O que vale de verdade: 13 emissores de VAZIO

Penduradas em `Effects`, e é a razão de o modelo ter entrado. **Nenhum efeito de vazio ou
nebulosa existe no Acervo hoje** — os 10 emissores catalogados são raio, estilhaço, brasa,
faísca, aura, e os cinco do Saitama.

| Molde | Emissores | Papel provável |
|---|---|---|
| `VoidCrystal` | `Nebulea1` + `Nebulea2` | o cristal grande |
| `SmallVoidCrystal` | `Nebulea1` + `Nebulea2` | o médio |
| `MiniVoidCrystal` | `Nebulea1` + `Nebulea2` | o pequeno |
| `AttEffects/VoidMagic` | `Nebulea1` + `Nebulea2` | conjuração |
| `AttEffects/VoidExplode` | `Nebulea1` + `Nebulea2` | estouro |
| `AttEffects/VoidExplode2` | `Nebulea1` + `Nebulea2` | estouro grande |
| `AttEffects/Stun` | `StunParticles` | atordoamento |

Três tamanhos do mesmo cristal é escala pronta — o tipo de coisa que o repositório vinha
fazendo com `Size` no tween.

Mais **20 `MeshId`/`TextureId`** distintos e **13 ids de som**, estes últimos criados em
código por `CreateSound(ID, ...)` — **zero `Sound` no XML**, então nenhum vem com volume ou
pitch autorado para copiar.

---

## O passe §12.12.2

| Achado | Quantos |
|---|---|
| `wait(` | **56** |
| `math.random` | 21 |
| `tick()` | 13 |
| `:Destroy()` | 12 |
| `BreakJoints` | **6** |
| `Health =` | 5 |
| `LoadAnimation` | 1 |
| `ScreenGui` | 1 |
| `workspace:GetDescendants()` | 1 |
| `TakeDamage` | **0** ⚠️ |

Os 56 `wait(` são o maior número já visto aqui — o `Swait(NUMBER)` da linha 241 é um laço de
`wait()` usado como base de tempo de tudo.

### `Banish` apaga o personagem

```lua
Foe:Destroy()
CLONE.Parent = Effects
CLONE:BreakJoints()
```

Destrói o alvo e deixa um clone quebrado no lugar. É a mesma família do `death()` do Xester e
do `enemyhum.Parent:Remove()` do Ato de Desaparecer: **matar por deleção tira o abate do
Núcleo e apaga o personagem do jogador**. Vira dano pesado na conversão, como as outras duas.

## Segurança

Zero `loadstring`, zero `require(<id numérico>)`, zero `HttpService`, zero webhook, zero
`getfenv`/`setfenv`, zero `ReplicatedStorage`/`ServerStorage`. **Limpo.**

O `LocalScript` de 23 linhas é o proxy de `UserInputService` por `UserInput_Event`, o mesmo
wrapper "FE bypass" de free model antigo já catalogado nas duas fichas do Xester. Não é
backdoor; é a forma de o script rodar com FilteringEnabled ligado.

---

## Distribuição, se virar Tool

**Nove ataques** → pela `REGRA_DISTRIBUICAO_DE_TOOLS` (piso 3, teto 7) são **7 Tools**, e os
dois excedentes viram habilidade **Extra** na Tool de tema mais próximo.

As seis formas não são habilidade de Tool: `mode` global que troca aparência e desbloqueia
ataque é estado de personagem, e cada Tool aqui é autocontida por definição. O que sobrevive
delas é o **tema** — vazio, tempo, lua, robô — e os props de vestir viram Handle.

## Passe de conformidade §12.12.2 — NÃO EXECUTADO

Este modelo está **CRU**: catalogado e triado, sem conversão. Falta a **licença** (§12.12.3),
e falta o pedido — quais Tools, com que nomes.
