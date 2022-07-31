local SelfHelpBook = RegisterMod("Self-Help Book", 1)

SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK = Isaac.GetItemIdByName("Self-Help Book")

SelfHelpBook.CHALLENGE_SELF_HELP_1 = Isaac.GetChallengeIdByName("Self-Help (DR)")
SelfHelpBook.CHALLENGE_SELF_HELP_2 = Isaac.GetChallengeIdByName("Self-Help (Chest)")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local players = {}
-- local playerTypes = {}
local usingItem = {false, false, false, false}
local damageUpVal = 0.5
local rangeUpVal_rep = 30 -- Repentance completely changes how Range is modified via API
local rangeUpVal_abp = 2.5
local speedUpVal = 0.15
local luckUpVal = 1
local oldCharge = {0, 0, 0, 0}
local oldBatteryCharge = {0, 0, 0, 0}
local statUpString = {nil, nil, nil, nil}
local statUpFrame = {-150, -150, -150, -150}
local playerNum = 0
-- books is only used for AB+
local books = {
	CollectibleType.COLLECTIBLE_BIBLE,
	CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL,
	CollectibleType.COLLECTIBLE_NECRONOMICON,
	CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS,
	CollectibleType.COLLECTIBLE_ANARCHIST_COOKBOOK,
	CollectibleType.COLLECTIBLE_BOOK_REVELATIONS,
	CollectibleType.COLLECTIBLE_BOOK_OF_SIN,
	CollectibleType.COLLECTIBLE_MONSTER_MANUAL,
	CollectibleType.COLLECTIBLE_BOOK_OF_SECRETS,
	CollectibleType.COLLECTIBLE_HOW_TO_JUMP,
	CollectibleType.COLLECTIBLE_TELEPATHY_BOOK,
	CollectibleType.COLLECTIBLE_SATANIC_BIBLE,
	CollectibleType.COLLECTIBLE_BOOK_OF_THE_DEAD
}

function SelfHelpBook:onStart()
	if SelfHelpBook:HasData() then
		GameState = json.decode(SelfHelpBook:LoadData())
	else
		GameState = {}
	end

	-- External Item Description
	if not __eidItemTransformations then
		__eidItemTransformations = {}
	end
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemTransformations[SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK] = "12"
	__eidItemDescriptions[SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK] = "Gives a small, permanent stat boost on every use#Input a direction to give a higher chance of raising a specific stat"

	players = getPlayers()
	-- playerTypes = getPlayerTypes()
	initializeAllVars()

	SelfHelpBook.COLLECTIBLE_TRANSFORMER = Isaac.GetItemIdByName("Transformer")
	oldCharge = {0, 0, 0, 0}
	oldBatteryCharge = {0, 0, 0, 0}
	statUpString = {nil, nil, nil, nil}
	statUpFrame = {-150, -150, -150, -150}

	if not alreadyPlayedOnceOnBoot then
		if ModConfigMenu then
			ModConfigMenu.AddSpace("Self-Help Book")
			ModConfigMenu.AddSetting("Self-Help Book", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.statBoostValue
				end,
				Display = function()
					return "Stat boost value: " .. GameState.statBoostValue*100 .. "%"
				end,
				Minimum = 0.01,
				Maximum = 1,
				ModifyBy = 0.01,
				Default = 0.5,
				OnChange = function(currentNum)
					GameState.statBoostValue = currentNum
				end,
				Info = {
					"Set the size of the stat boost",
					"relative to a stat up pill."
				}
			})
			ModConfigMenu.AddSpace("Self-Help Book")
			ModConfigMenu.AddSetting("Self-Help Book", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.statPriorityValue
				end,
				Display = function()
					if GameState.statPriorityValue == 0 then
						return "Stat priority value: No priority"
					elseif GameState.statPriorityValue == 1 then
						return "Stat priority value: 50% chance"
					else
						return "Stat priority value: Guaranteed"
					end
				end,
				Minimum = 0,
				Maximum = 2,
				Default = 1,
				OnChange = function(currentNum)
					GameState.statPriorityValue = currentNum
				end,
				Info = {
					"Set the likelihood that your",
					"chosen stat will increase."
				}
			})
			ModConfigMenu.AddSpace("Self-Help Book")
			ModConfigMenu.AddSetting("Self-Help Book", {
				Type = ModConfigMenu.OptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.canBoostHealth
				end,
				Display = function()
					local choice = "False"
					if GameState.canBoostHealth then
						choice = "True"
					end
					return "Can boost health: " .. choice
				end,
				Default = true,
				OnChange = function(currentBool)
					GameState.canBoostHealth = currentBool
				end,
				Info = {
					"Set whether or not the item",
					"can randomly increase health."
				}
			})
		end
		alreadyPlayedOnceOnBoot = true
	end

	if Game():GetFrameCount() == 0 then
		GameState.numDamageUp = {0, 0, 0, 0}
		GameState.numRangeUp = {0, 0, 0, 0}
		GameState.numSpeedUp = {0, 0, 0, 0}
		GameState.numLuckUp = {0, 0, 0, 0}
		GameState.collectedBooks = {{}, {}, {}, {}}
		GameState.highestID = {-1, -1, -1, -1}
		GameState.transformed = {false, false, false, false}
	else
		SelfHelpBook:loadCollectedList()
	end

	if Game():GetFrameCount() == 0 and (Game().Challenge == SelfHelpBook.CHALLENGE_SELF_HELP_1 or Game().Challenge == SelfHelpBook.CHALLENGE_SELF_HELP_2) then
		players[0]:AddCollectible(SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK, 6, false)
		Game():GetItemPool():RemoveCollectible(SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK)
	end
