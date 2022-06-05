SuperAppeal = RegisterMod("Super Appeal", 1)

SuperAppeal.COLLECTIBLE_SUPER_APPEAL = Isaac.GetItemIdByName("Super Appeal")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local player

function SuperAppeal:onStart()
	GameState = json.decode(SuperAppeal:LoadData())

	player = Isaac.GetPlayer(0)

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[SuperAppeal.COLLECTIBLE_SUPER_APPEAL] = "\1 +1.0 Luck Up#An additional +0.1 Luck Up upon clearing a room#Room clear bonus caps at 1.5 and decreases by 0.3 upon taking damage"
end

function SuperAppeal:onExit(save)
	SuperAppeal:SaveData(json.encode(GameState))
end

SuperAppeal:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SuperAppeal.onStart)
SuperAppeal:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SuperAppeal.onExit)
SuperAppeal:AddCallback(ModCallbacks.MC_POST_GAME_END, SuperAppeal.onExit)

function hasBit(var, bit)
	if var == nil then
		return false
	end
	return var % (bit + bit) >= bit
end

local sa_initLuckUp = 1
local sa_roomLuckBonus = 0.1
local sa_roomPenalty = 3
local sa_maxRooms = 15

function SuperAppeal:sa_onStart()
	if Game():GetFrameCount() < 5 then
		GameState.sa_numRooms = 0
		GameState.sa_currRoom = Game():GetRoom()
		GameState.sa_inSafeRoom = GameState.sa_currRoom:IsClear()
		GameState.sa_hadSA = false
	end
end

function SuperAppeal:sa_onUpdate()
	if player:HasCollectible(SuperAppeal.COLLECTIBLE_SUPER_APPEAL) then
		if not GameState.sa_inSafeRoom and GameState.sa_currRoom:IsClear() and GameState.sa_hadSA then
			GameState.sa_numRooms = math.min(GameState.sa_numRooms + 1, sa_maxRooms)
			GameState.sa_inSafeRoom = true
			player:AddCacheFlags(CacheFlag.CACHE_LUCK)
			player:EvaluateItems()
		end
	end
end

function SuperAppeal:sa_onNewRoom()
	GameState.sa_currRoom = Game():GetRoom()
	GameState.sa_inSafeRoom = GameState.sa_currRoom:IsClear()
	GameState.sa_hadSA = Isaac.GetPlayer(0):HasCollectible(SuperAppeal.COLLECTIBLE_SUPER_APPEAL)
end

function SuperAppeal:sa_loseBonus(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if player:HasCollectible(SuperAppeal.COLLECTIBLE_SUPER_APPEAL) and not hasBit(damageFlag, DamageFlag.DAMAGE_FAKE) then
		GameState.sa_numRooms = math.max(GameState.sa_numRooms - sa_roomPenalty, 0)
		player:AddCacheFlags(CacheFlag.CACHE_LUCK)
		player:EvaluateItems()
	end
end

function SuperAppeal:sa_cacheUpdate(player, flag)
	if player:HasCollectible(SuperAppeal.COLLECTIBLE_SUPER_APPEAL) and flag == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + (player:GetCollectibleNum(SuperAppeal.COLLECTIBLE_SUPER_APPEAL) * sa_initLuckUp) + (GameState.sa_numRooms * sa_roomLuckBonus)
    end
end

SuperAppeal:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SuperAppeal.sa_onStart)
SuperAppeal:AddCallback(ModCallbacks.MC_POST_UPDATE, SuperAppeal.sa_onUpdate)
SuperAppeal:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, SuperAppeal.sa_onNewRoom)
SuperAppeal:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SuperAppeal.sa_cacheUpdate)
SuperAppeal:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SuperAppeal.sa_loseBonus, EntityType.ENTITY_PLAYER)