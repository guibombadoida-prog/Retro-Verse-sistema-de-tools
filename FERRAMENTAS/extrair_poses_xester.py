#!/usr/bin/env python3
"""
extrair_poses_xester.py — Retro-Verse / Studios

Lê a animação que os DOIS scripts originais do Xester já tinham e a reescreve
como TRACK do `R6CFrameAnimator` V2.

    python3 FERRAMENTAS/extrair_poses_xester.py

POR QUE EXTRAIR EM VEZ DE REDESENHAR

    O pedido é "as tools tem que ser exatamente igual a habilidade do modelo".
    A animação faz parte da habilidade. Redesenhar a silhueta à mão seria
    autoral — e erraria, porque são ~1.900 poses.

    A boa notícia: o original JÁ guarda a animação em CFrame de junta R6, que é
    exatamente a moeda do animator canônico. Só falta traduzir a convenção.

A CONVENÇÃO — E POR QUE O `:Inverse()`

    Weld:  Part1.CFrame = Part0.CFrame * C0 * C1:Inverse()

    O original solda MEMBRO → Torso  (Part0 = braço,  Part1 = Torso)
    O animator solda        Torso → MEMBRO (Part0 = Torso, Part1 = braço)

    Logo  C0_animator = C0_original:Inverse()  para Head/braços/pernas.
    Confere nos seis: (-1.5,0,0)→(1.5,0,0) · (0,-1.5,0)→(0,1.5,0) ·
    (-0.5,2,0)→(0.5,-2,0) — os mesmos números que o V2 usa de base.

    `ROOTLERP` é a exceção: lá o original já solda Root → Torso, mesma direção
    do `HRP` do animator. Entra sem inverter.

    `TORSOLERP` fica de fora: `Part1` nunca é atribuído, é um Weld morto.
    `AXELERP` / `STAFFLERP` também: prendem o objeto ao braço, isso é Grip de
    Tool, não junta de personagem.

O `C1` NÃO PODE SER IGNORADO

    A Forma 1 anima o braço girando em torno do OMBRO, e o pivô do ombro está
    no `C1`, não no `C0`:

        RIGHTARMLERP.C1 = ...:lerp(CFrame.new(0,1.5,-.1), .5)
        RIGHTARMLERP.C0 = ...:lerp(CFrame.new(-1.5,0,0)*CFrame.Angles(...), .3)

    Como `Part1.CFrame = Part0.CFrame * C0 * C1:Inverse()`, a matriz que
    importa é `M = C0 * C1:Inverse()` — e é ela que se inverte. Ler só o `C0`
    dá um braço girando em torno do centro do próprio braço: o cotovelo
    atravessa o tronco.

O BALANÇO DE `IDLE` VIRA ZERO

    Várias poses da Forma 1 trazem um termo vivo:

        CFrame.new(0, -.2 + -.1 * math.sin(sine/12), 0)

    `sine` é o contador do idle: o termo oscila em torno de zero. O keyframe
    guarda o CENTRO (`math.sin` avaliado como 0) — o balanço é trabalho do
    `StartIdleBob` do animator, não do keyframe. Copiar um valor instantâneo do
    seno congelaria a pose num ponto arbitrário do ciclo.

O TEMPO, E POR QUE A POSE NÃO É O ALVO

    O original anima assim:

        for i = 1, 20 do
            BRACOLERP.C0 = BRACOLERP.C0:lerp(ALVO, .25)
            swait()
        end

    Isso é aproximação exponencial, não interpolação: em 20 quadros a .25 ele
    chega a 1-0.75^20 = 99,7% do alvo. Mas com .09 em 20 quadros chega a 85%, e
    a pose que aparece na tela NÃO é o alvo escrito no código.

    Então o extrator SIMULA: parte da pose corrente, aplica
    `lerp(alvo, 1-(1-alpha)^N)` e grava o ponto REALMENTE alcançado. O keyframe
    sai em t += N/60 (`swait()` é `RunService.Stepped:wait(0)`, um quadro).

    Cada bloco vira um keyframe com `style = "Exponential", dir = "Out"` — que
    é a curva que o original desenha, não uma escolha de gosto.
"""

