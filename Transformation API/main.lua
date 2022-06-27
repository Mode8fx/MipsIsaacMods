TransformationAPI = RegisterMod("Transformation API", 1)

-- This mod was updated for Repentance, but it is not recommended for use with Repentance due to official transformation tags making it redundant.

local GS = {} -- GameState (save data)
local json = require("json")

local itemConfig = Isaac.GetItemConfig()
local numTransformers = 0

-- _o = official, _m = modded
local items_beelzebub_o = {}
local items_guppy_o = {}
local items_bob_o = {}
local items_conjoined_o = {}
local items_funguy_o = {}
local items_leviathan_o = {}
local items_ohcrap_o = {}
local items_seraphim_o = {}
local items_spun_o = {}
local items_superbum_o = {}
local items_yesmother_o = {}
-- local items_adult_o
local items_bookworm_o = {}
local items_spiderbaby_o = {}
-- local items_stompy_o

local items_beelzebub_m = {}
local items_guppy_m = {}
local items_bob_m = {}
local items_conjoined_m = {}
local items_funguy_m = {}
local items_leviathan_m = {}
local items_ohcrap_m = {}
local items_seraphim_m = {}
local items_spun_m = {}
local items_superbum_m = {}
local items_yesmother_m = {}
local items_bookworm_m = {}
local items_spiderbaby_m = {}

-- local trinkets_beelzebub = {}
-- local trinkets_guppy = {
-- 	TrinketType.TRINKET_KIDS_DRAWING
-- }
-- local trinkets_bob = {}
-- local trinkets_conjoined = {}
-- local trinkets_funguy = {}
-- local trinkets_leviathan = {}
-- local trinkets_ohcrap = {}
-- local trinkets_seraphim = {}
-- local trinkets_spun = {}
-- local trinkets_superbum = {}
-- local trinkets_yesmother = {}
-- local trinkets_bookworm = {}
-- local trinkets_spiderbaby = {}

local player

local numOfCurrItem = 0
local countModded = 0
local countOfficial = 0

