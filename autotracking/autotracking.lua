-- Configuration --------------------------------------
AUTOTRACKER_ENABLE_DEBUG_LOGGING = false
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
		elseif value == 30 or value == 31 or value == 32 or value == 33 or value == 34 or value == 35
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
	
	if herb_count ~= HERB_COUNT then
		if herb_count + HERB_USED > HERB_COUNT then
			HERB_COUNT = HERB_COUNT + 1
			updateHerbs(segment)
		elseif herb_count + HERB_USED < HERB_COUNT then
			HERB_USED = HERB_USED + 1
		end
	end
	
	if crystal_ball_count ~= CRYSTAL_BALL_COUNT then
		if crystal_ball_count + CRYSTAL_BALL_USED > CRYSTAL_BALL_COUNT then
			CRYSTAL_BALL_COUNT = CRYSTAL_BALL_COUNT + 1
			updateCrystalBalls(segment)
		elseif crystal_ball_count + CRYSTAL_BALL_USED < CRYSTAL_BALL_COUNT then
			CRYSTAL_BALL_USED = CRYSTAL_BALL_USED + 1
		end
	end
	
	if hope_statue_count ~= HOPE_STATUE_COUNT then
		if hope_statue_count + HOPE_STATUE_USED > HOPE_STATUE_COUNT then
			HOPE_STATUE_COUNT = HOPE_STATUE_COUNT + 1
			updateHopeStatues(segment)
		elseif hope_statue_count + HOPE_STATUE_USED < HOPE_STATUE_COUNT then
			HOPE_STATUE_USED = HOPE_STATUE_USED + 1
		end
	end
	
	if rama_statue_count ~= RAMA_STATUE_COUNT then
		if rama_statue_count + RAMA_STATUE_USED > RAMA_STATUE_COUNT then
			RAMA_STATUE_COUNT = RAMA_STATUE_COUNT + 1
			updateRamaStatues(segment)
		elseif rama_statue_count + RAMA_STATUE_USED < RAMA_STATUE_COUNT then
			RAMA_STATUE_USED = RAMA_STATUE_USED + 1
		end
	end
	
	if mushroom_drops_count ~= MUSHROOM_DROPS_COUNT then
		if mushroom_drops_count + MUSHROOM_DROPS_COUNT > MUSHROOM_DROPS_COUNT then
			MUSHROOM_DROPS_COUNT = MUSHROOM_DROPS_COUNT + 1
			updateMushroomDrops(segment)
		elseif mushroom_drops_count + MUSHROOM_DROPS_USED < MUSHROOM_DROPS_COUNT then
			MUSHROOM_DROPS_USED = MUSHROOM_DROPS_USED + 1
		end
	end
	
	if hieroglyph_count ~= HIEROGLYPH_COUNT then
		if hieroglyph_count + HIEROGLYPH_COUNT > HIEROGLYPH_COUNT then
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
				print("Activated item : ", code)
			end
			item.Active = true
		end
	end
end

-- update "toggle" item depending on memory state
function updateToggleItemFromByte(segment, code, address)
    local item = Tracker:FindObjectForCode(code)
	
	print(code)
	
    if item then
        local value = ReadU8(segment, address)
        if value > 0 then
            item.Active = true
        else
            item.Active = false
        end
    end
end

-- update "toggle" from flag in address (case of multiple flags on same address)
function updateToggleItemFromByteAndFlag(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)

        local flagTest = value & flag

        if flagTest ~= 0 then
            item.Active = true
        else
            item.Active = false
        end
    end
end

function updatePsychoDashFromByteAndFlag(segment, address, flag)
    local item = Tracker:FindObjectForCode("psycho_dash")
	
    if item then
		local value = ReadU8(segment, address)
	
		local flagTest = value & flag
		
		if flagTest ~= 0 then
            item.CurrentStage = 1
        else
            item.CurrentStage = 0
		end
		
		local upgrade = AutoTracker:ReadU8(0x7e0b16, 0)
		
		local upgradeTest = upgrade & 0x01
		
		if upgradeTest ~= 0 then
			item.CurrentStage = 2
		end
    end
end

