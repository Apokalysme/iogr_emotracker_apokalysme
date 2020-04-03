--[[
	   Name : autotracking.lua
Description : Program to track automatically items obtained during an IoG:R seed
	Authors : Apokalysme, Neomatamune
	Version : 3.0.0
Last Change : 14/01/2020

   Features :
    * Item AutoTracking : (Apokalysme)
		- Items obtained (but not their use)
		- Red Jewels
		- Mystic Statues
		- Kara's Paint location
	* Stats AutoTracking : (Neomatamune)
		- Hit Points
		- Attack
		- Defense
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

-- Herb count / used
HERB_COUNT = 0
HERB_USED = 0

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

HIEROGLYPHS_PLACED = 0

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
	Function : updateRedJewels()
 Description : update Red Jewels count from count in memory
   Arguments : segment
--]]
function updateRedJewels(segment, address)
    local item = Tracker:FindObjectForCode("red_jewel")
	-- Getting actual count marked in Tracker
    local actualCount = item.AcquiredCount
	-- Getting new count in memory (BCD format)
    local newCount = tonumber(string.format("%04X", ReadU8(segment, address)))
	
	-- Debug informations about actual and new red jewels count
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
		print("RED JEWELS COUNT :")
		print("Actual count : ", actualCount)
		print("New count : ", newCount)
	end
	
	-- if there is change in red jewel count, update Tracker
	if (newCount - actualCount) > 0 then
		item.AcquiredCount = newCount
		newItemInInventory(segment)
	end
end

--[[
	Function : updateHerbs()
 Description : update herb count from count in memory
   Arguments : segment
--]]
function updateHerbs(segment)
	-- Getting inventory counts
	local herb_count
	
	-- Update obtained items state
	-- Check each inventory slot
	for i = 0, 15 do
		local value = ReadU8(segment, 0x7e0ab4 + i)

		-- update herb count in inventory
		if value == 6 then
			herb_count = herb_count + 1
		end
	end
	
	-- If there is some change in herb count
	if herb_count + HERB_USED ~= HERB_COUNT then
		-- Debug informations about actual and new inventory count
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("HERB COUNT :")
			print("Actual count : ", INVENTORY_COUNT)
			print("New count : ", herb_count)
			print("HERBS USED : ", HERB_USED)
		end
		
		-- If there is a new herb in inventory, add 1
		if herb_count + HERB_USED > HERB_COUNT then
			HERB_COUNT = HERB_COUNT + 1
			
			local item = Tracker:FindObjectForCode("herb")
			if item then
				item.AcquiredCount = HERB_COUNT
			end
		-- If there is one less herb, add 1 to used ones
		elseif herb_count + HERB_USED < HERB_COUNT then
			HERB_USED = HERB_USED + 1
		end
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
	Function : updateItemFromSwitch()
 Description : Update unique items from memory Switch
   Arguments : segment, code, address, flag
--]]
function updateItemFromSwitch(segment, code, address, flag)

	local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)

		-- Check if concerned flag is set
        local flagTest = value & flag
		-- Debug information about flag state
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Item : ", code)
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
	Function : updateUsedItemFromSwitch()
 Description : Update unique items from memory Switch
   Arguments : segment, code, address, flag
--]]
function updateUsedItemFromSwitch(segment, code, address, flag)

	local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)

		-- Check if concerned flag is set
        local flagTest = value & flag
		-- Debug information about flag state
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Used item : ", code)
			print("Value : ", value)
			print("Flag Test : ", flagTest)
		end
		
		-- if correct flag is ok, update Tracker
        if flagTest ~= 0 then
            item.Active = true
			item.CurrentStage = 2
        end
    end
end

--[[
	Function : updateCountedItemFromSwitch()
 Description : Update counted items from memory Switch
   Arguments : segment, code, address, flag
--]]
function updateCountedItemFromSwitch(segment, code, address, flag)
	local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)
		
		local actualCount = item.AcquiredCount
		
		-- Check if concerned flag is set
        local flagTest = value & flag
		-- Debug information about flag state
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Item : ", code)
			print("Value : ", value)
			print("Flag Test : ", flagTest)
		end
		
		-- if correct flag is ok, update Tracker
        if flagTest ~= 0 then
            -- item.Active = true
			item.AcquiredCount = actualCount + 1
        end
    end
