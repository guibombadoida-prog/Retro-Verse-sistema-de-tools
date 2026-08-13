# PIPELINE — MODELO → TOOL
**Retro-Verse / Studios** · o procedimento padrão deste repositório

> A fronteira que governa tudo aqui: **entra o que se vê e se ouve. Não entra o que decide
> dano, alvo ou estado.** (§12.12.1)

---

## Visão geral

```
MODELOS_ENTRADA/          ACERVO_RETROVERSE/              Tools/
  modelo cru       →        CRU → LIMPO → APROVADO   →      Tool autocontida
  + ORIGEM.md               + FICHA.md                      + Values declarados
  + AUDITORIA.md            + NOTAS.md / ids.md             + Delta do Acervo
```

---

## Passo 1 — Receber o modelo

Criar `MODELOS_ENTRADA/Nome_Do_Modelo/` com o arquivo cru e o `ORIGEM.md` preenchido:
**autor · origem · licença · data de entrada**.

> ⚠️ **Sem os quatro campos, para aqui.** Material sem origem fica CRU e não entra em Tool (§12.12.3).

---

## Passo 2 — Buscar no Acervo ANTES de qualquer coisa

Ler `ACERVO_RETROVERSE/_INDICE.md`.

Se já existe efeito equivalente, **reusar e adaptar**. Recriar do zero um efeito que já existe é
exatamente o desperdício que o Acervo foi criado para acabar (§12.16.5).

---

## Passo 3 — Inventário: o que se aproveita

| Do modelo | Aproveita? | Destino |
|---|---|---|
| Meshes, texturas, ParticleEmitter, Beam, Trail | ✅ | `ACERVO/[Modelo]/VFX/` |
| Sons e IDs de áudio | ✅ | `ACERVO/[Modelo]/SFX/` |
| Animações R6 em CFrame, tabelas de pose | ✅ | `ACERVO/[Modelo]/R6_CFRAME/` |
| Handle / geometria da arma | ✅ | direto na Tool |
| Lógica de dano, alvo, status | ❌ | **descartada** — o Núcleo é a única porta |
| NPCs, módulos de gear | ❌ | descartados |
| `require(<id numérico>)` | ❌ | descartado ou reescrito |
| `Animation` / `AnimationTrack` asset | ❌ | convertido em poses CFrame |
| `ScreenGui` / `ColorCorrection` / `Sky` | ❌ | removidos |

Registrar o inventário em `MODELOS_ENTRADA/Nome_Do_Modelo/AUDITORIA.md`.

---

## Passo 4 — Passe de conformidade (§12.12.2)

Rodar a busca no material importado. Cada achado tem correção obrigatória:

```bash
# Varredura rápida sobre os .lua extraídos do modelo
grep -rn ':Emit(\|require(1\|require(2\|require(3\|require(4\|require(5' .
grep -rn 'math\.random\|tick()\|wait(\|spawn(\|delay(' .
grep -rn ':Destroy()\|AncestryChanged\|Instance\.new("Explosion")' .
grep -rn 'ScreenGui\|ColorCorrection\|Sky\|LoadAnimation' .
grep -rn '+=\|-=\|continue' .
```

| Achado | Correção |
|---|---|
| `:Emit(n)` no servidor | `Enabled = true/false` + `Rate`; burst pré-criado e reusado |
| `require(<id numérico>)` | Módulo copiado para dentro da Tool, ou efeito reescrito |
| `math.random` em gameplay | Ângulo áureo / Vogel, jitter senoidal, índice sequencial |
| `wait()` / `spawn()` / `delay()` | `task.wait` / `task.spawn` / `task.delay` |
| `tick()` | Acumulador `dt` a partir de zero |
| `:Destroy()` em part/bodymover | `Parent = nil` ou `Debris` |
| `AncestryChanged` | `Tool.Destroying` |
| `Instance.new("Explosion")` | `_G.Combate.detectarHumanoides` |
| `ScreenGui` / overlay | Removido — o efeito vive só no mundo 3D |
| Clone para `ServerStorage` / `ReplicatedStorage` | Material fica dentro da Tool |
| `+=` / `continue` | Sintaxe expandida |
| `LoadAnimation` | Tabela de poses CFrame para `R6CFrameAnimator` |

Ao final: `FICHA.md` com status **LIMPO** e a lista de violações corrigidas.

---

## Passo 5 — Depositar no Acervo

```
ACERVO_RETROVERSE/Nome_Do_Modelo/
├── FICHA.md
├── VFX/[NOME_DO_EFEITO]/   → .lua + .rbxmx + NOTAS.md
├── SFX/[NOME_DO_EFEITO]/   → ids.md + .rbxmx
└── R6_CFRAME/              → Poses_[Modelo]_V1.lua + NOTAS.md
```