end
SelfHelpBook:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SelfHelpBook.onStart)

function initializeVar(var, value)
	if var == nil then
		var = value
	end
	return var
end

function initializeAllVars()
	GameState.numDamageUp = initializeVar(GameState.numDamageUp, {})
	GameState.numRangeUp = initializeVar(GameState.numRangeUp, {})
	GameState.numSpeedUp = initializeVar(GameState.numSpeedUp, {})
	GameState.numLuckUp = initializeVar(GameState.numLuckUp, {})
	GameState.collectedBooks = initializeVar(GameState.collectedBooks, {{}, {}, {}, {}})
	GameState.highestID = initializeVar(GameState.highestID, {})
	GameState.transformed = initializeVar(GameState.transformed, {})
	for i=1,8 do
		GameState.numDamageUp[i] = initializeVar(GameState.numDamageUp[i], 0)
		GameState.numRangeUp[i] = initializeVar(GameState.numRangeUp[i], 0)
		GameState.numSpeedUp[i] = initializeVar(GameState.numSpeedUp[i], 0)
		GameState.numLuckUp[i] = initializeVar(GameState.numLuckUp[i], 0)
		GameState.collectedBooks[i] = initializeVar(GameState.collectedBooks[i], {})
		GameState.highestID[i] = initializeVar(GameState.highestID[i], -1)
		GameState.transformed[i] = initializeVar(GameState.transformed[i], false)
	end
	GameState.statBoostValue = initializeVar(GameState.statBoostValue, 0.5)
	GameState.statPriorityValue = initializeVar(GameState.statPriorityValue, 1)
	GameState.canBoostHealth = initializeVar(GameState.canBoostHealth, true)
end

function SelfHelpBook:onExit(save)
	for playerNum=1,8 do
		for i=1,GameState.highestID[playerNum] do
			if GameState.collectedBooks[playerNum][i] == nil then
				GameState.collectedBooks[playerNum][i] = false
			end
		end
	end
	SelfHelpBook:SaveData(json.encode(GameState))
end
SelfHelpBook:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SelfHelpBook.onExit)
SelfHelpBook:AddCallback(ModCallbacks.MC_POST_GAME_END, SelfHelpBook.onExit)