end

--[[
	Function : updateCompactItemsFromSwitch()
 Description : Update Inventory table from memory Switch
   Arguments : segment, code1, address1, flag1, code2, address2, flag2
--]]
function updateCompactItemsFromSwitch(segment, code1, address1, flag1, code2, address2, flag2)
	
	compact_code=code1.."_"..code2
	
	local item = Tracker:FindObjectForCode(compact_code)

    if item then
        local value1 = ReadU8(segment, address1)
		local value2 = ReadU8(segment, address2)

		-- Check if concerned flags are set
        local flagTest1 = value1 & flag1
		local flagTest2 = value2 & flag2
		
		-- Debug information about flag states
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Item 1 : ", code1)
			print("Value 1 : ", value1)
			print("Flag Test 1 : ", flagTest1)
			print("Item 2 : ", code2)
			print("Value 2 : ", value2)
			print("Flag Test 2 : ", flagTest2)
		end
		
		-- if correct flag are ok, update Tracker
        if flagTest1 ~= 0 and flagTest2 ~= 0 then
			-- both items are obtained
			item.CurrentStage = 3
		elseif flagTest1 ~= 0 and flagTest2 == 0 then
			-- only the first item
			item.CurrentStage = 1
		elseif flagTest1 == 0 and flagTest2 ~= 0 then
			-- only the second item
			item.CurrentStage = 2
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
	Function : updateCompactAbilities()
 Description : Update compact abilities on Tracker
   Arguments : segment, code, address
--]]
function updateCompactAbilities(segment, code, address, flag1, flag2, flag3)
	local item = Tracker:FindObjectForCode(code)
	
	if item then
		local value = ReadU8(segment, address)
	
		local ability1 = value & flag1
		local ability2 = value & flag2
		local ability3 = value & flag3
		
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Toggle code : ", code)
			print("Value : ", value)
			print("Ability 1 : ", ability1)
			print("Ability 2 : ", ability2)
			print("Ability 3 : ", ability3)
		end

		if ability1 ~= 0 and ability2 ~= 0 and ability3 ~= 0 then
			item.CurrentStage = 7
		elseif ability1 ~= 0 and ability2 == 0 and ability3 == 0 then
			item.CurrentStage = 1
		elseif ability1 == 0 and ability2 ~= 0 and ability3 == 0 then
			item.CurrentStage = 2
		elseif ability1 == 0 and ability2 == 0 and ability3 ~= 0 then
			item.CurrentStage = 3
		elseif ability1 ~= 0 and ability2 ~= 0 and ability3 == 0 then
			item.CurrentStage = 4
		elseif ability1 == 0 and ability2 ~= 0 and ability3 ~= 0 then
			item.CurrentStage = 5
		elseif ability1 ~= 0 and ability2 == 0 and ability3 ~= 0 then
			item.CurrentStage = 6
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
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
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
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print("Kara from Letter : ", KARA_LOCATION)
		end
		
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
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
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
		local k = 0
		local l = 1
		local placed = 0
		while k <= 10 and l <= 6 do
			
			slot = l
			local value = ReadU16(segment, 0x7e0b28 + k)
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
				print("Hieroglyph slot code : ", value)
			end
			
			if value == slot - 1 then
				item[slot].Active = true
				placed = placed + 1
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
			
			k = k + 2
			l = l + 1
		end
		k = 0
		l = 1
		if placed == 6 then HIEROGLYPHS_PLACED = 1 end
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
		local placed = 0
		while i <= 10 and j <= 6 do
			
			slot = j
			local value = ReadU16(segment, 0x7e0b28 + i)
			if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
				print("Hieroglyph slot code : ", value)
			end

			if value == slot - 1 then
				item[slot].CurrentStage = HIEROGLYPHS_COMBINATION[slot] - 1
				item[slot].Active = true
				placed = placed + 1
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
		i = 0
		j = 1
		if placed == 6 then HIEROGLYPHS_PLACED = 1 end
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
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
			print(code, " :")
			print("Actual count : ", actualCount)
			print("New count : ", newCount)
		end
		-- if there is change in hit points, update Tracker
		if (newCount - actualCount) > 0 then
			item.AcquiredCount = newCount
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
		
		updateCompactAbilities(segment, "will_abilities", 0x7e0aa2, 0x01, 0x02, 0x04)
		updateCompactAbilities(segment, "freedan_abilities", 0x7e0aa2, 0x10, 0x20, 0x40)
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
	   Watch : updateItemsFromInventorySegment()
 Description : Watch for memory to update herbs and red jewels states
   Arguments : segment
