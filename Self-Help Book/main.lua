local SelfHelpBook = RegisterMod("Self-Help Book", 1)

SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK = Isaac.GetItemIdByName("Self-Help Book")

SelfHelpBook.CHALLENGE_SELF_HELP_1 = Isaac.GetChallengeIdByName("Self-Help (DR)")
SelfHelpBook.CHALLENGE_SELF_HELP_2 = Isaac.GetChallengeIdByName("Self-Help (Chest)")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local player
-- local usingItemStart = false
local usingItem = false
local damageUpVal = 0.5
local rangeUpVal = 2.5
local speedUpVal = 0.15
local luckUpVal = 1
local oldCharge = 0
local oldBatteryCharge = 0
local statUpString = nil
local statUpFrame = -150
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
	GameState = json.decode(SelfHelpBook:LoadData())

	-- External Item Description
	if not __eidItemTransformations then
		__eidItemTransformations = {}
	end
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemTransformations[SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK] = "12"
	__eidItemDescriptions[SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK] = "Gives a small, permanent stat boost on every use#Input a direction to give a higher chance of raising a specific stat"

	initializeAllVars()

	player = Isaac.GetPlayer(0)
	SelfHelpBook.COLLECTIBLE_TRANSFORMER = Isaac.GetItemIdByName("Transformer")
	statUpFrame = -150

	if not alreadyPlayedOnceOnBoot then
		-- OptionsMod
		-- if optionsmod ~= nil and optionsmod.RegisterNewSetting ~= nil then
		-- 	SelfHelpBookOptionsMod()
		-- else
		-- 	if optionsmod_init == nil then
		-- 		optionsmod_init = {}
		-- 	end
		-- 	optionsmod_init[#optionsmod_init+1] = SelfHelpBookOptionsMod
		-- end

		-- Mod Config Menu
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
		GameState.numDamageUp = 0
		GameState.numRangeUp = 0
		GameState.numSpeedUp = 0
		GameState.numLuckUp = 0
		GameState.collectedBooks = {}
		GameState.highestID = -1
		GameState.transformed = false
	else
		SelfHelpBook:loadCollectedList()
	end

	if Game():GetFrameCount() == 0 and (Game().Challenge == SelfHelpBook.CHALLENGE_SELF_HELP_1 or Game().Challenge == SelfHelpBook.CHALLENGE_SELF_HELP_2) then
		player:AddCollectible(SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK, 6, false)
		Game():GetItemPool():RemoveCollectible(SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK)
	end
end
SelfHelpBook:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SelfHelpBook.onStart)

-- function SelfHelpBookOptionsMod()
-- 	optionsmod.RegisterMod("Self-Help Book", {"Item behavior"})
-- 	GameState.statBoostValue = optionsmod.RegisterNewSetting({
-- 	    name = "Stat boost value",
-- 	    description = "Set the size of the stat boost relative to a stat up pill",
-- 	    category = "Item behavior",
-- 	    type = "percent",
-- 	    default = 0.5,
-- 	    min = 0.05,
-- 	    max = 1,
-- 	    adjustRate = 0.05
-- 	})
-- 	GameState.statPriorityValue = optionsmod.RegisterNewSetting({
-- 	    name = "Stat priority value",
-- 	    description = "Set the likelihood that your chosen stat will increase",
-- 	    category = "Item behavior",
-- 	    type = "normal",
-- 	    options = {{"No priority", 0}, {"50% chance", 1}, {"Guaranteed", 2}},
-- 	    default = 2 -- 2nd value, not "value = 2"
-- 	})
-- 	GameState.canBoostHealth = optionsmod.RegisterNewSetting({
-- 	    name = "Can boost health",
-- 	    description = "Set whether or not the item can randomly increase health",
-- 	    category = "Item behavior",
-- 	    type = "toggle",
-- 	    default = true
-- 	})
-- 	alreadyPlayedOnceOnBoot = true
-- end

function initializeVar(var, value)
	if var == nil then
		var = value
	end
	return var
end

function initializeAllVars()
	GameState.numDamageUp = initializeVar(GameState.numDamageUp, 0)
	GameState.numRangeUp = initializeVar(GameState.numRangeUp, 0)
	GameState.numSpeedUp = initializeVar(GameState.numSpeedUp, 0)
	GameState.numLuckUp = initializeVar(GameState.numLuckUp, 0)
	GameState.collectedBooks = initializeVar(GameState.collectedBooks, {})
	GameState.highestID = initializeVar(GameState.highestID, -1)
	GameState.transformed = initializeVar(GameState.transformed, false)
	GameState.statBoostValue = initializeVar(GameState.statBoostValue, 0.5)
	GameState.statPriorityValue = initializeVar(GameState.statPriorityValue, 1)
	GameState.canBoostHealth = initializeVar(GameState.canBoostHealth, true)
