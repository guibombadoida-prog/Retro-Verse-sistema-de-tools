#!/usr/bin/env python3
"""
preparar_maria.py — Retro-Verse / Studios

Monta a base das 7 Tools do conjunto MARIA, a partir do `mariatools.rbxmx`.

    python3 FERRAMENTAS/preparar_maria.py

════════════════════════════════════════════════════════════════════════
OITO CAJADOS VIRAM SETE — E O PAR QUE SE FUNDE NÃO FOI ESCOLHIDO NO OLHO
════════════════════════════════════════════════════════════════════════

    A `REGRA_DISTRIBUICAO_DE_TOOLS` dá teto 7. A origem tem 8 `Tool`, então uma
    habilidade tem de virar Extra de outra — e a pergunta é QUAL par.

    Lendo os dois `MainAttack`, a resposta é única:

      `Cajado Curador`         feixe no alvo, `Health + 2` dez vezes = cura 20
      `Cajado Roubador de Hp`  feixe no alvo, `TakeDamage(faltante/10)` dez
                               vezes, e a MESMA quantia entra na própria vida

    É o mesmo feixe, a mesma cadência de dez tiques, a mesma `Attachment` no
    `HumanoidRootPart` do alvo. Um dá, o outro tira. São a mesma Tool espelhada,
    e por isso o Roubar entra como Extra do Curador em vez de ocupar uma vaga.

    (O detalhe bonito do Roubador, que foi mantido: ele drena exatamente a SUA
    vida faltante. Cheio de vida, ele não rouba nada.)

════════════════════════════════════════════════════════════════════════
O QUE ATRAVESSA, E O QUE NÃO
════════════════════════════════════════════════════════════════════════

    ATRAVESSA — dado: `Handle` com as soldas, a pasta `ExtraTHICK` (as peças
    decorativas do cajado), o `Sound` `Atk`, e os `ParticleEmitter`,
    `SpecialMesh`, `Trail` e `Beam` de cada um. Isso é o cajado.

    NÃO ATRAVESSA — código e o que ele arrasta:

      `Script` · `LocalScript` · a pasta `Scripts`
          Reescritos. Os originais usam `wait`, `math.random` em gameplay,
          `Health = Health + x` direto, `HumanoidRootPart.Anchored = true` no
          jogador e `Instance.new("Explosion")` — cinco proibições.

      a pasta `Animation` (R6 e R15)
          São `Animation` com `AnimationId`, tocadas por `LoadAnimation`. O
          `CLAUDE.md` proíbe as duas coisas: pose R6 aqui é tabela `CFrame` sob
          o `R6CFrameAnimator`.

      `GetMouse` (RemoteEvent)
          A mira passa a viajar no payload do `VFXRemote`, como no resto do
          repositório.

    ⚠️ O `Anchored` do `Cajado De Gelo` merece nota. A origem faz
       `humanoid.Parent.HumanoidRootPart.Anchored = true` para congelar. Se a
       Tool sumir no meio — troca de personagem, morte, `Destroy` — o jogador
       fica preso no lugar PARA SEMPRE, sem nada que desfaça. Vira `prender()`,
       que é `BodyPosition` com prazo.
"""

import copy
import os
import re
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from preparar_xester import nova_raiz, novo_item  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "MODELOS_ENTRADA", "Maria_Tools", "mariatools.rbxmx")
SAIDA = os.path.join(RAIZ, "MODELOS_ENTRADA", "Maria_Tools",
                     "Maria_7_Tools.rbxmx")

#: sai tudo: é código, ou é o que o código arrastava
CLASSES_FORA = ("Script", "LocalScript", "ModuleScript", "RemoteEvent",
                "RemoteFunction", "Animation", "ScreenGui", "Humanoid")
NOMES_FORA = ("Scripts", "Animation", "GetMouse")

