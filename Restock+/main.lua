RestockPlus = RegisterMod("Restock Plus", 1)

local GameState = {}
local json = require("json")

local players = {}
local specialPlayerTypePresent = false
local currRoomIndex

local options = {0, 1, 2, 3, 4, 5, 99999}
local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

function RestockPlus:onStart()
	if RestockPlus:HasData() then
		GameState = json.decode(RestockPlus:LoadData())
	else
		GameState = {}
	end

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[CollectibleType.COLLECTIBLE_RESTOCK] = "Shops, Devil rooms, and black markets instantly restock their items when you buy them"

	players = getPlayers()

	specialPlayerTypePresent = false
	for i = 1, #players do
		if players[i]:GetPlayerType() == PlayerType.PLAYER_THELOST or players[i]:GetPlayerType() == PlayerType.PLAYER_THELOST_B or players[i]:GetPlayerType() == PlayerType.PLAYER_JACOB2_B then
			specialPlayerTypePresent = true
			break
		end
	end

	RestockPlus.COLLECTIBLE_SHADY_PASS = Isaac.GetItemIdByName("Shady Pass")
	RestockPlus.COLLECTIBLE_DARK_RESTOCK = Isaac.GetItemIdByName("Dark Restock")

	if GameState.lostOption == nil then
		GameState.lostOption = 1
	end

	if not alreadyPlayedOnceOnBoot then
		-- Mod Config Menu
		if ModConfigMenu then
			ModConfigMenu.AddSpace("Restock+")
			ModConfigMenu.AddSetting("Restock+", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					if GameState.lostOption == 99999 then
						return 6
					end
					return GameState.lostOption
				end,
				Display = function()
					if GameState.lostOption < 6 then
						return "# of restocks/floor (the Lost): " .. GameState.lostOption
					else
						return "# of restocks/floor (the Lost): Unlimited"
					end
				end,
				Minimum = 0,
				Maximum = 6,
				Default = 1,
				OnChange = function(currentNum)
					GameState.lostOption = options[currentNum+1]
					RestockPlus:onExit()
				end,
				Info = {
					"Set how many devil room/black market restocks",
					"per floor are allowed when playing as the Lost."
				}
			})
		end
		alreadyPlayedOnceOnBoot = true
	end

	if Game():GetFrameCount() == 0 then
		GameState.startSeed = Game():GetSeeds():GetStartSeed()
		GameState.roomItemValues = {} -- Table containing room index and position of each item spawned by devil room/black market
		GameState.crookedPennyFrame = -3
		GameState.inGoodRoom = false
		GameState.hadRestock = false
		GameState.hadShadyPass = false
		GameState.numRestocksUsedOnFloor = 0
	end
end
RestockPlus:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, RestockPlus.onStart)

function RestockPlus:onExit(save)
	RestockPlus:SaveData(json.encode(GameState))
end
RestockPlus:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, RestockPlus.onExit)
RestockPlus:AddCallback(ModCallbacks.MC_POST_GAME_END, RestockPlus.onExit)

