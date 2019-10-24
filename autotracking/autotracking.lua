--[[
	   Name : autotracking.lua
Description : Program to track automatically items obtained during an IoG:R seed
	 Author : Apokalysme
	Version : 0.9.0
Last Change : 24/08/2019

   Features :
    * Item AutoTracking :
		- Items obtained (but not their use)
		- Red Jewels
		- Mystic Statues
		- Kara's Paint location
--]]

-- Configuration --------------------------------------
AUTOTRACKER_ENABLE_DEBUG_LOGGING = true
-------------------------------------------------------

-- Settings display -----------------------------------
print("")
print("Active Auto-Tracker Configuration")
print("---------------------------------------------------------------------")
print("Enable Item Tracking:        ", AUTOTRACKER_ENABLE_ITEM_TRACKING)
if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
    print("Enable Debug Logging:        ", "true")
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
	[1] = "",
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
	[40] = "apple",
	[46] = "",
	[47] = ""
}

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

-- Inventory variables
-- Item count
INVENTORY_COUNT = 0
-- Herb count / used
HERB_COUNT = 0
HERB_USED = 0
-- Crystal ball count / used
CRYSTAL_BALL_COUNT = 0
CRYSTAL_BALL_USED = 0
-- Hope statue count / used
HOPE_STATUE_COUNT = 0
HOPE_STATUE_USED = 0
-- Rama statue count / used
RAMA_STATUE_COUNT = 0
RAMA_STATUE_USED = 0
-- Mushroom drops count / used
MUSHROOM_DROPS_COUNT = 0
MUSHROOM_DROPS_USED = 0

-- Mystic statues
MYSTIC_STATUE_NEEDED = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0
}
-- Mystic statues check state
MYSTIC_STATUE_CHECK = 0
-- Mystic statues mark state
MYSTIC_STATUE_SET = 0

-- Hieroglyphs detail
-- Hieroglyphs check state
HIEROGLYPHS_CHECK = 0

-- Journal gotten
JOURNAL_GOTTEN = 0

-- Hieroglyphs combination check state
HIEROGLYPHS_COMBINATION_SET = 0
-- Hieroglyphs combination
HIEROGLYPHS_COMBINATION = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0
}
-- Hieroglyphs gotten
HIEROGLYPHS_GOTTEN = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0
}

-- Ability table
ABILITY = {
	["psycho_dash"] = 0,
	["dark_friar"] = 0
}
-- Ability upgrade table
UPGRADE = {
	["psycho_dash"] = 0,
	["dark_friar"] = 0
}
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
	Function : howManyHieroglyphs()
 Description : Count how many hieroglyphs gotten
   Arguments : <none>
