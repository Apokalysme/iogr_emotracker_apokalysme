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


ITEM_TABLE = {
	1 = "red_jewel"
	2 = "prison_key"
	3 = "inca_statue_a"
	4 = "inca_statue_b"
	6 = "herb"
	7 = "diamond_block"
	8 = "melody_wind"
	9 = "melody_lola"
	10 = "large_roast"
	11 = "mine_key_a"
	12 = "mine_key_b"
	13 = "melody_memory"
	14 = "cristal_ball"
	15 = "elevator_key"
	16 = "mu_key"
	17 = "purity_stone"
	18 = "hope_statue"
	19 = "rama_statue"
	20 = "magic_dust"
	22 = "letter_lance"
	23 = "necklace"
	24 = "will"
	25 = "teapot"
	26 = "mushroom_drop"
	28 = "black_glasses"
	29 = "gorgon_flower"
	30 = "hieroglyph_5"
	31 = "hieroglyph_4"
	32 = "hieroglyph_3"
	33 = "hieroglyph_1"
	34 = "hieroglyph_6"
	35 = "hieroglyph_2"
	36 = "aura"
	37 = "letter_lola"
	38 = "journal"
	39 = "crystal_ring"
	40 = "apple"
	41 = "hp_jewel"
	42 = "defense_jewel"
	43 = "strength_jewel"
	44 = "light_jewel"
	45 = "dark_jewel"
	46 = "2_red_jewels"
	47 = "3_red_jewels"
	56 = "???"
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
	-- Read address "0" in "0x7e0010" segment
	-- check if value is greater than "0x05"
    return AutoTracker:ReadU8(0x7e0010, 0) > 0x05
end

function lastItemAddedInInventory()
	local value = ReadU8(segment, 0x7e0db8)
	
	item = whatItemIsIt(value)
	
	return item
end

function inventoryCount()
	
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
        item.CurrentStage = value + (offset or 0)
    end
end

function updateCrystalBalls(segment)
    local item = Tracker:FindObjectForCode("crystal_ball")
    local count = 0
    for i = 0, 3, 1 do
        if ReadU8(segment, 0x7ef35c + i) > 0 then
            count = count + 1
        end
    end
    item.CurrentStage = count
end

function updateHopeStatues(segment)
    local item = Tracker:FindObjectForCode("hope_statue")    
    local count = 0
    for i = 0, 3, 1 do
        if ReadU8(segment, 0x7ef35c + i) > 0 then
            count = count + 1
        end
    end
    item.CurrentStage = count
end

function updateRamaStatues(segment)
    local item = Tracker:FindObjectForCode("rama_statue")    
    local count = 0
    for i = 0, 3, 1 do
        if ReadU8(segment, 0x7ef35c + i) > 0 then
            count = count + 1
        end
    end
    item.CurrentStage = count
end

function updateMushroomDrops(segment)
    local item = Tracker:FindObjectForCode("mushroom_drop")    
    local count = 0
    for i = 0, 3, 1 do
        if ReadU8(segment, 0x7ef35c + i) > 0 then
            count = count + 1
        end
    end
    item.CurrentStage = count
end

function updateHieroglyphs(segment)
    local item = Tracker:FindObjectForCode("hieroglyph_count")    
    local count = 0
    for i = 0, 3, 1 do
        if ReadU8(segment, 0x7ef35c + i) > 0 then
            count = count + 1
        end
    end
    item.CurrentStage = count
end

function updateHerbs(segment)
    local item = Tracker:FindObjectForCode("herb")    
    local count = 0
    for i = 0, 3, 1 do
        if ReadU8(segment, 0x7ef35c + i) > 0 then
            count = count + 1
        end
    end
    item.CurrentStage = count
end

-- OK
function updateRedJewels(segment)
    local item = Tracker:FindObjectForCode("red_jewel")
    local actualCount = item.CurrentStage
    local newCount = ReadU8(segment, 0x7efab0)

	if (newCount - actualCount) > 0 then
		item.CurrentStage = newCount
	end
end

-- update bottles state
function updateBottles(segment)
    local item = Tracker:FindObjectForCode("bottle")    
    local count = 0
    for i = 0, 3, 1 do
        if ReadU8(segment, 0x7ef35c + i) > 0 then
            count = count + 1
        end
    end
    item.CurrentStage = count
end

-- update "toggle" item depending on memory state
function updateToggleItemFromByte(segment, code, address)
    local item = Tracker:FindObjectForCode(code)
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
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(item.Name, code, flag)
        end

        local flagTest = value & flag

        if flagTest ~= 0 then
            item.Active = true
        else
            item.Active = false
        end
    end
end

-- update "toggle" from memory state (mystic statues)
function updateToggleFromRoomSlot(segment, code, slot)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local roomData = ReadU16(segment, 0x7ef000 + slot[1])
        
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(roomData)
        end

        item.Active = (roomData & (1 << slot[2])) ~= 0
    end
end

-- update Heart piece value
function updateConsumableItemFromByte(segment, code, address)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)
        item.AcquiredCount = value
    else
        print("Couldn't find item: ", code)
    end
