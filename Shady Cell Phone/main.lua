local ShadyCellPhone = RegisterMod("Shady Cell Phone", 1)

ShadyCellPhone.COLLECTIBLE_SHADY_CELL_PHONE = Isaac.GetItemIdByName("Shady Cell Phone")
SoundEffect.SOUND_SHADY_CELL_GOOD = Isaac.GetSoundIdByName("good")
SoundEffect.SOUND_SHADY_CELL_BAD = Isaac.GetSoundIdByName("bad")

local GameState = {}
local json = require("json")

local players = {}
local currLevel
local restockShadyPass

function ShadyCellPhone:onStart()
	if ShadyCellPhone:HasData() then
		GameState = json.decode(ShadyCellPhone:LoadData())
	else
		GameState = {}
	end

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[ShadyCellPhone.COLLECTIBLE_SHADY_CELL_PHONE] = "Spawns a Black Market deal and restocks item spawned by Shady Pass#Has no effect in The Chest/Dark Room"

	players = getPlayers()
	currLevel = Game():GetLevel()
	ShadyCellPhone.COLLECTIBLE_SHADY_PASS = Isaac.GetItemIdByName("Shady Pass")
	if Game():GetFrameCount() == 0 then
		GameState.startSeed = Game():GetSeeds():GetStartSeed()
		GameState.currRoomIndex = currLevel:GetCurrentRoomIndex()
		GameState.hadRedHeartsOnLastTick = true
		GameState.createdItemValues = {} -- Table containing room index and position of each item spawned by Shady Cell Phone or Shady Pass
		GameState.highestRoomIndex = -10000
		if ShadyCellPhone.COLLECTIBLE_SHADY_PASS == -1 then
			-- This makes ShadyPass.itemSpawnPos = nil instead of an error
			ShadyPass = {}
		end
	end
end
ShadyCellPhone:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, ShadyCellPhone.onStart)

function ShadyCellPhone:onExit(save)
	for i=1,GameState.highestRoomIndex do
		if GameState.createdItemValues[i] == nil then
			GameState.createdItemValues[i] = {}
		end
	end
	ShadyCellPhone:SaveData(json.encode(GameState))
end
ShadyCellPhone:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ShadyCellPhone.onExit)
ShadyCellPhone:AddCallback(ModCallbacks.MC_POST_GAME_END, ShadyCellPhone.onExit)

function ShadyCellPhone:onUpdate()
	if restockShadyPass and GameState.currRoomIndex == GameState.originalRoomIndex and (DarkRestock == nil or not playersHaveCollectible(Isaac.GetItemIdByName("Dark Restock"))) and (RestockPlus == nil or not playersHaveCollectible(Isaac.GetItemIdByName("Restock"))) then
		-- Restock item spawned by Shady Pass if necessary
		-- ShadyCellPhone:addRoomPosPair(GameState.originalRoomIndex, ShadyPass.itemSpawnPos)
		local dealExists = false
		if ShadyPass.itemSpawnPos == nil then
			ShadyPass.itemSpawnPos = Isaac.GetFreeNearPosition(Vector(180,160), 0) -- Shady Pass initial item spawn position
		end
		local itemSpawnXPos = ShadyPass.itemSpawnPos.X
		local itemSpawnYPos = ShadyPass.itemSpawnPos.Y
		for _, entity in pairs(Isaac.GetRoomEntities()) do
			if entity.Position.X == itemSpawnXPos and entity.Position.Y == itemSpawnYPos and entity.Type == EntityType.ENTITY_PICKUP and entity:ToPickup().Price ~= 0 and entity:ToPickup().Price > -1000 then
				dealExists = true
				break
			end
		end
		if not dealExists then
			ShadyPass.itemSpawnPos = Isaac.GetFreeNearPosition(ShadyPass.itemSpawnPos, 0)
			-- GameState.startSeed is incremented here (and in other places) since rerolling several shady-created items at once can have a predictable pattern based on past items. Incrementing the seed mixes this up while still making everything rely on the unique game seed.
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, ShadyPass.itemSpawnPos, Vector(0,0), nil)
			ShadyCellPhone:spawnFromPool(ItemPoolType.POOL_SHOP, ShadyPass.itemSpawnPos, ShadyCellPhone:getPrice(), GameState.startSeed, 0)
			GameState.startSeed = GameState.startSeed + 1
			-- GameState.createdItemValues[GameState.currRoomIndex][i][1] = ShadyPass.itemSpawnPos
		end
		restockShadyPass = false
	end

	local haveRedHearts = playersHaveRedHearts()
	-- If Isaac is in a room that contains an item spawned by the Shady Cell Phone or Shady Pass, then update created item prices to correct amount of heart containers
	if haveRedHearts ~= GameState.hadRedHeartsOnLastTick then
		if GameState.createdItemValues[GameState.currRoomIndex] ~= nil then
			local currPrice = ShadyCellPhone:getPrice()
			for i=1,#GameState.createdItemValues[GameState.currRoomIndex] do
				local currItemPos = GameState.createdItemValues[GameState.currRoomIndex][i][1]
				-- Shady Pass file already takes care of its own item
				if currItemPos ~= ShadyPass.itemSpawnPos then
					for _, entity in pairs(Isaac.GetRoomEntities()) do
						-- Only update aforementioned items, ignore everything else
						if entity.Position.X == currItemPos.X and entity.Position.Y == currItemPos.Y and entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
							local pickup = entity:ToPickup()
							-- Only update the item's price if it's a devil (heart container) deal (-1000 = free)
							if pickup.Price < 0 and pickup.Price > -1000 then
								pickup.Price = currPrice
							end
							break
						end
					end
				end
			end
		end
	end
	-- Fix bug that makes created items sometimes reroll into heart pickups
	if GameState.createdItemValues[GameState.currRoomIndex] ~= nil then
		local currPrice = ShadyCellPhone:getPrice()
		for i=1,#GameState.createdItemValues[GameState.currRoomIndex] do
			local currItemPos = GameState.createdItemValues[GameState.currRoomIndex][i][1]
			-- Shady Pass file already takes care of its own item
			if currItemPos ~= ShadyPass.itemSpawnPos then
				for _, entity in pairs(Isaac.GetRoomEntities()) do
					-- Only update aforementioned items, ignore everything else
					if entity.Position.X == currItemPos.X and entity.Position.Y == currItemPos.Y and entity.Type == EntityType.ENTITY_PICKUP and entity.Variant ~= PickupVariant.PICKUP_COLLECTIBLE then
						local pickup = entity:ToPickup()
						-- Only update the item if it's a non-free heart
						if pickup.Price > 0 then
							entity:Remove()
							-- Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, currItemPos, Vector(0,0), nil)
							GameState.createdItemValues[GameState.currRoomIndex][i][2] = ShadyCellPhone:spawnFromPool(ItemPoolType.POOL_SHOP, currItemPos, currPrice, GameState.startSeed, GameState.createdItemValues[GameState.currRoomIndex][i][2])
							GameState.startSeed = GameState.startSeed + 1
						end
						break
					end
				end
			end
		end
	end
	GameState.hadRedHeartsOnLastTick = haveRedHearts
