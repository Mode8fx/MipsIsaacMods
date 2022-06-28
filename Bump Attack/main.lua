BumpAttack = RegisterMod("Bump Attack", 1)

BumpAttack.COLLECTIBLE_BUMP_ATTACK = Isaac.GetItemIdByName("Bump Attack")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local players = {}
local currFrame = 0

function BumpAttack:onStart()
	if BumpAttack:HasData() then
		GameState = json.decode(BumpAttack:LoadData())
	else
		GameState = {}
	end

	players = getPlayers()
	currFrame = 0

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[BumpAttack.COLLECTIBLE_BUMP_ATTACK] = "Don't take contact damage from enemies with max health <= 2/3 your DPS#Touching enemies with max health <= 1/2 your DPS kills them"

	GameState.ba_safeBumpValue = initializeVar(GameState.ba_safeBumpValue, 0.66)
	GameState.ba_bumpKillValue = initializeVar(GameState.ba_bumpKillValue, 0.5)

	if not alreadyPlayedOnceOnBoot then
		BumpAttack:ba_addMCMOptions()
		alreadyPlayedOnceOnBoot = true
	end
end

function BumpAttack:ba_addMCMOptions()
	if ModConfigMenu then
		ModConfigMenu.AddSetting("Bump Attack", { 
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
				BumpAttack:onExit()
			end,
			Info = {
				"Set the max health of an enemy (relative to",
				"your DPS) needed to safely bump into it."
			}
		})
		ModConfigMenu.AddSpace("Bump Attack")
		ModConfigMenu.AddSetting("Bump Attack", { 
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
				BumpAttack:onExit()
			end,
			Info = {
				"Set the max health of an enemy (relative",
				"to your DPS) needed to bump-kill it."
			}
		})
	end
end

function initializeVar(var, value)
	if var == nil then
		var = value
	end
	return var
end

function BumpAttack:onExit(save)
	BumpAttack:SaveData(json.encode(GameState))
end

function BumpAttack:onUpdate()
	currFrame = Game():GetFrameCount()
end

BumpAttack:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, BumpAttack.onStart)
BumpAttack:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, BumpAttack.onExit)
BumpAttack:AddCallback(ModCallbacks.MC_POST_GAME_END, BumpAttack.onExit)
BumpAttack:AddCallback(ModCallbacks.MC_POST_UPDATE, BumpAttack.onUpdate)

function hasBit(var, bit)
	if var == nil then
		return false
	end
	return var % (bit + bit) >= bit
end

local ba_lastBumpKilledFrame = {0,0,0,0,0,0,0,0}
local ba_range = 33
local ba_safeColor = Color(0.75, 1, 0, 1.0, 0, 0, 0)
local ba_killColor = Color(0, 1, 0, 1.0, 0, 0, 0)

function BumpAttack:ba_onStart()
	ba_lastBumpKilledFrame = {0,0,0,0,0,0,0,0}
end

function BumpAttack:ba_onUpdate()
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		-- Vulnerable enemies that do not deal contact damage (and therefore cannot call ba_bump())
		if entity:IsVulnerableEnemy() and entity.CollisionDamage == 0 then
			for playerNum=1,Game():GetNumPlayers() do
				local inRange = false
				if entity.Type == 293 then
					inRange = math.abs(entity.Position.X - players[playerNum].Position.X) < ba_range + 6 and math.abs(entity.Position.Y - players[playerNum].Position.Y) < ba_range + 6
				else
					inRange = math.abs(entity.Position.X - players[playerNum].Position.X) < ba_range and math.abs(entity.Position.Y - players[playerNum].Position.Y) < ba_range
				end
				if inRange then
					local entityHolder = EntityRef(entity)
					-- print(math.sqrt((players[playerNum].Position.X-entity.Position.X)^2 + (players[playerNum].Position.Y-entity.Position.Y)^2))
					BumpAttack:ba_bump(players[playerNum],nil,nil,entityHolder,nil)
				end
			end
		end
	end
end

function getAverageDPS_AllPlayers()
	local tearDamage = 0
	local tearDelay = 0
	for i=1, #players do
		tearDamage = tearDamage + players[i].Damage
		tearDelay = tearDelay + players[i].MaxFireDelay
	end
	tearDamage = tearDamage / #players
	tearDelay = tearDelay / #players
	return tearDamage*math.ceil(30/tearDelay)
