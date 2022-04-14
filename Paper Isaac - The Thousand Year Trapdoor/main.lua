PaperIsaac = RegisterMod("Paper Isaac", 1)

PaperIsaac.COLLECTIBLE_BUMP_ATTACK = Isaac.GetItemIdByName("Bump Attack")
PaperIsaac.COLLECTIBLE_CHILL_OUT = Isaac.GetItemIdByName("Chill Out")
PaperIsaac.COLLECTIBLE_CLOSE_CALL = Isaac.GetItemIdByName("Close Call")
PaperIsaac.COLLECTIBLE_DOUBLE_PAIN = Isaac.GetItemIdByName("Double Pain")
PaperIsaac.TRINKET_FIRE_SHIELD = Isaac.GetTrinketIdByName("Fire Shield")
PaperIsaac.COLLECTIBLE_P_UP_D_DOWN = Isaac.GetItemIdByName("P-Up, D-Down")
PaperIsaac.COLLECTIBLE_REFUND = Isaac.GetItemIdByName("Refund")
PaperIsaac.COLLECTIBLE_RETURN_POSTAGE = Isaac.GetItemIdByName("Return Postage")
PaperIsaac.COLLECTIBLE_SLOW_GO = Isaac.GetItemIdByName("Slow Go")
PaperIsaac.COLLECTIBLE_SPIKE_SHIELD = Isaac.GetItemIdByName("Spike Shield")
PaperIsaac.COLLECTIBLE_SUPER_APPEAL = Isaac.GetItemIdByName("Super Appeal")

SoundEffect.SOUND_SPIKE_SHIELD = Isaac.GetSoundIdByName("spike")

PaperIsaac.COSTUME_PAPER_ISAAC = Isaac.GetCostumeIdByPath("gfx/characters/paperisaacani.anm2")

PaperIsaac.CHALLENGE_PAPER_ISAAC_ALL_BADGES = Isaac.GetChallengeIdByName("Paper Isaac (All)")
PaperIsaac.CHALLENGE_PAPER_ISAAC_NORMAL = Isaac.GetChallengeIdByName("Paper Isaac")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

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

local player
local currFrame = 0

