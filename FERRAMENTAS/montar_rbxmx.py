#!/usr/bin/env python3
"""
montar_rbxmx.py — Retro-Verse / Studios

Monta o arquivo .rbxmx de cada Tool a partir dos .lua da própria pasta.

    python3 FERRAMENTAS/montar_rbxmx.py            # monta todas
    python3 FERRAMENTAS/montar_rbxmx.py AvoDoTempo # monta uma

Por que um montador, e não XML escrito à mão: o .rbxmx é DERIVADO dos .lua.
Editou o Lua, roda isto de novo. Assim o arquivo que vai para o Studio nunca
diverge do código que está no repositório.

Regra nº 1 — autocontenção absoluta: o .rbxmx sai completo. Handle, scripts,
Values, RemoteEvents, SFX e Efeitos, tudo dentro da Tool. Arraste para um place
vazio e funciona.
"""

import os
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")

# ---------------------------------------------------------------- enums Roblox

MATERIAL = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Metal": 1088,
            "Glass": 1568, "Slate": 800}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}


def cor(r, g, b):
    """Color3uint8 é 0xFF<RR><GG><BB> como inteiro sem sinal."""
    return (0xFF << 24) | (r << 16) | (g << 8) | b


# ---------------------------------------------------------------- catálogo

BASE = (154, 205, 50)      # BASECOLOR do modelo Guardião do Tempo
BRONZE = (124, 100, 58)
ESCURO = (48, 42, 34)

# SFX: nome do Sound -> (id, volume, pitch, rolloff)
CATALOGO = {
    "TemperoTemporal": {
        "tooltip": "Tempero Temporal - recolhe o tempo em volta e devolve tudo de uma vez",
        "classe": "Melee", "energia": 0, "recarga": 0, "extra": False,
        "sfx": {"Golpe": (588694531, 5.0, 1.0, 60), "Onda": (588738949, 5.0, 1.0, 60)},
    },
    "Cronostase": {
        "tooltip": "Cronostase - marca um ponto no tempo. Ative de novo para voltar a ele",
        "classe": "Magic", "energia": 0, "recarga": 0, "extra": False,
        "sfx": {"Marca": (588738949, 5.0, 1.0, 60), "Retorno": (782202168, 5.0, 1.0, 60)},
    },
    "AvancoRapido": {
        "tooltip": "Avanço Rápido - atravesse o instante. M alterna a aceleração",
        "classe": "Melee", "energia": 0, "recarga": 0, "extra": True,
        "sfx": {"Avanco": (447682521, 4.0, 0.7, 60), "Aceleracao": (743521450, 4.0, 1.5, 60)},
    },
    "CanhaoCronos": {
        "tooltip": "Canhão Cronos - concentra o tempo numa linha e solta",
        "classe": "Ranged", "energia": 0, "recarga": 9, "extra": False,
        "sfx": {"Carga": (743521450, 4.0, 0.8, 70), "Disparo": (908895929, 5.0, 1.5, 80)},
    },
    "Temporalise": {
        "tooltip": "Temporálise - o tempo para para todo mundo, menos para você",
        "classe": "Debuff", "energia": 0, "recarga": 22, "extra": False,
        "sfx": {"Parada": (447682521, 5.0, 0.7, 80), "Retomada": (743521450, 4.0, 3.0, 80)},
    },
    "ArmadilhaTemporal": {
        "tooltip": "Armadilha Temporal - deixe o tempo esperando por alguém",
        "classe": "Summon", "energia": 0, "recarga": 5, "extra": False,
        "sfx": {"Plantar": (447682521, 4.0, 0.7, 60), "Disparo": (782199941, 6.0, 1.5, 70)},
    },
    "AvoDoTempo": {
        "tooltip": "Avô do Tempo - a hora chega para todos. T provoca",
        "classe": "Magic", "energia": 0, "recarga": 45, "extra": True,
        "sfx": {"Badalada": (850256806, 7.0, 1.0, 80), "Voz": (819312817, 7.0, 1.0, 80),
                "Provocacao": (819373088, 7.0, 1.0, 80)},
    },
}


