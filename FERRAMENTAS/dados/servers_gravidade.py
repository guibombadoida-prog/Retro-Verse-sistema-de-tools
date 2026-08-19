"""
servers_gravidade.py — as 28 habilidades do conjunto GRAVIDADE.

Sete Tools, QUATRO habilidades cada: a que a Tool já tinha no clique, a Extra
que ela já tinha (agora em `R`), e duas novas em `T` e `Y`. Lido por
`FERRAMENTAS/gerar_servers_gravidade_v2.py`.

════════════════════════════════════════════════════════════════════════
A M1 E A EXTRA ANTIGA ENTRAM INTACTAS
════════════════════════════════════════════════════════════════════════

    O corpo das catorze habilidades que já existiam é o mesmo, byte a byte —
    só o nome de `extra` virou `extraR`, porque agora são três. Reescrever
    habilidade que já estava conformada e verificada é convite a introduzir um
    erro num lugar que não tinha nenhum.

    O que é novo são as catorze Extras de `T` e `Y`.

════════════════════════════════════════════════════════════════════════
A REGRA QUE MANDA AQUI: NINGUÉM TOCA EM `workspace.Gravity`
════════════════════════════════════════════════════════════════════════

    Vale para as 28. O `Campo Leve` do `Controlador` e o `Planar` das `Asas`
    são os dois lugares onde a tentação voltaria — os dois são "gravidade
    baixa" —, e nenhum dos dois encosta na propriedade global. Os dois são
    empurrão fraco e repetido, por alvo, com prazo no `Debris`.

════════════════════════════════════════════════════════════════════════
OS NOVE SONS QUE ESTAVAM MUDOS
════════════════════════════════════════════════════════════════════════

    `EquipSound` (Levitacao e Asas), `Press` (Controlador), e os seis do
    `Lancador` — `ClawsOpen`, `Drop`, `DryFire`, `Launch4`, `Pickup` e `sfx`.

    Eram som da ORIGEM viajando dentro da Tool sem ninguém tocá-los. O
    `verificar_rbxmx` avisava em quatro Tools; as Extras novas lhes deram
    papel, e o aviso sai.
"""

CONJUNTO = {}


def T(alvo, **kw):
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    CONJUNTO[alvo] = kw


# ═══════════════════════════════════════════════════════════════
T('Tremores da Gravidade',
  objeto='TremoresdaGravidade_Server_V1', sufixo='GravTremores',
  arquetipo='GRAVIDADE', alcance_mira=60,
  rotulo_m1='onda de tremor que corre pelo chão', rotulo_r='Sustentar',
  rotulo_t='Falha', rotulo_y='Replica',
  origem=['M1 e R vêm do conjunto GRAVIDADE anterior, sem uma linha mudada.', 'T e Y são novas, e usam os Sound da origem que estavam mudos.'],
  cfg="""	ALCANCE       = 8,
	RAIO_ONDA     = 22,
	DANO          = 18,
	EMPURRAO      = 42,
	SUBIDA        = 14,
	RECARGA       = 4,

	RECARGA_R     = 14,
	PULSOS        = 3,
	RAIO_PULSO    = 16,
	DANO_PULSO    = 11,
	TOMBO         = 1.4,
	RECARGA_T      = 11,
	ALCANCE_FALHA  = 46,
	PASSOS_FALHA   = 8,
	ESPACO_FALHA   = 5.5,
	INTERVALO_FALHA = 0.06,
	RAIO_FALHA     = 6,
	DANO_FALHA     = 15,
	LENTIDAO_FALHA = 0.55,

	RECARGA_Y      = 20,
	RAIO_REPLICA   = 9,
	LARGURA_REPLICA = 7,
	DANO_REPLICA   = 16,
	TOMBO_REPLICA  = 1.2,""",
  estado='local anelDaVez = 0',
  corpo='\n--═══════════════════════════════════════════════════════════════\n-- PRIMÁRIA — a onda\n--\n-- O `Quake Hammer` original varria `workspace:GetDescendants()` para achar\n-- alvo. Aqui é consulta espacial num raio, e quem filtra time é o Núcleo.\n--═══════════════════════════════════════════════════════════════\n\nfunction primaria(_mira)\n\tocupado = true\n\ttocar("Swing", 1 + jitter(0.4) * 0.08)\n\trig:PlaySequence("TREMOR", function(passo)\n\t\tlocal marca = marcaDe(passo)\n\t\tif marca ~= "BATE" then return end\n\t\tlocal chao = raiz.Position - Vector3.new(0, 2.6, 0)\n\t\tvfx("ONDA", { posicao = chao, escala = 1.2 })\n\t\ttocarEm("Hit", chao, 0.9 + jitter(1.1) * 0.08)\n\n\t\tfor _, alvo in ipairs(alvosEm(chao, CFG.RAIO_ONDA, 12)) do\n\t\t\taplicarDano(alvo, CFG.DANO)\n\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\tif alvoRaiz then\n\t\t\t\tempurrar(alvo, (alvoRaiz.Position - chao)\n\t\t\t\t\t+ Vector3.new(0, CFG.SUBIDA / CFG.EMPURRAO, 0),\n\t\t\t\t\tCFG.EMPURRAO, 0.24)\n\t\t\tend\n\t\tend\n\tend, function()\n\t\tocupado = false\n\tend)\nend\n\n--═══════════════════════════════════════════════════════════════\n-- EXTRA — o tremor sustentado\n--\n-- Três pulsos, um por beat do animator. Quem encadeia é o animator, não\n-- `task.wait(passo.duracao)` — é a regra que existe porque o oposto já\n-- dessincronizou animação e dano neste repositório.\n--═══════════════════════════════════════════════════════════════\n\nfunction extraR(_mira)\n\tocupado = true\n\trig:PlaySequence("SUSTENTO", despachar({\n\t\tABRE = { faz = function()\n\t\t\ttocar("Press", 0.8)\n\t\tend },\n\t\tPULSO = { faz = function()\n\t\t\tlocal chao = raiz.Position - Vector3.new(0, 2.6, 0)\n\t\t\tvfx("PULSO", { posicao = chao, escala = 1 })\n\t\t\ttocarEm("Hit", chao, 1.15 + jitter(0.6) * 0.1)\n\t\t\tfor _, alvo in ipairs(alvosEm(chao, CFG.RAIO_PULSO, 12)) do\n\t\t\t\taplicarDano(alvo, CFG.DANO_PULSO)\n\t\t\t\ttombar(alvo, CFG.TOMBO)\n\t\t\tend\n\t\tend },\n\t}), function()\n\t\tocupado = false\n\tend)\nend\n\n--- T — a FALHA: uma linha de fendas que corre à frente e afrouxa quem pisa.\n--- Ela não empurra: quem quer empurrão usa a M1. Esta prende no chão.\nfunction extraT(mira)\n\tocupado = true\n\tlocal destino = mira\n\trig:PlaySequence("FALHA", despachar({\n\t\tABRE  = { sfx = { "Swing", 1.05 } },\n\t\tCORTE = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal origem = raiz.Position - Vector3.new(0, 2.6, 0)\n\t\t\tlocal ponto = destino or frente(CFG.ALCANCE_FALHA)\n\t\t\tlocal delta = Vector3.new(ponto.X - origem.X, 0, ponto.Z - origem.Z)\n\t\t\tlocal dir = (delta.Magnitude > 0.5) and delta.Unit\n\t\t\t\tor raiz.CFrame.LookVector\n\t\t\tlocal i = 1\n\t\t\twhile i <= CFG.PASSOS_FALHA do\n\t\t\t\tlocal indice = i\n\t\t\t\ttask.delay(indice * CFG.INTERVALO_FALHA, function()\n\t\t\t\t\tif not personagem then return end\n\t\t\t\t\tlocal onde = origem + dir * (indice * CFG.ESPACO_FALHA)\n\t\t\t\t\tvfx("RACHADURA", { posicao = onde, escala = 1 })\n\t\t\t\t\tif indice % 3 == 1 then\n\t\t\t\t\t\ttocarEm("Hit", onde, 1.2)\n\t\t\t\t\tend\n\t\t\t\t\tfor _, alvo in ipairs(alvosEm(onde, CFG.RAIO_FALHA, 8)) do\n\t\t\t\t\t\taplicarDano(alvo, CFG.DANO_FALHA)\n\t\t\t\t\t\tafrouxar(alvo, CFG.LENTIDAO_FALHA, 2)\n\t\t\t\t\tend\n\t\t\t\tend)\n\t\t\t\ti = i + 1\n\t\t\tend\n\t\tend },\n\t}), function() ocupado = false end)\nend\n\n--- Y — a RÉPLICA: três anéis, do menor para o maior, um por beat.\n---\n--- Só o anel DA VEZ machuca. Sem o recorte pela largura, o terceiro anel\n--- pegaria de novo quem o primeiro já pegou, e a habilidade seria três vezes\n--- o mesmo dano em quem estivesse colado.\nfunction extraY(_mira)\n\tocupado = true\n\tanelDaVez = 0\n\trig:PlaySequence("REPLICA", despachar({\n\t\tABRE = { sfx = { "Press", 0.85 } },\n\t\tANEL = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tanelDaVez = anelDaVez + 1\n\t\t\tlocal chao = raiz.Position - Vector3.new(0, 2.6, 0)\n\t\t\tlocal raio = CFG.RAIO_REPLICA * anelDaVez\n\t\t\tvfx("ONDA", { posicao = chao, escala = 0.7 * anelDaVez })\n\t\t\ttocarEm("Hit", chao, 1.3 - anelDaVez * 0.12)\n\t\t\tfor _, alvo in ipairs(alvosEm(chao, raio, 14)) do\n\t\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\t\tlocal d = alvoRaiz and (alvoRaiz.Position - chao).Magnitude\n\t\t\t\t\tor raio\n\t\t\t\tif d > raio - CFG.LARGURA_REPLICA then\n\t\t\t\t\taplicarDano(alvo, CFG.DANO_REPLICA)\n\t\t\t\t\ttombar(alvo, CFG.TOMBO_REPLICA)\n\t\t\t\tend\n\t\t\tend\n\t\tend },\n\t}), function() ocupado = false end)\nend\n')

