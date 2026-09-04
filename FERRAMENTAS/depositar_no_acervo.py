#!/usr/bin/env python3
"""
depositar_no_acervo.py — Retro-Verse / Studios

Lê um modelo (.rbxm binário ou .rbxmx XML) e deposita o material audiovisual no
ACERVO_RETROVERSE, no formato do §12.16: FICHA, VFX com parâmetros, SFX com IDs,
malhas e o inventário de lógica.

    python3 FERRAMENTAS/depositar_no_acervo.py <arquivo> <Nome_Do_Modelo>

Aceita `.rbxm` (binário) e `.rbxmx` (XML) — a ferramenta escolhe o leitor.

O que sai:

    ACERVO_RETROVERSE/<Nome_Do_Modelo>/
    ├── FICHA.md              esqueleto — os 4 campos de §12.12.3 são SEUS de preencher
    ├── VFX/NOTAS.md          todo emitter/trail/beam com os parâmetros de verdade
    ├── SFX/ids.md            todo Sound com id, volume, pitch e rolloff
    ├── MALHAS/ids.md         MeshId e TextureId de tudo
    └── LOGICA/HABILIDADES.md inventário do que os scripts fazem

⚠️ O status sai **CRU**. Material recém-importado NÃO entra em Tool: falta o passe
de conformidade §12.12.2 e os quatro campos de origem. Quem preenche é gente, não
o script — é exatamente esse o ponto da regra.

A pasta LOGICA existe para CONSULTA. Lógica de combate de terceiro não entra em
Tool (§12.12.1); ela é catalogada para se saber o que a habilidade fazia, e então
reimplementá-la conforme, pelo Núcleo.
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extrair_rbxm import abrir as abrir_binario, caminho_de  # noqa: E402
from ler_rbxmx import abrir as abrir_xml  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ACERVO = os.path.join(RAIZ, "ACERVO_RETROVERSE")

CLASSES_EMISSOR = ("ParticleEmitter", "Trail", "Beam", "Smoke", "Fire", "Sparkles")
CLASSES_LUZ = ("PointLight", "SpotLight", "SurfaceLight", "Highlight")
CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")

# Propriedades que descrevem o efeito. A ordem é a de leitura, não a alfabética.
CAMPOS_EMISSOR = [
    "Texture", "Rate", "Lifetime", "Speed", "Size", "Transparency", "Color",
    "LightEmission", "LightInfluence", "Brightness", "Rotation", "RotSpeed",
    "Acceleration", "Drag", "VelocityInheritance", "SpreadAngle", "ZOffset",
    "EmissionDirection", "Orientation", "Shape", "LockedToPart", "Enabled",
    "Squash", "TimeScale",
]
CAMPOS_TRILHA = [
    "Texture", "Lifetime", "MinLength", "MaxLength", "WidthScale", "Color",
    "Transparency", "LightEmission", "LightInfluence", "FaceCamera", "Enabled",
]

PROIBIDOS = {
    "ScreenGui": "ScreenGui é proibido dentro da Tool (§12.12.4)",
    "SurfaceGui": "GUI de superfície: revisar caso a caso",
    "BillboardGui": "GUI de mundo: revisar caso a caso",
    "ColorCorrectionEffect": "efeito de tela — proibido (§12.12.1)",
    "BloomEffect": "efeito de tela — proibido",
    "BlurEffect": "efeito de tela — proibido",
    "SunRaysEffect": "efeito de tela — proibido",
    "Sky": "Sky é proibido (§12.12.1)",
    "Animation": "asset de Animation é proibido — virar pose CFrame (§10)",
    "Explosion": "Instance.new('Explosion') — usar detectarHumanoides (§12.6)",
}


def formatar(valor):
    if isinstance(valor, bool):
        return "true" if valor else "false"
    if isinstance(valor, float):
        return ("%g" % valor)
    if isinstance(valor, tuple):
        if len(valor) == 2 and all(isinstance(x, float) for x in valor):
            if valor[0] == valor[1]:
                return "%g" % valor[0]
            return "%g – %g" % valor
        return "(" + ", ".join("%g" % x if isinstance(x, float) else str(x)
                               for x in valor) + ")"
    if isinstance(valor, list):
        partes = []
        for ponto in valor:
            if len(ponto) == 3:                      # NumberSequence
                partes.append("%g→%g" % (ponto[0], ponto[1]))
            elif len(ponto) == 2:                    # ColorSequence
                r, g, b = ponto[1]
                partes.append("%g→rgb(%d,%d,%d)"
                              % (ponto[0], round(r * 255), round(g * 255),
                                 round(b * 255)))
        return " · ".join(partes)
    return str(valor)


def carregar(caminho):
    """Aceita os dois formatos: .rbxmx é XML, .rbxm é binário com blocos LZ4."""
    if caminho.lower().endswith(".rbxmx"):
        return abrir_xml(caminho)
    return abrir_binario(caminho)


def escrever(destino, texto):
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    with open(destino, "w", encoding="utf-8") as f:
        f.write(texto)


def secao_vfx(instancias, modelo):
    emissores = [i for i in instancias if i.classe in CLASSES_EMISSOR]
    luzes = [i for i in instancias if i.classe in CLASSES_LUZ]

    linhas = ["# %s — VFX" % modelo, ""]
    linhas.append("Extraído por `FERRAMENTAS/extrair_rbxm.py`. Os parâmetros abaixo são os do")
    linhas.append("modelo original, não estimativas: dá para reconstruir o efeito só com esta tabela.")
    linhas.append("")
    linhas.append("**Status: CRU.** Nenhum destes entra em Tool antes do passe §12.12.2.")
    linhas.append("")
    linhas.append("## Resumo")
    linhas.append("")
    linhas.append("| Tipo | Quantidade |")
    linhas.append("|---|---|")
    contagem = {}
    for i in emissores + luzes:
        contagem[i.classe] = contagem.get(i.classe, 0) + 1
    for classe, quantos in sorted(contagem.items(), key=lambda x: -x[1]):
        linhas.append("| `%s` | %d |" % (classe, quantos))
    linhas.append("")

    # dedup: emitters idênticos aparecem várias vezes nesses modelos
    vistos = {}
    for e in emissores:
        campos = CAMPOS_TRILHA if e.classe in ("Trail", "Beam") else CAMPOS_EMISSOR
        assinatura = (e.classe, e.nome,
                      tuple(formatar(e.props.get(c)) for c in campos))
        vistos.setdefault(assinatura, []).append(e)

    linhas.append("## Emissores")
    linhas.append("")
    for assinatura, grupo in sorted(vistos.items(), key=lambda x: x[0][1]):
        classe, nome, _ = assinatura
        campos = CAMPOS_TRILHA if classe in ("Trail", "Beam") else CAMPOS_EMISSOR
        exemplo = grupo[0]
        linhas.append("### `%s` — %s%s" % (nome, classe,
                                           "  (×%d idênticos)" % len(grupo)
                                           if len(grupo) > 1 else ""))
        linhas.append("")
        linhas.append("Caminho: `%s`" % caminho_de(exemplo))
        linhas.append("")
        linhas.append("| Propriedade | Valor |")
        linhas.append("|---|---|")
        for campo in campos:
            if campo in exemplo.props:
                linhas.append("| `%s` | %s |" % (campo, formatar(exemplo.props[campo])))
        linhas.append("")

    if luzes:
        linhas.append("## Luz e realce")
        linhas.append("")
        linhas.append("| Nome | Classe | Caminho |")
        linhas.append("|---|---|---|")
        for luz in luzes:
            linhas.append("| `%s` | `%s` | `%s` |" % (luz.nome, luz.classe,
                                                      caminho_de(luz)))
        linhas.append("")

    return "\n".join(linhas) + "\n"


def secao_sfx(instancias, modelo):
    sons = [i for i in instancias if i.classe == "Sound"]
    linhas = ["# %s — SFX" % modelo, ""]
    linhas.append("**Status: CRU.** Volume e pitch são os do modelo original.")
    linhas.append("")
    linhas.append("Ao montar a Tool, cada um vira um `Sound` **dentro** dela, em `Tool/SFX/`")
    linhas.append("(Regra nº 1). O script clona o molde; nunca cria `SoundId` solto.")
    linhas.append("")
    linhas.append("| Nome | ID | Volume | Pitch | RollOff | Loop | Caminho |")
    linhas.append("|---|---|---|---|---|---|---|")
    for s in sorted(sons, key=lambda x: x.nome):
        ident = s.props.get("SoundId", "")
        achado = re.search(r"(\d{5,})", ident or "")
        ident = "`rbxassetid://%s`" % achado.group(1) if achado else "(sem id)"
        linhas.append("| `%s` | %s | %s | %s | %s | %s | `%s` |" % (
            s.nome, ident,
            formatar(s.props.get("Volume", "")),
            formatar(s.props.get("PlaybackSpeed", "")),
            formatar(s.props.get("RollOffMaxDistance", "")),
            formatar(s.props.get("Looped", "")),
            caminho_de(s)))
    linhas.append("")
    return "\n".join(linhas) + "\n"


def secao_malhas(instancias, modelo):
    campos = ("MeshId", "TextureID", "TextureId", "Texture", "Image")
    achados = []
    for i in instancias:
        for campo in campos:
            valor = i.props.get(campo)
            if isinstance(valor, str) and valor.strip():
                achados.append((i, campo, valor))

    linhas = ["# %s — malhas e texturas" % modelo, ""]
    linhas.append("**Status: CRU.** IDs prontos para reuso; a instância que os carrega")
    linhas.append("tem de ser **filha da Tool** (Regra nº 1).")
    linhas.append("")
    linhas.append("| Instância | Classe | Campo | ID |")
    linhas.append("|---|---|---|---|")
    for inst, campo, valor in sorted(achados, key=lambda x: x[0].nome):
        achado = re.search(r"(\d{5,})", valor)
        mostrar = "`rbxassetid://%s`" % achado.group(1) if achado else "`%s`" % valor
        linhas.append("| `%s` | `%s` | `%s` | %s |" % (inst.nome, inst.classe,
                                                       campo, mostrar))
    linhas.append("")
    return "\n".join(linhas) + "\n"


def secao_logica(instancias, modelo):
    scripts = [i for i in instancias if i.classe in CLASSES_SCRIPT]
    linhas = ["# %s — inventário de lógica" % modelo, ""]
    linhas.append("> ⚠️ **Isto é CONSULTA, não material de reuso.** Lógica de combate de")
    linhas.append("> terceiro **não entra em Tool** (§12.12.1). Está catalogada para se saber")
    linhas.append("> o que cada habilidade fazia, e então reimplementá-la conforme, pelo Núcleo.")
    linhas.append("")

    # teclas
    teclas = set()
    for s in scripts:
        for achado in re.findall(r"KeyCode\.(\w+)", s.props.get("Source", "")):
            teclas.add(achado)
    if teclas:
        linhas.append("## Teclas encontradas")
        linhas.append("")
        linhas.append(", ".join("`%s`" % t for t in sorted(teclas)))
        linhas.append("")

    # dano
    danos = []
    for s in scripts:
        fonte = s.props.get("Source", "")
        for achado in re.findall(r"TakeDamage\(\s*([^)\n]{1,40})\)", fonte):
            danos.append((s.nome, achado.strip()))
        for achado in re.findall(r"Health\s*=\s*[^\n]{1,50}", fonte):
            danos.append((s.nome, achado.strip()))
    if danos:
        linhas.append("## Dano aplicado")
        linhas.append("")
        linhas.append("| Script | Chamada |")
        linhas.append("|---|---|")
        for nome, chamada in danos[:40]:
            linhas.append("| `%s` | `%s` |" % (nome, chamada.replace("|", "\\|")))
        linhas.append("")

    # achados proibidos
    achados_proibidos = {}
    for i in instancias:
        if i.classe in PROIBIDOS:
            achados_proibidos.setdefault(i.classe, []).append(caminho_de(i))
    padroes = {
        r"require\(\s*\d": "require de id numérico — proibido (§12.12.1)",
        r"math\.random": "math.random em gameplay — proibido (§10)",
        r"(?<!task\.)\bwait\(": "wait() — usar task.wait",
        r"(?<!task\.)\bspawn\(": "spawn() — usar task.spawn",
        r"\btick\(": "tick() — usar acumulador dt / os.clock",
        r":Destroy\(\)": ":Destroy() em instância — usar Parent = nil / Debris",
        r"BreakJoints": "BreakJoints — fura ForceField",
        r"AncestryChanged": "AncestryChanged — usar Tool.Destroying",
        r"IsTeamMate": "IsTeamMate reimplementado — a porta é o Núcleo",
        r"TagHumanoid": "TagHumanoid reimplementado — a porta é o Núcleo",
        r":Emit\(": ":Emit no servidor — o servidor transmite, não emite",
        r"LoadAnimation": "LoadAnimation — virar pose CFrame",
    }
    contagem_padrao = {}
    for s in scripts:
        fonte = s.props.get("Source", "")
        for padrao, motivo in padroes.items():
            achados = len(re.findall(padrao, fonte))
            if achados:
                contagem_padrao[motivo] = contagem_padrao.get(motivo, 0) + achados

    linhas.append("## Achados do passe §12.12.2")
    linhas.append("")
    linhas.append("| Achado | Ocorrências | Situação |")
    linhas.append("|---|---|---|")
    for classe, caminhos in sorted(achados_proibidos.items()):
        linhas.append("| `%s` — %s | %d | ❌ excluir |"
                      % (classe, PROIBIDOS[classe], len(caminhos)))
    for motivo, quantos in sorted(contagem_padrao.items(), key=lambda x: -x[1]):
        linhas.append("| %s | %d | ❌ corrigir |" % (motivo, quantos))
    linhas.append("")

    linhas.append("## Scripts")
    linhas.append("")
    linhas.append("| Linhas | Classe | Caminho |")
    linhas.append("|---|---|---|")
    for s in sorted(scripts, key=lambda x: -len(x.props.get("Source", ""))):
        linhas.append("| %d | `%s` | `%s` |"
                      % (len(s.props.get("Source", "").splitlines()),
                         s.classe, caminho_de(s)))
    linhas.append("")
    return "\n".join(linhas) + "\n"


def ficha(modelo, instancias, arquivo):
    tools = [i for i in instancias if i.classe == "Tool"]
    nome_tool = tools[0].nome if tools else "(sem Tool na raiz)"
    return """# Modelo: %s

