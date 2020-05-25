--[[
	   Name : autotracking.lua
Description : Program to track automatically items obtained and used during an IoG:R seed
	Authors : Apokalysme, Neomatamune
	Version : 3.0.0
Last Change : 23/04/2020

   Features :
    * Item AutoTracking : (Apokalysme)
		- Items obtained and used
		- Red Jewels
		- Mystic Statues
		- Kara's Paint location
		- Work after a crash or reset of EmoTracker (except for Herbs)
	* Stats AutoTracking : (Apokalysme/Neomatamune)
		- Hit Points
		- Attack
		- Defense
--]]

-- Configuration --------------------------------------
AUTOTRACKER_ENABLE_DEBUG_LOGGING = false
AUTOTRACKER_ENABLE_INVENTORY_DEBUG = false
AUTOTRACKER_ENABLE_ITEMS_DEBUG = false
AUTOTRACKER_ENABLE_COUNTS_DEBUG = false
AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG = false
AUTOTRACKER_ENABLE_OBJECTIVES_DEBUG = false
AUTOTRACKER_ENABLE_ABILITIES_DEBUG = false
AUTOTRACKER_ENABLE_STATS_DEBUG = false
-------------------------------------------------------

-- Settings display -----------------------------------
print("")
print("Active Auto-Tracker Configuration")
print("---------------------------------------------------------------------")
print("Enable Item Tracking:        ", AUTOTRACKER_ENABLE_ITEM_TRACKING)
print("---------------------------------------------------------------------")
print("Enable Debug Logging:        ", AUTOTRACKER_ENABLE_DEBUG_LOGGING)
if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
	print("  - Enable Inventory Debug:        ", AUTOTRACKER_ENABLE_INVENTORY_DEBUG)
	print("  - Enable Unique Items Debug:        ", AUTOTRACKER_ENABLE_ITEMS_DEBUG)
	print("  - Enable Item Counts Debug:        ", AUTOTRACKER_ENABLE_COUNTS_DEBUG)
	print("  - Enable Hieroglyphs Debug:        ", AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG)
	print("  - Enable Objectives Debug:        ", AUTOTRACKER_ENABLE_OBJECTIVES_DEBUG)
	print("  - Enable Abilities Debug:        ", AUTOTRACKER_ENABLE_ABILITIES_DEBUG)
	print("  - Enable Stats Debug:            ", AUTOTRACKER_ENABLE_STATS_DEBUG)
end
print("---------------------------------------------------------------------")
print("")
-------------------------------------------------------

--[[
	SUMMARY :
	 - GLOBAL VARIABLES
	 - FUNCTIONS
	 - WATCH
	 - MAIN
--]]

-- GLOBAL VARIABLES -----------------------------------

-- Memory Cache 
U8_READ_CACHE = 0
U8_READ_CACHE_ADDRESS = 0

U16_READ_CACHE = 0
U16_READ_CACHE_ADDRESS = 0

-- Items table
-- each item has an unique value in inventory
ITEM_TABLE = {
	[2] = "prison_key",
	[3] = "inca_statue_a", [4] = "inca_statue_b",
	[7] = "diamond_block",
	[8] = "melody_wind",
	[9] = "melody_lola",
	[10] = "large_roast",
	[11] = "mine_key_a", [12] = "mine_key_b",
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
	[36] = "aura",
	[37] = "letter_lola",
	[38] = "journal",
	[39] = "crystal_ring",
	[40] = "apple",
	[46] = "",
	[47] = ""
}

-- Inventory variables
-- Item count
INVENTORY_COUNT = 0

-- Inventory Table
--  * first value is quantity gotten
--  * second value is quantity used
-- table is used this way :
--  * INVENTORY_TABLE[item][1]
--  * INVENTORY_TABLE[item][2]
INVENTORY_TABLE = {}

INVENTORY_TABLE["prison_key"] = {0 , 0}
INVENTORY_TABLE["inca_statue_a"] = {0 , 0}
INVENTORY_TABLE["inca_statue_b"] = {0 , 0}
INVENTORY_TABLE["herb"] = {0 , 0}
INVENTORY_TABLE["diamond_block"] = {0 , 0}
INVENTORY_TABLE["melody_wind"] = {0 , 0}
INVENTORY_TABLE["melody_lola"] = {0 , 0}
INVENTORY_TABLE["large_roast"] = {0 , 0}
INVENTORY_TABLE["mine_key_a"] = {0 , 0}
INVENTORY_TABLE["mine_key_b"] = {0 , 0}
INVENTORY_TABLE["melody_memory"] = {0 , 0}
INVENTORY_TABLE["crystal_ball"] = {0 , 0}
INVENTORY_TABLE["elevator_key"] = {0 , 0}
INVENTORY_TABLE["mu_key"] = {0 , 0}
INVENTORY_TABLE["purity_stone"] = {0 , 0}
INVENTORY_TABLE["hope_statue"] =  {0 , 0}
INVENTORY_TABLE["rama_statue"] = {0 , 0}
INVENTORY_TABLE["magic_dust"] = {0 , 0}
INVENTORY_TABLE["letter_lance"] = {0 , 0}
INVENTORY_TABLE["necklace"] = {0 , 0}
INVENTORY_TABLE["will"] = {0 , 0}
INVENTORY_TABLE["teapot"] = {0 , 0}
INVENTORY_TABLE["mushroom_drop"] = {0 , 0}
INVENTORY_TABLE["black_glasses"] = {0 , 0}
INVENTORY_TABLE["gorgon_flower"] = {0 , 0}
INVENTORY_TABLE["hieroglyph_count"] = {0 , 0}
INVENTORY_TABLE["aura"] = {0 , 0}
INVENTORY_TABLE["letter_lola"] = {0 , 0}
INVENTORY_TABLE["journal"] = {0 , 0}
INVENTORY_TABLE["crystal_ring"] = {0 , 0}
INVENTORY_TABLE["apple"] = {0 , 0}

--[[
	Kara's paint location
	Address $0x039523
	 - Edward's : #$a7
   Diamond Mine : #$80
		  Angel : #$86
	  Mt. Kress : #$2a
	  Ankor Wat : #$8a
--]]
KARA_LOCATION = 0

-- Kara's location mark state
KARA_SET = 0