end

function BumpAttack:ba_onNPCUpdate(entity)
	if playersHaveCollectible(BumpAttack.COLLECTIBLE_BUMP_ATTACK) then
		if entity.Type and entity:IsVulnerableEnemy() and not entity:IsBoss() and not (entity.Type == 39 and entity.Variant == 22) and entity.Type ~= 33 and entity.Type < 1000 then
			local dps = getAverageDPS_AllPlayers()
			local bumpValue = BumpAttack:getBumpValue(dps, entity.MaxHitPoints)
			if bumpValue == 2 then
				entity:SetColor(ba_killColor, 65535, 0, false, false)
			elseif bumpValue == 1 then
				entity:SetColor(ba_safeColor, 65535, 0, false, false)
			end
		end
	end
end

-- 0 = no effect, 1 = can safely touch enemy, 2 = can kill enemy by touching
function BumpAttack:getBumpValue(dps, enemyMaxHealth)
	if dps * GameState.ba_safeBumpValue >= enemyMaxHealth then
		if dps * GameState.ba_bumpKillValue >= enemyMaxHealth then
			return 2
		end
		return 1
	end
	return 0
end

function BumpAttack:ba_cacheUpdate(player, flag)
	if playersHaveCollectible(BumpAttack.COLLECTIBLE_BUMP_ATTACK) then
		if flag == CacheFlag.CACHE_DAMAGE then
			for _, entity in pairs(Isaac.GetRoomEntities()) do
				BumpAttack:ba_onNPCUpdate(entity)
			end
		end
		if flag == CacheFlag.CACHE_FIREDELAY then
			for _, entity in pairs(Isaac.GetRoomEntities()) do
				BumpAttack:ba_onNPCUpdate(entity)
			end
		end
	end
end

function BumpAttack:ba_bump(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if playersHaveCollectible(BumpAttack.COLLECTIBLE_BUMP_ATTACK) then
		playerNum = getCurrPlayerNum(target:ToPlayer())
		if damageFlag ~= DamageFlag.DAMAGE_FAKE then
			if currFrame <= ba_lastBumpKilledFrame[playerNum] + 5 then
				return false
			end
			if not hasBit(damageFlag, DamageFlag.DAMAGE_EXPLOSION) and not hasBit(damageFlag, DamageFlag.DAMAGE_LASER) and not hasBit(damageFlag, DamageFlag.DAMAGE_FIRE) and damageSource and damageSource.Entity and damageSource.Entity:IsVulnerableEnemy() and not damageSource.Entity:IsBoss() and not (damageSource.Type == 39 and damageSource.Variant == 22) and damageSource.Type < 1000 then
				local dps = getAverageDPS_AllPlayers()
				local bumpValue = BumpAttack:getBumpValue(dps, damageSource.Entity.MaxHitPoints)
				if bumpValue >= 1 then
					if bumpValue == 2 then
						for _, entity in pairs(Isaac.GetRoomEntities()) do
							if entity.Type == damageSource.Entity.Type and entity.Variant == damageSource.Entity.Variant and entity.Position.X == damageSource.Entity.Position.X and entity.Position.Y == damageSource.Entity.Position.Y then
								ba_lastBumpKilledFrame[playerNum] = currFrame
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

function playersHaveCollectible(collectibleType)
	for playerNum=0,Game():GetNumPlayers()-1 do
		if Isaac.GetPlayer(playerNum):HasCollectible(collectibleType) then
			return true
		end
	end
	return false
end

function getPlayers()
	local p = {}
	for playerNum=0,Game():GetNumPlayers()-1 do
		if Isaac.GetPlayer(playerNum) ~= nil then
			table.insert(p, Isaac.GetPlayer(playerNum))
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

BumpAttack:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, BumpAttack.ba_onStart)
BumpAttack:AddCallback(ModCallbacks.MC_POST_UPDATE, BumpAttack.ba_onUpdate)
BumpAttack:AddCallback(ModCallbacks.MC_NPC_UPDATE, BumpAttack.ba_onNPCUpdate)
BumpAttack:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, BumpAttack.ba_cacheUpdate)
BumpAttack:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, BumpAttack.ba_bump, EntityType.ENTITY_PLAYER)