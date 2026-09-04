# Modelo: Danilo_Escudos

- **Autor original:** **não declarado no arquivo** — pendente.
  ⚠️ Campo obrigatório de §12.12.3.
- **Origem:** `DANILO_TOOLS.rbxmx` — 5 Tools de escudo
- **Licença / permissão:** **a confirmar**. ⚠️ Campo obrigatório de §12.12.3.
- **Data de entrada:** 2026-08-04
- **Status: LIMPO**   (CRU | LIMPO | APROVADO)
  Passe §12.12.2 executado sobre as 5 Tools inteiras — todas foram convertidas.
- **Já usado em:** conjunto Escudos — as 5 convertidas

> ⚠️ Sem autor e licença, a ficha não fecha em APROVADO. O material **de lógica**
> já entrou (foi reescrito do zero); o que segue bloqueado é reuso de asset novo.

## O que veio, e em que estado

5 Tools: `Salvador` · `Proteção` · `Escudo Skate` · `Escudo Bumerangue` ·
`Escudo Bloqueador`. Cada uma com Script, LocalScript, RemoteEvent, Handle
(Part + SpecialMesh) e 5 a 6 `Sound`.

### Violações encontradas nos 5 Scripts

| Proibido | Ocorrências |
|---|---|
| `Animation` / `LoadAnimation` | 69 |
| `wait()` | 35 |
| `spawn()` | 21 |
| `delay()` | 14 |
| `tick()` | 7 |
| `math.random` | 4 |
| `:Destroy()` | 3 |
| `:Emit()` em Server Script | 2 |
| `ScreenGui` | 1 |
| Escrita direta em `Health` | 1 |

Nenhum `require(<id numérico>)` — o modelo não tem execução de código remoto,
o que é raro em material de toolbox e vale registrar.

### Três defeitos de comportamento, não de estilo

1. **`Salvador`** escrevia `targetHumanoid.Health = oldHealth` para desfazer o
   dano do aliado. Ignora `ForceField` e redução registrada, e em alguns
   caminhos lia `oldHealth` **depois** do dano — curando acima do que o aliado
   tinha.
2. **`Escudo Skate`** restaurava `WalkSpeed` só no fim do laço. Largar a Tool no
   meio deixava o jogador a 51 de velocidade permanentemente.
3. **`Proteção`** varria `workspace:GetDescendants()` inteiro todo frame para
   achar projéteis.

Os três estão corrigidos nas Tools convertidas. Ver `Tools/ESCUDOS.md`.

## O que foi aproveitado

| | |
|---|---|
| **Lógica** | as 5 habilidades, reescritas do zero conforme as regras |
| **Números** | dano, alcance, duração e recarga — preservados do original |
| **Sons** | 7 ids (`block`, `block2`, `block3`, `block4`, `equip`, `Protecao`, `Sacrificio`) |
| **Poses** | as do original já eram `Weld.C0` com as bases certas — serviram de ponto de partida |
| **Handle** | **não** — o `SpecialMesh` aponta para `MeshId` de terceiro. O escudo foi remontado com primitivas |

O último ponto é o de sempre: `MeshId` sem licença declarada não entra em Tool,
e o Handle construído em código não depende de asset nenhum (Regra nº 1).
