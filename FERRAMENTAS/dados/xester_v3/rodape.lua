
--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

local function pronto(quando, recarga)
	return os.clock() - quando >= recarga
end

local function podeAgir()
	if not (personagem and humanoide and raiz and rig) then return false end
	if humanoide.Health <= 0 then return false end
	return not ocupado
end

VFXRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente(20) end
{guarda_m1}	primaria(mira)
end)
{ligacao_extra}
Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz and jogador) then return end

	rig = Animator.new(personagem, "{sufixo}", Poses, Poses.SEQUENCIAS,
		Poses.TRACKS)

	-- a Forma 2 acende sozinha: quem já virou dragão com o `Eclipse Deck`
	-- saca esta Tool e continua dragão, porque o estado mora no Character.
	if formaAtual() == 2 then
		porCajado()
		ligarAura()
	end

	-- morte devolve tudo. O cajado morre com o personagem sem ninguém pedir.
	guardar(humanoide.Died:Connect(function()
		limparTudo()
		apagarAura()
	end))
{ao_equipar}end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	bonusAtivo = false
	limparTudo()
	apagarAura()
	acabarCena()
{ao_guardar}	if rig then
		rig:CancelSequence()
		rig:ReleaseLegs()
		rig:LockCharacter(false)
		rig:Destroy()
		rig = nil
	end
end

Tool.Unequipped:Connect(desmontar)
Tool.Destroying:Connect(desmontar)
