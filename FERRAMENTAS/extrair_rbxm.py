#!/usr/bin/env python3
"""
extrair_rbxm.py — Retro-Verse / Studios

Abre modelo Roblox no formato BINÁRIO (.rbxm / .rbxl) e extrai o que interessa
para a conversão em Tool: a árvore de instâncias, o código dos scripts, e todo
asset citado (som, mesh, textura, decal).

    python3 FERRAMENTAS/extrair_rbxm.py <arquivo.rbxm> [pasta_de_saida]

Sem pasta de saída, só imprime o relatório.

POR QUE ESTA FERRAMENTA EXISTE
O .rbxmx é XML e o Python lê de graça. O .rbxm é binário, com blocos LZ4, e sem
ele metade dos modelos de toolbox fica inauditável — e material não auditado não
entra em Tool nenhuma (§12.12.2 / §12.12.3).

O QUE ELA DECODIFICA
Classes, referentes, parentesco e as propriedades que descrevem material
audiovisual: String, Bool, Int32, Int64, Float, Double, Color3, Color3uint8,
Vector3, Enum, NumberRange, NumberSequence e ColorSequence.

Isso cobre o que faz um ParticleEmitter, um Trail e um Beam serem o que são —
Rate, Lifetime, Speed, Size, Transparency, Color, Texture — que é justamente o
que se quer reusar. Sem esses números, "extrair o VFX" seria só listar nomes.

Tipo não implementado (CFrame, UDim2, PhysicalProperties…) faz o bloco inteiro
ser PULADO: cada bloco PROP guarda uma única propriedade de uma única classe,
então dá para ignorar sem saber o tamanho do tipo.
"""

import os
import struct
import sys
import re

# ---------------------------------------------------------------- LZ4

def lz4_descomprimir(dados, tamanho_final):
    """Bloco LZ4 puro. Implementado aqui porque o ambiente não tem o módulo."""
    saida = bytearray()
    i = 0
    n = len(dados)

    while i < n:
        token = dados[i]
        i = i + 1

        # literais
        tam_lit = token >> 4
        if tam_lit == 15:
            while True:
                extra = dados[i]
                i = i + 1
                tam_lit = tam_lit + extra
                if extra != 255:
                    break
        saida.extend(dados[i:i + tam_lit])
        i = i + tam_lit

        if i >= n:
            break

        # correspondência
        offset = dados[i] | (dados[i + 1] << 8)
        i = i + 2
        if offset == 0:
            break

        tam_match = token & 0x0F
        if tam_match == 15:
            while True:
                extra = dados[i]
                i = i + 1
                tam_match = tam_match + extra
                if extra != 255:
                    break
        tam_match = tam_match + 4

        inicio = len(saida) - offset
        for k in range(tam_match):
            saida.append(saida[inicio + k])

    if tamanho_final and len(saida) != tamanho_final:
        sys.stderr.write("aviso: LZ4 devolveu %d bytes, esperava %d\n"
                         % (len(saida), tamanho_final))
    return bytes(saida)


# ---------------------------------------------------------------- leitor

class Leitor:
    def __init__(self, dados):
        self.d = dados
        self.i = 0

    def u8(self):
        v = self.d[self.i]
        self.i = self.i + 1
        return v

    def u32(self):
        v = struct.unpack_from("<I", self.d, self.i)[0]
        self.i = self.i + 4
        return v

    def i32(self):
        v = struct.unpack_from("<i", self.d, self.i)[0]
        self.i = self.i + 4
        return v

    def bytes(self, n):
        v = self.d[self.i:self.i + n]
        self.i = self.i + n
        return v

    def texto(self):
        return self.bytes(self.u32())

    def resta(self):
        return len(self.d) - self.i


def desintercalar(bruto, quantidade, largura=4):
    """
    Arrays numéricos vêm com os bytes intercalados por posição: primeiro todos
    os bytes 0, depois todos os bytes 1, e assim por diante.
    """
    saida = bytearray(quantidade * largura)
    for b in range(largura):
        for k in range(quantidade):
            saida[k * largura + b] = bruto[b * quantidade + k]
    return bytes(saida)


def zigzag(v):
    return (v >> 1) ^ (-(v & 1))


