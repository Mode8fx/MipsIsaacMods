SlowGo = RegisterMod("Slow Go", 1)

SlowGo.COLLECTIBLE_SLOW_GO = Isaac.GetItemIdByName("Slow Go")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

function SlowGo:onStart()
	if SlowGo:HasData() then
		GameState = json.decode(SlowGo:LoadData())
	end

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[SlowGo.COLLECTIBLE_SLOW_GO] = "\2 -50% Speed multiplier"
end

function initializeVar(var, value)
	if var == nil then
		var = value
	end
	return var
end

function SlowGo:onExit(save)
	SlowGo:SaveData(json.encode(GameState))
end

SlowGo:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SlowGo.onStart)
SlowGo:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SlowGo.onExit)
SlowGo:AddCallback(ModCallbacks.MC_POST_GAME_END, SlowGo.onExit)

function SlowGo:sg_cacheUpdate(player, flag)
	if flag == CacheFlag.CACHE_SPEED and player:HasCollectible(SlowGo.COLLECTIBLE_SLOW_GO) then
		player.MoveSpeed = player.MoveSpeed / 2
	end
end

SlowGo:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SlowGo.sg_cacheUpdate)