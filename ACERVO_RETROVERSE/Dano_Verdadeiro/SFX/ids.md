# SFX — Damage First True

**Status: CRU.** 5 `Sound`, e a entrada mais interessante deste lote em áudio: os
**primeiros `SoundEffect` a chegar ao Acervo**.

## Os cinco sons

| `Sound` | id | Onde vive | Papel |
|---|---|---|---|
| `activate` | `456991831` | `Handle` | clique de armar |
| `alarm` | `675587093` | `Handle` | toca 3×, de 2 em 2 s, durante a carga |
| `charge` | `8578316223` | `sender` | zumbido de carga, 15 s |
| `boom` | `7390331288` | `script` | estouro |
| `hum` | `9114524356` | `script` | rastro, com fade de 25 s |

## Os efeitos de áudio — nenhuma Tool do repositório usa isto ainda

| Efeito | Em qual som |
|---|---|
| `DistortionSoundEffect` | `boom`, `hum`, `charge` |
| `PitchShiftSoundEffect` | `hum` (**dois**, empilhados) |

As 38 Tools do repositório tocam `Sound` cru. Este modelo mostra o degrau seguinte:
distorção no estouro e **dois `PitchShiftSoundEffect` empilhados** no rastro, que é o que dá
a sensação de algo grande demais para o alto-falante.

São filhos do `Sound`, então acompanham o `:Clone()` de graça — cabem no molde
`Tool/SFX/` sem mudar nada da mecânica que as bombas já usam.

## O que NÃO copiar

O script move `boom` e `hum` para `game:GetService("SoundService")` antes de tocar:

```lua
local sfx = script:WaitForChild("boom")
sfx.Parent = game:GetService("SoundService")
sfx:Play()
```

`SoundService` como depósito é violação da Regra nº 1, e o verificador cobra isso por nome
(`✓ sem SoundService como depósito`). O motivo de terem feito assim é real — o som precisa
sobreviver à Tool — e a resposta deste repositório já existe: **âncora invisível no
`workspace` com `Debris:AddItem`**, que é o `tocarEm` das Tools de bomba.

## Para sair de CRU

Falta autor, licença e o teste de ouvido. Ver `../FICHA.md`.
