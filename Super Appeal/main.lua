SuperAppeal = RegisterMod("Super Appeal", 1)

SuperAppeal.COLLECTIBLE_SUPER_APPEAL = Isaac.GetItemIdByName("Super Appeal")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local players = {}
local playerNum = 0

function SuperAppeal:onStart()
	if SuperAppeal:HasData() then
		GameState = json.decode(SuperAppeal:LoadData())
	else
		GameState = {}
	end

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[SuperAppeal.COLLECTIBLE_SUPER_APPEAL] = "\1 +1.0 Luck Up#An additional +0.1 Luck Up upon clearing a room#Room clear bonus caps at 1.5 and decreases by 0.3 upon taking damage"

	players = getPlayers()
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
		GameState.sa_numRooms = {}
		GameState.sa_currRoom = {}
		GameState.sa_inSafeRoom = {}
		GameState.sa_hadSA = {}
		for playerNum=1,4 do
			GameState.sa_numRooms[playerNum] = 0
			GameState.sa_currRoom[playerNum] = Game():GetRoom()
			GameState.sa_inSafeRoom[playerNum] = GameState.sa_currRoom[playerNum]:IsClear()
			GameState.sa_hadSA[playerNum] = false
		end
	end
end

function SuperAppeal:sa_onUpdate()
	if GameState.sa_inSafeRoom then
		for playerNum=1,Game():GetNumPlayers() do
			if players[playerNum]:HasCollectible(SuperAppeal.COLLECTIBLE_SUPER_APPEAL) then
				if not GameState.sa_inSafeRoom[playerNum] and GameState.sa_currRoom[playerNum]:IsClear() and GameState.sa_hadSA[playerNum] then
					GameState.sa_numRooms[playerNum] = math.min(GameState.sa_numRooms[playerNum] + 1, sa_maxRooms)
					GameState.sa_inSafeRoom[playerNum] = true
					players[playerNum]:AddCacheFlags(CacheFlag.CACHE_LUCK)
					players[playerNum]:EvaluateItems()
				end
			end
		end
	end
end

function SuperAppeal:sa_onNewRoom()
	if GameState.sa_currRoom then
		for playerNum=1,Game():GetNumPlayers() do
			GameState.sa_currRoom[playerNum] = Game():GetRoom()
			GameState.sa_inSafeRoom[playerNum] = GameState.sa_currRoom[playerNum]:IsClear()
			GameState.sa_hadSA[playerNum] = players[playerNum]:HasCollectible(SuperAppeal.COLLECTIBLE_SUPER_APPEAL)
		end
	end
end

function SuperAppeal:sa_loseBonus(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if target and target.Type == EntityType.ENTITY_PLAYER then
		playerNum = getCurrPlayerNum(target:ToPlayer())
		if players[playerNum]:HasCollectible(SuperAppeal.COLLECTIBLE_SUPER_APPEAL) and not hasBit(damageFlag, DamageFlag.DAMAGE_FAKE) then
			GameState.sa_numRooms[playerNum] = math.max(GameState.sa_numRooms[playerNum] - sa_roomPenalty, 0)
			players[playerNum]:AddCacheFlags(CacheFlag.CACHE_LUCK)
			players[playerNum]:EvaluateItems()
		end
	end
end

function SuperAppeal:sa_cacheUpdate(player, flag)
	if GameState.sa_numRooms then
		playerNum = getCurrPlayerNum(player)
		if player:HasCollectible(SuperAppeal.COLLECTIBLE_SUPER_APPEAL) and flag == CacheFlag.CACHE_LUCK then
			player.Luck = player.Luck + (player:GetCollectibleNum(SuperAppeal.COLLECTIBLE_SUPER_APPEAL) * sa_initLuckUp) + (GameState.sa_numRooms[playerNum] * sa_roomLuckBonus)
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

SuperAppeal:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SuperAppeal.sa_onStart)
SuperAppeal:AddCallback(ModCallbacks.MC_POST_UPDATE, SuperAppeal.sa_onUpdate)
SuperAppeal:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, SuperAppeal.sa_onNewRoom)
SuperAppeal:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SuperAppeal.sa_cacheUpdate)
SuperAppeal:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SuperAppeal.sa_loseBonus, EntityType.ENTITY_PLAYER)