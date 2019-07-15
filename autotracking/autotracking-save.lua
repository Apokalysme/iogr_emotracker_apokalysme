-- Configuration --------------------------------------
AUTOTRACKER_ENABLE_DEBUG_LOGGING = true
-------------------------------------------------------


-- Settings display
print("")
print("Active Auto-Tracker Configuration")
print("---------------------------------------------------------------------")
print("Enable Item Tracking:        ", AUTOTRACKER_ENABLE_ITEM_TRACKING)
if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
    print("Enable Debug Logging:        ", "true")
end
print("---------------------------------------------------------------------")
print("")

function autotracker_started()
    -- Invoked when the auto-tracker is activated/connected
end

-- Initial values

-- Clean memory read values
U8_READ_CACHE = 0
U8_READ_CACHE_ADDRESS = 0

U16_READ_CACHE = 0
U16_READ_CACHE_ADDRESS = 0

-- Item table
-- each item has an unique value in inventory
ITEM_TABLE = {
	[2] = "prison_key",
	[3] = "inca_statue_a",
	[4] = "inca_statue_b",
	[7] = "diamond_block",
	[8] = "melody_wind",
	[9] = "melody_lola",
	[10] = "large_roast",
	[11] = "mine_key_a",
	[12] = "mine_key_b",
	[13] = "melody_memory",
	[15] = "elevator_key",
	[16] = "mu_key",
	[17] = "purity_stone",
	[20] = "magic_dust",
	[22] = "letter_lance",
	[23] = "necklace",
	[24] = "will",
	[25] = "teapot",
	[28] = "black_glasses",
	[29] = "gorgon_flower",
	[30] = "hieroglyph_5",
	[31] = "hieroglyph_4",
	[32] = "hieroglyph_3",
	[33] = "hieroglyph_1",
	[34] = "hieroglyph_6",
	[35] = "hieroglyph_2",
	[36] = "aura",
	[37] = "letter_lola",
	[38] = "journal",
	[39] = "crystal_ring",
	[40] = "apple"
}

KARA_LOCATION = 0
-- Kara Location - $0x039520 :
-- Edward's: #$a7
-- Diamond Mine: #$80
-- Angel: #$86
-- Mt. Kress: #$2a
-- Ankor Wat: #$8a
KARA_LOCATION_STAGE = {
	[167] = 1,
	[128] = 2,
	[134] = 3,
	[42] = 4,
	[138] = 5
}
KARA_SET = 0

-- global variables
INVENTORY_COUNT = 0

HERB_COUNT = 0
HERB_USED = 0
CRYSTAL_BALL_COUNT = 0
CRYSTAL_BALL_USED = 0
HOPE_STATUE_COUNT = 0
HOPE_STATUE_USED = 0
RAMA_STATUE_COUNT = 0
RAMA_STATUE_USED = 0
MUSHROOM_DROPS_COUNT = 0
MUSHROOM_DROPS_USED = 0
HIEROGLYPH_COUNT = 0
HIEROGLYPH_USED = 0

MYSTIC_STATUE_1_NEEDED = 0
MYSTIC_STATUE_2_NEEDED = 0
MYSTIC_STATUE_3_NEEDED = 0
MYSTIC_STATUE_4_NEEDED = 0
MYSTIC_STATUE_5_NEEDED = 0
MYSTIC_STATUE_6_NEEDED = 0
MYSTIC_STATUE_CHECK = 0
MYSTIC_STATUE_SET = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0
}

HIEROGLYPHS_CHECK = 0
HIEROGLYPHS_CODE = {
	[49600] = 1,
	[50114] = 2,
	[50628] = 3,
	[51142] = 4,
	[51656] = 5,
	[52170] = 6
}
HIEROGLYPHS_COMBINATION_CHECK = 0
HIEROGLYPHS_COMBINATION = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0
}