function TransformationAPI:onStart()
	if TransformationAPI:HasData() then
		GS = json.decode(TransformationAPI:LoadData())
	else
		GS = {}
	end

	player = Isaac.GetPlayer(0)
	TransformationAPI.COLLECTIBLE_TRANSFORMER = Isaac.GetItemIdByName("Transformer")

	TransformationAPI:initOfficialDicts()

	TransformationAPI:addItemsToTransformation("beelzebub", false, {
		Isaac.GetItemIdByName("Blood Flies"),
		Isaac.GetItemIdByName("Fly Mod"),
		Isaac.GetItemIdByName("Mechanical Flies"),
		Isaac.GetItemIdByName("Orange Boom Fly"),
		Isaac.GetItemIdByName("Overly Attached")
	})
	TransformationAPI:addItemsToTransformation("guppy", false, {
		Isaac.GetItemIdByName("The Gupster!")
	})
	TransformationAPI:addItemsToTransformation("bob", false, {
	})
	TransformationAPI:addItemsToTransformation("conjoined", false, {
	})
	TransformationAPI:addItemsToTransformation("funguy", false, {
		Isaac.GetItemIdByName("Basidospore"),
		Isaac.GetItemIdByName("Glowy Mushroom"),
		Isaac.GetItemIdByName("Green Cap"),
		Isaac.GetItemIdByName("Happy Shroom"),
		Isaac.GetItemIdByName("Mom\'s Mushroom"),
		Isaac.GetItemIdByName("Orange Stem"),
		Isaac.GetItemIdByName("Poison Shroom"),
		Isaac.GetItemIdByName("Protective Shroom"),
		Isaac.GetItemIdByName("Red Stalk")
	})
	TransformationAPI:addItemsToTransformation("leviathan", false, {
	})
	TransformationAPI:addItemsToTransformation("ohcrap", false, {
		Isaac.GetItemIdByName("Mr. Poopy"),
		Isaac.GetItemIdByName("Pooptart")
	})
	TransformationAPI:addItemsToTransformation("seraphim", false, {
		Isaac.GetItemIdByName("Belt of Truth"),
		Isaac.GetItemIdByName("Breastplate of Righteousness"),
		Isaac.GetItemIdByName("Helmet of Salvation"),
		Isaac.GetItemIdByName("Shield of Faith"),
		Isaac.GetItemIdByName("Sword of the Spirit")
	})
	TransformationAPI:addItemsToTransformation("spun", false, {
		Isaac.GetItemIdByName("Allergy Shot"),
		Isaac.GetItemIdByName("Antidepressant"),
		Isaac.GetItemIdByName("Baby Blood"),
		Isaac.GetItemIdByName("Booster Shot"),
		Isaac.GetItemIdByName("Botox"),
		Isaac.GetItemIdByName("Crack"),
		Isaac.GetItemIdByName("Dopamine"),
		Isaac.GetItemIdByName("Empty Syringe"),
		Isaac.GetItemIdByName("Heroin"),
		Isaac.GetItemIdByName("Holy Syringe"),
		Isaac.GetItemIdByName("Lethal Injection"),
		Isaac.GetItemIdByName("Lucky Juice"),
		Isaac.GetItemIdByName("Methanphetamine"),
		Isaac.GetItemIdByName("Morphine"),
		Isaac.GetItemIdByName("Steroids"),
		Isaac.GetItemIdByName("Stim"),
		Isaac.GetItemIdByName("Substance X"),
		Isaac.GetItemIdByName("Used Needle")
	})
	TransformationAPI:addItemsToTransformation("superbum", false, {
	})
	TransformationAPI:addItemsToTransformation("yesmother", false, {
		Isaac.GetItemIdByName("Mom\'s Mole"),
		Isaac.GetItemIdByName("Mom\'s Mushroom"),
		Isaac.GetItemIdByName("Mom\'s Ring"),

		Isaac.GetItemIdByName("Mom\'s Cell"),
	})
	TransformationAPI:addItemsToTransformation("bookworm", false, {
		Isaac.GetItemIdByName("A Greed\'s Guide"),
		Isaac.GetItemIdByName("Book of Genesis"),
		Isaac.GetItemIdByName("Book of Lamentations"),
		Isaac.GetItemIdByName("Book of Mormon"),
		Isaac.GetItemIdByName("Book of Randomness"),
		Isaac.GetItemIdByName("Book of Ruth"),
		Isaac.GetItemIdByName("Book of Tobit"),
		Isaac.GetItemIdByName("Magic Tricks Book"),
		Isaac.GetItemIdByName("Prosperity Gospel"),
		Isaac.GetItemIdByName("Self-Help Book"),
		Isaac.GetItemIdByName("Strategy Guide"),

		Isaac.GetItemIdByName("Book of Books"),
	})
	TransformationAPI:addItemsToTransformation("spiderbaby", false, {
		Isaac.GetItemIdByName("Rainbow Spider")
	})

	if Game():GetFrameCount() == 0 then
		GS.tf_beelzebub = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_guppy = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_bob = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_conjoined = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_funguy = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_leviathan = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_ohcrap = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_seraphim = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_spun = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_superbum = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_yesmother = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_bookworm = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}

		GS.tf_spiderbaby = {
			collected_o = {},
			collected_m = {},
			highestID_o = -1,
			highestID_m = -1,
			transformed = false
		}
	else
		loadCollectedLists(GS.tf_beelzebub)
		loadCollectedLists(GS.tf_guppy)
		loadCollectedLists(GS.tf_bob)
		loadCollectedLists(GS.tf_conjoined)
		loadCollectedLists(GS.tf_funguy)
		loadCollectedLists(GS.tf_leviathan)
		loadCollectedLists(GS.tf_ohcrap)
		loadCollectedLists(GS.tf_seraphim)
		loadCollectedLists(GS.tf_spun)
		loadCollectedLists(GS.tf_superbum)
		loadCollectedLists(GS.tf_yesmother)
		loadCollectedLists(GS.tf_bookworm)
		loadCollectedLists(GS.tf_spiderbaby)
	end
end
TransformationAPI:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, TransformationAPI.onStart)

