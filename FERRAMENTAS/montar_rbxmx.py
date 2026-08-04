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
        "sfx": {"Golpe": (588694531, 5.0, 1.0, 60), "Onda": (588738949, 5.0, 1.0, 60),
                "Estilhaco": (935843979, 5.0, 1.0, 60), "Faisca": (785201669, 4.0, 1.2, 60)},
    },
    "Cronostase": {
        "tooltip": "Cronostase - marca um ponto no tempo. Ative de novo para voltar a ele",
        "classe": "Magic", "energia": 0, "recarga": 0, "extra": False,
        "sfx": {"Marca": (588738949, 5.0, 1.0, 60), "Retorno": (782202168, 5.0, 1.0, 60),
                "Estelar": (1846396833, 5.0, 1.0, 60)},
    },
    "AvancoRapido": {
        "tooltip": "Avanço Rápido - adianta o tempo até tudo em volta envelhecer. M acelera",
        "classe": "Magic", "energia": 0, "recarga": 60, "extra": True,
        "sfx": {"Avanco": (447682521, 4.0, 0.7, 60), "Aceleracao": (743521450, 4.0, 1.5, 60),
                "Estouro": (763717897, 6.0, 0.9, 90), "Brasa": (114121130345944, 5.0, 1.0, 80)},
    },
    "CanhaoCronos": {
        "tooltip": "Canhão Cronos - concentra o tempo numa linha e solta",
        "classe": "Ranged", "energia": 0, "recarga": 9, "extra": False,
        "sfx": {"Carga": (743521450, 4.0, 0.8, 70), "Disparo": (908895929, 5.0, 1.5, 80),
                "Raio": (96478259, 5.0, 1.1, 80), "Impacto": (9125403260, 5.0, 1.0, 70)},
    },
    "Temporalise": {
        "tooltip": "Temporálise - o tempo para para todo mundo, menos para você",
        "classe": "Debuff", "energia": 0, "recarga": 22, "extra": False,
        "sfx": {"Parada": (447682521, 5.0, 0.7, 80), "Retomada": (743521450, 4.0, 3.0, 80),
                "Estelar": (1846396833, 5.0, 0.9, 80), "Brasa": (6271036459, 4.0, 1.0, 70)},
    },
    "ArmadilhaTemporal": {
        "tooltip": "Armadilha Temporal - deixe o tempo esperando por alguém",
        "classe": "Summon", "energia": 0, "recarga": 5, "extra": False,
        "sfx": {"Plantar": (447682521, 4.0, 0.7, 60), "Disparo": (782199941, 6.0, 1.5, 70),
                "Brasa": (114121130345944, 4.0, 1.1, 70), "Faisca": (785201669, 4.0, 1.2, 60)},
    },

    "PulsoGravitacional": {
        "tooltip": "Pulso Gravitacional - comprime a gravidade ao redor. X lança singularidade",
        "classe": "Magic", "energia": 0, "recarga": 16, "extra": True,
        "sfx": {"Golpe": (9125403260, 5.0, 0.8, 80)},
    },
    "CampoZeroG": {
        "tooltip": "Campo Zero G - levita inimigos em órbita curta. X detona o campo",
        "classe": "Debuff", "energia": 0, "recarga": 16, "extra": True,
        "sfx": {"Golpe": (447682521, 4.0, 0.7, 80)},
    },
    "MaoTelecinetica": {
        "tooltip": "Mão Telecinética - empurra alvos com força mental. X puxa todos para você",
        "classe": "Magic", "energia": 0, "recarga": 16, "extra": True,
        "sfx": {"Golpe": (743521450, 4.0, 1.4, 80)},
    },
    "OrbitaPsi": {
        "tooltip": "Órbita Psi - anéis telecinéticos protegem e cortam. X expande a órbita",
        "classe": "Hybrid", "energia": 0, "recarga": 16, "extra": True,
        "sfx": {"Golpe": (588738949, 4.0, 1.1, 80)},
    },
    "LancaVetorial": {
        "tooltip": "Lança Vetorial - arremessa uma linha de força gravitacional. X perfura em área",
        "classe": "Ranged", "energia": 0, "recarga": 16, "extra": True,
        "sfx": {"Golpe": (908895929, 5.0, 1.5, 90)},
    },
    "PocoDeMassa": {
        "tooltip": "Poço de Massa - cria um peso absurdo no chão. X colapsa o poço",
        "classe": "Debuff", "energia": 0, "recarga": 16, "extra": True,
        "sfx": {"Golpe": (763717897, 5.0, 0.8, 90)},
    },
    "MarionetePsi": {
        "tooltip": "Marionete Psi - dobra a postura dos alvos com telecinese. X explode o vínculo",
        "classe": "Summon", "energia": 0, "recarga": 16, "extra": True,
        "sfx": {"Golpe": (782199941, 5.0, 1.2, 80)},
    },
    "AvoDoTempo": {
        "tooltip": "Avô do Tempo - a hora chega para todos. T provoca",
        "classe": "Magic", "energia": 0, "recarga": 45, "extra": True,
        "sfx": {"Badalada": (850256806, 7.0, 1.0, 80), "Voz": (819312817, 7.0, 1.0, 80),
                "Provocacao": (819373088, 7.0, 1.0, 80),
                "Supernova": (95335614812989, 8.0, 1.0, 90), "Raio": (96478346, 6.0, 1.0, 85), "Estouro": (401056199, 7.0, 0.9, 90)},
    },
}


