local Inheritance = RegisterMod("Inheritance", 1)

Inheritance.TRINKET_INHERITANCE = Isaac.GetTrinketIdByName("Inheritance")

local GameState = {}
local json = require("json")

function Inheritance:onStart()
	GameState = json.decode(Inheritance:LoadData())

	-- External Item Description
	if not __eidTrinketDescriptions then
		__eidTrinketDescriptions = {}
	end
	__eidTrinketDescriptions[Inheritance.TRINKET_INHERITANCE] = "Drops things on player's expected last floor:#Sheol: Devil item + black heart#Cat: Angel item + soul heart#DR: Red chest item + bomb#Chest: Golden chest item + key#Void: Boss item + trinket"

	if Game():GetFrameCount() == 0 then
		GameState.alreadyFoundLastStage = false
	end
end
Inheritance:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Inheritance.onStart)

function Inheritance:onExit(save)
	Inheritance:SaveData(json.encode(GameState))
end
Inheritance:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, Inheritance.onExit)
Inheritance:AddCallback(ModCallbacks.MC_POST_GAME_END, Inheritance.onExit)

function Inheritance:onNewLevel()
	local player = Isaac.GetPlayer(0)
	local startSeed = Game():GetSeeds():GetStartSeed()
	local currStage = Game():GetLevel():GetStage() -- 1 = Chapter 1, 2 = Chapter 2...
	local currStageType = Game():GetLevel():GetStageType() -- On Chapter 1: 0 = Basement, 1 = Cellar, 2 = Burning Basement...
	local itemType = nil
	local pickupType = nil
	local pickupSubType = nil
	-- Sheol
	if currStage == 10 and currStageType == 0 and not player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then
		itemType = ItemPoolType.POOL_DEVIL
		pickupType = PickupVariant.PICKUP_HEART
		pickupSubType = HeartSubType.HEART_BLACK
	end
	-- Cathedral
	if currStage == 10 and currStageType == 1 and not player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then
		itemType = ItemPoolType.POOL_ANGEL
		pickupType = PickupVariant.PICKUP_HEART
		pickupSubType = HeartSubType.HEART_SOUL
	end
	-- Dark Room
	if currStage == 11 and currStageType == 0 then
		itemType = ItemPoolType.POOL_RED_CHEST
		pickupType = PickupVariant.PICKUP_BOMB
		pickupSubType = BombSubType.BOMB_NORMAL
		if player:HasCollectible(CollectibleType.COLLECTIBLE_HUMBLEING_BUNDLE) or player:HasCollectible(CollectibleType.COLLECTIBLE_BOGO_BOMBS) then
			pickupSubType = BombSubType.BOMB_DOUBLEPACK
		end
	end
	-- Chest
	if currStage == 11 and currStageType == 1 then
		itemType = ItemPoolType.POOL_GOLDEN_CHEST
		pickupType = PickupVariant.PICKUP_KEY
		pickupSubType = KeySubType.KEY_NORMAL
		if player:HasCollectible(CollectibleType.COLLECTIBLE_HUMBLEING_BUNDLE) then
			pickupSubType = KeySubType.KEY_DOUBLEPACK
		end
	end
	-- Void
	if currStage == 12 then
		itemType = ItemPoolType.POOL_BOSS
		pickupType = PickupVariant.PICKUP_TRINKET
		-- local i = 0
		-- while pickupSubType == Inheritance.TRINKET_INHERITANCE and i < 32 do
		pickupSubType = 0
			-- i = i + 1
		-- end
	end
	-- Corpse
	if currStage == 8 and currStageType == 4 then
		itemType = ItemPoolType.POOL_CURSE
		pickupType = PickupVariant.PICKUP_HEART
		pickupSubType = HeartSubType.HEART_ROTTEN
	end
	-- Home
	if currStage == 13 and currStageType == 0 then
		itemType = ItemPoolType.POOL_SECRET
		pickupType = PickupVariant.PICKUP_TAROTCARD
		pickupSubType = 0
	end
	if itemType ~= nil then
		Game():GetItemPool():RemoveTrinket(Inheritance.TRINKET_INHERITANCE)
		if (not GameState.alreadyFoundLastStage) and player:HasTrinket(Inheritance.TRINKET_INHERITANCE) then
			player:TryRemoveTrinket(Inheritance.TRINKET_INHERITANCE)
			-- Everything involving hasNo accounts for the rare situation where the player smelted/gulped Inheritance and filled the rest of their trinket slots, meaning No! can't be equipped
			local hasNo = player:HasTrinket(TrinketType.TRINKET_NO)
			local topTrinket = 0
			local canHoldTrinket = true
			if not hasNo then
				-- player:GetEffects():AddTrinketEffect(TrinketType.TRINKET_NO, false)
				local maxTrinkets = player:GetMaxTrinkets()
				local trinket0 = player:GetTrinket(0)
				local trinket1 = player:GetTrinket(1)
				canHoldTrinket = (maxTrinkets == 1 and trinket0 == 0) or (maxTrinkets == 2 and trinket1 == 0)
				if not canHoldTrinket then
					if maxTrinkets == 1 then
						topTrinket = trinket0
					else
						topTrinket = trinket1
					end
					player:TryRemoveTrinket(topTrinket)
				end
				player:AddTrinket(TrinketType.TRINKET_NO)
			end
			Isaac.Spawn(
				EntityType.ENTITY_PICKUP,
				PickupVariant.PICKUP_COLLECTIBLE,
				Game():GetItemPool():GetCollectible(itemType, true, startSeed),
				Isaac.GetFreeNearPosition(Vector(270,220), 0),
				Vector(0,0),
				nil
			):ToPickup()
			Isaac.Spawn(
				EntityType.ENTITY_PICKUP,
				pickupType,
				pickupSubType,
				Isaac.GetFreeNearPosition(Vector(350,220), 0),
				Vector(0,0),
				nil
			):ToPickup()
			if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_BOX) then
				Isaac.Spawn(
					EntityType.ENTITY_PICKUP,
					PickupVariant.PICKUP_COLLECTIBLE,
					Game():GetItemPool():GetCollectible(itemType, true, startSeed),
					Isaac.GetFreeNearPosition(Vector(270,300), 0),
					Vector(0,0),
					nil
				):ToPickup()
				Isaac.Spawn(
					EntityType.ENTITY_PICKUP,
					pickupType,
					pickupSubType,
					Isaac.GetFreeNearPosition(Vector(350,300), 0),
					Vector(0,0),
					nil
				):ToPickup()
			end
			if not hasNo then
				-- player:GetEffects():RemoveTrinketEffect(TrinketType.TRINKET_NO)
				player:TryRemoveTrinket(TrinketType.TRINKET_NO)
				if not canHoldTrinket then
					player:AddTrinket(topTrinket)
				end
			end
		else
			player:TryRemoveTrinket(Inheritance.TRINKET_INHERITANCE)
		end
		GameState.alreadyFoundLastStage = true
	end
end

Inheritance:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, Inheritance.onNewLevel)