# ---------------------------------------------------------------- XML

class Montador:
    def __init__(self):
        self.n = 0

    def ref(self):
        self.n += 1
        return "RBX%d" % self.n

    def item(self, pai, classe):
        it = ET.SubElement(pai, "Item", {"class": classe, "referent": self.ref()})
        ET.SubElement(it, "Properties")
        return it

    @staticmethod
    def props(item):
        return item.find("Properties")

    def p_string(self, item, nome, valor):
        e = ET.SubElement(self.props(item), "string", {"name": nome})
        e.text = valor

    def p_bool(self, item, nome, valor):
        e = ET.SubElement(self.props(item), "bool", {"name": nome})
        e.text = "true" if valor else "false"

    def p_float(self, item, nome, valor):
        e = ET.SubElement(self.props(item), "float", {"name": nome})
        e.text = repr(float(valor))

    def p_double(self, item, nome, valor):
        e = ET.SubElement(self.props(item), "double", {"name": nome})
        e.text = repr(float(valor))

    def p_int(self, item, nome, valor):
        e = ET.SubElement(self.props(item), "int", {"name": nome})
        e.text = str(int(valor))

    def p_token(self, item, nome, valor):
        e = ET.SubElement(self.props(item), "token", {"name": nome})
        e.text = str(int(valor))

    def p_cor(self, item, valor):
        e = ET.SubElement(self.props(item), "Color3uint8", {"name": "Color3uint8"})
        e.text = str(valor)

    def p_vetor(self, item, nome, x, y, z):
        e = ET.SubElement(self.props(item), "Vector3", {"name": nome})
        for eixo, v in (("X", x), ("Y", y), ("Z", z)):
            ET.SubElement(e, eixo).text = repr(float(v))

    def p_cframe(self, item, nome, pos, rot=None):
        rot = rot or (1, 0, 0, 0, 1, 0, 0, 0, 1)
        e = ET.SubElement(self.props(item), "CoordinateFrame", {"name": nome})
        for eixo, v in (("X", pos[0]), ("Y", pos[1]), ("Z", pos[2])):
            ET.SubElement(e, eixo).text = repr(float(v))
        for i, chave in enumerate(("R00", "R01", "R02", "R10", "R11", "R12",
                                   "R20", "R21", "R22")):
            ET.SubElement(e, chave).text = repr(float(rot[i]))

    def p_fonte(self, item, codigo):
        # ProtectedString com CDATA. `]]>` quebraria o CDATA — nenhum .lua daqui
        # tem essa sequência, mas a checagem existe para nunca gerar XML inválido.
        if "]]>" in codigo:
            raise ValueError("fonte contém ]]> e quebraria o CDATA")
        e = ET.SubElement(self.props(item), "ProtectedString", {"name": "Source"})
        e.text = codigo

    def p_conteudo(self, item, nome, url):
        e = ET.SubElement(self.props(item), "Content", {"name": nome})
        ET.SubElement(e, "url").text = url

    def p_ref(self, item, nome, alvo):
        e = ET.SubElement(self.props(item), "Ref", {"name": nome})
        e.text = alvo

    # -------------------------------------------------------- peças

    def parte(self, pai, nome, tamanho, posicao, rgb, material, forma,
              transparencia=0.0, colide=False, reflexo=0.0, rot=None):
        it = self.item(pai, "Part")
        self.p_string(it, "Name", nome)
        self.p_vetor(it, "size", *tamanho)
        self.p_cframe(it, "CFrame", posicao, rot)
        self.p_cor(it, cor(*rgb))
        self.p_token(it, "Material", MATERIAL[material])
        self.p_token(it, "shape", SHAPE[forma])
        self.p_bool(it, "Anchored", False)
        self.p_bool(it, "CanCollide", colide)
        self.p_bool(it, "CanQuery", False)
        self.p_bool(it, "CanTouch", False)
        self.p_bool(it, "CastShadow", False)
        self.p_bool(it, "Massless", True)
        self.p_bool(it, "Locked", True)
        self.p_float(it, "Transparency", transparencia)
        self.p_float(it, "Reflectance", reflexo)
        # sem topo/base decorativos
        for lado in ("Top", "Bottom", "Front", "Back", "Left", "Right"):
            self.p_token(it, lado + "Surface", 0)
        return it

    def script(self, pai, classe, nome, codigo):
        it = self.item(pai, classe)
        self.p_string(it, "Name", nome)
        self.p_bool(it, "Disabled", False)
        self.p_fonte(it, codigo)
        return it

    def som(self, pai, nome, ident, volume, pitch, rolloff):
        it = self.item(pai, "Sound")
        self.p_string(it, "Name", nome)
        self.p_conteudo(it, "SoundId", "rbxassetid://%d" % ident)
        self.p_float(it, "Volume", volume)
        self.p_float(it, "PlaybackSpeed", pitch)
        self.p_float(it, "RollOffMaxDistance", rolloff)
        self.p_float(it, "RollOffMinDistance", 8)
        self.p_bool(it, "Looped", False)
        self.p_bool(it, "PlayOnRemove", False)
        return it


