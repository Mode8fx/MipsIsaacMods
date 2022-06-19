ChillOut = RegisterMod("Chill Out", 1)

ChillOut.COLLECTIBLE_CHILL_OUT = Isaac.GetItemIdByName("Chill Out")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local players = {}
local currFrame = 0

local co_numSafeFrames = 2 * 30
local co_numRenderFrames1 = 2 * 18 -- number of frames that the ! will stay solid
local co_numRenderFrames2 = co_numSafeFrames - co_numRenderFrames1 -- number of frames that the ! will fade out before the Chill Out effect expires

function ChillOut:onStart()
	if ChillOut:HasData() then
		GameState = json.decode(ChillOut:LoadData())
	else
		GameState = {}
	end

	players = getPlayers()
	currFrame = 0

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[ChillOut.COLLECTIBLE_CHILL_OUT] = "Become immune to all non-self-inflicted damage for 2 seconds upon entering a new room"

	GameState.co_invincibilityTime = initializeVar(GameState.co_invincibilityTime, 2.0)
	GameState.co_showIcon = initializeVar(GameState.co_showIcon, true)

	if not alreadyPlayedOnceOnBoot then
		ChillOut:co_addMCMOptions()
		alreadyPlayedOnceOnBoot = true
	end
end

function ChillOut:co_addMCMOptions()
	if ModConfigMenu then
		ModConfigMenu.AddSpace("Paper Isaac", "Values")
		ModConfigMenu.AddText("Paper Isaac", "Values", "Chill Out")
		ModConfigMenu.AddSetting("Paper Isaac", "Values", { 
			Type = ModConfigMenu.OptionType.NUMBER,
			CurrentSetting = function()
				return GameState.co_invincibilityTime
			end,
			Display = function()
				return "Invincibility Time: " .. GameState.co_invincibilityTime .. " seconds"
			end,
			Minimum = 0.1,
			Maximum = 5,
			ModifyBy = 0.1,
			Default = 2.0,
			OnChange = function(currentNum)
				GameState.co_invincibilityTime = currentNum
				ChillOut:onExit()
			end,
			Info = {
				"Set the amount of invincibility",
				"time upon entering a new room."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Values", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.co_showIcon
			end,
			Display = function()
				local choice = "False"
				if GameState.co_showIcon then
					choice = "True"
				end
				return "Show \"!\" Icon: " .. choice
			end,
			Default = true,
			OnChange = function(currentBool)
				GameState.co_showIcon = currentBool
				ChillOut:onExit()
			end,
			Info = {
				"Set whether or not the \"!\"",
				"appears during invincibility."
			}
		})
	end
end

function initializeVar(var, value)
	if var == nil then
		var = value
	end
	return var
end

function ChillOut:onExit(save)
	ChillOut:SaveData(json.encode(GameState))
end

function ChillOut:onUpdate()
	currFrame = Game():GetFrameCount()
end

ChillOut:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, ChillOut.onStart)
ChillOut:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ChillOut.onExit)
ChillOut:AddCallback(ModCallbacks.MC_POST_GAME_END, ChillOut.onExit)
ChillOut:AddCallback(ModCallbacks.MC_POST_UPDATE, ChillOut.onUpdate)

function hasBit(var, bit)
	if var == nil then
		return false
	end
	return var % (bit + bit) >= bit
end

function damageIsFromMausoleumDoor(damageFlag)
	local currStage = Game():GetLevel():GetStage()
	return (hasBit(damageFlag, DamageFlag.DAMAGE_SPIKES)
		and (currStage == LevelStage.STAGE2_2 or currStage == LevelStage.STAGE3_1 or currStage == LevelStage.STAGE2_1)
		and Game():GetRoom():GetType() == RoomType.ROOM_BOSS and Game():GetRoom():IsClear())
end

local co_roomEnterFrame
local co_canRenderText = {false, false, false, false, false, false, false, false}

function ChillOut:co_onRender()
	if GameState.co_showIcon then
		if currFrame <= co_roomEnterFrame + co_numSafeFrames and currFrame ~= co_roomEnterFrame then
			for playerNum=1, #co_canRenderText do
				if co_canRenderText[playerNum] then
					local playerPos = Game():GetRoom():WorldToScreenPosition(players[playerNum].Position)
					if currFrame < co_roomEnterFrame + co_numRenderFrames1 then
						Isaac.RenderText("!", playerPos.X-3, playerPos.Y-40, 1, 1, 1, 1)
					else
						Isaac.RenderText("!", playerPos.X-3, playerPos.Y-40, 1, 1, 1, 1-((currFrame-co_roomEnterFrame-co_numRenderFrames1)/co_numRenderFrames2))
					end
				end
			end
		end
	end
end

function ChillOut:co_onNewRoom()
	co_roomEnterFrame = currFrame
	co_canRenderText = {false, false, false, false, false, false, false, false}
	for playerNum=1,Game():GetNumPlayers() do
		co_canRenderText[playerNum] = players[playerNum]:HasCollectible(ChillOut.COLLECTIBLE_CHILL_OUT)
	end
end

function ChillOut:co_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if target and target.Type == EntityType.ENTITY_PLAYER then
		if target:ToPlayer():HasCollectible(ChillOut.COLLECTIBLE_CHILL_OUT) then
			if currFrame <= co_roomEnterFrame + co_numSafeFrames
				and (damageSource == nil or ((damageSource.Entity == nil or damageSource.Entity.SpawnerType ~= EntityType.ENTITY_PLAYER) and (damageSource.Type ~= EntityType.ENTITY_PLAYER)))
				and not hasBit(damageFlag, DamageFlag.DAMAGE_RED_HEARTS)
				and not hasBit(damageFlag, DamageFlag.DAMAGE_FAKE)
				and not hasBit(damageFlag, DamageFlag.DAMAGE_CURSED_DOOR)
				and not hasBit(damageFlag, DamageFlag.DAMAGE_CHEST)
				and not hasBit(damageFlag, DamageFlag.DAMAGE_INVINCIBLE)
				and not hasBit(damageFlag, DamageFlag.DAMAGE_TIMER)
				and not damageIsFromMausoleumDoor(damageFlag) then
				return false
			end
		end
	end
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

ChillOut:AddCallback(ModCallbacks.MC_POST_RENDER, ChillOut.co_onRender)
ChillOut:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ChillOut.co_onNewRoom)
ChillOut:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, ChillOut.co_onHit, EntityType.ENTITY_PLAYER)