# ═══════════════════════════════════════════════════════════════
T('Controlador da Gravidade',
  objeto='ControladordaGravidade_Server_V1', sufixo='GravControlador',
  arquetipo='GRAVIDADE', alcance_mira=90,
  rotulo_m1='campo de gravidade invertida no ponto mirado', rotulo_r='Esmagar',
  rotulo_t='Campo Leve', rotulo_y='Pulso Radial',
  origem=['M1 e R vêm do conjunto GRAVIDADE anterior, sem uma linha mudada.', 'T e Y são novas, e usam os Sound da origem que estavam mudos.'],
  cfg="""	ALCANCE       = 8,
	RAIO_CAMPO    = 16,
	ALTURA_CAMPO  = 22,
	DURACAO_CAMPO = 3.5,
	DANO_CAMPO    = 8,
	RECARGA       = 9,

	RECARGA_R     = 13,
	RAIO_ESMAGA   = 18,
	DANO_ESMAGA   = 38,
	FORCA_ESMAGA  = 140,
	RECARGA_T      = 16,
	RAIO_LEVE      = 20,
	DURACAO_LEVE   = 6,
	PASSO_LEVE     = 0.6,
	SUBIDA_LEVE    = 2.4,
	LENTIDAO_LEVE  = 1.35,

	RECARGA_Y      = 14,
	RAIO_PULSO_R   = 22,
	NUCLEO_PULSO   = 8,
	DANO_PULSO_R   = 26,
	BORDA_PULSO_R  = 13,
	FORCA_PULSO_R  = 120,
	TOMBO_PULSO    = 1.5,""",
  estado='local campoId = nil',
  corpo='\n--═══════════════════════════════════════════════════════════════\n-- PRIMÁRIA — gravidade invertida no ponto\n--\n-- ⚠️ O ORIGINAL FAZIA `game.Workspace.Gravity = 21.2` E NÃO DEVOLVIA.\n--\n-- Aqui ninguém toca em `workspace.Gravity`. Cada alvo dentro do campo ganha um\n-- `BodyPosition` próprio mirando acima de si, com prazo no `Debris` — e o\n-- `Debris` limpa mesmo se este script morrer no meio. Não existe estado global\n-- para vazar.\n--═══════════════════════════════════════════════════════════════\n\nfunction primaria(mira)\n\tocupado = true\n\trig:PlaySequence("INVERTE", function(passo)\n\t\tlocal marca = marcaDe(passo)\n\t\tif marca ~= "SOLTA" then return end\n\t\tlocal id = novoId("CAMPO")\n\t\ttocarEm("Shift", mira, 1.1)\n\t\tvfx("CAMPO_INVERSO", { posicao = mira, escala = 1.2,\n\t\t\traio = CFG.RAIO_CAMPO, duracao = CFG.DURACAO_CAMPO, id = id })\n\n\t\tfor _, alvo in ipairs(alvosEm(mira, CFG.RAIO_CAMPO, 12)) do\n\t\t\taplicarDano(alvo, CFG.DANO_CAMPO)\n\t\t\tsuspender(alvo, CFG.ALTURA_CAMPO, CFG.DURACAO_CAMPO, 9000)\n\t\tend\n\n\t\ttask.delay(CFG.DURACAO_CAMPO, function()\n\t\t\tvfx("APAGAR", { id = id })\n\t\tend)\n\tend, function()\n\t\tocupado = false\n\tend)\nend\n\n--═══════════════════════════════════════════════════════════════\n-- EXTRA — esmagar\n--\n-- O oposto visual e mecânico da primária: mesma bolha, força para baixo. É o\n-- que faz as duas lerem como a mesma Tool.\n--═══════════════════════════════════════════════════════════════\n\nfunction extraR(mira)\n\tocupado = true\n\trig:PlaySequence("ESMAGAR", despachar({\n\t\tERGUE = { faz = function()\n\t\t\ttocar("Shift", 0.7)\n\t\tend },\n\t\tESMAGA = { faz = function()\n\t\t\tvfx("ESMAGA", { posicao = mira, escala = 1.3 })\n\t\t\ttocarEm("Beep", mira, 0.72)\n\t\t\tfor _, alvo in ipairs(alvosEm(mira, CFG.RAIO_ESMAGA, 12)) do\n\t\t\t\taplicarDano(alvo, CFG.DANO_ESMAGA)\n\t\t\t\tempurrar(alvo, Vector3.new(0, -1, 0), CFG.FORCA_ESMAGA, 0.3)\n\t\t\t\ttombar(alvo, 1.6)\n\t\t\tend\n\t\tend },\n\t}), function()\n\t\tocupado = false\n\tend)\nend\n\n--- T — CAMPO LEVE: gravidade baixa numa área, por prazo.\n---\n--- ⚠️ E de novo: NÃO é `workspace.Gravity`. É um empurrão para cima, fraco e\n--- repetido, num `BodyVelocity` com prazo por alvo — mais `WalkSpeed` maior,\n--- que é o que faz "gravidade baixa" LER como gravidade baixa. O global fica\n--- onde está.\nfunction extraT(mira)\n\tocupado = true\n\tlocal destino = mira\n\trig:PlaySequence("CAMPO_LEVE", despachar({\n\t\tABRE   = { sfx = { "Shift", 1.1 } },\n\t\tSEGURA = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal centro = destino or frente(CFG.RAIO_LEVE)\n\t\t\tapagarEfeito(campoId)\n\t\t\tcampoId = novoId("CAMPO_LEVE")\n\t\t\tlocal meu = campoId\n\t\t\tvfx("CAMPO_INVERSO", { posicao = centro, raio = CFG.RAIO_LEVE,\n\t\t\t\tduracao = CFG.DURACAO_LEVE, id = meu })\n\t\t\ttocarEm("Beep", centro, 1.2)\n\n\t\t\ttask.spawn(function()\n\t\t\t\tlocal ate = os.clock() + CFG.DURACAO_LEVE\n\t\t\t\twhile campoId == meu and os.clock() < ate do\n\t\t\t\t\tif not personagem then break end\n\t\t\t\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO_LEVE, 14)) do\n\t\t\t\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\t\t\t\tif alvoRaiz then\n\t\t\t\t\t\t\tempurrar(alvo, Vector3.new(0, 1, 0),\n\t\t\t\t\t\t\t\tCFG.SUBIDA_LEVE, CFG.PASSO_LEVE)\n\t\t\t\t\t\tend\n\t\t\t\t\t\t-- `afrouxar` com fator > 1 ACELERA, e devolve o que\n\t\t\t\t\t\t-- havia: é a leveza, não a lentidão.\n\t\t\t\t\t\tafrouxar(alvo, CFG.LENTIDAO_LEVE, CFG.PASSO_LEVE * 1.6)\n\t\t\t\t\tend\n\t\t\t\t\ttask.wait(CFG.PASSO_LEVE)\n\t\t\t\tend\n\t\t\t\tif campoId == meu then\n\t\t\t\t\tapagarEfeito(meu)\n\t\t\t\t\tcampoId = nil\n\t\t\t\tend\n\t\t\tend)\n\t\tend },\n\t}), function() ocupado = false end)\nend\n\n--- Y — PULSO RADIAL: o contrário do campo. Empurra tudo para FORA.\nfunction extraY(_mira)\n\tocupado = true\n\trig:PlaySequence("PULSO_RADIAL", despachar({\n\t\tERGUE  = { sfx = { "Press", 0.9 } },\n\t\tSEGURA = { sfx = { "Shift", 0.8 } },\n\t\tSOLTA  = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal centro = raiz.Position\n\t\t\tvfx("PULSO", { posicao = centro, escala = 1.6 })\n\t\t\ttocarEm("Beep", centro, 0.85)\n\t\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO_PULSO_R, 16)) do\n\t\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\t\tlocal d = alvoRaiz\n\t\t\t\t\tand (alvoRaiz.Position - centro).Magnitude\n\t\t\t\t\tor CFG.RAIO_PULSO_R\n\t\t\t\tif d <= CFG.NUCLEO_PULSO then\n\t\t\t\t\taplicarDano(alvo, CFG.DANO_PULSO_R)\n\t\t\t\t\ttombar(alvo, CFG.TOMBO_PULSO)\n\t\t\t\telse\n\t\t\t\t\taplicarDano(alvo, CFG.BORDA_PULSO_R)\n\t\t\t\tend\n\t\t\t\tif alvoRaiz then\n\t\t\t\t\tempurrar(alvo, (alvoRaiz.Position - centro)\n\t\t\t\t\t\t+ Vector3.new(0, 0.5, 0), CFG.FORCA_PULSO_R, 0.3)\n\t\t\t\tend\n\t\t\tend\n\t\tend },\n\t}), function() ocupado = false end)\nend\n')

