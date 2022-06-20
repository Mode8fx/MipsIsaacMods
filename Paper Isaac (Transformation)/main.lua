PaperTransformation = RegisterMod("Paper Transformation", 1)

PaperTransformation.COSTUME_PAPER_ISAAC = Isaac.GetCostumeIdByPath("gfx/characters/paperisaacani.anm2")

PaperTransformation.CHALLENGE_PAPER_ISAAC_ALL_BADGES = Isaac.GetChallengeIdByName("Paper Isaac (All)")
PaperTransformation.CHALLENGE_PAPER_ISAAC_NORMAL = Isaac.GetChallengeIdByName("Paper Isaac")

local GameState = {}
local json = require("json")

local inChallengeSelection1 = false
local inChallengeSelection2 = false
local challengeCount = 0
local choseBA = false
local choseCO = false
local choseCC = false
local choseDP = false
local choseFS = false
local chosePUDD = false
local choseR = false
local choseRP = false
local choseSG = false
local choseSS = false
local choseSA = false
local alreadyHit = false

local players = {}
local currFrame = 0

function PaperTransformation:onStart()
	if PaperTransformation:HasData() then
		GameState = json.decode(PaperTransformation:LoadData())
	else
		GameState = {}
	end

	players = getPlayers()
	currFrame = Game():GetFrameCount()
	PaperTransformation.COLLECTIBLE_BUMP_ATTACK = Isaac.GetItemIdByName("Bump Attack")
	PaperTransformation.COLLECTIBLE_CHILL_OUT = Isaac.GetItemIdByName("Chill Out")
	PaperTransformation.COLLECTIBLE_CLOSE_CALL = Isaac.GetItemIdByName("Close Call")
	PaperTransformation.COLLECTIBLE_DOUBLE_PAIN = Isaac.GetItemIdByName("Double Pain")
	PaperTransformation.TRINKET_FIRE_SHIELD = Isaac.GetTrinketIdByName("Fire Shield")
	PaperTransformation.COLLECTIBLE_P_UP_D_DOWN = Isaac.GetItemIdByName("P-Up, D-Down")
	PaperTransformation.COLLECTIBLE_REFUND = Isaac.GetItemIdByName("Refund")
	PaperTransformation.COLLECTIBLE_RETURN_POSTAGE = Isaac.GetItemIdByName("Return Postage")
	PaperTransformation.COLLECTIBLE_SLOW_GO = Isaac.GetItemIdByName("Slow Go")
	PaperTransformation.COLLECTIBLE_SPIKE_SHIELD = Isaac.GetItemIdByName("Spike Shield")
	PaperTransformation.COLLECTIBLE_SUPER_APPEAL = Isaac.GetItemIdByName("Super Appeal")
	PaperTransformation.COLLECTIBLE_TRANSFORMER = Isaac.GetItemIdByName("Transformer")

	if currFrame == 0 and Game().Challenge == PaperTransformation.CHALLENGE_PAPER_ISAAC_ALL_BADGES then
		custAddItem(PaperTransformation.COLLECTIBLE_BUMP_ATTACK, false)
		custAddItem(PaperTransformation.COLLECTIBLE_CHILL_OUT, false)
		custAddItem(PaperTransformation.COLLECTIBLE_CLOSE_CALL, false)
		custAddItem(PaperTransformation.TRINKET_FIRE_SHIELD, true)
		custAddItem(PaperTransformation.COLLECTIBLE_P_UP_D_DOWN, false)
		custAddItem(PaperTransformation.COLLECTIBLE_REFUND, false)
		custAddItem(PaperTransformation.COLLECTIBLE_RETURN_POSTAGE, false)
		custAddItem(PaperTransformation.COLLECTIBLE_SPIKE_SHIELD, false)
		custAddItem(PaperTransformation.COLLECTIBLE_SUPER_APPEAL, false)
	end
	if currFrame == 0 and Game().Challenge == PaperTransformation.CHALLENGE_PAPER_ISAAC_NORMAL then
		custAddItem(PaperTransformation.TRINKET_FIRE_SHIELD, true)
		inChallengeSelection1 = true
		inChallengeSelection2 = false
		challengeCount = 0
		choseBA = false
		choseCO = false
		choseCC = false
		choseDP = false
		chosePUDD = false
		choseR = false
		choseRP = false
		choseSG = false
		choseSS = false
		choseSA = false
	else
		inChallengeSelection1 = false
		inChallengeSelection2 = false
	end