end

function SelfHelpBook:onExit(save)
	for i=1,GameState.highestID do
		if GameState.collectedBooks[i] == nil then
			GameState.collectedBooks[i] = false
		end
	end
	SelfHelpBook:SaveData(json.encode(GameState))
end
SelfHelpBook:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SelfHelpBook.onExit)
SelfHelpBook:AddCallback(ModCallbacks.MC_POST_GAME_END, SelfHelpBook.onExit)

function SelfHelpBook:loadCollectedList()
	local new_collectedBooks = {}
	for i=1, GameState.highestID do
		if GameState.collectedBooks[i] == true then
			new_collectedBooks[i] = true
		end
	end
	GameState.collectedBooks = new_collectedBooks
end

function SelfHelpBook:onRender()
	if usingItem and GameState.statPriorityValue > 0 then
		local playerPos = Game():GetRoom():WorldToScreenPosition(player.Position)
		Isaac.RenderText("Damage", playerPos.X-18, playerPos.Y-52, 1, 1, 1, 1)
		Isaac.RenderText("^", playerPos.X-3, playerPos.Y-40, 1, 1, 1, 1)
		Isaac.RenderText("Range <", playerPos.X-60, playerPos.Y-24, 1, 1, 1, 1)
		Isaac.RenderText("> Speed", playerPos.X+18, playerPos.Y-24, 1, 1, 1, 1)
		Isaac.RenderText("v", playerPos.X-3, playerPos.Y, 1, 1, 1, 1)
		Isaac.RenderText("Luck", playerPos.X-12, playerPos.Y+12, 1, 1, 1, 1)
	end
	if statUpString ~= nil then
		local currFrame = Game():GetFrameCount()
		if currFrame < statUpFrame + 90 then
			local playerPos = Game():GetRoom():WorldToScreenPosition(player.Position)
			Isaac.RenderText(statUpString, playerPos.X+18, playerPos.Y-40, 1, 1, 1, 1-((currFrame-statUpFrame)/90))
		else
			statUpString = nil
		end
	end
end

function SelfHelpBook:onUpdate()
	if player == nil then
		player = Isaac.GetPlayer(0)
	end
	if usingItem then
		local num
		local otherNums
		if GameState.statPriorityValue > 0 then
			for controllerId=0,1 do
				if Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, controllerId) then
					num, otherNums = SelfHelpBook:setNums(0)
					break
				end
				if Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, controllerId) then
					num, otherNums = SelfHelpBook:setNums(1)
					break
				end
				if Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, controllerId) then
					num, otherNums = SelfHelpBook:setNums(2)
					break
				end
				if Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, controllerId) then
					num, otherNums = SelfHelpBook:setNums(3)
					break
				end
			end
		elseif GameState.statPriorityValue == 0 then
			num, otherNums = SelfHelpBook:setNums(math.random(4))
		else
			usingItem = false
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
			if player:GetActiveItem() ~= CollectibleType.COLLECTIBLE_VOID then
				player:AnimateHappy()
			end
			SFXManager():Play(SoundEffect.SOUND_POWERUP_SPEWER, 1, 0, false, 1)
			-- usingItemStart = false
			usingItem = false
			-- player:DischargeActiveItem()
		end
	end
	-- Bookworm transformation (ignore if Transformation API is enabled)
	if TransformationAPI == nil and not GameState.transformed then
		for i=1,#books do
			if player:GetActiveItem() == books[i] then
				GameState.collectedBooks[books[i]] = true
				GameState.highestID = math.max(GameState.highestID, books[i])
			end
		end
		local count = 0
		for _, j in pairs(GameState.collectedBooks) do
			if j == true then
				count = count + 1
			end
		end
		local numTransformers = player:GetCollectibleNum(SelfHelpBook.COLLECTIBLE_TRANSFORMER)
		if SelfHelpBook.COLLECTIBLE_TRANSFORMER == -1 then
			numTransformers = 0
		end
		if count >= 3 or (SelfHelpBook.COLLECTIBLE_TRANSFORMER ~= -1 and count + numTransformers >= 3) then
			if GameState.collectedBooks[SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK] ~= nil then
				for i=1,(1+numTransformers) do
					for i=1,#books do
						if GameState.collectedBooks[books[i]] ~= true then
							local currItem = player:GetActiveItem()
							local currCharge = player:GetActiveCharge() + player:GetBatteryCharge()
							player:RemoveCollectible(currItem)
							player:AddCollectible(books[i], 0, false)
							GameState.collectedBooks[books[i]] = true
							player:RemoveCollectible(books[i])
							player:AddCollectible(currItem, currCharge, false)
							numTransformers = numTransformers - 1
							break
						end
					end
				end
			end
			GameState.transformed = true
		end
	end
