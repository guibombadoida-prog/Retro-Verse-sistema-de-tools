# Modelo: Canhão Satélite (`LowOrbitIonCannon`)

- Autor original:            **a confirmar** ⚠️ — o `Script` declara só o plugin conversor
- Origem:                    `Canhao_satelite.rbxmx`
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **CRU**
- Onde vive:                 `MODELOS_ENTRADA/Canhao_Satelite/` · ids em `SFX/ids.md`

---

## O que é

Uma `Tool` de verdade, e a **menor deste lote**: 40 instâncias, 675 linhas.

```
LowOrbitIonCannon [Tool]
  Handle [Part]          Mesh · loicimage (Decal) · Call · Equip · ClickAccept · ClickDecline
  LocalScript            104 linhas
  Script                 559 linhas · shakerbreaker [LocalScript] 12 linhas
  kaboom [RemoteEvent]
  LOIC [Model]           BaseSatellite + 3 × Satellite — e 17 Sound pendurados na base
```

**Uma habilidade só:** marcar um ponto e chamar o feixe orbital. Sem tecla nenhuma — o scan
não achou um único `KeyCode`.

## O problema de distribuição

O piso da regra é **3 Tools por modelo**. Este modelo tem **uma** habilidade.

Ele não sai sozinho. Ou entra como **habilidade Extra** de uma Tool de tema próximo — o
`Julgamento Final` do `collector` é o candidato óbvio, é a mesma ideia de feixe vindo de
cima — ou espera um segundo modelo de tema orbital para formar conjunto. Decisão de quem
manda converter, não minha.

## O que vale de verdade aqui: os 21 `Sound`

É a maior densidade de SFX por instância que já entrou (**21 sons em 40 instâncias**), e são
sons de **impacto pesado**, que é justamente o que faltava — as bombas e os escudos foram
sonorizados com o que havia à mão.

Ver `SFX/ids.md`. Destaques: `Big Explosion`, `Electric Explosion`, `DBExplode`,
`Explosion SFX`, `Gravity Hammer`, `sfx_swooshing`.

⚠️ **Todos os 17 sons do satélite estão com `Volume = 10`.** O teto do Roblox é 10; isso é
volume estourado de propósito. Qualquer um que entre em Tool entra **remixado**, não como
está.

## O `getfenv` / `setfenv` — o que é

Um de cada, e vêm do cabeçalho do arquivo:

```lua
--Converted with ttyyuu12345's model to script plugin v4
```

É o `sandbox(var, func)` que o plugin gera para remapear a variável `script` dentro das
funções convertidas. Junto vem o `mas = Instance.new("Model", game:GetService("Lighting"))`,
que é o depósito temporário do mesmo plugin.

**Zero `loadstring`, zero `require(<id numérico>)`, zero `HttpService`, zero webhook.** Não é
backdoor. Mas **nada disso sobrevive à conversão**: o depósito em `Lighting` é violação
direta da Regra nº 1, e o `sandbox` existe só para o modelo virar script — a Tool não
precisa dele.

## O resto do passe §12.12.2

| Achado | Quantos |
|---|---|
| `wait()` | 33 |
| `math.random` | 6 |
| escrita em `Motor6D.C0` | 8 |
| `spawn(` | 1 |
| `:Destroy()` | 1 |

## Passe de conformidade §12.12.2 — NÃO EXECUTADO
