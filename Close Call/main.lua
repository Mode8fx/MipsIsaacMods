CloseCall = RegisterMod("Close Call", 1)

CloseCall.COLLECTIBLE_CLOSE_CALL = Isaac.GetItemIdByName("Close Call")

local players = {}
local playerNum = 0

local currFrame = 0

function CloseCall:onStart()
	currFrame = 0

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[CloseCall.COLLECTIBLE_CLOSE_CALL] = "If your total health is 1.5 hearts or less, there is a 1/3 chance you will avoid damage#Stacks multiplicatively"

	players = getPlayers()
end

function CloseCall:onUpdate()
	currFrame = Game():GetFrameCount()
end

CloseCall:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, CloseCall.onStart)
CloseCall:AddCallback(ModCallbacks.MC_POST_UPDATE, CloseCall.onUpdate)

function hasBit(var, bit)
	if var == nil then
		return false
	end
	return var % (bit + bit) >= bit
end

local cc_lastSafeFrame = {0, 0, 0, 0, 0, 0, 0, 0}
local cc_safeColor = Color(1, 0.898, 0.396, 1, 0, 0, 0)
local cc_numSafeFrames = 30

function CloseCall:cc_onStart()
	cc_lastSafeFrame = {0, 0, 0, 0, 0, 0, 0, 0}
end

function damageIsFake(damageFlag)
	return hasBit(damageFlag, DamageFlag.DAMAGE_FAKE)
end

function damageIsFromSacrificeSpikes(damageFlag)
	return (hasBit(damageFlag, DamageFlag.DAMAGE_SPIKES) and Game():GetRoom():GetType() == RoomType.ROOM_SACRIFICE)
end

function damageIsFromMausoleumDoor(damageFlag)
	local currStage = Game():GetLevel():GetStage()
	return (hasBit(damageFlag, DamageFlag.DAMAGE_SPIKES)
		and (currStage == LevelStage.STAGE2_2 or currStage == LevelStage.STAGE3_1 or currStage == LevelStage.STAGE2_1)
		and Game():GetRoom():GetType() == RoomType.ROOM_BOSS and Game():GetRoom():IsClear())
end

function CloseCall:cc_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if target and target.Type == EntityType.ENTITY_PLAYER then
		playerNum = getCurrPlayerNum(target:ToPlayer())
		if players[playerNum]:HasCollectible(CloseCall.COLLECTIBLE_CLOSE_CALL) and not damageIsFake(damageFlag) and not damageIsFromSacrificeSpikes(damageFlag) and not damageIsFromMausoleumDoor(damageFlag) then
			if currFrame < cc_lastSafeFrame[playerNum] + cc_numSafeFrames then
				return false
			end
			if players[playerNum]:GetHearts() + players[playerNum]:GetSoulHearts() <= 3 and math.random(1000) > (2/3)^players[playerNum]:GetCollectibleNum(CloseCall.COLLECTIBLE_CLOSE_CALL)*1000 then
				cc_lastSafeFrame[playerNum] = currFrame
				players[playerNum]:SetColor(cc_safeColor, cc_numSafeFrames, 0, true, false)
				return false
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

CloseCall:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, CloseCall.cc_onStart)
CloseCall:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CloseCall.cc_onHit, EntityType.ENTITY_PLAYER)