#: chave normalizada -> nome na entrega. O 8º não vira Tool: vira Extra do 1º.
#:
#: ⚠️ OS NOMES NA ORIGEM ESTÃO COM MOJIBAKE. O arquivo guarda `EscuridÃ£o` e
#:    `RelÃ£mpago` — UTF-8 gravado como se fosse Latin-1, provavelmente por um
#:    plugin de export antigo. Casar por string exata falharia em três das oito,
#:    e casar pelo texto "certo" falharia igual.
#:
#:    A chave é o nome com os não-ASCII removidos: sobra `Cajado Da Escurido`
#:    dos dois lados, e a busca funciona sem depender de qual dos dois textos
#:    o arquivo tem.
NOMES = {
    "cajado curador": "Cajado Curador",
    "cajado da escurido": "Cajado da Escuridao",
    "cajado da iluso": "Cajado da Ilusao",
    "cajado das estrelas": "Cajado das Estrelas",
    "cajado de gelo": "Cajado de Gelo",
    "cajado do meteoro": "Cajado do Meteoro",
    "cajado relmpago": "Cajado Relampago",
}


def chave_de(texto):
    """O nome sem acento nem mojibake: só ASCII, minúsculo."""
    return re.sub(r"[^a-z ]", "", (texto or "").lower()).strip()
FUNDIDO = "Cajado Roubador de Hp"

#: SFX extra — TODO id já toca em Tool entregue deste repositório.
#: O `Atk` da origem vira o som da primária; os três de baixo são das Extras.
SONS_EXTRA = {
    "Cajado Curador": [("ROUBO", "363808674", 3, 0.9),      # DRENO
                       ("BENCAO", "824687369", 4, 1.15),    # COROA
                       ("RESSURGIR", "236989198", 4, 1.0)],
    "Cajado da Escuridao": [("ENXAME", "1894958339", 4, 1.1),
                            ("CEGUEIRA", "1072606965", 4, 0.7),
                            ("MANTO", "743521450", 3, 0.85)],
    "Cajado da Ilusao": [("TROCAR", "260281717", 3.5, 1.2),
                         ("MULTIPLICAR", "1888686669", 4, 1.25),
                         ("DISPERSAR", "472579737", 4, 1.3)],
    "Cajado das Estrelas": [("CHUVA", "2960518660", 4, 1.35),
                            ("CONSTELACAO", "824687369", 4, 1.4),
                            ("GUIA", "342337569", 3, 1.2)],
    "Cajado de Gelo": [("PRISAO", "413682983", 4, 1.05),
                       ("TRILHA", "342337569", 3, 1.5),
                       ("ESTILHACAR", "413682983", 4, 1.45)],
    "Cajado do Meteoro": [("CHUVA", "472579737", 5, 0.65),
                          ("CRATERA", "472214107", 4, 0.8),
                          ("IMPACTO", "220834019", 4, 0.9)],
    "Cajado Relampago": [("TEMPESTADE", "1910988873", 5, 0.8),
                         ("CORRENTE", "546410481", 3.5, 1.4),
                         ("PARARAIOS", "260281717", 4, 1.1)],
}

#: (nome, ToolTip, arquetipo, recarga M1, R, T, Y, chave)
CONJUNTO = [
    ("Cajado Curador",
     "Feixe que cura 20. R rouba a vida que te falta, T abencoa em area, Y ressurge.",
     "SUPORTE", 1.2, 14, 20, 34, "Maria_Curador"),
    ("Cajado da Escuridao",
     "Orbe negro teleguiado. R enxame, T cegueira, Y manto.",
     "ESPECTRAL", 1.0, 12, 18, 30, "Maria_Escuridao"),
    ("Cajado da Ilusao",
     "Isca que vaga no seu lugar. R troca com ela, T multiplica, Y dispersa.",
     "ESPECTRAL", 1.4, 16, 22, 28, "Maria_Ilusao"),
    ("Cajado das Estrelas",
     "Estrela de 16 studs, dano 10. R chuva, T constelacao, Y estrela-guia.",
     "EXPLOSIVO", 1.1, 13, 21, 32, "Maria_Estrelas"),
    ("Cajado de Gelo",
     "Feixe que congela. R prisao em area, T trilha escorregadia, Y estilhacar.",
     "ESPECTRAL", 1.3, 15, 19, 29, "Maria_Gelo"),
    ("Cajado do Meteoro",
     "Meteoro de 53 studs, dano 50. R chuva, T cratera, Y impacto.",
     "EXPLOSIVO", 1.6, 18, 24, 40, "Maria_Meteoro"),
    ("Cajado Relampago",
     "Quatro raios e estouro raio 10. R tempestade, T corrente, Y para-raios.",
     "EXPLOSIVO", 1.2, 14, 20, 33, "Maria_Relampago"),
]


