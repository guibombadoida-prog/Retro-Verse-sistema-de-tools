# Conjunto Guardião do Tempo — 7 Tools

Conversão de `MODELOS_ENTRADA/Guardiao_Do_Tempo/guardiao_do_tempo.rbxmx`.

**9 habilidades no modelo → 7 Tools** (teto da REGRA DE DISTRIBUIÇÃO), com as 2 excedentes
alocadas como habilidade **Extra**.

---

## Distribuição

| # | Tool | Primária (`Tool.Activated`) | Extra (tecla) | `DamageClass` | Arquétipo |
|---|---|---|---|---|---|
| 1 | `TemperoTemporal` | `TemporalTemper` (Z) — recolhe e arremessa | — | Melee | LUTADOR |
| 2 | `Cronostase` | `Chronostasis` (X) — marca e retorna | — | Magic | MAGO |
| 3 | `AvancoRapido` | `FastForward` (C) — avanço que atropela | **Aceleração** (M) | Melee | LUTADOR |
| 4 | `CanhaoCronos` | `ChronosCannon` (V) — feixe reto | — | Ranged | ATIRADOR |
| 5 | `Temporalise` | `Temporalysis` (B) — parada do tempo | — | Debuff | MAGO |
| 6 | `ArmadilhaTemporal` | `TemporalTrap` (G) — armadilha no chão | — | Summon | INVOCADOR |
| 7 | `AvoDoTempo` | `GrandfatherTime` (Q) — as doze badaladas | **Provocação** (T) | Magic | MAGO |

### Por que esses dois agrupamentos

- **Aceleração → `AvancoRapido`**: as duas são deslocamento. Quem quer velocidade equipa uma
  Tool só.
- **Provocação → `AvoDoTempo`**: a provocação é a fala do Guardião, e a ultimate é onde ele fala.

Nenhuma habilidade foi cortada. 9 de 9 entregues.

---

## O que cada Tool tem

Todas seguem a mesma árvore (§12.10 + Regra nº 1). Ver o `ESTRUTURA.md` dentro de cada pasta.

```
Tool
├── Handle · DamageClass · EnergyCost · RecargaGlobal
├── [Nome]_Server_V1   Script
├── Client             LocalScript
├── VFXRemote          RemoteEvent   servidor → cliente
├── AcaoRemote         RemoteEvent   só nas duas Tools com Extra
├── R6CFrameAnimator   ModuleScript  V2, modo absoluto
├── Poses              ModuleScript  Poses_GuardiaoDoTempo_[Nome]_V1
├── VFXModule          ModuleScript
├── SFX/               Folder  Sounds configurados
└── Efeitos/           Folder  moldes visuais (opcional)
```

`R6CFrameAnimator` e `VFXModule` são **idênticos** nas 7 Tools. Isso é duplicação **exigida**
pela Regra nº 1: cada Tool precisa funcionar sozinha em place vazio. A fonte única para
manutenção fica no Acervo, e a atualização é recopiar para as 7.

---

## Números de balanceamento

| Tool | Dano | Raio / alcance | Recarga local | Recarga global |
|---|---|---|---|---|
| `TemperoTemporal` | 30 | 35 recolhe · 15 arremesso | 1,10 s | — |
| `Cronostase` | — | — | 0,45 / 1,20 s | — |
| `AvancoRapido` | 22 | 42 de avanço · 7 por passo | 2,20 s | — |
| `CanhaoCronos` | 120 | 220 · raio 9 | 6,0 s | 9 s |
| `Temporalise` | — | 34 · parada de 7 s | 8,0 s | 22 s |
| `ArmadilhaTemporal` | 65 gatilho · 15 respingo | 12 · estouro 20 | 3,0 s | 5 s |
| `AvoDoTempo` | 55 × 12 badaladas | 46 | 20,0 s | 45 s |

Todos vivem no bloco `CFG` do topo do respectivo Server Script. Zero número mágico solto.

> O modelo original chamava `ApplyDamage(HUM, 600000)` no `ChronosCannon` — morte garantida,
> furando `ForceField`. Aqui são 120, aplicados por `TakeDamage` com o dano calculado pelo
> Núcleo. **Este é o número que você vai querer revisar primeiro.**

---

## Antes de pôr em jogo

- [ ] `bash TESTES/verificar_autocontencao.sh`
- [ ] `DIRETRIZES/CHECKLIST_ENTREGA.md` — inclusive os testes de aceitação no Studio
- [ ] Cada Tool sozinha em place vazio → funciona por inteiro
- [ ] Ler o aviso das **duas chaves de recarga** no `ESTRUTURA.md` das Tools 4, 5, 6 e 7

## Origem e auditoria

- `MODELOS_ENTRADA/Guardiao_Do_Tempo/ORIGEM.md` — os 4 campos de §12.12.3
- `MODELOS_ENTRADA/Guardiao_Do_Tempo/AUDITORIA.md` — o passe §12.12.2 e **o que foi descartado**
- `ACERVO_RETROVERSE/Guardiao_Do_Tempo/FICHA.md` — status **LIMPO**

> ⚠️ A lógica do modelo foi **integralmente descartada**: ele abre com
> `require(4395650693)()` — execução de código remoto — e ao matar alguém clonava um script
> (`TotalNil`) para dentro da vítima, apagando todo script da `PlayerGui` dela.
> Só o material audiovisual foi aproveitado. Ver `AUDITORIA.md`.