--]]
function updateItemsFromInventorySegment(segment)
    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		updateRedJewels(segment, 0x7e0ab0)
		updateHerbs(segment)
    end
end

--[[
	   Watch : updateItemsFromMemorySegment()
 Description : Watch for memory to update all items states
   Arguments : segment
--]]
function updateItemsFromMemorySegment(segment)

    if not isInGame() then
        return false
    end

    InvalidateReadCaches()

    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
		-- Switches list for items obtained
		-- updateItemFromSwitch(segment, "prison_key", 0x7e0, 0x)
		-- updateItemFromSwitch(segment, "elevator_key", 0x7e0, 0x)
		updateItemFromSwitch(segment, "mine_key_a", 0x7e0a0b, 0x20)
		-- updateItemFromSwitch(segment, "mine_key_b", 0x7e0, 0x)
		updateItemFromSwitch(segment, "mu_key", 0x7e0a10, 0x20)
		
		updateItemFromSwitch(segment, "melody_lola", 0x7e0a06, 0x20)
		updateItemFromSwitch(segment, "melody_wind", 0x7e0a06, 0x04)
		updateItemFromSwitch(segment, "memory_melody", 0x7e0a0b, 0x40)
		
		updateItemFromSwitch(segment, "inca_statue_a", 0x7e0a05, 0x20)
		updateItemFromSwitch(segment, "inca_statue_b", 0x7e0a09, 0x01)
		
		updateCountedItemFromSwitch(segment, "hope_statue", 0x7e0a0f, 0x80)
		updateCountedItemFromSwitch(segment, "hope_statue", 0x7e0a0f, 0x02)
		-- updateCountedItemFromSwitch(segment, "rama_statue", 0x7e0, 0x)
		-- updateCountedItemFromSwitch(segment, "rama_statue", 0x7e0, 0x)
		
		updateItemFromSwitch(segment, "will", 0x7e0a12, 0x20)
		-- updateItemFromSwitch(segment, "teapot", 0x7e0, 0x)
		-- updateItemFromSwitch(segment, "letter_lola", 0x7e0, 0x)
		
		updateItemFromSwitch(segment, "letter_lance", 0x7e0a12, 0x04)
		-- updateItemFromSwitch(segment, "magic_dust", 0x7e0, 0x)
		updateItemFromSwitch(segment, "aura", 0x7e0a17, 0x20)
		updateItemFromSwitch(segment, "crystal_ring", 0x7e0a1b, 0x10)
		
		updateItemFromSwitch(segment, "roast", 0x7e0a08, 0x40)
		-- updateItemFromSwitch(segment, "diamond_block", 0x7e0, 0x)
		-- updateCountedItemFromSwitch(segment, "crystal_ball", 0x7e0, 0x)
		-- updateItemFromSwitch(segment, "purity_stone", 0x7e0, 0x)
		-- updateItemFromSwitch(segment, "necklace", 0x7e0, 0x)
		-- updateCountedItemFromSwitch(segment, "mushroom_drop", 0x7e0, 0x)
		updateItemFromSwitch(segment, "apple", 0x7e0a13, 0x04)
		updateItemFromSwitch(segment, "black_glasses", 0x7e0a17, 0x04)
		updateItemFromSwitch(segment, "gorgon_flower", 0x7e0a17, 0x40)
		
		updateCountedItemFromSwitch(segment, "hieroglyph_count", 0x7e0a18, 0x80)
		updateCountedItemFromSwitch(segment, "hieroglyph_count", 0x7e0a18, 0x40)
		updateCountedItemFromSwitch(segment, "hieroglyph_count", 0x7e0a18, 0x20)
		updateCountedItemFromSwitch(segment, "hieroglyph_count", 0x7e0a18, 0x10)
		updateCountedItemFromSwitch(segment, "hieroglyph_count", 0x7e0a18, 0x08)
		updateCountedItemFromSwitch(segment, "hieroglyph_count", 0x7e0a18, 0x04)
		-- updateItemFromSwitch(segment, "journal", 0x7e0, 0x)
		
		-- updateCompactItemsFromSwitch(segment, "mine_key_a", 0x7e0a0b, 0x20, "mine_key_b", 0x7e0, 0x)
		updateCompactItemsFromSwitch(segment, "inca_statue_a", 0x7e0a05, 0x20, "inca_statue_b", 0x7e0a09, 0x01)
		-- updateCompactItemsFromSwitch(segment, "letter_lance", 0x7e0a12, 0x04, "magic_dust", 0x7e0, 0x)
		-- updateCompactItemsFromSwitch(segment, "melody_lola", 0x7e0a06, 0x20, "necklace", 0x7e0, 0x)
		-- updateCompactItemsFromSwitch(segment, "melody_wind", 0x7e0a06, 0x04, "diamond_block", 0x7e0, 0x)
		-- updateCompactItemsFromSwitch(segment, "purity_stone", 0x7e0, 0x, "mu_key", 0x7e0a10, 0x20)
		
		-- Switches list for items used
		updateUsedItemFromSwitch(segment, "prison_key", 0x7e0a04, 0x10)
		updateUsedItemFromSwitch(segment, "elevator_key", 0x7e0a0d, 0x02)
		updateUsedItemFromSwitch(segment, "mine_key_a", 0x7e0a0b, 0x08)
		updateUsedItemFromSwitch(segment, "mine_key_b", 0x7e0a0b, 0x10)
		updateUsedItemFromSwitch(segment, "mu_key", 0x7e0a27, 0x01)
		
		updateUsedItemFromSwitch(segment, "melody_lola", 0x7e0a08, 0x01)
		updateUsedItemFromSwitch(segment, "melody_wind", 0x7e0a22, 0x04)
		updateUsedItemFromSwitch(segment, "memory_melody", 0x7e0a02, 0x10)
		
		updateUsedItemFromSwitch(segment, "inca_statue_a", 0x7e0a06, 0x01)
		updateUsedItemFromSwitch(segment, "inca_statue_b", 0x7e0a06, 0x02)
		
		-- updateUsedItemFromSwitch(segment, "will", 0x7e0a12, 0x20)
		updateUsedItemFromSwitch(segment, "teapot", 0x7e0a05, 0x04)
		updateUsedItemFromSwitch(segment, "letter_lola", 0x7e0a02, 0x02)
		
		updateUsedItemFromSwitch(segment, "letter_lance", 0x7e0a11, 0x40)
		updateUsedItemFromSwitch(segment, "magic_dust", 0x7e0a11, 0x04)
		
		updateUsedItemFromSwitch(segment, "roast", 0x7e0a08, 0x02)
		updateUsedItemFromSwitch(segment, "diamond_block", 0x7e0a05, 0x80)
		updateUsedItemFromSwitch(segment, "purity_stone", 0x7e0a0e, 0x01)
		-- updateUsedItemFromSwitch(segment, "necklace", 0x7e0, 0x)
		updateUsedItemFromSwitch(segment, "apple", 0x7e0a1c, 0x10)
		updateUsedItemFromSwitch(segment, "black_glasses", 0x7e0a1e, 0x20)
		updateUsedItemFromSwitch(segment, "gorgon_flower", 0x7e0a19, 0x40)
		
		updateUsedItemFromSwitch(segment, "journal", 0x7e0a1d, 0x80)
		
		-- Information for the future
		-- The seven jeweler award amounts are located, respectively, at $8cee0, $8cef1, $8cf02, $8cf13, $8cf24, $8cf35 and $8cf40
		
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

		-- If Kara's paint location is not set :
		if KARA_SET == 0 then
			-- Check what place Lance's Letter gives
			-- For Item Tracker
			updateKaraIndicatorStatusFromLetter(segment, "save_kara2", 0x7e0a11, 0x40)
			-- For Map Tracker
			updateKaraIndicatorStatusFromLetter(segment, "kara_place", 0x7e0a11, 0x40)
		end
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
		-- Make needed statues check only if not made yet
		if MYSTIC_STATUE_CHECK == 0 then
			-- Checking flags for needed statues
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

		-- Checking if statues are obtained
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
		-- If Kara's paint location is not set :
		if KARA_SET == 0 then
			-- Check if you enter the place where Kara's paint is
			-- For Item Tracker
			updateKaraIndicatorStatusFromRoom(segment,"save_kara2", 0x7e0644)
			-- For Map Tracker
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
		if HIEROGLYPHS_COMBINATION_SET == 1 and HIEROGLYPHS_PLACED ~= 1 then
			updateSlotFromByte(segment, 0x7e0b28, 1)
			updateSlotFromByte(segment, 0x7e0b2a, 2)
			updateSlotFromByte(segment, 0x7e0b2c, 3)
			updateSlotFromByte(segment, 0x7e0b2e, 4)
			updateSlotFromByte(segment, 0x7e0b30, 5)
			updateSlotFromByte(segment, 0x7e0b32, 6)
		elseif JOURNAL_GOTTEN == 1 and HIEROGLYPHS_PLACED ~= 1 then
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
	   Watch : updateHitPoints()
 Description : Watch health address to update value
   Arguments : address