--]]
function howManyHieroglyphs()
	local hieroglyph_count = 0
	
	for i = 1, 6 do
		if HIEROGLYPHS_GOTTEN[i] == 1 then	
			hieroglyph_count = hieroglyph_count + 1
		end
	end
	
	return hieroglyph_count
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
		if value > 1 and value ~= 40 and value ~= 46 and value ~= 47 then
			count = count + 1

		-- If Apple is in inventory, update its state directly
		elseif value == 40 then
			updateToggleItem(ITEM_TABLE[value])
		end

		-- update herb count in inventory
		if value == 6 then
			herb_count = herb_count + 1

		-- update crystal ball count in inventory
		elseif value == 14 then
			crystal_ball_count = crystal_ball_count + 1

		-- update hope statue count in inventory
		elseif value == 18 then
			hope_statue_count = hope_statue_count + 1

		-- update rama statue count in inventory
		elseif value == 19 then
			rama_statue_count = rama_statue_count + 1

		-- update mushroom drops count in inventory
		elseif value == 26 then
			mushroom_drops_count = mushroom_drops_count + 1

		-- update hieroglyph count in inventory
		elseif value == 30 or value == 31 or value == 32 or value == 33 or value == 34 or value == 35 then
			hieroglyph_count = hieroglyph_count + 1
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
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
		print("INVENTORY :")
		print("Actual count : ", INVENTORY_COUNT)
		print("New count : ", count)
	end
	
	-- If there is some change in inventory count
	if count ~= INVENTORY_COUNT then
		-- Update obtained items state
		for i = 0, 15 do
			local value = ReadU8(segment, 0x7e0ab4 + i)
	
			if value == 33 and HIEROGLYPHS_GOTTEN[1] ~= 1 then
				HIEROGLYPHS_GOTTEN[1] = 1
				updateHieroglyphCount()
			elseif value == 35 and HIEROGLYPHS_GOTTEN[2] ~= 1 then
				HIEROGLYPHS_GOTTEN[2] = 1
				updateHieroglyphCount()
			elseif value == 32 and HIEROGLYPHS_GOTTEN[3] ~= 1 then
				HIEROGLYPHS_GOTTEN[3] = 1
				updateHieroglyphCount()
			elseif value == 31 and HIEROGLYPHS_GOTTEN[4] ~= 1 then
				HIEROGLYPHS_GOTTEN[4] = 1
				updateHieroglyphCount()
			elseif value == 30 and HIEROGLYPHS_GOTTEN[5] ~= 1 then
				HIEROGLYPHS_GOTTEN[5] = 1
				updateHieroglyphCount()
			elseif value == 34 and HIEROGLYPHS_GOTTEN[6] ~= 1 then
				HIEROGLYPHS_GOTTEN[6] = 1
				updateHieroglyphCount()
			elseif value == 38 then
				JOURNAL_GOTTEN = 1
				updateToggleItem(ITEM_TABLE[value])
			elseif (value > 0 and ITEM_TABLE[value]) then
				updateToggleItem(ITEM_TABLE[value])
			end
		end

		-- Update global inventory count
		INVENTORY_COUNT = count
	end
	
	-- If there is some change in herb count
	if herb_count + HERB_USED ~= HERB_COUNT then
		-- Debug informations about actual and new herb count
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("HERBS COUNT :")
			print("Actual count : ", HERB_COUNT)
			print("New count : ", herb_count)
			print("HERBS USED : ", HERB_USED)
		end
		-- If there is a new herb in inventory, add 1
		if herb_count + HERB_USED > HERB_COUNT then
			HERB_COUNT = HERB_COUNT + 1
			updateHerbs(segment)
		-- If there is one less herb, add 1 to used ones
		elseif herb_count + HERB_USED < HERB_COUNT then
			HERB_USED = HERB_USED + 1
		end
	end
	
	-- If there is some change in crystal ball count
	if crystal_ball_count + CRYSTAL_BALL_USED ~= CRYSTAL_BALL_COUNT then
		-- Debug informations about actual and new crystal ball count
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("CRYSTAL BALLS COUNT :")
			print("Actual count : ", CRYSTAL_BALL_COUNT)
			print("New count : ", crystal_ball_count)
			print("CRYSTAL BALLS USED : ", CRYSTAL_BALL_USED)
		end
		-- If there is a new crystal ball in inventory, add 1
		if crystal_ball_count + CRYSTAL_BALL_USED > CRYSTAL_BALL_COUNT then
			CRYSTAL_BALL_COUNT = CRYSTAL_BALL_COUNT + 1
			updateCrystalBalls(segment)
		-- If there is one less crystal ball, add 1 to used ones
		elseif crystal_ball_count + CRYSTAL_BALL_USED < CRYSTAL_BALL_COUNT then
			CRYSTAL_BALL_USED = CRYSTAL_BALL_USED + 1
		end
	end
	
	-- If there is some change in hope statue count
	if hope_statue_count + HOPE_STATUE_USED ~= HOPE_STATUE_COUNT then
		-- Debug informations about actual and new hope statue count
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("HOPE STATUES COUNT :")
			print("Actual count : ", HOPE_STATUE_COUNT)
			print("New count : ", hope_statue_count)
			print("HOPE STATUES USED : ", HOPE_STATUE_USED)
		end
		-- If there is a new hope statue in inventory, add 1
		if hope_statue_count + HOPE_STATUE_USED > HOPE_STATUE_COUNT then
			HOPE_STATUE_COUNT = HOPE_STATUE_COUNT + 1
			updateHopeStatues(segment)
		-- If there is one less hope statue, add 1 to used ones
		elseif hope_statue_count + HOPE_STATUE_USED < HOPE_STATUE_COUNT then
			HOPE_STATUE_USED = HOPE_STATUE_USED + 1
		end
	end
	
	-- If there is some change in rama statue count
	if rama_statue_count + RAMA_STATUE_USED ~= RAMA_STATUE_COUNT then
		-- Debug informations about actual and new rama statue count
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("RAMA STATUES COUNT :")
			print("Actual count : ", RAMA_STATUE_COUNT)
			print("New count : ", rama_statue_count)
			print("RAMA STATUES USED : ", RAMA_STATUE_USED)
		end
		-- If there is a new rama statue in inventory, add 1
		if rama_statue_count + RAMA_STATUE_USED > RAMA_STATUE_COUNT then
			RAMA_STATUE_COUNT = RAMA_STATUE_COUNT + 1
			updateRamaStatues(segment)
		-- If there is one less rama statue, add 1 to used ones
		elseif rama_statue_count + RAMA_STATUE_USED < RAMA_STATUE_COUNT then
			RAMA_STATUE_USED = RAMA_STATUE_USED + 1
		end
	end
	
	-- If there is some change in mushroom drops count
	if mushroom_drops_count + MUSHROOM_DROPS_USED ~= MUSHROOM_DROPS_COUNT then
		-- Debug informations about actual and new mushroom drops count
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("MUSHROOM DROPS COUNT :")
			print("Actual count : ", MUSHROOM_DROPS_COUNT)
			print("New count : ", mushroom_drops_count)
			print("MUSHROOM DROPS USED : ", MUSHROOM_DROPS_USED)
		end
		-- If there is a new mushroom drops in inventory, add 1
		if mushroom_drops_count + MUSHROOM_DROPS_USED > MUSHROOM_DROPS_COUNT then
			MUSHROOM_DROPS_COUNT = MUSHROOM_DROPS_COUNT + 1
			updateMushroomDrops(segment)
		-- If there is one less mushroom drops, add 1 to used ones
		elseif mushroom_drops_count + MUSHROOM_DROPS_USED < MUSHROOM_DROPS_COUNT then
			MUSHROOM_DROPS_USED = MUSHROOM_DROPS_USED + 1
		end
	end