end

function PaperTransformation:onExit(save)
	PaperTransformation:SaveData(json.encode(GameState))
end

function PaperTransformation:onRender()
	if inChallengeSelection1 then
		if not inChallengeSelection2 then
			Isaac.RenderText("Press DROP (CTRL/RT) to choose your items", 117, 10, 1, 1, 1, 1)
			Isaac.RenderText("(Don't press anything else while pressing DROP)", 99, 22, 1, 1, 1, 1)
		else
			if not choseBA then
				Isaac.RenderText("Move ^ - Bump Attack", 75, 96, 1, 1, 1, 1)
			end
			if not choseCO then
				Isaac.RenderText("Move < - Chill Out", 75, 108, 1, 1, 1, 1)
			end
			if not choseCC then
				Isaac.RenderText("Move > - Close Call", 75, 120, 1, 1, 1, 1)
			end
			if not chosePUDD then
				Isaac.RenderText("Move v - P-Up, D-Down", 75, 132, 1, 1, 1, 1)
			end
			if not choseR then
				Isaac.RenderText("Fire ^ - Refund", 267, 96, 1, 1, 1, 1)
			end
			if not choseRP then
				Isaac.RenderText("Fire < - Return Postage", 267, 108, 1, 1, 1, 1)
			end
			if not choseSS then
				Isaac.RenderText("Fire > - Spike Shield", 267, 120, 1, 1, 1, 1)
			end
			if not choseSA then
				Isaac.RenderText("Fire v - Super Appeal", 267, 132, 1, 1, 1, 1)
			end
		end
	end
end

function PaperTransformation:onUpdate()
	currFrame = Game():GetFrameCount()
	if inChallengeSelection1 then
		for controllerId=0,1 do
			if Input.IsActionPressed(ButtonAction.ACTION_DROP, controllerId) then
				inChallengeSelection2 = true
			end
		end
		if inChallengeSelection2 then
			for controllerId=0,1 do
				if not choseBA and Input.IsActionPressed(ButtonAction.ACTION_UP, controllerId) then
					if custAddItem(PaperTransformation.COLLECTIBLE_BUMP_ATTACK, false) then
						choseBA = true
						challengeCount = challengeCount + 1
					end
				end
				if not choseCO and Input.IsActionPressed(ButtonAction.ACTION_LEFT, controllerId) then
					if custAddItem(PaperTransformation.COLLECTIBLE_CHILL_OUT, false) then
						choseCO = true
						challengeCount = challengeCount + 1
					end
				end
				if not choseCC and Input.IsActionPressed(ButtonAction.ACTION_RIGHT, controllerId) then
					if custAddItem(PaperTransformation.COLLECTIBLE_CLOSE_CALL, false) then
						choseCC = true
						challengeCount = challengeCount + 1
					end
				end
				if not chosePUDD and Input.IsActionPressed(ButtonAction.ACTION_DOWN, controllerId) then
					if custAddItem(PaperTransformation.COLLECTIBLE_P_UP_D_DOWN, false) then
						chosePUDD = true
						challengeCount = challengeCount + 1
					end
				end
				if not choseR and Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, controllerId) then
					if custAddItem(PaperTransformation.COLLECTIBLE_REFUND, false) then
						choseR = true
						challengeCount = challengeCount + 1
					end
				end
				if not choseRP and Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, controllerId) then
					if custAddItem(PaperTransformation.COLLECTIBLE_RETURN_POSTAGE, false) then
						choseRP = true
						challengeCount = challengeCount + 1
					end
				end
				if not choseSS and Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, controllerId) then
					if custAddItem(PaperTransformation.COLLECTIBLE_SPIKE_SHIELD, false) then
						choseSS = true
						challengeCount = challengeCount + 1
					end
				end
				if not choseSA and Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, controllerId) then
					if custAddItem(PaperTransformation.COLLECTIBLE_SUPER_APPEAL, false) then
						choseSA = true
						challengeCount = challengeCount + 1
					end
				end
				if challengeCount >= 3 then
					inChallengeSelection1 = false
					inChallengeSelection2 = false
				end
			end
		end
	end