import json
import math
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENTRADA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Xester")

QUADRO = 1.0 / 60.0

# LERP do original -> junta do animator, e se inverte ou não
JUNTAS = {
    "HEADLERP": ("Head", True),
    "RIGHTARMLERP": ("RightArm", True),
    "LEFTARMLERP": ("LeftArm", True),
    "RIGHTLEGLERP": ("RightLeg", True),
    "LEFTLEGLERP": ("LeftLeg", True),
    "ROOTLERP": ("HRP", False),
}

# base do animator V2 (Part0 = Torso, Part1 = membro)
BASE = {
    "Head": (0.0, 1.5, 0.0),
    "RightArm": (1.5, 0.0, 0.0),
    "LeftArm": (-1.5, 0.0, 0.0),
    "RightLeg": (0.5, -2.0, 0.0),
    "LeftLeg": (-0.5, -2.0, 0.0),
    "HRP": (0.0, 0.0, 0.0),
}


# ═══════════════════════════════════════════════════════════════
# CFrame em Python — posição + matriz 3x3
# ═══════════════════════════════════════════════════════════════

def ident():
    return ((0.0, 0.0, 0.0), ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)))


def mat_mul(a, b):
    return tuple(
        tuple(sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3))
        for i in range(3)
    )


def mat_vec(m, v):
    return tuple(sum(m[i][k] * v[k] for k in range(3)) for i in range(3))


def cf_mul(x, y):
    px, rx = x
    py, ry = y
    p = tuple(px[i] + mat_vec(rx, py)[i] for i in range(3))
    return (p, mat_mul(rx, ry))


def cf_inverse(x):
    p, r = x
    rt = tuple(tuple(r[j][i] for j in range(3)) for i in range(3))
    np = mat_vec(rt, p)
    return (tuple(-c for c in np), rt)


def cf_new(x, y, z):
    return ((x, y, z), ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)))


def cf_angles(rx, ry, rz):
    """CFrame.Angles(x,y,z) = Rx * Ry * Rz — a ordem XYZ do Roblox."""
    cx, sx = math.cos(rx), math.sin(rx)
    cy, sy = math.cos(ry), math.sin(ry)
    cz, sz = math.cos(rz), math.sin(rz)
    mx = ((1, 0, 0), (0, cx, -sx), (0, sx, cx))
    my = ((cy, 0, sy), (0, 1, 0), (-sy, 0, cy))
    mz = ((cz, -sz, 0), (sz, cz, 0), (0, 0, 1))
    return ((0.0, 0.0, 0.0), mat_mul(mat_mul(mx, my), mz))


def para_quat(r):
    tr = r[0][0] + r[1][1] + r[2][2]
    if tr > 0:
        s = math.sqrt(tr + 1.0) * 2
        w = 0.25 * s
        x = (r[2][1] - r[1][2]) / s
        y = (r[0][2] - r[2][0]) / s
        z = (r[1][0] - r[0][1]) / s
    elif r[0][0] > r[1][1] and r[0][0] > r[2][2]:
        s = math.sqrt(1.0 + r[0][0] - r[1][1] - r[2][2]) * 2
        w = (r[2][1] - r[1][2]) / s
        x = 0.25 * s
        y = (r[0][1] + r[1][0]) / s
        z = (r[0][2] + r[2][0]) / s
    elif r[1][1] > r[2][2]:
        s = math.sqrt(1.0 + r[1][1] - r[0][0] - r[2][2]) * 2
        w = (r[0][2] - r[2][0]) / s
        x = (r[0][1] + r[1][0]) / s
        y = 0.25 * s
        z = (r[1][2] + r[2][1]) / s
    else:
        s = math.sqrt(1.0 + r[2][2] - r[0][0] - r[1][1]) * 2
        w = (r[1][0] - r[0][1]) / s
        x = (r[0][2] + r[2][0]) / s
        y = (r[1][2] + r[2][1]) / s
        z = 0.25 * s
    return (w, x, y, z)


