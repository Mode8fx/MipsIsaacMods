ShadyPass = RegisterMod("Shady Pass", 1)

ShadyPass.COLLECTIBLE_SHADY_PASS = Isaac.GetItemIdByName("Shady Pass")

local GameState = {}
local json = require("json")

local players = {}
local currLevel

function ShadyPass:onStart()
	if ShadyPass:HasData() then
		GameState = json.decode(ShadyPass:LoadData())
	else
		GameState = {}
	end

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[ShadyPass.COLLECTIBLE_SHADY_PASS] = "+1 Black Heart#Spawns a black market deal at the start of every floor except The Chest/Dark Room"

	players = getPlayers()
	currLevel = Game():GetLevel()
	if GameState.itemSpawnPosX ~= nil and GameState.itemSpawnPosY ~= nil then
		ShadyPass.itemSpawnPos = Vector(GameState.itemSpawnPosX, GameState.itemSpawnPosY)
	end
	if Game():GetFrameCount() == 0 then
		-- GameState.itemSpawnPosX = nil
		-- GameState.itemSpawnPosY = nil
		GameState.startSeed = Game():GetSeeds():GetStartSeed()
		GameState.currRoomIndex = currLevel:GetCurrentRoomIndex()
		GameState.oldNumShadyPasses = {0, 0, 0, 0, 0, 0, 0, 0}
		-- GameState.originalRoomIndex = nil
		-- GameState.lastItem = nil
		GameState.hadRedHeartsOnLastTick = true
	end
end
ShadyPass:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, ShadyPass.onStart)

function ShadyPass:onExit(save)
	GameState.itemSpawnPosX = ShadyPass.itemSpawnPos.X
	GameState.itemSpawnPosX = ShadyPass.itemSpawnPos.Y
	ShadyPass:SaveData(json.encode(GameState))
end
ShadyPass:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ShadyPass.onExit)
ShadyPass:AddCallback(ModCallbacks.MC_POST_GAME_END, ShadyPass.onExit)

function ShadyPass:onUpdate()
	local haveRedHearts = playersHaveRedHearts()
	for playerNum = 1, #players do
		local numShadyPasses = players[playerNum]:GetCollectibleNum(ShadyPass.COLLECTIBLE_SHADY_PASS)
		if numShadyPasses > 0 then
			if numShadyPasses > GameState.oldNumShadyPasses[playerNum] then
				players[playerNum]:AddBlackHearts((numShadyPasses - GameState.oldNumShadyPasses[playerNum]) * 2)
				GameState.oldNumShadyPasses[playerNum] = numShadyPasses
			end
			if haveRedHearts ~= GameState.hadRedHeartsOnLastTick then
				if GameState.currRoomIndex == GameState.originalRoomIndex then
					local currPrice = ShadyPass:getPrice()
					for _, entity in pairs(Isaac.GetRoomEntities()) do
						if entity.Position.X == ShadyPass.itemSpawnPos.X and entity.Position.Y == ShadyPass.itemSpawnPos.Y and entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
							local pickup = entity:ToPickup()
							-- Only update the item's price if it's a devil deal (-1000 = free)
							if pickup.Price < 0 and pickup.Price > -1000 then
								pickup.Price = currPrice
							end
							break
						end
					end
				end
			end
			if GameState.currRoomIndex == GameState.originalRoomIndex then
				local currPrice = ShadyPass:getPrice()
				for _, entity in pairs(Isaac.GetRoomEntities()) do
					if entity.Position.X == ShadyPass.itemSpawnPos.X and entity.Position.Y == ShadyPass.itemSpawnPos.Y and entity.Type == EntityType.ENTITY_PICKUP and entity.Variant ~= PickupVariant.PICKUP_COLLECTIBLE then
						local pickup = entity:ToPickup()
						-- Only update the item if it's a non-free heart
						if pickup.Price > 0 then
							entity:Remove()
							-- Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, ShadyPass.itemSpawnPos, Vector(0,0), nil)
							ShadyPass:spawnFromPool(ItemPoolType.POOL_SHOP, ShadyPass.itemSpawnPos, currPrice, GameState.startSeed)
						end
						break
					end
				end
			end
			GameState.hadRedHeartsOnLastTick = haveRedHearts
		end
	end
end

function ShadyPass:onNewLevel()
	currLevel = Game():GetLevel()
	GameState.originalRoomIndex = currLevel:GetCurrentRoomIndex()
	ShadyPass.itemSpawnPos = Isaac.GetFreeNearPosition(Vector(180,160), 0)
	-- Item works on every floor except The Chest/Dark Room (just like black markets)
	if currLevel:GetStage() ~= 11 then
		if playersHaveCollectible(ShadyPass.COLLECTIBLE_SHADY_PASS) then
			-- Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, ShadyPass.itemSpawnPos, Vector(0,0), nil)
			ShadyPass:spawnFromPool(ItemPoolType.POOL_SHOP, ShadyPass.itemSpawnPos, ShadyPass:getPrice(), GameState.startSeed)
		end
	end
end

function ShadyPass:onNewRoom()
	GameState.currRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
end

function ShadyPass:spawnFromPool(pool, pos, price, seed)
	local currItem = Game():GetItemPool():GetCollectible(pool, true, seed)
	-- Fixes bug where item has an unusually high chance of "rerolling" into itself (and the Breakfast check prevents a softlock in case the item pool is empty)
	while currItem == GameState.lastItem and currItem ~= CollectibleType.COLLECTIBLE_BREAKFAST do
		currItem = Game():GetItemPool():GetCollectible(pool, true, seed)
	end
	local spawnItem = Isaac.Spawn(
		EntityType.ENTITY_PICKUP,
		PickupVariant.PICKUP_COLLECTIBLE,
		currItem,
		pos,
		Vector(0,0),
		nil
	):ToPickup()
	spawnItem.Price = price
	local data = spawnItem:GetData()
	data.Price = price
	-- If this is true (which it is by default), the price will reset to 15 cents on every tick!
	spawnItem.AutoUpdatePrice = false
	GameState.lastItem = currItem
end

function ShadyPass:getPrice()
	for i = 1, #players do
		if players[i]:GetMaxHearts() == 0 then
			return PickupPrice.PRICE_THREE_SOULHEARTS
		end
	end
	return PickupPrice.PRICE_ONE_HEART
end

function playersHaveRedHearts()
	for playerNum=0,Game():GetNumPlayers()-1 do
		if Isaac.GetPlayer(playerNum):GetMaxHearts() > 0 then
			return true
		end
	end
	return false
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

ShadyPass:AddCallback(ModCallbacks.MC_POST_UPDATE, ShadyPass.onUpdate)
ShadyPass:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, ShadyPass.onNewLevel)
ShadyPass:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ShadyPass.onNewRoom)