ABILITY = {
	["psycho_dash"] = 0,
	["dark_friar"] = 0
}
UPGRADE = {
	["psycho_dash"] = 0,
	["dark_friar"] = 0
}

-- Reset cache addresses
function InvalidateReadCaches()
    U8_READ_CACHE_ADDRESS = 0
    U16_READ_CACHE_ADDRESS = 0
end

-- Read an address in memory segment (Unsigned Int 8 bits)
function ReadU8(segment, address)
    if U8_READ_CACHE_ADDRESS ~= address then
		-- Read value
        U8_READ_CACHE = segment:ReadUInt8(address)
		-- Save address
        U8_READ_CACHE_ADDRESS = address
    end

    return U8_READ_CACHE
end

-- Read an address in memory segment (Unsigned Int 16 bits)
function ReadU16(segment, address)
    if U16_READ_CACHE_ADDRESS ~= address then
        U16_READ_CACHE = segment:ReadUInt16(address)
        U16_READ_CACHE_ADDRESS = address        
    end

    return U16_READ_CACHE
end

-- Check if game is running
function isInGame()
	-- Read address "0" in "0x7e0061" segment
	-- check if value is greater than "0x01"
    return AutoTracker:ReadU8(0x7e0061, 0) >= 0x01
end

function lastItemAddedInInventory()
	local value = AutoTracker:ReadU8(0x7e0db8, 0)
	
	local item = ITEM_TABLE[value]
	
	return item
end

function inventoryCount(segment)
	-- inventory 0x7e0ab4 to 0x7e0ac3
	local count = 0
	local herb_count = 0
	local crystal_ball_count = 0
	local hope_statue_count = 0
	local rama_statue_count = 0
	local mushroom_drops_count = 0
	local hieroglyph_count = 0
	
	for i = 0, 15 do
		local value = ReadU8(segment, 0x7e0ab4 + i)

		if value > 0 then
			count = count + 1
		end
		
		if value == 6 then
			herb_count = herb_count + 1
		elseif value == 14 then
			crystal_ball_count = crystal_ball_count + 1
		elseif value == 18 then
			hope_statue_count = hope_statue_count + 1
		elseif value == 19 then
			rama_statue_count = rama_statue_count + 1
		elseif value == 26 then
			mushroom_drops_count = mushroom_drops_count + 1
		elseif value == 30 or value == 31 or value == 32 or value == 33 or value == 34 or value == 35 then
			hieroglyph_count = hieroglyph_count + 1
		end
		
	end
	
	return count, herb_count, crystal_ball_count, hope_statue_count, rama_statue_count, mushroom_drops_count, hieroglyph_count
end

