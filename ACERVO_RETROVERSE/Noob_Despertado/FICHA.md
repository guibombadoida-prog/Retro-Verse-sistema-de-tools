# Modelo: Noob Despertado — script de FORMAS, não Tool

- Autor original:            **a confirmar** ⚠️
- Origem:                    `noob_despertado.rbxmx`, enviado em 2026-08-14
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-14
- Status:                    **LIMPO** — passe §12.12.2 executado; falta licença
- Onde vive:                 `MODELOS_ENTRADA/Noob_Despertado/` · as **7 Tools** em `Tools/`

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

## Passe de conformidade §12.12.2 — EXECUTADO

```bash
python3 FERRAMENTAS/preparar_noob.py           # 1 Script solto -> 7 Tools
python3 FERRAMENTAS/gerar_poses_noob.py        # 7 Poses.lua
python3 FERRAMENTAS/gerar_servers_noob.py      # Server · Client · VFX · CutsceneCam
python3 FERRAMENTAS/clonar_tool.py montar ...  # o .rbxmx
python3 FERRAMENTAS/converter_para_rbxm.py ... # a entrega
```

Saíram **7 Tools** — `Noob_7_Tools.rbxm`. Duas têm **cutscene**: `Chuva de Lava` e
`Super Dominus`.

| Tool | Handle | Primária | Extra |
|---|---|---|---|
| `Tiro do Vazio` | `c` | feixe de 220 studs (34) | Disparo — 88, raio 22 |
| `Chuva de Lava` | invisível | a laje: 105 / 46, raio 30 · CUTSCENE | — |
| `Parada do Tempo` | `hat` | trava em raio 26 (18) | Relógio — 42, raio 15 |
| `Buraco Negro` | `RobotPart` | 26 por tique, 4 s | Colapso — 70 |
| `Colar das Trevas` | `RobotPart2` | 14 por tique, 30 ao soltar | — |
| `Explosao Lunar` | invisível | a lua: 62, raio 20 | — |
| `Super Dominus` | `dominus` | a coroa: 130 / 58, raio 34 · CUTSCENE | — |

### Nove ataques viraram 7 primárias e 2 Extras

Pela `REGRA_DISTRIBUICAO_DE_TOOLS`: com 8 ou mais habilidades saem 7 Tools, e o excedente
vira **Extra** na Tool de tema mais próximo. Os dois excedentes são o `BlastShoot` (foi para
o `Tiro do Vazio`) e o `ClockDestroyer` (foi para a `Parada do Tempo`) — os dois do mesmo
tema da primária que os recebeu.

**Quatro das sete não têm Extra**, e é por fidelidade: os modes `dark` e `dominus` da origem
tinham um e dois ataques, e inventar mais seria escrever habilidade que o modelo não tem.

### Os três ataques enterrados entraram

`TimeStop`, `BlackRole` e `ClockDestroyer` só saem no `mode == "master"`, e a tecla `e` que
ligaria a forma cai em **dois `if` seguidos** — `MasterForm()` e depois `LightForm()` — sem
`elseif`. O `mode` termina `"light"`, que não existe no despacho.

Os três estavam escritos, completos, e inalcançáveis. É o oposto do que o FAKER mostrou: lá
eram cinco malhas pagas e nunca acesas; aqui é código.

### O que foi trocado

| Defeito da origem | Conserto |
|---|---|
| **`Banish` faz `Foe:Destroy()`** — apaga o personagem do jogador | `TakeDamage` pesado pelo Núcleo |
| **4 dos 9 ataques com INSTAKILL**, um com 999 de dano em raio 400 | núcleo e borda, na faixa do repositório |
| raio **1000** (`TimeStop`) e **900** (`Lava`) — o mapa inteiro | 26 e 30 |
| **zero `TakeDamage`** em 2650 linhas | `TakeDamage` pelo Núcleo, com fallback |
| **56 `wait(`** — o maior número já visto aqui | `task.wait` e beat do animator |
| 21 `math.random` | ângulo áureo e jitter senoidal por contador |
| 13 `tick()` | `os.clock()` para recarga, acumulador `dt` para animação |
| 6 `BreakJoints` · 5 `Health =` | `PlatformStand` com prazo · `TakeDamage` |
| 12 `:Destroy()` | `Parent = nil` e `Debris:AddItem` |
| `ScreenGui` `Talk` com 2 `TextLabel` | `ContextActionService`, com botão de toque |
| animação em `Motor6D.C0` com `Clerp` | pose CFrame sob `R6CFrameAnimator` |
| `Sound` criado em código com `VOLUME = 10` | 13 `Sound` dentro da Tool, volume 1.2–2.0 |

### O que a origem deu, e ficou

Os **13 emissores de vazio**, os **três cristais em escala**, os **13 ids de som**, os
**props** que viraram Handle em cinco das sete, e o `ClockDestroyer` quase intocado — o único
dos nove cujos números já estavam na faixa.

E um detalhe que vale registrar: o `Neckless` chamava `ApplyDamage(HUM, **0**, true)`. Dano
zero. O agarrão existia, prendia, e não cobrava nada — o oposto dos outros oito, que matavam
de um golpe.

## Para sair de LIMPO e virar APROVADO

Falta a **licença** (§12.12.3) e o teste em jogo. Nada aqui rodou no Studio — a verificação é
toda estática. O que só o jogo confirma: se os emissores de vazio, ligados por `Enabled` +
`Rate` em vez de `:Emit()`, mantêm a cara que tinham na origem.
