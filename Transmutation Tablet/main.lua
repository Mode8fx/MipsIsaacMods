local TransmutationTablet = RegisterMod("Transmutation Tablet", 1)

TransmutationTablet.COLLECTIBLE_TRANSMUTATION_TABLET = Isaac.GetItemIdByName("Transmutation Tablet")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local players = {}
-- local playerTypes = {}
local usingItem = {false, false, false, false}
local oldCharge = {0, 0, 0, 0}
local oldBatteryCharge = {0, 0, 0, 0}
local NUM_CS_LINES = 12
local conversionString = {}
for i = 1, 4 do
    conversionString[i] = {}
    for j = 1, NUM_CS_LINES do
        conversionString[i][j] = nil
    end
end
local costMet = {
	{false, false, false, false},
	{false, false, false, false},
	{false, false, false, false},
	{false, false, false, false}
}
local conversionFrame = {-150, -150, -150, -150}
local playerNum = 0

function TransmutationTablet:onStart()
	if TransmutationTablet:HasData() then
		GameState = json.decode(TransmutationTablet:LoadData())
	else
		GameState = {}
	end

	players = getPlayers()
	-- playerTypes = getPlayerTypes()
	initializeAllVars()

	oldCharge = {0, 0, 0, 0}
	oldBatteryCharge = {0, 0, 0, 0}
	for i = 1, 4 do
		conversionString[i] = {}
		for j = 1, NUM_CS_LINES do
			conversionString[i][j] = nil
		end
	end
	costMet = {
		{false, false, false, false},
		{false, false, false, false},
		{false, false, false, false},
		{false, false, false, false}
	}
	conversionFrame = {-150, -150, -150, -150}

	if not alreadyPlayedOnceOnBoot then
		if ModConfigMenu then
			ModConfigMenu.AddSpace("Transmutation Tablet")
			ModConfigMenu.AddSetting("Transmutation Tablet", {
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.qualityCostZeroToOne
				end,
				Display = function()
					return "0->1 item cost: " .. GameState.qualityCostZeroToOne .. " items"
				end,
				Minimum = 1,
				Maximum = 6,
				ModifyBy = 1,
				Default = 2,
				OnChange = function(currentNum)
					GameState.qualityCostZeroToOne = currentNum
				end,
				Info = {
					"Set how many 0-quality items",
					"are needed for a 1-quality item."
				}
			})
			ModConfigMenu.AddSpace("Transmutation Tablet")
			ModConfigMenu.AddSetting("Transmutation Tablet", {
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.qualityCostOneToTwo
				end,
				Display = function()
					return "1->2 item cost: " .. GameState.qualityCostOneToTwo .. " items"
				end,
				Minimum = 1,
				Maximum = 6,
				ModifyBy = 1,
				Default = 2,
				OnChange = function(currentNum)
					GameState.qualityCostOneToTwo = currentNum
				end,
				Info = {
					"Set how many 1-quality items",
					"are needed for a 2-quality item."
				}
			})
			ModConfigMenu.AddSpace("Transmutation Tablet")
			ModConfigMenu.AddSetting("Transmutation Tablet", {
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.qualityCostTwoToThree
				end,
				Display = function()
					return "2->3 item cost: " .. GameState.qualityCostTwoToThree .. " items"
				end,
				Minimum = 1,
				Maximum = 6,
				ModifyBy = 1,
				Default = 2,
				OnChange = function(currentNum)
					GameState.qualityCostTwoToThree = currentNum
				end,
				Info = {
					"Set how many 2-quality items",
					"are needed for a 3-quality item."
				}
			})
			ModConfigMenu.AddSpace("Transmutation Tablet")
			ModConfigMenu.AddSetting("Transmutation Tablet", {
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.qualityCostThreeToFour
				end,
				Display = function()
					return "3->4 item cost: " .. GameState.qualityCostThreeToFour .. " items"
				end,
				Minimum = 1,
				Maximum = 6,
				ModifyBy = 1,
				Default = 4,
				OnChange = function(currentNum)
					GameState.qualityCostThreeToFour = currentNum
				end,
				Info = {
					"Set how many 3-quality items",
					"are needed for a 4-quality item."
				}
			})
		end
		alreadyPlayedOnceOnBoot = true
	end

	-- External Item Description
	if not __eidItemTransformations then
		__eidItemTransformations = {}
	end
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[TransmutationTablet.COLLECTIBLE_TRANSMUTATION_TABLET] = (
		"Converts passive items of a low quality into a passive item of a higher quality" ..
		"#Aside from quality, the selected items are random" ..
		"#0->1: " .. GameState.qualityCostZeroToOne .. " items" ..
		"#1->2: " .. GameState.qualityCostOneToTwo .. " items" ..
		"#2->3: " .. GameState.qualityCostTwoToThree .. " items" ..
		"#3->4: " .. GameState.qualityCostThreeToFour .. " items"
	)