function TransformationAPI:initOfficialDicts()
	if REPENTANCE then
		local currCollectible
		local currTags
		for i=1,(Isaac.GetItemConfig():GetCollectibles().Size-1) do
			currCollectible = Isaac.GetItemConfig():GetCollectible(i)
			if currCollectible ~= nil then
				currTags = currCollectible.Tags
				if (currTags & ItemConfig.TAG_FLY) == ItemConfig.TAG_FLY then
					TransformationAPI:addItemsToTransformation("beelzebub", true, {i})
				end
				if (currTags & ItemConfig.TAG_GUPPY) == ItemConfig.TAG_GUPPY then
					TransformationAPI:addItemsToTransformation("guppy", true, {i})
				end
				if (currTags & ItemConfig.TAG_BOB) == ItemConfig.TAG_BOB then
					TransformationAPI:addItemsToTransformation("bob", true, {i})
				end
				if (currTags & ItemConfig.TAG_BABY) == ItemConfig.TAG_BABY then
					TransformationAPI:addItemsToTransformation("conjoined", true, {i})
				end
				if (currTags & ItemConfig.TAG_MUSHROOM) == ItemConfig.TAG_MUSHROOM then
					TransformationAPI:addItemsToTransformation("funguy", true, {i})
				end
				if (currTags & ItemConfig.TAG_DEVIL) == ItemConfig.TAG_DEVIL then
					TransformationAPI:addItemsToTransformation("leviathan", true, {i})
				end
				if (currTags & ItemConfig.TAG_POOP) == ItemConfig.TAG_POOP then
					TransformationAPI:addItemsToTransformation("ohcrap", true, {i})
				end
				if (currTags & ItemConfig.TAG_ANGEL) == ItemConfig.TAG_ANGEL then
					TransformationAPI:addItemsToTransformation("seraphim", true, {i})
				end
				if (currTags & ItemConfig.TAG_SYRINGE) == ItemConfig.TAG_SYRINGE then
					TransformationAPI:addItemsToTransformation("spun", true, {i})
				end
				if (currTags & ItemConfig.TAG_MOM) == ItemConfig.TAG_MOM then
					TransformationAPI:addItemsToTransformation("yesmother", true, {i})
				end
				if (currTags & ItemConfig.TAG_BOOK) == ItemConfig.TAG_BOOK then
					TransformationAPI:addItemsToTransformation("bookworm", true, {i})
				end
				if (currTags & ItemConfig.TAG_SPIDER) == ItemConfig.TAG_SPIDER then
					TransformationAPI:addItemsToTransformation("spiderbaby", true, {i})
				end
			end
		end
	else
		items_beelzebub_o = {
			CollectibleType.COLLECTIBLE_JAR_OF_FLIES,
			CollectibleType.COLLECTIBLE_BLUEBABYS_ONLY_FRIEND,
			CollectibleType.COLLECTIBLE_ANGRY_FLY,
			CollectibleType.COLLECTIBLE_BBF,
			CollectibleType.COLLECTIBLE_BEST_BUD,
			CollectibleType.COLLECTIBLE_BIG_FAN,
			CollectibleType.COLLECTIBLE_DISTANT_ADMIRATION,
			CollectibleType.COLLECTIBLE_FOREVER_ALONE,
			CollectibleType.COLLECTIBLE_FRIEND_ZONE,
			CollectibleType.COLLECTIBLE_HALO_OF_FLIES,
			CollectibleType.COLLECTIBLE_HIVE_MIND,
			CollectibleType.COLLECTIBLE_INFESTATION,
			CollectibleType.COLLECTIBLE_LOST_FLY,
			CollectibleType.COLLECTIBLE_MULLIGAN,
			CollectibleType.COLLECTIBLE_OBSESSED_FAN,
			CollectibleType.COLLECTIBLE_PAPA_FLY,
			CollectibleType.COLLECTIBLE_SKATOLE,
			CollectibleType.COLLECTIBLE_SMART_FLY
		}
		items_guppy_o = {
			CollectibleType.COLLECTIBLE_GUPPYS_HEAD,
			CollectibleType.COLLECTIBLE_GUPPYS_PAW,
			CollectibleType.COLLECTIBLE_GUPPYS_HAIRBALL,
			CollectibleType.COLLECTIBLE_GUPPYS_TAIL,
			CollectibleType.COLLECTIBLE_GUPPYS_COLLAR,
			CollectibleType.COLLECTIBLE_DEAD_CAT
		}
		items_bob_o = {
			CollectibleType.COLLECTIBLE_BOBS_ROTTEN_HEAD,
			CollectibleType.COLLECTIBLE_BOBS_BRAIN,
			CollectibleType.COLLECTIBLE_IPECAC,
			CollectibleType.COLLECTIBLE_BOBS_CURSE
		}
		items_conjoined_o = {
			CollectibleType.COLLECTIBLE_BROTHER_BOBBY,
			CollectibleType.COLLECTIBLE_HARLEQUIN_BABY,
			CollectibleType.COLLECTIBLE_LITTLE_STEVEN,
			CollectibleType.COLLECTIBLE_SISTER_MAGGY,
			CollectibleType.COLLECTIBLE_MONGO_BABY,
			CollectibleType.COLLECTIBLE_ROTTEN_BABY,
			CollectibleType.COLLECTIBLE_HEADLESS_BABY
		}
		items_funguy_o = {
			CollectibleType.COLLECTIBLE_GODS_FLESH,
			CollectibleType.COLLECTIBLE_ODD_MUSHROOM_RATE,
			CollectibleType.COLLECTIBLE_MINI_MUSH,
			CollectibleType.COLLECTIBLE_ODD_MUSHROOM_DAMAGE,
			CollectibleType.COLLECTIBLE_BLUE_CAP,
			CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM,
			CollectibleType.COLLECTIBLE_ONE_UP
		}
		items_leviathan_o = {
			CollectibleType.COLLECTIBLE_THE_NAIL,
			CollectibleType.COLLECTIBLE_SPIRIT_NIGHT,
			CollectibleType.COLLECTIBLE_MAW_OF_VOID,
			CollectibleType.COLLECTIBLE_PENTAGRAM,
			CollectibleType.COLLECTIBLE_BRIMSTONE,
			CollectibleType.COLLECTIBLE_MARK,
			CollectibleType.COLLECTIBLE_PACT,
			CollectibleType.COLLECTIBLE_ABADDON
		}
		items_ohcrap_o = {
			CollectibleType.COLLECTIBLE_FLUSH,
			CollectibleType.COLLECTIBLE_POOP,
			CollectibleType.COLLECTIBLE_E_COLI
		}
		items_seraphim_o = {
			CollectibleType.COLLECTIBLE_DEAD_DOVE,
			CollectibleType.COLLECTIBLE_MITRE,
			CollectibleType.COLLECTIBLE_GUARDIAN_ANGEL,
			CollectibleType.COLLECTIBLE_SWORN_PROTECTOR,
			CollectibleType.COLLECTIBLE_HOLY_MANTLE,
			CollectibleType.COLLECTIBLE_BIBLE,
			CollectibleType.COLLECTIBLE_ROSARY,
			CollectibleType.COLLECTIBLE_HOLY_GRAIL,
			CollectibleType.COLLECTIBLE_HALO
		}
		items_spun_o = {
			CollectibleType.COLLECTIBLE_EUTHANASIA,
			CollectibleType.COLLECTIBLE_VIRUS,
			CollectibleType.COLLECTIBLE_ROID_RAGE,
			CollectibleType.COLLECTIBLE_SPEED_BALL,
			CollectibleType.COLLECTIBLE_SYNTHOIL,
			CollectibleType.COLLECTIBLE_GROWTH_HORMONES,
			CollectibleType.COLLECTIBLE_ADRENALINE,
			CollectibleType.COLLECTIBLE_EXPERIMENTAL_TREATMENT
		}
		items_superbum_o = {
			CollectibleType.COLLECTIBLE_BUM_FRIEND,
			CollectibleType.COLLECTIBLE_DARK_BUM,
			CollectibleType.COLLECTIBLE_KEY_BUM
		}
		items_yesmother_o = {
			CollectibleType.COLLECTIBLE_MOMS_BOTTLE_PILLS,
			CollectibleType.COLLECTIBLE_MOMS_BRA,
			CollectibleType.COLLECTIBLE_MOMS_PAD,
			CollectibleType.COLLECTIBLE_MOMS_SHOVEL,
			CollectibleType.COLLECTIBLE_MOMS_CONTACTS,
			CollectibleType.COLLECTIBLE_MOMS_EYE,
			CollectibleType.COLLECTIBLE_MOMS_EYESHADOW,
			CollectibleType.COLLECTIBLE_MOMS_HEELS,
			CollectibleType.COLLECTIBLE_MOMS_LIPSTICK,
			CollectibleType.COLLECTIBLE_MOMS_PEARLS,
			CollectibleType.COLLECTIBLE_MOMS_PERFUME,
			CollectibleType.COLLECTIBLE_MOMS_PURSE,
			CollectibleType.COLLECTIBLE_MOMS_UNDERWEAR,
			CollectibleType.COLLECTIBLE_MOMS_KNIFE,
			CollectibleType.COLLECTIBLE_MOMS_RAZOR,
			CollectibleType.COLLECTIBLE_MOMS_WIG,
			CollectibleType.COLLECTIBLE_MOMS_COIN_PURSE,
			CollectibleType.COLLECTIBLE_MOMS_KEY
		}
		-- items_adult_o
		items_bookworm_o = {
			CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL,
			CollectibleType.COLLECTIBLE_NECRONOMICON,
			CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS,
			CollectibleType.COLLECTIBLE_BIBLE,
			CollectibleType.COLLECTIBLE_ANARCHIST_COOKBOOK,
			CollectibleType.COLLECTIBLE_BOOK_REVELATIONS,
			CollectibleType.COLLECTIBLE_BOOK_OF_SIN,
			CollectibleType.COLLECTIBLE_MONSTER_MANUAL,
			CollectibleType.COLLECTIBLE_BOOK_OF_SECRETS,
			CollectibleType.COLLECTIBLE_HOW_TO_JUMP,
			CollectibleType.COLLECTIBLE_TELEPATHY_BOOK,
			CollectibleType.COLLECTIBLE_SATANIC_BIBLE
		}
		items_spiderbaby_o = {
			CollectibleType.COLLECTIBLE_BOX_OF_SPIDERS,
			CollectibleType.COLLECTIBLE_SPIDER_BUTT,
			CollectibleType.COLLECTIBLE_SPIDER_BITE,
			CollectibleType.COLLECTIBLE_SPIDERBABY,
			CollectibleType.COLLECTIBLE_MUTANT_SPIDER,
			CollectibleType.COLLECTIBLE_SPIDER_MOD
		}
	end
