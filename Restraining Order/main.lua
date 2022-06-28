RestrainingOrder = RegisterMod("Restraining Order", 1)

RestrainingOrder.COLLECTIBLE_RESTRAINING_ORDER = Isaac.GetItemIdByName("Restraining Order")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local players = {}
local spawnRock = false
local canSpawnRO = true

function RestrainingOrder:onStart()
	if RestrainingOrder:HasData() then
		GameState = json.decode(RestrainingOrder:LoadData())
	else
		GameState = {}
	end

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[RestrainingOrder.COLLECTIBLE_RESTRAINING_ORDER] = "#+3 coins#+3 bombs#+3 keys#+3 soul hearts#+32.5% Angel room chance#Immediately get warped outside all Devil rooms"

	players = getPlayers()

	if GameState.addedCoins == nil then
		GameState.addedCoins = 3
	end
	if GameState.addedBombs == nil then
		GameState.addedBombs = 3
	end
	if GameState.addedKeys == nil then
		GameState.addedKeys = 3
	end
	if GameState.addedSoulHearts == nil then
		GameState.addedSoulHearts = 3
	end

	if not alreadyPlayedOnceOnBoot then
		-- Mod Config Menu
		if ModConfigMenu then
			ModConfigMenu.AddSpace("Restraining Order")
			ModConfigMenu.AddSetting("Restraining Order", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.addedCoins
				end,
				Display = function()
					return "Coins: " .. GameState.addedCoins
				end,
				Minimum = 0,
				Maximum = 20,
				Default = 3,
				OnChange = function(currentNum)
					GameState.addedCoins = currentNum
				end,
				Info = {
					"Set how many coins this item gives."
				}
			})
			ModConfigMenu.AddSpace("Restraining Order")
			ModConfigMenu.AddSetting("Restraining Order", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.addedBombs
				end,
				Display = function()
					return "Bombs: " .. GameState.addedBombs
				end,
				Minimum = 0,
				Maximum = 20,
				Default = 3,
				OnChange = function(currentNum)
					GameState.addedBombs = currentNum
				end,
				Info = {
					"Set how many bombs this item gives."
				}
			})
			ModConfigMenu.AddSpace("Restraining Order")
			ModConfigMenu.AddSetting("Restraining Order", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.addedKeys
				end,
				Display = function()
					return "Keys: " .. GameState.addedKeys
				end,
				Minimum = 0,
				Maximum = 20,
				Default = 3,
				OnChange = function(currentNum)
					GameState.addedKeys = currentNum
				end,
				Info = {
					"Set how many keys this item gives."
				}
			})
			ModConfigMenu.AddSpace("Restraining Order")
			ModConfigMenu.AddSetting("Restraining Order", { 
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return GameState.addedSoulHearts
				end,
				Display = function()
					return "Soul Hearts: " .. GameState.addedSoulHearts
				end,
				Minimum = 0,
				Maximum = 12.0,
				ModifyBy = 0.5,
				Default = 3.0,
				OnChange = function(currentNum)
					GameState.addedSoulHearts = currentNum
				end,
				Info = {
					"Set how many soul hearts this item gives."
				}
			})
		end
		alreadyPlayedOnceOnBoot = true
	end

	if Game():GetFrameCount() == 0 then
		GameState.oldNumROs = {0, 0, 0, 0, 0, 0, 0, 0}
		RestrainingOrder:onNewRoom()
	end
end
RestrainingOrder:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, RestrainingOrder.onStart)

function RestrainingOrder:onExit(save)
	RestrainingOrder:SaveData(json.encode(GameState))
end
RestrainingOrder:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, RestrainingOrder.onExit)
RestrainingOrder:AddCallback(ModCallbacks.MC_POST_GAME_END, RestrainingOrder.onExit)

