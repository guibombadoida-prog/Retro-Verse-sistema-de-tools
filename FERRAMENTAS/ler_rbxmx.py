#!/usr/bin/env python3
"""
ler_rbxmx.py — Retro-Verse / Studios

Lê modelo Roblox no formato XML (.rbxmx) e devolve a MESMA estrutura que
`extrair_rbxm.py` devolve para o binário. Assim as ferramentas de Acervo
funcionam com os dois formatos sem saber qual é qual.

    python3 FERRAMENTAS/ler_rbxmx.py <arquivo.rbxmx>

O que decodifica: as propriedades que descrevem material audiovisual —
string, bool, int, float, double, token, Content, Color3, Color3uint8,
Vector3, NumberRange, NumberSequence e ColorSequence.

Os valores saem no mesmo formato Python do leitor binário:

    NumberSequence   [(tempo, valor, envelope), ...]
    ColorSequence    [(tempo, (r, g, b)), ...]
    NumberRange      (baixo, alto)
    Color3           (r, g, b)  em 0..1
    Vector3          (x, y, z)
"""

import os
import sys
import xml.etree.ElementTree as ET


class Instancia:
    __slots__ = ("ref", "classe", "props", "filhos", "pai")

    def __init__(self, ref, classe):
        self.ref = ref
        self.classe = classe
        self.props = {}
        self.filhos = []
        self.pai = None

    @property
    def nome(self):
        return self.props.get("Name", self.classe)


def _numeros(texto):
    if not texto:
        return []
    return [float(p) for p in texto.split()]


def _filho(elemento, nome):
    achado = elemento.find(nome)
    return achado.text if achado is not None else None


def ler_valor(e):
    """Traduz um elemento de propriedade para valor Python, ou None se não tratado."""
    tag = e.tag
    texto = (e.text or "").strip()

    if tag == "string" or tag == "ProtectedString":
        return e.text if e.text is not None else ""

    if tag == "bool":
        return texto == "true"

    if tag in ("int", "int64", "token"):
        try:
            return int(texto)
        except ValueError:
            return None

    if tag in ("float", "double"):
        try:
            return float(texto)
        except ValueError:
            return None

    if tag == "Content":
        url = e.find("url")
        if url is not None:
            return url.text or ""
        return ""

    if tag == "Color3":
        try:
            return (float(_filho(e, "R")), float(_filho(e, "G")),
                    float(_filho(e, "B")))
        except (TypeError, ValueError):
            return None

    if tag == "Color3uint8":
        try:
            v = int(texto)
            return ((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF)
        except ValueError:
            return None

    if tag == "Vector3":
        try:
            return (float(_filho(e, "X")), float(_filho(e, "Y")),
                    float(_filho(e, "Z")))
        except (TypeError, ValueError):
            return None

    if tag == "NumberRange":
        n = _numeros(texto)
        if len(n) >= 2:
            return (round(n[0], 4), round(n[1], 4))
        return None

    if tag == "NumberSequence":
        # lista plana de (tempo valor envelope)
        n = _numeros(texto)
        return [(round(n[k], 4), round(n[k + 1], 4), round(n[k + 2], 4))
                for k in range(0, len(n) - 2, 3)]

    if tag == "ColorSequence":
        # lista plana de (tempo r g b envelope)
        n = _numeros(texto)
        saida = []
        for k in range(0, len(n) - 4, 5):
            saida.append((round(n[k], 4), (round(n[k + 1], 4),
                                           round(n[k + 2], 4),
                                           round(n[k + 3], 4))))
        return saida

    return None


def abrir(caminho):
    raiz = ET.parse(caminho).getroot()
    instancias = {}
    contador = [0]

    def anda(elemento, pai):
        contador[0] = contador[0] + 1
        ref = elemento.get("referent") or ("X%d" % contador[0])
        inst = Instancia(ref, elemento.get("class") or "?")

        propriedades = elemento.find("Properties")
        if propriedades is not None:
            for e in propriedades:
                nome = e.get("name")
                if not nome:
                    continue
                valor = ler_valor(e)
                if valor is not None:
                    inst.props[nome] = valor

        inst.pai = pai
        if pai is not None:
            pai.filhos.append(inst)
        instancias[ref] = inst

        for filho in elemento.findall("Item"):
            anda(filho, inst)
        return inst

    raizes = [anda(item, None) for item in raiz.findall("Item")]

    compartilhadas = []
    ss = raiz.find("SharedStrings")
    if ss is not None:
        for e in ss:
            compartilhadas.append(e.text or "")

    classes = set(i.classe for i in instancias.values())
    return {
        "classes": len(classes),
        "instancias_declaradas": len(instancias),
        "instancias": instancias,
        "raizes": raizes,
        "compartilhadas": compartilhadas,
    }


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1

    dados = abrir(sys.argv[1])
    instancias = dados["instancias"]
    print("instâncias: %d   classes: %d" % (len(instancias), dados["classes"]))

    contagem = {}
    for i in instancias.values():
        contagem[i.classe] = contagem.get(i.classe, 0) + 1
    for classe, quantos in sorted(contagem.items(), key=lambda x: -x[1])[:30]:
        print("  %5d  %s" % (quantos, classe))
    return 0


if __name__ == "__main__":
    sys.exit(main())
