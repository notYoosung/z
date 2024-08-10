-- Handles basic mapgen features of Zoonami

-- Import files
local modname = minetest.get_current_modname() or "z"
local mod_path = minetest.get_modpath(modname)

local biomes = dofile(mod_path .. "/lua/biomes.lua")
local group = dofile(mod_path .. "/lua/group.lua")

-- Mob settings
local settings = minetest.settings
local generate_villages = settings:get_bool("zoonami_generate_villages") ~= false
local village_multiplier = tonumber(settings:get("zoonami_village_multiplier") or 1)
local prepopulate_villages = settings:get_bool("zoonami_prepopulate_villages") ~= false
local prepopulate_villages_multiplier = tonumber(settings:get("zoonami_prepopulate_villages_multiplier") or 1)
local prepopulate_world = settings:get_bool("zoonami_prepopulate_world") ~= false
local prepopulate_world_multiplier = tonumber(settings:get("zoonami_prepopulate_world_multiplier") or 1)
local generate_berry_bushes = settings:get_bool("zoonami_generate_berry_bushes") ~= false
local generate_flowers = settings:get_bool("zoonami_generate_flowers") ~= false
local mg_name = minetest.get_mapgen_setting("mg_name")

-- Force decorations if any are enabled
if prepopulate_world and prepopulate_world_multiplier > 0 
or generate_villages or generate_berry_bushes or generate_flowers then
	minetest.set_mapgen_setting("mg_flags", "decorations", true)
end

-- Default fill ratios
local bushes_fill_ratio = 0.0001
local flowers_fill_ratio = 0.0001
local village_fill_ratio = #biomes.villages > 0 and 0.000032 or 0

-- Mapgen version fill ratios
if mg_name == "v6" then
	bushes_fill_ratio = 0.00001
	flowers_fill_ratio = 0.00001
	village_fill_ratio = 0
elseif mg_name == "carpathian" then
	village_fill_ratio = #biomes.villages > 0 and 0.000024 or 0
elseif mg_name == "flat" then
	village_fill_ratio = #biomes.villages > 0 and 0.000014 or 0
end

-- Turn off mapgen features if they are disabled
village_fill_ratio = generate_villages and village_fill_ratio or 0
bushes_fill_ratio = generate_berry_bushes and bushes_fill_ratio or 0
flowers_fill_ratio = generate_flowers and flowers_fill_ratio or 0
prepopulate_villages_multiplier = prepopulate_villages and prepopulate_villages_multiplier or 0
prepopulate_world_multiplier = prepopulate_world and prepopulate_world_multiplier or 0

-- Berry Bushes
local function register_berry_bush(node_name, biomes_table)
	minetest.register_decoration({
		name = modname .. ":zoonami_"..node_name.."_berry_bush_2",
		deco_type = "simple",
		place_on = {group.crumbly, group.grass, group.soil},
		sidelen = 16,
		fill_ratio = #biomes_table > 0 and bushes_fill_ratio or 0.00001,
		biomes = biomes_table,
		y_max = 31000,
		y_min = 0,
		decoration = modname .. ":zoonami_"..node_name.."_berry_bush_2",
	})
end

register_berry_bush("blue", biomes.cold)
register_berry_bush("red", biomes.temperate)
register_berry_bush("orange", biomes.hot)
register_berry_bush("green", biomes.humid)

-- Flowers
local function register_flower(node_name, biomes_table)
	minetest.register_decoration({
		name = node_name,
		deco_type = "simple",
		place_on = {group.crumbly, group.grass, group.soil},
		sidelen = 16,
		fill_ratio = #biomes_table > 0 and flowers_fill_ratio or 0.00001,
		biomes = biomes_table,
		y_max = 31000,
		y_min = 0,
		decoration = node_name,
	})
end

register_flower(modname .. ":zoonami_daisy", biomes.cold)
register_flower(modname .. ":zoonami_blue_tulip", biomes.temperate)
register_flower(modname .. ":zoonami_sunflower", biomes.temperate)
register_flower(modname .. ":zoonami_tiger_lily", biomes.hot)
register_flower(modname .. ":zoonami_zinnia", biomes.humid)

