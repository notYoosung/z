-- Handles biome info for mapgen and choosing a battle background

-- Local namespace
local biomes = {}

-- Import files
local modname = minetest.get_current_modname() or "z"
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

local group = dofile(mod_path .. "/lua/group.lua")

-- Biome groups used for mapgen decorations
biomes.cold = {}
biomes.temperate = {}
biomes.humid = {}
biomes.hot = {}
biomes.villages = {}

-- Used to determine background texture in battles
biomes.backgrounds = {}

-- Add Biome
function biomes.add(biome, background, mapgen)
	biomes.backgrounds[biome] = background
	for i = 1, (mapgen and #mapgen or 0) do
		table.insert(biomes[mapgen[i]], biome)
	end
end

-- Minetest the Game
if minetest.get_modpath("default") then
	biomes.add("cold_desert", "desert", {"cold", "villages"})
	biomes.add("coniferous_forest", "pine", {"cold"})
	biomes.add("coniferous_forest_dunes", "beach", {"cold"})
	biomes.add("deciduous_forest", "forest", {"temperate"})
	biomes.add("deciduous_forest_shore", "beach")
	biomes.add("desert", "desert", {"hot", "villages"})
	biomes.add("grassland", "grassland", {"humid", "temperate", "villages"})
	biomes.add("grassland_dunes", "beach", {"hot", "villages"})
	biomes.add("icesheet", "snowy", {"cold", "villages"})
	biomes.add("rainforest", "forest", {"humid"})
	biomes.add("rainforest_swamp", "forest", {"humid"})
	biomes.add("sandstone_desert", "desert", {"hot"})
	biomes.add("savanna", "grassland", {"hot", "villages"})
	biomes.add("savanna_shore", "beach", {"hot", "villages"})
	biomes.add("snowy_grassland", "snowy", {"cold", "villages"})
	biomes.add("taiga", "snowy", {"cold"})
	biomes.add("tundra", "snowy", {"cold"})
	biomes.add("tundra_beach", "snowy")
	biomes.add("tundra_highland", "snowy", {"cold"})
end

-- Mineclone 2
if minetest.get_modpath("mcl_biomes") then
	biomes.add("BirchForest", "forest", {"temperate"})
	biomes.add("BirchForestM", "forest", {"temperate"})
	biomes.add("ColdTaiga", "snowy", {"cold"})
	biomes.add("ColdTaiga_beach", "snowy", {"cold", "villages"})
	biomes.add("Desert", "desert", {"hot", "villages"})
	biomes.add("ExtremeHills", "grassland", {"temperate",})
	biomes.add("ExtremeHills_beach", "beach", {"temperate", "villages"})
	biomes.add("ExtremeHillsM", "grassland", {"temperate"})
	biomes.add("ExtremeHills+", "grassland", {"temperate"})
	biomes.add("ExtremeHills+_snowtop", "snowy", {"cold"})
	biomes.add("Forest", "forest", {"temperate"})
	biomes.add("FlowerForest", "forest", {"temperate"})
	biomes.add("FlowerForest_beach", "beach", {"temperate", "villages"})
	biomes.add("IcePlains", "snowy", {"cold", "villages"})
	biomes.add("IcePlainsSpikes", "snowy", {"cold", "villages"})
	biomes.add("Jungle", "forest", {"humid"})
	biomes.add("Jungle_shore", "beach", {"humid"})
	biomes.add("JungleM", "forest", {"humid"})
	biomes.add("JungleM_shore", "beach", {"humid"})
	biomes.add("JungleEdge", "forest", {"humid"})
	biomes.add("JungleEdgeM", "forest", {"humid"})
	biomes.add("MangroveSwamp", "forest", {"humid"})
	biomes.add("MegaTaiga", "snowy", {"cold"})
	biomes.add("MegaSpruceTaiga", "snowy", {"cold"})
	biomes.add("Mesa", "rock", {"hot", "villages"})
	biomes.add("Mesa_sandlevel", "desert", {"hot", "villages"})
	biomes.add("MesaBryce", "rock", {"hot", "villages"})
	biomes.add("MesaBryce_sandlevel", "desert", {"hot", "villages"})
	biomes.add("MesaPlateauF", "forest", {"hot"})
	biomes.add("MesaPlateauF_grasstop", "forest", {"hot"})
	biomes.add("MesaPlateauF_sandlevel", "desert", {"hot", "villages"})
	biomes.add("MesaPlateauFM", "forest", {"hot"})
	biomes.add("MesaPlateauFM_grasstop", "forest", {"hot"})
	biomes.add("MesaPlateauFM_sandlevel", "desert", {"hot", "villages"})
	biomes.add("MushroomIsland", "grassland", {"temperate"})
	biomes.add("MushroomIslandShore", "beach", {"humid"})
	biomes.add("Plains", "grassland", {"temperate", "villages"})
	biomes.add("Plains_beach", "beach", {"temperate", "villages"})
	biomes.add("RoofedForest", "pine", {"humid"})
	biomes.add("Savanna", "grassland", {"hot"})
	biomes.add("SavannaM", "grassland", {"hot"})
	biomes.add("StoneBeach", "rock", {"hot", "villages"})
	biomes.add("SunflowerPlains", "grassland", {"temperate", "villages"})
	biomes.add("Swampland", "grassland", {"humid"})
	biomes.add("Swampland_shore", "beach", {"humid"})
	biomes.add("Taiga", "snowy", {"cold"})
	biomes.add("Taiga_beach", "snowy", {"cold", "villages"})
end

-- Farlands Reloaded
if minetest.get_modpath("fl_mapgen") then
	biomes.add("grassland", "grassland", {"temperate"})
	biomes.add("grassland_ocean", "beach", {"humid", "villages"})
	biomes.add("sand", "desert", {"hot", "villages"})
	biomes.add("sand_ocean", "beach", {"hot"})
	biomes.add("desert", "desert", {"hot"})
	biomes.add("desert_ocean", "beach")
	biomes.add("silversand", "desert", {"cold", "villages"})
	biomes.add("silversand_ocean", "beach", {"villages"})
	biomes.add("savannah", "grassland", {"hot"})
	biomes.add("savannah_ocean", "beach")
	biomes.add("taiga", "snowy", {"cold"})
	biomes.add("taiga_ocean", "snowy", {"villages"})
	biomes.add("snowygrassland", "snowy", {"cold"})
	biomes.add("snowygrassland_ocean", {"villages"})
	biomes.add("icy", "snowy", {"cold", "villages"})
	biomes.add("icy_ocean", "snowy", {"villages"})
	biomes.add("tundra", "snowy", {"cold", "villages"})
	biomes.add("tundra_ocean", "snowy", {"villages"})
	biomes.add("rainforest", "forest", {"humid"})
	biomes.add("rainforest_ocean", "beach", {"humid", "villages"})
	biomes.add("deciduousforest", "forest", {"temperate"})
	biomes.add("deciduousforest_ocean", "beach", {"villages"})
	biomes.add("coniferousforest", "pine", {"temperate"})
	biomes.add("coniferousforest_ocean", "beach", {"villages"})
end

-- Exile
if minetest.get_modpath("exile_env_sounds") then
	biomes.add("grassland", "grassland", {"temperate", "villages"})
	biomes.add("upland_grassland", "snowy", {"cold"})
	biomes.add("marshland", "grassland", {"humid"})
	biomes.add("highland", "snowy", {"cold"})
	biomes.add("duneland", "desert", {"villages"})
	biomes.add("woodland", "forest", {"temperate"})
	biomes.add("snowcap", "snowy", {"cold"})
	biomes.add("silty_beach", "rock")
	biomes.add("silty_beach_lower", "rock")
	biomes.add("sandy_beach", "beach", {"hot", "villages"})
	biomes.add("sandy_beach_lower", "beach", {"hot", "villages"})
	biomes.add("gravel_beach", "rock", {"villages"})
	biomes.add("gravel_beach_lower", "rock", {"villages"})
	biomes.add("grassland_dry", "grassland", {"temperate", "villages"})
	biomes.add("grassland_wet", "grassland", {"humid"})
	biomes.add("grassland_barren", "grassland", {"hot"})
	biomes.add("upland_grassland_dry", "grassland", {"cold"})
	biomes.add("barrenland", "rock", {"hot", "villages"})
	biomes.add("lavaland", "rock", {"hot"})
	biomes.add("hardpan_marshland", "rock", {"humid"})
	biomes.add("woodland_wet", "forest", {"humid"})
	biomes.add("woodland_dry", "forest", {"temperate"})
	biomes.add("upland_woodland_dry", "snowy", {"cold"})
	biomes.add("dry_highland_scree", "grassland", {"temperate"})
	biomes.add("wet_highland_scree", "grassland", {"humid"})
	biomes.add("dry_highland", "rock", {"temperate"})
	biomes.add("dry_mountain", "rock", {"humid"})
end

-- Loria
if minetest.get_modpath("loria") then
	biomes.add("loria:redland", "rock", {"hot", "villages"})
	biomes.add("loria:reptile_house", "grassland")
	biomes.add("loria:acidic_landscapes", "grassland", {"temperate", "villages"})
	biomes.add("loria:azure", "grassland", {"cold"})
	biomes.add("loria:purple_swamp", "forest", {"humid"})
	biomes.add("loria:swamp_connector", "forest", {"humid"})
	biomes.add("loria:mercury_ocean", "desert")
end

-- Ethereal by TenPlus1
if minetest.get_modpath("ethereal") then
	biomes.add("mountain", "snowy", {"cold"})
	biomes.add("grassland", "grassland", {"humid", "temperate", "villages"})
	biomes.add("desert", "desert", {"hot", "villages"})
	biomes.add("bamboo", "forest", {"humid"})
	biomes.add("sakura", "forest")
	biomes.add("mesa", "rock", {"hot"})
	biomes.add("coniferous_forest", "pine", {"cold"})
	biomes.add("taiga", "snowy", {"cold"})
	biomes.add("frost_floatland", "snowy")
	biomes.add("frost", "snowy", {"cold"})
	biomes.add("deciduous_forest", "forest", {"temperate"})
	biomes.add("grayness", "rock")
	biomes.add("grassytwo", "grassland", {"temperate"})
	biomes.add("prairie", "grassland", {"temperate", "villages"})
	biomes.add("jumble", "grassland", {"temperate"})
	biomes.add("junglee", "forest", {"humid"})
	biomes.add("grove", "forest", {"humid"})
	biomes.add("mediterranean", "grassland")
	biomes.add("mushroom", "grassland", {"cold"})
	biomes.add("sandstone", "desert", {"hot", "villages"})
	biomes.add("quicksand", "desert", {"hot"})
	biomes.add("plains", "grassland", {"humid", "temperate", "villages"})
	biomes.add("savanna", "grassland", {"hot"})
	biomes.add("fiery", "rock", {"hot"})
	biomes.add("fiery_beach", "beach", {"hot", "villages"})
	biomes.add("sandclay", "rock", {"hot", "villages"})
	biomes.add("swamp", "forest", {"humid"})
	biomes.add("glacier", "snowy", {"cold", "villages"})
	biomes.add("tundra", "snowy", {"cold"})
	biomes.add("tundra_highland", "snowy", {"cold"})
end

-- Extra Biomes by CowboyLva
if minetest.get_modpath("ebiomes") then
	biomes.add("bog", "grassland")
	biomes.add("cold_desert_buffer", "desert", {"cold", "villages"})
	biomes.add("cold_steppe", "grassland", {"cold", "villages"})
	biomes.add("cold_steppe_dunes", "beach", {"villages"})
	biomes.add("deciduous_forest_cold", "forest", {"cold"})
	biomes.add("deciduous_forest_cold_shore", "beach")
	biomes.add("deciduous_forest_warm", "forest", {"temperate"})
	biomes.add("deciduous_forest_warm_shore", "beach")
	biomes.add("grassland_warm", "grassland", {"temperate", "villages"})
	biomes.add("grassland_warm_dunes", "beach", {"temperate", "villages"})
	biomes.add("grassland_arid", "grassland", {"hot", "villages"})
	biomes.add("grassland_arid_shore", "beach", {"temperate", "villages"})
	biomes.add("grassland_arid_cool", "grassland", {"temperate", "villages"})
	biomes.add("grassland_arid_cool_shore", "beach", {"temperate", "villages"})
	biomes.add("humid_savanna", "grassland", {"humid"})
	biomes.add("humid_savanna_shore", "beach")
	biomes.add("mediterranean", "grassland", {"temperate"})
	biomes.add("mediterranean_dunes", "beach")
	biomes.add("sandstone_desert_buffer", "desert", {"hot", "villages"})
	biomes.add("steppe", "grassland", {"temperate", "villages"})
	biomes.add("steppe_dunes", "beach", {"temperate", "villages"})
	biomes.add("swamp", "forest", {"humid"})
	biomes.add("swamp_shore", "beach", {"humid"})
	biomes.add("swamp_ocean", "underwater")
	biomes.add("swamp_under", "underground")
	biomes.add("warm_steppe", "grassland", {"temperate", "villages"})
	biomes.add("warm_steppe_dunes", "beach", {"villages"})
	biomes.add("warm_steppe_ocean", "underwater")
	biomes.add("warm_steppe_under", "underground")
end

-- MoreBiomes by skylar-eng
if minetest.get_modpath("morebiomes") then
	biomes.add("luna", "rock", {"villages"})
end

-- Wildflower Fields by skylar-eng
if minetest.get_modpath("wildflower_fields") then
	biomes.add("wildflowers", "grassland", {"villages"})
end

-- Redwood Biome by runs
if minetest.get_modpath("redw") then
	biomes.add("redwood_forest", "forest", {"temperate"})
end

-- Wilhelmines Natural Biomes by Skandarella
if minetest.get_modpath("naturalbiomes") then
	biomes.add("naturalbiomes:alderswamp", "grassland", {"humid"})
	biomes.add("naturalbiomes:alpine", "pine", {"cold"})
	biomes.add("bambooforest", "forest", {"humid"})
	biomes.add("naturalbiomes:heath", "grassland", {"temperate"})
	biomes.add("naturalbiomes:mediterranean", "rock")
	biomes.add("naturalbiomes:outback", "rock", {"hot"})
	biomes.add("naturalbiomes:palmbeach", "beach", {"temperate"})
	biomes.add("naturalbiomes:wetsavanna", "grassland", {"humid"})
end

-- Wilhelmines Living Jungle by Skandarella
if minetest.get_modpath("livingjungle") then
	biomes.add("livingjungle:jungle", "forest", {"humid"})
end

-- Everness by SaKeL
if minetest.get_modpath("everness") then
	biomes.add("everness_bamboo_forest", "forest", {"humid"})
	biomes.add("everness_baobab_savanna", "grassland", {"hot"})
	biomes.add("everness_coral_forest", "forest", {"temperate"})
	biomes.add("everness_coral_forest_dunes", "desert", {"hot", "villages"})
	biomes.add("everness_crystal_forest", "forest", {"temperate"})
	biomes.add("everness_crystal_forest_dunes", "rock", {"temperate", "villages"})
	biomes.add("everness_crystal_forest_shore", "beach", {"villages"})
	biomes.add("everness_cursed_lands", "rock")
	biomes.add("everness_cursed_lands_dunes", "desert")
	biomes.add("everness_cursed_lands_swamp", "grassland", {"humid"})
	biomes.add("everness_forsaken_desert", "desert", {"hot"})
	biomes.add("everness_forsaken_tundra", "snowy", {"cold", "villages"})
	biomes.add("everness_forsaken_tundra_beach", "snowy", {"villages"})
	biomes.add("everness_frosted_icesheet", "snowy", {"villages"})
end

-- 30 Biomes by Gael-de-Sailly
if minetest.get_modpath("30biomes") then
	biomes.add("glacier_1", "snowy", {"cold", "villages"})
	biomes.add("glacier_2", "snowy", {"cold", "villages"})
	biomes.add("glacier_3", "snowy", {"cold", "villages"})
	biomes.add("taiga", "snowy", {"cold"})
	biomes.add("tundra", "snowy", {"cold", "villages"})
	biomes.add("coniferous_forest", "pine", {"cold"})
	biomes.add("cold_gravel_desert", "snowy", {"cold", "villages"})
	biomes.add("gravel_desert", "rock", {"villages"})
	biomes.add("dry_tundra", "snowy", {"cold", "villages"})
	biomes.add("cold_desert", "rock", {"cold", "villages"})
	biomes.add("swamp", "grassland", {"humid", "villages"})
	biomes.add("icy_swamp", "snowy", {"cold", "villages"})
	biomes.add("stone_grasslands", "grassland", {"villages"})
	biomes.add("mixed_forest", "forest", {"temperate"})
	biomes.add("cold_deciduous_forest", "forest", {"cold"})
	biomes.add("deciduous_forest", "forest", {"temperate"})
	biomes.add("bushes", "grassland", {"temperate"})
	biomes.add("scrub", "grassland", {"temperate"})
	biomes.add("hot_pine_forest", "pine", {"temperate"})
	biomes.add("desert", "desert", {"hot", "villages"})
	biomes.add("sandstone_grasslands", "grassland", {"villages"})
	biomes.add("savanna", "grassland", {"temperate"})
	biomes.add("desert_stone_grasslands", "grassland", {"hot", "villages"})
	biomes.add("red_savanna", "grassland", {"hot"})
	biomes.add("semi-tropical_forest", "forest", {"humid"})
	biomes.add("rainforest", "forest", {"humid"})
	biomes.add("sandstone_desert", "desert", {"hot", "villages"})
	biomes.add("orchard", "forest", {"humid"})
	biomes.add("hot_deciduous_forest", "forest", {"hot"})	
	biomes.add("gravel_beach", "rock", {"villages"})
	biomes.add("sand_dunes", "beach", {"temperate", "villages"})
	biomes.add("mangrove", "rock", {"humid"})
	biomes.add("desert_dunes", "beach", {"hot", "villages"})
	biomes.add("hot_sand_dunes", "beach", {"hot", "villages"})
	biomes.add("tundra_dunes", "beach", {"cold", "villages"})
	biomes.add("glacier_2_shore", "snowy", {"cold", "villages"})
	biomes.add("glacier_3_shore", "snowy", {"cold", "villages"})
	biomes.add("swamp_shore", "rock", {"humid", "villages"})
	biomes.add("icy_swamp_shore", "snowy", {"cold", "villages"})
	biomes.add("hot_swamp_shore", "rock", {"hot", "villages"})
end

-- Saltd by runs
if minetest.get_modpath("saltd") then
	biomes.add("salt_desert", "desert", {"hot"})
end

-- Swampz by runs
if minetest.get_modpath("swampz") then
	biomes.add("swampz", "forest", {"humid"})
end

-- Convert group strings
local sand = string.match(group.sand, "^group:(.*)$")
local snow = string.match(group.snowy, "^group:(.*)$")
local stone = string.match(group.stone, "^group:(.*)$")

-- Returns a background texture to match environment in battles
function biomes.background(player)
	local pos = player:get_pos()
	local feet_node = minetest.get_node(vector.offset(pos, 0, 0, 0))
	local under_node = minetest.get_node(vector.offset(pos, 0, -0.5, 0))
	local under_node_def = minetest.registered_nodes[under_node.name]
	local under_node_groups = under_node_def and under_node_def.groups
	local biome_data = minetest.get_biome_data(pos)
	local biome_name = biome_data and string.lower(minetest.get_biome_name(biome_data.biome))
	local heat = biome_data and biome_data.heat
	local humidity = biome_data and biome_data.humidity
	local natural_light = minetest.get_natural_light(pos, 0.5) or 15
	local inside_water = minetest.get_item_group(feet_node.name, "water") > 0 and 1 or nil
	local background = biome_data and biomes.backgrounds[biome_name]
	
	if inside_water then
		return "zoonami_underwater_background.png"
	elseif pos.y < -500 and natural_light < 1 then
		return "zoonami_bedrock_background.png"
	elseif pos.y < -5 and natural_light < 1 then
		return "zoonami_underground_background.png"
	elseif background then
		return "zoonami_"..background.."_background.png"
	elseif under_node_groups[snow] then
		return "zoonami_snowy_background.png"
	elseif under_node_groups[sand] then
		if heat and humidity and (heat < 60 or humidity >= 40) then
			return "zoonami_beach_background.png"
		else
			return "zoonami_desert_background.png"
		end
	elseif under_node_groups[stone] then
		return "zoonami_rock_background.png"
	elseif humidity and humidity >= 60 then
		return "zoonami_forest_background.png"
	else
		return "zoonami_grassland_background.png"
	end
end

return biomes
