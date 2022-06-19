ReturnPostage = RegisterMod("Return Postage", 1)

ReturnPostage.COLLECTIBLE_RETURN_POSTAGE = Isaac.GetItemIdByName("Return Postage")

local GameState = {}
local json = require("json")

local alreadyPlayedOnceOnBoot = false -- for Mod Config Menu; makes it so that the option is only added once per game boot

local player

function ReturnPostage:onStart()
	if ReturnPostage:HasData() then
		GameState = json.decode(ReturnPostage:LoadData())
	end

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[ReturnPostage.COLLECTIBLE_RETURN_POSTAGE] = "Deal 3x your DPS to anything that hurts you"

	GameState.rp_counterDamage = initializeVar(GameState.rp_counterDamage, 3.0)

	if not alreadyPlayedOnceOnBoot then
		ReturnPostage:rp_addMCMOptions()
		alreadyPlayedOnceOnBoot = true
	end
end

function ReturnPostage:rp_addMCMOptions()
	if ModConfigMenu then
		ModConfigMenu.AddSpace("Paper Isaac", "Values")
		ModConfigMenu.AddText("Paper Isaac", "Values", "Return Postage")
		ModConfigMenu.AddSetting("Paper Isaac", "Values", { 
			Type = ModConfigMenu.OptionType.NUMBER,
			CurrentSetting = function()
				return GameState.rp_counterDamage
			end,
			Display = function()
				return "Counter Damage: " .. GameState.rp_counterDamage .. "x DPS"
			end,
			Minimum = 0.1,
			Maximum = 5,
			ModifyBy = 0.1,
			Default = 3.0,
			OnChange = function(currentNum)
				GameState.rp_counterDamage = currentNum
				ReturnPostage:onExit()
			end,
			Info = {
				"Set the amount of damage (relative to",
				"your DPS) dealt by Return Postage."
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

function ReturnPostage:onExit(save)
	ReturnPostage:SaveData(json.encode(GameState))
end

ReturnPostage:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, ReturnPostage.onStart)
ReturnPostage:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ReturnPostage.onExit)
ReturnPostage:AddCallback(ModCallbacks.MC_POST_GAME_END, ReturnPostage.onExit)

function hasBit(var, bit)
	if var == nil then
		return false
	end
	return var % (bit + bit) >= bit
end

function ReturnPostage:rp_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	-- print(damageSource.SpawnerType)
	-- print(damageSource.SpawnerVariant)
	-- print(damageSource.Entity.SpawnerType) -- the type of enemy that spawned the entity (0 if nothing spawned it)
	-- print(damageSource.Entity.SpawnerVariant) -- the variant of enemy that spawned the entity (0 if nothing spawned it or default variant)
	if target:ToPlayer():HasCollectible(ReturnPostage.COLLECTIBLE_RETURN_POSTAGE) and not hasBit(damageFlag, DamageFlag.DAMAGE_FAKE) and damageSource and damageSource.Entity and damageSource.Type ~= EntityType.ENTITY_PLAYER and damageSource.Entity.SpawnerType ~= EntityType.ENTITY_PLAYER and damageSource.Type < 1000 then
		local hitByProjectile = damageSource.Entity.Type == EntityType.ENTITY_PROJECTILE or damageSource.Entity.Type == EntityType.ENTITY_BOMBDROP or damageSource.Entity.Type == EntityType.ENTITY_LASER or (damageSource.Entity.SpawnerType ~= 0 and not (damageSource.Entity:IsVulnerableEnemy() and not (damageSource.Type == 39 and damageSource.Variant == 22)))
		local entityToAttack = nil
		local entityToAttackDist = 999
		for _, entity in pairs(Isaac.GetRoomEntities()) do
			if hitByProjectile then
				if entity.Type == damageSource.Entity.SpawnerType and entity.Variant == damageSource.Entity.SpawnerVariant then
					local dist = math.sqrt((entity.Position.X - target.Position.X)^2 + (entity.Position.Y - target.Position.Y)^2)
					if entityToAttack == nil or dist < entityToAttackDist then
						entityToAttack = entity
						entityToAttackDist = dist
					end
				end
			elseif entity.Type == damageSource.Entity.Type and entity.Variant == damageSource.Entity.Variant and entity.Position.X == damageSource.Entity.Position.X and entity.Position.Y == damageSource.Entity.Position.Y then
				ReturnPostage:hurtEnemy(target:ToPlayer(), entity, damageFlag, numCountdownFrames)
				break
			end
		end
		if entityToAttack ~= nil then
			ReturnPostage:hurtEnemy(target:ToPlayer(), entityToAttack, damageFlag, numCountdownFrames)
		end
	end
end

function ReturnPostage:hurtEnemy(player, entity, damageFlag, numCountdownFrames)
	local dpsVal = player.Damage*math.ceil(GameState.rp_counterDamage*30/player.MaxFireDelay)
	entity:TakeDamage(dpsVal, damageFlag, EntityRef(player), numCountdownFrames)
end

ReturnPostage:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, ReturnPostage.rp_onHit, EntityType.ENTITY_PLAYER)