end

function TransformationAPI:addItemsToTransformation(transformation, useOfficialList, addedItems)
	if transformation == "beelzebub" then
		if useOfficialList then
			tfList = items_beelzebub_o
		else
			tfList = items_beelzebub_m
		end
		tfID = "3"
		icTag = ItemConfig.TAG_FLY
	end
	if transformation == "guppy" then
		if useOfficialList then
			tfList = items_guppy_o
		else
			tfList = items_guppy_m
		end
		tfID = "1"
		icTag = ItemConfig.TAG_GUPPY
	end
	if transformation == "bob" then
		if useOfficialList then
			tfList = items_bob_o
		else
			tfList = items_bob_m
		end
		tfID = "8"
		icTag = ItemConfig.TAG_BOB
	end
	if transformation == "conjoined" then
		if useOfficialList then
			tfList = items_conjoined_o
		else
			tfList = items_conjoined_m
		end
		tfID = "4"
		icTag = ItemConfig.TAG_BABY
	end
	if transformation == "funguy" then
		if useOfficialList then
			tfList = items_funguy_o
		else
			tfList = items_funguy_m
		end
		tfID = "2"
		icTag = ItemConfig.TAG_MUSHROOM
	end
	if transformation == "leviathan" then
		if useOfficialList then
			tfList = items_leviathan_o
		else
			tfList = items_leviathan_m
		end
		tfID = "9"
		icTag = ItemConfig.TAG_DEVIL
	end
	if transformation == "ohcrap" then
		if useOfficialList then
			tfList = items_ohcrap_o
		else
			tfList = items_ohcrap_m
		end
		tfID = "7"
		icTag = ItemConfig.TAG_POOP
	end
	if transformation == "seraphim" then
		if useOfficialList then
			tfList = items_seraphim_o
		else
			tfList = items_seraphim_m
		end
		tfID = "10"
		icTag = ItemConfig.TAG_ANGEL
	end
	if transformation == "spun" then
		if useOfficialList then
			tfList = items_spun_o
		else
			tfList = items_spun_m
		end
		tfID = "5"
		icTag = ItemConfig.TAG_SYRINGE
	end
	if transformation == "superbum" then
		if useOfficialList then
			tfList = items_superbum_o
		else
			tfList = items_superbum_m
		end
		tfID = "11"
		icTag = ItemConfig.TAG_QUEST -- superbum isn't really used
	end
	if transformation == "yesmother" then
		if useOfficialList then
			tfList = items_yesmother_o
		else
			tfList = items_yesmother_m
		end
		tfID = "6"
		icTag = ItemConfig.TAG_MOM
	end
	if transformation == "bookworm" then
		if useOfficialList then
			tfList = items_bookworm_o
		else
			tfList = items_bookworm_m
		end
		tfID = "12"
		icTag = ItemConfig.TAG_BOOK
	end
	if transformation == "spiderbaby" then
		if useOfficialList then
			tfList = items_spiderbaby_o
		else
			tfList = items_spiderbaby_m
		end
		tfID = "13"
		icTag = ItemConfig.TAG_SPIDER
	end
	for _, itemID in pairs(addedItems) do
		if itemID ~= nil and itemID ~= -1 and not contains(tfList, itemID) and not (REPENTANCE and itemConfig:GetCollectible(itemID):HasTags(icTag)) then
			table.insert(tfList, itemID)
			if not useOfficialList then
				-- External Item Description
				if not __eidItemDescriptions then
					__eidItemDescriptions = {}
				end
				if not __eidItemTransformations then
					__eidItemTransformations = {}
				end
				if __eidItemTransformations[itemID] == nil or __eidItemTransformations[itemID] == "0" then
					__eidItemTransformations[itemID] = tfID
					if __eidItemDescriptions[itemID] == nil then
						__eidItemDescriptions[itemID] = itemConfig:GetCollectible(itemID).Description
					end
				end
			end
		end
	end