-- Mystic statues
MYSTIC_STATUE_NEEDED = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0 }
-- Mystic statues check state
MYSTIC_STATUE_CHECK = 0
-- Mystic statues mark state
MYSTIC_STATUE_SET = 0

-- Hieroglyphs detail
-- Hieroglyphs check state
HIEROGLYPHS_CHECK = 0

-- Hieroglyphs combination check state
HIEROGLYPHS_COMBINATION_SET = 0
-- Hieroglyphs combination
HIEROGLYPHS_COMBINATION = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0 }

HIEROGLYPHS_PLACED = 0

-- Ability table
--  * first value is for ability obtained or not
--  * second value is for ability upgraded or not
-- table is used this way :
--  * ABILITY[ability][1]
--  * ABILITY[ability][2]
ABILITY = {}

ABILITY["psycho_dash"] = {0 , 0}
ABILITY["psycho_slide"] = {0 , 0}
ABILITY["spin_dash"] = {0 , 0}
ABILITY["dark_friar"] = {0 , 0}
ABILITY["aura_barrier"] = {0 , 0}
ABILITY["earthquaker"] = {0 , 0}

----------------------------------- GLOBAL VARIABLES --

-- FUNCTIONS ------------------------------------------

--[[
	Function : autotracker_started()
 Description : Invoked when the auto-tracker is activated/connected
   Arguments : <none>
--]]
function autotracker_started()
end

--[[
	Function : InvalidateReadCaches()
 Description : Reset cache addresses
   Arguments : <none>
--]]
function InvalidateReadCaches()
    U8_READ_CACHE_ADDRESS = 0
    U16_READ_CACHE_ADDRESS = 0
end

--[[
	Function : ReadU8()
 Description : Read an address in memory segment (Unsigned Int 8 bits)
   Arguments : segment, address
--]]
function ReadU8(segment, address)
    if U8_READ_CACHE_ADDRESS ~= address then
		-- Read value
        U8_READ_CACHE = segment:ReadUInt8(address)
		-- Save address
        U8_READ_CACHE_ADDRESS = address
    end

    return U8_READ_CACHE
end

--[[
	Function : ReadU16()
 Description : Read an address in memory segment (Unsigned Int 16 bits)
   Arguments : segment, address
--]]
function ReadU16(segment, address)
    if U16_READ_CACHE_ADDRESS ~= address then
		-- Read value
        U16_READ_CACHE = segment:ReadUInt16(address)
		-- Save address
        U16_READ_CACHE_ADDRESS = address        
    end

    return U16_READ_CACHE
end

--[[
	Function : isInGame()
 Description : Check if game is running
   Arguments : <none>
--]]
function isInGame()
	-- Read address "0" in "0x7e0061" segment
	-- check if value is greater than "0x01"
    return AutoTracker:ReadU8(0x7e0061, 0) >= 0x01
end

--[[
	Function : lastItemAddedInInventory()
 Description : Check code of the last item added in inventory
   Arguments : <none>
--]]
function lastItemAddedInInventory()
	local value = AutoTracker:ReadU8(0x7e0db8, 0)
	-- Take item name in Item table
	local item = ITEM_TABLE[value]
	
	return item
end

--[[
	Function : inventoryCount()
 Description : Count items in inventory
   Arguments : segment
--]]
function inventoryCount(segment)
	-- inventory 0x7e0ab4 to 0x7e0ac3
	local count = 0
	local herb_count = 0
	local crystal_ball_count = 0
	local hope_statue_count = 0
	local rama_statue_count = 0
	local mushroom_drops_count = 0
	local hieroglyph_count = 0
	
	-- Check each inventory slot
	for i = 0, 15 do
		local value = ReadU8(segment, 0x7e0ab4 + i)

		-- Count all items except Red Jewel, 2 Red Jewels, 3 Red Jewels or Apple
		if value > 1 and value ~= 40 and value ~= 46 and value ~= 47 then count = count + 1 end
		-- update herb count in inventory
		if value == 6 then herb_count = herb_count + 1
		-- update crystal ball count in inventory
		elseif value == 14 then crystal_ball_count = crystal_ball_count + 1
		-- update hope statue count in inventory
		elseif value == 18 then hope_statue_count = hope_statue_count + 1
		-- update rama statue count in inventory
		elseif value == 19 then rama_statue_count = rama_statue_count + 1
		-- update mushroom drops count in inventory
		elseif value == 26 then mushroom_drops_count = mushroom_drops_count + 1
		-- update hieroglyph count in inventory
		elseif value > 29 and value < 36 then hieroglyph_count = hieroglyph_count + 1
		elseif value == 40 then
			INVENTORY_TABLE[ITEM_TABLE[value]][1] = 1
			-- Update Tracker for all basic items
			updateTrackerItems()
		end
	end
	
	return count, herb_count, crystal_ball_count, hope_statue_count, rama_statue_count, mushroom_drops_count, hieroglyph_count
end

--[[
	Function : newItemInInventory()
 Description : Detect new item added in inventory
   Arguments : segment
--]]
function newItemInInventory(segment)
	-- Getting inventory counts
	local count, herb_count, crystal_ball_count, hope_statue_count, rama_statue_count, mushroom_drops_count, hieroglyph_count = inventoryCount(segment)
	
	-- Debug informations about actual and new inventory count
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_INVENTORY_DEBUG then
		print("INVENTORY : actual ", INVENTORY_COUNT, " - new ", count)
	end
	
	-- If there is some change in inventory count
	if count ~= INVENTORY_COUNT then
		-- Update obtained items state
		-- Loop on each inventory slot (16 total)
		for i = 0, 15 do
			local value = ReadU8(segment, 0x7e0ab4 + i)
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_INVENTORY_DEBUG then
				print("Slot : ", i, " - item code : ", value)
			end

			-- Don't manage Hieroglyphs
			if value > 29 and value < 36 then
			-- For each item in inventory which has an entry in ITEM_TABLE, we indicate in INVENTORY_TABLE that this item is gotten
			elseif (value > 0 and ITEM_TABLE[value]) then INVENTORY_TABLE[ITEM_TABLE[value]][1] = 1
			end
		end

		-- Update global inventory count
		INVENTORY_COUNT = count
	end

	-- Update Compact Item Tracker specifics
	updateTrackerCompactItems("mine_key_a", "mine_key_b")
	updateTrackerCompactItems("inca_statue_a", "inca_statue_b")
	updateTrackerCompactItems("letter_lance", "magic_dust")
	updateTrackerCompactItems("melody_lola", "necklace")
	updateTrackerCompactItems("melody_wind", "diamond_block")
	updateTrackerCompactItems("mu_key", "purity_stone")

	-- Check item counts and do Tracker updates if necessary
	checkCountChange(herb_count, "herb")
	checkCountChange(crystal_ball_count, "crystal_ball")
	checkCountChange(hope_statue_count, "hope_statue")
	checkCountChange(rama_statue_count, "rama_statue")
	checkCountChange(mushroom_drops_count, "mushroom_drop")
	checkCountChange(hieroglyph_count, "hieroglyph_count")
	
	-- Update Tracker for all basic items
	updateTrackerItems()
