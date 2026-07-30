# Guardiao_Do_Tempo

- **Autor original:** não declarado no arquivo. O script `CamShake` carrega o cabeçalho
  `-- Synapse Decompiler` — o modelo é artefato **descompilado**, não fonte original.
- **Origem:** `guardiao_do_tempo.rbxmx`, enviado pelo autor do projeto.
  `SourceAssetId` do `MainModule`: `4661847142`. `MainModule` carrega `require(4395650693)`.
- **Licença / permissão:** free model público — uso **audiovisual** (VFX, SFX, poses R6 CFrame).
  A lógica de gameplay **não** é aproveitada (§12.12.1).
- **Data de entrada:** 2026-07-30
- **Destino:** 7 Tools do conjunto Guardião do Tempo

---

## Conteúdo do arquivo

| Classe | Qtd. |
|---|---|
| Weld | 52 |
| UnionOperation | 38 |
| Part | 12 |
| Script | 8 |
| NumberValue | 8 |
| Model | 7 |
| LocalScript | 6 |
| BoolValue | 4 |
| ParticleEmitter | 3 |
| ModuleScript | 1 |

O conteúdo está **duplicado**: uma cópia dentro de `MainModule` e outra na raiz. A raiz é a
que foi auditada; a de dentro do `MainModule` é idêntica.

Não existe nenhuma `Tool` no modelo. O que existe é um `Script` chamado `Convert` (2.770 linhas)
que o `MainModule` clona para dentro da `PlayerGui` do jogador.

## Habilidades encontradas — 9

| Tecla | Função no modelo | Natureza |
|---|---|---|
| `Z` | `TemporalTemper` | Golpe de área: puxa e depois arremessa |
| `X` | `Chronostasis` | Marca um ponto no tempo e retorna a ele |
| `C` | `FastForward` | Avanço rápido |
| `V` | `ChronosCannon` | Canhão / disparo concentrado |
| `B` | `Temporalysis` | Parada do tempo em área |
| `G` | `TemporalTrap` | Armadilha temporal no chão |
| `Q` | `GrandfatherTime` | Ultimate — a maior sequência do modelo |
| `M` | alternância `SPEDUP` | Aceleração de movimento (16 ↔ 48) |
| `T` | `Taunt` | Provocação |

Não há ataque primário por clique: **todas** as habilidades são teclas.

Ver `AUDITORIA.md` para o passe de conformidade e o que foi descartado.