end

function contains(list, elem)
	for _, value in pairs(list) do
		if value == elem then
			return true
		end
	end
	return false
end

function TransformationAPI:onExit(save)
	setCollectedListsForSave(GS.tf_beelzebub)
	setCollectedListsForSave(GS.tf_guppy)
	setCollectedListsForSave(GS.tf_bob)
	setCollectedListsForSave(GS.tf_conjoined)
	setCollectedListsForSave(GS.tf_funguy)
	setCollectedListsForSave(GS.tf_leviathan)
	setCollectedListsForSave(GS.tf_ohcrap)
	setCollectedListsForSave(GS.tf_seraphim)
	setCollectedListsForSave(GS.tf_spun)
	setCollectedListsForSave(GS.tf_superbum)
	setCollectedListsForSave(GS.tf_yesmother)
	setCollectedListsForSave(GS.tf_bookworm)
	setCollectedListsForSave(GS.tf_spiderbaby)

	TransformationAPI:SaveData(json.encode(GS))
end
TransformationAPI:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, TransformationAPI.onExit)
TransformationAPI:AddCallback(ModCallbacks.MC_POST_GAME_END, TransformationAPI.onExit)

function setCollectedListsForSave(tf)
	for i=1, tf.highestID_o do
		if tf.collected_o[i] == nil then
			tf.collected_o[i] = 0
		end
	end
	for i=1, tf.highestID_m do
		if tf.collected_m[i] == nil then
			tf.collected_m[i] = 0
		end
	end