- **Autor original:** _(preencher)_
- **Origem:** `%s`
- **Licença / permissão:** _(preencher)_
- **Data de entrada:** _(preencher)_
- **Status: CRU**   (CRU | LIMPO | APROVADO)
- **Violações corrigidas:** _(nenhuma ainda — o passe §12.12.2 não foi executado)_
- **Excluído do acervo:** _(preencher ao rodar o passe)_
- **Já usado em:** —

> ⚠️ **Sem os quatro campos acima — autor, origem, licença, data — este material
> fica CRU e NÃO pode entrar em Tool** (§12.12.3).

Tool de origem no modelo: `%s`

---

## Conteúdo depositado

| Pasta | O que tem |
|---|---|
| `VFX/NOTAS.md` | Emissores com os parâmetros de verdade |
| `SFX/ids.md` | Sons com id, volume, pitch e rolloff |
| `MALHAS/ids.md` | `MeshId` e `TextureId` |
| `LOGICA/HABILIDADES.md` | Inventário do que os scripts faziam — **consulta, não reuso** |

## Como usar isto numa Tool nova

1. Ler o `VFX/NOTAS.md` e escolher o efeito.
2. Reescrever o efeito conforme (`_PADROES.md`): sem `math.random`, sem `wait`,
   sem `:Destroy()`, rodando **no cliente** por `VFXRemote`.