function PaperIsaac:onStart()
	GameState = json.decode(PaperIsaac:LoadData())

	player = Isaac.GetPlayer(0)
	currFrame = Game():GetFrameCount()
	PaperIsaac.COLLECTIBLE_TRANSFORMER = Isaac.GetItemIdByName("Transformer")

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	if not __eidTrinketDescriptions then
		__eidTrinketDescriptions = {}
	end
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_BUMP_ATTACK] = "Don't take contact damage from enemies with max health <= 2/3 your DPS#Touching enemies with max health <= 1/2 your DPS kills them"
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_CHILL_OUT] = "Become immune to all non-self-inflicted damage for 2 seconds upon entering a new room"
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_CLOSE_CALL] = "If your total health is 1.5 hearts or less, there is a 1/3 chance you will avoid damage#Stacks multiplicatively"
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_DOUBLE_PAIN] = "Take double damage"
	__eidTrinketDescriptions[PaperIsaac.TRINKET_FIRE_SHIELD] = "Grants immunity to all fire and fire hazards"
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_P_UP_D_DOWN] = "\1 x2 Damage Multiplier#Take double damage"
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_REFUND] = "Spawns pennies when an active item is used, depending on luck and the item's charge"
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_RETURN_POSTAGE] = "Deal 3x your DPS to anything that hurts you"
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_SLOW_GO] = "\2 -50% Speed multiplier"
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_SPIKE_SHIELD] = "Grants immunity to all spikes and spike hazards except sacrifice rooms"
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_SUPER_APPEAL] = "\1 +1.0 Luck Up#An additional +0.1 Luck Up upon clearing a room#Room clear bonus caps at 1.5 and decreases by 0.3 upon taking damage"

	GameState.ba_safeBumpValue = initializeVar(GameState.ba_safeBumpValue, 0.66)
	GameState.ba_bumpKillValue = initializeVar(GameState.ba_bumpKillValue, 0.5)
	GameState.co_invincibilityTime = initializeVar(GameState.co_invincibilityTime, 2.0)
	GameState.co_showIcon = initializeVar(GameState.co_showIcon, true)
	GameState.rp_counterDamage = initializeVar(GameState.rp_counterDamage, 3.0)
	GameState.enabledBA = initializeVar(GameState.enabledBA, true)
	GameState.enabledCO = initializeVar(GameState.enabledCO, true)
	GameState.enabledCC = initializeVar(GameState.enabledCC, true)
	GameState.enabledDP = initializeVar(GameState.enabledDP, false)
	GameState.enabledFS = initializeVar(GameState.enabledFS, true)
	GameState.enabledPUDD = initializeVar(GameState.enabledPUDD, true)
	GameState.enabledR = initializeVar(GameState.enabledR, true)
	GameState.enabledRP = initializeVar(GameState.enabledRP, true)
	GameState.enabledSG = initializeVar(GameState.enabledSG, false)
	GameState.enabledSS = initializeVar(GameState.enabledSS, true)
	GameState.enabledSA = initializeVar(GameState.enabledSA, true)

	if not alreadyPlayedOnceOnBoot then
		if ModConfigMenu then
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledBA
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledBA then
						choice = "Enabled"
					end
					return "Bump Attack: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.enabledBA = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, Bump Attack will not spawn."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledCO
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledCO then
						choice = "Enabled"
					end
					return "Chill Out: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.enabledCO = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, Chill Out will not spawn."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledCC
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledCC then
						choice = "Enabled"
					end
					return "Close Call: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.enabledCC = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, Close Call will not spawn."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledDP
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledDP then
						choice = "Enabled"
					end
					return "Double Pain: " .. choice
				end,
				Default = false,
				OnChange = function(currentBool)
					GameState.enabledDP = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, Double Pain will not spawn."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledFS
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledFS then
						choice = "Enabled"
					end
					return "Fire Shield: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.enabledFS = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, Fire Shield will not spawn."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledPUDD
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledPUDD then
						choice = "Enabled"
					end
					return "P-Up, D-Down: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.enabledPUDD = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, P-Up, D-Down will not spawn."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledR
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledR then
						choice = "Enabled"
					end
					return "Refund: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.enabledR = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, Refund will not spawn."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledRP
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledRP then
						choice = "Enabled"
					end
					return "Return Postage: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.enabledRP = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, Return Postage will not spawn."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledSG
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledSG then
						choice = "Enabled"
					end
					return "Slow Go: " .. choice
				end,
				Default = false,
				OnChange = function(currentBool)
					GameState.enabledSG = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, Slow Go will not spawn."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledSS
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledSS then
						choice = "Enabled"
					end
					return "Spike Shield: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.enabledSS = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, Spike Shield will not spawn."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledSA
				end,
				Display = function()
					local choice = "Disabled"
					if GameState.enabledSA then
						choice = "Enabled"
					end
					return "Super Appeal: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.enabledSA = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"If disabled, Super Appeal will not spawn."
				}
			})
			ModConfigMenu.AddText("Paper Isaac", "Values", "Bump Attack")
			ModConfigMenu.AddSetting("Paper Isaac", "Values", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.ba_safeBumpValue
				end,
				Display = function()
					return "Safe Bump Value: " .. GameState.ba_safeBumpValue .. "x DPS"
				end,
				Minimum = 0.01,
				Maximum = 1,
				ModifyBy = 0.01,
				Default = 0.66,
				OnChange = function(currentNum)
					GameState.ba_safeBumpValue = currentNum
					GameState.ba_bumpKillValue = math.min(GameState.ba_safeBumpValue, GameState.ba_bumpKillValue)
					PaperIsaac:onExit()
				end,
				Info = {
					"Set the max health of an enemy (relative to",
					"your DPS) needed to safely bump into it."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Values", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.ba_bumpKillValue
				end,
				Display = function()
					return "Bump-Kill Value: " .. GameState.ba_bumpKillValue .. "x DPS"
				end,
				Minimum = 0.01,
				Maximum = 1,
				ModifyBy = 0.01,
				Default = 0.5,
				OnChange = function(currentNum)
					GameState.ba_bumpKillValue = currentNum
					GameState.ba_safeBumpValue = math.max(GameState.ba_safeBumpValue, GameState.ba_bumpKillValue)
					PaperIsaac:onExit()
				end,
				Info = {
					"Set the max health of an enemy (relative",
					"to your DPS) needed to bump-kill it."
				}
			})
			ModConfigMenu.AddSpace("Paper Isaac", "Values")
			ModConfigMenu.AddText("Paper Isaac", "Values", "Chill Out")
			ModConfigMenu.AddSetting("Paper Isaac", "Values", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.co_invincibilityTime
				end,
				Display = function()
					return "Invincibility Time: " .. GameState.co_invincibilityTime .. " seconds"
				end,
				Minimum = 0.1,
				Maximum = 5,
				ModifyBy = 0.1,
				Default = 2.0,
				OnChange = function(currentNum)
					GameState.co_invincibilityTime = currentNum
					PaperIsaac:onExit()
				end,
				Info = {
					"Set the amount of invincibility",
					"time upon entering a new room."
				}
			})
			ModConfigMenu.AddSetting("Paper Isaac", "Values", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.co_showIcon
				end,
				Display = function()
					local choice = "False"
					if GameState.co_showIcon then
						choice = "True"
					end
					return "Show \"!\" Icon: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.co_showIcon = currentBool
					PaperIsaac:onExit()
				end,
				Info = {
					"Set whether or not the \"!\"",
					"appears during invincibility."
				}
			})
			ModConfigMenu.AddSpace("Paper Isaac", "Values")
			ModConfigMenu.AddText("Paper Isaac", "Values", "Return Postage")
			ModConfigMenu.AddSetting("Paper Isaac", "Values", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.rp_counterDamage
				end,
				Display = function()
					return "Counter Damage: " .. GameState.rp_counterDamage .. "x DPS"
				end,
				Minimum = 0.1,
				Maximum = 5,
				ModifyBy = 0.1,
				Default = 3.0,
				OnChange = function(currentNum)
					GameState.rp_counterDamage = currentNum
					PaperIsaac:onExit()
				end,
				Info = {
					"Set the amount of damage (relative to",
					"your DPS) dealt by Return Postage."
				}
			})
		end
		alreadyPlayedOnceOnBoot = true
	end

	if currFrame < 5 then
		if not GameState.enabledBA then
			Game():GetItemPool():RemoveCollectible(PaperIsaac.COLLECTIBLE_BUMP_ATTACK)
		end
		if not GameState.enabledCO then
			Game():GetItemPool():RemoveCollectible(PaperIsaac.COLLECTIBLE_CHILL_OUT)
		end
		if not GameState.enabledCC then
			Game():GetItemPool():RemoveCollectible(PaperIsaac.COLLECTIBLE_CLOSE_CALL)
		end
		if not GameState.enabledDP then
			Game():GetItemPool():RemoveCollectible(PaperIsaac.COLLECTIBLE_DOUBLE_PAIN)
		end
		if not GameState.enabledFS then
			Game():GetItemPool():RemoveTrinket(PaperIsaac.TRINKET_FIRE_SHIELD)
		end
		if not GameState.enabledPUDD then
			Game():GetItemPool():RemoveCollectible(PaperIsaac.COLLECTIBLE_P_UP_D_DOWN)
		end
		if not GameState.enabledR then
			Game():GetItemPool():RemoveCollectible(PaperIsaac.COLLECTIBLE_REFUND)
		end
		if not GameState.enabledRP then
			Game():GetItemPool():RemoveCollectible(PaperIsaac.COLLECTIBLE_RETURN_POSTAGE)
		end
		if not GameState.enabledSG then
			Game():GetItemPool():RemoveCollectible(PaperIsaac.COLLECTIBLE_SLOW_GO)
		end
		if not GameState.enabledSS then
			Game():GetItemPool():RemoveCollectible(PaperIsaac.COLLECTIBLE_SPIKE_SHIELD)
		end
		if not GameState.enabledSA then
			Game():GetItemPool():RemoveCollectible(PaperIsaac.COLLECTIBLE_SUPER_APPEAL)
		end
	end

	if currFrame < 5 and Game().Challenge == PaperIsaac.CHALLENGE_PAPER_ISAAC_ALL_BADGES then
		custAddItem(PaperIsaac.COLLECTIBLE_BUMP_ATTACK, false)
		custAddItem(PaperIsaac.COLLECTIBLE_CHILL_OUT, false)
		custAddItem(PaperIsaac.COLLECTIBLE_CLOSE_CALL, false)
		custAddItem(PaperIsaac.TRINKET_FIRE_SHIELD, true)
		custAddItem(PaperIsaac.COLLECTIBLE_P_UP_D_DOWN, false)
		custAddItem(PaperIsaac.COLLECTIBLE_REFUND, false)
		custAddItem(PaperIsaac.COLLECTIBLE_RETURN_POSTAGE, false)
		custAddItem(PaperIsaac.COLLECTIBLE_SPIKE_SHIELD, false)
		custAddItem(PaperIsaac.COLLECTIBLE_SUPER_APPEAL, false)
	end
	if currFrame < 5 and Game().Challenge == PaperIsaac.CHALLENGE_PAPER_ISAAC_NORMAL then
		custAddItem(PaperIsaac.TRINKET_FIRE_SHIELD, true)
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
	end
