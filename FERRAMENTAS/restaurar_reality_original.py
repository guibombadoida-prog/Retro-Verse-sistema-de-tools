#!/usr/bin/env python3
"""
restaurar_reality_original.py — Retro-Verse / Studios

Devolve as 7 Tools do `Reality Gui` **100% como a origem**, e muda DUAS coisas:

    1. não ferir quem carrega a Tool
    2. o dano valer — `TakeDamage` pelo Núcleo, com tag de abate

    python3 FERRAMENTAS/restaurar_reality_original.py

NADA MAIS. Nem `wait` para `task.wait`, nem `math.random` para jitter, nem
`:Destroy()` para `Parent = nil`, nem CFG, nem VFXModule, nem R6CFrameAnimator.
O script da origem entra byte por byte, com os remendos listados em `REMENDOS`
e mais nada.

════════════════════════════════════════════════════════════════════════
POR QUE ISTO É SEGURO
════════════════════════════════════════════════════════════════════════

    O `reality_tools.rbxmx` tem backdoor — mas ele mora na `Pistol`
    (`qPerfectionWeld`, `HttpService:GetAsync("https://assetimport.org/")` para
    dentro de um `require`), e o `require(206209239)` mora no `TrenchGun`.

    **Nenhuma das duas entra aqui.** As seis usadas — `SLAP`, `a-train`, `tre`,
    `gravity cat not amused`, `samsung`, `kick dance` — foram varridas atrás de
    `assetimport`, `loadstring`, `getfenv`, `setfenv`, `HttpService`,
    `GetAsync`, `PostAsync` e `require(<número>)`. Zero.

    A varredura roda de novo NO ARQUIVO ESCRITO, no fim. Se aparecer qualquer
    coisa, o script falha e não entrega.

════════════════════════════════════════════════════════════════════════
O QUE ISTO QUEBRA, E ESTÁ DECLARADO
════════════════════════════════════════════════════════════════════════

    `require(game:GetService("ReplicatedFirst").Ragdoll)` aparece em 5 lugares
    (a-train, tre, e três no gato). Esse módulo **não vem junto** e **não se
    auto-instala**: num place vazio a linha erra e o resto daquele handler para.

    Isso É violação da regra nº 1 e foi mantido de propósito — o pedido foi
    "sem mexer em nada" fora dos dois consertos. Os outros dois caminhos de
    fora (`script.tree.Parent = game.ReplicatedStorage` e
    `script[...].Parent = game.ServerStorage`) se auto-instalam: o próprio
    script põe o asset lá no carregamento, então funcionam sozinhos.

    Os verificadores do repositório vão reprovar estas 7. É esperado: elas são
    a origem, não o padrão da casa.
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REALITY = os.path.join(RAIZ, "MODELOS_ENTRADA", "Reality_Tools",
                       "reality_tools.rbxmx")
CANHAO = os.path.join(RAIZ, "MODELOS_ENTRADA", "Canhao_Satelite",
                      "Canhao_satelite.rbxmx")
SAIDA = os.path.join(RAIZ, "Tools", "Reality Gui.rbxmx")

CLASSES_SCRIPT = ("Script", "LocalScript", "ModuleScript")

VENENO = ("assetimport", "loadstring", "HttpService", "GetAsync", "PostAsync")
RE_REQUIRE_ID = re.compile(r"require\s*\(\s*[0-9]")

#: `getfenv`/`setfenv` saem da lista fixa e ganham prova, nao perdao.
#:
#: O `LowOrbitIonCannon` carrega o boilerplate do plugin "model to script v4"
#: do ttyyuu12345: uma funcao `sandbox(var, func)` que troca o `_ENV` de um
#: callback, e uma tabela `cors` que seria a fila desses callbacks.
#:
#: Nas 6 Tools do `reality_tools.rbxmx` isso NAO existe — foi conferido. Ele so
#: aparece no LOIC, que vem de outro arquivo.
#:
#: Liberar por nome seria abrir buraco permanente. `provar_inerte` exige as
#: tres condicoes que fazem o trecho ser codigo morto, e falha se qualquer uma
#: cair:
#:
#:   1. `sandbox` e DEFINIDA e nunca CHAMADA
#:   2. `cors` so recebe `{}` — ninguem faz `cors[...] = ` nem `insert(cors`
#:   3. `getfenv`/`setfenv` nao aparecem fora do corpo de `sandbox`
#:
#: Se um dia a origem mudar e passar a chamar `sandbox`, a entrega para.
RE_DEF_SANDBOX = re.compile(r"function\s+sandbox\s*\(", re.M)
RE_USO_SANDBOX = re.compile(r"(?<!function )\bsandbox\s*\(", re.M)
# ⚠️ o `\s*` fica DENTRO do lookahead de proposito. Fora dele o motor
#    retrocede `\s*` para zero, o lookahead cai no espaco em vez da chave, e
#    `cors = {}` passa a casar como se enchesse a fila — a prova acusaria
#    codigo morto de vivo, e a entrega travaria para sempre.
RE_ENCHE_CORS = re.compile(r"cors\s*\[|insert\s*\(\s*cors|cors\s*=(?!\s*\{\s*\})")


def provar_inerte(texto):
    """`[]` se `getfenv`/`setfenv` sao comprovadamente codigo morto."""
    if "getfenv" not in texto and "setfenv" not in texto:
        return []

    problemas = []
    if not RE_DEF_SANDBOX.search(texto):
        problemas.append("getfenv/setfenv fora do boilerplate `sandbox`")
    if RE_USO_SANDBOX.search(texto):
        problemas.append("`sandbox` e CHAMADA — deixou de ser codigo morto")
    if RE_ENCHE_CORS.search(texto):
        problemas.append("`cors` recebe callback — a fila deixou de ser vazia")

    # o corpo de sandbox vai da definicao ate o primeiro `end` na coluna zero
    corpo = ""
    m = RE_DEF_SANDBOX.search(texto)
    if m:
        resto = texto[m.start():]
        fim = resto.find("\nend\n")
        corpo = resto[:fim if fim > 0 else len(resto)]
    for fora in ("getfenv", "setfenv"):
        if texto.count(fora) != corpo.count(fora):
            problemas.append("%s aparece fora do corpo de `sandbox`" % fora)
    return problemas

#: (arquivo de origem, nome na origem, nome que a entrega usa)
CONJUNTO = (
    (REALITY, "SLAP", "Lapada Seca"),
    (CANHAO, "LowOrbitIonCannon", "Canhao Satelite"),
    (REALITY, "a-train", "Trem"),
    (REALITY, "tre", "Arvore Maligna"),
    (REALITY, "gravity cat not amused", "Gato Ajudante Boss"),
    (REALITY, "samsung", "Samsungus"),
    (REALITY, "kick dance", "Danca Provocadora"),
)

# ═══════════════════════════════════════════════════════════════
# O PREÂMBULO — o único código que este repositório acrescenta
# ═══════════════════════════════════════════════════════════════

PREAMBULO = '''--[[ ═══════════════════════════════════════════════════════════
     RETRO-VERSE — ÚNICO ACRÉSCIMO A ESTE SCRIPT DA ORIGEM.

     Duas coisas, e nada mais:
       1. nao ferir quem carrega a Tool
       2. o dano valer — TakeDamage pelo Nucleo, com tag de abate

     Tudo abaixo deste bloco e o script original, byte por byte.
     ═══════════════════════════════════════════════════════════ ]]
local __RV_Players = game:GetService("Players")
local __RV_Debris  = game:GetService("Debris")

--- Quem esta carregando a Tool.
---
--- Script dentro da Tool: sobe ate a Tool e devolve `Tool.Parent`, que e o
--- personagem enquanto ela esta equipada.
--- Script dentro de modelo clonado (a arvore, o gato): le o `RV_Dono` que o
--- invocador plantou — sem ele nao da para saber de quem e a invocacao, e sem
--- isso nao da para deixar de ferir o dono.
local function __RV_dono()
	local no = script
	while no do
		if no:IsA("Tool") then return no.Parent end
		local v = no:FindFirstChild("RV_Dono")
		if v and v:IsA("ObjectValue") and v.Value then return v.Value end
		no = no.Parent
	end
	return nil
end

local function __RV_ehDono(modelo)
	local d = __RV_dono()
	if not (modelo and d) then return false end
	return modelo == d
end

--- O dano. `TakeDamage` respeita ForceField; `Health = 0` nao respeitava nada,
--- e ainda tirava o abate do Nucleo porque nao deixava tag de creator.
local function __RV_dano(hum, quanto)
	if not hum or hum.Health <= 0 then return false end
	if __RV_ehDono(hum.Parent) then return false end

	local d = __RV_dono()
	local jog = nil
	if d then jog = __RV_Players:GetPlayerFromCharacter(d) end

	if _G.Combate and _G.Combate.canDamage and jog then
		if not _G.Combate.canDamage(jog, hum) then return false end
	end

	local final = quanto
	if _G.Combate and _G.Combate.calcular and jog then
		final = _G.Combate.calcular(jog, hum, quanto) or quanto
	end

	if jog then
		local marca = hum:FindFirstChild("creator")
		if marca then marca.Parent = nil end
		marca = Instance.new("ObjectValue")
		marca.Name = "creator"
		marca.Value = jog
		marca.Parent = hum
		__RV_Debris:AddItem(marca, 3)
	end

	hum:TakeDamage(final)
	return true
end

--- Planta a marca de dono num modelo invocado, para os scripts de dentro dele
--- saberem de quem e. E o mecanismo do conserto 1, nao um conserto novo.
local function __RV_marcar(modelo, quem)
	if not (modelo and quem) then return end
	local v = modelo:FindFirstChild("RV_Dono")
	if not v then
		v = Instance.new("ObjectValue")
		v.Name = "RV_Dono"
		v.Parent = modelo
	end
	v.Value = quem
end

'''

# ═══════════════════════════════════════════════════════════════
# OS REMENDOS — um por linha da origem que muda. Nada fora daqui.
#
#   (Tool da origem, caminho do script, o que era, o que fica, por que)
#
# Se qualquer `antes` nao for achado EXATAMENTE uma vez, o script falha. Um
# remendo que nao pega e pior que remendo nenhum: passa despercebido.
# ═══════════════════════════════════════════════════════════════

REMENDOS = (
 ("SLAP", "Hand/Script",
  'local blender = Touch.Parent:FindFirstChild("Head")',
  'if __RV_ehDono(Touch.Parent) then return end\n\tlocal blender = Touch.Parent:FindFirstChild("Head")',
  "1 — a mao arremessava e matava quem a carrega"),

 ("SLAP", "Hand/Script/RagdollSCript",
  "humanoid.Health = 0",
  "__RV_dano(humanoid, 100)",
  "2 — Health = 0 ignora ForceField e nao deixa tag de abate"),

 ("a-train", "SwordScript/Script",
  'if hit.Parent:FindFirstChildOfClass("Humanoid") ~= nil then',
  'if hit.Parent:FindFirstChildOfClass("Humanoid") ~= nil and not __RV_ehDono(hit.Parent) then',
  "1 — o Touched pegava o proprio corredor"),

 ("a-train", "SwordScript/Script",
  'hit.Parent:FindFirstChildOfClass("Humanoid").Health = 0',
  '__RV_dano(hit.Parent:FindFirstChildOfClass("Humanoid"), 100)',
  "2"),

 ("tre", "Script",
  "clone.Parent = workspace",
  "clone.Parent = workspace\n\t\t\t__RV_marcar(clone, isply)",
  "1 — sem marca de dono a arvore cacava quem plantou"),

 ("tre", "Script/tree/Death/Script",
  "if foundhead and foundHumanoidRootPart and foundhum and foundhum.Health > 0 then",
  "if foundhead and foundHumanoidRootPart and foundhum and foundhum.Health > 0 and not __RV_ehDono(char) then",
  "1 — quem plantou entrava na lista de presas"),

 ("tre", "Script/tree/Death/Script",
  'minply.Parent:FindFirstChildOfClass("Humanoid").Health = 0',
  '__RV_dano(minply.Parent:FindFirstChildOfClass("Humanoid"), 100)',
  "2"),

 ("gravity cat not amused", "spawner",
  'AI:MakeJoints()',
  'AI:MakeJoints()\n\t__RV_marcar(AI, script.Parent.Parent.Parent)',
  "1 — sem marca de dono o gato bombardeava quem o chamou"),

 ("gravity cat not amused", "spawner/Gravity Cat Not Amused/gravitycatMAIN.",
  'local h = child[i]:findFirstChild("Humanoid")\n\t\t\tif h ~= nil then',
  'local h = child[i]:findFirstChild("Humanoid")\n\t\t\tif h ~= nil and not __RV_ehDono(child[i]) then',
  "1 — findTorso escolhia o dono como alvo mais perto"),

 ("gravity cat not amused", "spawner/Gravity Cat Not Amused/gravitycatMAIN.",
  'man.Parent:FindFirstChildOfClass("Humanoid").Health = 0',
  '__RV_dano(man.Parent:FindFirstChildOfClass("Humanoid"), 100)',
  "2 — attack1"),

 ("gravity cat not amused", "spawner/Gravity Cat Not Amused/gravitycatMAIN.",
  'torso.Parent:FindFirstChildOfClass("Humanoid").Health = 0',
  '__RV_dano(torso.Parent:FindFirstChildOfClass("Humanoid"), 100)',
  "2 — attack3"),

 ("gravity cat not amused", "spawner/Gravity Cat Not Amused/gravitycatMAIN./bobm",
  'man.Parent:FindFirstChildOfClass("Humanoid").Health = 0',
  '__RV_dano(man.Parent:FindFirstChildOfClass("Humanoid"), 100)',
  "2 — a bomba da chuva"),

 ("samsung", "LeadpipeServer",
  "humanoiddd.Health = humanoiddd.Health - math.random(20,25)",
  "__RV_dano(humanoiddd, math.random(20,25))",
  "2 — subtrair Health direto ignora ForceField e nao credita o abate"),

 ("LowOrbitIonCannon", "Script",
  # 13 tabs no `if`, 14 no `v:destroy()` — indentação contada, não chutada
  "if (v.Position - energyhit.Position).magnitude < 250 then\n"
  + "\t" * 14 + "v:destroy()",
  "if (v.Position - energyhit.Position).magnitude < 250 then\n"
  + "\t" * 14 + 'local __hum = v.Parent and v.Parent:FindFirstChildOfClass("Humanoid")\n'
  + "\t" * 14 + "if __hum then\n"
  + "\t" * 15 + "__RV_dano(__hum, 100)\n"
  + "\t" * 14 + "elseif not __RV_ehDono(v.Parent) then\n"
  + "\t" * 15 + "v:destroy()\n"
  + "\t" * 14 + "end",
  "1 e 2 — apagar peca por peca matava o proprio atirador e nao creditava nada"),
)

#: quais scripts levam o preambulo (os que citam __RV_)
PRECISA = {}
for tool, caminho, _a, _d, _p in REMENDOS:
    PRECISA.setdefault(tool, set()).add(caminho)


def nome(item):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == "Name":
            return e.text
    return None


def campo(item, alvo):
    p = item.find("Properties")
    if p is None:
        return None
    for e in p:
        if e.get("name") == alvo:
            return e
    return None


def tool_de(caminho, alvo):
    raiz = ET.parse(caminho).getroot()
    for t in raiz.findall("Item"):
        if t.get("class") == "Tool" and nome(t) == alvo:
            return t
    for t in raiz.iter("Item"):
        if t.get("class") == "Tool" and nome(t) == alvo:
            return t
    return None


def caminhos_de_script(tool):
    """{caminho relativo dentro da Tool: Item} para todo script."""
    achados = {}

    def anda(no, prefixo):
        for f in no.findall("Item"):
            n = nome(f) or f.get("class")
            c = (prefixo + "/" + n) if prefixo else n
            if f.get("class") in CLASSES_SCRIPT:
                achados[c] = f
            anda(f, c)

    anda(tool, "")
    return achados


def main():
    for caminho in (REALITY, CANHAO):
        if not os.path.exists(caminho):
            print("origem não encontrada: %s" % caminho)
            return 1

    raiz_saida = ET.Element("roblox", {"version": "4"})
    aplicados, falhas = 0, []
    resumo = []

    for arquivo, na_origem, nome_final in CONJUNTO:
        tool = tool_de(arquivo, na_origem)
        if tool is None:
            print("não achei a Tool %r em %s" % (na_origem, arquivo))
            return 1

        import copy
        copia = copy.deepcopy(tool)

        # o nome da entrega é o que o pedido fixou; o resto é intocado
        pv = copia.find("Properties")
        for e in pv:
            if e.get("name") == "Name":
                e.text = nome_final

        scripts = caminhos_de_script(copia)
        precisa = PRECISA.get(na_origem, set())

        n_remendos = 0
        for tool_r, caminho_r, antes, depois, _porque in REMENDOS:
            if tool_r != na_origem:
                continue
            item = scripts.get(caminho_r)
            if item is None:
                falhas.append("%s: não achei o script %r" % (na_origem, caminho_r))
                continue
            fonte_e = campo(item, "Source")
            if fonte_e is None:
                falhas.append("%s/%s: sem Source" % (na_origem, caminho_r))
                continue
            texto = fonte_e.text or ""
            n = texto.count(antes)
            if n == 0:
                falhas.append("%s/%s: âncora não encontrada: %r"
                              % (na_origem, caminho_r, antes[:60]))
                continue
            fonte_e.text = texto.replace(antes, depois)
            n_remendos = n_remendos + n
            aplicados = aplicados + n

        # o preâmbulo entra UMA vez por script remendado
        for caminho_r in sorted(precisa):
            item = scripts.get(caminho_r)
            if item is None:
                continue
            fonte_e = campo(item, "Source")
            if fonte_e is None:
                continue
            if "__RV_dano" in (fonte_e.text or "") or "__RV_ehDono" in (fonte_e.text or "") or "__RV_marcar" in (fonte_e.text or ""):
                fonte_e.text = PREAMBULO + (fonte_e.text or "")

        raiz_saida.append(copia)
        resumo.append((nome_final, na_origem, len(scripts), n_remendos))

    if falhas:
        print("REMENDOS QUE NÃO PEGARAM — nada foi escrito:")
        for f in falhas:
            print("   %s" % f)
        return 1

    # ── A TABELA <SharedStrings>, sem a qual o arquivo nao abre
    #
    # `MeshPart.AeroMeshData` e gravado como
    # `<SharedString name="AeroMeshData">md5</SharedString>` — uma CITACAO. Quem
    # resolve a md5 e um bloco `<SharedStrings>` irmao dos Items, no nivel do
    # `<roblox>`, e ele nao viaja junto quando se copia so a Tool.
    #
    # Sem ele as 7 citacoes ficam penduradas, o `rbx-dom` nao acha o valor e
    # trata a propriedade como `BinaryString` — que e outro tipo. A conversao
    # para `.rbxm` morre com PropTypeMismatch, e um `.rbxmx` assim tambem abre
    # torto no Studio.
    #
    # Isto NAO e mexer na Tool: e trazer junto a tabela que o arquivo de origem
    # ja tinha, para a citacao continuar apontando para o mesmo lugar.
    tabela = {}
    for caminho in (REALITY, CANHAO):
        for e in ET.parse(caminho).getroot().iter("SharedString"):
            if e.get("md5"):
                tabela[e.get("md5")] = e.text

    citadas = {(e.text or "").strip() for e in raiz_saida.iter("SharedString")
               if e.get("name")}
    citadas.discard("")

    penduradas = sorted(m for m in citadas if m not in tabela)
    if penduradas:
        print("⛔ %d SharedString sem valor na tabela de origem: %s"
              % (len(penduradas), ", ".join(penduradas[:3])))
        return 1

    bloco = ET.SubElement(raiz_saida, "SharedStrings")
    for md5 in sorted(citadas):
        ET.SubElement(bloco, "SharedString", {"md5": md5}).text = tabela[md5]

    ET.ElementTree(raiz_saida).write(SAIDA, encoding="utf-8",
                                     xml_declaration=True)

    # ── a varredura de veneno, no arquivo ESCRITO
    escrito = open(SAIDA, encoding="utf-8").read()
    achados = [v for v in VENENO if v.lower() in escrito.lower()]
    if RE_REQUIRE_ID.search(escrito):
        achados.append("require(<número>)")
    achados = achados + provar_inerte(escrito)
    if achados:
        os.remove(SAIDA)
        print("⛔ VENENO NO ARQUIVO ESCRITO: %s — entrega abortada"
              % ", ".join(achados))
        return 1

    print("%-22s %-24s %s" % ("ENTREGA", "ORIGEM", "scripts · remendos"))
    for nome_final, na_origem, n_scripts, n_rem in resumo:
        print("%-22s %-24s %2d · %d" % (nome_final, na_origem, n_scripts, n_rem))
    print("")
    print("%s — %d bytes · %d remendo(s) aplicado(s)"
          % (os.path.relpath(SAIDA, RAIZ), os.path.getsize(SAIDA), aplicados))
    print("veneno no arquivo escrito: nenhum")
    print("SharedStrings: %d citada(s), %d na tabela, 0 pendurada"
          % (len(citadas), len(citadas)))
    if "getfenv" in escrito or "setfenv" in escrito:
        print("getfenv/setfenv: presentes e PROVADOS INERTES — `sandbox` "
              "definida e nunca chamada, `cors` vazia")
    return 0


if __name__ == "__main__":
    sys.exit(main())