end

-- update pseudo "progressive" (case of shovel and mushroom, which are associated with flute and powder)
function updatePseudoProgressiveItemFromByteAndFlag(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)
        local flagTest = value & flag

        if flagTest ~= 0 then
            item.CurrentStage = math.max(1, item.CurrentStage)
        else
            item.CurrentStage = 0
        end    
    end
end

-- update chests count
function updateSectionChestCountFromByteAndFlag(segment, locationRef, address, flag, callback)
    local location = Tracker:FindObjectForCode(locationRef)
    if location then
        -- Do not auto-track this the user has manually modified it
        if location.Owner.ModifiedByUser then
            return
        end

        local value = ReadU8(segment, address)
        
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(locationRef, value)
        end

        if (value & flag) ~= 0 then
            location.AvailableChestCount = 0
            if callback then
                callback(true)
            end
        else
            location.AvailableChestCount = location.ChestCount
            if callback then
                callback(false)
            end
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
        print("Couldn't find location", locationRef)
    end
end

function updateNPCItemFlagsFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        return true
    end

    InvalidateReadCaches()

    updateSectionChestCountFromByteAndFlag(segment, "@Old Man/Bring Him Home", 0x7ef410, 0x01)
    updateSectionChestCountFromByteAndFlag(segment, "@Zora Area/King Zora", 0x7ef410, 0x02)
    updateSectionChestCountFromByteAndFlag(segment, "@Sick Kid/By The Bed", 0x7ef410, 0x04)
    updateSectionChestCountFromByteAndFlag(segment, "@Haunted Grove/Stumpy", 0x7ef410, 0x08)
    updateSectionChestCountFromByteAndFlag(segment, "@Sahasrala's Hut/Shabbadoo", 0x7ef410, 0x10)
    updateSectionChestCountFromByteAndFlag(segment, "@Catfish/Ring of Stones", 0x7ef410, 0x20)
    -- 0x40 is unused
    updateSectionChestCountFromByteAndFlag(segment, "@Library/On The Shelf", 0x7ef410, 0x80)

    updateSectionChestCountFromByteAndFlag(segment, "@Ether Tablet/Tablet", 0x7ef411, 0x01)
    updateSectionChestCountFromByteAndFlag(segment, "@Bombos Tablet/Tablet", 0x7ef411, 0x02)
    updateSectionChestCountFromByteAndFlag(segment, "@Dwarven Smiths/Bring Him Home", 0x7ef411, 0x04)
    -- 0x08 is no longer relevant
    updateSectionChestCountFromByteAndFlag(segment, "@Lost Woods/Mushroom Spot", 0x7ef411, 0x10)
    updateSectionChestCountFromByteAndFlag(segment, "@Witch's Hut/Assistant", 0x7ef411, 0x20, updateMushroomStatus)
    -- 0x40 is unused
    updateSectionChestCountFromByteAndFlag(segment, "@Magic Bat/Magic Bowl", 0x7ef411, 0x80, updateBatIndicatorStatus)    