-- detect new item added into inventory
function newItemInInventory(segment)
	local count, herb_count, crystal_ball_count, hope_statue_count, rama_statue_count, mushroom_drops_count, hieroglyph_count = inventoryCount(segment)
	
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
		print("INVENTORY :")
		print("Actual count : ", INVENTORY_COUNT)
		print("New count : ", count)
	end
	
	if count ~= INVENTORY_COUNT then
		for i = 0, 15 do
			local value = ReadU8(segment, 0x7e0ab4 + i)
	
			if (value > 0 and ITEM_TABLE[value]) then
				updateToggleItem(ITEM_TABLE[value])
			end
		end
	
		INVENTORY_COUNT = count
	end
	
	if herb_count + HERB_USED ~= HERB_COUNT then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("HERBS COUNT :")
			print("Actual count : ", HERB_COUNT)
			print("New count : ", herb_count)
			print("HERBS USED : ", HERB_USED)
		end
		if herb_count + HERB_USED > HERB_COUNT then
			HERB_COUNT = HERB_COUNT + 1
			updateHerbs(segment)
		elseif herb_count + HERB_USED < HERB_COUNT then
			HERB_USED = HERB_USED + 1
		end
	end
	
	if crystal_ball_count + CRYSTAL_BALL_USED ~= CRYSTAL_BALL_COUNT then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("CRYSTAL BALLS COUNT :")
			print("Actual count : ", CRYSTAL_BALL_COUNT)
			print("New count : ", crystal_ball_count)
			print("CRYSTAL BALLS USED : ", CRYSTAL_BALL_USED)
		end
		if crystal_ball_count + CRYSTAL_BALL_USED > CRYSTAL_BALL_COUNT then
			CRYSTAL_BALL_COUNT = CRYSTAL_BALL_COUNT + 1
			updateCrystalBalls(segment)
		elseif crystal_ball_count + CRYSTAL_BALL_USED < CRYSTAL_BALL_COUNT then
			CRYSTAL_BALL_USED = CRYSTAL_BALL_USED + 1
		end
	end
	
	if hope_statue_count + HOPE_STATUE_USED ~= HOPE_STATUE_COUNT then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("HOPE STATUES COUNT :")
			print("Actual count : ", HOPE_STATUE_COUNT)
			print("New count : ", hope_statue_count)
			print("HOPE STATUES USED : ", HOPE_STATUE_USED)
		end
		if hope_statue_count + HOPE_STATUE_USED > HOPE_STATUE_COUNT then
			HOPE_STATUE_COUNT = HOPE_STATUE_COUNT + 1
			updateHopeStatues(segment)
		elseif hope_statue_count + HOPE_STATUE_USED < HOPE_STATUE_COUNT then
			HOPE_STATUE_USED = HOPE_STATUE_USED + 1
		end
	end
	
	if rama_statue_count + RAMA_STATUE_USED ~= RAMA_STATUE_COUNT then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("RAMA STATUES COUNT :")
			print("Actual count : ", RAMA_STATUE_COUNT)
			print("New count : ", rama_statue_count)
			print("RAMA STATUES USED : ", RAMA_STATUE_USED)
		end
		if rama_statue_count + RAMA_STATUE_USED > RAMA_STATUE_COUNT then
			RAMA_STATUE_COUNT = RAMA_STATUE_COUNT + 1
			updateRamaStatues(segment)
		elseif rama_statue_count + RAMA_STATUE_USED < RAMA_STATUE_COUNT then
			RAMA_STATUE_USED = RAMA_STATUE_USED + 1
		end
	end
	
	if mushroom_drops_count + MUSHROOM_DROPS_USED ~= MUSHROOM_DROPS_COUNT then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("MUSHROOM DROPS COUNT :")
			print("Actual count : ", MUSHROOM_DROPS_COUNT)
			print("New count : ", mushroom_drops_count)
			print("MUSHROOM DROPS USED : ", MUSHROOM_DROPS_USED)
		end
		if mushroom_drops_count + MUSHROOM_DROPS_USED > MUSHROOM_DROPS_COUNT then
			MUSHROOM_DROPS_COUNT = MUSHROOM_DROPS_COUNT + 1
			updateMushroomDrops(segment)
		elseif mushroom_drops_count + MUSHROOM_DROPS_USED < MUSHROOM_DROPS_COUNT then
			MUSHROOM_DROPS_USED = MUSHROOM_DROPS_USED + 1
		end
	end
	
	if hieroglyph_count + HIEROGLYPH_USED ~= HIEROGLYPH_COUNT then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("HIEROGLYPHS COUNT :")
			print("Actual count : ", HIEROGLYPH_COUNT)
			print("New count : ", hieroglyph_count)
			print("HIEROGLYPHS USED : ", HIEROGLYPH_USED)
		end
		if hieroglyph_count + HIEROGLYPH_USED > HIEROGLYPH_COUNT then
			HIEROGLYPH_COUNT = HIEROGLYPH_COUNT + 1
			updateHieroglyphCount(segment)
		elseif hieroglyph_count + HIEROGLYPH_USED < HIEROGLYPH_COUNT then
			HIEROGLYPH_USED = HIEROGLYPH_USED + 1
		end
	end
end