function SelfHelpBook:loadCollectedList()
	for playerNum=1,8 do
		local new_collectedBooks = {}
		for i=1, GameState.highestID[playerNum] do
			if GameState.collectedBooks[playerNum][i] == true then
				new_collectedBooks[playerNum][i] = true
			end
		end
		GameState.collectedBooks[playerNum] = new_collectedBooks
	end
end

function SelfHelpBook:onRender()
	for playerNum=1,Game():GetNumPlayers() do
		if usingItem[playerNum] and GameState.statPriorityValue > 0 then
			local playerPos = Game():GetRoom():WorldToScreenPosition(players[playerNum].Position)
			Isaac.RenderText("Damage", playerPos.X-18, playerPos.Y-52, 1, 1, 1, 1)
			Isaac.RenderText("^", playerPos.X-3, playerPos.Y-40, 1, 1, 1, 1)
			Isaac.RenderText("Range <", playerPos.X-60, playerPos.Y-24, 1, 1, 1, 1)
			Isaac.RenderText("> Speed", playerPos.X+18, playerPos.Y-24, 1, 1, 1, 1)
			Isaac.RenderText("v", playerPos.X-3, playerPos.Y, 1, 1, 1, 1)
			Isaac.RenderText("Luck", playerPos.X-12, playerPos.Y+12, 1, 1, 1, 1)
		end
		if statUpString[playerNum] ~= nil then
			local currFrame = Game():GetFrameCount()
			if currFrame < statUpFrame[playerNum] + 90 then
				local playerPos = Game():GetRoom():WorldToScreenPosition(players[playerNum].Position)
				Isaac.RenderText(statUpString[playerNum], playerPos.X+18, playerPos.Y-40, 1, 1, 1, 1-((currFrame-statUpFrame[playerNum])/90))
			else
				statUpString[playerNum] = nil
			end
		end
	end
end

function SelfHelpBook:onUpdate()
	if players[playerNum] == nil then
		players = getPlayers()
	end
	for playerNum=1,Game():GetNumPlayers() do
		if usingItem[playerNum] then
			local num
			local otherNums
			if GameState.statPriorityValue > 0 then
				local currPlayerIsEsau = 0
				if players[playerNum]:GetPlayerType()==20 then
					currPlayerIsEsau = 1
				end
				if Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, playerNum-1-currPlayerIsEsau) then
					num, otherNums = SelfHelpBook:setNums(0)
				elseif Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, playerNum-1-currPlayerIsEsau) then
					num, otherNums = SelfHelpBook:setNums(1)
				elseif Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, playerNum-1-currPlayerIsEsau) then
					num, otherNums = SelfHelpBook:setNums(2)
				elseif Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, playerNum-1-currPlayerIsEsau) then
					num, otherNums = SelfHelpBook:setNums(3)
				end
			elseif GameState.statPriorityValue == 0 then
				num, otherNums = SelfHelpBook:setNums(math.random(0,3))
			else
				usingItem[playerNum] = false
			end
			if num ~= nil then
				-- 50% chance that the chosen stat will increase, 12.5% chance for each other stat
				if GameState.statPriorityValue == 2 or math.random(2) == 1 then
					SelfHelpBook:statUp(num)
				elseif GameState.canBoostHealth == true then
					SelfHelpBook:statUp(otherNums[math.random(4)])
				else
					SelfHelpBook:statUp(otherNums[math.random(3)])
				end
				if players[playerNum]:GetActiveItem() ~= CollectibleType.COLLECTIBLE_VOID then
					players[playerNum]:AnimateHappy()
				end
				SFXManager():Play(SoundEffect.SOUND_POWERUP_SPEWER, 1, 0, false, 1)
				usingItem[playerNum] = false
			end
		end
		-- Bookworm transformation (only needed for AB+; ignore if Transformation API is enabled)
		if (not REPENTANCE) and (TransformationAPI == nil) and (not GameState.transformed[playerNum]) then
			for i=1,#books do
				if players[playerNum]:GetActiveItem() == books[i] then
					GameState.collectedBooks[playerNum][books[i]] = true
					GameState.highestID[playerNum] = math.max(GameState.highestID[playerNum], books[i])
				end
			end
			local count = 0
			for _, j in pairs(GameState.collectedBooks[playerNum]) do
				if j == true then
					count = count + 1
				end
			end
			local numTransformers = 0
			if SelfHelpBook.COLLECTIBLE_TRANSFORMER ~= nil and SelfHelpBook.COLLECTIBLE_TRANSFORMER ~= -1 then
				numTransformers = players[playerNum]:GetCollectibleNum(SelfHelpBook.COLLECTIBLE_TRANSFORMER)
			end
			if count >= 3 or (SelfHelpBook.COLLECTIBLE_TRANSFORMER ~= nil and SelfHelpBook.COLLECTIBLE_TRANSFORMER ~= -1 and count + numTransformers >= 3) then
				if GameState.collectedBooks[playerNum][SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK] ~= nil then
					for i=1,(1+numTransformers) do
						for i=1,#books do
							if GameState.collectedBooks[playerNum][books[i]] ~= true then
								local currItem = players[playerNum]:GetActiveItem()
								local currCharge = players[playerNum]:GetActiveCharge() + players[playerNum]:GetBatteryCharge()
								players[playerNum]:RemoveCollectible(currItem)
								players[playerNum]:AddCollectible(books[i], 0, false)
								GameState.collectedBooks[playerNum][books[i]] = true
								players[playerNum]:RemoveCollectible(books[i])
								players[playerNum]:AddCollectible(currItem, currCharge, false)
								numTransformers = numTransformers - 1
								break
							end
						end
					end
				end
				GameState.transformed[playerNum] = true
			end
		end
	end