end

function updateItemsFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        
        updateToggleItemFromByte(segment, "melody_lola", 0x7ef342)
        updateToggleItemFromByte(segment, "prison_key", 0x7ef343)
        updateToggleItemFromByte(segment, "large_roast", 0x7ef345)
        updateToggleItemFromByte(segment, "diamond_block", 0x7ef346)
        updateToggleItemFromByte(segment, "melody_wind", 0x7ef347)
        updateToggleItemFromByte(segment, "inca_statue_a", 0x7ef348)
        updateToggleItemFromByte(segment, "inca_statue_b", 0x7ef349)
        updateToggleItemFromByte(segment, "mine_key_a", 0x7ef34a)
        updateToggleItemFromByte(segment, "mine_key_b", 0x7ef34b)
        updateToggleItemFromByte(segment, "elevator_key", 0x7ef34d)
        updateToggleItemFromByte(segment, "melody_memory", 0x7ef34e)
        updateToggleItemFromByte(segment, "purity_stone", 0x7ef350)
        updateToggleItemFromByte(segment, "mu_key", 0x7ef351)
        updateToggleItemFromByte(segment, "magic_dust", 0x7ef352)
        updateToggleItemFromByte(segment, "letter_lance", 0x7ef353)
        updateToggleItemFromByte(segment, "necklace", 0x7ef355)
        updateToggleItemFromByte(segment, "will", 0x7ef356)
        updateToggleItemFromByte(segment, "apple", 0x7ef357)
        updateToggleItemFromByte(segment, "teapot", 0x7ef37b)
		updateToggleItemFromByte(segment, "black_glasses", 0x7ef37b)
		updateToggleItemFromByte(segment, "gorgon_flower", 0x7ef37b)
		updateToggleItemFromByte(segment, "letter_lola", 0x7ef37b)
		updateToggleItemFromByte(segment, "journal", 0x7ef37b)
		updateToggleItemFromByte(segment, "aura", 0x7ef37b)
		updateToggleItemFromByte(segment, "crystal_ring", 0x7ef37b)

		updateToggleItemFromByte(segment, "psycho_dash", 0x7ef37b)
		updateToggleItemFromByte(segment, "psycho_slide", 0x7ef37b)
		updateToggleItemFromByte(segment, "spin_dash", 0x7ef37b)
		updateToggleItemFromByte(segment, "dark_friar", 0x7ef37b)
		updateToggleItemFromByte(segment, "aura_barrier", 0x7ef37b)
		updateToggleItemFromByte(segment, "earthquaker", 0x7ef37b)
		
        updatePseudoProgressiveItemFromByteAndFlag(segment, "mushroom", 0x7ef38c, 0x20)
        updatePseudoProgressiveItemFromByteAndFlag(segment, "shovel", 0x7ef38c, 0x04)

        updateCrystalBalls(segment)
        updateHopeStatues(segment)
		updateRamaStatues(segment)
		updateMushroomDrops(segment)
		updateHieroglyphs(segment)
		updateHerbs(segment)
		updateRedJewels(segment)
    end

    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        return true
    end    

    --  It may seem unintuitive, but these locations are controlled by flags stored adjacent to the item data,
    --  which makes it more efficient to update them here.
    updateSectionChestCountFromByteAndFlag(segment, "@Castle Secret Entrance/Uncle", 0x7ef3c6, 0x01)    
    updateSectionChestCountFromByteAndFlag(segment, "@Hobo/Under The Bridge", 0x7ef3c9, 0x01)
    updateSectionChestCountFromByteAndFlag(segment, "@Bottle Vendor/This Jerk", 0x7ef3c9, 0x02)
    updateSectionChestCountFromByteAndFlag(segment, "@Purple Chest/Show To Gary", 0x7ef3c9, 0x10)

end

ScriptHost:AddMemoryWatch("IoG Item Data", 0x7ef340, 0x90, updateItemsFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG NPC Item Data", 0x7ef410, 2, updateNPCItemFlagsFromMemorySegment)
