PUpDDown = RegisterMod("P-Up, D-Down", 1)

PUpDDown.COLLECTIBLE_P_UP_D_DOWN = Isaac.GetItemIdByName("P-Up, D-Down")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local player

function PUpDDown:onStart()
	player = Isaac.GetPlayer(0)

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[PUpDDown.COLLECTIBLE_P_UP_D_DOWN] = "\1 x2 Damage Multiplier#Take double damage"
end

PUpDDown:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PUpDDown.onStart)

function hasBit(var, bit)
	if var == nil then
		return false
	end
	return var % (bit + bit) >= bit
end

local pudd_tookDamage = false

function PUpDDown:pudd_onStart()
	pudd_tookDamage = false
end

function PUpDDown:pudd_cacheUpdate(player, flag)
	if flag == CacheFlag.CACHE_DAMAGE and player:HasCollectible(PUpDDown.COLLECTIBLE_P_UP_D_DOWN) then
		player.Damage = player.Damage * 2
	end
end

function PUpDDown:pudd_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if pudd_tookDamage then
		-- print("START")
		-- print(damageAmount) -- 1 per half heart
		-- print(numCountdownFrames)
		pudd_tookDamage = false
		return nil
	end
	if player:HasCollectible(PUpDDown.COLLECTIBLE_P_UP_D_DOWN) then
		pudd_tookDamage = true
		player:TakeDamage(damageAmount * 2, damageFlag, damageSource, numCountdownFrames) -- this is supposed to keep the original number of invincibility frames, but it's broken in the API?
		return false
	end
end

PUpDDown:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PUpDDown.pudd_onStart)
PUpDDown:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, PUpDDown.pudd_onHit, EntityType.ENTITY_PLAYER)
PUpDDown:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, PUpDDown.pudd_cacheUpdate)