-- update "progressive" item depending on memory state
function updateProgressiveItemFromByte(segment, code, address, offset)
	-- find tracker object from specified code
    local item = Tracker:FindObjectForCode(code)
	
	-- if item is found
    if item then
		-- read item state in memory
        local value = ReadU8(segment, address)
		-- update tracker with result
        item.CurrentStage = value + offset
    end
end

-- update Red Jewels count from count in memory
function updateRedJewels(segment)
    local item = Tracker:FindObjectForCode("red_jewel")
    local actualCount = item.AcquiredCount
    local newCount = tonumber(string.format("%04X", ReadU8(segment, 0x7e0ab0)))
	
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
		print("RED JEWELS COUNT :")
		print("Actual count : ", actualCount)
		print("New count : ", newCount)
	end
	
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

function updateHerbs(segment)
    local item = Tracker:FindObjectForCode("herb")
    local actualCount = item.AcquiredCount
    local newCount = HERB_COUNT
	
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

function updateCrystalBalls(segment)
    local item = Tracker:FindObjectForCode("crystal_ball")
    local actualCount = item.AcquiredCount
    local newCount = CRYSTAL_BALL_COUNT
	
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

function updateHopeStatues(segment)
    local item = Tracker:FindObjectForCode("hope_statue")
    local actualCount = item.AcquiredCount
    local newCount = HOPE_STATUE_COUNT
	
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

function updateRamaStatues(segment)
    local item = Tracker:FindObjectForCode("rama_statue")
    local actualCount = item.AcquiredCount
    local newCount = RAMA_STATUE_COUNT
	
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

function updateMushroomDrops(segment)
    local item = Tracker:FindObjectForCode("mushroom_drop")
    local actualCount = item.AcquiredCount
    local newCount = MUSHROOM_DROPS_COUNT
	
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

function updateHieroglyphCount(segment)
    local item = Tracker:FindObjectForCode("hieroglyph_count")
    local actualCount = item.AcquiredCount
    local newCount = HIEROGLYPH_COUNT
	
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

function updateToggleItem(code)
	local item = Tracker:FindObjectForCode(code)
	
	if code ~= "red_jewel" and code ~= "herb" then
		if (item and item.Active ~= true) then
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
				print("Obtained item : ", code)
			end
			item.Active = true
		end
	end
end

-- update "toggle" from flag in address (case of multiple flags on same address)
function updateToggleItemFromByteAndFlag(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)

        local flagTest = value & flag
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Toggle code : ", code)
			print("Value : ", value)
			print("Flag Test : ", flagTest)
		end
		
        if flagTest ~= 0 then
            item.Active = true
        else
            item.Active = false
        end
    end
end

function updateProgressiveItemFromByteAndFlag(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)

        local flagTest = value & flag
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Toggle code : ", code)
			print("Value : ", value)
			print("Flag Test : ", flagTest)
		end
		
        if flagTest ~= 0 then
			if UPGRADE[code] == 1 then
				item.CurrentStage = 2
			else
				item.CurrentStage = 1
				ABILITY[code] = 1
			end
        else
            item.CurrentStage = 0
        end
    end
end