def ler_referentes(leitor, quantidade):
    """Referentes: intercalados, zigzag e ACUMULADOS (delta em relação ao anterior)."""
    bruto = leitor.bytes(quantidade * 4)
    plano = desintercalar(bruto, quantidade)
    saida = []
    atual = 0
    for k in range(quantidade):
        v = struct.unpack_from(">i", plano, k * 4)[0]
        atual = atual + zigzag(v)
        saida.append(atual)
    return saida


# ---------------------------------------------------------------- tipos

TIPO_STRING      = 0x01
TIPO_BOOL        = 0x02
TIPO_INT32       = 0x03
TIPO_FLOAT       = 0x04
TIPO_DOUBLE      = 0x05
TIPO_COLOR3      = 0x0C
TIPO_VECTOR3     = 0x0E
TIPO_TOKEN       = 0x12
TIPO_NUMSEQ      = 0x15
TIPO_COLORSEQ    = 0x16
TIPO_NUMRANGE    = 0x17
TIPO_COLOR3UINT8 = 0x1A
TIPO_INT64       = 0x1B


def ler_floats(leitor, quantidade):
    """
    Float: bytes intercalados, big-endian, e com o bit de sinal rotacionado
    para o fim. Desfazer é rodar 1 bit para a direita antes de reinterpretar.
    """
    plano = desintercalar(leitor.bytes(quantidade * 4), quantidade)
    saida = []
    for k in range(quantidade):
        v = struct.unpack_from(">I", plano, k * 4)[0]
        v = (v >> 1) | ((v & 1) << 31)
        saida.append(struct.unpack("<f", struct.pack("<I", v))[0])
    return saida


def ler_int32(leitor, quantidade):
    plano = desintercalar(leitor.bytes(quantidade * 4), quantidade)
    return [zigzag(struct.unpack_from(">i", plano, k * 4)[0])
            for k in range(quantidade)]


def ler_int64(leitor, quantidade):
    plano = desintercalar(leitor.bytes(quantidade * 8), quantidade, 8)
    return [zigzag(struct.unpack_from(">q", plano, k * 8)[0])
            for k in range(quantidade)]


def ler_tokens(leitor, quantidade):
    plano = desintercalar(leitor.bytes(quantidade * 4), quantidade)
    return [struct.unpack_from(">I", plano, k * 4)[0] for k in range(quantidade)]


def ler_propriedade(b, tipo, quantos):
    """Devolve a lista de valores, ou None se o tipo não é implementado."""
    if tipo == TIPO_STRING:
        return [b.texto().decode("utf-8", "replace") for _ in range(quantos)]

    if tipo == TIPO_BOOL:
        return [b.u8() != 0 for _ in range(quantos)]

    if tipo == TIPO_INT32:
        return ler_int32(b, quantos)

    if tipo == TIPO_INT64:
        return ler_int64(b, quantos)

    if tipo == TIPO_FLOAT:
        return ler_floats(b, quantos)

    if tipo == TIPO_DOUBLE:
        # double NÃO é intercalado
        return [struct.unpack_from("<d", b.bytes(8), 0)[0] for _ in range(quantos)]

    if tipo == TIPO_TOKEN:
        return ler_tokens(b, quantos)

    if tipo == TIPO_COLOR3:
        r = ler_floats(b, quantos)
        g = ler_floats(b, quantos)
        azul = ler_floats(b, quantos)
        return [(round(r[k], 4), round(g[k], 4), round(azul[k], 4))
                for k in range(quantos)]

    if tipo == TIPO_VECTOR3:
        x = ler_floats(b, quantos)
        y = ler_floats(b, quantos)
        z = ler_floats(b, quantos)
        return [(round(x[k], 4), round(y[k], 4), round(z[k], 4))
                for k in range(quantos)]

    if tipo == TIPO_COLOR3UINT8:
        r = b.bytes(quantos)
        g = b.bytes(quantos)
        azul = b.bytes(quantos)
        return [(r[k], g[k], azul[k]) for k in range(quantos)]

    if tipo == TIPO_NUMRANGE:
        saida = []
        for _ in range(quantos):
            bruto = b.bytes(8)
            lo, hi = struct.unpack("<ff", bruto)
            saida.append((round(lo, 4), round(hi, 4)))
        return saida

    if tipo == TIPO_NUMSEQ:
        saida = []
        for _ in range(quantos):
            n = b.u32()
            pontos = []
            for _ in range(n):
                t, v, env = struct.unpack("<fff", b.bytes(12))
                pontos.append((round(t, 4), round(v, 4), round(env, 4)))
            saida.append(pontos)
        return saida

    if tipo == TIPO_COLORSEQ:
        saida = []
        for _ in range(quantos):
            n = b.u32()
            pontos = []
            for _ in range(n):
                t, r, g, azul, env = struct.unpack("<fffff", b.bytes(20))
                pontos.append((round(t, 4), (round(r, 4), round(g, 4),
                                             round(azul, 4))))
            saida.append(pontos)
        return saida

    return None


