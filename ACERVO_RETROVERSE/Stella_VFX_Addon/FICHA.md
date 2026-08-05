# Modelo: Stella's VFX Addon

- Autor original:            **Stellabotrus** (declarado no cabeçalho dos módulos)
- Origem:                    `vfx_module.rbxmx` — addon do *Takeo's VFX System* (roblox.com/library/8199013483)
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-05
- Status:                    CRU — entra só como reforço opcional, nenhuma Tool depende dele
- Onde vive:                 `ReplicatedStorage/VFX_Module.rbxmx` — **não** vive no Acervo nem dentro da Tool

## Por que este material não está no Acervo

Ele é a **exceção declarada** à Regra nº 1: vive em `ReplicatedStorage` e é lido de lá pelo
`VFXModule` de cada Tool. Ver `DIRETRIZES/REGRA_AUTOCONTENCAO_ABSOLUTA.md`, seção
"A exceção declarada", e `ReplicatedStorage/README.md`.

O Acervo é prateleira de **edição**; este pack é dependência de **runtime**, opcional e
degradável. São coisas diferentes e por isso ele não é depositado aqui — esta ficha existe
para o registro de §12.12.3, não para reserva de material.

## Conteúdo

116 ModuleScripts, 46 emissores, 58 MeshParts. 30 efeitos chamáveis.

### Em uso pela ponte do `VFXModule`

| Efeito do pack | Reforça |
|---|---|
| `Shockwave` | `IMPACTO`, `IMPACTO_NOVA`, `ONDA_CHOQUE`, `RAJADA` |
| `Shockwave_2` | `IMPACTO_NOVA` |
| `Small_Nova` | `IMPACTO_NOVA` |
| `Smoky_Explosion` | `IMPACTO_NOVA`, `DESTROCOS`, `POEIRA` |
| `Shockwave_Explosion` | `DOMO` |
| `Small_Slash` | `CORTE`, `RETALHO`, `CORTE_X`, `GRADE_CORTES` |
| `Sonar_Ring` | `BLOQUEIO`, `PULSO_TRACAO`, `CICLONE`, `TEMPO_PARADO` |
| `Floor_Crack` | `RACHADURA_SOLO`, `DESTROCOS` |
| `Laser_Shot` | `FEIXE` |
| `Spiral_Effect` | `AURA`, `CICLONE` |

### Fora de uso, com motivo

| Efeito | Por que não entra |
|---|---|
| `Flung_Debris`, `Particle_Debris` | `Part` não-ancorada com velocidade e `CanCollide` — empurraria o personagem |
| `Impact_Frame` | troca `Sky`, liga `ColorCorrection`, põe `ScreenGui` |
| `Sharp_Crater`, `Smooth_Crater` | `workspace:GetDescendants()` a cada chamada |
| `Wind_Effect`, `Wind_Spiral` | exigem `Instance` de fora como âncora |
| `Fire_Circle` | contrato quebrado no próprio pack (`:Emit(Vector3)`) |

## Passe de conformidade (§12.12.2) — NÃO APLICADO

O pack **não passou** pelo passe, e é por isso que ele está CRU. A contagem de violações,
medida no arquivo:

| Violação | Ocorrências |
|---|---|
| `:Destroy()` | 114 |
| `math.random` | 92 |
| `Lighting` | 63 |
| `ReplicatedStorage` | 44 |
| `require(` | 36 |
| `Sky` | 24 |
| `:Emit(` | 21 |

Nada disso está dentro de Tool nenhuma: o pack roda no próprio contexto, no cliente, e o que
atravessa a ponte é chamada de função — forma, cor e tempo. Regra de jogo continua sendo
assunto do servidor e do Núcleo.
