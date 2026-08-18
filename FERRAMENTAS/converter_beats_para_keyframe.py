#!/usr/bin/env python3
"""
converter_beats_para_keyframe.py — Retro-Verse / Studios

Troca a escada `elseif marca ==` dos geradores por TABELA DE KEYFRAME mais
`despachar()`.

    python3 FERRAMENTAS/converter_beats_para_keyframe.py FERRAMENTAS/gerar_servers_faker.py

Rodou uma vez, em 5 geradores, e converteu 167 ramos. Fica guardado porque é a
ferramenta que prova o que foi feito — e porque o próximo conjunto que nascer
com escada passa por aqui.

O QUE ELE RECUSA, E POR QUE ISSO IMPORTA

    Ele só entende ramificação na forma `if/elseif marca == "X" then`. Qualquer
    outra coisa no nível da escada — `else`, `elseif marca ~= "X"`, `if` de
    outra variável — faz a conversão daquele bloco ser PULADA, com o motivo no
    relatório.

    Isso não é excesso de zelo: a primeira versão engolia o que não entendia, e
    o `elseif marca ~= "BATE"` do `Terremoto` virou corpo do ramo anterior. O
    Lua saiu sintaticamente inválido e só o `luac` pegou.

    Os 6 blocos recusados usam `if marca ~= "X" then return end` como guarda de
    saída antecipada. Já é padrão limpo, não escada: ficam como estão.
"""
import re, sys

ABRE = ', function(passo)\n\t\tlocal marca = marcaDe(passo)\n'
FECHA = '\n\tend, function()'

RE_SO_TOCAR = re.compile(r'^tocar\("([A-Z_]+)"(?:,\s*([0-9.]+))?\)$')
RE_SO_CENA  = re.compile(r'^beatCena\("([A-Z_]+)"\)$')


#: qualquer ramificação no nível da escada que NÃO seja `marca == "X"`.
#: `elseif marca ~= "BATE"`, `else`, `elseif outraCoisa` — o conversor não
#: entende nenhuma delas, e engolir o que não se entende foi exatamente o que
#: quebrou o `Terremoto`: o `else` virou corpo do ramo anterior e o Lua saiu
#: sintaticamente inválido.
RE_RAMO_ESTRANHO = re.compile(r'^\t\t(?:else\s*$|elseif (?!marca == ")|if (?!marca == "))')


def ramos_de(corpo):
    """[(marca, [linhas])] a partir do miolo da escada.

    Devolve `None` se houver ramificação que este conversor não entende — aí
    a escada fica como estava, e o relatório diz qual foi.
    """
    for linha in corpo.split("\n"):
        if RE_RAMO_ESTRANHO.match(linha):
            return None
    saida, atual, buf = [], None, []
    for linha in corpo.split("\n"):
        m = re.match(r'\t\t(?:els)?e?if marca == "([A-Z_]+)" then\s*$', linha)
        if m:
            if atual: saida.append((atual, buf))
            atual, buf = m.group(1), []
            continue
        if re.match(r'\t\tend\s*$', linha):
            if atual: saida.append((atual, buf)); atual = None
            continue
        if atual is not None:
            buf.append(linha)
    if atual: saida.append((atual, buf))
    return saida


def virar_tabela(ramos):
    linhas = ["despachar({"]
    for marca, corpo in ramos:
        uteis = [l for l in corpo if l.strip()]
        campos, resto = [], []
        for l in uteis:
            st = l.strip()
            mc = RE_SO_CENA.match(st)
            mt = RE_SO_TOCAR.match(st)
            if mc and mc.group(1) == marca and not any("cam = true" in c for c in campos):
                campos.append("cam = true")
            elif mt and not any(c.startswith("sfx") for c in campos) and not resto:
                p = mt.group(2)
                campos.append('sfx = { "%s"%s }' % (mt.group(1), (", " + p) if p else ""))
            else:
                resto.append(l)
        if resto:
            # a indentação NÃO muda: o corpo saía de `if marca == X then` em
            # \t\t e entra em `faz = function()` em \t\t — mesmo nível. Reindentar
            # achatava linha de continuação e embaralhava a leitura.
            corpo_fn = "\n".join(resto)
            campos.append("faz = function()\n%s\n\t\tend" % corpo_fn)
        if not campos:
            campos.append("cam = true")
        linhas.append("\t\t%s = { %s }," % (marca, ", ".join(campos)))
    linhas.append("\t})")
    return "\n".join(linhas)


PULADAS = []


def converter(texto):
    saida, i, n = [], 0, 0
    while True:
        a = texto.find(ABRE, i)
        if a < 0:
            saida.append(texto[i:]); break
        b = texto.find(FECHA, a)
        if b < 0:
            saida.append(texto[i:]); break
        miolo = texto[a + len(ABRE):b]
        limpo = miolo.replace("\t\tif not marca then return end\n", "")
        ramos = ramos_de(limpo)
        if ramos is None:
            PULADAS.append(texto[a:a + 200].split("\n")[2].strip()[:60])
        if not ramos:
            saida.append(texto[i:b]); i = b; continue
        saida.append(texto[i:a])
        saida.append(", " + virar_tabela(ramos))
        n += len(ramos)
        i = b + len(FECHA)
        saida.append(", function()")
    return "".join(saida), n


if __name__ == "__main__":
    total = 0
    for p in sys.argv[1:]:
        s = open(p, encoding="utf-8").read()
        novo, n = converter(s)
        if n:
            open(p, "w", encoding="utf-8").write(novo)
            total += n
            print("  %-30s %d ramo(s) viraram keyframe" % (p.split("/")[-1], n))
    print("total: %d" % total)
    if PULADAS:
        print("PULADAS (ramificação que o conversor não entende):")
        for x in PULADAS:
            print("   %s" % x)