function upgradeAbilityFromByteAndFlag(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
	
    if item then
		local value = ReadU8(segment, address)
	
		local upgradeTest = value & flag
		
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Toggle code : ", code)
			print("Value : ", value)
			print("Upgrade Test : ", upgradeTest)
		end

		if upgradeTest ~= 0 then
			if ABILITY[code] == 1 then
				item.CurrentStage = 2
			else
				UPGRADE[code] = 1
			end
		end
    end
end

function updateKaraIndicatorStatusFromLetter(segment, code, address, flag)
	local item = Tracker:FindObjectForCode(code)
    if item then
		-- address pre-1.3.3
		KARA_LOCATION = AutoTracker:ReadU8(0x039523, 0)
		
		local value = ReadU8(segment, address)
		
		local flagTest = value & flag
	
        if flagTest ~= 0 then
            item.CurrentStage = KARA_LOCATION_STAGE[KARA_LOCATION]
			KARA_SET = 1
        else
            item.CurrentStage = 0
        end
    end
end

function updateNeededStatues(segment, code, address, status, number)
	local item = Tracker:FindObjectForCode(code)
	
	if item then
		local value = ReadU8(segment, address)

        if value ~= 8 and status then
            item.CurrentStage = 1
			MYSTIC_STATUE_SET[number] = 1
		elseif MYSTIC_STATUE_SET[number] ~= 1 then
            item.CurrentStage = 0
			MYSTIC_STATUE_SET[number] = 1
        end
    end
end

function updateKaraIndicatorStatusFromRoom(segment, code, address)
	local item = Tracker:FindObjectForCode(code)
	
	KARA_LOCATION = AutoTracker:ReadU8(0x039523, 0)
	
	-- Edward's: #$13
	-- Mine: #$47
	-- Angel: #$74
	-- Kress: #$a9
	-- Ankor Wat: #$bf
	if item then
		local value = ReadU8(segment, address)
	
        if value == 19 and KARA_LOCATION_STAGE[KARA_LOCATION] == 1 then
            item.CurrentStage = 1
			KARA_SET = 1
        elseif value == 71 and KARA_LOCATION_STAGE[KARA_LOCATION] == 2 then
			item.CurrentStage = 2
			KARA_SET = 1
        elseif value == 116 and KARA_LOCATION_STAGE[KARA_LOCATION] == 3 then
			item.CurrentStage = 3
			KARA_SET = 1
        elseif value == 169 and KARA_LOCATION_STAGE[KARA_LOCATION] == 4 then
			item.CurrentStage = 4
			KARA_SET = 1
        elseif value == 191 and KARA_LOCATION_STAGE[KARA_LOCATION] == 5 then
			item.CurrentStage = 5
			KARA_SET = 1
		else
            item.CurrentStage = 0
        end
    end
end

function updateCombinationFromByteAndFlag(segment, address, flag)
	local itemA = Tracker:FindObjectForCode("hieroglyph_a")
	local itemB = Tracker:FindObjectForCode("hieroglyph_b")
	local itemC = Tracker:FindObjectForCode("hieroglyph_c")
	local itemD = Tracker:FindObjectForCode("hieroglyph_d")
	local itemE = Tracker:FindObjectForCode("hieroglyph_e")
	local itemF = Tracker:FindObjectForCode("hieroglyph_f")
	
    if itemA and itemB and itemC and itemD and itemE and itemF then
				
		local value = ReadU8(segment, address)
		local flagTest = value & flag

        if flagTest ~= 0 then
            itemA.CurrentStage = HIEROGLYPHS_COMBINATION[1] - 1
			itemB.CurrentStage = HIEROGLYPHS_COMBINATION[2] - 1
			itemC.CurrentStage = HIEROGLYPHS_COMBINATION[3] - 1
			itemD.CurrentStage = HIEROGLYPHS_COMBINATION[4] - 1
			itemE.CurrentStage = HIEROGLYPHS_COMBINATION[5] - 1
			itemF.CurrentStage = HIEROGLYPHS_COMBINATION[6] - 1
			
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
				print("Hieroglyph 1 : ", itemA.CurrentStage)
				print("Hieroglyph 2 : ", itemB.CurrentStage)
				print("Hieroglyph 3 : ", itemC.CurrentStage)
				print("Hieroglyph 4 : ", itemD.CurrentStage)
				print("Hieroglyph 5 : ", itemE.CurrentStage)
				print("Hieroglyph 6 : ", itemF.CurrentStage)
			end
			
			HIEROGLYPHS_COMBINATION_CHECK = 1
        else
            itemA.CurrentStage = 0
			itemB.CurrentStage = 0
			itemC.CurrentStage = 0
			itemD.CurrentStage = 0
			itemE.CurrentStage = 0
			itemF.CurrentStage = 0
        end
    end
end

function updateSlotFromByte(segment, address, slot)
	
	local item = {
		[1] = nil,
		[2] = nil,
		[3] = nil,
		[4] = nil,
		[5] = nil,
		[6] = nil
	}
	
	item[1] = Tracker:FindObjectForCode("hieroglyph_a")
	item[2] = Tracker:FindObjectForCode("hieroglyph_b")
	item[3] = Tracker:FindObjectForCode("hieroglyph_c")
	item[4] = Tracker:FindObjectForCode("hieroglyph_d")
	item[5] = Tracker:FindObjectForCode("hieroglyph_e")
	item[6] = Tracker:FindObjectForCode("hieroglyph_f")

	print("%d H-slot : ", slot, item[slot].Active)
	
	if item[1] and item[2] and item[3] and item[4] and item[5] and item[6] then
				
		local value = ReadU16(segment, address)
		
		print("Filled with : ", value)

		if value == 0 and HIEROGLYPHS_COMBINATION[slot] == 4 then
			item[slot].Active = true
		elseif value == 1 and HIEROGLYPHS_COMBINATION[slot] == 2 then
			item[slot].Active = true
		elseif value == 2 and HIEROGLYPHS_COMBINATION[slot] == 3 then
			item[slot].Active = true
		elseif value == 3 and HIEROGLYPHS_COMBINATION[slot] == 6 then
			item[slot].Active = true
		elseif value == 4 and HIEROGLYPHS_COMBINATION[slot] == 5 then
			item[slot].Active = true
		elseif value == 5 and HIEROGLYPHS_COMBINATION[slot] == 1 then
			item[slot].Active = true
		end
    end
end

function updateAbilitiesFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        
		updateProgressiveItemFromByteAndFlag(segment, "psycho_dash", 0x7e0aa2, 0x01)
		updateToggleItemFromByteAndFlag(segment, "psycho_slide", 0x7e0aa2, 0x02)
		updateToggleItemFromByteAndFlag(segment, "spin_dash", 0x7e0aa2, 0x04)
		updateProgressiveItemFromByteAndFlag(segment, "dark_friar", 0x7e0aa2, 0x10)
		updateToggleItemFromByteAndFlag(segment, "aura_barrier", 0x7e0aa2, 0x20)
		updateToggleItemFromByteAndFlag(segment, "earthquaker", 0x7e0aa2, 0x40)
		
    end
end

function upgradeAbilitiesFromMemorySegment(segment)
	if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        
		upgradeAbilityFromByteAndFlag(segment, "psycho_dash", 0x7e0b16, 0x01)
		upgradeAbilityFromByteAndFlag(segment, "dark_friar", 0x7e0b1c, 0x02)
		
    end
end

function updateItemsFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        
		newItemInInventory(segment)
		
		updateRedJewels(segment)
		
		-- Oh, do you need to know what the jeweler amounts are?  The seven award amounts are located, respectively, at $8cee0, $8cef1, $8cf02, $8cf13, $8cf24, $8cf35 and $8cf40
		
    end
end

function updateMysticStatuesFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	
		if MYSTIC_STATUE_CHECK == 0 then
			local value1 = AutoTracker:ReadU8(0x08dd19, 0)
			MYSTIC_STATUE_1_NEEDED = (value1 == tonumber(0xf8) or value1 ~= tonumber(0x10))

			local value2 = AutoTracker:ReadU8(0x08dd1f, 0)
			MYSTIC_STATUE_2_NEEDED = (value2 == tonumber(0xf9) or value2 ~= tonumber(0x10))

			local value3 = AutoTracker:ReadU8(0x08dd25, 0)
			MYSTIC_STATUE_3_NEEDED = (value3 == tonumber(0xfa) or value3 ~= tonumber(0x10))

			local value4 = AutoTracker:ReadU8(0x08dd2b, 0)
			MYSTIC_STATUE_4_NEEDED = (value4 == tonumber(0xfb) or value4 ~= tonumber(0x10))

			local value5 = AutoTracker:ReadU8(0x08dd31, 0)
			MYSTIC_STATUE_5_NEEDED = (value5 == tonumber(0xfc) or value5 ~= tonumber(0x10))

			local value6 = AutoTracker:ReadU8(0x08dd37, 0)
			MYSTIC_STATUE_6_NEEDED = (value6 == tonumber(0xfd) or value6 ~= tonumber(0x10))
			
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
				print("Mystic Statue 1 needed : ", MYSTIC_STATUE_1_NEEDED)
				print("Mystic Statue 2 needed : ", MYSTIC_STATUE_2_NEEDED)
				print("Mystic Statue 3 needed : ", MYSTIC_STATUE_3_NEEDED)
				print("Mystic Statue 4 needed : ", MYSTIC_STATUE_4_NEEDED)
				print("Mystic Statue 5 needed : ", MYSTIC_STATUE_5_NEEDED)
				print("Mystic Statue 6 needed : ", MYSTIC_STATUE_6_NEEDED)
			end
			
			MYSTIC_STATUE_CHECK = 1
		end

        updateToggleItemFromByteAndFlag(segment, "mystic_statue_1", 0x7e0a1f, 0x01)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_2", 0x7e0a1f, 0x02)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_3", 0x7e0a1f, 0x04)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_4", 0x7e0a1f, 0x08)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_5", 0x7e0a1f, 0x10)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_6", 0x7e0a1f, 0x20)

    end