end

function initializeVar(var, value)
	if var == nil then
		var = value
	end
	return var
end

function PaperIsaac:onExit(save)
	for i=1,GameState.r_highestID do
		if GameState.r_activeItems[i] == nil then
			GameState.r_activeItems[i] = 0
		end
	end
	PaperIsaac:SaveData(json.encode(GameState))
end

function PaperIsaac:onRender()
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

function PaperIsaac:onUpdate()
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
					custAddItem(PaperIsaac.COLLECTIBLE_BUMP_ATTACK, false)
					choseBA = true
					challengeCount = challengeCount + 1
				end
				if not choseCO and Input.IsActionPressed(ButtonAction.ACTION_LEFT, controllerId) then
					custAddItem(PaperIsaac.COLLECTIBLE_CHILL_OUT, false)
					choseCO = true
					challengeCount = challengeCount + 1
				end
				if not choseCC and Input.IsActionPressed(ButtonAction.ACTION_RIGHT, controllerId) then
					custAddItem(PaperIsaac.COLLECTIBLE_CLOSE_CALL, false)
					choseCC = true
					challengeCount = challengeCount + 1
				end
				if not chosePUDD and Input.IsActionPressed(ButtonAction.ACTION_DOWN, controllerId) then
					custAddItem(PaperIsaac.COLLECTIBLE_P_UP_D_DOWN, false)
					chosePUDD = true
					challengeCount = challengeCount + 1
				end
				if not choseR and Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, controllerId) then
					custAddItem(PaperIsaac.COLLECTIBLE_REFUND, false)
					choseR = true
					challengeCount = challengeCount + 1
				end
				if not choseRP and Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, controllerId) then
					custAddItem(PaperIsaac.COLLECTIBLE_RETURN_POSTAGE, false)
					choseRP = true
					challengeCount = challengeCount + 1
				end
				if not choseSS and Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, controllerId) then
					custAddItem(PaperIsaac.COLLECTIBLE_SPIKE_SHIELD, false)
					choseSS = true
					challengeCount = challengeCount + 1
				end
				if not choseSA and Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, controllerId) then
					custAddItem(PaperIsaac.COLLECTIBLE_SUPER_APPEAL, false)
					choseSA = true
					challengeCount = challengeCount + 1
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
	if not isTrinket then
		player:AddCollectible(itemID, 0, false)
		Game():GetItemPool():RemoveCollectible(itemID)
	else
		player:AddTrinket(itemID)
		Game():GetItemPool():RemoveTrinket(itemID)
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, PaperIsaac.onExit)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_GAME_END, PaperIsaac.onExit)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_UPDATE, PaperIsaac.onUpdate)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_RENDER, PaperIsaac.onRender)

