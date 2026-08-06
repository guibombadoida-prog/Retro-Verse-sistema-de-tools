#!/usr/bin/env python3
"""
verificar_poses.py — Retro-Verse / Studios

Confere as tabelas de pose de cada Tool contra o R6CFrameAnimator V2.

    python3 TESTES/verificar_poses.py

Sai com 1 se qualquer Tool falhar.

O que confere:
  1. Toda junta citada existe no animator — nome errado é ERRO SILENCIOSO:
     o animator ignora a junta e a pose simplesmente não sai
  2. Todo `pose = "X"` de sequência aponta para uma pose que existe
  3. Nenhuma sequência é inteiramente NEUTRA — sequência que não move nada é
     animação morta, e o Studio não reclama disso
  4. Sequência usa `time`/`style`/`dir` (V2), não `duracao`/`easing` (V1)
  5. Pose com perna traz o aviso do ReleaseLegs no cabeçalho

A checagem 3 nasceu de defeito real: duas Tools tinham a sequência inteira com
as poses iguais à base do Weld. As habilidades não animavam nada, e o Studio não
reclama disso — pose neutra é pose válida.
"""

import glob
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

VERMELHO = "\033[31m%s\033[0m"
VERDE = "\033[32m%s\033[0m"
CINZA = "\033[90m%s\033[0m"

# As seis juntas que o R6CFrameAnimator V2 solda. Qualquer outro nome é erro.
JUNTAS = {
    "RightArm": (1.5, 0.0, 0.0),
    "LeftArm": (-1.5, 0.0, 0.0),
    "Head": (0.0, 1.5, 0.0),
    "HRP": (0.0, 0.0, 0.0),
    "RightLeg": (0.5, -2.0, 0.0),
    "LeftLeg": (-0.5, -2.0, 0.0),
}
PERNAS = ("RightLeg", "LeftLeg")

IDENTIDADE = (1, 0, 0, 0, 1, 0, 0, 0, 1)
TOLERANCIA = 1e-4

NUMERO = re.compile(r"-?\d*\.?\d+(?:[eE][-+]?\d+)?")
# `{` pode ser seguido de comentário na mesma linha — é Lua válido, e ignorar
# isso fazia o bloco inteiro passar despercebido (uma pose invisível para o
# lint é pior que uma pose errada).
BLOCO_POSE = re.compile(
    r"\n\t(\w+)\s*=\s*\{[^\n]*\n((?:\t+\w+\s*=\s*[^\n]*\n)+)\t\},")
CAMPO = re.compile(r"\t+(\w+)\s*=\s*([^\n]+),\s*$", re.MULTILINE)
BLOCO_SEQ = re.compile(r"\n\t(\w+)\s*=\s*\{\n((?:\t\t\{ pose[^\n]*\n)+)\t\},")
PASSO = re.compile(r'\{ pose = "(\w+)",([^}]*)\}')


def mexe(junta, valor):
    """A junta sai da base? Angles/graus na expressão já contam como mexer."""
    if "Angles" in valor or "graus(" in valor:
        return True
    numeros = [float(x) for x in NUMERO.findall(valor)]
    base = JUNTAS.get(junta)
    if base is None or not numeros:
        return False
    if any(abs(a - b) > TOLERANCIA for a, b in zip(numeros[:3], base)):
        return True
    rotacao = numeros[3:12]
    if len(rotacao) == 9:
        if any(abs(r - i) > TOLERANCIA for r, i in zip(rotacao, IDENTIDADE)):
            return True
    return False


# A tabela de sequências pode ser `Poses.SEQUENCIAS`, `P.SEQUENCIAS` ou
# `SEQUENCIAS` solta: o que importa é onde ela começa, porque é ali que o
# bloco de poses termina. Exigir um prefixo específico só servia para o
# formato que eu mesmo tinha escrito antes.
ABRE_SEQ = re.compile(r"(?m)^(?:\w+\.)?SEQUENCIAS\s*=\s*\{")

# Pose no topo do arquivo: `P.GUARDA = {` … `}` com o fecha na coluna zero.
# O corpo é pego inteiro e só depois fatiado por campo — um `CFrame.new(` com
# os doze componentes em linhas separadas é Lua perfeitamente normal, e o
# padrão antigo (um campo por linha) não enxergava a pose inteira. Pose
# invisível para o lint vira "a sequência chama uma pose que não existe".
BLOCO_POSE_TOPO = re.compile(
    r"(?m)^(?:\w+\.)?([A-Z][\w]*)\s*=\s*\{[^\n]*\n(.*?)\n\}", re.S)

INICIO_CAMPO = re.compile(r"(?m)^\t(\w+)\s*=\s*")


