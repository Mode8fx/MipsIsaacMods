FireShield = RegisterMod("Fire Shield", 1)

FireShield.TRINKET_FIRE_SHIELD = Isaac.GetTrinketIdByName("Fire Shield")

local playerTypes
local currPlayerType
local currFrame = 0

function FireShield:onStart()
	playerTypes = getPlayerTypes()
	currPlayerType = playerTypes[0]

	currFrame = 0

	-- External Item Description
	if not __eidTrinketDescriptions then
		__eidTrinketDescriptions = {}
	end
	__eidTrinketDescriptions[FireShield.TRINKET_FIRE_SHIELD] = "Grants immunity to all fire and fire hazards"
end

function FireShield:onUpdate()
	currFrame = Game():GetFrameCount()
end

FireShield:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, FireShield.onStart)
FireShield:AddCallback(ModCallbacks.MC_POST_UPDATE, FireShield.onUpdate)

function hasBit(var, bit)
	if var == nil then
		return false
	end
	return var % (bit + bit) >= bit
end

local fs_lastColorFrame = {}
local fs_safeColor = Color(0.886, 0.345, 0.133, 1, 0, 0, 0)
local fs_numColorFrames = 15
local fs_onFire = {}

function FireShield:fs_onStart()
	for i = 0, Game():GetNumPlayers() do
		table.insert(fs_lastColorFrame, 0)
		table.insert(fs_onFire, false)
	end
end

function FireShield:fs_onUpdate()
	for i = 0, Game():GetNumPlayers() do
		if fs_onFire[i] and currFrame > fs_lastColorFrame[i] + 1 then
			if Game():GetNumPlayers() == 1 then
				Isaac.GetPlayer(i):SetColor(fs_safeColor, fs_numColorFrames, 0, true, false) -- SetColor() is bugged and always affects all players?
			end
			fs_onFire[i] = false
		end
	end
end

function FireShield:fs_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	-- print(damageSource.Type)
	-- print(damageSource.Variant)
	-- print(damageFlag)
	player = target:ToPlayer()
	currPlayerType = player:GetPlayerType()
	if player:HasTrinket(FireShield.TRINKET_FIRE_SHIELD) then
		if hasBit(damageFlag, DamageFlag.DAMAGE_FIRE) or (damageSource ~= nil and (damageSource.Type == EntityType.ENTITY_FIREPLACE or (damageSource.Type == EntityType.ENTITY_PROJECTILE and damageSource.Variant == ProjectileVariant.PROJECTILE_FIRE) or (damageSource.Entity ~= nil and damageSource.Entity:ToProjectile() ~= nil and damageSource.Entity:ToProjectile().ProjectileFlags == ProjectileFlags.FIRE))) then
			for i = 0, Game():GetNumPlayers() do
				if playerTypes[i] == currPlayerType then
					fs_lastColorFrame[i] = currFrame
					target:SetColor(fs_safeColor, 1, 0, false, false)
					fs_onFire[i] = true
					return false
				end
			end
		end
	end
end

function getPlayerTypes()
	local playerTypes = {}
	for i = 0, Game():GetNumPlayers() do
		table.insert(playerTypes, Isaac.GetPlayer(i):GetPlayerType())
	end
	return playerTypes
end

FireShield:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, FireShield.fs_onStart)
FireShield:AddCallback(ModCallbacks.MC_POST_UPDATE, FireShield.fs_onUpdate)
FireShield:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, FireShield.fs_onHit, EntityType.ENTITY_PLAYER)