function hasBit(var, bit)
	if var == nil then
		return false
	end
	return var % (bit + bit) >= bit
end



-- Bump Attack --

local ba_lastBumpKilledFrame = 0
local ba_range = 33
local ba_safeColor = Color(0.75, 1, 0, 1.0, 0, 0, 0)
local ba_killColor = Color(0, 1, 0, 1.0, 0, 0, 0)

function PaperIsaac:ba_onStart()
	ba_lastBumpKilledFrame = 0
end

function PaperIsaac:ba_onUpdate()
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		-- Vulnerable enemies that do not deal contact damage (and therefore cannot call ba_bump())
		if entity:IsVulnerableEnemy() and entity.CollisionDamage == 0 then
			local inRange = false
			if entity.Type == 293 then
				inRange = math.abs(entity.Position.X - player.Position.X) < ba_range + 6 and math.abs(entity.Position.Y - player.Position.Y) < ba_range + 6
			else
				inRange = math.abs(entity.Position.X - player.Position.X) < ba_range and math.abs(entity.Position.Y - player.Position.Y) < ba_range
			end
			if inRange then
				local entityHolder = EntityRef(entity)
				-- print(math.sqrt((player.Position.X-entity.Position.X)^2 + (player.Position.Y-entity.Position.Y)^2))
				PaperIsaac:ba_bump(player,nil,nil,entityHolder,nil)
			end
		end
	end
end

function PaperIsaac:ba_onNPCUpdate(entity)
	if Game():GetPlayer(1):HasCollectible(PaperIsaac.COLLECTIBLE_BUMP_ATTACK) then
		if entity.Type and entity:IsVulnerableEnemy() and not entity:IsBoss() and not (entity.Type == 39 and entity.Variant == 22) and entity.Type ~= 33 and entity.Type < 1000 then
			local tearDamage = player.Damage
			local tearDelay = player.MaxFireDelay
			local dps = tearDamage*math.ceil(30/tearDelay)
			local bumpValue = PaperIsaac:getBumpValue(dps, entity.MaxHitPoints)
			if bumpValue == 2 then
				entity:SetColor(ba_killColor, 65535, 0, false, false)
			elseif bumpValue == 1 then
				entity:SetColor(ba_safeColor, 65535, 0, false, false)
			end
		end
	end
end

-- 0 = no effect, 1 = can safely touch enemy, 2 = can kill enemy by touching
function PaperIsaac:getBumpValue(dps, enemyMaxHealth)
	if dps * GameState.ba_safeBumpValue >= enemyMaxHealth then
		if dps * GameState.ba_bumpKillValue >= enemyMaxHealth then
			return 2
		end
		return 1
	end
	return 0
end

function PaperIsaac:ba_cacheUpdate(player, flag)
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_BUMP_ATTACK) then
		if flag == CacheFlag.CACHE_DAMAGE then
			for _, entity in pairs(Isaac.GetRoomEntities()) do
				PaperIsaac:ba_onNPCUpdate(entity)
			end
		end
		if flag == CacheFlag.CACHE_FIREDELAY then
			for _, entity in pairs(Isaac.GetRoomEntities()) do
				PaperIsaac:ba_onNPCUpdate(entity)
			end
		end
	end
end

function PaperIsaac:ba_bump(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_BUMP_ATTACK) then
		if damageFlag ~= DamageFlag.DAMAGE_FAKE then
			if currFrame <= ba_lastBumpKilledFrame + 5 then
				return false
			end
			if not hasBit(damageFlag, DamageFlag.DAMAGE_EXPLOSION) and not hasBit(damageFlag, DamageFlag.DAMAGE_LASER) and not hasBit(damageFlag, DamageFlag.DAMAGE_FIRE) and damageSource and damageSource.Entity and damageSource.Entity:IsVulnerableEnemy() and not damageSource.Entity:IsBoss() and not (damageSource.Type == 39 and damageSource.Variant == 22) and damageSource.Type < 1000 then
				local tearDamage = player.Damage
				local tearDelay = player.MaxFireDelay
				local dps = tearDamage*math.ceil(30/tearDelay)
				local bumpValue = PaperIsaac:getBumpValue(dps, damageSource.Entity.MaxHitPoints)
				-- print("START")
				-- print(dps)
				-- print(damageSource.Entity.MaxHitPoints)
				-- print(bumpValue)
				if bumpValue >= 1 then
					if bumpValue == 2 then
						for _, entity in pairs(Isaac.GetRoomEntities()) do
							if entity.Type == damageSource.Entity.Type and entity.Variant == damageSource.Entity.Variant and entity.Position.X == damageSource.Entity.Position.X and entity.Position.Y == damageSource.Entity.Position.Y then
								ba_lastBumpKilledFrame = currFrame
								entity:Kill()
								break
							end
						end
					end
					return false
				end
			end
		end
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.ba_onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_UPDATE, PaperIsaac.ba_onUpdate)
PaperIsaac:AddCallback(ModCallbacks.MC_NPC_UPDATE, PaperIsaac.ba_onNPCUpdate)
PaperIsaac:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, PaperIsaac.ba_cacheUpdate)
PaperIsaac:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperIsaac.ba_bump, EntityType.ENTITY_PLAYER)



