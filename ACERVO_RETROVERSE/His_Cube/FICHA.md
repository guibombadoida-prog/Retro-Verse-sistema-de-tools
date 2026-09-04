# Modelo: His Cube

- Autor original:            não declarado ⚠️
- Origem:                    `his_cube_com_vfx_addon.rbxmx` — Tool completa, com o addon da Stella embutido
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-05
- Status:                    CRU — referência de leitura, nada extraído
- Onde vive:                 `MODELOS_ENTRADA/His_Cube/`

## Por que este modelo está aqui

Foi enviado como **referência de lógica de CFrame R6** ("existe uma lógica perfeita para
cframe R6"). Nada dele foi extraído nesta leva.

## O que ele faz de animação

O script `Shoot` solda `Weld`s próprios, com nomes marcados por Tool:

```
RightArmWeldHisCube · HeadWeldHisCube · HRPWeldHisCube
AnimLerpSpeed = 0.2
```

É a **mesma abordagem** do `R6CFrameAnimator_V2` do repositório: `Weld` próprio por junta,
nunca `Motor6D.C0`. A diferença está em como a pose caminha — lerp por frame com fator fixo,
contra `Tween` / acumulador `dt` no animator canônico.

> **Trocar o animator canônico é decisão do dono do repositório, não minha.** A comparação
> está registrada; a troca não foi feita.

## Conteúdo

119 instâncias: 40 `ModuleScript` (o addon da Stella, embutido), 20 `MeshPart`,
15 `ParticleEmitter`, 14 `Part`, 4 `RemoteEvent`, 2 `LocalScript`, 1 `Tool`.

## Passe de conformidade (§12.12.2)

Não aplicado — nada deste modelo entrou em Tool.