def de_quat(q):
    w, x, y, z = q
    n = math.sqrt(w * w + x * x + y * y + z * z) or 1.0
    w, x, y, z = w / n, x / n, y / n, z / n
    return (
        (1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)),
        (2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)),
        (2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)),
    )


def cf_lerp(a, b, t):
    """Igual ao CFrame:Lerp do Roblox: posição linear, rotação em slerp."""
    pa, ra = a
    pb, rb = b
    p = tuple(pa[i] + (pb[i] - pa[i]) * t for i in range(3))
    qa, qb = para_quat(ra), para_quat(rb)
    ponto = sum(qa[i] * qb[i] for i in range(4))
    if ponto < 0:
        qb = tuple(-c for c in qb)
        ponto = -ponto
    if ponto > 0.9995:
        q = tuple(qa[i] + (qb[i] - qa[i]) * t for i in range(4))
    else:
        teta = math.acos(max(-1.0, min(1.0, ponto)))
        st = math.sin(teta)
        k0 = math.sin((1 - t) * teta) / st
        k1 = math.sin(t * teta) / st
        q = tuple(qa[i] * k0 + qb[i] * k1 for i in range(4))
    return (p, de_quat(q))


def para_euler(r):
    """ToEulerAnglesXYZ — o inverso exato de CFrame.Angles."""
    sy = max(-1.0, min(1.0, r[0][2]))
    b = math.asin(sy)
    if abs(sy) < 0.99999:
        a = math.atan2(-r[1][2], r[2][2])
        c = math.atan2(-r[0][1], r[0][0])
    else:
        a = math.atan2(r[2][1], r[1][1])
        c = 0.0
    return (a, b, c)


def escrever_cf(cf):
    p, r = cf
    a, b, c = para_euler(r)
    return ("CFrame.new(%s, %s, %s) * CFrame.Angles(math.rad(%s), math.rad(%s), math.rad(%s))"
            % (num(p[0]), num(p[1]), num(p[2]),
               num(math.degrees(a)), num(math.degrees(b)), num(math.degrees(c))))


def num(v):
    if abs(v) < 5e-4:
        return "0"
    t = "%.3f" % v
    t = t.rstrip("0").rstrip(".")
    return t if t not in ("-0", "") else "0"


# ═══════════════════════════════════════════════════════════════
# Leitura do Lua original
# ═══════════════════════════════════════════════════════════════

RE_LERP = re.compile(
    r"(\w+LERP)\.(C[01])\s*=\s*\1\.\2:[lL]erp\((.+),\s*([0-9.]+)\s*\)\s*$")
RE_SET = re.compile(r"(\w+LERP)\.(C[01])\s*=\s*(CFrame\..+?)\s*$")
RE_FOR = re.compile(r"^\s*for\s+\w+\s*=\s*1,\s*([0-9]+)\s*do")
RE_SWAIT_N = re.compile(r"^\s*swait\(\s*([0-9]+)\s*\)")


def _balanceado(txt, ini):
    """Devolve (miolo, fim) do parêntese que abre em `ini`."""
    nivel, i = 0, ini
    while i < len(txt):
        if txt[i] == "(":
            nivel = nivel + 1
        elif txt[i] == ")":
            nivel = nivel - 1
            if nivel == 0:
                return txt[ini + 1:i], i + 1
        i = i + 1
    return None, len(txt)