-- Chill Out --

local co_roomEnterFrame
local co_canRenderText = false

function PaperIsaac:co_onRender()
	if GameState.co_showIcon then
		local co_numSafeFrames = GameState.co_invincibilityTime * 30
		local co_numRenderFrames1 = GameState.co_invincibilityTime * 18 -- number of frames that the ! will stay solid
		local co_numRenderFrames2 = co_numSafeFrames - co_numRenderFrames1 -- number of frames that the ! will fade out before the Chill Out effect expires
		if co_canRenderText and currFrame <= co_roomEnterFrame + co_numSafeFrames and currFrame ~= co_roomEnterFrame then
			local playerPos = Game():GetRoom():WorldToScreenPosition(player.Position)
			if currFrame < co_roomEnterFrame + co_numRenderFrames1 then
				Isaac.RenderText("!", playerPos.X-3, playerPos.Y-40, 1, 1, 1, 1)
			else
				Isaac.RenderText("!", playerPos.X-3, playerPos.Y-40, 1, 1, 1, 1-((currFrame-co_roomEnterFrame-co_numRenderFrames1)/co_numRenderFrames2))
			end
		end
	end
end

function PaperIsaac:co_onNewRoom()
	co_roomEnterFrame = currFrame
	co_canRenderText = player:HasCollectible(PaperIsaac.COLLECTIBLE_CHILL_OUT)
end

function PaperIsaac:co_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_CHILL_OUT) then
		if currFrame <= co_roomEnterFrame + GameState.co_invincibilityTime * 30 and (damageSource == nil or ((damageSource.Entity == nil or damageSource.Entity.SpawnerType ~= EntityType.ENTITY_PLAYER) and (damageSource.Type ~= EntityType.ENTITY_PLAYER))) and not hasBit(damageFlag, DamageFlag.DAMAGE_RED_HEARTS) and not hasBit(damageFlag, DamageFlag.DAMAGE_FAKE) and not hasBit(damageFlag, DamageFlag.DAMAGE_CURSED_DOOR) and not hasBit(damageFlag, DamageFlag.DAMAGE_CHEST) and not hasBit(damageFlag, DamageFlag.DAMAGE_INVINCIBLE) and not hasBit(damageFlag, DamageFlag.DAMAGE_TIMER) then
			return false
		end
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_RENDER, PaperIsaac.co_onRender)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, PaperIsaac.co_onNewRoom)
PaperIsaac:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperIsaac.co_onHit, EntityType.ENTITY_PLAYER)



-- Close Call --

local cc_lastSafeFrame
local cc_safeColor = Color(1, 0.898, 0.396, 1, 0, 0, 0)
local cc_numSafeFrames = 30

function PaperIsaac:cc_onStart()
	cc_lastSafeFrame = 0
end

function PaperIsaac:cc_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_CLOSE_CALL) and not hasBit(damageFlag, DamageFlag.DAMAGE_FAKE) and not (hasBit(damageFlag, DamageFlag.DAMAGE_SPIKES) and Game():GetRoom():GetType() == RoomType.ROOM_SACRIFICE) then
		if currFrame < cc_lastSafeFrame + cc_numSafeFrames then
			return false
		end
		if player:GetHearts() + player:GetSoulHearts() <= 3 and math.random(1000) > (2/3)^player:GetCollectibleNum(PaperIsaac.COLLECTIBLE_CLOSE_CALL)*1000 then
			cc_lastSafeFrame = currFrame
			player:SetColor(cc_safeColor, cc_numSafeFrames, 0, true, false)
			return false
		end
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.cc_onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperIsaac.cc_onHit, EntityType.ENTITY_PLAYER)



-- Double Pain --

local dp_tookDamage = false

function PaperIsaac:dp_onStart()
	dp_tookDamage = false
end

function PaperIsaac:dp_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if dp_tookDamage then
		dp_tookDamage = false
		return nil
	end
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_DOUBLE_PAIN) then
		dp_tookDamage = true
		player:TakeDamage(damageAmount * 2, damageFlag, damageSource, numCountdownFrames) -- this is supposed to keep the original number of invincibility frames, but it's broken in the API?
		return false
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.dp_onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperIsaac.dp_onHit, EntityType.ENTITY_PLAYER)



-- Fire Shield --

local fs_lastColorFrame = 0
local fs_safeColor = Color(0.886, 0.345, 0.133, 1, 0, 0, 0)
local fs_numColorFrames = 15
local fs_onFire = false

function PaperIsaac:fs_onStart()
	fs_lastColorFrame = 0
end

function PaperIsaac:fs_onUpdate()
	if fs_onFire and currFrame > fs_lastColorFrame + 1 then
		player:SetColor(fs_safeColor, fs_numColorFrames, 0, true, false)
		fs_onFire = false
	end
end