-- Monster Mapgen Spawning
minetest.register_decoration({
	name = modname .. ":zoonami_monster_mapgen_spawn",
	deco_type = "simple",
	place_on = {group.cracky, group.crumbly, group.grass, group.sand, group.stone, group.snowy},
	sidelen = 16,
	fill_ratio = 0.001 * prepopulate_world_multiplier,
	y_max = 31000,
	y_min = -31000,
	decoration = modname .. ":zoonami_monster_mapgen_spawn",
})

minetest.register_decoration({
	name = modname .. ":zoonami_monster_mapgen_spawn_liquid",
	deco_type = "simple",
	place_on = {group.lava, group.water},
	sidelen = 16,
	fill_ratio = 0.001 * prepopulate_world_multiplier,
	y_max = 31000,
	y_min = -31000,
	flags = "liquid_surface",
	decoration = modname .. ":zoonami_monster_mapgen_spawn",
})

-- Villages
minetest.register_decoration({
	name = modname .. ":zoonami_village_layout",
	deco_type = "schematic",
	place_on = {group.cracky, group.crumbly, group.grass, group.sand, group.snowy, group.soil, group.stone},
	sidelen = 256,
	fill_ratio = village_fill_ratio * village_multiplier,
	biomes = biomes.villages,
	y_max = 20,
	y_min = 0,
	schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_village_layout.mts",
	flags = "place_center_x, place_center_y, place_center_z",
	rotation = "random",
	spawn_by = {"group:soil", "group:sand"},
	num_spawn_by = 8,
})

-- Buildings
minetest.register_decoration({
	name = modname .. ":zoonami_house_red_slanted_roof",
	deco_type = "schematic",
	place_on = {group.cracky, group.crumbly, group.sand, group.snowy, group.soil, group.stone},
	sidelen = 16,
	fill_ratio = 0.048,
	biomes = biomes.villages,
	y_max = 20,
	y_min = 3,
	place_offset_y = -4,
	schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_house_red_slanted_roof.mts",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
	spawn_by = modname .. ":zoonami_village_path",
	num_spawn_by = 1,
})

minetest.register_decoration({
	name = modname .. ":zoonami_house_blue_slanted_roof",
	deco_type = "schematic",
	place_on = {group.cracky, group.crumbly, group.sand, group.snowy, group.soil, group.stone},
	sidelen = 16,
	fill_ratio = 0.048,
	biomes = biomes.villages,
	y_max = 20,
	y_min = 3,
	place_offset_y = -4,
	schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_house_blue_slanted_roof.mts",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
	spawn_by = modname .. ":zoonami_village_path",
	num_spawn_by = 1,
})

minetest.register_decoration({
	name = modname .. ":zoonami_shop_red_flat_roof",
	deco_type = "schematic",
	place_on = {group.cracky, group.crumbly, group.sand, group.snowy, group.soil, group.stone},
	sidelen = 16,
	fill_ratio = 0.045,
	biomes = biomes.villages,
	y_max = 20,
	y_min = 3,
	place_offset_y = -4,
	schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_shop_red_flat_roof.mts",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
	spawn_by = modname .. ":zoonami_village_path",
	num_spawn_by = 1,
})

minetest.register_decoration({
	name = modname .. ":zoonami_shop_blue_flat_roof",
	deco_type = "schematic",
	place_on = {group.cracky, group.crumbly, group.sand, group.snowy, group.soil, group.stone},
	sidelen = 16,
	fill_ratio = 0.045,
	biomes = biomes.villages,
	y_max = 20,
	y_min = 3,
	place_offset_y = -4,
	schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_shop_blue_flat_roof.mts",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
	spawn_by = modname .. ":zoonami_village_path",
	num_spawn_by = 1,
})

-- Flower Patches
minetest.register_decoration({
	name = modname .. ":zoonami_orange_flower_patch",
	deco_type = "schematic",
	place_on = {group.cracky, group.crumbly, group.sand, group.snowy, group.soil, group.stone},
	sidelen = 16,
	fill_ratio = 0.022,
	biomes = biomes.villages,
	y_max = 20,
	y_min = 3,
	place_offset_y = -3,
	schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_orange_flower_patch.mts",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
	spawn_by = modname .. ":zoonami_village_path",
	num_spawn_by = 1,
})

