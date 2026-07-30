# [Modelo] — poses R6 CFrame

> Molde de `NOTAS.md` do diretório `R6_CFRAME/`.
> Arquivo de poses: `Poses_[Modelo]_V[X].lua` (§12.15)

## Juntas usadas

| Junta | Pai | Usada em |
|---|---|---|
| `Right Shoulder` | `Torso` | |
| `Left Shoulder` | `Torso` | |
| `Right Hip` | `Torso` | |
| `Left Hip` | `Torso` | |
| `Neck` | `Torso` | |
| `RootJoint` | `HumanoidRootPart` | |

## Sequências

| Sequência | Quadros | Duração total | Easing |
|---|---|---|---|
| | | | |

## Origem

- Autor original:
- Origem:
- Licença / permissão:
- Data de entrada:
- Status: CRU | LIMPO | APROVADO
- Convertida de `LoadAnimation`? (sim/não — se sim, o asset original **não** entra na Tool)

## Notas

- Toda pose é **offset sobre a base da junta**, não C0 absoluta.
- Tempo acumula com `dt` a partir de zero. `tick()` nunca alimenta `CFrame` (§10.11.7).
- Quadro abaixo de 0.08 s não é percebido.

## Onde já foi usada

| Tool | Versão | Ajuste feito |
|---|---|---|
| | | |