# ═══════════════════════════════════════════════════════════════
T('Telecinese Levitacao',
  objeto='TelecineseLevitacao_Server_V1', sufixo='GravLevitacao',
  arquetipo='TELECINESE', alcance_mira=80,
  rotulo_m1='ergue o alvo mirado e o deixa indefeso', rotulo_r='Levitar',
  rotulo_t='Corrente', rotulo_y='Queda',
  origem=['M1 e R vêm do conjunto GRAVIDADE anterior, sem uma linha mudada.', 'T e Y são novas, e usam os Sound da origem que estavam mudos.'],
  cfg="""	ALCANCE       = 8,
	RAIO_ALVO     = 9,
	ALTURA        = 16,
	DURACAO       = 3,
	DANO          = 14,
	DANO_QUEDA    = 22,
	RECARGA       = 8,

	RECARGA_R     = 10,
	ALTURA_PROPRIA = 26,
	DURACAO_PROPRIA = 4,
	RECARGA_T      = 15,
	ALCANCE_PRENDE = 60,
	RAIO_PRENDE    = 16,
	DURACAO_PRENDE = 4,
	ALTURA_PRENDE  = 3,
	DANO_PRENDE    = 9,
	PASSO_PRENDE   = 0.5,

	RECARGA_Y      = 18,
	RAIO_QUEDA     = 20,
	DANO_QUEDA     = 40,
	FORCA_QUEDA    = 150,
	TOMBO_QUEDA    = 2,""",
  estado='local presoProprio = nil\nlocal presos = {}',
  corpo='\n--═══════════════════════════════════════════════════════════════\n-- PRIMÁRIA — erguer o alvo\n--\n-- Uma vítima por vez, a mais perto do ponto mirado. Levitar a sala inteira é o\n-- que a Extra do `Controlador` faz; esta é cirúrgica, e por isso pesa mais.\n--═══════════════════════════════════════════════════════════════\n\nlocal function maisPerto(ponto, raio)\n\tlocal melhor, dist = nil, math.huge\n\tfor _, alvo in ipairs(alvosEm(ponto, raio, 12)) do\n\t\tlocal alvoRaiz = raizDe(alvo)\n\t\tif alvoRaiz then\n\t\t\tlocal d = (alvoRaiz.Position - ponto).Magnitude\n\t\t\tif d < dist then melhor, dist = alvo, d end\n\t\tend\n\tend\n\treturn melhor\nend\n\nfunction primaria(mira)\n\tocupado = true\n\trig:PlaySequence("ERGUER", despachar({\n\t\tALCANCA = { faz = function()\n\t\t\ttocar("ScifiLiftSound", 1)\n\t\t\tvfx("AGARRA", { origem = Handle.Position, destino = mira })\n\t\tend },\n\t\tERGUE = { faz = function()\n\t\t\tlocal alvo = maisPerto(mira, CFG.RAIO_ALVO)\n\t\t\tif not alvo then return end\n\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\tif not alvoRaiz then return end\n\t\t\tlocal id = novoId("LEVITA")\n\t\t\taplicarDano(alvo, CFG.DANO)\n\t\t\tsuspender(alvo, CFG.ALTURA, CFG.DURACAO, 14000)\n\t\t\ttombar(alvo, CFG.DURACAO + 0.6)\n\t\t\tvfx("LEVITA", { posicao = alvoRaiz.Position + Vector3.new(0, CFG.ALTURA, 0),\n\t\t\t\tescala = 1, duracao = CFG.DURACAO, id = id })\n\t\t\t-- a queda cobra o resto: quem foi erguido volta com o chão\n\t\t\ttask.delay(CFG.DURACAO, function()\n\t\t\t\tvfx("APAGAR", { id = id })\n\t\t\t\tif alvo and alvo.Parent and alvo.Health > 0 then\n\t\t\t\t\taplicarDano(alvo, CFG.DANO_QUEDA)\n\t\t\t\t\tlocal ondeCaiu = raizDe(alvo)\n\t\t\t\t\tif ondeCaiu then\n\t\t\t\t\t\tvfx("ONDA", { posicao = ondeCaiu.Position\n\t\t\t\t\t\t\t- Vector3.new(0, 2.6, 0), escala = 0.8 })\n\t\t\t\t\tend\n\t\t\t\tend\n\t\t\tend)\n\t\tend },\n\t\tSOLTA = { faz = function()\n\t\t\ttocar("ScifiBlastSound", 1.1)\n\t\tend },\n\t}), function()\n\t\tocupado = false\n\tend)\nend\n\n--═══════════════════════════════════════════════════════════════\n-- EXTRA — levitar a si mesmo\n--\n-- O `BodyPosition` do próprio portador é o único estado desta Tool que\n-- sobreviveria a um desequipar no meio. Por isso ele fica guardado e\n-- `desmontar()` o desfaz — nas duas portas.\n--═══════════════════════════════════════════════════════════════\n\nfunction extraR(_mira)\n\tocupado = true\n\trig:PlaySequence("SUBIR", despachar({\n\t\tSOBE = { faz = function()\n\t\t\ttocar("ScifiLiftSound", 1.25)\n\t\t\tif presoProprio then presoProprio.Parent = nil end\n\t\t\tpresoProprio = Instance.new("BodyPosition")\n\t\t\tpresoProprio.MaxForce = Vector3.new(0, 1e5, 0)\n\t\t\tpresoProprio.P = 9000\n\t\t\tpresoProprio.D = 1400\n\t\t\tpresoProprio.Position = raiz.Position\n\t\t\t\t+ Vector3.new(0, CFG.ALTURA_PROPRIA, 0)\n\t\t\tpresoProprio.Parent = raiz\n\t\t\tDebris:AddItem(presoProprio, CFG.DURACAO_PROPRIA)\n\t\t\tvfx("FLUTUA", { posicao = raiz.Position, escala = 1 })\n\t\tend },\n\t\tDESCE = { faz = function()\n\t\t\ttocar("Bam", 0.9)\n\t\tend },\n\t}), function()\n\t\tocupado = false\n\tend)\nend\n\n--- T — CORRENTE: prende no ar quem já está erguido, e segura mais tempo.\n---\n--- `presos` guarda os Humanoids, não posições: quem foi preso fica preso onde\n--- estiver, e a `QUEDA` os derruba de lá. Guardar a posição faria a habilidade\n--- premiar quem não se mexeu.\nfunction extraT(mira)\n\tocupado = true\n\tlocal destino = mira\n\trig:PlaySequence("CORRENTE", despachar({\n\t\tABRE   = { sfx = { "EquipSound", 1.1 } },\n\t\tPRENDE = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal centro = destino or frente(CFG.ALCANCE_PRENDE * 0.5)\n\t\t\tpresos = alvosEm(centro, CFG.RAIO_PRENDE, 12)\n\t\t\tvfx("LEVITA", { posicao = centro, raio = CFG.RAIO_PRENDE,\n\t\t\t\tduracao = CFG.DURACAO_PRENDE })\n\t\t\ttocarEm("ScifiLiftSound", centro, 1)\n\n\t\t\tlocal minha = novaGeracao("T")\n\t\t\tfor _, alvo in ipairs(presos) do\n\t\t\t\tsuspender(alvo, CFG.ALTURA_PRENDE, CFG.DURACAO_PRENDE)\n\t\t\tend\n\t\t\ttask.spawn(function()\n\t\t\t\tlocal ate = os.clock() + CFG.DURACAO_PRENDE\n\t\t\t\twhile geracao.T == minha and os.clock() < ate do\n\t\t\t\t\tif not personagem then break end\n\t\t\t\t\tfor _, alvo in ipairs(presos) do\n\t\t\t\t\t\tif alvo and alvo.Parent and alvo.Health > 0 then\n\t\t\t\t\t\t\taplicarDano(alvo, CFG.DANO_PRENDE)\n\t\t\t\t\t\tend\n\t\t\t\t\tend\n\t\t\t\t\ttask.wait(CFG.PASSO_PRENDE)\n\t\t\t\tend\n\t\t\tend)\n\t\tend },\n\t}), function() ocupado = false end)\nend\n\n--- Y — QUEDA: derruba TUDO que está no ar, com impacto no chão.\n---\n--- Quem foi preso pela `CORRENTE` cai primeiro e leva o dano cheio; quem está\n--- por perto e no chão leva metade. É o par que faz as duas Extras valerem\n--- juntas.\nfunction extraY(_mira)\n\tocupado = true\n\trig:PlaySequence("QUEDA", despachar({\n\t\tERGUE  = { sfx = { "Bam", 0.9 } },\n\t\tSEGURA = { sfx = { "ScifiLiftSound", 0.75 } },\n\t\tLARGA  = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tnovaGeracao("T")\n\t\t\tlocal centro = raiz.Position\n\t\t\tvfx("ESMAGA", { posicao = centro, raio = CFG.RAIO_QUEDA })\n\t\t\ttocarEm("ScifiBlastSound", centro, 0.85)\n\n\t\t\tlocal jaCaiu = {}\n\t\t\tfor _, alvo in ipairs(presos) do\n\t\t\t\tif alvo and alvo.Parent and alvo.Health > 0 then\n\t\t\t\t\tjaCaiu[alvo] = true\n\t\t\t\t\taplicarDano(alvo, CFG.DANO_QUEDA)\n\t\t\t\t\tempurrar(alvo, Vector3.new(0, -1, 0), CFG.FORCA_QUEDA, 0.3)\n\t\t\t\t\ttombar(alvo, CFG.TOMBO_QUEDA)\n\t\t\t\tend\n\t\t\tend\n\t\t\tpresos = {}\n\n\t\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO_QUEDA, 14)) do\n\t\t\t\tif not jaCaiu[alvo] then\n\t\t\t\t\taplicarDano(alvo, CFG.DANO_QUEDA * 0.5)\n\t\t\t\t\tempurrar(alvo, Vector3.new(0, -1, 0),\n\t\t\t\t\t\tCFG.FORCA_QUEDA * 0.6, 0.26)\n\t\t\t\tend\n\t\t\tend\n\t\tend },\n\t}), function() ocupado = false end)\nend\n')