end

function loadCollectedLists(tf)
	local new_collected_o = {}
	for i=1, tf.highestID_o do
		if tf.collected_o[i] > 0 then
			new_collected_o[i] = tf.collected_o[i]
		end
	end
	tf.collected_o = new_collected_o

	local new_collected_m = {}
	for i=1, tf.highestID_m do
		if tf.collected_m[i] > 0 then
			new_collected_m[i] = tf.collected_m[i]
		end
	end
	tf.collected_m = new_collected_m
end

function TransformationAPI:onUpdate()
	if TransformationAPI.COLLECTIBLE_TRANSFORMER == -1 then
		numTransformers = 0
	else
		numTransformers = player:GetCollectibleNum(TransformationAPI.COLLECTIBLE_TRANSFORMER)
	end

	-- Transformations --
	checkForTransformation(GS.tf_beelzebub,  items_beelzebub_o,  items_beelzebub_m,  0)
	checkForTransformation(GS.tf_guppy,      items_guppy_o,      items_guppy_m,      1)
	checkForTransformation(GS.tf_bob,        items_bob_o,        items_bob_m,        2)
	checkForTransformation(GS.tf_conjoined,  items_conjoined_o,  items_conjoined_m,  3)
	checkForTransformation(GS.tf_funguy,     items_funguy_o,     items_funguy_m,     4)
	checkForTransformation(GS.tf_leviathan,  items_leviathan_o,  items_leviathan_m,  5)
	checkForTransformation(GS.tf_ohcrap,     items_ohcrap_o,     items_ohcrap_m,     6)
	checkForTransformation(GS.tf_seraphim,   items_seraphim_o,   items_seraphim_m,   7)
	checkForTransformation(GS.tf_spun,       items_spun_o,       items_spun_m,       8)
	checkForTransformation(GS.tf_superbum,   items_superbum_o,   items_superbum_m,   9)
	checkForTransformation(GS.tf_yesmother,  items_yesmother_o,  items_yesmother_m,  10)
	checkForTransformation(GS.tf_bookworm,   items_bookworm_o,   items_bookworm_m,   11)
	checkForTransformation(GS.tf_spiderbaby, items_spiderbaby_o, items_spiderbaby_m, 12)