end

function updateKaraFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then

        if KARA_LOCATION_STAGE[KARA_LOCATION] == 1 then
            updateToggleItemFromByteAndFlag(segment, "kara2_edwards_castle", 0x7e0a11, 0x04)
        elseif KARA_LOCATION_STAGE[KARA_LOCATION] == 2 then
			updateToggleItemFromByteAndFlag(segment, "kara2_diamond_mine", 0x7e0a11, 0x04)
        elseif KARA_LOCATION_STAGE[KARA_LOCATION] == 3 then
			updateToggleItemFromByteAndFlag(segment, "kara2_angel_dungeon", 0x7e0a11, 0x04)
        elseif KARA_LOCATION_STAGE[KARA_LOCATION] == 4 then
			updateToggleItemFromByteAndFlag(segment, "kara2_mount_kress", 0x7e0a11, 0x04)
        elseif KARA_LOCATION_STAGE[KARA_LOCATION] == 5 then
			updateToggleItemFromByteAndFlag(segment, "kara2_ankor_wat", 0x7e0a11, 0x04)
        end
		
		if KARA_SET == 0 then
			updateKaraIndicatorStatusFromLetter(segment, "save_kara2", 0x7e0a11, 0x40)
		end
    end
end

function updateFromRoomSegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then

		updateNeededStatues(segment, "mystic_statue_1", 0x7e0644, MYSTIC_STATUE_1_NEEDED, 1)
		updateNeededStatues(segment, "mystic_statue_2", 0x7e0644, MYSTIC_STATUE_2_NEEDED, 2)
		updateNeededStatues(segment, "mystic_statue_3", 0x7e0644, MYSTIC_STATUE_3_NEEDED, 3)
		updateNeededStatues(segment, "mystic_statue_4", 0x7e0644, MYSTIC_STATUE_4_NEEDED, 4)
		updateNeededStatues(segment, "mystic_statue_5", 0x7e0644, MYSTIC_STATUE_5_NEEDED, 5)
		updateNeededStatues(segment, "mystic_statue_6", 0x7e0644, MYSTIC_STATUE_6_NEEDED, 6)
	
		if KARA_SET == 0 then
			updateKaraIndicatorStatusFromRoom(segment,"save_kara2", 0x7e0644)
		end
		
    end
