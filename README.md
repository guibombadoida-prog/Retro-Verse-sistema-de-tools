# Retro-Verse — Sistema de Tools (Roblox Studio)

Repositório **exclusivo para ferramentas (`Tool`) do Roblox Studio** do projeto Retro-Verse.

> **Escopo fechado.** Aqui entra apenas: Tools e o Acervo de
> VFX / SFX / poses R6 CFrame. Nada de NPC, mapa, economia, UI de jogo ou sistema fora de Tool.

O trabalho desta pasta é um só: **converter modelos (`.rbxm` / `.rbxmx`) em Tools conformes.**

---

## Regras vigentes

| Documento | O que governa |
|---|---|
| [`DIRETRIZES/REGRA_AUTOCONTENCAO_ABSOLUTA.md`](DIRETRIZES/REGRA_AUTOCONTENCAO_ABSOLUTA.md) | **Regra nº 1** — tudo dentro da Tool, sem exceção |
| [`DIRETRIZES/DIRETRIZES_SISTEMA_DE_TOOL.md`](DIRETRIZES/DIRETRIZES_SISTEMA_DE_TOOL.md) | Base: classe `Tool`, Handle, debounce, proibições |
| [`DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md`](DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md) | **Regra nº 2** — o depósito de VFX em `ReplicatedStorage` |
| [`DIRETRIZES/REGRA_DISTRIBUICAO_DE_TOOLS.md`](DIRETRIZES/REGRA_DISTRIBUICAO_DE_TOOLS.md) | Quantas Tools saem de um modelo — piso 3, teto 7 |
| [`DIRETRIZES/REGRA_ENTREGA_RBXM.md`](DIRETRIZES/REGRA_ENTREGA_RBXM.md) | Todo modelo convertido sai como `.rbxmx` |
| [`DIRETRIZES/REGRA_ANIMACAO_R6.md`](DIRETRIZES/REGRA_ANIMACAO_R6.md) | Weld C0, animator canônico, perna sob demanda |
| [`DIRETRIZES/REGRA_CAMERA_DE_CUTSCENE.md`](DIRETRIZES/REGRA_CAMERA_DE_CUTSCENE.md) | Câmera é 100% cliente, e sempre devolvida |
| [`DIRETRIZES/PIPELINE_MODELO_PARA_TOOL.md`](DIRETRIZES/PIPELINE_MODELO_PARA_TOOL.md) | Passo a passo da conversão modelo → Tool |
| [`DIRETRIZES/CHECKLIST_ENTREGA.md`](DIRETRIZES/CHECKLIST_ENTREGA.md) | Checklist final, copiável, de toda entrega |

Em conflito, a **Regra nº 1 vence tudo**; depois dela, a **Regra nº 2** vence a base.

---

## Estrutura do repositório

```
.
├── ServerScriptService/
│
├── Tools/
│   ├── Escudos_7_Tools.rbxmx      ← as 7 Tools num arquivo só
│   └── [Nome]/[Nome].rbxmx        ← e uma por arquivo, pronta para arrastar
│
├── MODELOS_ENTRADA/               ← .rbxm/.rbxmx crus, antes da conversão
│
├── ACERVO_RETROVERSE/             ← §12.16 — VFX · SFX · R6 CFrame reutilizáveis
│   ├── _INDICE.md
│   ├── _PADROES.md
│   └── [Modelo_De_Origem]/
│       ├── FICHA.md
│       └── VFX/ SFX/ R6_CFRAME/
│
├── FERRAMENTAS/
│   ├── clonar_tool.py             ← CLONA Tool que chega pronta (não remonta nada)
│   ├── conformar_pack_vfx.py      ← Pack de terceiro → passe §12.12.2 → Acervo
│   ├── montar_rbxmx.py            ← CONSTRÓI Tool autoral a partir dos .lua
│   ├── extrair_rbxm.py            ← Abre .rbxm BINÁRIO (LZ4) e lê tudo
│   ├── ler_rbxmx.py               ← Abre .rbxmx XML, mesma interface
│   └── depositar_no_acervo.py     ← Modelo → Acervo, com parâmetros de VFX
│
├── TESTES/                        ← Bancada. Nada daqui vai para o place
│   ├── verificar_autocontencao.sh
│   ├── verificar_estrutura_rbxmx.py
│   ├── verificar_poses.py
│   └── verificar_rbxmx.py
│
└── DIRETRIZES/                    ← As regras acima
```