def valor(txt):
    """
    Avalia a expressão de um argumento de CFrame.

    Constantes e aritmética entram. `math.sin`/`math.cos` valem ZERO — são o
    balanço de idle, cujo centro é o que o keyframe guarda. Qualquer outro
    identificador solto derruba para None: prefiro não extrair a extrair errado.
    """
    txt = txt.strip()
    if not txt:
        return None

    # math.sin(...) / math.cos(...) -> 0  (centro da oscilação)
    for fn in ("math.sin", "math.cos"):
        while True:
            pos = txt.find(fn + "(")
            if pos < 0:
                break
            _miolo, fim = _balanceado(txt, pos + len(fn))
            txt = txt[:pos] + "0" + txt[fim:]

    # math.rad(x) -> radianos, resolvendo o miolo antes
    while True:
        pos = txt.find("math.rad(")
        if pos < 0:
            break
        miolo, fim = _balanceado(txt, pos + len("math.rad"))
        if miolo is None:
            return None
        dentro = valor(miolo)
        if dentro is None:
            return None
        txt = txt[:pos] + repr(math.radians(dentro)) + txt[fim:]

    if re.search(r"[A-Za-z_]", txt):
        return None
    if not re.fullmatch(r"[-+*/(). 0-9]+", txt):
        return None
    try:
        return float(eval(txt, {"__builtins__": {}}, {}))
    except Exception:
        return None


def partes(txt):
    """Quebra 'a,b,c' respeitando parênteses."""
    saida, nivel, atual = [], 0, ""
    for ch in txt:
        if ch == "(":
            nivel = nivel + 1
        elif ch == ")":
            nivel = nivel - 1
        if ch == "," and nivel == 0:
            saida.append(atual)
            atual = ""
        else:
            atual = atual + ch
    saida.append(atual)
    return saida


def avaliar_cframe(expr):
    """
    CFrame.new(...) * CFrame.Angles(...) * ... -> CFrame, ou None.

    Os parênteses são casados por contagem, não por regex: o original escreve
    `CFrame.new(0, -.2 + -.1 * math.sin(sine/12), 0)`, e um `[^()]*` pararia no
    parêntese do `math.sin`.
    """
    resto = expr.strip()
    fatores = []
    while resto:
        resto = resto.lstrip("* \t")
        if not resto:
            break
        for prefixo, construtor in (("CFrame.new", cf_new),
                                    ("CFrame.Angles", cf_angles),
                                    ("CFrame.fromEulerAnglesXYZ", cf_angles)):
            if resto.startswith(prefixo + "("):
                miolo, fim = _balanceado(resto, len(prefixo))
                if miolo is None:
                    return None
                args = [valor(a) for a in partes(miolo)]
                if len(args) != 3 or any(a is None for a in args):
                    return None
                fatores.append(construtor(*args))
                resto = resto[fim:]
                break
        else:
            return None
    if not fatores:
        return None
    fora = fatores[0]
    for f in fatores[1:]:
        fora = cf_mul(fora, f)
    return fora


def fim_do_bloco(linhas, ini, limite):
    """Índice do `end` que fecha o bloco aberto em `ini`."""
    nivel = 1
    j = ini + 1
    while j < limite:
        desnuda = re.sub(r"--.*$", "", linhas[j]).rstrip()
        abre = re.search(r"\b(?:for|while|if)\b.*\b(?:do|then)\s*$", desnuda) \
            or re.search(r"\bfunction\b", desnuda) \
            or re.search(r"\bdo\s*$", desnuda)
        if abre:
            nivel = nivel + 1
        elif re.match(r"^\s*end\b", desnuda):
            nivel = nivel - 1
            if nivel == 0:
                return j
        j = j + 1
    return limite