end
TransmutationTablet:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, TransmutationTablet.onStart)

function initializeVar(var, value)
	if var == nil then
		var = value
	end
	return var
end

function initializeAllVars()
	GameState.qualityCostZeroToOne = initializeVar(GameState.qualityCostZeroToOne, 2)
	GameState.qualityCostOneToTwo = initializeVar(GameState.qualityCostOneToTwo, 2)
	GameState.qualityCostTwoToThree = initializeVar(GameState.qualityCostTwoToThree, 2)
	GameState.qualityCostThreeToFour = initializeVar(GameState.qualityCostThreeToFour, 4)
end

function TransmutationTablet:onExit(save)
	TransmutationTablet:SaveData(json.encode(GameState))
end
TransmutationTablet:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, TransmutationTablet.onExit)
TransmutationTablet:AddCallback(ModCallbacks.MC_POST_GAME_END, TransmutationTablet.onExit)

function TransmutationTablet:onRender()
	for playerNum=1,Game():GetNumPlayers() do
		if usingItem[playerNum] then
			local playerPos = Game():GetRoom():WorldToScreenPosition(players[playerNum].Position)
			if costMet[playerNum][1] then
				Isaac.RenderText("0->1", playerPos.X-42, playerPos.Y-24, 1, 1, 1, 1)
			else
				Isaac.RenderText("0->1", playerPos.X-42, playerPos.Y-24, 1, 0.1, 0.1, 1)
			end
			if costMet[playerNum][2] then
				Isaac.RenderText("1->2", playerPos.X-12, playerPos.Y-46, 1, 1, 1, 1)
			else
				Isaac.RenderText("1->2", playerPos.X-12, playerPos.Y-46, 1, 0.1, 0.1, 1)
			end
			if costMet[playerNum][3] then
				Isaac.RenderText("2->3", playerPos.X+19, playerPos.Y-24, 1, 1, 1, 1)
			else
				Isaac.RenderText("2->3", playerPos.X+19, playerPos.Y-24, 1, 0.1, 0.1, 1)
			end
			if costMet[playerNum][4] then
				Isaac.RenderText("3->4", playerPos.X-12, playerPos.Y+4, 1, 1, 1, 1)
			else
				Isaac.RenderText("3->4", playerPos.X-12, playerPos.Y+4, 1, 0.1, 0.1, 1)
			end
		end
		if conversionString[playerNum][1] ~= nil then
			local currFrame = Game():GetFrameCount()
			if currFrame < conversionFrame[playerNum] + 90 then
				local playerPos = Game():GetRoom():WorldToScreenPosition(players[playerNum].Position)
				local opacity = 1-((currFrame-conversionFrame[playerNum])/90)
				for i=1,NUM_CS_LINES do
					Isaac.RenderText(conversionString[playerNum][i], playerPos.X+18, playerPos.Y-148+(12*i), 1, 0.1, 0.1, opacity)
				end
			else
				for i=1,NUM_CS_LINES do
					conversionString[playerNum][i] = nil
				end
			end
		end
	end
end

