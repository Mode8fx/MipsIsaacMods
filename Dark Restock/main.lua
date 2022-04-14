DarkRestock = RegisterMod("Dark Restock", 1)

DarkRestock.COLLECTIBLE_DARK_RESTOCK = Isaac.GetItemIdByName("Dark Restock")

local GameState = {}
local json = require("json")

local player
local currRoomIndex

local options = {0, 1, 2, 3, 4, 5, 99999}
local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

function DarkRestock:onStart()
	GameState = json.decode(DarkRestock:LoadData())

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[DarkRestock.COLLECTIBLE_DARK_RESTOCK] = "Devil rooms and black markets instantly restock their items when you buy them"

	player = Isaac.GetPlayer(0)
	DarkRestock.COLLECTIBLE_SHADY_PASS = Isaac.GetItemIdByName("Shady Pass")

	if GameState.lostOption == nil then
		GameState.lostOption = 1
	end

	if not alreadyPlayedOnceOnBoot then
		-- OptionsMod
		-- if optionsmod ~= nil and optionsmod.RegisterNewSetting ~= nil then
		-- 	DarkRestockOptionsMod()
		-- else
		-- 	if optionsmod_init == nil then
		-- 		optionsmod_init = {}
		-- 	end
		-- 	optionsmod_init[#optionsmod_init+1] = DarkRestockOptionsMod
		-- end

		-- Mod Config Menu
		if ModConfigMenu then
			ModConfigMenu.AddSpace("Dark Restock")
			ModConfigMenu.AddSetting("Dark Restock", { 
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
		GameState.oldNumDarkRestocks = 0
		GameState.roomItemValues = {} -- Table containing room index and position of each item spawned by devil room/black market
		GameState.crookedPennyFrame = -3
		GameState.inGoodRoom = false
		GameState.hadDarkRestock = false
		GameState.hadShadyPass = false
	end
end
DarkRestock:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, DarkRestock.onStart)

-- function DarkRestockOptionsMod()
-- 	optionsmod.RegisterMod("Dark Restock", {"Lost behavior"})
-- 	option = optionsmod.RegisterNewSetting({
-- 	    name = "# of restocks/floor",
-- 	    description = "Determines how many devil room/black market restocks per floor are allowed when playing as the Lost",
-- 	    category = "Lost behavior",
-- 	    type = "normal",
-- 	    options = {{"0", 0}, {"1", 1}, {"2", 2}, {"3", 3}, {"4", 4}, {"5", 5}, {"Unlimited", 99999}},
-- 	    default = 2 -- option #2 (one per floor), not value 2
-- 	})
-- 	alreadyPlayedOnceOnBoot = true
-- end

function DarkRestock:onExit(save)
	DarkRestock:SaveData(json.encode(GameState))
end
DarkRestock:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, DarkRestock.onExit)
DarkRestock:AddCallback(ModCallbacks.MC_POST_GAME_END, DarkRestock.onExit)

function DarkRestock:onUpdate()
	local numDarkRestocks = player:GetCollectibleNum(DarkRestock.COLLECTIBLE_DARK_RESTOCK)
	if numDarkRestocks > GameState.oldNumDarkRestocks then
		local pickupTypeList = {PickupVariant.PICKUP_HEART, PickupVariant.PICKUP_COIN, PickupVariant.PICKUP_KEY, PickupVariant.PICKUP_BOMB, PickupVariant.PICKUP_PILL, PickupVariant.PICKUP_LIL_BATTERY, PickupVariant.PICKUP_TAROTCARD, PickupVariant.PICKUP_TRINKET}
		for i=1,3 do
			Isaac.Spawn(EntityType.ENTITY_PICKUP, pickupTypeList[math.random(1,8)], 0, Isaac.GetFreeNearPosition(Vector(player.Position.X + 20*math.random(-1,1), player.Position.Y + 20*math.random(-1,1)), 0), Vector(0,0), nil):ToPickup()
		end
		GameState.oldNumDarkRestocks = numDarkRestocks
	end
	if GameState.inGoodRoom and player:HasCollectible(DarkRestock.COLLECTIBLE_DARK_RESTOCK) and ((player:GetPlayerType() ~= PlayerType.PLAYER_THELOST and player:GetPlayerType() ~= PlayerType.PLAYER_THELOST_B) or GameState.numRestocksUsedOnFloor < GameState.lostOption) then
		local currFrame = Game():GetFrameCount()
		if currFrame == GameState.crookedPennyFrame + 1 then
			DarkRestock:getItemValues()
			if #GameState.roomItemValues == 0 then
				GameState.inGoodRoom = false
				return
			end
		end
		if not GameState.hadDarkRestock then
			DarkRestock:getItemValues()
		end
		currRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
		if GameState.roomItemValues[currRoomIndex] ~= nil then
			local hasShadyPass = DarkRestock.COLLECTIBLE_SHADY_PASS ~= -1 and player:HasCollectible(DarkRestock.COLLECTIBLE_SHADY_PASS)
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
							DarkRestock:spawnFromPool(ItemPoolType.POOL_DEVIL, newItemPos, DarkRestock:getPrice(), GameState.startSeed)
						else
							DarkRestock:spawnFromPool(ItemPoolType.POOL_SHOP, newItemPos, DarkRestock:getPrice(), GameState.startSeed)
						end
						GameState.numRestocksUsedOnFloor = GameState.numRestocksUsedOnFloor + 1
						if currRoomIndex == GameState.originalRoomIndex and DarkRestock.COLLECTIBLE_SHADY_PASS ~= -1 and hasShadyPass then
							ShadyPass.itemSpawnPos = newItemPos
						end
						GameState.roomItemValues[currRoomIndex][i][1] = newItemPos
					end
				end
			end
		end
	end
	GameState.hadDarkRestock = player:HasCollectible(DarkRestock.COLLECTIBLE_DARK_RESTOCK)
end

function DarkRestock:onNewLevel()
	GameState.originalRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
	if DarkRestock.COLLECTIBLE_SHADY_PASS ~= -1 then
		DarkRestock:addRoomPosPair(currRoomIndex, Isaac.GetFreeNearPosition(Vector(180,160), 0)) -- Shady Pass initial item spawn position
	end
	GameState.hadShadyPass = DarkRestock.COLLECTIBLE_SHADY_PASS ~= -1 and Isaac.GetPlayer(0):HasCollectible(Isaac.GetItemIdByName("Shady Pass"))
	GameState.numRestocksUsedOnFloor = 0
end

function DarkRestock:getItemValues()
	currRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
	GameState.roomItemValues = {}
	local roomType = Game():GetRoom():GetType()
	if roomType == RoomType.ROOM_DEVIL or roomType == RoomType.ROOM_BLACK_MARKET or (currRoomIndex == GameState.originalRoomIndex and DarkRestock.COLLECTIBLE_SHADY_PASS ~= -1) then
		GameState.inGoodRoom = true
		for _, entity in pairs(Isaac.GetRoomEntities()) do
			if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity:ToPickup().Price < 0 then
				DarkRestock:addRoomPosPair(currRoomIndex, Vector(entity.Position.X, entity.Position.Y))
			end
		end
	else
		GameState.inGoodRoom = false
	end
end

function DarkRestock:spawnFromPool(pool, pos, price, seed)
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

function DarkRestock:addRoomPosPair(roomIndex, itemPos)
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

function DarkRestock:getPrice()
	local price = PickupPrice.PRICE_ONE_HEART
	if player:GetMaxHearts() == 0 then
		price = PickupPrice.PRICE_THREE_SOULHEARTS
	end
	return price
end

function DarkRestock:useCrookedPenny()
	GameState.crookedPennyFrame = Game():GetFrameCount()
end

DarkRestock:AddCallback(ModCallbacks.MC_POST_UPDATE, DarkRestock.onUpdate);
DarkRestock:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, DarkRestock.onNewLevel)
DarkRestock:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DarkRestock.getItemValues)
DarkRestock:AddCallback(ModCallbacks.MC_USE_ITEM, DarkRestock.useCrookedPenny, CollectibleType.COLLECTIBLE_CROOKED_PENNY)