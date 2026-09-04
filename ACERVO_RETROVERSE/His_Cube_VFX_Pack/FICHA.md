# Modelo: His Cube — `Vfx pack`

- Autor original:            **a confirmar** ⚠️ — o pack não declara autor em lugar nenhum
- Origem:                    `his_cube.rbxmx` (segunda entrega do modelo His Cube), pasta `Vfx pack`
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **CRU** — nada daqui entra em Tool antes do passe §12.12.2
- Onde vive:                 catálogo em `VFX/CATALOGO.md`; os assets seguem no `.rbxmx` de origem

---

## O que é, e por que é a entrada mais importante deste lote

O `.rbxmx` do His Cube V2 é a **nossa própria Tool convertida** (o `Shoot` é o
`ServerScript_HisCube_V4` que este repositório escreveu) com **uma pasta nova enxertada**:
`Vfx pack`, 121 filhos diretos.

A diferença entre as duas entregas do His Cube é só isso:

| | V1 (`his_cube_com_vfx_addon.rbxmx`) | V2 (`his_cube.rbxmx`) |
|---|---|---|
| instâncias | 119 | **1061** |
| `ModuleScript` | 40 | 40 — **os mesmos 40**, sem uma linha de diferença |
| `ParticleEmitter` | 15 | **296** |
| `Beam` | 0 | 21 |
| `Decal` | 0 | 45 |

**O pack de código Stella é idêntico nas duas.** O que V2 traz é o que faltava: os
**emissores prontos**, montados à mão, em vez de `ParticleEmitter` construído por script.

Isto responde diretamente ao que estava pedido — *"uns VFX absurdos que estão em outras
ferramentas que eu lancei aqui"*. É a maior fonte de VFX que já entrou no repositório:
**281 `ParticleEmitter`, 21 `Beam`, 45 `Decal`, 34 texturas nomeadas.**

---

## O que tem dentro

Ver `VFX/CATALOGO.md` para a lista emissor a emissor. Resumo:

| Grupo | Conteúdo | Emissores |
|---|---|---|
| `Anime` | 36 efeitos nomeados — soco, corte, sangue, fogo, água, vento, portal, escudo… | 71 |
| `vfx pack` | 4 peças soltas (Explosion, Projectile, f, Part) | 45 |
| `Big` | 5 efeitos grandes — Explosion, Tornado, Ball, Lighting, Big-Crack | 25 |
| `Auras` | 5 auras de corpo inteiro (Fire, Water, RNG ×3) | 25 + 12 `Beam` |
| `Beams` | 3 feixes contínuos — Waterfall, Wind, Lava | 12 + 9 `Beam` |
| `Heads` | 6 expressões faciais | 8 |
| `Particle Storage` | 35 `Part` de depósito | — |
| soltas | 34 `Part` carregando uma textura cada | 95 |

### O que salta à vista para o que já está no repositório

| Efeito do pack | Onde cabe |
|---|---|
| `Shield-01`, `Shield-Break-01` | as **7 Tools de escudo** — hoje o escudo é desenhado por código |
| `Punch-01/02/03`, `Slash-Impact-01` | impacto de golpe corpo a corpo, medido pela gramática R6 |
| `Portal-01`, `Portal-Enter-01` | `Portal do submundo` (`collector` T5) |
| `Crack-01`, `Big-Crack-01` | `RACHADURA_SOLO` — hoje vem do `Floor_Crack` do Stella |
| `Charge-01` | o quadro segurado de ultimate (regra 7 da gramática R6) |
| `Lighting-01/02/03` | Xester e `Cajado Relâmpago`, se ele virar Tool |

---

## As 34 texturas

O valor real do pack não são os emissores montados — é o **acervo de textura**. Flipbooks de
fumaça, fogo e raio, anéis, estrelas, crescentes, vórtice, glow. São `rbxassetid` que
qualquer `ParticleEmitter` autoral pode usar **sem copiar o emissor de ninguém**.

Ver a tabela completa em `VFX/CATALOGO.md`.

---

## Passe de conformidade §12.12.2 — NÃO EXECUTADO

O pack é **asset**, não código: não tem `Source` nenhum para conformar. O passe que ele
precisa é outro, e é de **estrutura**:

- [ ] `Auras` carrega **5 `Humanoid` + 5 `HumanoidDescription` + 30 `Motor6D`** — são
      *dummies* R6 inteiros vestindo a aura. **Rig não entra em Tool.** Só os
      `ParticleEmitter` e `Beam` presos aos `Attachment` é que aproveitam.
- [ ] `Particle Storage` são 35 `Part` vazias de depósito — não entram.
- [ ] Todo emissor entra **desligado** (`Enabled = false`) e é ligado na execução — é a
      regra que já vale para as 38 Tools.
- [ ] Verificar `Rate` × `Lifetime` de cada emissor antes de ligar: emissor de pack costuma
      vir com `Rate` alto demais para uso dentro de Tool.
- [ ] Nenhum emissor pode depender do `Part` de origem: cada um vira molde clonado para
      dentro da Tool, com o próprio `Attachment`.

## Para sair de CRU

Falta **autor e licença**. Sem os quatro campos da ficha, nada daqui entra em Tool (§12.12.3).
