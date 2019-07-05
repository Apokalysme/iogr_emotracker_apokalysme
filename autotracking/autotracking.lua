-- Configuration --------------------------------------
AUTOTRACKER_ENABLE_DEBUG_LOGGING = false
-------------------------------------------------------


-- Settings display
print("")
print("Active Auto-Tracker Configuration")
print("---------------------------------------------------------------------")
print("Enable Item Tracking:        ", AUTOTRACKER_ENABLE_ITEM_TRACKING)
print("Enable Location Tracking:    ", AUTOTRACKER_ENABLE_LOCATION_TRACKING)
if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
    print("Enable Debug Logging:        ", "true")
end
print("---------------------------------------------------------------------")
print("")

function autotracker_started()
    -- Invoked when the auto-tracker is activated/connected
end

-- Initial values
-- Are we on the Moon ?
AUTOTRACKER_IS_ON_THE_MOON = false
-- Have we done post game summary ?
AUTOTRACKER_HAS_DONE_POST_GAME_SUMMARY = false

-- Clean memory read values
U8_READ_CACHE = 0
U8_READ_CACHE_ADDRESS = 0

U16_READ_CACHE = 0
U16_READ_CACHE_ADDRESS = 0


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

-- Update InGame Status by reading memory segment
function updateInGameStatusFromMemorySegment(segment)

	-- set up "0x7e0010" memory segment
    local mainModuleIdx = segment:ReadUInt8(0x7e0010)

	-- save last state
    local wasOnTheMoon = AUTOTRACKER_IS_ON_THE_MOON
	-- check if player is on the moon
    AUTOTRACKER_IS_IN_TRIFORCE_ROOM = (mainModuleIdx == 0x19 or mainModuleIdx == 0x1a)

	-- if player is now in Triforce Room and was not before
    if AUTOTRACKER_IS_ON_THE_MOON and not wasOnTheMoon then
		-- take statistics in "0x7ef420" segment at "0x46" address
        ScriptHost:AddMemoryWatch("IoG Statistics", 0x7ef420, 0x46, updateStatisticsFromMemorySegment)
    end

	-- if Debug mode enabled
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
		-- track current room information
        if mainModuleIdx > 0x05 then
            print("Current Room Index: ", segment:ReadUInt16(0x7e00a0))
            print("Current OW   Index: ", segment:ReadUInt16(0x7e008a))
        end
        return false
    end

    return true
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

function updateSectionChestCountFromOverworldIndexAndFlag(segment, locationRef, index, callback)
    updateSectionChestCountFromByteAndFlag(segment, locationRef, 0x7ef280 + index, 0x40, callback)
end

-- update chest state from memory
function updateSectionChestCountFromRoomSlotList(segment, locationRef, roomSlots, callback)
    local location = Tracker:FindObjectForCode(locationRef)
    if location then
        -- Do not auto-track this the user has manually modified it
        if location.Owner.ModifiedByUser then
            return
        end

        local clearedCount = 0
        for i,slot in ipairs(roomSlots) do
            local roomData = ReadU16(segment, 0x7ef000 + (slot[1] * 2))

            if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
                print(locationRef, roomData, 1 << slot[2])
            end
                
            if (roomData & (1 << slot[2])) ~= 0 then
                clearedCount = clearedCount + 1
            end
        end

        location.AvailableChestCount = location.ChestCount - clearedCount

        if callback then
            callback(clearedCount > 0)
        end
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

function updateOverworldEventsFromMemorySegment(segment)
    
    if not isInGame() then
        return false
    end

    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        return true
    end    

    InvalidateReadCaches()

    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Spectacle Rock/Up On Top",              3)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Floating Island/Island",                5)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Race Game/Take This Trash",             40)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Grove Digging Spot/Hidden Treasure",    42)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Desert Ledge/Ledge",                    48)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Lake Hylia Island/Island",              53)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Dam/Outside",                           59)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Bumper Cave/Ledge",                     74)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Pyramid Ledge/Ledge",                   91)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Digging Game/Dig For Treasure",         104)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Master Sword Pedestal/Pedestal",        128)    
    updateSectionChestCountFromOverworldIndexAndFlag(segment, "@Zora Area/Ledge",                       129)    