end

function SelfHelpBook:setNums(tempNum)
	if tempNum == 0 then
		num = 0
		otherNums = {1, 2, 3, 4}
	end
	if tempNum == 1 then
		num = 1
		otherNums = {0, 2, 3, 4}
	end
	if tempNum == 2 then
		num = 2
		otherNums = {0, 1, 3, 4}
	end
	if tempNum == 3 then
		num = 3
		otherNums = {0, 1, 2, 4}
	end

	return num, otherNums
end

function SelfHelpBook:statUp(num)
	local j = 1
	if player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) then
		j = 2
	end
	for i=1,j do
		if num == 0 then
			GameState.numDamageUp = GameState.numDamageUp + 1
			player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			statUpString = "Damage up"
		end
		if num == 1 then
			GameState.numRangeUp = GameState.numRangeUp + 1
			player:AddCacheFlags(CacheFlag.CACHE_RANGE)
			statUpString = "Range up"
		end
		if num == 2 then
			GameState.numSpeedUp = GameState.numSpeedUp + 1
			player:AddCacheFlags(CacheFlag.CACHE_SPEED)
			statUpString = "Speed up"
		end
		if num == 3 then
			GameState.numLuckUp = GameState.numLuckUp + 1
			player:AddCacheFlags(CacheFlag.CACHE_LUCK)
			statUpString = "Luck up"
		end
		if num == 4 then
			player:AddMaxHearts(2, true)
			statUpString = "Health up"
		end
	end
	player:EvaluateItems()
	statUpFrame = Game():GetFrameCount()
end

function SelfHelpBook:useItem()
	if not usingItem then
		if GameState.statPriorityValue > 0 and player:GetActiveItem() ~= CollectibleType.COLLECTIBLE_VOID then
			player:AnimateCollectible(SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK, "LiftItem", "Idle")
		end
		-- usingItemStart = true
		usingItem = true
		oldCharge = player:GetActiveCharge()
		oldBatteryCharge = player:GetBatteryCharge()
	end
end

function SelfHelpBook:cacheUpdate(player, flag)
	if GameState.numDamageUp == nil then
		initializeAllVars()
	end
	if flag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + (GameState.numDamageUp * damageUpVal * GameState.statBoostValue)
    end
    if flag == CacheFlag.CACHE_RANGE then
		player.TearHeight = player.TearHeight - (GameState.numRangeUp * rangeUpVal * GameState.statBoostValue)
		player.TearFallingSpeed = player.TearFallingSpeed + (GameState.numRangeUp * rangeUpVal/9 * GameState.statBoostValue)
    end
    if flag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + (GameState.numSpeedUp * speedUpVal * GameState.statBoostValue)
    end
	if flag == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + (GameState.numLuckUp * luckUpVal * GameState.statBoostValue)
    end
end

function SelfHelpBook:onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if target and target.Type == EntityType.ENTITY_PLAYER then
		SelfHelpBook:refreshItemCharge()
	end
end

function SelfHelpBook:refreshItemCharge()
	if usingItem and player:GetActiveItem() == SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK then
		player:SetActiveCharge(oldCharge + oldBatteryCharge)
	end
	usingItem = false
end

SelfHelpBook:AddCallback(ModCallbacks.MC_POST_RENDER, SelfHelpBook.onRender)
SelfHelpBook:AddCallback(ModCallbacks.MC_POST_UPDATE, SelfHelpBook.onUpdate)
SelfHelpBook:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, SelfHelpBook.refreshItemCharge)
SelfHelpBook:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, SelfHelpBook.refreshItemCharge)
SelfHelpBook:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SelfHelpBook.cacheUpdate)
SelfHelpBook:AddCallback(ModCallbacks.MC_USE_ITEM, SelfHelpBook.useItem, SelfHelpBook.COLLECTIBLE_SELF_HELP_BOOK)
SelfHelpBook:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SelfHelpBook.onHit)