# ---------------------------------------------------------------- efeitos novos
#
# ACRESCENTADOS ao conjunto Guardião do Tempo. Os cinco efeitos originais
# (ONDA_TEMPORAL, ESFERA_TEMPORAL, MOSTRADOR_TEMPORAL, DETRITOS, TREMOR)
# continuam existindo e não foram tocados — estes entram POR CIMA.
#
# Curvas (Size, Transparency, Rate, Speed, Lifetime) são as do modelo de origem,
# extraídas por FERRAMENTAS/extrair_rbxm.py. A COR foi trocada para a paleta do
# Guardião, que é o que costura o material de dois modelos diferentes no mesmo
# conjunto — a leitura visual é do Guardião, o comportamento é do original.
#
# Passe §12.12.2 aplicado: Enabled = false na origem, e o cliente liga por
# Enabled + Rate. Zero :Emit(), no servidor ou fora dele.

VERDE = (0.604, 0.804, 0.196)      # 154,205,50 — BASECOLOR do Guardião
VERDE_CLARO = (0.78, 0.95, 0.45)
BRANCO = (1.0, 1.0, 1.0)

EFEITOS = {
    # Jupiter: PlasmaEmitter + ExplosionBrightspot do gerador de raio
    "RAIO_TEMPORAL": [
        ("Plasma", {
            "textura": "rbxasset://textures/particles/sparkles_main.dds",
            "rate": 10000.0, "vida": (0.1, 0.2), "velocidade": (100.0, 100.0),
            "tamanho": [(0.0, 18.0, 0.0), (1.0, 18.0, 0.0)],
            "transparencia": [(0.0, 0.0, 0.0), (1.0, 0.3, 0.0)],
            "cor": [(0.0, VERDE_CLARO), (1.0, VERDE)],
            "emissao": 1.0, "influencia": 1.0, "brilho": 1.0,
            "rotacao": (0.0, 360.0), "zoffset": 5.0,
        }),
        ("Clarao", {
            "textura": "rbxassetid://243098098",
            "rate": 1000.0, "vida": (0.2, 0.2), "velocidade": (0.0, 0.0),
            "tamanho": [(0.0, 10.0, 0.0), (0.1166, 0.2105, 0.2105),
                        (0.342, 9.5263, 0.4737), (0.4785, 0.8421, 0.8421),
                        (0.6733, 9.7895, 0.0), (0.7929, 1.6316, 1.6316),
                        (1.0, 10.0, 0.0)],
            "transparencia": [(0.0, 0.0, 0.0), (1.0, 0.0, 0.0)],
            "cor": [(0.0, VERDE_CLARO), (1.0, VERDE_CLARO)],
            "emissao": 1.0, "influencia": 0.0, "brilho": 10.0,
            "rotacao": (0.0, 360.0), "zoffset": 2.0,
        }),
    ],

    # Cosmic Entity: StarSplash + Stars
    "ESTILHACO_ESTELAR": [
        ("Estrelas", {
            "textura": "rbxassetid://1141830599",
            "rate": 600.0, "vida": (1.0, 2.0), "velocidade": (50.0, 100.0),
            "tamanho": [(0.0, 7.0, 3.0), (0.1, 7.0, 3.0), (0.2, 7.0, 3.0),
                        (0.35, 0.0, 0.0), (0.5, 7.0, 3.0), (0.7, 7.0, 3.0),
                        (1.0, 0.0, 0.0)],
            "transparencia": [(0.0, 0.0, 0.0), (1.0, 1.0, 0.0)],
            "cor": [(0.0, BRANCO), (1.0, VERDE)],
            "emissao": 1.0, "influencia": 0.0, "brilho": 1.0,
            "rotacao": (20.0, 20.0), "arrasto": 2.0,
        }),
        ("Cintilar", {
            "textura": "rbxassetid://5242069486",
            "rate": 50.0, "vida": (1.0, 1.0), "velocidade": (1.0, 1.0),
            "tamanho": [(0.0, 0.0, 0.0), (0.1, 1.0, 0.0), (0.3, 1.0, 0.0),
                        (0.5, 1.0, 0.0), (0.7, 1.0, 0.0), (1.0, 0.0, 0.0)],
            "transparencia": [(0.0, 0.3, 0.0), (1.0, 0.999, 0.0)],
            "cor": [(0.0, BRANCO), (1.0, VERDE_CLARO)],
            "emissao": 1.0, "influencia": 0.0, "brilho": 1.0,
        }),
    ],

    # Cosmic Entity: Ember + Explosion_Smoke
    "BRASA": [
        ("Brasa", {
            "textura": "rbxasset://textures/particles/sparkles_main.dds",
            "rate": 1000.0, "vida": (4.0, 5.0), "velocidade": (50.0, 75.0),
            "tamanho": [(0.0, 2.0, 0.0), (1.0, 2.0, 0.0)],
            "transparencia": [(0.0, 0.0, 0.0), (1.0, 1.0, 0.0)],
            "cor": [(0.0, VERDE), (1.0, VERDE_CLARO)],
            "emissao": 1.0, "influencia": 1.0, "brilho": 1.0,
            "aceleracao": (0.0, 10.0, 0.0),
        }),
        ("Fumaca", {
            "textura": "rbxasset://textures/particles/smoke_main.dds",
            "rate": 300.0, "vida": (1.0, 1.42), "velocidade": (23.3, 23.3),
            "tamanho": [(0.0, 0.125, 0.0), (1.0, 8.25, 0.0)],
            "transparencia": [(0.0, 0.35, 0.0), (1.0, 1.0, 0.0)],
            "cor": [(0.0, VERDE_CLARO), (1.0, BRANCO)],
            "emissao": 0.0, "influencia": 1.0, "brilho": 1.0,
            "rotacao": (-180.0, 180.0), "giro": (0.0, 180.0),
            "aceleracao": (0.0, 8.0, 0.0), "direcao": 0,
        }),
    ],

    # Cosmic Entity: Sparks  +  Jupiter: Impact
    "FAISCA": [
        ("Faisca", {
            "textura": "rbxassetid://4584076139",
            "rate": 150.0, "vida": (0.5, 0.5), "velocidade": (150.0, 150.0),
            "tamanho": [(0.0, 6.0, 0.0), (1.0, 0.0, 0.0)],
            "transparencia": [(0.0, 1.0, 0.0), (0.52, 0.0, 0.0), (1.0, 1.0, 0.0)],
            "cor": [(0.0, BRANCO), (1.0, VERDE_CLARO)],
            "emissao": 1.0, "influencia": 0.0, "brilho": 1.0,
            "zoffset": 4.0, "arrasto": 0.5, "direcao": 5, "orientacao": 2,
        }),
        ("Anel", {
            "textura": "rbxassetid://4566568378",
            "rate": 8.0, "vida": (0.1, 0.1), "velocidade": (0.0, 0.0),
            "tamanho": [(0.0, 1.0, 0.0), (1.0, 8.5, 1.5)],
            "transparencia": [(0.0, 0.0, 0.0), (1.0, 0.0, 0.0)],
            "cor": [(0.0, VERDE_CLARO), (1.0, VERDE)],
            "emissao": 0.75, "influencia": 0.0, "brilho": 1.0,
            "rotacao": (-180.0, 180.0), "zoffset": 2.0,
        }),
    ],

    # Jupiter: Flash_Particle — aura presa ao Handle, não é disparo
    "AURA": [
        ("Aura", {
            "textura": "rbxassetid://12156297119",
            "rate": 2.0, "vida": (1.25, 1.25), "velocidade": (0.05, 0.05),
            "tamanho": [(0.0, 5.0, 0.0), (1.0, 5.0, 0.0)],
            "transparencia": [(0.0, 0.35, 0.0), (1.0, 1.0, 0.0)],
            "cor": [(0.0, VERDE), (1.0, VERDE_CLARO)],
            "emissao": 1.0, "influencia": 1.0, "brilho": 1.0,
            "zoffset": 5.0, "preso": True,
        }),
    ],
}