3. Copiar o `Sound` e o emitter **para dentro da Tool** (`SFX/` e `Efeitos/`).
4. Marcar o status na ficha: CRU → LIMPO → APROVADO.
""" % (modelo, os.path.basename(arquivo), nome_tool)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1

    arquivo, modelo = sys.argv[1], sys.argv[2]
    dados = carregar(arquivo)
    instancias = list(dados["instancias"].values())
    base = os.path.join(ACERVO, modelo)

    escrever(os.path.join(base, "FICHA.md"), ficha(modelo, instancias, arquivo))
    escrever(os.path.join(base, "VFX", "NOTAS.md"), secao_vfx(instancias, modelo))
    escrever(os.path.join(base, "SFX", "ids.md"), secao_sfx(instancias, modelo))
    escrever(os.path.join(base, "MALHAS", "ids.md"), secao_malhas(instancias, modelo))
    escrever(os.path.join(base, "LOGICA", "HABILIDADES.md"),
             secao_logica(instancias, modelo))

    print("depositado em ACERVO_RETROVERSE/%s/" % modelo)
    for pasta, _, arquivos in os.walk(base):
        for a in sorted(arquivos):
            caminho = os.path.join(pasta, a)
            print("  %7d bytes  %s" % (os.path.getsize(caminho),
                                       os.path.relpath(caminho, RAIZ)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