end

--[[
	Function : checkCountChange()
 Description : Check count change for counted items
   Arguments : new_count, code
--]]
function checkCountChange(new_count, code)
	-- If there is some change in count
	if new_count + INVENTORY_TABLE[code][2] ~= INVENTORY_TABLE[code][1] then
		-- Debug informations about actual and new count
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_COUNTS_DEBUG then
			print(code, " count : actual ", INVENTORY_TABLE[code][1], " - new ", new_count, " - used ", INVENTORY_TABLE[code][2])
		end
		-- If there is a new in inventory, add 1
		if new_count + INVENTORY_TABLE[code][2] > INVENTORY_TABLE[code][1] then
			INVENTORY_TABLE[code][1] = new_count + INVENTORY_TABLE[code][2]
			updateTrackerCountedItem(code)
		-- If there is one less, add 1 to used ones
		elseif new_count + INVENTORY_TABLE[code][2] < INVENTORY_TABLE[code][1] then
			INVENTORY_TABLE[code][2] = INVENTORY_TABLE[code][1] - new_count
		end
	end
end

--[[
	Function : updateTrackerCountedItem()
 Description : update count from count in memory
   Arguments : code
--]]
function updateTrackerCountedItem(code)
    local item = Tracker:FindObjectForCode(code)
	-- Getting actual count marked in Tracker
    local actualCount = item.AcquiredCount
	-- Getting new count in memory
    local newCount = INVENTORY_TABLE[code][1]
	
	-- if there is change in herb count, update Tracker
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

--[[
	Function : updateTrackerUsedCountedItem()
 Description : update count from used flags in memory
   Arguments : segment, code, array, max_count
--]]
function updateTrackerUsedCountedItem(segment, code, array, max_count)
    local item = Tracker:FindObjectForCode(code)
	
	if item then
		local count = 0
		local i = 1
		
		-- checking through all addresses in memory for uses for these counted items
		while i <= max_count do
			local value = 0
			local flagTest = 0
		
			value = ReadU8(segment, array[i][1])
			-- Check if concerned flag is set
			flagTest = value & array[i][2]

			if flagTest > 0 then count = count + 1 end
			i = i + 1
		end
	
		-- if used items count is more than tracker has, update Tracker
		if count > 0 then
			-- Debug informations about actual and new count
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_COUNTS_DEBUG then
				print(code, " used count : actual ", INVENTORY_TABLE[code][2], " - new ", count)
			end
			INVENTORY_TABLE[code][2] = count
			if item.AcquiredCount == 0 and INVENTORY_TABLE[code][1] == 0 then
				item.AcquiredCount = count
				INVENTORY_TABLE[code][1] = INVENTORY_TABLE[code][2]
			end
		end
	end
end

--[[
	Function : updateTrackerItems()
 Description : update items on Tracker (basic items)
   Arguments : <none>
--]]
function updateTrackerItems()
	for i = 2, 40 do
		if ITEM_TABLE[i] then
			local code = ITEM_TABLE[i]
			local item = Tracker:FindObjectForCode(code)
			
			if INVENTORY_TABLE[code][1] == 1 and item then
				-- Debug information about new item obtained
				if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_ITEMS_DEBUG and item.Active ~= true then
					print("Item : ", code, " - flag ", INVENTORY_TABLE[code][1])
				end
				item.Active = true
			end
		end
	end
end

--[[
	Function : updateTrackerRedJewels()
 Description : update Red Jewels on Tracker
   Arguments : segment
--]]
function updateTrackerRedJewels(segment)
    local item = Tracker:FindObjectForCode("red_jewel")
	if item then
		-- Getting actual count marked in Tracker
		local actualCount = item.AcquiredCount
		-- Getting new count in memory (BCD format)
		local newCount = tonumber(string.format("%04X", ReadU8(segment, 0x7e0ab0)))
	
		-- Debug informations about actual and new red jewels count
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("RED JEWELS COUNT : actual count ", actualCount, " - new ", newCount)
		end
	
		-- if there is change in red jewel count, update Tracker
		if (newCount - actualCount) > 0 then
			item.AcquiredCount = newCount
			newItemInInventory(segment)
		end
	end
end

--[[
	Function : updateTrackerCompactItems()
 Description : update compact items on Tracker
   Arguments : code1, code2
--]]
function updateTrackerCompactItems(code1, code2)
	compact_code=code1.."_"..code2
	
	local item = Tracker:FindObjectForCode(compact_code)

    if item and item.CurrentStage ~= 2 then
        local value1 = INVENTORY_TABLE[code1][1]
		local value2 = INVENTORY_TABLE[code2][1]
		
		-- if correct flag are ok, update Tracker
        if value1 == 1 and value2 == 1 then
			-- both items are obtained
			item.CurrentStage = 3
		elseif value1 == 1 and value2 == 0 then
			-- only the first item
			item.CurrentStage = 1
		elseif value1 == 0 and value2 == 1 then
			-- only the second item
			item.CurrentStage = 2
        end
    end
end

--[[
	Function : updateTrackerUsedItems()
 Description : Update unique items from memory Switch
   Arguments : segment, code, address, flag
--]]
function updateTrackerUsedItems(segment, code, address, flag)

	local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)

		-- Check if concerned flag is set
        local flagTest = value & flag
		-- Debug information about flag state
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_ITEMS_DEBUG and item.Active ~= true then
			print("Used item : code ", code, " - value : ", value, " - flag : ", flagTest)
		end
		
		-- if correct flag is ok, update Tracker
        if flagTest ~= 0 and INVENTORY_TABLE[code][2] ~= 1 then
			INVENTORY_TABLE[code][1] = 1
			INVENTORY_TABLE[code][2] = 1
            item.Active = true
			if code ~= "letter_lance" and code ~= "magic_dust" and code ~= "crystal_ring" and code ~= "aura" then
				item.CurrentStage = 1
			end
        end
    end
