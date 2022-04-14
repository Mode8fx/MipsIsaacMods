ChillOut = RegisterMod("Chill Out", 1)

ChillOut.COLLECTIBLE_CHILL_OUT = Isaac.GetItemIdByName("Chill Out")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local player
local currFrame = 0

function ChillOut:onStart()
	GameState = json.decode(ChillOut:LoadData())

	player = Isaac.GetPlayer(0)
	currFrame = 0

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[ChillOut.COLLECTIBLE_CHILL_OUT] = "Become immune to all non-self-inflicted damage for 2 seconds upon entering a new room"

	GameState.co_invincibilityTime = initializeVar(GameState.co_invincibilityTime, 2.0)
	GameState.co_showIcon = initializeVar(GameState.co_showIcon, true)

	if not alreadyPlayedOnceOnBoot then
		if ModConfigMenu then
			ModConfigMenu.AddSetting("Chill Out", { 
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
			ModConfigMenu.AddSpace("Chill Out")
			ModConfigMenu.AddSetting("Chill Out", {
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
		alreadyPlayedOnceOnBoot = true
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

local co_roomEnterFrame
local co_canRenderText = false

function ChillOut:co_onRender()
	if GameState.co_showIcon then
		local co_numSafeFrames = GameState.co_invincibilityTime * 30
		local co_numRenderFrames1 = GameState.co_invincibilityTime * 18 -- number of frames that the ! will stay solid
		local co_numRenderFrames2 = co_numSafeFrames - co_numRenderFrames1 -- number of frames that the ! will fade out before the Chill Out effect expires
		if co_canRenderText and currFrame <= co_roomEnterFrame + co_numSafeFrames and currFrame ~= co_roomEnterFrame then
			local playerPos = Game():GetRoom():WorldToScreenPosition(player.Position)
			if currFrame < co_roomEnterFrame + co_numRenderFrames1 then
				Isaac.RenderText("!", playerPos.X-3, playerPos.Y-40, 1, 1, 1, 1)
			else
				Isaac.RenderText("!", playerPos.X-3, playerPos.Y-40, 1, 1, 1, 1-((currFrame-co_roomEnterFrame-co_numRenderFrames1)/co_numRenderFrames2))
			end
		end
	end
end

function ChillOut:co_onNewRoom()
	co_roomEnterFrame = currFrame
	co_canRenderText = player:HasCollectible(ChillOut.COLLECTIBLE_CHILL_OUT)
end

function ChillOut:co_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if player:HasCollectible(ChillOut.COLLECTIBLE_CHILL_OUT) then
		if currFrame <= co_roomEnterFrame + GameState.co_invincibilityTime * 30 and (damageSource == nil or ((damageSource.Entity == nil or damageSource.Entity.SpawnerType ~= EntityType.ENTITY_PLAYER) and (damageSource.Type ~= EntityType.ENTITY_PLAYER))) and not hasBit(damageFlag, DamageFlag.DAMAGE_RED_HEARTS) and not hasBit(damageFlag, DamageFlag.DAMAGE_FAKE) and not hasBit(damageFlag, DamageFlag.DAMAGE_CURSED_DOOR) and not hasBit(damageFlag, DamageFlag.DAMAGE_CHEST) and not hasBit(damageFlag, DamageFlag.DAMAGE_INVINCIBLE) and not hasBit(damageFlag, DamageFlag.DAMAGE_TIMER) then
			return false
		end
	end
end

ChillOut:AddCallback(ModCallbacks.MC_POST_RENDER, ChillOut.co_onRender)
ChillOut:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ChillOut.co_onNewRoom)
ChillOut:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, ChillOut.co_onHit, EntityType.ENTITY_PLAYER)