end

--[[
	Function : updateRedJewels()
 Description : update Red Jewels count from count in memory
   Arguments : segment
--]]
function updateRedJewels(segment)
    local item = Tracker:FindObjectForCode("red_jewel")
	-- Getting actual count marked in Tracker
    local actualCount = item.AcquiredCount
	-- Getting new count in memory (BCD format)
    local newCount = tonumber(string.format("%04X", ReadU8(segment, 0x7e0ab0)))
	
	-- Debug informations about actual and new red jewels count
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
		print("RED JEWELS COUNT :")
		print("Actual count : ", actualCount)
		print("New count : ", newCount)
	end
	
	-- if there is change in red jewel count, update Tracker
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

--[[
	Function : updateHerbs()
 Description : update herb count from count in memory
   Arguments : segment
--]]
function updateHerbs(segment)
    local item = Tracker:FindObjectForCode("herb")
	-- Getting actual count marked in Tracker
    local actualCount = item.AcquiredCount
	-- Getting new count in memory
    local newCount = HERB_COUNT
	
	-- if there is change in herb count, update Tracker
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

--[[
	Function : updateCrystalBalls()
 Description : update crystal ball count from count in memory
   Arguments : segment
--]]
function updateCrystalBalls(segment)
    local item = Tracker:FindObjectForCode("crystal_ball")
	-- Getting actual count marked in Tracker
    local actualCount = item.AcquiredCount
	-- Getting new count in memory
    local newCount = CRYSTAL_BALL_COUNT
	
	-- if there is change in crystall ball count, update Tracker
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

