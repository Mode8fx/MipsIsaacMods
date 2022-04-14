CloseCall = RegisterMod("Close Call", 1)

CloseCall.COLLECTIBLE_CLOSE_CALL = Isaac.GetItemIdByName("Close Call")

local player
local currFrame = 0

function CloseCall:onStart()
	player = Isaac.GetPlayer(0)
	currFrame = 0

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[CloseCall.COLLECTIBLE_CLOSE_CALL] = "If your total health is 1.5 hearts or less, there is a 1/3 chance you will avoid damage#Stacks multiplicatively"
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

local cc_lastSafeFrame
local cc_safeColor = Color(1, 0.898, 0.396, 1, 0, 0, 0)
local cc_numSafeFrames = 30

function CloseCall:cc_onStart()
	cc_lastSafeFrame = 0
end

function CloseCall:cc_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if player:HasCollectible(CloseCall.COLLECTIBLE_CLOSE_CALL) and not hasBit(damageFlag, DamageFlag.DAMAGE_FAKE) and not (hasBit(damageFlag, DamageFlag.DAMAGE_SPIKES) and Game():GetRoom():GetType() == RoomType.ROOM_SACRIFICE) then
		if currFrame < cc_lastSafeFrame + cc_numSafeFrames then
			return false
		end
		if player:GetHearts() + player:GetSoulHearts() <= 3 and math.random(1000) > (2/3)^player:GetCollectibleNum(CloseCall.COLLECTIBLE_CLOSE_CALL)*1000 then
			cc_lastSafeFrame = currFrame
			player:SetColor(cc_safeColor, cc_numSafeFrames, 0, true, false)
			return false
		end
	end
end

CloseCall:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, CloseCall.cc_onStart)
CloseCall:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CloseCall.cc_onHit, EntityType.ENTITY_PLAYER)