# ═══════════════════════════════════════════════════════════════
T('Lancador de Objetos',
  # os dois sons de origem que sobraram: `equip` e `unequip`. Eles não são de
  # habilidade nenhuma — são da Tool entrando e saindo da mão, que é o papel
  # que a origem lhes dava. Sem isto os dois ficariam depositados e mudos.
  ao_equipar='\ttocar("equip", 1)\n',
  ao_guardar='\ttocar("unequip", 1)\n',
  objeto='LancadordeObjetos_Server_V1', sufixo='GravLancador',
  arquetipo='TELECINESE', alcance_mira=140,
  rotulo_m1='agarra um destroço e arremessa', rotulo_r='Rajada',
  rotulo_t='Prender', rotulo_y='Despejo',
  origem=['M1 e R vêm do conjunto GRAVIDADE anterior, sem uma linha mudada.', 'T e Y são novas, e usam os Sound da origem que estavam mudos.'],
  cfg="""	ALCANCE       = 8,
	DANO          = 26,
	RAIO_IMPACTO  = 7,
	VELOCIDADE    = 190,
	VIDA_DESTROCO = 5,
	TAMANHO       = 2.6,
	RECARGA       = 3,

	RECARGA_R     = 11,
	QUANTOS       = 5,
	DANO_RAJADA   = 15,
	ESPALHAMENTO  = 7,
	RECARGA_T      = 12,
	ALCANCE_GARRA  = 55,
	RAIO_GARRA     = 8,
	DURACAO_GARRA  = 3,
	ALTURA_GARRA   = 4,
	DANO_GARRA     = 14,

	RECARGA_Y      = 22,
	DESTROCOS      = 7,
	INTERVALO_DESP = 0.09,
	ESPALHA_DESP   = 10,
	ALCANCE_DESP   = 55,
	RAIO_DESP      = 8,
	DANO_DESP      = 22,
	FORCA_DESP     = 70,""",
  estado='local agarrado = nil',
  corpo='\n--═══════════════════════════════════════════════════════════════\n-- O DESTROÇO\n--\n-- Peça NOVA, criada pela Tool, e não uma peça do mapa arrancada. O `detainer`\n-- original agarrava geometria do mundo — que é ler o mundo, e pior, deixa\n-- buraco permanente no cenário quando a peça não volta.\n--\n-- Peça NÃO ancorada, movida por física: peça ancorada movida por script de\n-- servidor replica a ~20 Hz picotado; física replica com interpolação.\n--═══════════════════════════════════════════════════════════════\n\nlocal function novoDestroco(posicao, tamanho)\n\tlocal peca = Instance.new("Part")\n\tpeca.Name = "Destroco"\n\tpeca.Size = Vector3.new(tamanho, tamanho * 0.85, tamanho)\n\tpeca.Color = Color3.fromRGB(138, 128, 116)\n\tpeca.Material = Enum.Material.Slate\n\tpeca.CanCollide = true\n\tpeca.CFrame = CFrame.new(posicao)\n\t\t* CFrame.Angles(jitter(0.3) * 3, jitter(1.7) * 3, jitter(2.4) * 3)\n\tpeca.Parent = workspace\n\tpcall(function() peca:SetNetworkOwner(nil) end)\n\tDebris:AddItem(peca, CFG.VIDA_DESTROCO)\n\n\tlocal halo = Instance.new("SelectionBox")\n\thalo.Adornee = peca\n\thalo.Color3 = Color3.fromRGB(168, 118, 255)\n\thalo.LineThickness = 0.04\n\thalo.Transparency = 0.35\n\thalo.Parent = peca\n\treturn peca\nend\n\nlocal function lancar(peca, destino, dano)\n\tlocal origem = peca.Position\n\tlocal direcao = destino - origem\n\tif direcao.Magnitude < 0.01 then direcao = raiz.CFrame.LookVector end\n\tlocal impulso = Instance.new("BodyVelocity")\n\timpulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)\n\timpulso.Velocity = direcao.Unit * CFG.VELOCIDADE\n\timpulso.Parent = peca\n\tDebris:AddItem(impulso, 0.6)\n\n\tlocal bateu = false\n\tguardar(peca.Touched:Connect(function(atingido)\n\t\tif bateu then return end\n\t\tlocal corpo = atingido and atingido.Parent\n\t\tif not corpo or corpo == personagem then return end\n\t\tlocal hum = corpo:FindFirstChildOfClass("Humanoid")\n\t\tif not (hum and hum.Health > 0) then return end\n\t\tbateu = true\n\t\tlocal onde = peca.Position\n\t\tvfx("DESTROCO", { posicao = onde, escala = 1 })\n\t\ttocarEm("Launch1", onde, 1.3)\n\t\tfor _, alvo in ipairs(alvosEm(onde, CFG.RAIO_IMPACTO, 6)) do\n\t\t\taplicarDano(alvo, dano)\n\t\t\tempurrar(alvo, direcao, 45, 0.2)\n\t\tend\n\t\tpeca.Transparency = 1\n\t\tpeca.CanCollide = false\n\t\tpeca.CanTouch = false\n\t\tDebris:AddItem(peca, 0.15)\n\tend))\nend\n\n--═══════════════════════════════════════════════════════════════\n-- PRIMÁRIA — agarra e arremessa\n--═══════════════════════════════════════════════════════════════\n\nfunction primaria(mira)\n\tocupado = true\n\trig:PlaySequence("ARREMESSO", despachar({\n\t\tAGARRA = { faz = function()\n\t\t\ttocar("ClawsClose", 1)\n\t\t\tvfx("AGARRA", { origem = Handle.Position,\n\t\t\t\tdestino = frente(CFG.ALCANCE) })\n\t\tend },\n\t\tSOLTA = { faz = function()\n\t\t\ttocar("Launch2", 1)\n\t\t\tlocal origem = Handle.Position + raiz.CFrame.LookVector * 2.5\n\t\t\t\t+ Vector3.new(0, 1.5, 0)\n\t\t\tlancar(novoDestroco(origem, CFG.TAMANHO), mira, CFG.DANO)\n\t\tend },\n\t}), function()\n\t\tocupado = false\n\tend)\nend\n\n--═══════════════════════════════════════════════════════════════\n-- EXTRA — a rajada\n--\n-- Cinco destroços em ângulo áureo em volta do portador, e todos partem para a\n-- mira. Dispersão por índice sequencial, nunca `math.random`.\n--═══════════════════════════════════════════════════════════════\n\nfunction extraR(mira)\n\tocupado = true\n\trig:PlaySequence("RAJADA", despachar({\n\t\tREUNE = { faz = function()\n\t\t\ttocar("Pull", 0.85)\n\t\t\tvfx("CACOS", { posicao = raiz.Position + Vector3.new(0, 3, 0),\n\t\t\t\tescala = 1.2, quantos = CFG.QUANTOS, duracao = 0.9 })\n\t\tend },\n\t\tSEGURA = { faz = function()\n\t\t\ttocar("Holding", 1)\n\t\tend },\n\t\tSALVA = { faz = function()\n\t\t\tfor i = 1, CFG.QUANTOS do\n\t\t\t\tlocal a = angulo(i)\n\t\t\t\tlocal origem = raiz.Position + Vector3.new(0, 3, 0)\n\t\t\t\t\t+ Vector3.new(math.cos(a) * CFG.ESPALHAMENTO, 0,\n\t\t\t\t\t\tmath.sin(a) * CFG.ESPALHAMENTO)\n\t\t\t\tlancar(novoDestroco(origem, CFG.TAMANHO * 0.75),\n\t\t\t\t\tmira, CFG.DANO_RAJADA)\n\t\t\tend\n\t\t\ttocarEm("Launch3", raiz.Position, 1)\n\t\tend },\n\t}), function()\n\t\tocupado = false\n\tend)\nend\n\n--- T — PRENDER: a garra fecha no ALVO, não no destroço.\n---\n--- É a única do conjunto que segura uma PESSOA no ar por conta própria, e por\n--- isso ela usa `suspender` — `BodyPosition` com prazo. Nunca `Anchored`: com\n--- ele, a Tool sumindo no meio deixaria o jogador preso para sempre.\nfunction extraT(mira)\n\tocupado = true\n\tlocal destino = mira\n\trig:PlaySequence("PRENDER", despachar({\n\t\tABRE = { sfx = { "ClawsOpen", 1 } },\n\t\tPEGA = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal ponto = destino or frente(CFG.ALCANCE_GARRA)\n\t\t\tlocal alvo = maisPerto(ponto, CFG.RAIO_GARRA)\n\t\t\tif not alvo then\n\t\t\t\ttocar("DryFire", 1)\n\t\t\t\tvfx("AGARRA", { posicao = ponto, escala = 0.8 })\n\t\t\t\treturn\n\t\t\tend\n\t\t\tagarrado = alvo\n\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\tlocal onde = alvoRaiz and alvoRaiz.Position or ponto\n\t\t\tvfx("AGARRA", { posicao = onde, escala = 1.2 })\n\t\t\ttocarEm("Holding", onde, 1)\n\t\t\ttocarEm("Pickup", onde, 1.1)\n\t\t\tsuspender(alvo, CFG.ALTURA_GARRA, CFG.DURACAO_GARRA)\n\t\t\taplicarDano(alvo, CFG.DANO_GARRA)\n\t\t\ttask.delay(CFG.DURACAO_GARRA, function()\n\t\t\t\tif agarrado == alvo then agarrado = nil end\n\t\t\tend)\n\t\tend },\n\t}), function() ocupado = false end)\nend\n\n--- Y — DESPEJO: sete destroços de uma vez, em leque, no ponto mirado.\n---\n--- O espalhamento é ângulo áureo, não sorteio: com todos os clientes\n--- desenhando, um `math.random` faria cada um ver uma chuva diferente.\nfunction extraY(mira)\n\tocupado = true\n\tlocal destino = mira\n\trig:PlaySequence("DESPEJO", despachar({\n\t\tERGUE  = { sfx = { "ClawsClose", 0.9 } },\n\t\tSEGURA = { sfx = { "sfx", 0.85 } },\n\t\tSOLTA  = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal origem = raiz.Position + Vector3.new(0, 3, 0)\n\t\t\tlocal ponto = destino or frente(CFG.ALCANCE_DESP)\n\t\t\ttocar("Drop", 0.9)\n\t\t\tlocal i = 1\n\t\t\twhile i <= CFG.DESTROCOS do\n\t\t\t\tlocal indice = i\n\t\t\t\ttask.delay(indice * CFG.INTERVALO_DESP, function()\n\t\t\t\t\tif not personagem then return end\n\t\t\t\t\tlocal ang = angulo(indice)\n\t\t\t\t\tlocal espalha = CFG.ESPALHA_DESP\n\t\t\t\t\t\t* (indice / CFG.DESTROCOS)\n\t\t\t\t\tlocal chegada = ponto + Vector3.new(\n\t\t\t\t\t\tmath.cos(ang) * espalha, 0, math.sin(ang) * espalha)\n\t\t\t\t\tvfx("DESTROCO", { origem = origem, destino = chegada })\n\t\t\t\t\tvfx("CACOS", { posicao = chegada, escala = 1 })\n\t\t\t\t\tif indice % 3 == 1 then\n\t\t\t\t\t\ttocarEm("Launch4", chegada, 1.05)\n\t\t\t\t\tend\n\t\t\t\t\tfor _, alvo in ipairs(alvosEm(chegada, CFG.RAIO_DESP, 10)) do\n\t\t\t\t\t\taplicarDano(alvo, CFG.DANO_DESP)\n\t\t\t\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\t\t\t\tif alvoRaiz then\n\t\t\t\t\t\t\tempurrar(alvo, (alvoRaiz.Position - chegada)\n\t\t\t\t\t\t\t\t+ Vector3.new(0, 0.4, 0), CFG.FORCA_DESP, 0.26)\n\t\t\t\t\t\tend\n\t\t\t\t\tend\n\t\t\t\tend)\n\t\t\t\ti = i + 1\n\t\t\tend\n\t\tend },\n\t}), function() ocupado = false end)\nend\n')