--[[
	Function : updateHopeStatues()
 Description : update hope statue count from count in memory
   Arguments : segment
--]]
function updateHopeStatues(segment)
    local item = Tracker:FindObjectForCode("hope_statue")
	-- Getting actual count marked in Tracker
    local actualCount = item.AcquiredCount
	-- Getting new count in memory
    local newCount = HOPE_STATUE_COUNT
	
	-- if there is change in hope statue count, update Tracker
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

--[[
	Function : updateRamaStatues()
 Description : update rama statue count from count in memory
   Arguments : segment
--]]
function updateRamaStatues(segment)
    local item = Tracker:FindObjectForCode("rama_statue")
	-- Getting actual count marked in Tracker
    local actualCount = item.AcquiredCount
	-- Getting new count in memory
    local newCount = RAMA_STATUE_COUNT
	
	-- if there is change in rama statue count, update Tracker
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

--[[
	Function : updateMushroomDrops()
 Description : update mushroom drops count from count in memory
   Arguments : segment
--]]
function updateMushroomDrops(segment)
    local item = Tracker:FindObjectForCode("mushroom_drop")
	-- Getting actual count marked in Tracker
    local actualCount = item.AcquiredCount
	-- Getting new count in memory
    local newCount = MUSHROOM_DROPS_COUNT
	
	-- if there is change in mushroom drops count, update Tracker
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

--[[
	Function : updateHieroglyphCount()
 Description : update hieroglyph count from count in memory
   Arguments : segment
--]]
function updateHieroglyphCount(segment)
    local item = Tracker:FindObjectForCode("hieroglyph_count")
	-- Getting actual count marked in Tracker
    local actualCount = item.AcquiredCount
	-- Getting new count in memory
    local newCount = howManyHieroglyphs()
	
	-- if there is change in hieroglyph count, update Tracker
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
	end
end

--[[
	Function : updateToggleItem()
 Description : update toggle item in Tracker
   Arguments : code
--]]
function updateToggleItem(code)
	local item = Tracker:FindObjectForCode(code)
	-- Update Tracker only if this is not red jewel of herb
	if code ~= "red_jewel" and code ~= "herb" then
		if (item and item.Active ~= true) then
			-- Debug information about new item obtained
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
				print("Obtained item : ", code)
			end
			item.Active = true
		end
	end
end

--[[
	Function : updateToggleItemFromByteAndFlag()
 Description : update toggle item from flag in address (case of multiple flags on same address)
   Arguments : segment, code, address, flag
--]]
function updateToggleItemFromByteAndFlag(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)

		-- Check if concerned flag is set
        local flagTest = value & flag
		-- Debug information about flag state
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Toggle code : ", code)
			print("Value : ", value)
			print("Flag Test : ", flagTest)
		end
		
		-- if correct flag is ok, update Tracker
        if flagTest ~= 0 then
            item.Active = true
        else
            item.Active = false
        end
    end
end

--[[
	Function : updateProgressiveAbilityFromByteAndFlag()
 Description : update progressive ability from flag in address
   Arguments : segment, code, address, flag
--]]
function updateProgressiveAbilityFromByteAndFlag(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)

		-- Check if concerned flag is set
        local flagTest = value & flag
		-- Debug information about flag state
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Ability code : ", code)
			print("Value : ", value)
			print("Flag Test : ", flagTest)
		end

		-- if correct flag is ok, update Tracker
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

--[[
	Function : upgradeAbilityFromByteAndFlag()
 Description : upgrade progressive ability from flag in address
   Arguments : segment, code, address, flag
--]]
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
				UPGRADE[code] = 1
			else
				UPGRADE[code] = 1
			end
		end
    end