end

function ShadyCellPhone:onNewLevel()
	GameState.createdItemValues = {}
	currLevel = Game():GetLevel()
	GameState.originalRoomIndex = currLevel:GetCurrentRoomIndex()
end

function ShadyCellPhone:onNewRoom()
	GameState.currRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
end

function ShadyCellPhone:useItem(collectibleType, rng, player, flags, activeSlot, customVarData)
	player:AnimateCollectible(ShadyCellPhone.COLLECTIBLE_SHADY_CELL_PHONE, "UseItem", "PlayerPickup")
	if currLevel:GetStage() ~= 11 then
		SFXManager():Play(SoundEffect.SOUND_SHADY_CELL_GOOD, 0.5, 0, false, 1)
		if ShadyCellPhone.COLLECTIBLE_SHADY_PASS ~= -1 and player:HasCollectible(ShadyCellPhone.COLLECTIBLE_SHADY_PASS) then -- and ShadyPass.itemSpawnPos ~= nil
			restockShadyPass = true
		end

		-- Spawn new item near Isaac
		local pos = Isaac.GetFreeNearPosition(Vector(player.Position.X, player.Position.Y + 30), 0)
		ShadyCellPhone:addRoomPosPair(GameState.currRoomIndex, pos)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, pos, Vector(0,0), nil)
		ShadyCellPhone:spawnFromPool(ItemPoolType.POOL_SHOP, pos, ShadyCellPhone:getPrice(), GameState.startSeed, 0)
		GameState.startSeed = GameState.startSeed + 1
	else
		SFXManager():Play(SoundEffect.SOUND_SHADY_CELL_BAD, 2, 0, false, 1)
	end
end

function ShadyCellPhone:spawnFromPool(pool, pos, price, seed, lastItem)
	local currItem = Game():GetItemPool():GetCollectible(pool, true, seed)
	-- Fixes bug where item has an unusually high chance of "rerolling" into itself (and the Breakfast check prevents a softlock in case the item pool is empty)
	while currItem == lastItem and currItem ~= CollectibleType.COLLECTIBLE_BREAKFAST do
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
	return currItem
end

function ShadyCellPhone:getPrice()
	for i = 1, #players do
		if players[i]:GetMaxHearts() == 0 then
			return PickupPrice.PRICE_THREE_SOULHEARTS
		end
	end
	return PickupPrice.PRICE_ONE_HEART
end

function ShadyCellPhone:addRoomPosPair(roomIndex, itemPos)
	GameState.highestRoomIndex = math.max(GameState.highestRoomIndex, roomIndex)
	if GameState.createdItemValues[roomIndex] == nil then
		GameState.createdItemValues[roomIndex] = {}
	end
	for i=1, #GameState.createdItemValues[roomIndex] do
		if GameState.createdItemValues[roomIndex][i][1] == itemPos then
			return
		end
	end
	table.insert(GameState.createdItemValues[roomIndex], {itemPos, 0})
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
	for i = 0, Game():GetNumPlayers() do
		if Isaac.GetPlayer(i) ~= nil then
			table.insert(p, Isaac.GetPlayer(i))
		end
	end
	return p
end

ShadyCellPhone:AddCallback(ModCallbacks.MC_POST_UPDATE, ShadyCellPhone.onUpdate)
ShadyCellPhone:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, ShadyCellPhone.onNewLevel)
ShadyCellPhone:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ShadyCellPhone.onNewRoom)
ShadyCellPhone:AddCallback(ModCallbacks.MC_USE_ITEM, ShadyCellPhone.useItem, ShadyCellPhone.COLLECTIBLE_SHADY_CELL_PHONE)