Copiar `_MODELO_DE_PASTA/` como ponto de partida. Atualizar `_INDICE.md`.

---

## Passo 6 — Montar a Tool

1. Copiar `Tools/_TEMPLATE_Tool/` → `Tools/[NomeDaTool]/`; trocar `Template` em todos os arquivos.
2. Montar a hierarquia do §12.10 no Studio (ver `_TEMPLATE_Tool/ESTRUTURA.md`).
3. Handle: `Part` ou `MeshPart`, nome **exato** `"Handle"`. `Grip` configurado **no servidor**.
4. Declarar os `Value`s (§12.4):

| Value | Tipo | Nota |
|---|---|---|
| `DamageClass` | StringValue | **Nunca omitir.** Sem ele, todo bônus por classe fica inerte |
| `EnergyCost` | NumberValue | custo por ativação |
| `RecargaGlobal` | NumberValue | segundos; 0 ou ausente = sem recarga |
| `ChaveRecarga` | StringValue | só se Tools irmãs dividirem a recarga |

5. **Copiar** o material aprovado do Acervo **para dentro da Tool** (Regra nº 1):

   | Material | Destino dentro da Tool | Consumido por |
   |---|---|---|
   | `Sound` | `Tool/SFX/<Nome>` | `tocarSom(nome, posicao)` — clona o molde |
   | Mesh, MeshPart, textura, `ParticleEmitter`, `Beam`, `Trail` | `Tool/Efeitos/<NOME>` | `molde(nome)` no `VFXModule` — clona |
   | Poses R6 CFrame | ModuleScript `Poses` | `Poses.golpe()` / `Poses.extra()` |
   | Geometria da arma | `Handle` e filhos | a própria Tool |

   **Nunca referenciar o Acervo, `ReplicatedStorage`, `ServerStorage` ou `workspace`.**

6. Preencher `CFG` com os números de balanceamento. Zero número mágico solto.
   Volume, pitch e RollOff **não** vão para o `CFG` — são propriedades da instância dentro da Tool.
7. Rodar `bash TESTES/verificar_autocontencao.sh` antes de considerar a montagem pronta.

---

## Passo 6b — Montar o `.rbxmx`

A entrega é o arquivo da Tool, não o `.lua` solto (`REGRA_ENTREGA_RBXM.md`):

```bash
python3 FERRAMENTAS/montar_rbxmx.py
python3 TESTES/verificar_rbxmx.py
```

O `.rbxmx` é **derivado** dos `.lua`. Editou o Lua, monta de novo. Editar o XML à mão é
proibido — cria divergência silenciosa entre repositório e Studio.

> Se o modelo de origem vier sem as `SharedStrings` de malha, toda `UnionOperation` dele
> aponta para um blob de 0 byte e vira caixa cinza no Studio. Aí o `Handle` é **construído
> com primitivas** no montador, e o achado vai para a `AUDITORIA.md`.

---

## Passo 7 — Testar

| Teste | Esperado |
|---|---|
| **Importar o `.rbxmx` sozinho num place vazio** | **A Tool funciona por inteiro — Regra nº 1** |
| Equipar / desequipar / ativar | Sem erro no Output; `Equipped`/`Unequipped` disparam (exige Handle) |
| Duas cópias da Tool na mochila | A recarga global trava **as duas** |
| Desequipar durante a recarga | A recarga **não** zera |
| Alvo com escudo registrado | Escudo absorve; a barra não pisca (modo preciso) |
| Aliado do mesmo time | Não recebe dano |
| Alvo com `ForceField` | Não recebe dano |
| Morte por esta Tool | Tag `creator` aparece no Humanoid, com o jogador certo |
| **Acervo deletado do place** | **Toda Tool continua funcionando** (§12.16.4) |
| Núcleo removido do place | Tool continua funcionando, sem os bônus (guardas `_G.Combate and`) |

O último par de testes é o que separa uma Tool conforme de uma Tool que só parece conforme.

Status no `FICHA.md` vira **APROVADO** depois deste passo — não antes.

---

## Passo 8 — Entregar

Relatório no formato §13, **incluindo a seção obrigatória**:

```
## Delta do Acervo
  Entrou:    [efeito] — [modelo de origem] — [status]
  Reusado:   [efeito] — [de onde]
  Status:    [efeito]: CRU → LIMPO → APROVADO
```

**Entrega sem Delta do Acervo é entrega incompleta** (§12.16.2).

Fechar com `CHECKLIST_ENTREGA.md`.