end

--[[
	Function : updateNeededStatues()
 Description : Update Tracker for needed mystic statues
   Arguments : segment, address, flag
--]]
function updateNeededStatues(segment, address, flag)
	local item1 = Tracker:FindObjectForCode("mystic_statue_1")
	local item2 = Tracker:FindObjectForCode("mystic_statue_2")
	local item3 = Tracker:FindObjectForCode("mystic_statue_3")
	local item4 = Tracker:FindObjectForCode("mystic_statue_4")
	local item5 = Tracker:FindObjectForCode("mystic_statue_5")
	local item6 = Tracker:FindObjectForCode("mystic_statue_6")
	
	if item1 and item2 and item3 and item4 and item5 and item6 then
		local value = ReadU8(segment, address)

		-- Update Tracker when player has talked to teacher in South Cape
		local flagTest = value & flag
        if flagTest > 0 then
            if (MYSTIC_STATUE_NEEDED[1] == 1) then item1.CurrentStage = 1 end
			if (MYSTIC_STATUE_NEEDED[2] == 1) then item2.CurrentStage = 1 end
			if (MYSTIC_STATUE_NEEDED[3] == 1) then item3.CurrentStage = 1 end
			if (MYSTIC_STATUE_NEEDED[4] == 1) then item4.CurrentStage = 1 end
			if (MYSTIC_STATUE_NEEDED[5] == 1) then item5.CurrentStage = 1 end
			if (MYSTIC_STATUE_NEEDED[6] == 1) then item6.CurrentStage = 1 end
			
			MYSTIC_STATUE_SET = 1
        end
    end
end

--[[
	Function : updateKaraIndicatorStatusFromLetter()
 Description : Update Kara's paint location from letter status
   Arguments : segment, code, address, flag
--]]
function updateKaraIndicatorStatusFromLetter(segment, code, address, flag)
	local item = Tracker:FindObjectForCode(code)
    if item then
		-- Getting Kara's location in ROM address
		KARA_LOCATION = AutoTracker:ReadU8(0x7e0a5e, 0)
		
		local value = ReadU8(segment, address)
		-- Check Lance's letter status (if read or not)
		local flagTest = value & flag

		-- If player read Lance's letter, update Tracker
        if flagTest ~= 0 then
            item.CurrentStage = KARA_LOCATION
			-- Set Kara's mark status to prevent new useless check
			KARA_SET = 1
        else
            item.CurrentStage = 0
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
			
			-- Debug informations about hieroglpyhs combination
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
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
	Function : updateSlotFromByte()
 Description : Update placed hieroglyphs
   Arguments : segment, address, slot
--]]
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

	-- Debug informations about hieroglpyhs placement
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
		print("Hieroglyph slot %d : ", slot, item[slot].Active)
	end
	
	if item[1] and item[2] and item[3] and item[4] and item[5] and item[6] then
		local i = 0
		local j = 1
		while i <= 10 and j <= 6 do
			
			slot = j
			local value = ReadU16(segment, 0x7e0b28 + i)
			if value == slot - 1 then
				item[slot].Active = true
				-- Debug information about successful placement
				if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
					print("Filled successfully : true")
					print("Value : ", value)
					print("Slot : ",slot - 1)
				end
			else
				if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
					print("Filled successfully : false")
					print("Value : ", value)
					print("Slot : ",slot - 1)
				end
			end
			
			i = i + 2
			j = j + 1
		end
	end
end

