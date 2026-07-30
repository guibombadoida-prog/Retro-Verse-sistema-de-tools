# Modelo: Guardião do Tempo

- **Autor original:** não declarado no arquivo. `CamShake` traz o cabeçalho `-- Synapse Decompiler`
  — o modelo é artefato descompilado, não fonte original.
- **Origem:** `guardiao_do_tempo.rbxmx`, enviado pelo autor do projeto.
  `SourceAssetId` do `MainModule`: `4661847142`.
- **Licença / permissão:** free model público — uso **audiovisual**. A lógica não é aproveitada.
- **Data de entrada:** 2026-07-30
- **Status: LIMPO** (CRU | LIMPO | APROVADO)
- **Violações corrigidas:** `require(4395650693)` remoto · `require(<id>)` no `MainModule` ·
  `Health = Health - dano` + `BreakJoints` · `INSTAKILL` · `MRANDOM` no dano ·
  `workspace:GetDescendants()` por golpe · `wait()` / `Swait()` · `SINE` global alimentando `CFrame` ·
  `:remove()` · `ScreenGui` (`WEAPONGUI`) · `ColorCorrectionEffect` (`Permachrome`) ·
  `Animation` + `AnimationId` · `Mouse.KeyDown` · `BodyVelocity` órfão
- **Excluído do acervo:** `Convert` (lógica) · `MainModule` (require remoto) ·
  `TotalNil` (apaga a `PlayerGui` da vítima) · `Permachrome` (`ColorCorrection`) ·
  `CamShake` original (`math.random` + `wait`; reescrito como `TREMOR`)
- **Já usado em:** TemperoTemporal_V1, Cronostase_V1, AvancoRapido_V1, CanhaoCronos_V1,
  Temporalise_V1, ArmadilhaTemporal_V1, AvoDoTempo_V1

> ⚠️ O `Convert` original **não** está no Acervo e não deve ser reintroduzido.
> Ver `MODELOS_ENTRADA/Guardiao_Do_Tempo/AUDITORIA.md` para o porquê de cada descarte.

---

## Conteúdo

| Efeito | Tipo | Status | Origem no modelo |
|---|---|---|---|
| `ONDA_TEMPORAL` | VFX | LIMPO | `WACKYEFFECT` EffectType `Wave` |
| `ESFERA_TEMPORAL` | VFX | LIMPO | `WACKYEFFECT` EffectType `Sphere` |
| `MOSTRADOR_TEMPORAL` | VFX | LIMPO | `ClockEffect` |
| `DETRITOS` | VFX | LIMPO | `Debree` |
| `TREMOR` | VFX | LIMPO | `CamShake` (LocalScript) |
| `IMPACTO_TEMPORAL` | SFX | LIMPO | `CreateSound` 588694531 / 588738949 / 782199941 |
| `ENGRENAGEM` | SFX | LIMPO | `CreateSound` 743521450 / 447682521 |
| `BADALADA` | SFX | LIMPO | `CreateSound` 850256806 / 1208650519 |
| `VOZ_GUARDIAO` | SFX | LIMPO | `Vocal` 819312817 / 819373088 |
| `Poses_GuardiaoDoTempo_*_V1` | R6_CFRAME | LIMPO | `Clerp(...C0, alvo, ...)` — 19 quadros |

## Passe de conformidade (§12.12.2)

- [x] `:Emit(n)` no servidor → efeito roda no cliente, disparado por `VFXRemote`
- [x] `require(<id numérico>)` → **removido**, sem equivalente
- [x] `math.random` em gameplay → ângulo áureo e jitter senoidal por contador
- [x] `wait()` / `spawn()` / `delay()` → `task.*`
- [x] `tick()` / `SINE` global → acumulador `dt` a partir de zero
- [x] `:Destroy()` / `:remove()` → `Parent = nil` / `Debris`
- [x] `AncestryChanged` → `Tool.Destroying`
- [x] `Instance.new("Explosion")` → não havia; a área usa `_G.Combate.detectarHumanoides`
- [x] `ScreenGui` / `ColorCorrection` → removidos
- [x] Clone para `ServerStorage` / `ReplicatedStorage` → material fica dentro da Tool
- [x] `+=` / `continue` → sintaxe expandida
- [x] `LoadAnimation` → tabela de poses CFrame
- [x] **Zero lógica de combate importada**

Status vira **APROVADO** depois dos testes de aceitação em jogo.