def nome(item):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == "Name":
            return e.text
    return None


def definir_nome(item, valor):
    p = item.find("Properties")
    for e in p:
        if e.get("name") == "Name":
            e.text = valor
            return


def podar(item):
    """Tira todo código e o que o código arrastava. Recursivo."""
    tirados = 0
    for filho in list(item.findall("Item")):
        if filho.get("class") in CLASSES_FORA or nome(filho) in NOMES_FORA:
            item.remove(filho)
            tirados = tirados + 1
        else:
            tirados = tirados + podar(filho)
    return tirados


def remarcar(item, marca, contador):
    """Referent único por Tool: dois clones com o mesmo referent se sobrescrevem."""
    velho = item.get("referent")
    contador[0] = contador[0] + 1
    novo = "RV_M_%s_%d" % (marca, contador[0])
    item.set("referent", novo)
    if velho:
        contador[1][velho] = novo
    for filho in item.findall("Item"):
        remarcar(filho, marca, contador)


def consertar_refs(item, mapa):
    """`Ref` que aponta para referent antigo passa a apontar para o novo."""
    p = item.find("Properties")
    for e in (p if p is not None else []):
        if e.tag == "Ref" and e.text in mapa:
            e.text = mapa[e.text]
    for filho in item.findall("Item"):
        consertar_refs(filho, mapa)