--]]
function updateHitPoints(address)
	if not isInGame() then
			return false
	end

	InvalidateReadCaches()

	updateStatsPoints(address, "hit_points")
end

--[[
	   Watch : updateDefValue()
 Description : Watch Def address to update value
   Arguments : address
--]]
function updateDefValue(address)
	if not isInGame() then
			return false
	end

	InvalidateReadCaches()

	updateStatsPoints(address, "def_stat")
end

--[[
	   Watch : updateAtkValue()
 Description : Watch Atk address to update value
   Arguments : address
--]]
function updateAtkValue(address)
	if not isInGame() then
			return false
	end

	InvalidateReadCaches()

	updateStatsPoints(address, "atk_stat")
end
---------------------------------------------- WATCH --

-- MAIN -----------------------------------------------
ScriptHost:AddMemoryWatch("IoG Inventory Data", 0x7e0ab0, 0x16, updateItemsFromInventorySegment)
ScriptHost:AddMemoryWatch("IoG Item Data", 0x7e0a02, 0x2a, updateItemsFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Ability Data", 0x7e0aa2, 0x01, updateAbilitiesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Ability Upgrade Data", 0x7e0b16, 0x08, upgradeAbilitiesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Mystic Statue Data", 0x7e0a1f, 0x01, updateMysticStatuesFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Room Data", 0x7e0644, 0x01, updateFromRoomSegment)
ScriptHost:AddMemoryWatch("IoG Hieroglyphs Data", 0x7e0b28, 0x20, updateHieroglyphsFromMemorySegment)
ScriptHost:AddMemoryWatch("IoG Hit Points", 0x7e0aca, 0x01, updateHitPoints)
ScriptHost:AddMemoryWatch("IoG Attack", 0x7e0ade, 0x01, updateAtkValue)
ScriptHost:AddMemoryWatch("IoG Defense", 0x7e0adc, 0x01, updateDefValue)
----------------------------------------------- MAIN --