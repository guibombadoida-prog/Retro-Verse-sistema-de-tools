# Modelo: Domain_Expansion_Elemental

- **Autor original:** **não declarado no arquivo** — pendente (§12.12.3)
- **Origem:** `domain_vfx_sfx.rbxmx` — 13 MB, o maior arquivo único do Acervo
- **Licença / permissão:** **a confirmar** (§12.12.3)
- **Data de entrada:** 2026-08-04
- **Status: CRU**
- **Já usado em:** nada

## O que tem dentro

**4657 itens:** 1800 `Part` · 568 `Texture` · 558 `Weld` · 309 `Model` ·
256 `WedgePart` · 228 `CylinderMesh` · 208 `UnionOperation` · 160 `Pose` ·
122 `SpecialMesh` · 102 `MeshPart` · 84 `Motor6D` · 36 `Keyframe` ·
32 `CornerWedgePart` · **28 `Fire`** · 22 `Script` · 20 `ParticleEmitter` ·
14 `Humanoid` · 10 `KeyframeSequence` · 6 `Accessory` · 4 `PointLight`.

## Por que não entrou em nada

**Tema.** É um pack de domínio **elemental** — fogo e gelo, com 28 `Fire` e
geometria de cenário. O conjunto desta entrega é de **escudos**. Forçar
material elemental num escudo daria um resultado incoerente, e a paleta não
costura.

Não é rejeição: é material bom, guardado para um conjunto elemental futuro.

## O que vale saber para quando for usado

| | |
|---|---|
| 10 `KeyframeSequence` com 160 `Pose` | animação de corpo, convertível pela fórmula de `REGRA_ANIMACAO_R6.md` |
| 1800 `Part` + 208 `UnionOperation` | geometria de domínio/cenário, não de Tool |
| 28 `Fire` | `Fire` é legado do Roblox; a substituição moderna é `ParticleEmitter` |
| 14 `Humanoid` · 6 `Accessory` | o pack traz personagens montados — **fora de escopo** deste repositório |

O último item é o que mais importa: boa parte do arquivo é **personagem**, e
personagem não é `Tool`. O aproveitável de verdade são as 10 sequências de
animação e alguns emissores.
