#!/usr/bin/env python3
"""
conformar_pack_vfx.py — Retro-Verse / Studios

Tira do pack `Stella's VFX Addon` só os efeitos que as Tools usam, aplica o
passe de conformidade §12.12.2, e deposita o resultado no Acervo pronto para
ser COPIADO PARA DENTRO da Tool.

    python3 FERRAMENTAS/conformar_pack_vfx.py

POR QUE ISTO EXISTE

    O pack inteiro tem um `MainModule` que se muda sozinho para
    ReplicatedStorage e um cabeçalho que manda requerer por id. Olhando só
    para ele eu concluí que o pack não cabia dentro da Tool, e propus uma
    exceção à Regra nº 1. Estava errado: o loader é que não cabe.

    Os MÓDULOS DE EFEITO não dependem de nada fora deles — nenhum `require`,
    nenhum ReplicatedStorage, nenhum Takeo. Cada um é um `return function(...)`
    com os próprios moldes como filhos. Copiados para dentro da Tool, a Regra
    nº 1 continua inteira e o teste do place vazio volta a valer para o VFX.

    Regra nº 1 não tem exceção. Tem só quem não leu o arquivo direito.
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Stella_VFX_Addon", "vfx_module.rbxmx")
DESTINO = os.path.join(RAIZ, "ACERVO_RETROVERSE", "Stella_VFX_Addon", "VFX")

# Só o que a ponte do VFXModule chama. O resto do pack não entra: cada Tool
# carrega o que usa, não um catálogo.
USADOS = [
    "Shockwave", "Shockwave_2", "Small_Nova", "Smoky_Explosion",
    "Shockwave_Explosion", "Small_Slash", "Sonar_Ring", "Floor_Crack",
    "Laser_Shot", "Spiral_Effect",
]

# Cabeçalho determinístico: substitui math.random sem mudar a cara do efeito.
# Ângulo áureo espalha sem repetir; jitter senoidal por contador varia a cada
# chamada e é reprodutível — dois clientes veem o mesmo efeito.
PREFACIO = '''--[[ CONFORMADO §12.12.2 — Retro-Verse
	Origem: Stella's VFX Addon (Stellabotrus). Módulo copiado PARA DENTRO da
	Tool: sem require, sem ReplicatedStorage, sem depósito externo.
	Alterações estão marcadas com [RV] no corpo.
]]

local _rv_n = 0
local function _rv_passo()
	_rv_n = _rv_n + 1
	if _rv_n > 100000 then _rv_n = 1 end
	return _rv_n
end

-- [RV] dispersão por ângulo áureo, no lugar de math.random(-360,360)
local function _rv_angulo()
	return (_rv_passo() * 137.507764) % 360
end

-- [RV] jitter determinístico em [-1,1], no lugar de math.random(-100,100)/100
local function _rv_jitter()
	return math.sin(_rv_passo() * 2.399963)
end

'''


def prop(item, nome):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == nome:
            return e
    return None


def texto(item, nome):
    e = prop(item, nome)
    if e is None:
        return None
    u = e.find("url")
    return u.text if u is not None else e.text


def conformar(nome, fonte):
    """Aplica o passe §12.12.2. Devolve (fonte_nova, [o que mudou])."""
    mudancas = []

    def trocar(padrao, novo, rotulo, flags=0):
        nonlocal fonte
        n = len(re.findall(padrao, fonte, flags))
        if n:
            fonte = re.sub(padrao, novo, fonte, flags=flags)
            mudancas.append("%s × %d" % (rotulo, n))

    # Alias no topo do Laser_Shot. `Foreach` e `random` são declarados e nunca
    # usados — declarar só o que se usa resolve os dois de uma vez. Tem de vir
    # ANTES das trocas de math.random, senão sobra um alias meio comido.
    trocar(r"local Instant\s*,\s*Foreach\s*,\s*random\s*=\s*"
           r"Instance\.new\s*,\s*table\.foreach\s*,\s*math\.random",
           "local Instant = Instance.new   -- [RV] Foreach e random eram mortos",
           "alias morto de math.random/table.foreach removido")

    # math.random em ângulo -> ângulo áureo
    trocar(r"math\.random\(\s*-360\s*,\s*360\s*\)", "_rv_angulo()",
           "math.random(-360,360) -> ângulo áureo")
    # math.random em desvio percentual -> jitter senoidal
    trocar(r"math\.random\(\s*-100\s*,\s*100\s*\)\s*/\s*100", "_rv_jitter()",
           "math.random(-100,100)/100 -> jitter senoidal")

    # workspace:FindFirstChild("Terrain") -> workspace.Terrain
    # Terrain é singleton do place, como CurrentCamera: existe sempre. Mas na
    # forma com literal ele lê igualzinho a uma busca de asset, e é essa forma
    # que a Regra nº 1 proíbe.
    trocar(r'workspace:FindFirstChild\(\s*"Terrain"\s*\)', "workspace.Terrain",
           'workspace:FindFirstChild("Terrain") -> workspace.Terrain')

    # script:WaitForChild("X") -> script.X
    # O molde é filho do próprio módulo e viaja junto: nunca falta, e esperar
    # por ele só cria um ponto de yield que pode pendurar.
    trocar(r'script:WaitForChild\(\s*"(\w+)"\s*(?:,\s*[\d.]+\s*)?\)', r"script.\1",
           "script:WaitForChild -> acesso direto")

    trocar(r"(?<![.\w])tick\s*\(\s*\)", "os.clock()", "tick() -> os.clock()")

    # `+=` e `continue` não existem em Lua 5.4 e são proibidos aqui
    trocar(r"(\b[\w.\[\]]+)\s*\+=\s*([^\n;]+)", r"\1 = \1 + \2", "+= expandido")

    sobrou = []
    for rotulo, padrao in (
        ("math.random", r"math\.random"),
        ("Random.new", r"Random\.new"),
        (":Destroy()", r":Destroy\(\)"),
        ("wait/spawn/delay", r"(?<![.\w])(wait|spawn|delay)\s*\("),
        ("tick()", r"(?<![.\w])tick\s*\("),
        ("continue", r"(?<![\w])continue(?![\w])"),
        ("ReplicatedStorage", r"ReplicatedStorage"),
        ("require(", r"require\("),
        ("Lighting/Sky/Gui", r"Lighting|ScreenGui|ColorCorrection"),
    ):
        n = len(re.findall(padrao, fonte))
        if n:
            sobrou.append("%s × %d" % (rotulo, n))

    return PREFACIO + fonte, mudancas, sobrou


def main():
    if not os.path.exists(ORIGEM):
        print("origem não encontrada: %s" % ORIGEM)
        return 1

    raiz = ET.parse(ORIGEM).getroot()
    achados = {}

    def procurar(item):
        nome = texto(item, "Name")
        if item.get("class") == "ModuleScript" and nome in USADOS and nome not in achados:
            achados[nome] = item
        for filho in item.findall("Item"):
            procurar(filho)

    for item in raiz.findall("Item"):
        procurar(item)

    faltando = [n for n in USADOS if n not in achados]
    if faltando:
        print("efeitos não encontrados no pack: %s" % ", ".join(faltando))
        return 1

    os.makedirs(DESTINO, exist_ok=True)

    # Pasta "Pack" com os 10 módulos, pronta para virar filha do VFXModule
    pack = ET.Element("Item", {"class": "Folder", "referent": "RVPACK"})
    props = ET.SubElement(pack, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = "Pack"

    total_sobra = 0
    print("PASSE DE CONFORMIDADE §12.12.2 — Stella's VFX Addon")
    print("")
    for nome in USADOS:
        item = achados[nome]
        campo = prop(item, "Source")
        novo, mudancas, sobrou = conformar(nome, campo.text or "")
        campo.text = novo

        with open(os.path.join(DESTINO, "%s.lua" % nome), "w", encoding="utf-8") as f:
            f.write(novo)

        pack.append(item)

        print("  %-22s %s" % (nome, "; ".join(mudancas) or "nada a corrigir"))
        if sobrou:
            total_sobra += 1
            print("  %-22s ⚠️  SOBROU: %s" % ("", "; ".join(sobrou)))

    envelope = ET.Element("roblox", {
        "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd",
        "version": "4",
    })
    ET.SubElement(envelope, "External").text = "null"
    ET.SubElement(envelope, "External").text = "nil"
    envelope.append(pack)

    saida = os.path.join(DESTINO, "PACK_VFX.rbxmx")
    ET.ElementTree(envelope).write(saida, encoding="utf-8", xml_declaration=False)

    print("")
    print("%s  —  %d bytes" % (os.path.relpath(saida, RAIZ), os.path.getsize(saida)))
    print("%d efeito(s); %d com violação remanescente" % (len(USADOS), total_sobra))
    return 1 if total_sobra else 0


if __name__ == "__main__":
    sys.exit(main())