function RestockPlus:onUpdate()
	if GameState.inGoodRoom and playersHaveCollectible(CollectibleType.COLLECTIBLE_RESTOCK) and ((not specialPlayerTypePresent) or GameState.numRestocksUsedOnFloor < GameState.lostOption) and (RestockPlus.COLLECTIBLE_DARK_RESTOCK == -1 or not playersHaveCollectible(RestockPlus.COLLECTIBLE_DARK_RESTOCK)) then
		local currFrame = Game():GetFrameCount()
		if currFrame == GameState.crookedPennyFrame + 1 then
			RestockPlus:getItemValues()
			if #GameState.roomItemValues == 0 then
				GameState.inGoodRoom = false
				return
			end
		end
		if not GameState.hadRestock then
			RestockPlus:getItemValues()
		end
		currRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
		if GameState.roomItemValues[currRoomIndex] ~= nil then
			local hasShadyPass = RestockPlus.COLLECTIBLE_SHADY_PASS ~= -1 and playersHaveCollectible(RestockPlus.COLLECTIBLE_SHADY_PASS)
			for i=1,#GameState.roomItemValues[currRoomIndex] do
				if currRoomIndex ~= GameState.originalRoomIndex or (hasShadyPass and GameState.hadShadyPass and Game():GetLevel():GetStage() ~= 11) then
					local dealExists = false
					local currItemPos = GameState.roomItemValues[currRoomIndex][i][1]
					for _, entity in pairs(Isaac.GetRoomEntities()) do
						if entity.Position.X == currItemPos.X and entity.Position.Y == currItemPos.Y and entity.Type == EntityType.ENTITY_PICKUP and entity:ToPickup().Price ~= 0 and entity:ToPickup().Price > -1000 then
							dealExists = true
							break
						end
					end
					if not dealExists then
						local newItemPos = Isaac.GetFreeNearPosition(currItemPos, 0)
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, newItemPos, Vector(0,0), nil)
						-- getPrice() will immediately reset to the correct price
						if Game():GetRoom():GetType() == RoomType.ROOM_DEVIL then
							RestockPlus:spawnFromPool(ItemPoolType.POOL_DEVIL, newItemPos, RestockPlus:getPrice(), GameState.startSeed)
						else
							RestockPlus:spawnFromPool(ItemPoolType.POOL_SHOP, newItemPos, RestockPlus:getPrice(), GameState.startSeed)
						end
						GameState.numRestocksUsedOnFloor = GameState.numRestocksUsedOnFloor + 1
						if currRoomIndex == GameState.originalRoomIndex and RestockPlus.COLLECTIBLE_SHADY_PASS ~= -1 and hasShadyPass then
							ShadyPass.itemSpawnPos = newItemPos
						end
						GameState.roomItemValues[currRoomIndex][i][1] = newItemPos
					end
				end
			end
		end
	end
	GameState.hadRestock = playersHaveCollectible(CollectibleType.COLLECTIBLE_RESTOCK)
end

function RestockPlus:onNewLevel()
	GameState.originalRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
	if RestockPlus.COLLECTIBLE_SHADY_PASS ~= -1 then
		RestockPlus:addRoomPosPair(currRoomIndex, Isaac.GetFreeNearPosition(Vector(180,160), 0)) -- Shady Pass initial item spawn position
	end
	GameState.hadShadyPass = RestockPlus.COLLECTIBLE_SHADY_PASS ~= -1 and playersHaveCollectible(Isaac.GetItemIdByName("Shady Pass"))
	GameState.numRestocksUsedOnFloor = 0
end

function RestockPlus:getItemValues()
	currRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
	GameState.roomItemValues = {}
	local roomType = Game():GetRoom():GetType()
	if roomType == RoomType.ROOM_DEVIL or roomType == RoomType.ROOM_BLACK_MARKET or (currRoomIndex == GameState.originalRoomIndex and RestockPlus.COLLECTIBLE_SHADY_PASS ~= -1) then
		GameState.inGoodRoom = true
		for _, entity in pairs(Isaac.GetRoomEntities()) do
			if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity:ToPickup().Price < 0 then
				RestockPlus:addRoomPosPair(currRoomIndex, Vector(entity.Position.X, entity.Position.Y))
			end
		end
	else
		GameState.inGoodRoom = false
	end
end

function RestockPlus:spawnFromPool(pool, pos, price, seed)
	local currItem = Game():GetItemPool():GetCollectible(pool, true, seed)
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
	if currRoomIndex == GameState.originalRoomIndex then
		spawnItem.AutoUpdatePrice = false
	end
	return currItem
end

function RestockPlus:addRoomPosPair(roomIndex, itemPos)
	if GameState.roomItemValues[roomIndex] == nil then
		GameState.roomItemValues[roomIndex] = {}
	end
	for i=1, #GameState.roomItemValues[roomIndex] do
		if GameState.roomItemValues[roomIndex][i][1] == itemPos then
			return
		end
	end
	table.insert(GameState.roomItemValues[roomIndex], {itemPos, 0})
end

function RestockPlus:getPrice()
	for i = 1, #players do
		if players[i]:GetMaxHearts() == 0 then
			return PickupPrice.PRICE_THREE_SOULHEARTS
		end
	end
	return PickupPrice.PRICE_ONE_HEART
end

function RestockPlus:useCrookedPenny()
	GameState.crookedPennyFrame = Game():GetFrameCount()
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

RestockPlus:AddCallback(ModCallbacks.MC_POST_UPDATE, RestockPlus.onUpdate);
RestockPlus:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, RestockPlus.onNewLevel)
RestockPlus:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, RestockPlus.getItemValues)
RestockPlus:AddCallback(ModCallbacks.MC_USE_ITEM, RestockPlus.useCrookedPenny, CollectibleType.COLLECTIBLE_CROOKED_PENNY)