Depois de qualquer edição:

```bash
# Tool que CHEGOU pronta — o .rbxmx de origem é a verdade, só o Source é reescrito
python3 FERRAMENTAS/clonar_tool.py montar \
        MODELOS_ENTRADA/Danilo_Escudos_V4/DANILO_TOOLS_ESCUDOS_V4.rbxmx \
        Tools/Escudos_7_Tools.rbxmx

python3 FERRAMENTAS/montar_rbxmx.py       # Tool AUTORAL, nascida aqui
python3 TESTES/verificar_estrutura_rbxmx.py  # o envelope: SharedStrings, Ref, CDATA
python3 TESTES/verificar_rbxmx.py         # confere as Tools entregues
python3 TESTES/verificar_poses.py         # poses x animator V2
bash    TESTES/verificar_autocontencao.sh # Regra nº 1
python3 TESTES/verificar_deposito_vfx.py  # o depósito instala, conta e apaga
```

**Clonar não é montar.** `montar_rbxmx.py` constrói o Handle a partir de primitivas — serve
para Tool autoral. Tool que chega pronta passa por `clonar_tool.py`, que **não toca** em
Handle, Mesh, Model, Sound nem Value.

### Mapeamento para o Studio

| Pasta no repositório | Destino no Studio |
|---|---|
| `Tools/[Nome]/` | `Tool` na `StarterPack` / `ServerStorage` |
| `ACERVO_RETROVERSE/` | `ServerStorage.ACERVO_RETROVERSE` — **prateleira de edição, nunca runtime** |

---

## Os três invariantes

1. **Autocontenção absoluta — nada de referência de script fora da Tool.**
   Todo script, animação, VFX, SFX, mesh, MeshPart e textura é **filho da Tool**.
   Arraste a Tool sozinha para um place vazio — sem Acervo, sem `ReplicatedStorage` povoado
   nem `ServerStorage` — e **ela funciona por inteiro**. Se faltar uma partícula, um som ou uma
   pose, a Tool violou a regra nº 1.

   **Sem exceção.** Já houve uma tentativa aqui — o pack de VFX em `ReplicatedStorage` —
   e ela saiu: os módulos de efeito não dependiam de nada e cabiam dentro da Tool desde o
   começo. Ver "Um caso real" no fim da regra.

   ```bash
   bash TESTES/verificar_autocontencao.sh
   ```

2. **O VFX sai da Tool e volta com ela.**
   Na entrega é filho da Tool; em runtime o Server o move para
   `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`; em `Tool.Destroying` a pasta some.
   Quem lê tem duas portas — depósito, e depois o interior da Tool.
3. **Nada de terceiro decide dano, alvo ou estado.**
   Entra o que se **vê e se ouve** (VFX, SFX, pose R6 CFrame), após o passe de conformidade §12.12.2.

---

## Instalação no place

**Um passo.** Colocar as Tools na `StarterPack` (ou entregá-las por código a partir de
`ServerStorage`).

Não há Script central para copiar, não há pasta para montar em `ReplicatedStorage`, não há
nada para confirmar no Output. Cada Tool monta o depósito de VFX dela sozinha no primeiro
`Equipped`, e o desmonta quando morre.

> O `NucleoCombate` foi **removido do repositório**. Ele era opcional e sempre com guarda,
> e ainda assim fazia a mesma Tool se comportar de dois jeitos conforme existisse ou não um
> script em outro lugar do place. O que era fallback virou o caminho único, e nenhuma Tool
> perdeu habilidade — os fallbacks já estavam escritos e testados nas 94.

---

## Antes de abrir qualquer trabalho

- [ ] Li `ACERVO_RETROVERSE/_INDICE.md` — o efeito que eu ia criar talvez já exista.
- [ ] A Tool alvo tem `DamageClass`. Sem ele, todo bônus por classe do jogo fica **inerte**.
- [ ] A entrega vai fechar com a seção **Delta do Acervo**. Sem ela, a entrega está incompleta.