def main():
    if not os.path.exists(ORIGEM):
        print("origem não encontrada: %s" % ORIGEM)
        return 1
    raiz_origem = ET.parse(ORIGEM).getroot()

    por_nome = {}
    for t in raiz_origem.iter("Item"):
        if t.get("class") == "Tool":
            por_nome[chave_de(nome(t))] = t

    faltando = [n for n in NOMES if n not in por_nome]
    if faltando:
        print("não achei na origem: %s" % ", ".join(faltando))
        print("disponíveis: %s" % ", ".join(sorted(por_nome)))
        return 1

    raiz = nova_raiz()
    resumo = []

    for dados in CONJUNTO:
        alvo, tooltip, arquetipo, rec_m1, rec_r, rec_t, rec_y, chave = dados
        na_origem = next(k for k, v in NOMES.items() if v == alvo)
        marca = chave.replace("Maria_", "")

        tool = copy.deepcopy(por_nome[na_origem])
        tirados = podar(tool)
        definir_nome(tool, alvo)

        contador = [0, {}]
        remarcar(tool, marca, contador)
        consertar_refs(tool, contador[1])

        props = tool.find("Properties")
        for campo, tag, valor in (("ToolTip", "string", tooltip),
                                  ("RequiresHandle", "bool", "true"),
                                  ("CanBeDropped", "bool", "false")):
            achou = False
            for e in props:
                if e.get("name") == campo:
                    e.text = valor
                    achou = True
            if not achou:
                ET.SubElement(props, tag, {"name": campo}).text = valor

        # os sons: o `Atk` da origem vira ATAQUE, e entram os três das Extras.
        # Tudo dentro de uma pasta SFX, que é onde o gerador procura.
        sfx, _ = novo_item(tool, "Folder", "SFX", "RV_MSFX_%s" % marca)
        for filho in list(tool.findall("Item")):
            if filho.get("class") == "Sound" and nome(filho) == "Atk":
                tool.remove(filho)
                definir_nome(filho, "ATAQUE")
                sfx.append(filho)
        for rotulo, ident, volume, pitch in SONS_EXTRA[alvo]:
            _s, sp = novo_item(sfx, "Sound", rotulo,
                               "RV_MS_%s_%s" % (marca, rotulo))
            conteudo = ET.SubElement(sp, "Content", {"name": "SoundId"})
            ET.SubElement(conteudo, "url").text = "rbxassetid://%s" % ident
            ET.SubElement(sp, "float", {"name": "Volume"}).text = str(volume)
            ET.SubElement(sp, "float", {"name": "PlaybackSpeed"}).text = str(pitch)
            ET.SubElement(sp, "float",
                          {"name": "RollOffMaxDistance"}).text = "180"

        for classe, tag, campo, valor in (
                ("StringValue", "string", "DamageClass", arquetipo),
                ("StringValue", "string", "ChaveRecarga", chave),
                ("NumberValue", "float", "EnergyCost", "0"),
                ("NumberValue", "float", "RecargaGlobal", str(rec_m1))):
            _i, vp = novo_item(tool, classe, campo,
                               "RV_MV_%s_%s" % (marca, campo[:6]))
            ET.SubElement(vp, tag, {"name": "Value"}).text = valor

        novo_item(tool, "RemoteEvent", "VFXRemote", "RV_MVFX_%s" % marca)
        novo_item(tool, "RemoteEvent", "AcaoRemote", "RV_MACAO_%s" % marca)

        objeto = "%s_Server_V1" % re.sub(r"[^\w]", "", alvo)
        for classe, script in (("Script", objeto), ("Script", "Client"),
                               ("ModuleScript", "R6CFrameAnimator"),
                               ("ModuleScript", "Poses"),
                               ("ModuleScript", "VFXModule")):
            _i, sp = novo_item(tool, classe, script,
                               "RV_MSC_%s_%s" % (marca, script[:10]))
            ET.SubElement(sp, "ProtectedString", {"name": "Source"}).text = ""
            if script == "Client":
                ET.SubElement(sp, "token", {"name": "RunContext"}).text = "2"

        raiz.append(tool)
        moldes = sorted({nome(x) for x in tool.iter("Item")
                         if x.get("class") in ("ParticleEmitter", "SpecialMesh",
                                               "Trail", "Beam")})
        resumo.append((alvo, na_origem, tirados, len(SONS_EXTRA[alvo]) + 1,
                       moldes))

    # ── A TABELA <SharedStrings>, sem a qual o Studio recusa o arquivo
    #
    # `MeshPart.AeroMeshData` é gravado como
    # `<SharedString name="AeroMeshData">md5</SharedString>` — uma CITAÇÃO. Quem
    # resolve a md5 é um bloco `<SharedStrings>` IRMÃO dos `Item`, no nível do
    # `<roblox>`, e ele não viaja quando se copia só a Tool.
    #
    # Sem ele a citação fica pendurada: o `rbx-dom` lê a propriedade como outro
    # tipo e a conversão para `.rbxm` morre, e o Studio chama o `.rbxmx` de
    # corrompido. Foi o mesmo defeito do `restaurar_reality_original.py`.
    tabela = {}
    for e in raiz_origem.iter("SharedString"):
        if e.get("md5"):
            tabela[e.get("md5")] = e.text

    citadas = {(e.text or "").strip() for e in raiz.iter("SharedString")
               if e.get("name")}
    citadas.discard("")

    penduradas = sorted(m for m in citadas if m not in tabela)
    if penduradas:
        print("⛔ %d SharedString sem valor na origem: %s"
              % (len(penduradas), ", ".join(penduradas[:3])))
        return 1

    if citadas:
        bloco = ET.SubElement(raiz, "SharedStrings")
        for md5 in sorted(citadas):
            ET.SubElement(bloco, "SharedString", {"md5": md5}).text = tabela[md5]

    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    ET.ElementTree(raiz).write(SAIDA, encoding="utf-8", xml_declaration=True)

    print("%-22s %-22s %s" % ("ENTREGA", "ORIGEM", "podados · sons · moldes"))
    for alvo, na_origem, tirados, sons, moldes in resumo:
        print("%-22s %-22s %2d · %d · %s"
              % (alvo, na_origem, tirados, sons, ", ".join(moldes) or "—"))
    print("")
    print("`%s` NÃO virou Tool: o feixe dele é o do Curador espelhado, e entra"
          % FUNDIDO)
    print("como Extra `R` ali. 8 -> 7, dentro do teto da regra.")
    print("")
    escrito = open(SAIDA, encoding="utf-8").read()
    for proibido in ("<Item class=\"Script\"", "<Item class=\"LocalScript\"",
                     "<Item class=\"Animation\"", "GetMouse"):
        n = escrito.count(proibido)
        if proibido == "<Item class=\"Script\"":
            n = n - 7 * 2   # os dois Script placeholder por Tool são meus
        print("   %-32s %d" % (proibido, n))
    print("")
    print("%s — %d bytes · 7 Tools · %d SharedString na tabela"
          % (os.path.relpath(SAIDA, RAIZ), os.path.getsize(SAIDA), len(citadas)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