# ═══════════════════════════════════════════════════════════════
T('Asas Telecineticas',
  objeto='AsasTelecineticas_Server_V1', sufixo='GravAsas',
  arquetipo='TELECINESE', alcance_mira=60,
  rotulo_m1='bate as asas: sobe e empurra quem estiver perto', rotulo_r='Mergulho',
  rotulo_t='Planar', rotulo_y='Vendaval',
  origem=['M1 e R vêm do conjunto GRAVIDADE anterior, sem uma linha mudada.', 'T e Y são novas, e usam os Sound da origem que estavam mudos.'],
  cfg="""	ALCANCE       = 8,
	IMPULSO_CIMA  = 78,
	IMPULSO_FRENTE = 46,
	RAIO_SOPRO    = 14,
	DANO_SOPRO    = 12,
	EMPURRAO      = 62,
	RECARGA       = 5,

	RECARGA_R     = 12,
	ALTURA_SUBIDA = 34,
	FORCA_MERGULHO = 190,
	RAIO_MERGULHO = 17,
	DANO_MERGULHO = 42,
	RECARGA_T      = 13,
	DURACAO_PLANO  = 5,
	PASSO_PLANO    = 0.35,
	SUSTENTO_PLANO = 3.2,
	VELOCIDADE_PLANO = 1.5,

	RECARGA_Y      = 17,
	ALCANCE_VENTO  = 40,
	LARGURA_VENTO  = 12,
	DANO_VENTO     = 24,
	FORCA_VENTO    = 130,""",
  estado='local impulsoAtivo = nil\nlocal planandoAte = 0',
  corpo='\n--═══════════════════════════════════════════════════════════════\n-- PRIMÁRIA — a batida de asa\n--\n-- Sobe o portador e empurra quem está perto. O impulso do PRÓPRIO portador é\n-- guardado: se a Tool sumir no meio, `desmontar()` o tira — corpo de força\n-- pendurado num personagem é estado que vaza.\n--═══════════════════════════════════════════════════════════════\n\nlocal function impulsionar(direcao, forca, tempo)\n\tif impulsoAtivo then impulsoAtivo.Parent = nil end\n\timpulsoAtivo = Instance.new("BodyVelocity")\n\timpulsoAtivo.MaxForce = Vector3.new(1e5, 1e5, 1e5)\n\timpulsoAtivo.Velocity = direcao.Unit * forca\n\timpulsoAtivo.Parent = raiz\n\tDebris:AddItem(impulsoAtivo, tempo)\nend\n\nfunction primaria(_mira)\n\tocupado = true\n\trig:PlaySequence("BATIDA", despachar({\n\t\tABRE = { faz = function()\n\t\t\ttocar("ScifiLiftSound", 1.2)\n\t\tend },\n\t\tBATE = { faz = function()\n\t\t\ttocar("ScifiBlastSound", 1.05)\n\t\t\timpulsionar(Vector3.new(0, CFG.IMPULSO_CIMA, 0)\n\t\t\t\t+ raiz.CFrame.LookVector * CFG.IMPULSO_FRENTE, 1, 0.3)\n\t\t\tvfx("ASA", { cframe = raiz.CFrame, escala = 1.2 })\n\t\t\tfor _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_SOPRO, 10)) do\n\t\t\t\taplicarDano(alvo, CFG.DANO_SOPRO)\n\t\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\t\tif alvoRaiz then\n\t\t\t\t\tempurrar(alvo, (alvoRaiz.Position - raiz.Position)\n\t\t\t\t\t\t+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.22)\n\t\t\t\tend\n\t\t\tend\n\t\tend },\n\t}), function()\n\t\tocupado = false\n\tend)\nend\n\n--═══════════════════════════════════════════════════════════════\n-- EXTRA — o mergulho\n--\n-- Sobe, segura, e desce com peso. É a sequência com mais quadro segurado do\n-- conjunto depois do ultimate — a regra 7 vale para o alto também: o instante\n-- parado no ar é o que vende a queda.\n--═══════════════════════════════════════════════════════════════\n\nfunction extraR(_mira)\n\tocupado = true\n\trig:PlaySequence("MERGULHO", despachar({\n\t\tERGUE = { faz = function()\n\t\t\ttocar("ScifiLiftSound", 0.85)\n\t\t\timpulsionar(Vector3.new(0, CFG.ALTURA_SUBIDA, 0), 1, 0.45)\n\t\t\tvfx("ASA", { cframe = raiz.CFrame, escala = 1 })\n\t\tend },\n\t\tDESCE = { faz = function()\n\t\t\ttocar("ScifiBlastSound", 0.75)\n\t\t\timpulsionar(Vector3.new(0, -1, 0), CFG.FORCA_MERGULHO, 0.35)\n\t\tend },\n\t\tIMPACTO = { faz = function()\n\t\t\tlocal chao = raiz.Position - Vector3.new(0, 2.6, 0)\n\t\t\tvfx("MERGULHO", { posicao = chao, escala = 1.4 })\n\t\t\ttocarEm("Bam", chao, 0.8)\n\t\t\tfor _, alvo in ipairs(alvosEm(chao, CFG.RAIO_MERGULHO, 12)) do\n\t\t\t\taplicarDano(alvo, CFG.DANO_MERGULHO)\n\t\t\t\ttombar(alvo, 1.6)\n\t\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\t\tif alvoRaiz then\n\t\t\t\t\tempurrar(alvo, (alvoRaiz.Position - chao)\n\t\t\t\t\t\t+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO * 1.4, 0.28)\n\t\t\t\tend\n\t\t\tend\n\t\tend },\n\t}), function()\n\t\tocupado = false\n\tend)\nend\n\n--- T — PLANAR: queda lenta e passo mais rápido, por prazo.\n---\n--- A queda lenta é um empurrão para cima FRACO e repetido — 3.2 contra os ~196\n--- da gravidade do jogo. Ele não levanta: ele segura. E de novo, `workspace.\n--- Gravity` não é tocado.\nfunction extraT(_mira)\n\tocupado = true\n\trig:PlaySequence("PLANAR", despachar({\n\t\tABRE  = { sfx = { "EquipSound", 1.15 } },\n\t\tPLANA = { faz = function()\n\t\t\tif not (personagem and humanoide and raiz) then return end\n\t\t\tplanandoAte = os.clock() + CFG.DURACAO_PLANO\n\t\t\tlocal minha = novaGeracao("T")\n\t\t\tvfx("ASA", { posicao = raiz.Position, escala = 1.1 })\n\t\t\ttocar("ScifiLiftSound", 1.2)\n\t\t\tafrouxar(humanoide, CFG.VELOCIDADE_PLANO, CFG.DURACAO_PLANO)\n\n\t\t\ttask.spawn(function()\n\t\t\t\twhile geracao.T == minha and os.clock() < planandoAte do\n\t\t\t\t\tif not (personagem and raiz and raiz.Parent\n\t\t\t\t\t\t\tand humanoide and humanoide.Health > 0) then\n\t\t\t\t\t\tbreak\n\t\t\t\t\tend\n\t\t\t\t\t-- só segura QUEM ESTÁ CAINDO: empurrar para cima quem já\n\t\t\t\t\t-- sobe viraria voo infinito\n\t\t\t\t\tif raiz.AssemblyLinearVelocity.Y < 0 then\n\t\t\t\t\t\tlocal freio = Instance.new("BodyVelocity")\n\t\t\t\t\t\tfreio.MaxForce = Vector3.new(0, 1e5, 0)\n\t\t\t\t\t\tfreio.Velocity = Vector3.new(0, -CFG.SUSTENTO_PLANO, 0)\n\t\t\t\t\t\tfreio.Parent = raiz\n\t\t\t\t\t\tDebris:AddItem(freio, CFG.PASSO_PLANO)\n\t\t\t\t\tend\n\t\t\t\t\ttask.wait(CFG.PASSO_PLANO)\n\t\t\t\tend\n\t\t\tend)\n\t\tend },\n\t}), function() ocupado = false end)\nend\n\n--- Y — VENDAVAL: uma batida de asa que empurra tudo à frente, num corredor.\n---\n--- Projeção no eixo mais distância lateral, não um raio: um raio pegaria quem\n--- está atrás, e a habilidade é direcional.\nfunction extraY(mira)\n\tocupado = true\n\tlocal destino = mira\n\trig:PlaySequence("VENDAVAL", despachar({\n\t\tERGUE  = { sfx = { "EquipSound", 0.8 } },\n\t\tSEGURA = { sfx = { "Bam", 0.9 } },\n\t\tSOPRA  = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal origem = raiz.Position\n\t\t\tlocal ponto = destino or frente(CFG.ALCANCE_VENTO)\n\t\t\tlocal delta = Vector3.new(ponto.X - origem.X, 0, ponto.Z - origem.Z)\n\t\t\tlocal dir = (delta.Magnitude > 0.5) and delta.Unit\n\t\t\t\tor raiz.CFrame.LookVector\n\n\t\t\tvfx("ASA", { posicao = origem, escala = 1.6 })\n\t\t\tvfx("PULSO", { posicao = origem + dir * 6, escala = 1.3 })\n\t\t\ttocarEm("ScifiBlastSound", origem, 0.85)\n\n\t\t\tfor _, alvo in ipairs(alvosEm(origem,\n\t\t\t\t\tCFG.ALCANCE_VENTO + CFG.LARGURA_VENTO, 16)) do\n\t\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\t\tif alvoRaiz then\n\t\t\t\t\tlocal rel = alvoRaiz.Position - origem\n\t\t\t\t\tlocal aoLongo = rel:Dot(dir)\n\t\t\t\t\tlocal lateral = (rel - dir * aoLongo).Magnitude\n\t\t\t\t\tif aoLongo >= -2 and aoLongo <= CFG.ALCANCE_VENTO\n\t\t\t\t\t\t\tand lateral <= CFG.LARGURA_VENTO then\n\t\t\t\t\t\taplicarDano(alvo, CFG.DANO_VENTO)\n\t\t\t\t\t\tempurrar(alvo, dir + Vector3.new(0, 0.45, 0),\n\t\t\t\t\t\t\tCFG.FORCA_VENTO, 0.34)\n\t\t\t\t\tend\n\t\t\t\tend\n\t\t\tend\n\t\tend },\n\t}), function() ocupado = false end)\nend\n')