--[[
	Function : updateAllSlotFromByte()
 Description : Update placed hieroglyphs
   Arguments : segment, address, slot
--]]
function updateSlotWithJournal(segment, address, slot)
	
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

	-- Debug informations about hieroglpyhs placement
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
		print("Hieroglyph slot %d : ", slot, item[slot].Active)
	end
	
	if item[1] and item[2] and item[3] and item[4] and item[5] and item[6] then
		local i = 0
		local j = 1
		while i <= 10 and j <= 6 do
			
			slot = j
			local value = ReadU16(segment, 0x7e0b28 + i)

			if value == slot - 1 then
				item[slot].CurrentStage = HIEROGLYPHS_COMBINATION[slot] - 1
				item[slot].Active = true
				-- Debug information about successful placement
				if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
					print("Filled successfully : true")
					print("Value : ", value)
					print("Slot : ",slot - 1)
				end
			else
				if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
					print("Filled successfully : false")
					print("Value : ", value)
					print("Slot : ",slot - 1)
				end
			end
			
			i = i + 2
			j = j + 1
		end
    end
end
------------------------------------------ FUNCTIONS --

-- WATCH ----------------------------------------------
--[[
	   Watch : updateAbilitiesFromMemorySegment()
 Description : Watch for memory to update Abilities states
   Arguments : segment
--]]
function updateAbilitiesFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then        
		updateProgressiveAbilityFromByteAndFlag(segment, "psycho_dash", 0x7e0aa2, 0x01)
		updateToggleItemFromByteAndFlag(segment, "psycho_slide", 0x7e0aa2, 0x02)
		updateToggleItemFromByteAndFlag(segment, "spin_dash", 0x7e0aa2, 0x04)
		updateProgressiveAbilityFromByteAndFlag(segment, "dark_friar", 0x7e0aa2, 0x10)
		updateToggleItemFromByteAndFlag(segment, "aura_barrier", 0x7e0aa2, 0x20)
		updateToggleItemFromByteAndFlag(segment, "earthquaker", 0x7e0aa2, 0x40)
    end
end

--[[
	   Watch : upgradeAbilitiesFromMemorySegment()
 Description : Watch for memory to update upgraded Abilities states
   Arguments : segment
--]]
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

--[[
	   Watch : updateItemsFromMemorySegment()
 Description : Watch for memory to update items and red jewels states
   Arguments : segment
--]]
function updateItemsFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		newItemInInventory(segment)
		updateRedJewels(segment)
		
		-- Information for the future
		-- The seven jeweler award amounts are located, respectively, at $8cee0, $8cef1, $8cf02, $8cf13, $8cf24, $8cf35 and $8cf40
    end
end

--[[
	   Watch : updateMysticStatuesFromMemorySegment()
 Description : Watch for memory to update mystic statues
   Arguments : segment
--]]
function updateMysticStatuesFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		if MYSTIC_STATUE_CHECK == 0 then
			local value = AutoTracker:ReadU8(0x7e0a5f, 0)
			if ((value & 0x01) > 0) then
				MYSTIC_STATUE_NEEDED[1] = 1
			end
			if ((value & 0x02) > 0) then
				MYSTIC_STATUE_NEEDED[2] = 1
			end
			if ((value & 0x04) > 0) then
				MYSTIC_STATUE_NEEDED[3] = 1
			end
			if ((value & 0x08) > 0) then
				MYSTIC_STATUE_NEEDED[4] = 1
			end
			if ((value & 0x10) > 0) then
				MYSTIC_STATUE_NEEDED[5] = 1
			end
			if ((value & 0x20) > 0) then
				MYSTIC_STATUE_NEEDED[6] = 1
			end

			-- Debug informations about Needed mystic statues
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
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

        updateToggleItemFromByteAndFlag(segment, "mystic_statue_1", 0x7e0a1f, 0x01)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_2", 0x7e0a1f, 0x02)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_3", 0x7e0a1f, 0x04)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_4", 0x7e0a1f, 0x08)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_5", 0x7e0a1f, 0x10)
		updateToggleItemFromByteAndFlag(segment, "mystic_statue_6", 0x7e0a1f, 0x20)
    end
end

--[[
	   Watch : updateFromRoomSegment()
 Description : Watch for room segment memory to update Kara's paint location
   Arguments : segment
--]]
function updateFromRoomSegment(segment)
    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		if KARA_SET == 0 then
			updateKaraIndicatorStatusFromRoom(segment,"save_kara2", 0x7e0644)
			updateKaraIndicatorStatusFromRoom(segment,"kara_place", 0x7e0644)
		end
    end