end

function SelfHelpBook:setNums(tempNum)
	if tempNum == 0 then
		num = 0
		otherNums = {1, 2, 3, 4}
	elseif tempNum == 1 then
		num = 1
		otherNums = {0, 2, 3, 4}
	elseif tempNum == 2 then
		num = 2
		otherNums = {0, 1, 3, 4}
	elseif tempNum == 3 then
		num = 3
		otherNums = {0, 1, 2, 4}
	end

	return num, otherNums
end

function SelfHelpBook:statUp(num)
	-- playerNum has already been set
	local numUses = 1
	if players[playerNum]:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) then
		numUses = 2
	end
	for i=1,numUses do
		if num == 0 then
			GameState.numDamageUp[playerNum] = GameState.numDamageUp[playerNum] + 1
			players[playerNum]:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			statUpString[playerNum] = "Damage up"
		elseif num == 1 then
			GameState.numRangeUp[playerNum] = GameState.numRangeUp[playerNum] + 1
			players[playerNum]:AddCacheFlags(CacheFlag.CACHE_RANGE)
			statUpString[playerNum] = "Range up"
		elseif num == 2 then
			GameState.numSpeedUp[playerNum] = GameState.numSpeedUp[playerNum] + 1
			players[playerNum]:AddCacheFlags(CacheFlag.CACHE_SPEED)
			statUpString[playerNum] = "Speed up"
		elseif num == 3 then
			GameState.numLuckUp[playerNum] = GameState.numLuckUp[playerNum] + 1
			players[playerNum]:AddCacheFlags(CacheFlag.CACHE_LUCK)
			statUpString[playerNum] = "Luck up"
		elseif num == 4 then
			players[playerNum]:AddMaxHearts(2, true)
			statUpString[playerNum] = "Health up"
		end
	end
	statUpFrame[playerNum] = Game():GetFrameCount()
	players[playerNum]:EvaluateItems()
end