# ---------------------------------------------------------------- handle

def montar_handle(m, tool):
    """
    Relógio de bolso, montado com primitivas.

    O .rbxmx de origem foi salvo com as SharedStrings de malha VAZIAS: toda
    UnionOperation dele aponta para um blob de 0 byte, e no Studio apareceria
    como caixa cinza. Por isso o Handle é construído aqui, e não copiado —
    assim ele é geometria de verdade e não depende de nada de fora (Regra nº 1).
    """
    # cilindro tem o eixo circular em X local; Ry(90) põe a face virada para Z
    ry90 = (0, 0, 1, 0, 1, 0, -1, 0, 0)

    handle = m.parte(tool, "Handle", (0.35, 1.5, 1.5), (0, 0, 0), BRONZE,
                     "Metal", "Cylinder", colide=False, reflexo=0.25, rot=ry90)
    ref_handle = handle.get("referent")

    decorativas = [
        # nome,            tamanho,             posição,          cor,  material, forma, rot
        ("Mostrador", (0.38, 1.22, 1.22), (0, 0, 0), BASE, "Neon", "Cylinder", ry90),
        ("Aro", (0.30, 1.62, 1.62), (0, 0, 0), ESCURO, "Metal", "Cylinder", ry90),
        ("PonteiroHora", (0.06, 0.44, 0.06), (0, 0.20, 0.20), ESCURO, "SmoothPlastic", "Block", None),
        ("PonteiroMinuto", (0.30, 0.05, 0.05), (0.14, 0, 0.20), ESCURO, "SmoothPlastic", "Block", None),
        ("Pino", (0.10, 0.10, 0.10), (0, 0, 0.21), BRONZE, "Metal", "Ball", None),
    ]

    for nome, tam, pos, rgb, mat, forma, rot in decorativas:
        peca = m.parte(handle, nome, tam, pos, rgb, mat, forma, rot=rot)
        # WeldConstraint solda na posição relativa em que a peça já está
        solda = m.item(peca, "WeldConstraint")
        m.p_string(solda, "Name", "Solda" + nome)
        m.p_bool(solda, "Enabled", True)
        m.p_ref(solda, "Part0", ref_handle)
        m.p_ref(solda, "Part1", peca.get("referent"))

    return handle


# ---------------------------------------------------------------- montagem

def ler(caminho):
    with open(caminho, "r", encoding="utf-8") as f:
        return f.read()