end

function updateRoomsFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        updateToggleFromRoomSlot(segment, "mystic_statue_1", { 2591, 11 })
        updateToggleFromRoomSlot(segment, "mystic_statue_2", { 2591, 11 })
        updateToggleFromRoomSlot(segment, "mystic_statue_3", { 2591, 11 })
        updateToggleFromRoomSlot(segment, "mystic_statue_4", { 2591, 11 })
        updateToggleFromRoomSlot(segment, "mystic_statue_5", { 2591, 11 })
        updateToggleFromRoomSlot(segment, "mystic_statue_6", { 2591, 11 })
    end

    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        return true
    end

    updateSectionChestCountFromRoomSlotList(segment, "@Link's House/By The Door", { { 0, 10 } })
    updateSectionChestCountFromRoomSlotList(segment, "@The Well/Cave", { { 47, 5 }, { 47, 6 }, { 47, 7 }, { 47, 8 } })
    updateSectionChestCountFromRoomSlotList(segment, "@The Well/Bombable Wall", { { 47, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Hookshot Cave/Bonkable Chest", { { 60, 7 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Hookshot Cave/Back", { { 60, 4 }, { 60, 5 }, { 60, 6 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Castle Secret Entrance/Hallway", { { 85, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Lost Woods/Forest Hideout", { { 225, 9 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Lumberjack Cave/Cave", { { 226, 9 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Spectacle Rock/Cave", { { 234, 10 } })        
    updateSectionChestCountFromRoomSlotList(segment, "@Paradox Cave/Top", { { 239, 4 }, { 239, 5 }, { 239, 6 }, { 239, 7 }, { 239, 8 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Super-Bunny Cave/Cave", { { 248, 4 }, { 248, 5 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Spiral Cave/Cave", { { 254, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Paradox Cave/Bottom", { { 255, 4 }, { 255, 5 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Tavern/Back Room", { { 259, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Link's House/By The Door", { { 260, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Sahasrala's Hut/Back Room", { { 261, 4 }, { 261, 5 }, { 261, 6 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Bombable Shack/Downstairs", { { 262, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Treasure Game/Prize", { { 262, 10 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Chicken House/Bombable Wall", { { 264, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Aginah's Cave/Cave", { { 266, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Dam/Inside", { { 267, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Mimic Cave/Cave", { { 268, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Mire Shack/Shack", { { 269, 4 }, { 269, 5 } })
    updateSectionChestCountFromRoomSlotList(segment, "@King's Tomb/The Crypt", { { 275, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Waterfall Fairy/Waterfall Cave", { { 276, 4 }, { 276, 5 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Fat Fairy/Big Bomb Spot", { { 278, 4 }, { 278, 5 } }, updateBombIndicatorStatus)
    updateSectionChestCountFromRoomSlotList(segment, "@Spike Cave/Cave", { { 279, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Graveyard Ledge/Cave", { { 283, 9 } })
    updateSectionChestCountFromRoomSlotList(segment, "@South of Grove/Circle of Bushes", { { 283, 10 } })
    updateSectionChestCountFromRoomSlotList(segment, "@C-Shaped House/House", { { 284, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Blind's House/Basement", { { 285, 5 }, { 285, 6 }, { 285, 7 }, { 285, 8 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Blind's House/Bombable Wall", { { 285, 4 } })   
    updateSectionChestCountFromRoomSlotList(segment, "@Hype Cave/Cave", { { 286, 4 }, { 286, 5 }, { 286, 6 }, { 286, 7 }, { 286, 10 } }) 
    updateSectionChestCountFromRoomSlotList(segment, "@Ice Rod Cave/Cave", { { 288, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Mini Moldorm Cave/Cave", { { 291, 4 }, { 291, 5 }, { 291, 6 }, { 291, 7 }, { 291, 10 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Bonk Rocks/Cave", { { 292, 4 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Checkerboard Cave/Cave", { { 294, 9 } })
    updateSectionChestCountFromRoomSlotList(segment, "@Hammer Pegs/Cave", { { 295, 10 } })

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

function updateHeartPiecesFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        updateConsumableItemFromByte(segment, "heartpiece", 0x7ef448)
    end
end

function updateHeartContainersFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then

        local pieces = Tracker:FindObjectForCode("heartpiece")
        local containers = Tracker:FindObjectForCode("heartcontainer")

        if pieces and containers then
            
            local maxHealth = (ReadU8(segment, 0x7ef36c) // 8) - 3
            
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
                print("Pieces: ", pieces.AcquiredCount)
                print("Max Health: ", maxHealth)
            end

            containers.AcquiredCount = maxHealth - (pieces.AcquiredCount // 4)
        end
    end
end

AUTOTRACKER_STATS_MARKDOWN_FORMAT = [===[
### Post-Game Summary

Stat | Value
--|-
**Collection Rate** | %d/216
**Deaths** | %d
**Bonks** | %d
**Total Time** | %02d:%02d:%02d.%02d
]===]

function read32BitTimer(segment, baseAddress)
    local timer = 0;
    timer = timer | (ReadU8(segment, baseAddress + 3) << 24)
    timer = timer | (ReadU8(segment, baseAddress + 2) << 16)
    timer = timer | (ReadU8(segment, baseAddress + 1) << 8)
    timer = timer | (ReadU8(segment, baseAddress + 0) << 0)

    local hours = timer // (60 * 60 * 60)
    local minutes = (timer % (60 * 60 * 60)) // (60 * 60)
    local seconds = (timer % (60 * 60)) // (60)
    local frames = timer % 60

    return hours, minutes, seconds, frames
end

function updateStatisticsFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if not AUTOTRACKER_HAS_DONE_POST_GAME_SUMMARY then
        -- Read completion timer
        local hours, minutes, seconds, frames = read32BitTimer(segment, 0x7ef43e)

        local collection_rate = ReadU8(segment, 0x7ef423)
        local deaths = ReadU8(segment, 0x7ef449)
        local bonks = ReadU8(segment, 0x7ef420)

        local markdown = string.format(AUTOTRACKER_STATS_MARKDOWN_FORMAT, collection_rate, deaths, bonks, hours, minutes, seconds, frames)
        ScriptHost:PushMarkdownNotification(NotificationType.Celebration, markdown)
    end

    AUTOTRACKER_HAS_DONE_POST_GAME_SUMMARY = true

    return true
end

-- Run the in-game status check more frequently (every 250ms) to catch save/quit scenarios more effectively
ScriptHost:AddMemoryWatch("LTTP In-Game status", 0x7e0010, 0x90, updateInGameStatusFromMemorySegment, 250)
ScriptHost:AddMemoryWatch("LTTP Item Data", 0x7ef340, 0x90, updateItemsFromMemorySegment)
ScriptHost:AddMemoryWatch("LTTP Room Data", 0x7ef000, 0x250, updateRoomsFromMemorySegment)
ScriptHost:AddMemoryWatch("LTTP Overworld Event Data", 0x7ef280, 0x82, updateOverworldEventsFromMemorySegment)
ScriptHost:AddMemoryWatch("LTTP NPC Item Data", 0x7ef410, 2, updateNPCItemFlagsFromMemorySegment)
ScriptHost:AddMemoryWatch("LTTP Heart Piece Data", 0x7ef448, 1, updateHeartPiecesFromMemorySegment)
ScriptHost:AddMemoryWatch("LTTP Heart Container Data", 0x7ef36c, 1, updateHeartContainersFromMemorySegment)