def blocos_de_pose(linhas, ini, fim):
    """
    Percorre [ini,fim) em ordem de leitura e devolve os blocos de animação.

    Cada bloco: (quadros, {LERP: {"C0"/"C1": (alvo, alpha)}}). `alpha = 1`
    marca atribuição direta (sem `:lerp`), que é aplicada de uma vez.
    """
    saida = []
    i = ini
    while i < fim:
        m = RE_FOR.match(linhas[i])
        if not m:
            i = i + 1
            continue
        n = int(m.group(1))
        j = fim_do_bloco(linhas, i, fim)
        alvos = {}
        for k in range(i + 1, min(j, fim)):
            corpo = linhas[k].strip()
            ml = RE_LERP.search(corpo)
            if ml:
                lerp, campo, expr, alpha = ml.group(1), ml.group(2), ml.group(3), float(ml.group(4))
            else:
                ms = RE_SET.search(corpo)
                if not ms:
                    continue
                lerp, campo, expr, alpha = ms.group(1), ms.group(2), ms.group(3), 1.0
            if lerp not in JUNTAS or not (0 < alpha <= 1):
                continue
            cf = avaliar_cframe(expr)
            if cf is not None:
                alvos.setdefault(lerp, {})[campo] = (cf, alpha)
        if alvos:
            saida.append((n, alvos))
        i = j + 1
    return saida


def estado_inicial():
    """C0/C1 de cada Weld como o script original os cria."""
    estado = {}
    for lerp, (junta, inverter) in JUNTAS.items():
        base = cf_new(*BASE[junta])
        estado[lerp] = {"C0": cf_inverse(base) if inverter else base,
                        "C1": ident()}
    return estado


def compor(estado, lerp):
    """C0 do animator a partir do par (C0,C1) do original."""
    _junta, inverter = JUNTAS[lerp]
    m = cf_mul(estado[lerp]["C0"], cf_inverse(estado[lerp]["C1"]))
    return cf_inverse(m) if inverter else m


def fatia_forma(linhas, a, b, quer_segunda):
    """
    A guarda da Forma 2 traz DUAS posturas no mesmo ramo:

        if secondform then   -- de cajado
            ...
        else                 -- antes da transformação
            ...
        end

    Ler as duas em sequência deixa a última vencer, e cinco das sete Tools da
    Forma 2 ficariam com a postura errada. Aqui a fatia certa é escolhida.
    Devolve (a, b) inalterado quando o ramo não se divide.
    """
    inicio = None
    for k in range(a, b):
        if re.match(r"^\s*if\s+secondform\s+then\s*$", linhas[k]):
            inicio = k
            break
    if inicio is None:
        return a, b

    nivel, senao, fecha = 1, None, b
    k = inicio + 1
    while k < b:
        desnuda = re.sub(r"--.*$", "", linhas[k]).rstrip()
        if re.search(r"\b(?:for|while|if)\b.*\b(?:do|then)\s*$", desnuda) \
                or re.search(r"\bfunction\b", desnuda):
            nivel = nivel + 1
        elif re.match(r"^\s*end\b", desnuda):
            nivel = nivel - 1
            if nivel == 0:
                fecha = k
                break
        elif nivel == 1 and re.match(r"^\s*else\s*$", desnuda):
            senao = k
        k = k + 1

    if quer_segunda:
        return inicio + 1, (senao if senao is not None else fecha)
    if senao is None:
        return a, b
    return senao + 1, fecha


def pose_sustentada(linhas, ini, fim, rotulo, quer_segunda=None):
    """
    Extrai a POSTURA de um ramo `if position == "<rotulo>"`.

    Esse ramo vive dentro de um `while` que roda a cada quadro enquanto a
    habilidade está ativa, então o `:lerp` converge: o alvo escrito no código é
    a pose que aparece. Aqui, diferente do bloco de ação, o alvo vale direto.

    É essa postura que segura tronco e pernas enquanto o golpe move só o braço.
    Sem ela, as juntas que a ação não toca ficam na base do animator — de pé,
    reto, e o golpe parece amputado.
    """
    marca = 'position == "%s"' % rotulo
    estado = estado_inicial()
    achou = False
    i = ini
    while i < fim:
        if marca not in linhas[i]:
            i = i + 1
            continue
        j = fim_do_bloco(linhas, i, fim)
        de, ate = (i + 1, min(j, fim))
        if quer_segunda is not None:
            de, ate = fatia_forma(linhas, de, ate, quer_segunda)
        for k in range(de, ate):
            corpo = linhas[k].strip()
            if re.match(r'^\s*(else)?if\s+position\s*==', corpo):
                break
            ml = RE_LERP.search(corpo)
            if not ml:
                continue
            lerp, campo, expr = ml.group(1), ml.group(2), ml.group(3)
            if lerp not in JUNTAS:
                continue
            cf = avaliar_cframe(expr)
            if cf is not None:
                estado[lerp][campo] = cf
                achou = True
        if achou:
            break
        i = j + 1
    if not achou:
        return None
    return estado