end
TransformationAPI:AddCallback(ModCallbacks.MC_POST_UPDATE, TransformationAPI.onUpdate)

function checkForTransformation(tf, itemListOfficial, itemListModded, tfIndex)
	if not tf.transformed then
		for _, item in pairs(itemListModded) do
			numOfCurrItem = player:GetCollectibleNum(item)
			if numOfCurrItem > 0 then
				tf.collected_m[item] = numOfCurrItem
				tf.highestID_m = math.max(tf.highestID_m, item)
			end
		end
		countModded = 0
		for _, j in pairs(tf.collected_m) do
			if j > 0 then
				if REPENTANCE then
					countModded = countModded + j
				else
					countModded = countModded + 1
				end
			end
		end
		if not REPENTANCE then
			countModded = countModded + numTransformers -- Transformer already has Repentance tags
		end
		for _, item in pairs(itemListOfficial) do
			numOfCurrItem = player:GetCollectibleNum(item)
			if numOfCurrItem > 0 then
				tf.collected_o[item] = numOfCurrItem
				tf.highestID_o = math.max(tf.highestID_o, item)
			end
		end
		if countModded > 0 then
			countOfficial = 0
			for _, j in pairs(tf.collected_o) do
				if j > 0 then
					if REPENTANCE then
						countOfficial = countOfficial + j
					else
						countOfficial = countOfficial + 1
					end
				end
			end
			-- hardcoding Kid's Drawing trinket to still work with Guppy
			if REPENTANCE and (tfIndex == 1) and player:HasTrinket(TrinketType.TRINKET_KIDS_DRAWING) then
				countOfficial = countOfficial + 1
			end
			countTotal = countOfficial + countModded
			if countTotal >= 3 then
				if countOfficial < 3 then
					for i=1,countModded do
						if REPENTANCE then
							if tfIndex == 0 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Beelzebub)"), 0, true)
							end
							if tfIndex == 1 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Guppy)"), 0, true)
							end
							if tfIndex == 2 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Bob)"), 0, true)
							end
							if tfIndex == 3 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Conjoined)"), 0, true)
							end
							if tfIndex == 4 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Fun Guy)"), 0, true)
							end
							if tfIndex == 5 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Leviathan)"), 0, true)
							end
							if tfIndex == 6 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Oh Crap)"), 0, true)
							end
							if tfIndex == 7 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Seraphim)"), 0, true)
							end
							if tfIndex == 8 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Spun)"), 0, true)
							end
							if tfIndex == 10 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Yes Mother)"), 0, true)
							end
							if tfIndex == 11 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Bookworm)"), 0, true)
							end
							if tfIndex == 12 then
								player:AddCollectible(Isaac.GetItemIdByName("TFAPI Token (Spider Baby)"), 0, true)
							end
						else
							for i=1,#itemListOfficial do
								if tf.collected_o[itemListOfficial[i]] == nil or tf.collected_o[itemListOfficial[i]] == 0 then
									local currItem = player:GetActiveItem()
									local currCharge = player:GetActiveCharge() + player:GetBatteryCharge()
									player:RemoveCollectible(currItem)
									player:AddCollectible(itemListOfficial[i], 0, false) -- false would need to be changed to true for repentance (among other things)
									tf.highestID_o = math.max(tf.highestID_o, itemListOfficial[i])
									tf.collected_o[itemListOfficial[i]] = 1
									player:RemoveCollectible(itemListOfficial[i])
									player:AddCollectible(currItem, currCharge, false)
									break
								end
							end
						end
					end
				end
				tf.transformed = true
			end
		end
	end
end

-- function itemIDInList(id, list)
-- 	for index in pairs(list) do
-- 		if list[index] = id then
-- 			return index
-- 		end
-- 	end
-- 	return -1
-- end