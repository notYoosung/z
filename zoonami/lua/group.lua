local modname = minetest.get_current_modname() or "z"
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

-- Handles node and item groups to support compatability across multiple games

-- Local namespace
local group = {}

-- Default values
group.air = "group:air"
group.choppy = "group:choppy"
group.cracky = "group:cracky"
group.crumbly = "group:crumbly"
group.flora = "group:flora"
group.flower = "group:flower"
group.grass = "group:spreading_dirt_type"
group.lava = "group:lava"
group.leaves = "group:leaves"
group.sand = "group:sand"
group.snappy = "group:snappy"
group.snowy = "group:snowy"
group.soil = "group:soil"
group.stone = "group:stone"
group.tall_grass = "group:grass"
group.tree = "group:tree"
group.water = "group:water"
group.wood = "group:wood"          

-- Additional mod support
if minetest.get_modpath("mcl_core") then
	group.choppy = "group:axey"
	group.cracky = "group:pickaxey"
	group.crumbly = "group:shovely"
	group.flora = "group:plant"
	group.snappy = "group:handy"
	group.snowy = "group:snow_cover"
	group.stone = "group:material_stone"
	group.tall_grass = "group:plant"
elseif minetest.get_modpath("exile_env_sounds") then
	group.grass = "group:spreading"
	group.lava = "group:igniter"
	group.leaves = "group:leafdecay"
	group.sand = "group:sediment"
	group.snowy = "group:fall_damage_add_percent"
	group.soil = "group:bare_sediment"
	group.tall_grass = "group:fibrous_plant"
	group.wood = "group:log"
elseif minetest.get_modpath("fl_core") then
	group.choppy = "group:dig_tree"
	group.cracky = "group:dig_stone"
	group.crumbly = "group:dig_sand"
	group.flora = "group:plant"
	group.grass = "group:dig_dirt"
	group.leaves = "group:leaf"
	group.snappy = "group:dig_generic"
	group.snowy = "group:dig_snow"
	group.soil = "group:farm_convert"
	group.stone = "group:stone"
	group.tall_grass = "group:plant"
	group.tree = "group:trunk"
	group.wood = "group:plank"
elseif minetest.get_modpath("hades_core") then
	group.grass = "group:dirt_with_grass"
end

return group