# ---------------------------------------------------------------- modelo


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


def abrir(caminho):
    d = open(caminho, "rb").read()
    if d[:8] != b"<roblox!":
        raise ValueError("não é .rbxm binário (esperava o magic '<roblox!')")

    leitor = Leitor(d)
    leitor.bytes(16)               # magic + assinatura
    n_classes = leitor.u32()
    n_instancias = leitor.u32()
    leitor.bytes(8)                # reservado

    classes = {}                   # índice -> (nome, [referentes])
    instancias = {}                # referente -> Instancia
    compartilhadas = []

    while leitor.resta() > 0:
        nome_bloco = leitor.bytes(4)
        comprimido = leitor.u32()
        descomprimido = leitor.u32()
        leitor.bytes(4)            # reservado

        if comprimido == 0:
            corpo = leitor.bytes(descomprimido)
        else:
            corpo = lz4_descomprimir(leitor.bytes(comprimido), descomprimido)

        b = Leitor(corpo)

        if nome_bloco == b"INST":
            indice = b.u32()
            classe = b.texto().decode("utf-8", "replace")
            b.u8()                 # isService
            quantos = b.u32()
            refs = ler_referentes(b, quantos)
            classes[indice] = (classe, refs)
            for r in refs:
                instancias[r] = Instancia(r, classe)

        elif nome_bloco == b"PROP":
            indice = b.u32()
            nome_prop = b.texto().decode("utf-8", "replace")
            if b.resta() == 0:
                continue
            tipo = b.u8()
            if indice not in classes:
                continue
            _, refs = classes[indice]
            try:
                valores = ler_propriedade(b, tipo, len(refs))
            except (struct.error, IndexError):
                valores = None     # bloco malformado: pula, não derruba a leitura
            if valores is None:
                continue           # tipo não implementado: bloco inteiro pulado
            for k, r in enumerate(refs):
                if k < len(valores):
                    instancias[r].props[nome_prop] = valores[k]

        elif nome_bloco == b"PRNT":
            b.u8()                 # versão
            quantos = b.u32()
            filhos = ler_referentes(b, quantos)
            pais = ler_referentes(b, quantos)
            for k in range(quantos):
                f = instancias.get(filhos[k])
                p = instancias.get(pais[k])
                if f is None:
                    continue
                f.pai = p
                if p is not None:
                    p.filhos.append(f)

        elif nome_bloco == b"SSTR":
            b.u32()                # versão
            quantos = b.u32()
            for _ in range(quantos):
                b.bytes(16)        # hash
                compartilhadas.append(b.texto())

        elif nome_bloco == b"END\0":
            break

    raizes = [i for i in instancias.values() if i.pai is None]
    return {
        "classes": n_classes,
        "instancias_declaradas": n_instancias,
        "instancias": instancias,
        "raizes": raizes,
        "compartilhadas": compartilhadas,
    }


# ---------------------------------------------------------------- relatório

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")
CLASSES_VFX = ("ParticleEmitter", "Beam", "Trail", "Smoke", "Fire", "Sparkles",
               "Explosion", "Highlight", "SelectionBox", "PointLight",
               "SpotLight", "SurfaceLight")
CLASSES_SFX = ("Sound",)
CLASSES_MESH = ("MeshPart", "SpecialMesh", "CharacterMesh", "UnionOperation",
                "FileMesh", "Decal", "Texture")

CAMPOS_ASSET = ("SoundId", "MeshId", "TextureID", "TextureId", "Texture",
                "Image", "AnimationId")


