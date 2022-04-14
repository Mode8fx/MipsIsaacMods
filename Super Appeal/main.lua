PaperIsaac = RegisterMod("Paper Isaac", 1)

PaperIsaac.COLLECTIBLE_SUPER_APPEAL = Isaac.GetItemIdByName("Super Appeal")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local player

function PaperIsaac:onStart()
	GameState = json.decode(PaperIsaac:LoadData())

	player = Isaac.GetPlayer(0)

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[PaperIsaac.COLLECTIBLE_SUPER_APPEAL] = "\1 +1.0 Luck Up#An additional +0.1 Luck Up upon clearing a room#Room clear bonus caps at 1.5 and decreases by 0.3 upon taking damage"
end

function PaperIsaac:onExit(save)
	PaperIsaac:SaveData(json.encode(GameState))
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, PaperIsaac.onExit)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_GAME_END, PaperIsaac.onExit)

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

function PaperIsaac:sa_onStart()
	if Game():GetFrameCount() < 5 then
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