end

function updateHieroglyphsCombinationFromMemorySegment(segment)
	if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then

		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Hieroglyph Check : ", HIEROGLYPHS_CHECK)
		end
	
		if HIEROGLYPHS_CHECK == 0 then
			-- Hieroglyph Order: check ROM address $39e9a, this is the location of where the correct order is reported in Father's Journal.  Each hieroglyph character is defined with a two-byte tuple:

			HIEROGLYPHS_COMBINATION[1] = HIEROGLYPHS_CODE[AutoTracker:ReadU16(0x039e9a, 0)]
			HIEROGLYPHS_COMBINATION[2] = HIEROGLYPHS_CODE[AutoTracker:ReadU16(0x039e9c, 0)]
			HIEROGLYPHS_COMBINATION[3] = HIEROGLYPHS_CODE[AutoTracker:ReadU16(0x039e9e, 0)]
			HIEROGLYPHS_COMBINATION[4] = HIEROGLYPHS_CODE[AutoTracker:ReadU16(0x039ea0, 0)]
			HIEROGLYPHS_COMBINATION[5] = HIEROGLYPHS_CODE[AutoTracker:ReadU16(0x039ea2, 0)]
			HIEROGLYPHS_COMBINATION[6] = HIEROGLYPHS_CODE[AutoTracker:ReadU16(0x039ea4, 0)]
			
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
				print("Hieroglyph 1 : ", HIEROGLYPHS_COMBINATION[1])
				print("Hieroglyph 2 : ", HIEROGLYPHS_COMBINATION[2])
				print("Hieroglyph 3 : ", HIEROGLYPHS_COMBINATION[3])
				print("Hieroglyph 4 : ", HIEROGLYPHS_COMBINATION[4])
				print("Hieroglyph 5 : ", HIEROGLYPHS_COMBINATION[5])
				print("Hieroglyph 6 : ", HIEROGLYPHS_COMBINATION[6])
			end
			
			HIEROGLYPHS_CHECK = 1
		end
		
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Hieroglyph Combination Check : ", HIEROGLYPHS_COMBINATION_CHECK)
		end
		
		if HIEROGLYPHS_COMBINATION_CHECK == 0 then
			updateCombinationFromByteAndFlag(segment, 0x7e0a1d, 0x80)
		end
    end