function updateDarkFriarFromByteAndFlag(segment, address, flag)
    local item = Tracker:FindObjectForCode("dark_friar")
	
    if item then
		local value = ReadU8(segment, address)
	
		local flagTest = value & flag
		
		if flagTest ~= 0 then
            item.CurrentStage = 1
        else
            item.CurrentStage = 0
		end
		
		local upgrade = AutoTracker:ReadU8(0x7e0b1c, 0)
		
		local upgradeTest = upgrade & 0x02
		
		if upgradeTest ~= 0 then
			item.CurrentStage = 2
		end
    end
end

function updateAbilitiesFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        
		updatePsychoDashFromByteAndFlag(segment, 0x7e0aa2, 0x01)
		updateToggleItemFromByteAndFlag(segment, "psycho_slide", 0x7e0aa2, 0x02)
		updateToggleItemFromByteAndFlag(segment, "spin_dash", 0x7e0aa2, 0x04)
		updateDarkFriarFromByteAndFlag(segment, 0x7e0aa2, 0x10)
		updateToggleItemFromByteAndFlag(segment, "aura_barrier", 0x7e0aa2, 0x20)
		updateToggleItemFromByteAndFlag(segment, "earthquaker", 0x7e0aa2, 0x40)
		
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
		
		-- Hieroglyph Order: check ROM address $39e9a, this is the location of where the correct order is reported in Father's Journal.  Each hieroglyph character is defined with a two-byte tuple:
		-- 1 = #$c0c1
		-- 2 = #$c2c3
		-- 3 = #$c4c5
		-- 4 = #$c6c7
		-- 5 = #$c8c9
		-- 6 = #$cacb
		-- You can find where this is handled programmatically in "iogr_rom.py", around line 1654
		
		-- Oh, do you need to know what the jeweler amounts are?  The seven award amounts are located, respectively, at $8cee0, $8cef1, $8cf02, $8cf13, $8cf24, $8cf35 and $8cf40.
		-- This is handled around line 1744
		
    end
end

function updateMysticStatuesFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	
        updateToggleItemFromByteAndFlag(segment, "mystic_statue_1", 0x7e0a1f, 0x01)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_2", 0x7e0a1f, 0x02)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_3", 0x7e0a1f, 0x04)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_4", 0x7e0a1f, 0x08)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_5", 0x7e0a1f, 0x10)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_6", 0x7e0a1f, 0x20)
		
		--For talking to the teacher
		-- the first address of the teacher's text is $48aa8, so if you're able to track when that ROM address is read, that means the player has talked to the teacher.  (Line 1912)
		
		-- Mystic Statues Required: Check the following ROM addresses for the proper values to know which ones are required:
		-- Statue 1: $8dd19 = #$f8 (or != #$10)
		-- Statue 2: $8dd1f = #$f9 (or != #$10)
		-- Statue 3: $8dd25 = #$fa (or != #$10)
		-- Statue 4: $8dd2b  = #$fb (or != #$10)
		-- Statue 5: $8dd31 = #$fc (or != #$10)
		-- Statue 6: $8dd37 = #$fd (or != #$10)

		-- Line 1817
		
    end
end

function updateKaraFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	
        updateToggleItemFromByteAndFlag(segment, "save_kara2", 0x7e0a11, 0x04)
		
		-- Kara Location: Probably the easiest is to look at the text code for Lance's Letter.  So, look at $39520 -- this is the third character in the location, which is unique for each.  Kara's location can be inferred based on the value found there:
		-- Edward's: #$a7
		-- Diamond Mine: #$80
		-- Angel: #$86
		-- Mt. Kress: #$2a
		-- Ankor Wat: #$8a
		-- Line 1937
		
    end
end

ScriptHost:AddMemoryWatch("IoG Item Data", 0x7e0ab0, 0x16, updateItemsFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Ability Data", 0x7e0aa2, 0x01, updateAbilitiesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Mystic Statue Data", 0x7e0a1f, 0x01, updateMysticStatuesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Kara Data", 0x7e0a11, 0x01, updateKaraFromMemorySegment)

-- Do you have a plan to handle ROMs with headers/offsets?  You could check for the rando code location.  With this method, the ROM offset could be found by searching the ROM for the bit string "52 41 4E 44 4F 90 43 4F 44 45 90" and subtracting #$1da4c (which is where it should show up in an unheadered ROM).
-- Line 80