def montar_track(linhas, ini, fim, postura=None):
    """Simula a aproximação exponencial e devolve a lista de keyframes."""
    blocos = blocos_de_pose(linhas, ini, fim)
    if not blocos:
        return None, set()

    tocadas = set()
    for _n, alvos in blocos:
        for lerp in alvos:
            tocadas.add(JUNTAS[lerp][0])

    # a postura da habilidade é o ponto de partida; sem ela, a base do animator
    estado = dict((l, dict(c)) for l, c in (postura or estado_inicial()).items())

    def instantanea():
        return dict((JUNTAS[l][0], compor(estado, l)) for l in JUNTAS)

    track = [(0.0, instantanea())]
    t = 0.0
    for n, alvos in blocos:
        for lerp, campos in alvos.items():
            for campo, (alvo, alpha) in campos.items():
                progresso = 1.0 if alpha >= 1.0 else 1.0 - (1.0 - alpha) ** n
                estado[lerp][campo] = cf_lerp(estado[lerp][campo], alvo, progresso)
        t = t + n * QUADRO
        track.append((t, instantanea()))
    return track, tocadas


def emitir_poses(nome, track):
    """Cada keyframe vira uma pose nomeada `<HABILIDADE>_<n>`."""
    blocos = []
    for indice, (_t, juntas) in enumerate(track):
        linhas = ["P.%s_%d = {" % (nome, indice + 1)]
        for junta in sorted(juntas):
            linhas.append("\t%s = %s," % (junta, escrever_cf(juntas[junta])))
        linhas.append("}")
        blocos.append("\n".join(linhas))
    return "\n\n".join(blocos)


def emitir_sequencia(nome, track):
    """
    A track vira SEQUENCIA: um passo por keyframe, com o `time` que o original
    gastou naquele trecho. `marca` sai no primeiro e no último passo, que é
    onde o Client pende VFX e som.
    """
    if len(track) < 2:
        return ('\t%s = {\n\t\t{ pose = "%s_1", time = 0.12, style = "Quad", '
                'dir = "Out", marca = "GOLPE" },\n\t\t'
                '{ pose = "GUARDA_1", time = 0.2, style = "Quad", dir = "Out" },\n\t},'
                % (nome, nome))
    linhas = ["\t%s = {" % nome]
    for indice in range(1, len(track)):
        dt = track[indice][0] - track[indice - 1][0]
        marca = ""
        if indice == 1:
            marca = ', marca = "CARGA"'
        elif indice == len(track) - 1:
            marca = ', marca = "GOLPE"'
        linhas.append(
            '\t\t{ pose = "%s_%d", time = %s, style = "Exponential", dir = "Out"%s },'
            % (nome, indice + 1, num(max(dt, 0.03)), marca))
    linhas.append('\t\t{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },')
    linhas.append("\t},")
    return "\n".join(linhas)


# ═══════════════════════════════════════════════════════════════

