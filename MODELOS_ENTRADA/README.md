# MODELOS_ENTRADA

Ponto de chegada dos modelos **crus**, antes da conversão em Tool.

```
MODELOS_ENTRADA/
└── Nome_Do_Modelo/
    ├── ORIGEM.md              autor · origem · licença · data — os 4 campos de §12.12.3
    ├── [modelo].rbxm(x)       arquivo cru, como veio
    └── AUDITORIA.md           o que foi achado no passe §12.12.2, e o destino de cada achado
```

## Regras

- Nada sai daqui sem **auditoria** (§12.12.2) e sem os **quatro campos** de origem (§12.12.3).
  Faltando qualquer um dos quatro, o material fica **CRU** e não entra em Tool nenhuma.
- Do modelo cru aproveita-se **o que se vê e se ouve**: VFX, SFX, poses R6 CFrame, meshes.
  **Nunca** a lógica: dano, alvo, status, NPC, `require(<id numérico>)`.
- O material aprovado é depositado no `ACERVO_RETROVERSE/[Nome_Do_Modelo]/` e **copiado**
  para dentro da Tool. O modelo cru permanece aqui como rastro de origem.

## `ORIGEM.md` — modelo mínimo

```markdown
# Nome_Do_Modelo
- Autor original:
- Origem:                  (Toolbox / arquivo / URL)
- Licença / permissão:
- Data de entrada:         AAAA-MM-DD
- Destino pretendido:      [NomeDaTool]
```

Ver o passo a passo completo em `DIRETRIZES/PIPELINE_MODELO_PARA_TOOL.md`.
