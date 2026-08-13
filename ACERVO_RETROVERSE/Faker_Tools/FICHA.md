# Modelo: Faker Tools — o His Cube ORIGINAL

- Autor original:            **a confirmar** ⚠️
- Origem:                    `Faker_tools.rbxmx`, enviado no lote de 2026-08-13
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **LIMPO** — passe §12.12.2 executado; falta licença
- Onde vive:                 `MODELOS_ENTRADA/Faker_Tools/` · as **7 Tools** em `Tools/` · notas em `VFX/NOTAS.md`

---

## O que é, e por que o nome do arquivo está certo

Uma `Tool` chamada `His Cube` — a **terceira** entrega do His Cube a chegar aqui. E é a mais
importante das três, porque é a **origem**: as outras duas já eram nossa conversão de volta.

| | `Faker_Tools` | `His_Cube` (V1) | `His_Cube_V2` |
|---|---|---|---|
| `Shoot` (servidor) | **40 linhas** | 830 | 830 |
| onde vive a habilidade | `AbbilityClient` + `Client`, **no cliente** | servidor | servidor |
| `TakeDamage` / `Health =` | **zero** | sim | sim |
| pack Stella | não | 40 `ModuleScript` | 40 `ModuleScript` |
| `Vfx pack` | não | não | 121 filhos |

### O `Shoot` inteiro tem 40 linhas, e não causa dano nenhum

```lua
remote.OnServerEvent:Connect(function()
	remote1:FireAllClients()
end)

remote2.OnServerEvent:Connect(function(Client, Key)
	if Client ~= Player or ... then return end
	if Key == Enum.KeyCode.Q then
		if cd1 == false then
			remote3:FireAllClients()
			...delay(15, function() cd1 = false end)
		end
	end
end)
```

É só isto: o servidor recebe um aviso e retransmite. **Nenhuma linha do modelo aplica dano** —
o scan não achou um único `TakeDamage` nem uma escrita em `Health`.

Toda a habilidade está em `AbbilityClient` (365 linhas) e `Client` (431 linhas), do lado do
cliente. Ou seja: **é uma casca de VFX.** Bonita, e sem combate.

Por isso o nome do arquivo faz sentido. Não é acusação de plágio — é a descrição técnica do
que ele é: **fake**, no sentido de que o efeito acontece e nada muda no jogo.

### E o que ele mostra sobre o próprio repositório

A conversão que este repositório fez do His Cube não "melhorou" o original — ela **escreveu o
combate que não existia**. Vale registrar, porque é o tipo de coisa que se esquece: as 830
linhas do nosso `Shoot` não são um refactor das 40, são código novo.

---

## O que vale de verdade: 7 `MeshPart` de VFX

Penduradas no `AbbilityClient`, e é a razão de o modelo ter entrado:

| Mesh | Provável papel |
|---|---|
| `Sphere` | núcleo da explosão |
| `Mushroom` | o cogumelo |
| `Ring` | anel de choque |
| `Spiral` | espiral |
| `WindSphere` | domo de vento |
| `E` · `Erlo` | (nome não diz; conferir no Studio) |

`Sphere` e `Mushroom` já vieram na V1 e estão em uso. As **outras cinco são novas** —
`Ring`, `Spiral` e `WindSphere` cobrem exatamente três formas que o `VFXModule` das Tools
desenha hoje com `Part` primitiva e Tween.

Ver `VFX/NOTAS.md`.

---

## O passe §12.12.2

| Achado | Quantos |
|---|---|
| `math.random` | **67** |
| `spawn(` | 20 |
| `:Destroy()` | 18 |
| `wait()` | 15 |
| `delay(` | 2 |

67 `math.random` em 859 linhas é a maior densidade de sorteio que já entrou — e faz sentido,
porque é VFX puro, onde variação aleatória é a técnica. Na conversão vira ângulo áureo e
jitter senoidal por contador, que é o que garante que **os dois clientes vejam a mesma coisa**.

