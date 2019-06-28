--  Load configuration options up front
ScriptHost:LoadScript("scripts/settings.lua")

-- Progression items
Tracker:AddItems("items/items.json")
-- Characters' abilities
Tracker:AddItems("items/abilities.json")
-- Adventure's Objectives
Tracker:AddItems("items/objectives.json")
-- Dark Spaces
Tracker:AddItems("items/dark_spaces.json")
-- Labels (not used for now)
Tracker:AddItems("items/labels.json")

-- World maps
Tracker:AddMaps("maps/maps.json")
-- Areas maps
Tracker:AddMaps("maps/areas.json")

-- Global logic
Tracker:AddLocations("locations/logic.json")
-- Jeweler's locations
Tracker:AddLocations("locations/jeweler.json")
-- South West Continent
Tracker:AddLocations("locations/south_west/cities.json")
Tracker:AddLocations("locations/south_west/dungeons.json")
Tracker:AddLocations("locations/south_west/area_south_cape.json")
-- South East Continent
Tracker:AddLocations("locations/south_east/cities.json")
Tracker:AddLocations("locations/south_east/dungeons.json")
-- North East Continent
Tracker:AddLocations("locations/north_east/seaside_palace.json")
Tracker:AddLocations("locations/north_east/cities.json")
Tracker:AddLocations("locations/north_east/dungeons.json")
-- North Continent
Tracker:AddLocations("locations/north/cities.json")
Tracker:AddLocations("locations/north/dungeons.json")
-- North West Continent
Tracker:AddLocations("locations/north_west/cities.json")
Tracker:AddLocations("locations/north_west/dungeons.json")
-- Babel
Tracker:AddLocations("locations/babel/dungeons.json")

-- Options/Settings
Tracker:AddItems("layouts/options.json")
-- Settings grid
Tracker:AddLayouts("layouts/options_grid.json")
-- Layout
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/standard_broadcast.json")
