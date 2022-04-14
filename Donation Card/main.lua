local DonationCard = RegisterMod("Donation Card", 1)

DonationCard.DONATION_CARD = Isaac.GetCardIdByName("Donation Card")

local GameState = {}
local json = require("json")

local donationCardChance = 65 -- higher number = less likely to appear (default = 65)
-- local usedCard = false
local usedCardInThisRoom = false
local animation = "gfx/donationcarddrop.anm2"

local player
local isGreedMode
local numCoinsDonated
local oldNumCoinsDonated
local numCoins
local oldNumCoins
-- local currRoomHasDonationMachine

function DonationCard:onStart()
	GameState = json.decode(DonationCard:LoadData())
	player = Isaac.GetPlayer(0)
	isGreedMode = Game():IsGreedMode()
	numCoinsDonated = 0
	oldNumCoinsDonated = numCoinsDonated
	numCoins = player:GetNumCoins()
	oldNumCoins = numCoins

	if not __eidCardDescriptions then
	  __eidCardDescriptions = {};
	end
	__eidCardDescriptions[DonationCard.DONATION_CARD] = "Spawns a penny#Spawns/unjams a donation machine#Allows free coin donations for the current room"

	if Game():GetFrameCount() == 0 then
		GameState.totalNumCoinsDonated = 0
		GameState.minDonationLimit = 0
	end
end
DonationCard:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, DonationCard.onStart)

function DonationCard:onExit(save)
	DonationCard:SaveData(json.encode(GameState))
end
DonationCard:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, DonationCard.onExit)
DonationCard:AddCallback(ModCallbacks.MC_POST_GAME_END, DonationCard.onExit)

function DonationCard:onUpdate()
	if usedCardInThisRoom then
		if isGreedMode and Game():GetLevel():GetStage() == 7 and Game():GetRoom():IsClear() then
			-- numCoinsDonated = Game():GetDonationModGreed() -- doesn't work in the API
			numCoins = player:GetNumCoins()
			if numCoins < oldNumCoins then
				numCoinsDonated = numCoinsDonated + (oldNumCoins - numCoins)
			end
		else
			numCoinsDonated = Game():GetDonationModAngel()
		end
		if numCoinsDonated > oldNumCoinsDonated then
			player:AddCoins(numCoinsDonated - oldNumCoinsDonated)
			GameState.totalNumCoinsDonated = GameState.totalNumCoinsDonated + (numCoinsDonated - oldNumCoinsDonated)
			checkForJam()
		end
		oldNumCoinsDonated = numCoinsDonated
		oldNumCoins = numCoins
	end
end

function DonationCard:onUseCard()
	-- Donate_____() doesn't actually donate; it just changes the amount the game thinks you "donated" on the current floor
	local newMachinePos = Isaac.GetFreeNearPosition(Vector(player.Position.X + 30, player.Position.Y - 30), 0)
	Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 1, Isaac.GetFreeNearPosition(Vector(player.Position.X + 20*math.random(-1,1), player.Position.Y + 20*math.random(-1,1)), 0), Vector(0,0), nil):ToPickup()
	usedCardInThisRoom = true
	GameState.minDonationLimit = GameState.totalNumCoinsDonated + 5
	checkForJam()
	local donMachineInRoom = false
	local machineVariant = 8
	if isGreedMode then
		machineVariant = 11
	end
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		if entity.Type == EntityType.ENTITY_SLOT and entity.Variant == machineVariant then
			donMachineInRoom = true
			break
		end
	end
	if not donMachineInRoom then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, newMachinePos, Vector(0,0), nil)
		Isaac.Spawn(EntityType.ENTITY_SLOT, machineVariant, 0, newMachinePos, Vector(0,0), nil)
		SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND, 1, 0, false, 1)
	end
end

function checkForJam()
	if (Game():GetStateFlag(GameStateFlag.STATE_DONATION_SLOT_JAMMED) or Game():GetStateFlag(GameStateFlag.STATE_GREED_SLOT_JAMMED)) and GameState.totalNumCoinsDonated < GameState.minDonationLimit then
		Game():SetStateFlag(GameStateFlag.STATE_DONATION_SLOT_JAMMED, false)
		Game():SetStateFlag(GameStateFlag.STATE_GREED_SLOT_JAMMED, false)
		local machineVariant = 8
		if isGreedMode then
			machineVariant = 11
		end
		for _, entity in pairs(Isaac.GetRoomEntities()) do
			if entity.Type == EntityType.ENTITY_SLOT and entity.Variant == machineVariant then
				local machinePos = entity.Position
				entity:Remove()
				Isaac.Spawn(EntityType.ENTITY_SLOT, machineVariant, 0, machinePos, Vector(0,0), nil)
			end
		end
	end
end

function DonationCard:onNewRoom()
	usedCardInThisRoom = false

	-- for _, entity in pairs(Isaac.GetRoomEntities()) do
	-- 	if entity.Type == EntityType.ENTITY_SLOT and entity.Variant == 8 then
	-- 		currRoomHasDonationMachine = true
	-- 	end
	-- end
end

function DonationCard:onGetCard(rng, currentCard, playing, runes, onlyRunes)
	if not onlyRunes and currentCard ~= Card.CARD_CHAOS and Game().Challenge == 0 then
		local randomInt = rng:RandomInt(donationCardChance)
		if randomInt == 1 and not onlyrunes and current ~= Card.CARD_CHAOS then
			return DonationCard.DONATION_CARD
		end
	end
end

-- function DonationCard:onPickupUpdate(pickup) -- unused since there's a bug that makes it so that newly-spawned cards can't be picked up in some situations without leaving and re-entering the room
-- 	if pickup.Type == EntityType.ENTITY_PICKUP and pickup.Variant == PickupVariant.PICKUP_TAROTCARD and pickup.SubType == DonationCard.DONATION_CARD then
-- 		local sprite = pickup:GetSprite()
-- 		if sprite:GetFilename() ~= animation then
-- 			sprite:Load(animation, true)
-- 			if Game():GetLevel():GetCurrentRoom():GetFrameCount() > 5 and not pickup:IsShopItem() then
-- 				sprite:Play("Appear", true);
-- 			else
-- 				sprite:Play("Idle", true);
-- 			end
-- 		end
-- 		sprite:ReplaceSpritesheet(0, "gfx/donationcard.png")
-- 		sprite:LoadGraphics()
-- 	end
-- end

DonationCard:AddCallback(ModCallbacks.MC_POST_UPDATE, DonationCard.onUpdate);
DonationCard:AddCallback(ModCallbacks.MC_USE_CARD, DonationCard.onUseCard, DonationCard.DONATION_CARD);
DonationCard:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DonationCard.onNewRoom)
DonationCard:AddCallback(ModCallbacks.MC_GET_CARD, DonationCard.onGetCard);
-- DonationCard:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, DonationCard.onPickupUpdate);