def montar(nome):
    pasta = os.path.join(TOOLS, nome)
    dados = CATALOGO[nome]

    fonte_servidor = ler(os.path.join(pasta, "%s_Server_V1.lua" % nome))
    fonte_cliente = ler(os.path.join(pasta, "Client.lua"))
    fonte_animator = ler(os.path.join(pasta, "R6CFrameAnimator.lua"))
    fonte_vfx = ler(os.path.join(pasta, "VFXModule.lua"))
    fonte_poses = ler(os.path.join(pasta, "Poses_GuardiaoDoTempo_%s_V1.lua" % nome))

    m = Montador()
    raiz = ET.Element("roblox", {
        "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd",
        "version": "4",
    })
    ET.SubElement(raiz, "External").text = "null"
    ET.SubElement(raiz, "External").text = "nil"

    tool = m.item(raiz, "Tool")
    m.p_string(tool, "Name", nome)
    m.p_string(tool, "ToolTip", dados["tooltip"])
    m.p_bool(tool, "CanBeDropped", False)
    m.p_bool(tool, "RequiresHandle", True)
    m.p_bool(tool, "Enabled", True)
    m.p_bool(tool, "ManualActivationOnly", False)
    # Grip identidade: o Handle assenta no centro da mão. Ajuste fino é no Studio,
    # e as propriedades Grip* NÃO replicam do cliente — só valem no servidor.
    m.p_cframe(tool, "Grip", (0, 0, 0))

    montar_handle(m, tool)

    # Values — a Tool declara o que É (§12.4)
    v = m.item(tool, "StringValue")
    m.p_string(v, "Name", "DamageClass")
    m.p_string(v, "Value", dados["classe"])

    v = m.item(tool, "NumberValue")
    m.p_string(v, "Name", "EnergyCost")
    m.p_double(v, "Value", dados["energia"])

    v = m.item(tool, "NumberValue")
    m.p_string(v, "Name", "RecargaGlobal")
    m.p_double(v, "Value", dados["recarga"])

    # Scripts
    m.script(tool, "Script", "%s_Server_V1" % nome, fonte_servidor)
    m.script(tool, "LocalScript", "Client", fonte_cliente)
    m.script(tool, "ModuleScript", "R6CFrameAnimator", fonte_animator)
    m.script(tool, "ModuleScript", "VFXModule", fonte_vfx)
    m.script(tool, "ModuleScript", "Poses", fonte_poses)

    # Remotes
    r = m.item(tool, "RemoteEvent")
    m.p_string(r, "Name", "VFXRemote")
    if dados["extra"]:
        r = m.item(tool, "RemoteEvent")
        m.p_string(r, "Name", "AcaoRemote")

    # SFX — todo Sound é filho da Tool (Regra nº 1)
    pasta_sfx = m.item(tool, "Folder")
    m.p_string(pasta_sfx, "Name", "SFX")
    for nome_som, (ident, vol, pitch, roll) in sorted(dados["sfx"].items()):
        m.som(pasta_sfx, nome_som, ident, vol, pitch, roll)

    # Efeitos — vazia de propósito: sem molde, o VFXModule desenha procedural
    pasta_efeitos = m.item(tool, "Folder")
    m.p_string(pasta_efeitos, "Name", "Efeitos")

    destino = os.path.join(pasta, "%s.rbxmx" % nome)
    ET.ElementTree(raiz).write(destino, encoding="utf-8", xml_declaration=False)

    # ProtectedString precisa de CDATA, e o ElementTree escapa em vez de embrulhar
    with open(destino, "r", encoding="utf-8") as f:
        texto = f.read()
    texto = envolver_cdata(texto)
    with open(destino, "w", encoding="utf-8") as f:
        f.write(texto)

    return destino, os.path.getsize(destino)


def envolver_cdata(texto):
    """Troca o escape do ElementTree por CDATA nas fontes de script."""
    import re

    def trocar(m):
        corpo = m.group(1)
        corpo = (corpo.replace("&lt;", "<").replace("&gt;", ">")
                      .replace("&quot;", '"').replace("&#10;", "\n")
                      .replace("&amp;", "&"))
        return '<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>' % corpo

    return re.sub(r'<ProtectedString name="Source">(.*?)</ProtectedString>',
                  trocar, texto, flags=re.S)


def main():
    alvos = sys.argv[1:] or sorted(CATALOGO.keys())
    for nome in alvos:
        if nome not in CATALOGO:
            print("desconhecida: %s" % nome)
            continue
        destino, tamanho = montar(nome)
        print("%-20s %7d bytes  %s" % (nome, tamanho,
                                       os.path.relpath(destino, RAIZ)))


if __name__ == "__main__":
    main()