end

function custAddItem(itemID, isTrinket)
	if itemID ~= -1 then
		if not isTrinket then
			players[1]:AddCollectible(itemID, 0, false)
			Game():GetItemPool():RemoveCollectible(itemID)
		else
			players[1]:AddTrinket(itemID)
			Game():GetItemPool():RemoveTrinket(itemID)
		end
	end
	return itemID ~= -1
end

PaperTransformation:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperTransformation.onStart)
PaperTransformation:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, PaperTransformation.onExit)
PaperTransformation:AddCallback(ModCallbacks.MC_POST_GAME_END, PaperTransformation.onExit)
PaperTransformation:AddCallback(ModCallbacks.MC_POST_UPDATE, PaperTransformation.onUpdate)
PaperTransformation:AddCallback(ModCallbacks.MC_POST_RENDER, PaperTransformation.onRender)

function PaperTransformation:pt_onStart()
	if currFrame == 0 then
		GameState.pt_hadBA = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_hadCO = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_hadCC = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_hadDP = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_hadPUDD = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_hadR = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_hadRP = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_hadSG = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_hadSS = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_hadSA = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_hadT = {0, 0, 0, 0, 0, 0, 0, 0}
		GameState.pt_transformed = {false, false, false, false, false, false, false, false}
	end
end

function PaperTransformation:pt_onUpdate()
	if GameState.pt_transformed then
		for i=1, #players do
			if not GameState.pt_transformed[i] then
				GameState.pt_hadBA[i] = checkItemForTF(PaperTransformation.COLLECTIBLE_BUMP_ATTACK, GameState.pt_hadBA[i], players[i])
				GameState.pt_hadCO[i] = checkItemForTF(PaperTransformation.COLLECTIBLE_CHILL_OUT, GameState.pt_hadCO[i], players[i])
				GameState.pt_hadCC[i] = checkItemForTF(PaperTransformation.COLLECTIBLE_CLOSE_CALL, GameState.pt_hadCC[i], players[i])
				GameState.pt_hadDP[i] = checkItemForTF(PaperTransformation.COLLECTIBLE_DOUBLE_PAIN, GameState.pt_hadDP[i], players[i])
				GameState.pt_hadPUDD[i] = checkItemForTF(PaperTransformation.COLLECTIBLE_P_UP_D_DOWN, GameState.pt_hadPUDD[i], players[i])
				GameState.pt_hadR[i] = checkItemForTF(PaperTransformation.COLLECTIBLE_REFUND, GameState.pt_hadR[i], players[i])
				GameState.pt_hadRP[i] = checkItemForTF(PaperTransformation.COLLECTIBLE_RETURN_POSTAGE, GameState.pt_hadRP[i], players[i])
				GameState.pt_hadSG[i] = checkItemForTF(PaperTransformation.COLLECTIBLE_SLOW_GO, GameState.pt_hadSG[i], players[i])
				GameState.pt_hadSS[i] = checkItemForTF(PaperTransformation.COLLECTIBLE_SPIKE_SHIELD, GameState.pt_hadSS[i], players[i])
				GameState.pt_hadSA[i] = checkItemForTF(PaperTransformation.COLLECTIBLE_SUPER_APPEAL, GameState.pt_hadSA[i], players[i])
				if PaperTransformation.COLLECTIBLE_TRANSFORMER ~= -1 and players[i]:HasCollectible(PaperTransformation.COLLECTIBLE_TRANSFORMER) then
					GameState.pt_hadT[i] = math.max(GameState.pt_hadT[i], players[i]:GetCollectibleNum(PaperTransformation.COLLECTIBLE_TRANSFORMER))
				end

				if GameState.pt_hadBA[i] + GameState.pt_hadCO[i] + GameState.pt_hadCC[i] + GameState.pt_hadDP[i] + GameState.pt_hadPUDD[i] + GameState.pt_hadR[i] + GameState.pt_hadRP[i] + GameState.pt_hadSG[i] + GameState.pt_hadSS[i] + GameState.pt_hadSA[i] + GameState.pt_hadT[i] >= 3 then
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, players[i].Position, Vector(0,0), nil)
					SFXManager():Play(SoundEffect.SOUND_POWERUP_SPEWER, 1, 0, false, 1)
					players[i]:AddNullCostume(PaperTransformation.COSTUME_PAPER_ISAAC)
					GameState.pt_transformed[i] = true
					players[i]:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
					players[i]:AddCacheFlags(CacheFlag.CACHE_TEARCOLOR)
					players[i]:EvaluateItems()
				end
			end
		end
	end
