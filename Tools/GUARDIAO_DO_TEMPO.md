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
| 3 | `AvancoRapido` | `FastForward` (C) — carga longa, detonação no fim | **Aceleração** (M) | Magic | HIBRIDO |
| 4 | `CanhaoCronos` | `ChronosCannon` (V) — feixe reto | — | Ranged | ATIRADOR |
| 5 | `Temporalise` | `Temporalysis` (B) — parada do tempo | — | Debuff | MAGO |
| 6 | `ArmadilhaTemporal` | `TemporalTrap` (G) — armadilha no chão | — | Summon | INVOCADOR |
| 7 | `AvoDoTempo` | `GrandfatherTime` (Q) — as doze badaladas | **Provocação** (T) | Magic | MAGO |

### Por que esses dois agrupamentos

- **Aceleração → `AvancoRapido`**: as duas mexem no andamento do tempo do dono.
- **Provocação → `AvoDoTempo`**: a provocação é a fala do Guardião, e a ultimate é onde ele fala.

Nenhuma habilidade foi cortada. 9 de 9 entregues.

---

## A entrega — um arquivo só

### `Tools/GuardiaoDoTempo_7_Tools.rbxmx` — 297 KB, as 7 Tools, 35 scripts

**Botão direito na `StarterPack` → Insert from File → escolha o arquivo.** As 7 Tools entram
de uma vez.

As Tools ficam na **raiz** do arquivo, não dentro de uma `Folder`: `Folder` na `StarterPack`
não entrega nada ao jogador. O verificador barra essa armadilha.

Cada Tool já traz `Handle`, os `Value`s, os cinco scripts, `VFXRemote` (e `AcaoRemote` onde há
Extra), a pasta `SFX/` com os `Sound` configurados e a pasta `Efeitos/`.

### Individuais, se você quiser só uma

| Arquivo | Tamanho |
|---|---|
| `TemperoTemporal/TemperoTemporal.rbxmx` | 43,0 KB |
| `Cronostase/Cronostase.rbxmx` | 38,8 KB |
| `AvancoRapido/AvancoRapido.rbxmx` | 47,9 KB |
| `CanhaoCronos/CanhaoCronos.rbxmx` | 39,7 KB |
| `Temporalise/Temporalise.rbxmx` | 39,6 KB |
| `ArmadilhaTemporal/ArmadilhaTemporal.rbxmx` | 42,7 KB |
| `AvoDoTempo/AvoDoTempo.rbxmx` | 46,8 KB |

```bash
python3 FERRAMENTAS/montar_rbxmx.py     # regenera a partir dos .lua
python3 TESTES/verificar_rbxmx.py       # confere as 7
```

### Sobre o Handle

O `.rbxmx` de origem foi salvo com as `SharedStrings` de malha **vazias**: toda
`UnionOperation` dele aponta para um blob de 0 byte e apareceria como caixa cinza no Studio.
Por isso o `Handle` é um relógio de bolso **montado com primitivas** — corpo, aro, mostrador,
dois ponteiros e pino, soldados por `WeldConstraint`. Geometria de verdade, sem depender de
nada de fora (Regra nº 1).

Trocar por um mesh próprio depois é só substituir o `Handle` e remontar.

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
| `AvancoRapido` | 180 | 120 de raio · carga de 2,9 s | 12,0 s | 60 s |
| `CanhaoCronos` | 120 | 220 · raio 9 | 6,0 s | 9 s |
| `Temporalise` | — | 34 · parada de 7 s | 8,0 s | 22 s |
| `ArmadilhaTemporal` | 65 gatilho · 15 respingo | 12 · estouro 20 | 3,0 s | 5 s |
| `AvoDoTempo` | 55 × 12 badaladas | 46 | 20,0 s | 45 s |

Todos vivem no bloco `CFG` do topo do respectivo Server Script. Zero número mágico solto.

> O modelo original chamava `ApplyDamage(HUM, 600000)` no `ChronosCannon` — morte garantida,
> furando `ForceField`. Aqui são 120, aplicados por `TakeDamage` com o dano calculado pelo
> Núcleo. **Este é o número que você vai querer revisar primeiro.**

---

## Fidelidade — leia antes de julgar o resultado

**Não é 100% fiel, e não pode ser.** Três das nove habilidades terminam em morte instantânea de
todo mundo do mapa (`workspace:GetDescendants()` + `BreakJoints`, e `Health = 0`).

| | Habilidades |
|---|---|
| ✅ Fiel | Chronostasis, TemporalTrap, SPEDUP, Taunt |
| 🔧 Adaptado | TemporalTemper, Temporalysis |
| ⛔ Desfecho não reproduzido | FastForward, ChronosCannon, GrandfatherTime |

O detalhamento, habilidade por habilidade — com o que mudou, o número exato e o porquê — está em
[`DIRETRIZES/MAPA_DE_FIDELIDADE_Guardiao_Do_Tempo.md`](../DIRETRIZES/MAPA_DE_FIDELIDADE_Guardiao_Do_Tempo.md).

---

## Antes de pôr em jogo

- [ ] `python3 TESTES/verificar_rbxmx.py`
- [ ] `bash TESTES/verificar_autocontencao.sh`
- [ ] `DIRETRIZES/CHECKLIST_ENTREGA.md` — inclusive os testes de aceitação no Studio
- [ ] Importar cada `.rbxmx` sozinho num place vazio → a Tool funciona por inteiro
- [ ] Ler o aviso das **duas chaves de recarga** no `ESTRUTURA.md` das Tools 4, 5, 6 e 7

## Origem e auditoria

- `MODELOS_ENTRADA/Guardiao_Do_Tempo/ORIGEM.md` — os 4 campos de §12.12.3
- `MODELOS_ENTRADA/Guardiao_Do_Tempo/AUDITORIA.md` — o passe §12.12.2 e **o que foi descartado**
- `ACERVO_RETROVERSE/Guardiao_Do_Tempo/FICHA.md` — status **LIMPO**

> ⚠️ A lógica do modelo foi **integralmente descartada**: ele abre com
> `require(4395650693)()` — execução de código remoto — e ao matar alguém clonava um script
> (`TotalNil`) para dentro da vítima, apagando todo script da `PlayerGui` dela.
> Só o material audiovisual foi aproveitado. Ver `AUDITORIA.md`.