function TransmutationTablet:onUpdate()
	if players[playerNum] == nil then
		players = getPlayers()
	end
	for playerNum=1,Game():GetNumPlayers() do
		if usingItem[playerNum] and players[playerNum]:GetActiveItem() ~= CollectibleType.COLLECTIBLE_VOID then
			local oldQuality
			local newQuality
			local cost
			local currPlayerIsEsau = 0
			if players[playerNum]:GetPlayerType()==20 then
				currPlayerIsEsau = 1
			end
			if Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, playerNum-1-currPlayerIsEsau) then
				oldQuality = 0
				newQuality = 1
				cost = GameState.qualityCostZeroToOne
			elseif Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, playerNum-1-currPlayerIsEsau) then
				oldQuality = 1
				newQuality = 2
				cost = GameState.qualityCostOneToTwo
			elseif Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, playerNum-1-currPlayerIsEsau) then
				oldQuality = 2
				newQuality = 3
				cost = GameState.qualityCostTwoToThree
			elseif Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, playerNum-1-currPlayerIsEsau) then
				oldQuality = 3
				newQuality = 4
				cost = GameState.qualityCostThreeToFour
			end
			if oldQuality ~= nil then
				TransmutationTablet:convertItems(oldQuality, newQuality, cost)
				usingItem[playerNum] = false
			end
		end
	end
end