# (arquivo, tecla, linha inicial, linha final, nome da TRACK)
# (tecla, linha inicial, linha final, nome da sequência, guarda de fundo)
# A guarda é a postura que segura o corpo enquanto o golpe move só o braço.
# As quatro moves de fogo saem da segunda forma do script, cuja guarda é o
# `Idle2` — usar o `Idle` de cartas ali deixaria o mago de fogo em pose de
# baralho.
RAMOS_F1 = [
    ("q", 1577, 1748, "ATO_DE_DESAPARECER", ("Idle", None)),
    ("e", 749, 946, "FULL_HOUSE", ("Idle", None)),
    ("r", 619, 749, "CARDNADO", ("Idle", None)),
    ("t", 1493, 1577, "TELEPORTE", ("Idle", None)),
    ("y", 946, 1165, "CARTA_COLOSSAL", ("Idle", None)),
    ("u", 1165, 1493, "BURACO_NEGRO", ("Idle", None)),
    ("p", 1748, 2057, "ESCUDO_DE_CARTAS", ("Idle", None)),
    ("g", 2432, 2549, "BOLA_DE_FOGO", ("Idle2", None)),
    ("h", 2549, 2859, "BOLA_DE_FOGO_IMENSA", ("Idle2", None)),
    ("j", 2859, 3065, "SOPRO_DO_DRAGAO", ("Idle2", None)),
    ("k", 3065, 3235, "RAIO", ("Idle2", None)),
]

# `True` = postura de cajado (`if secondform`), `False` = antes da transformação.
# Cinco das sete só existem depois do cajado; machado e provocação, antes.
RAMOS_F2 = [
    ("y", 1040, 1304, "CARTA_CEIFEIRA", ("Idle", True)),
    ("r", 1306, 1549, "ESFERA_DO_FIM", ("Idle", True)),
    ("q", 1549, 1674, "BARALHO_ESPECTRAL", ("Idle", True)),
    ("g", 1674, 1775, "INVOCACAO", ("Idle", True)),
    ("z", 1814, 1874, "FURIA_DO_MACHADO", ("Idle", False)),
    ("e", 1874, 2366, "PROCISSAO_DE_CARTAS", ("Idle", True)),
    # o ramo `m` só toca o som; a pose da provocação mora em `taunt()`
    ("m", 432, 478, "GARGALHADA", ("Idle", False)),
]

# Ramos que o original REALMENTE não anima — não é falha do extrator.
SEM_POSE = {
    "TELEPORTE": "o original teleporta em um quadro: ghost(), som, "
                 "Root.CFrame = mouse.Hit.p, wait(.1). Não há pose a extrair.",
}


def processar(caminho, ramos, rotulo):
    linhas = open(caminho, encoding="utf-8", errors="replace").read().splitlines()

    def guarda_global(marca, segunda):
        return pose_sustentada(linhas, 0, len(linhas), marca, segunda) \
            or estado_inicial()

    base = guarda_global(*ramos[0][4])
    tracks = {"GUARDA": [(0.0, dict((JUNTAS[l][0], compor(base, l)) for l in JUNTAS))]}
    relatorio = []
    for tecla, ini, fim, nome, guarda in ramos:
        postura = pose_sustentada(linhas, ini - 1, fim - 1, "Idle2") \
            or guarda_global(*guarda)
        track, tocadas = montar_track(linhas, ini - 1, fim - 1, postura)
        if not track:
            # a habilidade existe, mas o original não a anima: entra com um
            # keyframe só, para o Client ter algo nomeado a tocar
            tracks[nome] = [(0.0, dict(
                (JUNTAS[l][0], compor(postura, l)) for l in JUNTAS))]
            relatorio.append((tecla, nome, 1, 0.0,
                              SEM_POSE.get(nome, "o original não anima este ramo")))
            continue
        tracks[nome] = track
        relatorio.append((tecla, nome, len(track), track[-1][0],
                          "anima " + " ".join(sorted(tocadas))))

    print("  %s" % rotulo)
    for tecla, nome, kf, dur, obs in relatorio:
        print("    %-2s %-24s %3d keyframes  %5.2fs  %s"
              % (tecla, nome, kf, dur, obs))
    return tracks