# Que efeitos novos entram em cada Tool. A escolha é por tema, não por sobra.
EFEITOS_POR_TOOL = {
    "PulsoGravitacional": ["RAIO_TEMPORAL", "AURA"],
    "CampoZeroG": ["ESTILHACO_ESTELAR", "AURA"],
    "MaoTelecinetica": ["FAISCA", "RAIO_TEMPORAL", "AURA"],
    "OrbitaPsi": ["FAISCA", "AURA"],
    "LancaVetorial": ["RAIO_TEMPORAL", "FAISCA", "AURA"],
    "PocoDeMassa": ["BRASA", "AURA"],
    "MarionetePsi": ["ESTILHACO_ESTELAR", "FAISCA", "AURA"],
    "TemperoTemporal":   ["ESTILHACO_ESTELAR", "FAISCA", "AURA"],
    "Cronostase":        ["ESTILHACO_ESTELAR", "AURA"],
    "AvancoRapido":      ["BRASA", "FAISCA", "AURA"],
    "CanhaoCronos":      ["RAIO_TEMPORAL", "FAISCA", "AURA"],
    "Temporalise":       ["ESTILHACO_ESTELAR", "BRASA", "AURA"],
    "ArmadilhaTemporal": ["BRASA", "FAISCA", "AURA"],
    "AvoDoTempo":        ["RAIO_TEMPORAL", "ESTILHACO_ESTELAR", "BRASA",
                          "FAISCA", "AURA"],
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

    def p_numseq(self, item, nome, pontos):
        """NumberSequence: lista plana de (tempo valor envelope)."""
        e = ET.SubElement(self.props(item), "NumberSequence", {"name": nome})
        e.text = " ".join("%g %g %g" % (t, v, env) for t, v, env in pontos) + " "

    def p_colorseq(self, item, nome, pontos):
        """ColorSequence: lista plana de (tempo r g b envelope)."""
        e = ET.SubElement(self.props(item), "ColorSequence", {"name": nome})
        e.text = " ".join("%g %g %g %g 0" % (t, r, g, b)
                          for t, (r, g, b) in pontos) + " "

    def p_numrange(self, item, nome, lo, hi):
        e = ET.SubElement(self.props(item), "NumberRange", {"name": nome})
        e.text = "%g %g " % (lo, hi)

    def p_color3(self, item, nome, rgb):
        e = ET.SubElement(self.props(item), "Color3", {"name": nome})
        for eixo, v in zip(("R", "G", "B"), rgb):
            ET.SubElement(e, eixo).text = repr(float(v))

    def emissor(self, pai, nome, cfg):
        """ParticleEmitter com os parâmetros extraídos do modelo de origem."""
        it = self.item(pai, "ParticleEmitter")
        self.p_string(it, "Name", nome)
        self.p_conteudo(it, "Texture", cfg["textura"])
        self.p_float(it, "Rate", cfg["rate"])
        self.p_numrange(it, "Lifetime", *cfg["vida"])
        self.p_numrange(it, "Speed", *cfg["velocidade"])
        self.p_numseq(it, "Size", cfg["tamanho"])
        self.p_numseq(it, "Transparency", cfg["transparencia"])
        self.p_colorseq(it, "Color", cfg["cor"])
        self.p_float(it, "LightEmission", cfg.get("emissao", 1.0))
        self.p_float(it, "LightInfluence", cfg.get("influencia", 0.0))
        self.p_float(it, "Brightness", cfg.get("brilho", 1.0))
        self.p_numrange(it, "Rotation", *cfg.get("rotacao", (0.0, 0.0)))
        self.p_numrange(it, "RotSpeed", *cfg.get("giro", (0.0, 0.0)))
        self.p_float(it, "ZOffset", cfg.get("zoffset", 0.0))
        self.p_float(it, "Drag", cfg.get("arrasto", 0.0))
        self.p_vetor(it, "Acceleration", *cfg.get("aceleracao", (0.0, 0.0, 0.0)))
        self.p_token(it, "EmissionDirection", cfg.get("direcao", 1))
        self.p_token(it, "Orientation", cfg.get("orientacao", 0))
        self.p_bool(it, "LockedToPart", cfg.get("preso", False))
        self.p_bool(it, "Enabled", False)   # o cliente liga por Enabled, nunca :Emit
        self.p_float(it, "TimeScale", 1.0)
        return it

    def ancora(self, pai, nome):
        """Part invisível que carrega os emissores de um efeito."""
        it = self.parte(pai, nome, (0.4, 0.4, 0.4), (0, 0, 0), (255, 255, 255),
                        "SmoothPlastic", "Block", transparencia=1.0)
        return it

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


def construir_tool(m, raiz, nome):
    """Constrói a Tool inteira dentro de `raiz` e devolve o Item."""
    pasta = os.path.join(TOOLS, nome)
    dados = CATALOGO[nome]

    fonte_servidor = ler(os.path.join(pasta, "%s_Server_V1.lua" % nome))
    fonte_cliente = ler(os.path.join(pasta, "Client.lua"))
    fonte_animator = ler(os.path.join(pasta, "R6CFrameAnimator.lua"))
    fonte_vfx = ler(os.path.join(pasta, "VFXModule.lua"))
    fonte_poses = ler(os.path.join(pasta, "Poses_GuardiaoDoTempo_%s_V1.lua" % nome))

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

    # Efeitos — moldes reais, um por efeito novo. Cada molde é uma Part âncora
    # invisível com os emissores dentro; o VFXModule clona, posiciona e liga por
    # Enabled. Os cinco efeitos originais seguem procedurais e não dependem daqui.
    pasta_efeitos = m.item(tool, "Folder")
    m.p_string(pasta_efeitos, "Name", "Efeitos")
    for tipo in EFEITOS_POR_TOOL.get(nome, []):
        molde = m.ancora(pasta_efeitos, tipo)
        for nome_emissor, cfg in EFEITOS[tipo]:
            m.emissor(molde, nome_emissor, cfg)

    return tool


def nova_raiz():
    raiz = ET.Element("roblox", {
        "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd",
        "version": "4",
    })
    ET.SubElement(raiz, "External").text = "null"
    ET.SubElement(raiz, "External").text = "nil"
    return raiz


def escrever(raiz, destino):
    ET.ElementTree(raiz).write(destino, encoding="utf-8", xml_declaration=False)
    with open(destino, "r", encoding="utf-8") as f:
        texto = f.read()
    with open(destino, "w", encoding="utf-8") as f:
        f.write(envolver_cdata(texto))
    return destino, os.path.getsize(destino)


def montar(nome):
    pasta = os.path.join(TOOLS, nome)
    m = Montador()
    raiz = nova_raiz()
    construir_tool(m, raiz, nome)
    destino = os.path.join(pasta, "%s.rbxmx" % nome)
    return escrever(raiz, destino)


def montar_conjunto(nomes, arquivo):
    """
    Todas as Tools num arquivo só.

    As Tools ficam como itens de RAIZ, não dentro de uma Folder: no Studio,
    "Insert from File" na StarterPack põe as 7 Tools direto lá. Dentro de uma
    Folder elas NÃO seriam entregues ao jogador — Folder na StarterPack não
    distribui o que tem dentro.
    """
    m = Montador()
    raiz = nova_raiz()
    for nome in nomes:
        construir_tool(m, raiz, nome)
    return escrever(raiz, os.path.join(TOOLS, arquivo))
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


# UM CONJUNTO POR MODELO DE ORIGEM — não um arquivo com tudo dentro.
#
# A REGRA_ENTREGA_RBXMX manda entregar as Tools DE UM MODELO num arquivo só.
# Juntar modelos diferentes no mesmo .rbxmx não é conveniência: quem importa o
# conjunto do Guardião passa a receber sete Tools de gravidade que não pediu, e
# o nome do arquivo deixa de dizer o que ele tem dentro.
CONJUNTOS = [
    ("GuardiaoDoTempo_7_Tools.rbxmx", "Guardião do Tempo", [
        "TemperoTemporal", "Cronostase", "AvancoRapido", "CanhaoCronos",
        "Temporalise", "ArmadilhaTemporal", "AvoDoTempo"]),
    ("GravidadeTelecinese_7_Tools.rbxmx", "Gravidade / Telecinese", [
        "PulsoGravitacional", "CampoZeroG", "MaoTelecinetica", "OrbitaPsi",
        "LancaVetorial", "PocoDeMassa", "MarionetePsi"]),
]


def main():
    alvos = sys.argv[1:] or sorted(CATALOGO.keys())
    for nome in alvos:
        if nome not in CATALOGO:
            print("desconhecida: %s" % nome)
            continue
        destino, tamanho = montar(nome)
        print("%-20s %7d bytes  %s" % (nome, tamanho,
                                       os.path.relpath(destino, RAIZ)))

    if not sys.argv[1:]:
        print("")
        print("CONJUNTOS — um arquivo por modelo de origem")
        for arquivo, modelo, ordem in CONJUNTOS:
            destino, tamanho = montar_conjunto(ordem, arquivo)
            print("%-22s %7d bytes  %s" % (modelo, tamanho,
                                           os.path.relpath(destino, RAIZ)))


if __name__ == "__main__":
    main()