# ═══════════════════════════════════════════════════════════════
T('Terremoto',
  objeto='Terremoto_Server_V1', sufixo='GravTerremoto',
  arquetipo='GRAVIDADE', alcance_mira=70,
  rotulo_m1='rachadura que corre à frente', rotulo_r='Colapso',
  rotulo_t='Estaca', rotulo_y='Ruina',
  origem=['M1 e R vêm do conjunto GRAVIDADE anterior, sem uma linha mudada.', 'T e Y são novas, e usam os Sound da origem que estavam mudos.'],
  cfg="""	ALCANCE       = 8,
	PASSOS        = 6,
	AVANCO        = 5,
	RAIO_PASSO    = 7,
	DANO          = 20,
	SUBIDA        = 34,
	RECARGA       = 7,

	RECARGA_R     = 42,
	RAIO_COLAPSO  = 44,
	DANO_COLAPSO  = 78,
	EMPURRAO_COLAPSO = 110,
	CARGA         = 4.4,
	RECARGA_T      = 12,
	ALCANCE_ESTACA = 42,
	PILARES        = 6,
	ESPACO_ESTACA  = 6.5,
	INTERVALO_ESTACA = 0.08,
	RAIO_ESTACA    = 6,
	DANO_ESTACA    = 21,
	SUBIDA_ESTACA  = 62,

	RECARGA_Y      = 26,
	RAIO_RUINA     = 28,
	NUCLEO_RUINA   = 10,
	DANO_RUINA     = 54,
	BORDA_RUINA    = 27,
	TOMBO_RUINA    = 2.2,""",
  estado='',
  corpo='\n--═══════════════════════════════════════════════════════════════\n-- PRIMÁRIA — a rachadura\n--\n-- Ela CORRE: seis paradas à frente, uma a cada beat de tempo, cada uma com o\n-- seu raio. Bater tudo de uma vez no mesmo instante seria uma explosão, não um\n-- terremoto — e a diferença entre os dois é justamente a propagação.\n--═══════════════════════════════════════════════════════════════\n\nfunction primaria(_mira)\n\tocupado = true\n\trig:PlaySequence("RACHADURA", function(passo)\n\t\tlocal marca = marcaDe(passo)\n\t\tif marca == "ERGUE" then\n\t\t\ttocar("Swing", 0.85)\n\t\telseif marca ~= "BATE" then\n\t\t\treturn\n\t\telse\n\t\t\tlocal chao = raiz.Position - Vector3.new(0, 2.6, 0)\n\t\t\tlocal direcao = raiz.CFrame.LookVector\n\t\t\ttocarEm("Hit", chao, 0.8)\n\t\t\tvfx("RACHADURA", { posicao = chao, direcao = direcao,\n\t\t\t\tescala = 1.2, passos = CFG.PASSOS })\n\n\t\t\tfor i = 1, CFG.PASSOS do\n\t\t\t\tlocal onde = chao + direcao * (i * CFG.AVANCO)\n\t\t\t\ttask.delay((i - 1) * 0.05, function()\n\t\t\t\t\tif not personagem then return end\n\t\t\t\t\tfor _, alvo in ipairs(alvosEm(onde, CFG.RAIO_PASSO, 6)) do\n\t\t\t\t\t\taplicarDano(alvo, CFG.DANO)\n\t\t\t\t\t\tempurrar(alvo, Vector3.new(0, 1, 0), CFG.SUBIDA, 0.24)\n\t\t\t\t\tend\n\t\t\t\tend)\n\t\t\tend\n\t\tend\n\tend, function()\n\t\tocupado = false\n\tend)\nend\n\n--═══════════════════════════════════════════════════════════════\n-- EXTRA — o colapso\n--\n-- ULTIMATE. 7.20 s, 71% de preparação — dentro da faixa da regra 5, que mede\n-- ultimate em 7–9 s. É a única sequência do conjunto com beat de câmera, e é a\n-- própria regra que exige: ultimate longo sem enquadramento vira tempo morto.\n--\n-- O beat "CAMERA" viaja pelo VFXRemote como qualquer outro. Quem enquadra é o\n-- cliente — servidor não toca em `Camera`, nunca.\n--═══════════════════════════════════════════════════════════════\n\nfunction extraR(_mira)\n\tocupado = true\n\trig:LockCharacter(true)\n\tlocal id = novoId("COLAPSO")\n\n\trig:PlaySequence("COLAPSO", despachar({\n\t\tCAMERA = { faz = function()\n\t\t\ttocar("Swing", 0.55)\n\t\t\tvfx("COLAPSO_CARGA", { posicao = raiz.Position, escala = 1.4,\n\t\t\t\traio = CFG.RAIO_COLAPSO, duracao = CFG.CARGA, id = id })\n\t\tend },\n\t\tCARGA = { faz = function()\n\t\t\ttocarEm("Press", raiz.Position, 0.7)\n\t\tend },\n\t\tAUGE = { faz = function()\n\t\t\ttocarEm("Press", raiz.Position, 1.4)\n\t\tend },\n\t\tCOLAPSO = { faz = function()\n\t\t\tlocal chao = raiz.Position - Vector3.new(0, 2.6, 0)\n\t\t\tvfx("APAGAR", { id = id })\n\t\t\tvfx("COLAPSO", { posicao = chao, escala = 1.8 })\n\t\t\ttocarEm("Hit", chao, 0.55)\n\t\t\tfor _, alvo in ipairs(alvosEm(chao, CFG.RAIO_COLAPSO, 20)) do\n\t\t\t\taplicarDano(alvo, CFG.DANO_COLAPSO)\n\t\t\t\ttombar(alvo, 2.6)\n\t\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\t\tif alvoRaiz then\n\t\t\t\t\tempurrar(alvo, (alvoRaiz.Position - chao)\n\t\t\t\t\t\t+ Vector3.new(0, 0.6, 0), CFG.EMPURRAO_COLAPSO, 0.4)\n\t\t\t\tend\n\t\t\tend\n\t\tend },\n\t}), function()\n\t\trig:LockCharacter(false)\n\t\tocupado = false\n\tend)\nend\n\n--- T — ESTACA: pilares sobem em linha, e quem está em cima vai junto.\nfunction extraT(mira)\n\tocupado = true\n\tlocal destino = mira\n\trig:PlaySequence("ESTACA", despachar({\n\t\tERGUE = { sfx = { "Press", 1 } },\n\t\tCRAVA = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal origem = raiz.Position - Vector3.new(0, 2.6, 0)\n\t\t\tlocal ponto = destino or frente(CFG.ALCANCE_ESTACA)\n\t\t\tlocal delta = Vector3.new(ponto.X - origem.X, 0, ponto.Z - origem.Z)\n\t\t\tlocal dir = (delta.Magnitude > 0.5) and delta.Unit\n\t\t\t\tor raiz.CFrame.LookVector\n\t\t\tlocal i = 1\n\t\t\twhile i <= CFG.PILARES do\n\t\t\t\tlocal indice = i\n\t\t\t\ttask.delay(indice * CFG.INTERVALO_ESTACA, function()\n\t\t\t\t\tif not personagem then return end\n\t\t\t\t\tlocal onde = origem + dir * (indice * CFG.ESPACO_ESTACA)\n\t\t\t\t\tvfx("RACHADURA", { posicao = onde, escala = 1.2 })\n\t\t\t\t\tvfx("PULSO", { posicao = onde, escala = 0.7 })\n\t\t\t\t\ttocarEm("Hit", onde, 1.25)\n\t\t\t\t\tfor _, alvo in ipairs(alvosEm(onde, CFG.RAIO_ESTACA, 8)) do\n\t\t\t\t\t\taplicarDano(alvo, CFG.DANO_ESTACA)\n\t\t\t\t\t\tempurrar(alvo, Vector3.new(0, 1, 0),\n\t\t\t\t\t\t\tCFG.SUBIDA_ESTACA, 0.22)\n\t\t\t\t\tend\n\t\t\t\tend)\n\t\t\t\ti = i + 1\n\t\t\tend\n\t\tend },\n\t}), function() ocupado = false end)\nend\n\n--- Y — RUÍNA: a maior área do conjunto, com núcleo e borda.\n---\n--- Dois raios é o que impede um estouro grande de matar meio servidor por\n--- estar por perto.\nfunction extraY(_mira)\n\tocupado = true\n\trig:PlaySequence("RUINA", despachar({\n\t\tERGUE  = { sfx = { "Swing", 0.8 } },\n\t\tSEGURA = { sfx = { "Press", 0.7 } },\n\t\tDESABA = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal chao = raiz.Position - Vector3.new(0, 2.6, 0)\n\t\t\tvfx("COLAPSO", { posicao = chao, raio = CFG.RAIO_RUINA })\n\t\t\tvfx("RACHADURA", { posicao = chao, escala = 1.8 })\n\t\t\ttocarEm("Hit", chao, 0.7)\n\t\t\tgolpearArea(chao, CFG.RAIO_RUINA, CFG.NUCLEO_RUINA,\n\t\t\t\tCFG.DANO_RUINA, CFG.BORDA_RUINA, nil, CFG.TOMBO_RUINA)\n\t\tend },\n\t}), function() ocupado = false end)\nend\n')