end

function updateHieroglyphsFromMemorySegment(segment)
	if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	
		if HIEROGLYPHS_COMBINATION_CHECK == 1 then
			updateSlotFromByte(segment, 0x7e0b28, 1)
			updateSlotFromByte(segment, 0x7e0b2a, 2)
			updateSlotFromByte(segment, 0x7e0b2c, 3)
			updateSlotFromByte(segment, 0x7e0b2e, 4)
			updateSlotFromByte(segment, 0x7e0b30, 5)
			updateSlotFromByte(segment, 0x7e0b32, 6)
		end
    end
end

function autotracker_started()
	-- Invoked when the auto-tracker is activated/connected
    if AutoTracker.SelectedConnectorType.Name == "SD2SNES" then
        --  Initialize SD2SNES SRAM watches
        print("SD2SNES is not supported")
    end
	
end

ScriptHost:AddMemoryWatch("IoG Item Data", 0x7e0ab0, 0x16, updateItemsFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Ability Data", 0x7e0aa2, 0x01, updateAbilitiesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Ability Upgrade Data", 0x7e0b16, 0x08, upgradeAbilitiesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Mystic Statue Data", 0x7e0a1f, 0x01, updateMysticStatuesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Kara Data", 0x7e0a11, 0x01, updateKaraFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Room Data", 0x7e0644, 0x01, updateFromRoomSegment)
ScriptHost:AddMemoryWatch("IoG Hieroglyphs combination Data", 0x7e0a1d, 0x01, updateHieroglyphsCombinationFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Hieroglyphs Data", 0x7e0b28, 0x10, updateHieroglyphsFromMemorySegment)