function PaperIsaac:fs_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	-- print(damageSource.Type)
	-- print(damageSource.Variant)
	-- print(damageFlag)
	if player:HasTrinket(PaperIsaac.TRINKET_FIRE_SHIELD) then
		if hasBit(damageFlag, DamageFlag.DAMAGE_FIRE) or (damageSource ~= nil and (damageSource.Type == EntityType.ENTITY_FIREPLACE or (damageSource.Type == EntityType.ENTITY_PROJECTILE and damageSource.Variant == ProjectileVariant.PROJECTILE_FIRE) or (damageSource.Entity ~= nil and damageSource.Entity:ToProjectile() ~= nil and damageSource.Entity:ToProjectile().ProjectileFlags == ProjectileFlags.FIRE))) then
			fs_lastColorFrame = currFrame
			player:SetColor(fs_safeColor, 1, 0, false, false)
			fs_onFire = true
			return false
		end
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.fs_onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_UPDATE, PaperIsaac.fs_onUpdate)
PaperIsaac:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperIsaac.fs_onHit, EntityType.ENTITY_PLAYER)



-- P-Up, D-Down

local pudd_tookDamage = false

function PaperIsaac:pudd_onStart()
	pudd_tookDamage = false
end

function PaperIsaac:pudd_cacheUpdate(player, flag)
	if flag == CacheFlag.CACHE_DAMAGE and player:HasCollectible(PaperIsaac.COLLECTIBLE_P_UP_D_DOWN) then
		player.Damage = player.Damage * 2
	end
end

function PaperIsaac:pudd_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if pudd_tookDamage then
		-- print("START")
		-- print(damageAmount) -- 1 per half heart
		-- print(currFrame)
		-- print(numCountdownFrames)
		pudd_tookDamage = false
		return nil
	end
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_P_UP_D_DOWN) then
		pudd_tookDamage = true
		player:TakeDamage(damageAmount * 2, damageFlag, damageSource, numCountdownFrames) -- this is supposed to keep the original number of invincibility frames, but it's broken in the API?
		return false
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.pudd_onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperIsaac.pudd_onHit, EntityType.ENTITY_PLAYER)
PaperIsaac:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, PaperIsaac.pudd_cacheUpdate)



-- Refund --

function PaperIsaac:r_onStart()
	if currFrame < 5 then
		GameState.r_activeItems = {}
		GameState.r_highestID = -1
	end
end

function PaperIsaac:r_spawnCoins()
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_REFUND) then
		local chargeTime = player:GetActiveCharge()
		local activeItem = player:GetActiveItem()
		GameState.r_highestID = math.max(GameState.r_highestID, activeItem)
		if GameState.r_activeItems[activeItem] == nil then
			GameState.r_activeItems[activeItem] = 0
		end
		-- timed items, Breath of Life, and Isaac's Tears (which technically aren't timed items, but are easily infinitely reusable)
		if chargeTime > 12 or activeItem == CollectibleType.COLLECTIBLE_BREATH_OF_LIFE or activeItem == CollectibleType.COLLECTIBLE_ISAACS_TEARS then -- or (chargeTime == 1 and Isaac.GetPlayer(0):GetCollectibleNum(CollectibleType.COLLECTIBLE_NINE_VOLT))
			chargeTime = 0
		end
		local luck = player.Luck
		local numCoins = PaperIsaac:getNumCoins(chargeTime, luck)
		for i=1,numCoins do
			if GameState.r_activeItems[activeItem] < 15 then
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, Isaac.GetFreeNearPosition(Vector(player.Position.X, player.Position.Y), 0), Vector(0,0), player)
				GameState.r_activeItems[activeItem] = GameState.r_activeItems[activeItem] + 1
			end
		end
	end
end

function PaperIsaac:getNumCoins(chargeTime, luck)
	local numPaperIsaacs = player:GetCollectibleNum(PaperIsaac.COLLECTIBLE_REFUND)
	local value = chargeTime*(1/3)*(1 + (1/6)*(luck+1)) * 1.3^(numPaperIsaacs-1) -- Matches Sack of Pennies (one penny every two rooms) at 2 luck (assuming no 9 Volt, AAA Battery, Car Battery, etc)
	-- Example: if value == 2.4, then there is a 40% chance it will go up to 3, or 60% chance it will go down to 2
	if math.random(1000) <= (value%1)*1000 then
		value = math.ceil(value)
	else
		value = math.floor(value)
	end
	-- return math.min(value, 3)
	return value
end

-- Using Void activates the MC_USE_ITEM callback for itself and every absorbed item. This method only activates the PaperIsaac for Void itself and ignores absorbed items.
function PaperIsaac:r_useNonVoidItem()
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
		PaperIsaac:r_spawnCoins()
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.r_onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_USE_ITEM, PaperIsaac.r_spawnCoins, CollectibleType.COLLECTIBLE_VOID)
PaperIsaac:AddCallback(ModCallbacks.MC_USE_ITEM, PaperIsaac.r_useNonVoidItem)



-- Return Postage --