# ═══════════════════════════════════════════════════════════════
T('Telecinese Gravitacional',
  objeto='TelecineseGravitacional_Server_V1', sufixo='GravGravitacional',
  arquetipo='TELECINESE', alcance_mira=110,
  rotulo_m1='puxa todos para o ponto mirado', rotulo_r='Singularidade',
  rotulo_t='Orbita', rotulo_y='Expulsar',
  origem=['M1 e R vêm do conjunto GRAVIDADE anterior, sem uma linha mudada.', 'T e Y são novas, e usam os Sound da origem que estavam mudos.'],
  cfg="""	ALCANCE       = 8,
	RAIO_PUXAO    = 30,
	DANO_PUXAO    = 16,
	TEMPO_PUXAO   = 0.8,
	RECARGA       = 12,

	RECARGA_R     = 26,
	RAIO_SING     = 26,
	DANO_SING     = 30,
	DANO_ESTOURO  = 55,
	TEMPO_SING    = 1.1,
	EMPURRAO_SING = 95,
	RECARGA_T      = 18,
	ALCANCE_ORBITA = 60,
	RAIO_ORBITA    = 18,
	DURACAO_ORBITA = 4.5,
	PASSO_ORBITA   = 0.4,
	ANEL_ORBITA    = 9,
	ALTURA_ORBITA  = 4,
	DANO_ORBITA    = 8,

	RECARGA_Y      = 20,
	RAIO_EXPULSA   = 24,
	NUCLEO_EXPULSA = 9,
	DANO_EXPULSA   = 44,
	BORDA_EXPULSA  = 22,
	FORCA_EXPULSA  = 165,
	TOMBO_EXPULSA  = 1.9,""",
  estado='local orbitaId = nil',
  corpo='\n--═══════════════════════════════════════════════════════════════\n-- PRIMÁRIA — o puxão\n--\n-- Todo mundo no raio vem PARA o ponto. É o inverso de toda explosão do\n-- repositório, e é a leitura que define telecinese: as coisas vão para onde a\n-- física não mandaria.\n--═══════════════════════════════════════════════════════════════\n\nfunction primaria(mira)\n\tocupado = true\n\trig:PlaySequence("PUXAO", despachar({\n\t\tALCANCA = { faz = function()\n\t\t\ttocar("SendOut", 1.1)\n\t\t\tvfx("AGARRA", { origem = Handle.Position, destino = mira })\n\t\tend },\n\t\tPUXA = { faz = function()\n\t\t\ttocarEm("InitialHit", mira, 0.9)\n\t\t\tvfx("PUXAO", { posicao = mira, escala = 1.3, raio = CFG.RAIO_PUXAO })\n\t\t\tfor _, alvo in ipairs(alvosEm(mira, CFG.RAIO_PUXAO, 14)) do\n\t\t\t\taplicarDano(alvo, CFG.DANO_PUXAO)\n\t\t\t\tatrair(alvo, mira, CFG.TEMPO_PUXAO, 11000)\n\t\t\tend\n\t\tend },\n\t\tSEGURA = { faz = function()\n\t\t\ttocar("Whack", 0.8)\n\t\tend },\n\t}), function()\n\t\tocupado = false\n\tend)\nend\n\n--═══════════════════════════════════════════════════════════════\n-- EXTRA — a singularidade\n--\n-- Junta, segura, e estoura. O dano vem em dois tempos, e o segundo é maior:\n-- quem ficou preso paga mais caro que quem escapou da atração.\n--═══════════════════════════════════════════════════════════════\n\nfunction extraR(mira)\n\tocupado = true\n\tlocal id = novoId("SING")\n\n\trig:PlaySequence("SINGULARIDADE", despachar({\n\t\tABRE = { faz = function()\n\t\t\ttocar("SendOut", 0.8)\n\t\tend },\n\t\tREUNE = { faz = function()\n\t\t\ttocarEm("InitialHit", mira, 0.75)\n\t\t\tvfx("SINGULARIDADE", { posicao = mira, escala = 1.4,\n\t\t\t\tduracao = CFG.TEMPO_SING, id = id })\n\t\t\tfor _, alvo in ipairs(alvosEm(mira, CFG.RAIO_SING, 16)) do\n\t\t\t\taplicarDano(alvo, CFG.DANO_SING)\n\t\t\t\tatrair(alvo, mira, CFG.TEMPO_SING, 14000)\n\t\t\tend\n\t\tend },\n\t\tSEGURA = { faz = function()\n\t\t\ttocarEm("Whack", mira, 0.6)\n\t\tend },\n\t\tCOLAPSA = { faz = function()\n\t\t\tvfx("APAGAR", { id = id })\n\t\t\tvfx("COLAPSO", { posicao = mira, escala = 1.2 })\n\t\t\ttocarEm("Hit", mira, 0.7)\n\t\t\t-- quem ficou preso paga o dobro do que pagou na atração\n\t\t\tfor _, alvo in ipairs(alvosEm(mira, CFG.RAIO_SING * 0.6, 16)) do\n\t\t\t\taplicarDano(alvo, CFG.DANO_ESTOURO)\n\t\t\t\ttombar(alvo, 2)\n\t\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\t\tif alvoRaiz then\n\t\t\t\t\tempurrar(alvo, (alvoRaiz.Position - mira)\n\t\t\t\t\t\t+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_SING, 0.32)\n\t\t\t\tend\n\t\t\tend\n\t\tend },\n\t}), function()\n\t\tocupado = false\n\tend)\nend\n\n--- T — ÓRBITA: os alvos GIRAM em volta do ponto, presos num anel.\n---\n--- Cada alvo recebe o próprio `atrair`, para um ponto do anel que avança a\n--- cada passo. É o giro: ninguém fica no centro, e ninguém escapa.\nfunction extraT(mira)\n\tocupado = true\n\tlocal destino = mira\n\trig:PlaySequence("ORBITA", despachar({\n\t\tABRE = { sfx = { "SendOut", 1.05 } },\n\t\tGIRA = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal centro = destino or frente(CFG.ALCANCE_ORBITA * 0.5)\n\t\t\tapagarEfeito(orbitaId)\n\t\t\torbitaId = novoId("ORBITA")\n\t\t\tlocal meu = orbitaId\n\t\t\tlocal minha = novaGeracao("T")\n\t\t\tvfx("PUXAO", { posicao = centro, raio = CFG.RAIO_ORBITA,\n\t\t\t\tduracao = CFG.DURACAO_ORBITA, id = meu })\n\t\t\ttocarEm("Hit", centro, 1.15)\n\n\t\t\ttask.spawn(function()\n\t\t\t\tlocal ate = os.clock() + CFG.DURACAO_ORBITA\n\t\t\t\tlocal passo = 0\n\t\t\t\twhile geracao.T == minha and os.clock() < ate do\n\t\t\t\t\tif not personagem then break end\n\t\t\t\t\tlocal presos = alvosEm(centro, CFG.RAIO_ORBITA, 12)\n\t\t\t\t\tfor indice, alvo in ipairs(presos) do\n\t\t\t\t\t\tlocal ang = passo * 0.8\n\t\t\t\t\t\t\t+ indice * (math.pi * 2 / math.max(#presos, 1))\n\t\t\t\t\t\tlocal onde = centro + Vector3.new(\n\t\t\t\t\t\t\tmath.cos(ang) * CFG.ANEL_ORBITA,\n\t\t\t\t\t\t\tCFG.ALTURA_ORBITA,\n\t\t\t\t\t\t\tmath.sin(ang) * CFG.ANEL_ORBITA)\n\t\t\t\t\t\tatrair(alvo, onde, CFG.PASSO_ORBITA * 1.4)\n\t\t\t\t\t\taplicarDano(alvo, CFG.DANO_ORBITA)\n\t\t\t\t\tend\n\t\t\t\t\tpasso = passo + 1\n\t\t\t\t\ttask.wait(CFG.PASSO_ORBITA)\n\t\t\t\tend\n\t\t\t\tif orbitaId == meu then\n\t\t\t\t\tapagarEfeito(meu)\n\t\t\t\t\torbitaId = nil\n\t\t\t\tend\n\t\t\tend)\n\t\tend },\n\t}), function() ocupado = false end)\nend\n\n--- Y — EXPULSAR: o contrário do puxão. Tudo vai para fora de uma vez.\n---\n--- É o fecho natural da `ÓRBITA`: junta com T, expulsa com Y.\nfunction extraY(_mira)\n\tocupado = true\n\trig:PlaySequence("EXPULSAR", despachar({\n\t\tERGUE  = { sfx = { "InitialHit", 0.9 } },\n\t\tSEGURA = { sfx = { "SendOut", 0.8 } },\n\t\tEXPULSA = { faz = function()\n\t\t\tif not (raiz and raiz.Parent) then return end\n\t\t\tlocal centro = raiz.Position\n\t\t\tif orbitaId then\n\t\t\t\tapagarEfeito(orbitaId)\n\t\t\t\torbitaId = nil\n\t\t\t\tnovaGeracao("T")\n\t\t\tend\n\t\t\tvfx("SINGULARIDADE", { posicao = centro,\n\t\t\t\traio = CFG.RAIO_EXPULSA })\n\t\t\tvfx("PULSO", { posicao = centro, escala = 1.8 })\n\t\t\ttocarEm("Whack", centro, 0.8)\n\t\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO_EXPULSA, 16)) do\n\t\t\t\tlocal alvoRaiz = raizDe(alvo)\n\t\t\t\tlocal d = alvoRaiz\n\t\t\t\t\tand (alvoRaiz.Position - centro).Magnitude\n\t\t\t\t\tor CFG.RAIO_EXPULSA\n\t\t\t\tif d <= CFG.NUCLEO_EXPULSA then\n\t\t\t\t\taplicarDano(alvo, CFG.DANO_EXPULSA)\n\t\t\t\t\ttombar(alvo, CFG.TOMBO_EXPULSA)\n\t\t\t\telse\n\t\t\t\t\taplicarDano(alvo, CFG.BORDA_EXPULSA)\n\t\t\t\tend\n\t\t\t\tif alvoRaiz then\n\t\t\t\t\tempurrar(alvo, (alvoRaiz.Position - centro)\n\t\t\t\t\t\t+ Vector3.new(0, 0.6, 0), CFG.FORCA_EXPULSA, 0.34)\n\t\t\t\tend\n\t\t\tend\n\t\tend },\n\t}), function() ocupado = false end)\nend\n')