function TransmutationTablet:convertItems(oldQuality, newQuality, cost)
	-- playerNum has already been set
	local numUses = 1
	if players[playerNum]:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) then
		numUses = 2
	end
	for i=1,NUM_CS_LINES do
		conversionString[playerNum][i] = ""
	end
	local didConversion = false -- for Car Battery
	local lineNum = NUM_CS_LINES
	for i=1,numUses do
		local lowQualityItems = TransmutationTablet:getOwnedPassiveItemsByQuality(oldQuality)
		if #lowQualityItems >= cost then
			for i=1,cost do
				lowQualityItems = TransmutationTablet:getOwnedPassiveItemsByQuality(oldQuality)
				local itemToRemove = lowQualityItems[math.random(#lowQualityItems)]
				players[playerNum]:RemoveCollectible(itemToRemove)
				conversionString[playerNum][lineNum] = "- " .. TransmutationTablet:getLocalizedItemName(itemToRemove)
				lineNum = lineNum - 1
			end
			local highQualityItems = TransmutationTablet:getAllPassiveItemsByQuality(newQuality)
			local itemToAdd = highQualityItems[math.random(#highQualityItems)]
			-- players[playerNum]:AddCollectible(itemToAdd)
			-- if not didConversion then
			-- 	conversionString[playerNum][NUM_CS_LINES] = "+ " .. TransmutationTablet:getLocalizedItemName(itemToAdd)
			-- end
			-- players[playerNum]:AnimateHappy()
			local room = Game():GetRoom()
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, itemToAdd,
				room:FindFreePickupSpawnPosition(room:GetCenterPos()), Vector.Zero, nil)
			SFXManager():Play(SoundEffect.SOUND_SLOTSPAWN, 1, 0, false, 1)
			players[playerNum]:AnimateCollectible(TransmutationTablet.COLLECTIBLE_TRANSMUTATION_TABLET, "HideItem", "Idle")
		else
			if not didConversion then
				conversionString[playerNum][NUM_CS_LINES] = "Not enough items..."
				-- players[playerNum]:AnimateSad()
				-- SFXManager():Play(SoundEffect.SOUND_THUMBS_DOWN, 1, 0, false, 1)
				players[playerNum]:AnimateCollectible(TransmutationTablet.COLLECTIBLE_TRANSMUTATION_TABLET, "HideItem", "Idle")
				TransmutationTablet:refreshItemChargeOnePlayer(players[playerNum])
			end
		end
		didConversion = true
	end
	conversionFrame[playerNum] = Game():GetFrameCount()
	players[playerNum]:EvaluateItems()
end

function TransmutationTablet:getLocalizedItemName(itemID)
	if REPENTOGON then
		return Isaac.GetLocalizedString("Items", Isaac.GetItemConfig():GetCollectible(itemID).Name, Options.Language)
	else
		return Isaac.GetItemConfig():GetCollectible(itemID).Name
	end
end

function TransmutationTablet:getAllPassiveItemsByQuality(quality)
    local items = {}
	local itemConfig = Isaac.GetItemConfig()
    for i=1,CollectibleType.NUM_COLLECTIBLES - 1 do
		local currItem = itemConfig:GetCollectible(i)
		if currItem and currItem.Quality == quality and (currItem.Type == ItemType.ITEM_PASSIVE or currItem.Type == ItemType.ITEM_FAMILIAR) and currItem:IsAvailable() and not currItem:HasTags(ItemConfig.TAG_QUEST) then
			table.insert(items, i)
		end
    end
    return items
end

function TransmutationTablet:getOwnedPassiveItemsByQuality(quality)
    local items = {}
	local itemConfig = Isaac.GetItemConfig()
    for i=1,CollectibleType.NUM_COLLECTIBLES - 1 do
        local count = players[playerNum]:GetCollectibleNum(i, true)
        if count > 0 then
            local currItem = itemConfig:GetCollectible(i)
            if currItem and currItem.Quality == quality and (currItem.Type == ItemType.ITEM_PASSIVE or currItem.Type == ItemType.ITEM_FAMILIAR) and not currItem:HasTags(ItemConfig.TAG_QUEST) then
                for _ = 1, count do
                    table.insert(items, i)
                end
            end
        end
    end
    return items
end

function TransmutationTablet:useItem(collectibleType, rng, player, flags, activeSlot, customVarData)
	playerNum = getCurrPlayerNum(player)
	if not usingItem[playerNum] then
		if player:GetActiveItem() ~= CollectibleType.COLLECTIBLE_VOID then
			player:AnimateCollectible(TransmutationTablet.COLLECTIBLE_TRANSMUTATION_TABLET, "LiftItem", "Idle")
		end
		usingItem[playerNum] = true
		oldCharge[playerNum] = player:GetActiveCharge()
		oldBatteryCharge[playerNum] = player:GetBatteryCharge()
		local zeroQualityItems = TransmutationTablet:getOwnedPassiveItemsByQuality(0)
		costMet[playerNum][1] = #zeroQualityItems >= GameState.qualityCostZeroToOne
		local oneQualityItems = TransmutationTablet:getOwnedPassiveItemsByQuality(1)
		costMet[playerNum][2] = #oneQualityItems >= GameState.qualityCostOneToTwo
		local twoQualityItems = TransmutationTablet:getOwnedPassiveItemsByQuality(2)
		costMet[playerNum][3] = #twoQualityItems >= GameState.qualityCostTwoToThree
		local threeQualityItems = TransmutationTablet:getOwnedPassiveItemsByQuality(3)
		costMet[playerNum][4] = #threeQualityItems >= GameState.qualityCostThreeToFour
	end
end

function TransmutationTablet:onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if target and target.Type == EntityType.ENTITY_PLAYER then
		TransmutationTablet:refreshItemChargeOnePlayer(target:ToPlayer())
	end
end

function TransmutationTablet:refreshItemChargeOnePlayer(player)
	playerNum = getCurrPlayerNum(player)
	if usingItem[playerNum] and players[playerNum]:GetActiveItem() == TransmutationTablet.COLLECTIBLE_TRANSMUTATION_TABLET then
		players[playerNum]:SetActiveCharge(oldCharge[playerNum] + oldBatteryCharge[playerNum])
	end
	usingItem[playerNum] = false
end

function TransmutationTablet:refreshItemChargeAllPlayers()
	for playerNum=1,Game():GetNumPlayers() do
		if usingItem[playerNum] and players[playerNum]:GetActiveItem() == TransmutationTablet.COLLECTIBLE_TRANSMUTATION_TABLET then
			players[playerNum]:SetActiveCharge(oldCharge[playerNum] + oldBatteryCharge[playerNum])
		end
		usingItem[playerNum] = false
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

TransmutationTablet:AddCallback(ModCallbacks.MC_POST_RENDER, TransmutationTablet.onRender)
TransmutationTablet:AddCallback(ModCallbacks.MC_POST_UPDATE, TransmutationTablet.onUpdate)
TransmutationTablet:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, TransmutationTablet.refreshItemChargeAllPlayers)
TransmutationTablet:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, TransmutationTablet.refreshItemChargeAllPlayers)
TransmutationTablet:AddCallback(ModCallbacks.MC_USE_ITEM, TransmutationTablet.useItem, TransmutationTablet.COLLECTIBLE_TRANSMUTATION_TABLET)
TransmutationTablet:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, TransmutationTablet.onHit)