def campos(corpo):
    """(junta, valor) de um corpo de pose, com valores de várias linhas."""
    marcas = list(INICIO_CAMPO.finditer(corpo))
    saida = []
    for i, m in enumerate(marcas):
        fim = marcas[i + 1].start() if i + 1 < len(marcas) else len(corpo)
        saida.append((m.group(1), corpo[m.end():fim].strip().rstrip(",")))
    return saida


def verificar(caminho):
    texto = open(caminho, encoding="utf-8").read()
    erros = []

    # A perna é liberada pelo ANIMATOR, que viaja dentro da Tool e chama
    # ReleaseLegs ao fim de toda sequência. Procurar a citação só no arquivo de
    # poses acusava as 7 Tools cujo comportamento estava correto. O escopo certo
    # é a Tool inteira: se ninguém ali libera, aí sim a perna fica soldada.
    pasta = os.path.dirname(caminho)
    vizinhos = ""
    for arq in sorted(os.listdir(pasta)):
        if arq.endswith(".lua"):
            vizinhos = vizinhos + open(os.path.join(pasta, arq),
                                       encoding="utf-8").read()

    abertura = ABRE_SEQ.search(texto)
    if abertura is None:
        return ["sem tabela SEQUENCIAS — formato do V2"]

    corte = abertura.start()
    bloco_poses = texto[:corte]
    bloco_seqs = texto[corte:]

    poses, usa_perna = {}, False
    achados = BLOCO_POSE.findall(bloco_poses) + BLOCO_POSE_TOPO.findall(bloco_poses)
    if not achados:
        erros.append("nenhuma pose reconhecida antes de SEQUENCIAS — "
                     "verificador cego é pior que verificador ausente")
    for nome, corpo in achados:
        juntas = {}
        for junta, valor in campos(corpo):
            # 1. junta conhecida
            if junta not in JUNTAS:
                erros.append(
                    "pose %r cita a junta %r, que o animator não solda — "
                    "a pose não sai, e nada avisa" % (nome, junta)
                )
                continue
            if junta in PERNAS:
                usa_perna = True
            juntas[junta] = mexe(junta, valor)
        poses[nome] = juntas

    # 5. perna exige o aviso do ReleaseLegs
    if usa_perna and "ReleaseLegs" not in vizinhos:
        erros.append(
            "usa perna sem citar ReleaseLegs — perna soldada trava a caminhada"
        )

    for nome, corpo in BLOCO_SEQ.findall(bloco_seqs):
        viva = False
        for pose, resto in PASSO.findall(corpo):
            # 4. chaves do V2 — antes do teste de existência, senão um passo com
            #    pose fantasma esconderia o formato velho
            if "duracao" in resto or "easing" in resto:
                erros.append(
                    "sequência %r usa duracao/easing (V1) — o V2 quer time/style/dir"
                    % nome
                )
            # 2. a pose referida existe
            if pose not in poses:
                erros.append("sequência %r chama a pose %r, que não existe" % (nome, pose))
                continue
            if any(poses[pose].values()):
                viva = True
        # 3. sequência morta
        if not viva and poses:
            erros.append(
                "sequência %r não move nenhuma junta em nenhum quadro — "
                "animação morta" % nome
            )

    return erros


def main():
    # `Poses_*.lua` sozinho NÃO serve: Tool clonada traz o arquivo como
    # `Poses.lua`, e o glob antigo casava zero arquivos. Uma suíte que verifica
    # nada e imprime OK é pior do que não existir — por isso o padrão pegou
    # todos os `Poses*.lua` e a contagem zero passou a ser falha.
    caminhos = sorted(glob.glob(os.path.join(RAIZ, "Tools", "*", "Poses*.lua")))

    print("")
    print("VERIFICAÇÃO DAS TABELAS DE POSE")
    print(CINZA % "Juntas do R6CFrameAnimator V2, sequências vivas, formato V2")
    print("")

    if not caminhos:
        print(VERMELHO % "NENHUMA TABELA DE POSE ENCONTRADA")
        print(CINZA % "Tools/*/Poses*.lua não casou nada — o verificador estaria cego")
        print("")
        return 1

    total = 0
    for caminho in caminhos:
        tool = os.path.basename(os.path.dirname(caminho))
        erros = verificar(caminho)
        if erros:
            total += len(erros)
            print(VERMELHO % ("✗ %s" % tool))
            for e in erros:
                print("    %s" % e)
        else:
            print(VERDE % ("✓ %s" % tool))

    print("")
    if total == 0:
        print(VERDE % "TODAS AS TABELAS DE POSE OK")
        print("")
        return 0
    print(VERMELHO % ("%d PROBLEMA(S)" % total))
    print(CINZA % "Ver DIRETRIZES/REGRA_ANIMACAO_R6.md")
    print("")
    return 1


if __name__ == "__main__":
    sys.exit(main())
