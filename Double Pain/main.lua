DoublePain = RegisterMod("Double Pain", 1)

DoublePain.COLLECTIBLE_DOUBLE_PAIN = Isaac.GetItemIdByName("Double Pain")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local player

function DoublePain:onStart()
	GameState = json.decode(DoublePain:LoadData())

	player = Isaac.GetPlayer(0)

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[DoublePain.COLLECTIBLE_DOUBLE_PAIN] = "Take double damage"

	GameState.enabledDP = initializeVar(GameState.enabledDP, false)

	if not alreadyPlayedOnceOnBoot then
		if ModConfigMenu then
			ModConfigMenu.AddSetting("Double Pain", "Spawns", {
				Type = ModConfigMenuOptionType.BOOLEAN,
				CurrentSetting = function()
					return GameState.enabledDP
				end,
				Display = function()
					local choice = "No"
					if GameState.enabledDP then
						choice = "Yes"
					end
					return "Spawns in item pool: " .. choice
				end,
				Default = false,
				OnChange = function(currentBool)
					GameState.enabledDP = currentBool
					DoublePain:onExit()
				end,
				Info = {
					"If disabled, Double Pain will not spawn."
				}
			})
		end
		alreadyPlayedOnceOnBoot = true
	end

	if currFrame == 0 then
		if not GameState.enabledDP then
			Game():GetItemPool():RemoveCollectible(DoublePain.COLLECTIBLE_DOUBLE_PAIN)
		end
	end
end

function initializeVar(var, value)
	if var == nil then
		var = value
	end
	return var
end

function DoublePain:onExit(save)
	DoublePain:SaveData(json.encode(GameState))
end

DoublePain:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, DoublePain.onStart)
DoublePain:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, DoublePain.onExit)
DoublePain:AddCallback(ModCallbacks.MC_POST_GAME_END, DoublePain.onExit)

local dp_tookDamage = false

function DoublePain:dp_onStart()
	dp_tookDamage = false
end

function DoublePain:dp_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if dp_tookDamage then
		dp_tookDamage = false
		return nil
	end
	if player:HasCollectible(DoublePain.COLLECTIBLE_DOUBLE_PAIN) then
		dp_tookDamage = true
		player:TakeDamage(damageAmount * 2, damageFlag, damageSource, numCountdownFrames) -- this is supposed to keep the original number of invincibility frames, but it's broken in the API?
		return false
	end
end

DoublePain:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, DoublePain.dp_onStart)
DoublePain:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, DoublePain.dp_onHit, EntityType.ENTITY_PLAYER)