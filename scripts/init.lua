--  Load configuration options up front
ScriptHost:LoadScript("scripts/settings.lua")

-- Progression items
Tracker:AddItems("items/items_full.json")
Tracker:AddItems("items/items_compact.json")
-- Characters' abilities
Tracker:AddItems("items/abilities.json")
-- Adventure's Objectives
Tracker:AddItems("items/objectives.json")
-- Dark Spaces
Tracker:AddItems("items/dark_spaces.json")
-- Stats
Tracker:AddItems("items/stats.json")
-- Labels (not used for now)
-- Tracker:AddItems("items/labels.json")

-- World maps
Tracker:AddMaps("maps/maps.json")
-- Areas maps
Tracker:AddMaps("maps/areas.json")

-- Global logic
Tracker:AddLocations("locations/0 - logic/logic_settings.json")
Tracker:AddLocations("locations/0 - logic/logic_switches.json")
Tracker:AddLocations("locations/0 - logic/logic_transitions.json")
Tracker:AddLocations("locations/0 - logic/logic_dungeons.json")
-- Jeweler's locations
Tracker:AddLocations("locations/jeweler.json")
-- South West Continent
Tracker:AddLocations("locations/1 - south_west/south_cape.json")
Tracker:AddLocations("locations/1 - south_west/itoryville.json")
Tracker:AddLocations("locations/1 - south_west/edwards_castle.json")
Tracker:AddLocations("locations/1 - south_west/moon_tribe.json")
Tracker:AddLocations("locations/1 - south_west/gold_ship.json")
Tracker:AddLocations("locations/1 - south_west/edwards_prison.json")
Tracker:AddLocations("locations/1 - south_west/inca_ruins.json")
-- Tracker:AddLocations("locations/1 - south_west/area_south_cape.json")
-- South East Continent
Tracker:AddLocations("locations/2 - south_east/cities.json")
Tracker:AddLocations("locations/2 - south_east/diamond_mine.json")
Tracker:AddLocations("locations/2 - south_east/sky_garden.json")
-- North East Continent
Tracker:AddLocations("locations/3 - north_east/seaside_palace.json")
Tracker:AddLocations("locations/3 - north_east/cities.json")
Tracker:AddLocations("locations/3 - north_east/mu.json")
Tracker:AddLocations("locations/3 - north_east/wind_tunnel.json")
Tracker:AddLocations("locations/3 - north_east/great_wall.json")
-- North Continent
Tracker:AddLocations("locations/4 - north/cities.json")
Tracker:AddLocations("locations/4 - north/mt_temple.json")
Tracker:AddLocations("locations/4 - north/ankor_wat.json")
-- North West Continent
Tracker:AddLocations("locations/5 - north_west/cities.json")
Tracker:AddLocations("locations/5 - north_west/pyramid.json")
-- Babel
Tracker:AddLocations("locations/6 - babel/babel.json")

-- Options/Settings
Tracker:AddItems("layouts/options.json")
-- Settings grid
Tracker:AddLayouts("layouts/options_grid.json")
-- Layout
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/standard_broadcast.json")

if _VERSION == "Lua 5.3" then
    ScriptHost:LoadScript("autotracking/autotracking.lua")
else
    print("Auto-tracker is unsupported by your tracker version")
end