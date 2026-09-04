#!/usr/bin/env python3
"""
montar_rbxmx.py — Retro-Verse / Studios

Monta o arquivo .rbxmx de cada Tool a partir dos .lua da própria pasta.

    python3 FERRAMENTAS/montar_rbxmx.py            # monta todas
    python3 FERRAMENTAS/montar_rbxmx.py OrbitaPsi  # monta uma

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

BASE = (154, 205, 50)      # paleta do repositório — verde-limão
ACO = (150, 160, 172)      # escudo — corpo
ACO_ESCURO = (74, 82, 92)  # escudo — aro e nervuras
AZUL = (0, 122, 190)       # escudo — face
AZUL_CLARO = (96, 205, 255)
BRONZE = (124, 100, 58)
ESCURO = (48, 42, 34)

# SFX: nome do Sound -> (id, volume, pitch, rolloff)
CATALOGO = {
    # VAZIO POR DECISÃO, não por descuido.
    #
    # Todas as Tools foram removidas do repositório a pedido. As próximas
    # nascem CLONANDO o modelo que o usuário enviar — não montando Handle novo
    # com primitivas, que foi o erro da leva anterior: o modelo vinha com
    # SpecialMesh próprio e eu remontei um escudo em código, entregando outra
    # coisa visualmente.
    #
    # Ao cadastrar uma Tool aqui, ela precisa de:
    #   tooltip · classe · energia · recarga · extra · poses · handle · sfx
    # e, se tiver cutscene, "cutscene": True.
}

# ---------------------------------------------------------------- efeitos
#
# Emissores de verdade, extraídos de dois modelos de terceiro:
# Jupiter_Great_Pressure_Sword e Sword_of_Cosmic_Entity.
#
# Curvas (Size, Transparency, Rate, Speed, Lifetime) são as do modelo de origem,
# extraídas por FERRAMENTAS/extrair_rbxm.py. A COR foi trocada para a paleta do
# repositório — é o que costura material de dois modelos diferentes no mesmo
# conjunto: a leitura visual fica única, o comportamento continua o do original.
#
# Passe §12.12.2 aplicado: Enabled = false na origem, e o cliente liga por
# Enabled + Rate. Zero :Emit(), no servidor ou fora dele.

VERDE = (0.604, 0.804, 0.196)      # 154,205,50 — paleta do repositório
VERDE_CLARO = (0.78, 0.95, 0.45)
BRANCO = (1.0, 1.0, 1.0)
ACO_F = (0.588, 0.627, 0.674)          # 150,160,172
ACO_ESCURO_F = (0.290, 0.322, 0.361)   # 74,82,92
AZUL_F = (0.0, 0.478, 0.745)           # 0,122,190
AZUL_CLARO_F = (0.376, 0.804, 1.0)     # 96,205,255
CINZA_F = (0.392, 0.400, 0.451)        # 100,102,115 — o cinza do Saitama

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
    # ------------------------------------------------------------------
    # 01_Saitama, da VFX_Library_V2. Parâmetros extraídos do arquivo cru;
    # o passe §12.12.2 trocou a cor para a paleta do escudo e deixou
    # Enabled = false na origem — quem liga é o cliente, por Enabled + Rate.
    # ------------------------------------------------------------------

    # Death Counter: estilhaços pretos e rápidos. É o efeito de coisa QUEBRANDO.
    "ESTILHACO_ESCUDO": [
        ("Estilhaco", {
            "textura": "rbxassetid://8030734851",
            "rate": 200.0, "vida": (0.45, 0.75), "velocidade": (6.0, 50.0),
            "tamanho": [(0.0, 0.0, 0.0), (0.3, 0.8, 0.0), (1.0, 0.0, 0.0)],
            "transparencia": [(0.0, 0.0, 0.0), (1.0, 0.0, 0.0)],
            "cor": [(0.0, ACO_F), (1.0, ACO_ESCURO_F)],
            "emissao": 0.0, "influencia": 0.0, "brilho": 0.0,
            "rotacao": (90.0, 90.0), "zoffset": 1.0, "direcao": 5,
            "orientacao": 2,
        }),
    ],

    # Normal Uppercut: clarão que abre e fecha, girando a 250 graus/s.
    # A curva de Size tem 13 pontos e é o que dá o flash — não simplificar.
    "CLARAO_ESCUDO": [
        ("Clarao", {
            "textura": "rbxassetid://9791756255",
            "rate": 20.0, "vida": (0.5, 0.5), "velocidade": (0.0, 0.0),
            "tamanho": [(0.0, 0.0, 0.0), (0.0273, 13.6337, 0.0),
                        (0.1213, 24.9397, 0.0), (0.1973, 33.2529, 0.0),
                        (0.2893, 39.0722, 0.0), (0.4093, 45.7228, 0.0),
                        (0.5333, 49.8794, 0.0), (0.6273, 47.0529, 0.0),
                        (0.7073, 40.236, 0.0), (0.8293, 30.4264, 0.0),
                        (0.9293, 19.9517, 0.0), (0.9773, 9.6433, 0.0),
                        (1.0, 0.0919, 0.0)],
            "transparencia": [(0.0, 0.0, 0.0), (1.0, 0.0, 0.0)],
            "cor": [(0.0, BRANCO), (1.0, AZUL_CLARO_F)],
            "emissao": 1.0, "influencia": 1.0, "brilho": 1.0,
            "giro": (250.0, 250.0), "zoffset": 5.0,
        }),
    ],

    # Serious Punch: anel de choque que abre até 120 studs.
    "ONDA_ESCUDO": [
        ("Onda", {
            "textura": "rbxassetid://9160490836",
            "rate": 15.0, "vida": (0.1, 0.6), "velocidade": (0.01, 0.01),
            "tamanho": [(0.0, 0.0, 0.0), (0.5436, 108.75, 0.0), (1.0, 120.0, 0.0)],
            "transparencia": [(0.0, 1.0, 0.0), (1.0, 0.9375, 0.0)],
            "cor": [(0.0, BRANCO), (1.0, AZUL_F)],
            "emissao": 0.0, "influencia": 0.0, "brilho": 2.0,
            "rotacao": (-25.0, 25.0), "giro": (-35.0, 35.0),
            "orientacao": 3,
        }),
    ],

    # Death Counter: rajada curta em volta do punho. Drag 10 segura a partícula
    # perto do ponto — é o que faz ler como impacto, e não como jato.
    "IMPACTO_ESCUDO": [
        ("Impacto", {
            "textura": "rbxassetid://9160490836",
            "rate": 75.0, "vida": (0.1, 0.5), "velocidade": (-25.0, 25.0),
            "tamanho": [(0.0, 2.7385, 0.0), (0.2991, 9.2424, 0.0), (1.0, 13.3501, 0.0)],
            "transparencia": [(0.0, 1.0, 0.0), (1.0, 0.8438, 0.0)],
            "cor": [(0.0, BRANCO), (1.0, AZUL_CLARO_F)],
            "emissao": 0.0, "influencia": 0.0, "brilho": 2.0,
            "rotacao": (0.0, 360.0), "giro": (-35.0, 35.0),
            "arrasto": 10.0, "zoffset": 1.0, "direcao": 0,
        }),
    ],

    # Serious Mode: poeira pesada que cai (aceleração -15 em Y).
    "POEIRA_ESCUDO": [
        ("Poeira", {
            "textura": "rbxassetid://7216851605",
            "rate": 20.0, "vida": (2.0, 2.25), "velocidade": (75.0, 100.0),
            "tamanho": [(0.0, 5.0, 0.0), (1.0, 5.0, 0.0)],
            "transparencia": [(0.0, 0.9, 0.0), (0.1837, 0.9375, 0.0), (1.0, 1.0, 0.0)],
            "cor": [(0.0, CINZA_F), (1.0, CINZA_F)],
            "emissao": 1.0, "influencia": 1.0, "brilho": 1.0,
            "rotacao": (0.0, 360.0), "giro": (-32.0, 32.0),
            "aceleracao": (0.0, -15.0, 0.0), "arrasto": 8.0,
            "zoffset": 1.0, "direcao": 5,
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

    "EscudoBloqueador": ["CLARAO_ESCUDO", "IMPACTO_ESCUDO", "AURA"],
    "EscudoBumerangue": ["IMPACTO_ESCUDO", "ESTILHACO_ESCUDO", "FAISCA"],
    "EscudoSkate": ["POEIRA_ESCUDO", "IMPACTO_ESCUDO", "FAISCA"],
    "EscudoProtecao": ["CLARAO_ESCUDO", "AURA", "FAISCA"],
    "EscudoSalvador": ["CLARAO_ESCUDO", "AURA", "ESTILHACO_ESTELAR"],
    "EscudoCiclone": ["ONDA_ESCUDO", "POEIRA_ESCUDO", "AURA", "IMPACTO_ESCUDO"],
    "EscudoPartido": ["ESTILHACO_ESCUDO", "CLARAO_ESCUDO", "ONDA_ESCUDO", "IMPACTO_ESCUDO"],
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


def montar_handle_escudo(m, tool):
    """
    Escudo redondo, montado com primitivas.

    O modelo de origem usa SpecialMesh apontando para um MeshId de terceiro. Aqui
    o Handle é geometria de verdade, construída no lugar: não depende de asset
    externo, e o teste do place vazio continua passando (Regra nº 1).
    """
    # cilindro tem o eixo circular em X local; Ry(90) põe a face virada para Z
    ry90 = (0, 0, 1, 0, 1, 0, -1, 0, 0)

    handle = m.parte(tool, "Handle", (0.30, 3.4, 3.4), (0, 0, 0), ACO,
                     "Metal", "Cylinder", colide=False, reflexo=0.35, rot=ry90)
    ref_handle = handle.get("referent")

    decorativas = [
        # nome,          tamanho,             posição,           cor,  material, forma, rot
        ("Face", (0.34, 3.0, 3.0), (0, 0, 0.01), AZUL, "SmoothPlastic", "Cylinder", ry90),
        ("AroExterno", (0.26, 3.6, 3.6), (0, 0, 0), ACO_ESCURO, "Metal", "Cylinder", ry90),
        ("AroInterno", (0.36, 2.1, 2.1), (0, 0, 0.02), AZUL_CLARO, "Neon", "Cylinder", ry90),
        ("Bossa", (0.44, 0.9, 0.9), (0, 0, 0.04), ACO, "Metal", "Ball", None),
        ("NervuraA", (0.34, 3.0, 0.16), (0, 0, 0.03), ACO_ESCURO, "Metal", "Block", None),
        ("NervuraB", (0.34, 0.16, 3.0), (0, 0, 0.03), ACO_ESCURO, "Metal", "Block", None),
        ("Alca", (0.22, 1.5, 0.16), (0, 0, -0.18), ACO_ESCURO, "Metal", "Block", None),
    ]

    for nome, tam, pos, rgb, mat, forma, rot in decorativas:
        peca = m.parte(handle, nome, tam, pos, rgb, mat, forma, rot=rot)
        solda = m.item(peca, "WeldConstraint")
        m.p_string(solda, "Name", "Solda" + nome)
        m.p_bool(solda, "Enabled", True)
        m.p_ref(solda, "Part0", ref_handle)
        m.p_ref(solda, "Part1", peca.get("referent"))

    return handle


HANDLES = {"relogio": montar_handle, "escudo": montar_handle_escudo}


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
    fonte_poses = ler(os.path.join(pasta, "Poses_%s_%s_V1.lua" % (dados["poses"], nome)))

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

    HANDLES[dados.get("handle", "relogio")](m, tool)

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

    # Câmera de cutscene: LocalScript próprio, só nas Tools que têm cutscene.
    # A câmera é 100% cliente — o Server manda beat nomeado por CutsceneRemote.
    if dados.get("cutscene"):
        m.script(tool, "LocalScript", "CutsceneCam",
                 ler(os.path.join(pasta, "CutsceneCam.lua")))

    # Remotes
    r = m.item(tool, "RemoteEvent")
    m.p_string(r, "Name", "VFXRemote")
    if dados["extra"]:
        r = m.item(tool, "RemoteEvent")
        m.p_string(r, "Name", "AcaoRemote")
    if dados.get("cutscene"):
        r = m.item(tool, "RemoteEvent")
        m.p_string(r, "Name", "CutsceneRemote")

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
# A REGRA_ENTREGA_RBXM manda entregar as Tools DE UM MODELO num arquivo só.
# Juntar modelos diferentes no mesmo .rbxmx não é conveniência: quem importa o
# conjunto de um modelo passa a receber Tools de outro que não pediu, e o nome
# do arquivo deixa de dizer o que ele tem dentro. Modelo novo entra como
# entrada nova nesta lista, nunca como apêndice de uma existente.
CONJUNTOS = [
    # Um por MODELO de origem. Vazio enquanto não houver Tool no repositório.
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