def arvore(inst, prof=0, linhas=None, teto=400):
    if linhas is None:
        linhas = []
    if len(linhas) >= teto:
        return linhas
    linhas.append("%s[%s] %s" % ("  " * prof, inst.classe, inst.nome))
    for f in inst.filhos:
        arvore(f, prof + 1, linhas, teto)
    return linhas


def caminho_de(inst):
    partes = []
    atual = inst
    while atual is not None:
        partes.append(atual.nome)
        atual = atual.pai
    return "/".join(reversed(partes))


def relatorio(modelo, rotulo, saida=None):
    instancias = modelo["instancias"]
    print("=" * 78)
    print("MODELO: %s" % rotulo)
    print("=" * 78)
    print("instâncias: %d   classes: %d   shared strings: %d"
          % (len(instancias), modelo["classes"], len(modelo["compartilhadas"])))

    contagem = {}
    for i in instancias.values():
        contagem[i.classe] = contagem.get(i.classe, 0) + 1

    print("\n--- CLASSES ---")
    for classe, quantos in sorted(contagem.items(), key=lambda x: -x[1]):
        print("  %4d  %s" % (quantos, classe))

    print("\n--- ÁRVORE ---")
    for raiz in modelo["raizes"]:
        for linha in arvore(raiz):
            print("  " + linha)

    scripts = [i for i in instancias.values() if i.classe in CLASSES_SCRIPT]
    print("\n--- SCRIPTS (%d) ---" % len(scripts))
    for s in sorted(scripts, key=lambda x: -len(x.props.get("Source", ""))):
        fonte = s.props.get("Source", "")
        print("  %6d linhas  [%s] %s" % (len(fonte.splitlines()), s.classe,
                                          caminho_de(s)))

    vfx = [i for i in instancias.values() if i.classe in CLASSES_VFX]
    print("\n--- VFX (%d) ---" % len(vfx))
    for v in vfx:
        print("  [%s] %s" % (v.classe, caminho_de(v)))

    sfx = [i for i in instancias.values() if i.classe in CLASSES_SFX]
    print("\n--- SFX (%d) ---" % len(sfx))
    for s in sfx:
        print("  %s  ->  %s" % (caminho_de(s), s.props.get("SoundId", "(sem id)")))

    malhas = [i for i in instancias.values() if i.classe in CLASSES_MESH]
    print("\n--- MALHA / TEXTURA (%d) ---" % len(malhas))
    for m in malhas:
        ids = [(c, m.props[c]) for c in CAMPOS_ASSET if m.props.get(c)]
        if ids:
            print("  [%s] %s" % (m.classe, caminho_de(m)))
            for campo, valor in ids:
                print("        %-12s %s" % (campo, valor))

    # todo rbxassetid citado em qualquer lugar, inclusive dentro de código
    citados = set()
    for i in instancias.values():
        for chave, valor in i.props.items():
            if isinstance(valor, str):
                for achado in re.findall(r"rbxassetid://(\d+)", valor):
                    citados.add(achado)
                for achado in re.findall(r"rbxasset://[^\s\"']+", valor):
                    citados.add(achado)
    print("\n--- IDs DE ASSET CITADOS (%d) ---" % len(citados))
    for c in sorted(citados):
        print("  %s" % c)

    if saida:
        os.makedirs(saida, exist_ok=True)
        pasta_scripts = os.path.join(saida, "fontes")
        os.makedirs(pasta_scripts, exist_ok=True)
        usados = {}
        for s in scripts:
            fonte = s.props.get("Source", "")
            base = re.sub(r"[^A-Za-z0-9]+", "_", caminho_de(s)).strip("_")
            nome = base
            k = 1
            while nome in usados:
                k = k + 1
                nome = "%s__%d" % (base, k)
            usados[nome] = True
            with open(os.path.join(pasta_scripts, nome + ".lua"), "w",
                      encoding="utf-8") as f:
                f.write(fonte)
        print("\n%d script(s) gravado(s) em %s" % (len(scripts), pasta_scripts))


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    caminho = sys.argv[1]
    saida = sys.argv[2] if len(sys.argv) > 2 else None
    modelo = abrir(caminho)
    relatorio(modelo, os.path.basename(caminho), saida)
    return 0


if __name__ == "__main__":
    sys.exit(main())