function PaperIsaac:rp_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	-- print(damageSource.SpawnerType)
	-- print(damageSource.SpawnerVariant)
	-- print(damageSource.Entity.SpawnerType) -- the type of enemy that spawned the entity (0 if nothing spawned it)
	-- print(damageSource.Entity.SpawnerVariant) -- the variant of enemy that spawned the entity (0 if nothing spawned it or default variant)
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_RETURN_POSTAGE) and not hasBit(damageFlag, DamageFlag.DAMAGE_FAKE) and damageSource and damageSource.Entity and damageSource.Type ~= EntityType.ENTITY_PLAYER and damageSource.Entity.SpawnerType ~= EntityType.ENTITY_PLAYER and damageSource.Type < 1000 then
		local hitByProjectile = damageSource.Entity.Type == EntityType.ENTITY_PROJECTILE or damageSource.Entity.Type == EntityType.ENTITY_BOMBDROP or damageSource.Entity.Type == EntityType.ENTITY_LASER or (damageSource.Entity.SpawnerType ~= 0 and not (damageSource.Entity:IsVulnerableEnemy() and not (damageSource.Type == 39 and damageSource.Variant == 22)))
		local entityToAttack = nil
		local entityToAttackDist = 999
		for _, entity in pairs(Isaac.GetRoomEntities()) do
			if hitByProjectile then
				if entity.Type == damageSource.Entity.SpawnerType and entity.Variant == damageSource.Entity.SpawnerVariant then
					local dist = math.sqrt((entity.Position.X - player.Position.X)^2 + (entity.Position.Y - player.Position.Y)^2)
					if entityToAttack == nil or dist < entityToAttackDist then
						entityToAttack = entity
						entityToAttackDist = dist
					end
				end
			elseif entity.Type == damageSource.Entity.Type and entity.Variant == damageSource.Entity.Variant and entity.Position.X == damageSource.Entity.Position.X and entity.Position.Y == damageSource.Entity.Position.Y then
				PaperIsaac:hurtEnemy(entity, damageFlag, numCountdownFrames)
				break
			end
		end
		if entityToAttack ~= nil then
			PaperIsaac:hurtEnemy(entityToAttack, damageFlag, numCountdownFrames)
		end
	end
end

function PaperIsaac:hurtEnemy(entity, damageFlag, numCountdownFrames)
	local dpsVal = player.Damage*math.ceil(GameState.rp_counterDamage*30/player.MaxFireDelay)
	entity:TakeDamage(dpsVal, damageFlag, EntityRef(player), numCountdownFrames)
end

PaperIsaac:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperIsaac.rp_onHit, EntityType.ENTITY_PLAYER)



-- Slow Go --

function PaperIsaac:sg_cacheUpdate(player, flag)
	if flag == CacheFlag.CACHE_SPEED and player:HasCollectible(PaperIsaac.COLLECTIBLE_SLOW_GO) then
		player.MoveSpeed = player.MoveSpeed / 2
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, PaperIsaac.sg_cacheUpdate)



-- Spike Shield --

local ss_lastDamageFrame = 0

function PaperIsaac:ss_onStart()
	ss_lastDamageFrame = 0
end

function PaperIsaac:ss_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_SPIKE_SHIELD) then
		if (hasBit(damageFlag, DamageFlag.DAMAGE_SPIKES) and Game():GetRoom():GetType() ~= RoomType.ROOM_SACRIFICE) or hasBit(damageFlag, DamageFlag.DAMAGE_CURSED_DOOR) or hasBit(damageFlag, DamageFlag.DAMAGE_CHEST) or damageSource.Type == 44 or damageSource.Type == 218 then
			if currFrame > ss_lastDamageFrame + 1 then
				SFXManager():Play(SoundEffect.SOUND_SPIKE_SHIELD, 1, 0, false, 1)
			end
			ss_lastDamageFrame = currFrame
			return false
		end
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.ss_onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperIsaac.ss_onHit, EntityType.ENTITY_PLAYER)



-- Super Appeal --

local sa_initLuckUp = 1
local sa_roomLuckBonus = 0.1
local sa_roomPenalty = 3
local sa_maxRooms = 15

function PaperIsaac:sa_onStart()
	if currFrame < 5 then
		GameState.sa_numRooms = 0
		GameState.sa_currRoom = Game():GetRoom()
		GameState.sa_inSafeRoom = GameState.sa_currRoom:IsClear()
		GameState.sa_hadSA = false
	end
end

function PaperIsaac:sa_onUpdate()
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_SUPER_APPEAL) then
		if not GameState.sa_inSafeRoom and GameState.sa_currRoom:IsClear() and GameState.sa_hadSA then
			GameState.sa_numRooms = math.min(GameState.sa_numRooms + 1, sa_maxRooms)
			GameState.sa_inSafeRoom = true
			player:AddCacheFlags(CacheFlag.CACHE_LUCK)
			player:EvaluateItems()
		end
	end
end

function PaperIsaac:sa_onNewRoom()
	GameState.sa_currRoom = Game():GetRoom()
	GameState.sa_inSafeRoom = GameState.sa_currRoom:IsClear()
	GameState.sa_hadSA = Isaac.GetPlayer(0):HasCollectible(PaperIsaac.COLLECTIBLE_SUPER_APPEAL)
end

function PaperIsaac:sa_loseBonus(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_SUPER_APPEAL) and not hasBit(damageFlag, DamageFlag.DAMAGE_FAKE) then
		GameState.sa_numRooms = math.max(GameState.sa_numRooms - sa_roomPenalty, 0)
		player:AddCacheFlags(CacheFlag.CACHE_LUCK)
		player:EvaluateItems()
	end
end

function PaperIsaac:sa_cacheUpdate(player, flag)
	if player:HasCollectible(PaperIsaac.COLLECTIBLE_SUPER_APPEAL) and flag == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + (player:GetCollectibleNum(PaperIsaac.COLLECTIBLE_SUPER_APPEAL) * sa_initLuckUp) + (GameState.sa_numRooms * sa_roomLuckBonus)
    end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.sa_onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_UPDATE, PaperIsaac.sa_onUpdate)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, PaperIsaac.sa_onNewRoom)
