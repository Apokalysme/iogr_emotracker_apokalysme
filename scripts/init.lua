print("-- IoG:R Tracker pack - v3.6.0.0 --")
print("Loaded tracker : ", Tracker.ActiveVariantUID)

--  Load configuration options up front
ScriptHost:LoadScript("scripts/settings.lua")

-- Characters' abilities
Tracker:AddItems("items/abilities.json")
-- Adventure's Objectives
Tracker:AddItems("items/objectives.json")
-- Stats
Tracker:AddItems("items/stats.json")
-- Progression items
Tracker:AddItems("items/items_full.json")

if string.find(Tracker.ActiveVariantUID, "compact") then
	Tracker:AddItems("items/items_compact.json")
elseif string.find(Tracker.ActiveVariantUID, "map") then
		-- Dark Spaces
		Tracker:AddItems("items/dark_spaces.json")
		-- World maps
		Tracker:AddMaps("maps/maps.json")
		-- Areas maps
		-- Tracker:AddMaps("maps/areas.json")

		ScriptHost:LoadScript("scripts/locations.lua")

		-- Global logic
		Tracker:AddLocations("locations/0 - logic/logic_switches.json")
		Tracker:AddLocations("locations/0 - logic/logic_transitions.json")
		Tracker:AddLocations("locations/0 - logic/logic_dungeons.json")
		Tracker:AddLocations("locations/0 - logic/logic_regions.json")
		-- Continents
		Tracker:AddLocations("locations/1 - south_west.json")
		Tracker:AddLocations("locations/2 - south_east.json")
		Tracker:AddLocations("locations/3 - north_east.json")
		Tracker:AddLocations("locations/4 - north.json")
		Tracker:AddLocations("locations/5 - north_west.json")
		Tracker:AddLocations("locations/6 - babel.json")
		Tracker:AddLocations("locations/7 - jeweler.json")

		-- Detailled maps (WIP)
		-- Tracker:AddLocations("locations/area_south_cape.json")

		-- Options/Settings
		Tracker:AddItems("layouts/options.json")
		-- Settings grid
		Tracker:AddLayouts("layouts/options_grid.json")
end

-- Layout
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/standard_broadcast.json")

if _VERSION == "Lua 5.3" then
    ScriptHost:LoadScript("scripts/autotracking.lua")
else
    print("Auto-tracker is unsupported by your tracker version")
end