minetest.register_decoration({
	name = modname .. ":zoonami_red_flower_patch",
	deco_type = "schematic",
	place_on = {group.cracky, group.crumbly, group.sand, group.snowy, group.soil, group.stone},
	sidelen = 16,
	fill_ratio = 0.022,
	biomes = biomes.villages,
	y_max = 20,
	y_min = 3,
	place_offset_y = -3,
	schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_red_flower_patch.mts",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
	spawn_by = modname .. ":zoonami_village_path",
	num_spawn_by = 1,
})

-- Fountains
minetest.register_decoration({
	name = modname .. ":zoonami_large_fountain",
	deco_type = "schematic",
	place_on = {group.cracky, group.crumbly, group.sand, group.snowy, group.soil, group.stone},
	sidelen = 16,
	fill_ratio = 0.024,
	biomes = biomes.villages,
	y_max = 20,
	y_min = 3,
	place_offset_y = -3,
	schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_large_fountain.mts",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
	spawn_by = modname .. ":zoonami_village_path",
	num_spawn_by = 1,
})

minetest.register_decoration({
	name = modname .. ":zoonami_small_fountain",
	deco_type = "schematic",
	place_on = {group.cracky, group.crumbly, group.sand, group.snowy, group.soil, group.stone},
	sidelen = 16,
	fill_ratio = 0.024,
	biomes = biomes.villages,
	y_max = 20,
	y_min = 3,
	place_offset_y = -3,
	schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_small_fountain.mts",
	flags = "place_center_x, place_center_z, force_placement",
	rotation = "random",
	spawn_by = modname .. ":zoonami_village_path",
	num_spawn_by = 1,
})

-- NPC Mapgen Spawning
minetest.register_decoration({
	name = modname .. ":zoonami_npc_mapgen_spawn",
	deco_type = "simple",
	place_on = {group.cracky, group.crumbly, group.sand, group.snowy, group.soil, group.stone},
	sidelen = 16,
	fill_ratio = 0.02 * prepopulate_villages_multiplier,
	y_max = 20,
	y_min = 3,
	decoration = modname .. ":zoonami_npc_mapgen_spawn",
	spawn_by = {modname .. ":zoonami_gravel_path"},
	num_spawn_by = 1,
})

-- Crystal Puzzles
for i = 1, 7 do
	minetest.register_decoration({
		name = modname .. ":zoonami_crystal_puzzle_"..i,
		deco_type = "schematic",
		place_on = {group.crumbly, group.stone},
		sidelen = 16,
		noise_params = {
			offset = 0.0001,
			scale = 0.00075,
			spread = {x = 350, y = 350, z = 350},
			seed = 163 * i,
			octaves = 1,
			persist = 0.1
		},
		y_max = -50,
		y_min = -31000,
		place_offset_y = -5,
		schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_crystal_puzzle_"..i..".mts",
		flags = "place_center_x, place_center_z, all_floors, force_placement",
		rotation = "random",
	})
end

-- Excavation Sites
local function register_excavation_site(id, place_on, scale, seed, y_max, y_min, placement)
	minetest.register_decoration({
		name = modname .. ":zoonami_excavation_site_"..id,
		deco_type = "schematic",
		place_on = {place_on},
		sidelen = 8,
		noise_params = {
			offset = 0.00045,
			scale = scale,
			spread = {x = 250, y = 250, z = 250},
			seed = seed,
			octaves = 1,
			persist = 0.1
		},
		y_max = y_max,
		y_min = y_min,
		place_offset_y = -3,
		schematic = minetest.get_modpath(modname) .. "/schematics/zoonami_excavation_site.mts",
		flags = "place_center_x, place_center_z, "..placement..", force_placement",
		rotation = "random",
	})
end

register_excavation_site(1, group.crumbly, 0.0016, 162, -50, -31000, "all_floors")
register_excavation_site(2, group.crumbly, 0.0013, 535, -50, -31000, "all_ceilings")
register_excavation_site(3, group.stone, 0.0008, 472, -50, -500, "all_floors")
register_excavation_site(4, group.stone, 0.001, 834, -500, -31000, "all_floors")
register_excavation_site(5, group.stone, 0.0008, 735, -500, -31000, "all_ceilings")

-- Zeenite Ore
minetest.register_ore({
	ore_type = "scatter",
	ore = modname .. ":zoonami_zeenite_ore",
	wherein = "mapgen_stone",
	clust_scarcity = 8 * 8 * 8,
	clust_num_ores = 5,
	clust_size = 3,
	y_max = -20,
	y_min = -31000,
})
