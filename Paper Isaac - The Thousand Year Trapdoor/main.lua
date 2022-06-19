PaperIsaac = RegisterMod("Paper Isaac", 1)

-- Initialization --

local paperIsaacModList = {
	"bump_attack",
	"chill_out",
	"close_call",
	"double_pain",
	"fire_shield",
	"p-up_d-down",
	"refund",
	"return_postage",
	"slow_go",
	"spike_shield",
	"super_appeal",
	"paper_transformation"
}
for i=1,#paperIsaacModList do
	if REPENTANCE then
		include(paperIsaacModList[i])
	else
		require(paperIsaacModList[i])
	end
end

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

-- General --

function PaperIsaac:onStart()
	-- Save Data --
	if PaperIsaac:HasData() then
		GameState = json.decode(PaperIsaac:LoadData())
	else
		GameState = {}
	end

	-- Mod Config Menu --
	GameState.enabledBA = initializeVar(GameState.enabledBA, true)
	GameState.enabledCO = initializeVar(GameState.enabledCO, true)
	GameState.enabledCC = initializeVar(GameState.enabledCC, true)
	GameState.enabledDP = initializeVar(GameState.enabledDP, false)
	GameState.enabledFS = initializeVar(GameState.enabledFS, true)
	GameState.enabledPUDD = initializeVar(GameState.enabledPUDD, true)
	GameState.enabledR = initializeVar(GameState.enabledR, true)
	GameState.enabledRP = initializeVar(GameState.enabledRP, true)
	GameState.enabledSG = initializeVar(GameState.enabledSG, false)
	GameState.enabledSS = initializeVar(GameState.enabledSS, true)
	GameState.enabledSA = initializeVar(GameState.enabledSA, true)
	if not alreadyPlayedOnceOnBoot then
		PaperIsaac:modpack_addMCMOptions()
		alreadyPlayedOnceOnBoot = true
	end

	if Game():GetFrameCount() < 5 then
		if not GameState.enabledBA then
			Game():GetItemPool():RemoveCollectible(BumpAttack.COLLECTIBLE_BUMP_ATTACK)
		end
		if not GameState.enabledCO then
			Game():GetItemPool():RemoveCollectible(ChillOut.COLLECTIBLE_CHILL_OUT)
		end
		if not GameState.enabledCC then
			Game():GetItemPool():RemoveCollectible(CloseCall.COLLECTIBLE_CLOSE_CALL)
		end
		if not GameState.enabledDP then
			Game():GetItemPool():RemoveCollectible(DoublePain.COLLECTIBLE_DOUBLE_PAIN)
		end
		if not GameState.enabledFS then
			Game():GetItemPool():RemoveTrinket(FireShield.TRINKET_FIRE_SHIELD)
		end
		if not GameState.enabledPUDD then
			Game():GetItemPool():RemoveCollectible(PUpDDown.COLLECTIBLE_P_UP_D_DOWN)
		end
		if not GameState.enabledR then
			Game():GetItemPool():RemoveCollectible(Refund.COLLECTIBLE_REFUND)
		end
		if not GameState.enabledRP then
			Game():GetItemPool():RemoveCollectible(ReturnPostage.COLLECTIBLE_RETURN_POSTAGE)
		end
		if not GameState.enabledSG then
			Game():GetItemPool():RemoveCollectible(SlowGo.COLLECTIBLE_SLOW_GO)
		end
		if not GameState.enabledSS then
			Game():GetItemPool():RemoveCollectible(SpikeShield.COLLECTIBLE_SPIKE_SHIELD)
		end
		if not GameState.enabledSA then
			Game():GetItemPool():RemoveCollectible(SuperAppeal.COLLECTIBLE_SUPER_APPEAL)
		end
	end
end

function PaperIsaac:onExit(save)
	PaperIsaac:SaveData(json.encode(GameState))
end

PaperIsaac:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, PaperIsaac.onStart)
PaperIsaac:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, PaperIsaac.onExit)
PaperIsaac:AddCallback(ModCallbacks.MC_POST_GAME_END, PaperIsaac.onExit)

-- Mod Config Menu --

function PaperIsaac:modpack_addMCMOptions()
	if ModConfigMenu then
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledBA
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledBA then
					choice = "Enabled"
				end
				return "Bump Attack: " .. choice
			end,
			Default = true,
			OnChange = function(currentBool)
				GameState.enabledBA = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, Bump Attack will not spawn."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledCO
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledCO then
					choice = "Enabled"
				end
				return "Chill Out: " .. choice
			end,
			Default = true,
			OnChange = function(currentBool)
				GameState.enabledCO = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, Chill Out will not spawn."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledCC
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledCC then
					choice = "Enabled"
				end
				return "Close Call: " .. choice
			end,
			Default = true,
			OnChange = function(currentBool)
				GameState.enabledCC = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, Close Call will not spawn."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledDP
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledDP then
					choice = "Enabled"
				end
				return "Double Pain: " .. choice
			end,
			Default = false,
			OnChange = function(currentBool)
				GameState.enabledDP = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, Double Pain will not spawn."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledFS
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledFS then
					choice = "Enabled"
				end
				return "Fire Shield: " .. choice
			end,
			Default = true,
			OnChange = function(currentBool)
				GameState.enabledFS = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, Fire Shield will not spawn."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledPUDD
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledPUDD then
					choice = "Enabled"
				end
				return "P-Up, D-Down: " .. choice
			end,
			Default = true,
			OnChange = function(currentBool)
				GameState.enabledPUDD = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, P-Up, D-Down will not spawn."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledR
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledR then
					choice = "Enabled"
				end
				return "Refund: " .. choice
			end,
			Default = true,
			OnChange = function(currentBool)
				GameState.enabledR = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, Refund will not spawn."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledRP
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledRP then
					choice = "Enabled"
				end
				return "Return Postage: " .. choice
			end,
			Default = true,
			OnChange = function(currentBool)
				GameState.enabledRP = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, Return Postage will not spawn."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledSG
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledSG then
					choice = "Enabled"
				end
				return "Slow Go: " .. choice
			end,
			Default = false,
			OnChange = function(currentBool)
				GameState.enabledSG = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, Slow Go will not spawn."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledSS
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledSS then
					choice = "Enabled"
				end
				return "Spike Shield: " .. choice
			end,
			Default = true,
			OnChange = function(currentBool)
				GameState.enabledSS = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, Spike Shield will not spawn."
			}
		})
		ModConfigMenu.AddSetting("Paper Isaac", "Spawns", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return GameState.enabledSA
			end,
			Display = function()
				local choice = "Disabled"
				if GameState.enabledSA then
					choice = "Enabled"
				end
				return "Super Appeal: " .. choice
			end,
			Default = true,
			OnChange = function(currentBool)
				GameState.enabledSA = currentBool
				PaperIsaac:onExit()
			end,
			Info = {
				"If disabled, Super Appeal will not spawn."
			}
		})
	end
end

-- The included mods are the exact same files as their standalone counterparts, with the following exceptions:
-- Bump Attack, Chill Out, Return Postage
	-- Mod Config Menu option field has been replaced with '"Paper Isaac", "Values"' with new text field '"Paper Isaac", "Values", "[ITEM]"''
	-- All instances of AddSpace() in ModConfigMenu have been removed
-- Chill Out, Return Postage
	-- ModConfigMenu.AddSpace("Paper Isaac", "Values") has been added
-- Double Pain, Slow Go
	-- Mod Config Menu options and their functionality (they're just spawn toggles) have been removed since they're handled in main.lua