def escrever_modulo(tracks, nomes, titulo):
    """Monta o texto de um ModuleScript `Poses` com as poses e as SEQUENCIAS."""
    corpo = [CABECALHO % titulo, "local P = {}\n"]
    for nome in nomes:
        corpo.append(emitir_poses(nome, tracks[nome]))
        corpo.append("")
    corpo.append("P.SEQUENCIAS = {\n")
    for nome in nomes:
        if nome == "GUARDA":
            continue
        corpo.append(emitir_sequencia(nome, tracks[nome]))
        corpo.append("")
    corpo.append("}\n\nreturn P\n")
    return "\n".join(corpo)


def main():
    f1 = os.path.join(ENTRADA, "Xester_Forma1.rbxmx")
    f2 = os.path.join(ENTRADA, "Xester_Forma2_O_Despertar.rbxmx")
    fonte1 = os.environ.get("XESTER_F1")
    fonte2 = os.environ.get("XESTER_F2")
    if not (fonte1 and fonte2):
        print("Este extrator lê os .lua já desempacotados dos dois .rbxmx.")
        print("Aponte XESTER_F1 e XESTER_F2 para eles.")
        print("  origem 1: %s" % f1)
        print("  origem 2: %s" % f2)
        return 2

    print("EXTRAÇÃO DE POSES — Xester")
    print("")
    t1 = processar(fonte1, RAMOS_F1, "Forma 1 — o Mestre das Cartas")
    print("")
    t2 = processar(fonte2, RAMOS_F2, "Forma 2 — O Despertar")

    saida = {}
    for titulo, tracks, ramos, arquivo in (
        ("Forma1", t1, RAMOS_F1, "Poses_Xester_Forma1_V1.lua"),
        ("Forma2", t2, RAMOS_F2, "Poses_Xester_Forma2_V1.lua"),
    ):
        nomes = ["GUARDA"] + [r[3] for r in ramos]
        destino = os.path.join(RAIZ, "ACERVO_RETROVERSE", "_AUTORAL_RetroVerse",
                               "R6_CFRAME", arquivo)
        with open(destino, "w", encoding="utf-8") as f:
            f.write(escrever_modulo(tracks, nomes, titulo))
        print("")
        print("  %s → %s" % (titulo, os.path.relpath(destino, RAIZ)))

        # a mesma tabela em JSON: é dela que o gerador monta o Poses.lua de
        # cada Tool, com só as sequências daquela Tool
        saida[titulo] = dict(
            (nome, [{"t": t, "juntas": dict((j, escrever_cf(c))
                                            for j, c in juntas.items())}
                    for t, juntas in tracks[nome]])
            for nome in nomes)

    pasta = os.path.join(RAIZ, "FERRAMENTAS", "dados")
    os.makedirs(pasta, exist_ok=True)
    with open(os.path.join(pasta, "poses_xester.json"), "w", encoding="utf-8") as f:
        json.dump(saida, f, ensure_ascii=False, indent=1)
    print("  tabela   → FERRAMENTAS/dados/poses_xester.json")
    return 0


CABECALHO = '''-- Poses_Xester_%s_V1.lua
-- ModuleScript "Poses" — TRACKS extraídas do script original do modelo
--
-- NÃO É POSE AUTORAL. Cada keyframe é a pose que o script original REALMENTE
-- alcança: o extrator simula o `:lerp(alvo, alpha)` repetido N quadros
-- (`1-(1-alpha)^N`) em vez de copiar o alvo, porque com alpha baixo o original
-- nunca chega ao alvo escrito no código.
--
-- Convenção: C0 do animator = C0 do original invertido (o original solda
-- membro→Torso, o animator solda Torso→membro). HRP entra sem inverter.
--
-- Gerado por FERRAMENTAS/extrair_poses_xester.py — não editar à mão.

'''


if __name__ == "__main__":
    sys.exit(main())