PaperIsaac:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, PaperIsaac.sa_cacheUpdate)
PaperIsaac:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperIsaac.sa_loseBonus, EntityType.ENTITY_PLAYER)



-- Paper Transformation --

function PaperIsaac:pt_onStart()
	if currFrame < 5 then
		GameState.pt_hadBA = 0
		GameState.pt_hadCO = 0
		GameState.pt_hadCC = 0
		GameState.pt_hadDP = 0
		GameState.pt_hadPUDD = 0
		GameState.pt_hadR = 0
		GameState.pt_hadRP = 0
		GameState.pt_hadSG = 0
		GameState.pt_hadSS = 0
		GameState.pt_hadSA = 0
		GameState.pt_hadT = 0
		GameState.pt_transformed = false
	end
end

function PaperIsaac:pt_onUpdate()
	if not GameState.pt_transformed then
		GameState.pt_hadBA = checkItemForTF(PaperIsaac.COLLECTIBLE_BUMP_ATTACK, GameState.pt_hadBA, player)
		GameState.pt_hadCO = checkItemForTF(PaperIsaac.COLLECTIBLE_CHILL_OUT, GameState.pt_hadCO, player)
		GameState.pt_hadCC = checkItemForTF(PaperIsaac.COLLECTIBLE_CLOSE_CALL, GameState.pt_hadCC, player)
		GameState.pt_hadDP = checkItemForTF(PaperIsaac.COLLECTIBLE_DOUBLE_PAIN, GameState.pt_hadDP, player)
		GameState.pt_hadPUDD = checkItemForTF(PaperIsaac.COLLECTIBLE_P_UP_D_DOWN, GameState.pt_hadPUDD, player)
		GameState.pt_hadR = checkItemForTF(PaperIsaac.COLLECTIBLE_REFUND, GameState.pt_hadR, player)
		GameState.pt_hadRP = checkItemForTF(PaperIsaac.COLLECTIBLE_RETURN_POSTAGE, GameState.pt_hadRP, player)
		GameState.pt_hadSG = checkItemForTF(PaperIsaac.COLLECTIBLE_SLOW_GO, GameState.pt_hadSG, player)
		GameState.pt_hadSS = checkItemForTF(PaperIsaac.COLLECTIBLE_SPIKE_SHIELD, GameState.pt_hadSS, player)
		GameState.pt_hadSA = checkItemForTF(PaperIsaac.COLLECTIBLE_SUPER_APPEAL, GameState.pt_hadSA, player)
		if PaperIsaac.COLLECTIBLE_TRANSFORMER ~= -1 and player:HasCollectible(PaperIsaac.COLLECTIBLE_TRANSFORMER) then
			GameState.pt_hadT = math.max(GameState.pt_hadT, player:GetCollectibleNum(PaperIsaac.COLLECTIBLE_TRANSFORMER))
		end

		if GameState.pt_hadBA + GameState.pt_hadCO + GameState.pt_hadCC + GameState.pt_hadDP + GameState.pt_hadPUDD + GameState.pt_hadR + GameState.pt_hadRP + GameState.pt_hadSG + GameState.pt_hadSS + GameState.pt_hadSA + GameState.pt_hadT >= 3 then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, player.Position, Vector(0,0), nil)
			SFXManager():Play(SoundEffect.SOUND_POWERUP_SPEWER, 1, 0, false, 1)
			player:AddNullCostume(PaperIsaac.COSTUME_PAPER_ISAAC)
			GameState.pt_transformed = true
			player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
			player:AddCacheFlags(CacheFlag.CACHE_TEARCOLOR)
			player:EvaluateItems()
		end
	end
end

function checkItemForTF(itemID, itemVar, p)
	if p:HasCollectible(itemID) and itemVar == 0 then
		itemVar = 1
	end
	return itemVar
end

function PaperIsaac:pt_cacheUpdate(player, flag)
	if GameState.pt_transformed then
		if flag == CacheFlag.CACHE_SHOTSPEED then
			player.ShotSpeed = player.ShotSpeed + 0.16
		end
		if flag == CacheFlag.CACHE_TEARCOLOR then
			player.TearColor = Color(1, 1, 1, 1, 0, 0, 0)
		end
	end
end

function PaperIsaac:pt_checkForBleeding(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if GameState.pt_transformed and damageSource.Type == EntityType.ENTITY_TEAR and target:IsVulnerableEnemy() and not (target.Type == 39 and target.Variant == 22) and math.random(5) == 1 then
		for _, entity in pairs(Isaac.GetRoomEntities()) do
			if entity.Type == damageSource.Entity.Type and entity.Variant == damageSource.Entity.Variant and entity.Position.X == damageSource.Entity.Position.X and entity.Position.Y == damageSource.Entity.Position.Y then
				target:TakeDamage(player.Damage * 0.5, 0, damageSource, 0)
				if not target:IsBoss() then
					target:AddEntityFlags(EntityFlag.FLAG_BLEED_OUT)
				end
				break
			end
		end
	end
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.pt_onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_UPDATE, PaperIsaac.pt_onUpdate)
PaperIsaac:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, PaperIsaac.pt_cacheUpdate)
PaperIsaac:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PaperIsaac.pt_checkForBleeding)