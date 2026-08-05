# ReplicatedStorage — a exceção declarada

> **Esta pasta existe por uma exceção à Regra nº 1, e a exceção é declarada.**

## O que fica aqui, e por quê

| Arquivo | O que é |
|---|---|
| `VFX_Module.rbxmx` | `Stella's VFX Addon` + `LightningBolt` — 116 ModuleScripts, 46 emissores, 58 MeshParts |
| `VFX_Meshes.rbxmx` | pack de malhas de VFX — 200 `MeshPart`, 32 `Decal` |

## Por que não dentro da Tool

O pack **foi escrito para viver em `ReplicatedStorage`**. Não é preferência de
estilo; é como ele funciona:

| | |
|---|---|
| `Script.Parent = ReplicatedStorage` | o `MainModule` **se move para lá sozinho**, na primeira execução |
| `require(<id>)` × 36 | o cabeçalho manda: *"make sure to require via ID!"* |
| Dependência externa | é addon do **Takeo's VFX System**, que é outro módulo |
| `Lighting` / `Sky` × 63 / 24 | o `Impact_Frame` troca o skybox e guarda o antigo |

Copiar 116 ModuleScripts para dentro de cada uma das 7 Tools daria um arquivo
7× maior com 7 cópias do mesmo pack, e ainda assim o `MainModule` tentaria se
mudar para `ReplicatedStorage` no primeiro uso.

## O que a exceção custa, dito claramente

**O teste do place vazio deixa de valer para o VFX.** Arraste uma Tool sozinha
para um place sem este `ReplicatedStorage` e ela funciona — golpe, dano, som,
animação, tudo — mas **sem os efeitos do pack**. O `VFXModule` de cada Tool cai
nos efeitos próprios dela, que continuam lá dentro.

Ou seja: a Tool não quebra, ela empobrece. Foi essa a escolha, e foi consciente.

## O que a exceção NÃO autoriza

A exceção é **só para o módulo de VFX compartilhado**. Continua proibido:

- depositar `Sound`, `Mesh`, `Texture` ou pose de Tool em `ReplicatedStorage`
- `require(<id numérico>)` dentro de script de Tool
- qualquer outro `ReplicatedStorage` em script de Tool que não seja o módulo de VFX

`TESTES/verificar_autocontencao.sh` foi ajustado para permitir **exatamente**
essa referência e continuar barrando o resto.

## Instalação no place

1. `VFX_Module.rbxmx` → `ReplicatedStorage`
2. `VFX_Meshes.rbxmx` → `ReplicatedStorage`
3. As Tools → `StarterPack`

O `MainModule` se registra sozinho na primeira execução.

## Origem — pendente (§12.12.3)

| Campo | Valor |
|---|---|
| Autor | **Stellabotrus** (declarado no cabeçalho dos módulos) |
| Base | addon do *Takeo's VFX System* |
| Licença | **a confirmar** ⚠️ |
| Data de entrada | 2026-08-05 |

Autor está declarado — é o primeiro pack que chega com esse campo preenchido.
Falta a licença.