function SelfHelpBook:useItem(collectibleType, rng, player, flags, activeSlot, customVarData)
	playerNum = getCurrPlayerNum(player)
	if not usingItem[playerNum] then
		if GameState.statPriorityValue > 0 and player:GetActiveItem() ~= CollectibleType.COLLECTIBLE_VOID then
			player:AnimateCollectible(SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK, "LiftItem", "Idle")
		end
		usingItem[playerNum] = true
		oldCharge[playerNum] = player:GetActiveCharge()
		oldBatteryCharge[playerNum] = player:GetBatteryCharge()
	end
end

function SelfHelpBook:cacheUpdate(player, flag)
	if players[1] == nil then
		players = getPlayers()
	end
	-- if playerTypes[1] == nil then
	-- 	playerTypes = getPlayerTypes()
	-- end
	if GameState.numDamageUp == nil then
		initializeAllVars()
	end
	playerNum = getCurrPlayerNum(player)
	if playerNum ~= -1 then
		if flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage + (GameState.numDamageUp[playerNum] * damageUpVal * GameState.statBoostValue)
		end
		if flag == CacheFlag.CACHE_RANGE then
			if REPENTANCE then
				player.TearRange = player.TearRange + (GameState.numRangeUp[playerNum] * rangeUpVal_rep * GameState.statBoostValue)
			else
				player.TearHeight = player.TearHeight - (GameState.numRangeUp[playerNum] * rangeUpVal_abp * GameState.statBoostValue)
				player.TearFallingSpeed = player.TearFallingSpeed + (GameState.numRangeUp[playerNum] * rangeUpVal_abp/9 * GameState.statBoostValue)
			end
		end
		if flag == CacheFlag.CACHE_SPEED then
			player.MoveSpeed = player.MoveSpeed + (GameState.numSpeedUp[playerNum] * speedUpVal * GameState.statBoostValue)
		end
		if flag == CacheFlag.CACHE_LUCK then
			player.Luck = player.Luck + (GameState.numLuckUp[playerNum] * luckUpVal * GameState.statBoostValue)
		end
	end
end

function SelfHelpBook:onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if target and target.Type == EntityType.ENTITY_PLAYER then
		SelfHelpBook:refreshItemChargeOnePlayer(target:ToPlayer())
	end
end

function SelfHelpBook:refreshItemChargeOnePlayer(player)
	playerNum = getCurrPlayerNum(player)
	if usingItem[playerNum] and players[playerNum]:GetActiveItem() == SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK then
		players[playerNum]:SetActiveCharge(oldCharge[playerNum] + oldBatteryCharge[playerNum])
	end
	usingItem[playerNum] = false
end

function SelfHelpBook:refreshItemChargeAllPlayers()
	for playerNum=1,Game():GetNumPlayers() do
		if usingItem[playerNum] and players[playerNum]:GetActiveItem() == SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK then
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

-- function getPlayerTypes()
-- 	local pt = {}
-- 	for i = 0, Game():GetNumPlayers() do
-- 		if Isaac.GetPlayer(i) ~= nil then
-- 			table.insert(pt, Isaac.GetPlayer(i):GetPlayerType())
-- 		end
-- 	end
-- 	return pt
-- end

function getCurrPlayerNum(player)
	for i = 1, #players do
		if player:GetPlayerType() == players[i]:GetPlayerType() then
			return i
		end
	end
	return -1
end

SelfHelpBook:AddCallback(ModCallbacks.MC_POST_RENDER, SelfHelpBook.onRender)
SelfHelpBook:AddCallback(ModCallbacks.MC_POST_UPDATE, SelfHelpBook.onUpdate)
SelfHelpBook:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, SelfHelpBook.refreshItemChargeAllPlayers)
SelfHelpBook:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, SelfHelpBook.refreshItemChargeAllPlayers)
SelfHelpBook:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SelfHelpBook.cacheUpdate)
SelfHelpBook:AddCallback(ModCallbacks.MC_USE_ITEM, SelfHelpBook.useItem, SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK)
SelfHelpBook:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SelfHelpBook.onHit)