**Nenhum** `ScreenGui`, `BreakJoints`, `Lighting` ou varredura de `workspace`. Para uma casca
de VFX de 859 linhas, é surpreendentemente contido.

## Segurança

Zero `loadstring`, zero `require(<id numérico>)`, zero `HttpService`, zero webhook, zero
`getfenv`/`setfenv`, e **zero referência a qualquer depósito fora da Tool**. É o modelo mais
limpo desse ponto de vista que já chegou.

## "Não vira Tool nova" — REVERTIDO em 2026-08-13, a pedido

Esta ficha dizia, ao entrar: *"Já existe His Cube convertido neste repositório. Este entra
como fonte de VFX e como registro do que o original era."*

O usuário pediu o contrário, e o pedido está certo. O que ele pediu foram **sete Tools
nomeadas** — e duas delas são os nomes que **o próprio modelo usa**:

```lua
Services.Input:SetTitle("Primary",   "Ultra Combo")        -- Q
Services.Input:SetTitle("Secondary", "An end of an Era")   -- E
```

`T1: Ultra Combo` e `T2: Era Do Fim` não foram inventados no pedido; foram lidos de dentro do
arquivo. As sete não competem com o His Cube convertido: aquelas são Tools de **cubo**, estas
são de **vazio** — sala, prisão, poço, entidade, e o cogumelo de 522 studs.

---

## Passe de conformidade §12.12.2 — EXECUTADO

```bash
python3 FERRAMENTAS/preparar_faker.py          # 1 Tool -> 7
python3 FERRAMENTAS/gerar_poses_faker.py       # 7 Poses.lua
python3 FERRAMENTAS/gerar_servers_faker.py     # Server · Client · VFX · CutsceneCam
python3 FERRAMENTAS/clonar_tool.py montar ...  # o .rbxmx
python3 FERRAMENTAS/converter_para_rbxm.py ... # a entrega
```

Saíram **7 Tools** — `Faker_7_Tools.rbxm`. Duas têm **cutscene**: `Era Do Fim` e
`Faker Entity`.

### O conserto é de VISIBILIDADE, e foi o que o usuário pediu por escrito

> *"faço com que os efeitos apareça para todos não esqueça disso"*

Não é preferência de estilo — é o defeito central da origem, e ele tem duas metades:

| Metade | Na origem | Aqui |
|---|---|---|
| quem DESENHA | `Client` (431 linhas) e `AbbilityClient` (365), os dois **LocalScript** | `Script` com `RunContext = Client`, que roda em TODO cliente |
| quem manda desenhar | o cliente, para si mesmo | o **servidor**, por `VFXRemote:FireAllClients` |

LocalScript dentro de Tool só roda para o jogador cujo Character a contém. As 796 linhas de
VFX da origem aconteciam **só na tela de quem segurava a Tool** — para o resto do servidor a
habilidade era invisível. E como o `Shoot` tinha 40 linhas e nenhum `TakeDamage`, também não
fazia nada.

Nada saiu de dentro da Tool para consertar isso. A Regra nº 1 está intacta.

### As cinco malhas que a origem nunca ligou

O `AbbilityClient` carrega sete `MeshPart`/`UnionOperation`, e o código de origem usa **duas**:
`Sphere` (3 clones) e `Mushroom` (1). As outras cinco estão lá, pagas, e nunca acesas. Elas são
o motivo de o conjunto existir, e o **tamanho** de cada uma decidiu para onde ela foi:

| Malha | Tamanho | O que é | Vai para |
|---|---|---|---|
| `E` | 9.9 × **1.0** × 9.9 | disco chato | Ultra Combo · Faker Entity |
| `Erlo` | 5³ | bloco cúbico | Prisao Cubica |
| `Sphere` | 4³ | esfera | Prisao Cubica · Faker Entity |
| `Spiral` | 33 × 17 × 40 | espiral | Ilusao · Abismo Profundo |
| `WindSphere` | 9.9³ | domo | Sala Do Abismo |
| `Ring` | **500** × 48 × 500 | anel gigante | Era Do Fim · Abismo Profundo |
| `Mushroom` | **522 × 543 × 522** | cogumelo | Era Do Fim |

