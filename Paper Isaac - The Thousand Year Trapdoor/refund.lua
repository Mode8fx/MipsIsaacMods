Refund = RegisterMod("Refund", 1)

Refund.COLLECTIBLE_REFUND = Isaac.GetItemIdByName("Refund")

local GameState = {}
local json = require("json")

local players = {}
local playerNum = 0

function Refund:onStart()
	if Refund:HasData() then
		GameState = json.decode(Refund:LoadData())
	else
		GameState = {}
	end

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[Refund.COLLECTIBLE_REFUND] = "Spawns pennies when an active item is used, depending on luck and the item's charge"

	players = getPlayers()
end

function Refund:onExit(save)
	for playerNum=1,8 do
		for i=1,GameState.r_highestID[playerNum] do
			if GameState.r_activeItems[playerNum][i] == nil then
				GameState.r_activeItems[playerNum][i] = 0
			end
		end
	end
	Refund:SaveData(json.encode(GameState))
end

Refund:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Refund.onStart)
Refund:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, Refund.onExit)
Refund:AddCallback(ModCallbacks.MC_POST_GAME_END, Refund.onExit)

function initializeVar(var, value)
	if var == nil then
		var = value
	end
	return var
end

function Refund:r_onStart()
	if Game():GetFrameCount() < 5 then
		-- initialize all variables
		GameState.r_activeItems = {}
		GameState.r_highestID = {-1, -1, -1, -1, -1, -1, -1, -1}
		for playerNum=1,8 do
			GameState.r_activeItems[playerNum] = {}
		end
	end
end

function Refund:r_spawnCoins(playerNum)
	if players[playerNum]:HasCollectible(Refund.COLLECTIBLE_REFUND) then
		local chargeTime = players[playerNum]:GetActiveCharge()
		local activeItem = players[playerNum]:GetActiveItem()
		GameState.r_highestID[playerNum] = math.max(GameState.r_highestID[playerNum], activeItem)
		if GameState.r_activeItems[playerNum][activeItem] == nil then
			GameState.r_activeItems[playerNum][activeItem] = 0
		end
		-- timed items, Breath of Life, and Isaac's Tears (which technically aren't timed items, but are easily infinitely reusable)
		if chargeTime > 12 or activeItem == CollectibleType.COLLECTIBLE_BREATH_OF_LIFE or activeItem == CollectibleType.COLLECTIBLE_ISAACS_TEARS then -- or (chargeTime == 1 and Isaac.GetPlayer(0):GetCollectibleNum(CollectibleType.COLLECTIBLE_NINE_VOLT))
			chargeTime = 0
		end
		local luck = players[playerNum].Luck
		local numCoins = Refund:getNumCoins(chargeTime, luck, playerNum)
		for i=1,numCoins do
			if GameState.r_activeItems[playerNum][activeItem] < 15 then
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, Isaac.GetFreeNearPosition(Vector(players[playerNum].Position.X, players[playerNum].Position.Y), 0), Vector(0,0), players[playerNum])
				GameState.r_activeItems[playerNum][activeItem] = GameState.r_activeItems[playerNum][activeItem] + 1
			end
		end
	end
end

function Refund:getNumCoins(chargeTime, luck, playerNum)
	local numRefunds = players[playerNum]:GetCollectibleNum(Refund.COLLECTIBLE_REFUND)
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
function Refund:r_useItem(collectibleType, rng, player, useFlags, activeSlot, customVarData)
	playerNum = getCurrPlayerNum(player)
	if (not player:HasCollectible(CollectibleType.COLLECTIBLE_VOID)) or (ct == CollectibleType.COLLECTIBLE_VOID) then
		Refund:r_spawnCoins(playerNum)
	end
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

function getCurrPlayerNum(player)
	for i = 1, #players do
		if player:GetPlayerType() == players[i]:GetPlayerType() then
			return i
		end
	end
	return -1
end

Refund:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Refund.r_onStart)
Refund:AddCallback(ModCallbacks.MC_USE_ITEM, Refund.r_useItem)