end

--[[
	   Watch : updateHieroglyphsFromMemorySegment()
 Description : Watch for memory to update hieroglyph placement
   Arguments : segment
--]]
function updateHieroglyphsFromMemorySegment(segment)
	if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		-- Update only when player has given Father's Journal to Pyramid's guide
		if HIEROGLYPHS_COMBINATION_SET == 1 then
			updateSlotFromByte(segment, 0x7e0b28, 1)
			updateSlotFromByte(segment, 0x7e0b2a, 2)
			updateSlotFromByte(segment, 0x7e0b2c, 3)
			updateSlotFromByte(segment, 0x7e0b2e, 4)
			updateSlotFromByte(segment, 0x7e0b30, 5)
			updateSlotFromByte(segment, 0x7e0b32, 6)
		elseif JOURNAL_GOTTEN == 1 then
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
	   Watch : updateFromSwitchesSegment()
 Description : Watch for switch segment memory to update many elements
   Arguments : segment
--]]
function updateFromSwitchesSegment(segment)
    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		-- Updating Needed mystic statues marks
		if MYSTIC_STATUE_SET == 0 then
			updateNeededStatues(segment, 0x7e0a07, 0x01)
		end
		
		-- Debug informations about hieroglyphs check status
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
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
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
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
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Hieroglyph Combination Check : ", HIEROGLYPHS_COMBINATION_SET)
		end
		
		-- If hieroglyph combination is not marked on Tracker, check if Father's Journal has been given
		if HIEROGLYPHS_COMBINATION_SET == 0 then
			updateCombinationFromByteAndFlag(segment, 0x7e0a1d, 0x80)
		end
		
		-- Update Kara's safety state on Tracker 
        if KARA_LOCATION == 1 then
            updateToggleItemFromByteAndFlag(segment, "kara2_edwards_castle", 0x7e0a11, 0x04)
        elseif KARA_LOCATION == 2 then
			updateToggleItemFromByteAndFlag(segment, "kara2_diamond_mine", 0x7e0a11, 0x04)
			elseif KARA_LOCATION == 3 then
			updateToggleItemFromByteAndFlag(segment, "kara2_angel_dungeon", 0x7e0a11, 0x04)
        elseif KARA_LOCATION == 4 then
			updateToggleItemFromByteAndFlag(segment, "kara2_mount_kress", 0x7e0a11, 0x04)
        elseif KARA_LOCATION == 5 then
			updateToggleItemFromByteAndFlag(segment, "kara2_ankor_wat", 0x7e0a11, 0x04)
        end
		-- Update in Map Tracker context
		updateToggleItemFromByteAndFlag(segment, "save_kara", 0x7e0a11, 0x04)
		
		if KARA_SET == 0 then
			updateKaraIndicatorStatusFromLetter(segment, "save_kara2", 0x7e0a11, 0x40)
			updateKaraIndicatorStatusFromLetter(segment, "kara_place", 0x7e0a11, 0x40)
		end
	end
end
---------------------------------------------- WATCH --

-- MAIN -----------------------------------------------
ScriptHost:AddMemoryWatch("IoG Item Data", 0x7e0ab0, 0x16, updateItemsFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Ability Data", 0x7e0aa2, 0x01, updateAbilitiesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Ability Upgrade Data", 0x7e0b16, 0x08, upgradeAbilitiesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Mystic Statue Data", 0x7e0a1f, 0x01, updateMysticStatuesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Room Data", 0x7e0644, 0x01, updateFromRoomSegment)
ScriptHost:AddMemoryWatch("IoG Hieroglyphs Data", 0x7e0b28, 0x10, updateHieroglyphsFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Switches Data", 0x7e0a07, 0x20, updateFromSwitchesSegment)
----------------------------------------------- MAIN --