`Ring` e `Mushroom` são duas ordens de grandeza maiores que tudo que já entrou aqui. Não são
efeito de golpe, são efeito de **evento** — e por isso só as duas Tools de escala grande as
usam.

Elas vivem em `Tool/Moldes/`, **invisíveis** (`Transparency = 1`, `Anchored`, sem colisão). Quem
aparece é o clone, aceso pelo `VFXModule` na execução. É a regra que o usuário fixou: *"deixar
os vfx invisível dentro da tool, e visível na execução da habilidade"*.

### A cutscene é de AFASTAMENTO, não de aproximação

O conjunto DRAMA fecha a câmera na cara do alvo — `Corte Frio` tem FOV 44 no quadro mais
apertado. Aqui é o oposto, e o motivo é o tamanho: fechar a câmera num cogumelo de 522 studs
mostra uma parede preta. O beat `DETONA` joga a câmera para 42 studs e abre o FOV para 100.

A regra 1 continua valendo — o FOV é a técnica, e a amplitude (52) é a mesma do `Corte Frio`.
Só a direção do estouro é para fora.

A `CutsceneCam_Faker` ganhou um terceiro alvo de foco que o DRAMA não tinha: **`cima`**, que
aponta `alto` studs acima de quem conjurou. É assim que a câmera acompanha o cogumelo subindo
e a entidade nascendo, sem precisar de uma `Part` no mundo para mirar.

E a plateia é diferente: no DRAMA a cena é entre **dois**, porque é execução de um alvo; aqui
é evento de área, então todo mundo dentro do raio recebe o papel `ALVO`. Quem está fora não
perde a câmera, que é o ponto da regra 2.

### O que foi trocado

| Defeito da origem | Conserto |
|---|---|
| **796 linhas de habilidade em LocalScript** — efeito só na tela do portador | `RunContext = Client` + `FireAllClients` |
| **zero `TakeDamage`, zero `Health =`** nas 859 linhas | `TakeDamage` pelo Núcleo, com fallback |
| **67 `math.random`** | ângulo áureo e jitter senoidal por contador |
| 20 `spawn(` · 15 `wait()` · 2 `delay(` | `task.spawn` · `task.wait` · `task.delay` |
| 18 `:Destroy()` | `Parent = nil` e `Debris:AddItem` |
| `Sound` com **`Volume = 100`** (o teto do Roblox é 10) | 1.1 – 2.2, com volume de gente |
| UI própria por `Input:SetTitle` | `ContextActionService`, com botão de toque para celular |
| cinco malhas pagas e nunca acesas | as sete estão em uso, uma por papel |

### O que a origem deu, e ficou

Os **nomes das habilidades** (`Ultra Combo`, `An end of an Era`), as **sete malhas**, e a
**paleta**: `Color3.new(0,0,0)` no corpo do laser com `Color3.new(1,1,1)` no núcleo. Preto com
contorno branco é a assinatura do original, e nenhum outro conjunto deste repositório é preto
— ele se distingue sem precisar de cor.

⚠️ A paleta **sonora** é de um timbre só: `rbxassetid://2960518660`, o único `Sound` do modelo,
repartido em três papéis por volume e pitch (`DISPARO`, `GRAVE`, `AGUDO`). É a mais fina do
repositório, mais fina até que a do DRAMA.

## Para sair de LIMPO e virar APROVADO

Falta a **licença** e o teste em jogo. Nada aqui rodou no Studio — a verificação é toda
estática. O que só o jogo confirma: se o cogumelo de 522 studs cabe no quadro que a cutscene
escolheu, e se a entidade parada (ela não persegue, por decisão declarada) lê como ameaça ou
como enfeite.
