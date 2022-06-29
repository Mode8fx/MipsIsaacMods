SpikeShield = RegisterMod("Spike Shield", 1)

SpikeShield.COLLECTIBLE_SPIKE_SHIELD = Isaac.GetItemIdByName("Spike Shield")

SoundEffect.SOUND_SPIKE_SHIELD = Isaac.GetSoundIdByName("spike")

local currFrame = 0

function SpikeShield:onStart()
	currFrame = 0

	-- External Item Description
	if not __eidItemDescriptions then
		__eidItemDescriptions = {}
	end
	__eidItemDescriptions[SpikeShield.COLLECTIBLE_SPIKE_SHIELD] = "Grants immunity to all spikes and spike hazards except sacrifice rooms"
end

function SpikeShield:onUpdate()
	currFrame = Game():GetFrameCount()
end

SpikeShield:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SpikeShield.onStart)
SpikeShield:AddCallback(ModCallbacks.MC_POST_UPDATE, SpikeShield.onUpdate)

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

-- Spiked rocks don't have any unique identifier... but they do have a strange quirk where all their values - including position - are either 0 or nil. So this PROBABLY doesn't include anything else
function damageIsFromSpikedRock(damageFlag, damageSource)
	return damageFlag == 0 and damageSource.Entity == nil and damageSource.Position.X == 0 and damageSource.Position.Y == 0 and damageSource.Type == 0 and damageSource.Variant == 0
end

local ss_lastDamageFrame = 0

function SpikeShield:ss_onStart()
	ss_lastDamageFrame = 0
end

function SpikeShield:ss_onHit(target,damageAmount,damageFlag,damageSource,numCountdownFrames)
	if target and target.Type == EntityType.ENTITY_PLAYER then
		if target:ToPlayer():HasCollectible(SpikeShield.COLLECTIBLE_SPIKE_SHIELD) then
			if ((hasBit(damageFlag, DamageFlag.DAMAGE_SPIKES) and Game():GetRoom():GetType() ~= RoomType.ROOM_SACRIFICE)
				or hasBit(damageFlag, DamageFlag.DAMAGE_CURSED_DOOR)
				or hasBit(damageFlag, DamageFlag.DAMAGE_CHEST)
				or damageIsFromSpikedRock(damageFlag, damageSource)
				or damageSource.Type == 44 or damageSource.Type == 218 or damageSource.Type == 877 or damageSource.Type == 893 or damageSource.Type == 852 or damageSource.Type == 915)
				and not damageIsFromMausoleumDoor(damageFlag) then
				if currFrame > ss_lastDamageFrame + 1 then
					SFXManager():Play(SoundEffect.SOUND_SPIKE_SHIELD, 1, 0, false, 1)
				end
				ss_lastDamageFrame = currFrame
				return false
			end
		end
	end
end

SpikeShield:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SpikeShield.ss_onStart)
SpikeShield:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SpikeShield.ss_onHit, EntityType.ENTITY_PLAYER)