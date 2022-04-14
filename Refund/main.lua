Refund = RegisterMod("Refund", 1)

Refund.COLLECTIBLE_REFUND = Isaac.GetItemIdByName("Refund")

local GameState = {}
local json = require("json")

local player

function Refund:onStart()
	GameState = json.decode(Refund:LoadData())

	player = Isaac.GetPlayer(0)

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[Refund.COLLECTIBLE_REFUND] = "Spawns pennies when an active item is used, depending on luck and the item's charge"
end

function Refund:onExit(save)
	for i=1,GameState.r_highestID do
		if GameState.r_activeItems[i] == nil then
			GameState.r_activeItems[i] = 0
		end
	end
	Refund:SaveData(json.encode(GameState))
end

Refund:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Refund.onStart)
Refund:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, Refund.onExit)
Refund:AddCallback(ModCallbacks.MC_POST_GAME_END, Refund.onExit)

function Refund:r_onStart()
	if Game():GetFrameCount() < 5 then
		GameState.r_activeItems = {}
		GameState.r_highestID = -1
	end
end

function Refund:r_spawnCoins()
	if player:HasCollectible(Refund.COLLECTIBLE_REFUND) then
		local chargeTime = player:GetActiveCharge()
		local activeItem = player:GetActiveItem()
		GameState.r_highestID = math.max(GameState.r_highestID, activeItem)
		if GameState.r_activeItems[activeItem] == nil then
			GameState.r_activeItems[activeItem] = 0
		end
		-- timed items, Breath of Life, and Isaac's Tears (which technically aren't timed items, but are easily infinitely reusable)
		if chargeTime > 12 or activeItem == CollectibleType.COLLECTIBLE_BREATH_OF_LIFE or activeItem == CollectibleType.COLLECTIBLE_ISAACS_TEARS then -- or (chargeTime == 1 and Isaac.GetPlayer(0):GetCollectibleNum(CollectibleType.COLLECTIBLE_NINE_VOLT))
			chargeTime = 0
		end
		local luck = player.Luck
		local numCoins = Refund:getNumCoins(chargeTime, luck)
		for i=1,numCoins do
			if GameState.r_activeItems[activeItem] < 15 then
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, Isaac.GetFreeNearPosition(Vector(player.Position.X, player.Position.Y), 0), Vector(0,0), player)
				GameState.r_activeItems[activeItem] = GameState.r_activeItems[activeItem] + 1
			end
		end
	end
end

function Refund:getNumCoins(chargeTime, luck)
	local numRefunds = player:GetCollectibleNum(Refund.COLLECTIBLE_REFUND)
	local value = chargeTime*(1/3)*(1 + (1/6)*(luck+1)) * 1.3^(numRefunds-1) -- Matches Sack of Pennies (one penny every two rooms) at 2 luck (assuming no 9 Volt, AAA Battery, Car Battery, etc)
	-- Example: if value == 2.4, then there is a 40% chance it will go up to 3, or 60% chance it will go down to 2
	if math.random(1000) <= (value%1)*1000 then
		value = math.ceil(value)
	else
		value = math.floor(value)
	end
	-- return math.min(value, 3)
	return value
end

-- Using Void activates the MC_USE_ITEM callback for itself and every absorbed item. This method only activates the Refund for Void itself and ignores absorbed items.
function Refund:r_useNonVoidItem()
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
		Refund:r_spawnCoins()
	end
end

Refund:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Refund.r_onStart)
Refund:AddCallback(ModCallbacks.MC_USE_ITEM, Refund.r_spawnCoins, CollectibleType.COLLECTIBLE_VOID)
Refund:AddCallback(ModCallbacks.MC_USE_ITEM, Refund.r_useNonVoidItem)