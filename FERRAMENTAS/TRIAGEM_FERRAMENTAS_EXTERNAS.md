# Triagem — ferramentas externas de autoria

> **Segunda leva — quatro motores de física:** ver
> [`TRIAGEM_FISICA.md`](TRIAGEM_FISICA.md). Critério igual, escrutínio maior — aqueles
> são ferramentas de autoria e param no Studio; os de física rodam junto com a
> habilidade. E lá está o primeiro material **GPL** que chegou ao repositório.

Data: 2026-08-18 · três repositórios avaliados a pedido, clonados e lidos no código.

O critério é um só, e é a **regra nº 1**: o que a ferramenta produz precisa caber
**dentro da Tool**, funcionando sozinho num place vazio. Ferramenta de autoria pode ser o
que quiser — ela roda no Studio, não no jogo. O que importa é o **artefato de saída**.

| Repositório | Licença | Último commit | Veredito |
|---|---|---|---|
| [tijnepema/vfx-editor](https://github.com/tijnepema/vfx-editor) | **MIT** | 2024-11-18 | ✅ **ADOTAR** |
| [reapimus/grims-cutscene-engine](https://github.com/reapimus/grims-cutscene-engine) | **nenhuma** | 2021-09-05 | ⚠️ **estudar, não usar** |
| [Mqxsyy/Lumina](https://github.com/Mqxsyy/Lumina) | MIT | 2024-07-21 | ❌ **incompatível** |

---

## ✅ `vfx-editor` — adotar

**O que produz:** instâncias Roblox nativas. Contagem no código:
`Instance.new("ParticleEmitter")` ×6, `Instance.new("Attachment")` ×2,
`Instance.new("Part")` ×9 — parenteadas em `workspace` / `attachment`, não em script.

**Por que serve:** `ParticleEmitter` é **dado**, não código. Sai do editor, entra em
`Tool/Efeitos/` ou `Tool/Moldes/`, e a Tool continua funcionando sozinha num place vazio.
Dependência de runtime: **zero**.

É exatamente o buraco que este repositório tapa à mão hoje. Os `VFXModule_*.lua` desenham
com `Part` primitiva esticada (`camadaFlash`, `camadaFeixe`, `camadaCristais`) porque não
havia emissor autorado — e onde há (o pack do Noob, os 10 do Acervo) o resultado é
visivelmente melhor.

**Como usar, sem quebrar nada:**

1. O emissor entra **desligado** (`Enabled = false`) dentro da Tool. Quem acende é o clone.
2. Acender é **`Enabled` + `Rate`**, nunca `:Emit(n)` — `:Emit` ignora a curva de `Rate`
   que o autor escreveu, e o efeito fica com outra cara. Regra já fixada no `_INDICE.md`.
3. Passa pelo §12.12.2 como qualquer material de terceiro, com a ficha de quatro campos.
   Licença MIT resolve o §12.12.3 — é o único dos três que já chega resolvido.

---

## ⚠️ `grims-cutscene-engine` — estudar, não usar

**O que produz:** um `ModuleScript` de 14 linhas com `Keyframes` e `Actions` dentro dele:

```lua
for _, v in pairs(script.Keyframes:GetChildren()) do
	local instance = v:FindFirstChild("CameraInstance") and workspace.CurrentCamera or v.Instance.Value
	cutsceneData.Keyframes[instance] = require(v)
end
```

**O desenho está certo, e vale copiar a ideia:** todo `require` é `script.<filho>` —
relativo a si mesmo. O artefato é portátil, e `workspace.CurrentCamera` no cliente é
permitido aqui. Ele resolve por **dados** o que os `CutsceneCam_*.lua` deste repositório
resolvem por `if marca == "..."` escrito à mão — keyframe por instância, ação por tempo.

**O que barra:** **não tem licença.** Sem os quatro campos (autor, origem, licença, data) o
material fica **CRU** e não entra em Tool — §12.12.2. E é a regra que existe justamente
para não repetir o caso `reality_tools.rbxmx`.

Sem licença, ele serve como **referência de formato**, lida e reimplementada — nunca
copiada. É a mesma distinção que fechou o Reality: ler o que um script faz e reescrever é
o oposto de copiá-lo.

Detalhe menor: o `default.project.json` monta em `ServerStorage`, mas isso é o *plugin*,
não a saída.

---

## ❌ `Lumina` — incompatível com a regra nº 1

Não é um editor de `ParticleEmitter`: é um **motor de partículas próprio**, com grafo de
nós (`NodeSystem`, `ObjectPool`, `ParticleService`) avaliado **em tempo de execução**.

O script que ele gera começa assim — `src/API/VFXScriptCreator.ts`, linhas 50–54:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local APIFolder = ReplicatedStorage.Lumina_API.API
local TS = require(ReplicatedStorage.Lumina_API.include.RuntimeLib)
```

Duas dependências duras **fora da Tool**: a pasta `Lumina_API` e o `RuntimeLib` do
roblox-ts. Uma Tool que usasse isso **morre no teste que decide a regra nº 1** — arrastada
sozinha para um place vazio, o `require` erra na primeira linha.

Não há como "copiar o módulo para dentro": não é um módulo, é uma árvore de API mais o
runtime de uma linguagem transpilada. Vendorizar isso dentro de cada Tool é o oposto de
autocontenção — é 7 cópias de um framework.

A licença é MIT e o plugin é bom no que faz. O problema não é permissão, é arquitetura.

---

## O que fica decidido

- **Adotar** `vfx-editor` como ferramenta de autoria de emissor. Saída = instância, entra
  em `Tool/Efeitos/` desligada, acende por `Enabled` + `Rate`.
- **Ler** o formato de cutscene do `grims` e reimplementar como tabela de dados nos
  `CutsceneCam_*.lua`, trocando os `if marca ==` escritos à mão por keyframe declarativo.
  Nada de copiar: sem licença, não entra.
- **Não usar** `Lumina` em Tool. Motor de runtime fora da Tool é a regra nº 1 quebrada.

Nada foi vendorizado neste commit — isto é triagem, não integração.