end

function checkItemForTF(itemID, itemVar, p)
	if itemID ~= -1 and p:HasCollectible(itemID) and itemVar == 0 then
		itemVar = 1
	end
	return itemVar
end

function PaperTransformation:pt_cacheUpdate(player, flag)
	playerNum = getCurrPlayerNum(player)
	if GameState.pt_transformed and GameState.pt_transformed[playerNum] then
		if flag == CacheFlag.CACHE_SHOTSPEED then
			player.ShotSpeed = player.ShotSpeed + 0.16
		end
		if flag == CacheFlag.CACHE_TEARCOLOR then
			player.TearColor = Color(1, 1, 1, 1, 0, 0, 0)
		end
	end
end

function PaperTransformation:pt_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	PaperTransformation:pt_checkForBleeding(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	alreadyHit = false
end

function PaperTransformation:pt_checkForBleeding(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if (not alreadyHit) and damageSource and damageSource.Entity and damageSource.Entity.SpawnerType == EntityType.ENTITY_PLAYER and damageSource.Type == EntityType.ENTITY_TEAR and target:IsVulnerableEnemy() and not (target.Type == 39 and target.Variant == 22) and math.random(5) == 1 then
		playerNum = getCurrPlayerNum(damageSource.Entity.SpawnerEntity:ToPlayer())
		if GameState.pt_transformed[playerNum] then
			for _, entity in pairs(Isaac.GetRoomEntities()) do
				if entity.Type == damageSource.Entity.Type and entity.Variant == damageSource.Entity.Variant and entity.Position.X == damageSource.Entity.Position.X and entity.Position.Y == damageSource.Entity.Position.Y then
					alreadyHit = true
					target:TakeDamage(damageAmount * 0.5, 0, damageSource, 0)
					if not target:IsBoss() then
						target:AddEntityFlags(EntityFlag.FLAG_BLEED_OUT)
					end
					break
				end
			end
		end
	end
end

function getPlayers()
	local p = {}
	for i = 0, Game():GetNumPlayers() do
		if Isaac.GetPlayer(i) ~= nil then
			table.insert(p, Isaac.GetPlayer(i))
		end
	end
	return p
end

function getCurrPlayerNum(player)
	for i = 1, #players do
		if player:GetPlayerType() == players[i]:GetPlayerType() then
			return i
		end
	end
	return -1
end

PaperTransformation:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperTransformation.pt_onStart)
PaperTransformation:AddCallback(ModCallbacks.MC_POST_UPDATE, PaperTransformation.pt_onUpdate)
PaperTransformation:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, PaperTransformation.pt_cacheUpdate)
PaperTransformation:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperTransformation.pt_onHit)