end

--[[
	Function : updateTrackerAbilities()
 Description : update toggle item from flag in address (case of multiple flags on same address)
   Arguments : segment, code, address, flag
--]]
function updateTrackerAbilities(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)

		-- Check if concerned flag is set
        local flagTest = value & flag
		-- Debug information about flag state
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_ABILITIES_DEBUG and ABILITY[code][1] ~= 1 then
			print("Ability : code ", code, " - value ", value, " - flag ", flagTest)
		end
		
		-- if ability is obtained, update Tracker
        if flagTest ~= 0 and ABILITY[code][1] ~= 1 then
			ABILITY[code][1] = 1
            if code == "psycho_dash" or code == "dark_friar" then
				item.CurrentStage = 1
				-- if we already have an upgrade for this ability, update Tracker
				if ABILITY[code][2] == 1 then
					item.CurrentStage = 2
				end
			else item.Active = true
			end
			
			updateTrackerCompactAbilities("will_abilities","psycho_dash","psycho_slide","spin_dash")
			updateTrackerCompactAbilities("freedan_abilities","dark_friar","aura_barrier","earthquaker")
        end
    end
end

--[[
	Function : updateTrackerCompactAbilities()
 Description : update compact abilities on Tracker
   Arguments : code1, code2, code3
--]]
function updateTrackerCompactAbilities(compact_code, code1, code2, code3)
	local item = Tracker:FindObjectForCode(compact_code)

    if item then
        local value1 = ABILITY[code1][1]
		local value2 = ABILITY[code2][1]
		local value3 = ABILITY[code3][1]
		
		-- if correct flag are ok, update Tracker
		-- all abilities are obtained
        if value1 == 1 and value2 == 1 and value3 == 1 then item.CurrentStage = 7
		-- only the first ability
		elseif value1 == 1 and value2 == 0 and value3 == 0 then item.CurrentStage = 1
		-- only the second ability
		elseif value1 == 0 and value2 == 1 and value3 == 0 then item.CurrentStage = 2
		-- only the third ability
		elseif value1 == 0 and value2 == 0 and value3 == 1 then item.CurrentStage = 3
		-- first and second abilities
		elseif value1 == 1 and value2 == 1 and value3 == 0 then item.CurrentStage = 4
		-- first and third abilities
		elseif value1 == 1 and value2 == 0 and value3 == 1 then item.CurrentStage = 5
		-- second and third abilities
		elseif value1 == 0 and value2 == 1 and value3 == 1 then item.CurrentStage = 6
        end
    end
end

