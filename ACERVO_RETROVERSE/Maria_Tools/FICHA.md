# Modelo: Maria Tools — 8 cajados, entregues como 7

- Autor original:            **a confirmar** ⚠️
- Origem:                    `mariatools.rbxmx`, enviado em 2026-08-13
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Conversão:                 2026-08-18
- Status:                    **APROVADO** (licença §12.12.3 segue em aberto)
- Onde vive:                 `Tools/Maria_7_Tools.rbxm`

---

## 8 → 7: qual par se funde, e por que não foi escolha de gosto

A `REGRA_DISTRIBUICAO_DE_TOOLS` dá teto 7 e a origem tem 8 `Tool`. Lendo os dois
`MainAttack`, a resposta é única:

| | |
|---|---|
| `Cajado Curador` | feixe no alvo, `Health + 2` **dez vezes** = cura 20 |
| `Cajado Roubador de Hp` | feixe no alvo, `TakeDamage(faltante/10)` **dez vezes**, e a mesma quantia entra na sua vida |

Mesmo feixe, mesma cadência de dez tiques, mesma `Attachment` no
`HumanoidRootPart` do alvo. Um dá, o outro tira — são a mesma Tool espelhada.
O Roubar virou a Extra `R` do Curador.

O detalhe bonito do Roubador foi mantido: ele drena **exatamente a sua vida
faltante**. Cheio de vida, não rouba nada. É a única mecânica do repositório
onde o dano depende do estado de quem ataca.

---

## As 28 habilidades

| Cajado | M1 (da origem) | R | T | Y |
|---|---|---|---|---|
| **Curador** | cura 20 em dez tiques | Roubar | Bênção (área) | Ressurgir (cura 45 + ForceField 6 s) |
| **da Escuridão** | orbe teleguiado, 26 | Enxame (3 orbes) | Cegueira | Manto (aura que segue) |
| **da Ilusão** | isca por 10 s | Trocar com a isca | Multiplicar (3) | Dispersar (estouram) |
| **das Estrelas** | estrela, dano 10 | Chuva (6) | Constelação (marca ×1.5) | Estrela-guia (persegue) |
| **de Gelo** | congela 3.5 s | Prisão (área) | Trilha (chão, 6 s) | Estilhaçar (**×2.2 em congelado**) |
| **do Meteoro** | meteoro, dano 50 | Chuva (5) | Cratera (6 s) | Impacto (puxa e estoura) |
| **Relâmpago** | 4 raios + estouro raio 10 | Tempestade (6 s) | Corrente (5 saltos) | Para-raios (marca ×1.6) |

Os números da origem foram mantidos onde faziam sentido: a cura de 20, o dano
10 da estrela, o 50 do meteoro, os 4 raios e o raio 10 do relâmpago.

Três pares se encaixam de propósito: **congelar → estilhaçar**, **marcar →
estrela**, **para-raios → raios**. Quem joga na ordem certa rende mais.

---

## Cinco proibições da origem, resolvidas

| Da origem | Vira | Por quê |
|---|---|---|
| `Health = Health + x` | `math.min(MaxHealth, ...)` | a origem estourava o teto e o valor vazava para quem lesse no meio |
| `HumanoidRootPart.Anchored = true` | `prender()` | com `Anchored`, a Tool sumindo no meio deixava o jogador preso **para sempre** |
| `Instance.new("Explosion")` | `golpearArea` | quem detecta alvo é o Núcleo |
| `math.random` em gameplay | `naFaixa` / ângulo áureo | sorteio faria cada cliente ver outra cena |
| `LoadAnimation` + `Animation` | `R6CFrameAnimator` | proibidos em Tool; e não havia `KeyframeSequence` para converter — o conteúdo mora atrás do id, no servidor da Roblox |

E a isca da `Ilusão`: a origem **clonava o personagem**, com `Animate` de 505
linhas, `Wander` e `ControlFollow` — um `Humanoid` a mais no servidor por uso.
Virou geometria do cliente com prazo. NPC segue fora de escopo; invocar com
prazo, não.

---

## `aliadosEm` — o primeiro do repositório, e como ele não quebra o invariante

O Curador é a primeira Tool que precisa saber em quem **não** bater. O
`CLAUDE.md` é explícito: `IsTeamMate` só existe dentro do `NucleoCombate.lua`.

Então a pergunta é feita ao Núcleo (`detectarAliados`), e o **fallback não
inventa regra de time: ele deriva**. Quem está no raio e não está na lista de
inimigos que o próprio `alvosEm` devolveu é aliado, mais o portador. Sem Núcleo
e sem time configurado, a cura vira auto-cura — que é o certo para uma Tool
sozinha num place vazio.

## A armadilha que o verificador pegou

`preparar_maria.py` copiava a Tool e **não levava a tabela `<SharedStrings>`**.
`MeshPart.AeroMeshData` é uma citação de md5 e o bloco que a resolve é irmão dos
`Item` — não viaja junto. Os sete `_ORIGEM.rbxmx` saíram com citação pendurada, e
o Studio chamaria os arquivos de corrompidos. Mesmo defeito do
`restaurar_reality_original.py`, e o verificador de estrutura pegou os dois.

## Delta do Acervo

Entrou: 24 efeitos autorais em `VFXModule_Maria.lua`, 28 sequências de pose R6,
e os helpers `aliadosEm` / `maisPertoAliado`. Reusado: o andaime de VFX do Jodro
(que veio do Guest), o `R6CFrameAnimator` canônico e o pack Stella. Da origem
atravessaram Handle, `ExtraTHICK`, o `Sound` `Atk` e os moldes `Beam`, `Orb`,
`Shadows`, `Trail`, `Mesh` e `Particle` — geometria e som, nunca código.