function RestrainingOrder:onUpdate()
	local justGotRO = false
	for i = 1, #players do
		local numROs = players[i]:GetCollectibleNum(RestrainingOrder.COLLECTIBLE_RESTRAINING_ORDER)
		if numROs > GameState.oldNumROs[i] then
			players[i]:AddCoins(GameState.addedCoins)
			players[i]:AddBombs(GameState.addedBombs)
			players[i]:AddKeys(GameState.addedKeys)
			players[i]:AddSoulHearts(GameState.addedSoulHearts*2)
			Game():GetLevel():SetStateFlag(LevelStateFlag.STATE_EVIL_BUM_KILLED, true)
			Game():GetLevel():SetStateFlag(LevelStateFlag.STATE_BUM_LEFT, true)
			players[i]:EvaluateItems()
			if GameState.inDevilRoom then
				for j = 1, #players do
					players[i]:AnimateTeleport(false)
				end
				Game():ChangeRoom(GameState.lastRoom)
			end
			GameState.oldNumROs[i] = numROs
			justGotRO = true
		end
	end
	if (not justGotRO) and GameState.inDevilRoom then
		if spawnRock then
			GameState.spawnedRock = Isaac.GridSpawn(2, 0, GameState.devilStatuePos, false)
			spawnRock = false
		end
		if GameState.spawnedRock ~= nil and GameState.spawnedRock.State == 2 and canSpawnRO then -- the rock was destroyed
			GameState.devilStatue:Remove()
			if Game():GetDevilRoomDeals() == 0 then
				GameState.spawnedRO = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, RestrainingOrder.COLLECTIBLE_RESTRAINING_ORDER, GameState.devilStatuePos, Vector(0,0), nil)
			end
			canSpawnRO = false
		end
		if GameState.spawnedRO ~= nil and Game():GetDevilRoomDeals() > 0 then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, GameState.devilStatuePos, Vector(0,0), nil)
			GameState.spawnedRO:Remove()
			GameState.spawnedRO = nil
		end
	end
end

function RestrainingOrder:onNewLevel()
	canSpawnRO = true
	GameState.spawnedRock = nil
	GameState.devilStatue = nil
	GameState.devilStatuePos = nil
	GameState.devilStatueGridIndex = nil
	GameState.spawnedRO = nil
	if playersHaveCollectible(RestrainingOrder.COLLECTIBLE_RESTRAINING_ORDER) then
		Game():GetLevel():SetStateFlag(LevelStateFlag.STATE_EVIL_BUM_KILLED, true)
		Game():GetLevel():SetStateFlag(LevelStateFlag.STATE_BUM_LEFT, true)
	end
end

function RestrainingOrder:onNewRoom()
	local currRoom = Game():GetRoom()
	GameState.inDevilRoom = (currRoom:GetType() == RoomType.ROOM_DEVIL)
	if GameState.inDevilRoom then
		for _, entity in pairs(Isaac.GetRoomEntities()) do
			if entity.Type == 1000 and entity.Variant == 6 then
				GameState.devilStatue = entity
				GameState.devilStatuePos = GameState.devilStatue.Position
				GameState.devilStatueGridIndex = currRoom:GetGridIndex(GameState.devilStatuePos)
				currRoom:RemoveGridEntity(GameState.devilStatueGridIndex, 0, false)
				spawnRock = true
				break
			end
		end
	end
	if not GameState.inDevilRoom then
		GameState.lastRoom = Game():GetLevel():GetCurrentRoomIndex()
	elseif playersHaveCollectible(RestrainingOrder.COLLECTIBLE_RESTRAINING_ORDER) then
		for i = 1, #players do
			players[i]:AnimateTeleport(false)
		end
		Game():ChangeRoom(GameState.lastRoom)
	end
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

RestrainingOrder:AddCallback(ModCallbacks.MC_POST_UPDATE, RestrainingOrder.onUpdate);
RestrainingOrder:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, RestrainingOrder.onNewLevel)
RestrainingOrder:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, RestrainingOrder.onNewRoom)