--[[
	Function : upgradeTrackerAbilityUpgrades()
 Description : upgrade progressive ability from flag in address
   Arguments : segment, code, address, flag
--]]
function upgradeTrackerAbilityUpgrades(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
	
    if item then
		local value = ReadU8(segment, address)
		local upgradeTest = value & flag
		
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_ABILITIES_DEBUG and ABILITY[code][2] ~= 1 then
			print("Ability Upgrade : code ", code, " - value ", value, " - flag ", upgradeTest)
		end

		if upgradeTest ~= 0 then
			-- if we have this ability, update Tracker
			if ABILITY[code][1] == 1 then
				item.CurrentStage = 2
				ABILITY[code][2] = 1
			-- if we don't have yet, just update ABILITY table
			else ABILITY[code][2] = 1
			end
		end
    end
end

--[[
	Function : updateTrackerObjectives()
 Description : update objectives on Tracker
   Arguments : segment, code, address, flag
--]]
function updateTrackerObjectives(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
	
    if item then
        local value = ReadU8(segment, address)
		-- Check if concerned flag is set
        local flagTest = value & flag
		
		-- Debug information about flag state
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_OBJECTIVES_DEBUG and item.Active ~= true then
			print("Objective : code ", code, " - value ", value, " - flag ", flagTest)
		end
		
		-- if objective is reached, update Tracker
        if flagTest ~= 0 then item.Active = true
        else item.Active = false
        end
    end
end

--[[
	Function : updateTrackerNeededStatues()
 Description : Update Tracker for needed mystic statues
   Arguments : segment, address, flag
--]]
function updateTrackerNeededStatues(segment, address, flag)
	local item1 = Tracker:FindObjectForCode("mystic_statue_1")
	local item2 = Tracker:FindObjectForCode("mystic_statue_2")
	local item3 = Tracker:FindObjectForCode("mystic_statue_3")
	local item4 = Tracker:FindObjectForCode("mystic_statue_4")
	local item5 = Tracker:FindObjectForCode("mystic_statue_5")
	local item6 = Tracker:FindObjectForCode("mystic_statue_6")
	
	if item1 and item2 and item3 and item4 and item5 and item6 then
		local value = ReadU8(segment, address)
		
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_OBJECTIVES_DEBUG then
			print("Needed Statues : ", value)
		end

		-- Update Tracker when player has talked to teacher in South Cape
		local flagTest = value & flag
        if flagTest > 0 and MYSTIC_STATUE_SET == 0 then
            if (MYSTIC_STATUE_NEEDED[1] == 1) then item1.CurrentStage = 1 end
			if (MYSTIC_STATUE_NEEDED[2] == 1) then item2.CurrentStage = 1 end
			if (MYSTIC_STATUE_NEEDED[3] == 1) then item3.CurrentStage = 1 end
			if (MYSTIC_STATUE_NEEDED[4] == 1) then item4.CurrentStage = 1 end
			if (MYSTIC_STATUE_NEEDED[5] == 1) then item5.CurrentStage = 1 end
			if (MYSTIC_STATUE_NEEDED[6] == 1) then item6.CurrentStage = 1 end
			-- Set this variable to not do this check again
			MYSTIC_STATUE_SET = 1
        end
    end
end

--[[
	Function : updateTrackerKaraPlaceFromLetter()
 Description : Update Kara's paint location from letter status
   Arguments : segment, code, address, flag
--]]
function updateTrackerKaraPlaceFromLetter(segment, code, address, flag)
	local item = Tracker:FindObjectForCode(code)
    if item then
		-- Getting Kara's location in ROM address
		KARA_LOCATION = AutoTracker:ReadU8(0x7e0a5e, 0)
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_OBJECTIVES_DEBUG then
			print("Kara from Letter : ", KARA_LOCATION)
		end
		
		local value = ReadU8(segment, address)
		-- Check Lance's letter status (if read or not)
		local flagTest = value & flag

		-- If player read Lance's letter, update Tracker
        if flagTest ~= 0 then
            item.CurrentStage = KARA_LOCATION
			-- Set Kara's mark status to prevent new useless checks
			KARA_SET = 1
        else item.CurrentStage = 0
        end
    end
end

--[[
	Function : updateKaraIndicatorStatusFromRoom()
 Description : Update Kara's paint location by finding it in place
   Arguments : segment, code, address
--]]
function updateKaraIndicatorStatusFromRoom(segment, code, address)
	local item = Tracker:FindObjectForCode(code)
	
	-- Getting Kara's location in ROM address
	KARA_LOCATION = AutoTracker:ReadU8(0x7e0a5e, 0)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_OBJECTIVES_DEBUG then
		print("Kara from Room : ", KARA_LOCATION)
	end
	
	if item then
		local value = ReadU8(segment, address)

		--[[
			Setting Kara's paint location depending on room visited
				- Edward's: #$13
				- Mine: #$47
				- Angel: #$74
				- Kress: #$a9
				- Ankor Wat: #$bf
		--]]
        if value == 19 and KARA_LOCATION == 1 then
            item.CurrentStage = 1
			-- Set Kara's mark status to prevent new useless check
			KARA_SET = 1
        elseif value == 71 and KARA_LOCATION == 2 then
			item.CurrentStage = 2
			-- Set Kara's mark status to prevent new useless check
			KARA_SET = 1
        elseif value == 116 and KARA_LOCATION == 3 then
			item.CurrentStage = 3
			-- Set Kara's mark status to prevent new useless check
			KARA_SET = 1
        elseif value == 169 and KARA_LOCATION == 4 then
			item.CurrentStage = 4
			-- Set Kara's mark status to prevent new useless check
			KARA_SET = 1
        elseif value == 191 and KARA_LOCATION == 5 then
			item.CurrentStage = 5
			-- Set Kara's mark status to prevent new useless check
			KARA_SET = 1
		else
            item.CurrentStage = 0
        end
    end
end

--[[
	Function : updateCombinationFromByteAndFlag()
 Description : Update hieroglyphs combination
   Arguments : segment, address, flag
--]]
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

		-- Update combination on Tracker when player give Father's Journal to Pyramid's guide
        if flagTest ~= 0 then
            itemA.CurrentStage = HIEROGLYPHS_COMBINATION[1] - 1
			itemB.CurrentStage = HIEROGLYPHS_COMBINATION[2] - 1
			itemC.CurrentStage = HIEROGLYPHS_COMBINATION[3] - 1
			itemD.CurrentStage = HIEROGLYPHS_COMBINATION[4] - 1
			itemE.CurrentStage = HIEROGLYPHS_COMBINATION[5] - 1
			itemF.CurrentStage = HIEROGLYPHS_COMBINATION[6] - 1
			
			-- Debug informations about hieroglyphs combination
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
				print("Hieroglyph 1 : ", itemA.CurrentStage) -- 1 - 2
				print("Hieroglyph 2 : ", itemB.CurrentStage) -- 3 - 4
				print("Hieroglyph 3 : ", itemC.CurrentStage) -- 2 - 3
				print("Hieroglyph 4 : ", itemD.CurrentStage) -- 4 - 5
				print("Hieroglyph 5 : ", itemE.CurrentStage) -- 5 - 6
				print("Hieroglyph 6 : ", itemF.CurrentStage) -- 0 - 1
			end
			
			-- Set combination mark status to prevent new useless check
			HIEROGLYPHS_COMBINATION_SET = 1
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

--[[
	Function : updateTrackerHieroglyphSlots()
 Description : Update placed hieroglyphs
   Arguments : segment, address, slot
--]]
function updateTrackerHieroglyphSlots(segment, address, slot)
	local item = { [1] = nil, [2] = nil, [3] = nil, [4] = nil, [5] = nil, [6] = nil }
	
	item[1] = Tracker:FindObjectForCode("hieroglyph_a")
	item[2] = Tracker:FindObjectForCode("hieroglyph_b")
	item[3] = Tracker:FindObjectForCode("hieroglyph_c")
	item[4] = Tracker:FindObjectForCode("hieroglyph_d")
	item[5] = Tracker:FindObjectForCode("hieroglyph_e")
	item[6] = Tracker:FindObjectForCode("hieroglyph_f")

	-- Debug informations about hieroglyphs placement
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
		print("Hieroglyph slot %d : ", slot, item[slot].Active)
	end
	
	if item[1] and item[2] and item[3] and item[4] and item[5] and item[6] then
		-- setting up a loop to check all memory segments
		--   * l is to loop on hieroglyph slot number (l=l+1 for each loop)
		local l = 1
		--   * k is to loop on memory segment, as they are each 2 bytes (k=k+2 for each loop)
		local k = 0
		--   * placed is to count well placed hieroglyphs
		local placed = 0
		--   * used it to count placed hieroglyphs, even if not correctly [not yet implemented]
		-- local used = 0

		while k <= 10 and l <= 6 do
			slot = l
			local value = ReadU16(segment, 0x7e0b28 + k)

			if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
				print("Hieroglyph slot code : ", value)
			end
			
			-- correct intended value is always "slot number - 1"
			if value == slot - 1 then
				item[slot].Active = true
				placed = placed + 1
				-- Debug information about successful placement
				if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
					print("Filled successfully : true")
					print("Value : ", value)
					print("Slot : ", slot - 1)
				end
			-- other values mean that hieroglyph placed is not the right one or no one is placed in this slot
			else
				if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
					print("Filled successfully : false")
					print("Value : ", value)
					print("Slot : ", slot - 1)
				end
			end
			
			-- used = used + 1
			
			k = k + 2
			l = l + 1
		end
		k = 0
		l = 1
		if placed == 6 then
			HIEROGLYPHS_PLACED = 1
			-- in case of crash or tracker restart, this allows to retrieve informations
			INVENTORY_TABLE["hieroglyph_count"][1] = 6
			INVENTORY_TABLE["hieroglyph_count"][2] = 6
			checkCountChange(INVENTORY_TABLE["hieroglyph_count"][1], "hieroglyph_count")
		end
	end
end

--[[
	Function : updateAllSlotFromByte()
 Description : Update placed hieroglyphs
   Arguments : segment, address, slot
--]]
function updateSlotWithJournal(segment, address, slot)
	local item = { [1] = nil, [2] = nil, [3] = nil, [4] = nil, [5] = nil, [6] = nil }
	
	item[1] = Tracker:FindObjectForCode("hieroglyph_a")
	item[2] = Tracker:FindObjectForCode("hieroglyph_b")
	item[3] = Tracker:FindObjectForCode("hieroglyph_c")
	item[4] = Tracker:FindObjectForCode("hieroglyph_d")
	item[5] = Tracker:FindObjectForCode("hieroglyph_e")
	item[6] = Tracker:FindObjectForCode("hieroglyph_f")

	-- Debug informations about hieroglyphs placement
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
		print("Hieroglyph slot %d : ", slot, item[slot].Active)
	end
	
	if item[1] and item[2] and item[3] and item[4] and item[5] and item[6] then
		local i = 0
		local j = 1
		local placed = 0
		while i <= 10 and j <= 6 do
			
			slot = j
			local value = ReadU16(segment, 0x7e0b28 + i)
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
				print("Hieroglyph slot code : ", value)
			end

			if value == slot - 1 then
				item[slot].CurrentStage = HIEROGLYPHS_COMBINATION[slot] - 1
				item[slot].Active = true
				placed = placed + 1
				-- Debug information about successful placement
				if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
					print("Filled successfully : true")
					print("Value : ", value)
					print("Slot : ",slot - 1)
				end
			else
				if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
					print("Filled successfully : false")
					print("Value : ", value)
					print("Slot : ",slot - 1)
				end
			end
			
			i = i + 2
			j = j + 1
		end
		i = 0
		j = 1
		if placed == 6 then
			HIEROGLYPHS_PLACED = 1
			-- in case of crash or tracker restart, this allows to retrieve informations
			INVENTORY_TABLE["hieroglyph_count"][1] = 6
			INVENTORY_TABLE["hieroglyph_count"][2] = 6
			checkCountChange(INVENTORY_TABLE["hieroglyph_count"][1], "hieroglyph_count")
		end
    end
end

--[[
	Function : updateStatsPoints()
 Description : Update specified stats points
   Arguments : address, code
--]]
function updateStatsPoints(address, code)
	if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		-- Update health value
		local item = Tracker:FindObjectForCode(code)
		-- Getting actual count marked in Tracker
		local actualCount = item.AcquiredCount
		-- Getting new count in memory
		local newCount = tonumber(AutoTracker:ReadU8(address, 0))

		-- Debug informations about actual and new hit points
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_STATS_DEBUG then
			print(code, " : actual ", actualCount, " - new : ", newCount)
		end
		
		-- if there is change in stat points, update Tracker
		if (newCount - actualCount) ~= 0 then
			item.AcquiredCount = newCount
		end
	end
end
------------------------------------------ FUNCTIONS --

-- WATCH ----------------------------------------------

--[[
	   Watch : watchItemsFromInventorySegment()
 Description : Watch for memory to update items and red jewels states
   Arguments : segment
--]]
function watchItemsFromInventorySegment(segment)
    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		newItemInInventory(segment)
		updateTrackerRedJewels(segment)
		
		-- Information for the future
		-- The seven jeweler award amounts are located, respectively, at $8cee0, $8cef1, $8cf02, $8cf13, $8cf24, $8cf35 and $8cf40
    end
end

--[[
	   Watch : watchAbilitiesFromMemorySegment()
 Description : Watch for memory to update Abilities states
   Arguments : segment
--]]
function watchAbilitiesFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then        
		updateTrackerAbilities(segment, "psycho_dash", 0x7e0aa2, 0x01)
		updateTrackerAbilities(segment, "psycho_slide", 0x7e0aa2, 0x02)
		updateTrackerAbilities(segment, "spin_dash", 0x7e0aa2, 0x04)
		updateTrackerAbilities(segment, "dark_friar", 0x7e0aa2, 0x10)
		updateTrackerAbilities(segment, "aura_barrier", 0x7e0aa2, 0x20)
		updateTrackerAbilities(segment, "earthquaker", 0x7e0aa2, 0x40)
    end
end

--[[
	   Watch : watchAbilityUpgradesFromMemorySegment()
 Description : Watch for memory to update upgraded Abilities states
   Arguments : segment
--]]
function watchAbilityUpgradesFromMemorySegment(segment)
	if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then        
		upgradeTrackerAbilityUpgrades(segment, "psycho_dash", 0x7e0b16, 0x01)
		upgradeTrackerAbilityUpgrades(segment, "dark_friar", 0x7e0b1c, 0x02)
    end
end

--[[
	   Watch : watchMysticStatuesFromMemorySegment()
 Description : Watch for memory to update mystic statues
   Arguments : segment
--]]
function watchMysticStatuesFromMemorySegment(segment)
    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		if MYSTIC_STATUE_CHECK == 0 then
			local value = AutoTracker:ReadU8(0x7e0a5f, 0)
			-- Checking flags for each statue if needed or not
			if ((value & 0x01) > 0) then MYSTIC_STATUE_NEEDED[1] = 1 end
			if ((value & 0x02) > 0) then MYSTIC_STATUE_NEEDED[2] = 1 end
			if ((value & 0x04) > 0) then MYSTIC_STATUE_NEEDED[3] = 1 end
			if ((value & 0x08) > 0) then MYSTIC_STATUE_NEEDED[4] = 1 end
			if ((value & 0x10) > 0) then MYSTIC_STATUE_NEEDED[5] = 1 end
			if ((value & 0x20) > 0) then MYSTIC_STATUE_NEEDED[6] = 1 end

			-- Debug informations about Needed mystic statues
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_OBJECTIVES_DEBUG then
				print("Mystic Statue 1 needed : ", MYSTIC_STATUE_NEEDED[1])
				print("Mystic Statue 2 needed : ", MYSTIC_STATUE_NEEDED[2])
				print("Mystic Statue 3 needed : ", MYSTIC_STATUE_NEEDED[3])
				print("Mystic Statue 4 needed : ", MYSTIC_STATUE_NEEDED[4])
				print("Mystic Statue 5 needed : ", MYSTIC_STATUE_NEEDED[5])
				print("Mystic Statue 6 needed : ", MYSTIC_STATUE_NEEDED[6])
			end
			
			-- Once checked, this mark is set up to prevent new useless checks
			MYSTIC_STATUE_CHECK = 1
		end

		-- Update Tracker if we obtain any mystic statue
        updateTrackerObjectives(segment, "mystic_statue_1", 0x7e0a1f, 0x01)
		updateTrackerObjectives(segment, "mystic_statue_2", 0x7e0a1f, 0x02)
		updateTrackerObjectives(segment, "mystic_statue_3", 0x7e0a1f, 0x04)
		updateTrackerObjectives(segment, "mystic_statue_4", 0x7e0a1f, 0x08)
		updateTrackerObjectives(segment, "mystic_statue_5", 0x7e0a1f, 0x10)
		updateTrackerObjectives(segment, "mystic_statue_6", 0x7e0a1f, 0x20)
    end
end

--[[
	   Watch : watchKaraFromRoomSegment()
 Description : Watch for room segment memory to update Kara's paint location
   Arguments : segment
--]]
function watchKaraFromRoomSegment(segment)
    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		-- if we don't know yet where is Kara's Paint
		if KARA_SET == 0 then
			-- check if room we are in contains Kara's Paint
			updateKaraIndicatorStatusFromRoom(segment, "save_kara2", 0x7e0644)
			updateKaraIndicatorStatusFromRoom(segment, "kara_place", 0x7e0644)
		end
    end
end

--[[
	   Watch : watchSwitchesFromMemorySegment()
 Description : Watch for in-memory switches to update items, objectives or hieroglyphs states
   Arguments : segment
--]]
function watchSwitchesFromMemorySegment(segment)
    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		-- Switches list for items used
		updateTrackerUsedItems(segment, "prison_key", 0x7e0a04, 0x10)
		updateTrackerUsedItems(segment, "elevator_key", 0x7e0a0d, 0x02)
		updateTrackerUsedItems(segment, "mine_key_a", 0x7e0a0b, 0x08)
		updateTrackerUsedItems(segment, "mine_key_b", 0x7e0a0b, 0x10)
		updateTrackerUsedItems(segment, "mu_key", 0x7e0a27, 0x01)
		
		updateTrackerUsedItems(segment, "melody_lola", 0x7e0a08, 0x01)
		updateTrackerUsedItems(segment, "melody_wind", 0x7e0a22, 0x04)
		updateTrackerUsedItems(segment, "melody_memory", 0x7e0a02, 0x10)
		
		updateTrackerUsedItems(segment, "inca_statue_a", 0x7e0a06, 0x01)
		updateTrackerUsedItems(segment, "inca_statue_b", 0x7e0a06, 0x02)
		
		updateTrackerUsedItems(segment, "will", 0x7e0a03, 0x80)
		updateTrackerUsedItems(segment, "teapot", 0x7e0a05, 0x04)
		updateTrackerUsedItems(segment, "letter_lola", 0x7e0a02, 0x02)
		
		updateTrackerUsedItems(segment, "letter_lance", 0x7e0a11, 0x40)
		updateTrackerUsedItems(segment, "magic_dust", 0x7e0a11, 0x04)
		updateTrackerUsedItems(segment, "crystal_ring", 0x7e0a07, 0x40)
		
		updateTrackerUsedItems(segment, "large_roast", 0x7e0a08, 0x02)
		updateTrackerUsedItems(segment, "diamond_block", 0x7e0a05, 0x80)
		updateTrackerUsedItems(segment, "purity_stone", 0x7e0a0e, 0x01)
		updateTrackerUsedItems(segment, "necklace", 0x7e0a0d, 0x80)
		updateTrackerUsedItems(segment, "apple", 0x7e0a1c, 0x20)
		updateTrackerUsedItems(segment, "black_glasses", 0x7e0a1e, 0x20)
		updateTrackerUsedItems(segment, "gorgon_flower", 0x7e0a1c, 0x40)
		
		updateTrackerUsedItems(segment, "journal", 0x7e0a1d, 0x80)
		
		crystal_ball_add = {}
		crystal_ball_add[1] = { 0x7e0a0c , 0x01 }
		crystal_ball_add[2] = { 0x7e0a0c , 0x02 }
		crystal_ball_add[3] = { 0x7e0a0c , 0x04 }
		crystal_ball_add[4] = { 0x7e0a0c , 0x08 }
		
		hope_statue_add = {}
		hope_statue_add[1] = { 0x7e0a0f , 0x08 }
		hope_statue_add[2] = { 0x7e0a0f , 0x40 }
		
		rama_statue_add = {}
		rama_statue_add[1] = { 0x7e0a10 , 0x01 }
		rama_statue_add[2] = { 0x7e0a10 , 0x02 }
		
		mushroom_drop_add = {}
		mushroom_drop_add[1] = { 0x7e0a2b , 0x02 }
		mushroom_drop_add[2] = { 0x7e0a2b , 0x80 }
		mushroom_drop_add[3] = { 0x7e0a2c , 0x80 }
		
		updateTrackerUsedCountedItem(segment, "crystal_ball", crystal_ball_add, 4)
		updateTrackerUsedCountedItem(segment, "hope_statue", hope_statue_add, 2)
		updateTrackerUsedCountedItem(segment, "rama_statue", rama_statue_add, 2)
		updateTrackerUsedCountedItem(segment, "mushroom_drop", mushroom_drop_add, 3)
		
		-- Information for the future
		-- The seven jeweler award amounts are located, respectively, at $8cee0, $8cef1, $8cf02, $8cf13, $8cf24, $8cf35 and $8cf40
		
		-- Updating Needed mystic statues marks
		if MYSTIC_STATUE_SET == 0 then updateTrackerNeededStatues(segment, 0x7e0a07, 0x01) end
		
		-- Debug informations about hieroglyphs check status
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
			print("Hieroglyphs Check : ", HIEROGLYPHS_CHECK)
		end

		-- Check hieroglyph combination once and for all
		if HIEROGLYPHS_CHECK == 0 then
			HIEROGLYPHS_COMBINATION[1] = AutoTracker:ReadU8(0x7e0a58, 0)
			HIEROGLYPHS_COMBINATION[2] = AutoTracker:ReadU8(0x7e0a59, 0)
			HIEROGLYPHS_COMBINATION[3] = AutoTracker:ReadU8(0x7e0a5a, 0)
			HIEROGLYPHS_COMBINATION[4] = AutoTracker:ReadU8(0x7e0a5b, 0)
			HIEROGLYPHS_COMBINATION[5] = AutoTracker:ReadU8(0x7e0a5c, 0)
			HIEROGLYPHS_COMBINATION[6] = AutoTracker:ReadU8(0x7e0a5d, 0)
			
			-- Debug informations about hieroglyph combination
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
				print("Hieroglyph 1 : ", HIEROGLYPHS_COMBINATION[1])
				print("Hieroglyph 2 : ", HIEROGLYPHS_COMBINATION[2])
				print("Hieroglyph 3 : ", HIEROGLYPHS_COMBINATION[3])
				print("Hieroglyph 4 : ", HIEROGLYPHS_COMBINATION[4])
				print("Hieroglyph 5 : ", HIEROGLYPHS_COMBINATION[5])
				print("Hieroglyph 6 : ", HIEROGLYPHS_COMBINATION[6])
			end
			-- Once checked, this mark is set up to prevent new useless checks
			HIEROGLYPHS_CHECK = 1
		end
		
		-- Debug informations about having marked combination in Tracker
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING and AUTOTRACKER_ENABLE_HIEROGLYPHS_DEBUG then
			print("Hieroglyph Combination Check : ", HIEROGLYPHS_COMBINATION_SET)
		end
		
		-- If hieroglyph combination is not marked on Tracker, check if Father's Journal has been given
		if HIEROGLYPHS_COMBINATION_SET == 0 then updateCombinationFromByteAndFlag(segment, 0x7e0a1d, 0x80) end
		
		-- Update Kara's safety state on Tracker
        if KARA_LOCATION == 1 then updateTrackerObjectives(segment, "kara2_edwards_castle", 0x7e0a11, 0x04)
        elseif KARA_LOCATION == 2 then updateTrackerObjectives(segment, "kara2_diamond_mine", 0x7e0a11, 0x04)
		elseif KARA_LOCATION == 3 then updateTrackerObjectives(segment, "kara2_angel_dungeon", 0x7e0a11, 0x04)
        elseif KARA_LOCATION == 4 then updateTrackerObjectives(segment, "kara2_mount_kress", 0x7e0a11, 0x04)
        elseif KARA_LOCATION == 5 then updateTrackerObjectives(segment, "kara2_ankor_wat", 0x7e0a11, 0x04)
		end
		-- Update in Map Tracker context
		updateTrackerObjectives(segment, "save_kara", 0x7e0a11, 0x04)		

		-- If Kara's paint location is not set :
		if KARA_SET == 0 then
			-- Check what place Lance's Letter gives
			-- For Item Tracker
			updateTrackerKaraPlaceFromLetter(segment, "save_kara2", 0x7e0a11, 0x40)
			-- For Map Tracker
			updateTrackerKaraPlaceFromLetter(segment, "kara_place", 0x7e0a11, 0x40)
		end
    end
end

--[[
	   Watch : watchHieroglyphsFromMemorySegment()
 Description : Watch for memory to update hieroglyph placement
   Arguments : segment
--]]
function watchHieroglyphsFromMemorySegment(segment)
	if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		-- Update only when player has given Father's Journal to Pyramid's guide
		if HIEROGLYPHS_COMBINATION_SET == 1 and HIEROGLYPHS_PLACED ~= 1 then
			updateTrackerHieroglyphSlots(segment, 0x7e0b28, 1)
			updateTrackerHieroglyphSlots(segment, 0x7e0b2a, 2)
			updateTrackerHieroglyphSlots(segment, 0x7e0b2c, 3)
			updateTrackerHieroglyphSlots(segment, 0x7e0b2e, 4)
			updateTrackerHieroglyphSlots(segment, 0x7e0b30, 5)
			updateTrackerHieroglyphSlots(segment, 0x7e0b32, 6)
		elseif INVENTORY_TABLE["journal"][1] == 1 and HIEROGLYPHS_PLACED ~= 1 then
			updateSlotWithJournal(segment, 0x7e0b28, 1)
			updateSlotWithJournal(segment, 0x7e0b2a, 2)
			updateSlotWithJournal(segment, 0x7e0b2c, 3)
			updateSlotWithJournal(segment, 0x7e0b2e, 4)
			updateSlotWithJournal(segment, 0x7e0b30, 5)
			updateSlotWithJournal(segment, 0x7e0b32, 6)
		end
    end
end

--[[
	   Watch : watchStatsFromMemorySegment()
 Description : Watch health address to update value
   Arguments : address
--]]
function watchStatsFromMemorySegment(address)
	if not isInGame() then
		return false
	end

	InvalidateReadCaches()

	if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		updateStatsPoints(0x7e0aca, "hit_points")
		updateStatsPoints(0x7e0ade, "atk_stat")
		updateStatsPoints(0x7e0adc, "def_stat")
	end
end

---------------------------------------------- WATCH --

-- MAIN -----------------------------------------------

---- Items watchers -----------------------------------
ScriptHost:AddMemoryWatch("IoG Inventory Data", 0x7e0ab0, 0x16, watchItemsFromInventorySegment)
---- Abilities watchers -------------------------------
ScriptHost:AddMemoryWatch("IoG Ability Data", 0x7e0aa2, 0x01, watchAbilitiesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Ability Upgrade Data", 0x7e0b16, 0x08, watchAbilityUpgradesFromMemorySegment)
---- Objectives watchers ------------------------------
ScriptHost:AddMemoryWatch("IoG Mystic Statue Data", 0x7e0a1f, 0x01, watchMysticStatuesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Kara's Paint Data", 0x7e0644, 0x01, watchKaraFromRoomSegment)
---- Switches watchers --------------------------------
ScriptHost:AddMemoryWatch("IoG Switches Data", 0x7e0a02, 0x2b, watchSwitchesFromMemorySegment)
---- Hieroglyphs watchers -----------------------------
ScriptHost:AddMemoryWatch("IoG Hieroglyphs Data", 0x7e0b28, 0x20, watchHieroglyphsFromMemorySegment)
---- Stats watchers -----------------------------------
ScriptHost:AddMemoryWatch("IoG Stats Data", 0x7e0aca, 0x14, watchStatsFromMemorySegment)
----------------------------------------------- MAIN --
