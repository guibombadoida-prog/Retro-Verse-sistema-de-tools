# [NOME_DO_EFEITO] — SFX

> Molde de `ids.md` (§12.16.1). Uma pasta por som:
> `SFX/[NOME_DO_EFEITO]/` → `ids.md` + `[Nome_Do_Efeito].rbxmx`

## IDs

| Camada | `rbxassetid` | Volume | Pitch | RollOffMaxDistance |
|---|---|---|---|---|
| Principal | `rbxassetid://` | 0.6 | 1.00 | 60 |
| Corpo | `rbxassetid://` | 0.4 | 0.92 | 45 |
| Cauda | `rbxassetid://` | 0.3 | 1.08 | 70 |

## Origem

- Autor original:
- Origem:
- Licença / permissão:
- Data de entrada:
- Status: CRU | LIMPO | APROVADO

## Notas

- O som é tocado numa `Part` âncora invisível e retirado de cena com `Debris` — nunca `:Destroy()`.
- Volume acima de 0.8 satura junto com o SFX do alvo.
- Ordem de impacto: **SFX primeiro**, antes de física, VFX e dano (§8 V2).

## Onde já foi usado

| Tool | Versão |
|---|---|
| | |
