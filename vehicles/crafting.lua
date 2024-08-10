local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)


local i = {
	"default:steel_ingot",
	"default:copper_ingot",
	"default:iron_lump",
	"default:copper_lump",
	"default:gold_lump",
	"default:coal_lump",
	"default:glass",
	"dye:red",
	"dye:blue",
	"dye:magenta",
	"dye:white",
	"dye:orange",
	"dye:cyan",
	"dye:violet",
	"dye:grey",
	"dye:black",
	"dye:brown",
	"dye:green",
	"dye:yellow",
	"default:mese_crystal",
	"default:desert_sand",
	"farming:hoe_steel",
	"default:stick",
	"default:torch",
}

if minetest.get_modpath("default") then
	for k, v in pairs(i) do
		i[v] = v
	end
elseif minetest.get_modpath("mcl_core") then
	i["default:steel_ingot"] = "mcl_core:iron_ingot"
	i["default:copper_ingot"] = "mcl_copper:copper_ingot"
	i["default:iron_lump"] = "mcl_raw_ores:raw_iron"
	i["default:copper_lump"] = "mcl_copper:raw_copper"
	i["default:gold_lump"] = "mcl_raw_ores:raw_gold"
	i["default:coal_lump"] = "mcl_core:coal_lump"
	i["default:glass"] = "mcl_core:glass"
	i["dye:red"] = "mcl_dyes:red"
	i["dye:blue"] = "mcl_dyes:blue"
	i["dye:magenta"] = "mcl_dyes:magenta"
	i["dye:white"] = "mcl_dyes:white"
	i["dye:orange"] = "mcl_dyes:orange"
	i["dye:cyan"] = "mcl_dyes:cyan"
	i["dye:violet"] = "mcl_dyes:violet"
	i["dye:grey"] = "mcl_dyes:grey"
	i["dye:black"] = "mcl_dyes:black"
	i["dye:brown"] = "mcl_dyes:brown"
	i["dye:green"] = "mcl_dyes:green"
	i["dye:yellow"] = "mcl_dyes:yellow"
	i["default:mese_crystal"] = "mcl_core:emerald"
	i["default:desert_sand"] = "mcl_core:redsand"
	i["farming:hoe_steel"] = "mcl_farming:hoe_iron"
	i["default:stick"] = "mcl_core:stick"
	i["default:torch"] = "mcl_core:torch"
end


-- craftitem materials and crafting recipes
-- (only if default and dye mods exist)

local S = minetest.get_translator(modname)

minetest.register_craftitem(modname .. ":vehicles_wheel", {
	description = S("Wheel"),
	inventory_image = "vehicles_wheel.png",
})

minetest.register_craftitem(modname .. ":vehicles_engine", {
	description = S("Engine"),
	inventory_image = "vehicles_engine.png",
})

minetest.register_craftitem(modname .. ":vehicles_body", {
	description = S("Car Body"),
	inventory_image = "vehicles_car_body.png",
})

minetest.register_craftitem(modname .. ":vehicles_armor", {
	description = S("Armor plating"),
	inventory_image = "vehicles_armor.png",
})

minetest.register_craftitem(modname .. ":vehicles_gun", {
	description = S("Vehicle Gun"),
	inventory_image = "vehicles_gun.png",
})

minetest.register_craftitem(modname .. ":vehicles_propeller", {
	description = S("Propeller"),
	inventory_image = "vehicles_propeller.png",
})

minetest.register_craftitem(modname .. ":vehicles_jet_engine", {
	description = S("Jet Engine"),
	inventory_image = "vehicles_jet_engine.png",
})

minetest.register_craft({
	output = modname .. ":vehicles_propeller",
	recipe = {
		{i["default:steel_ingot"], "", ""},
		{"", "group:stick", ""},
		{"", "", i["default:steel_ingot"]}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_jet_engine",
	recipe = {
		{"", i["default:steel_ingot"], ""},
		{i["default:steel_ingot"], modname .. ":vehicles_propeller", i["default:steel_ingot"]},
		{"", i["default:steel_ingot"], ""}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_armor",
	recipe = {
		{"", i["default:gold_lump"], ""},
		{"", i["default:iron_lump"], ""},
		{"", i["default:copper_lump"], ""}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_gun",
	recipe = {
		{"", modname .. ":vehicles_armor", ""},
		{modname .. ":vehicles_armor", i["default:coal_lump"], modname .. ":vehicles_armor"},
		{"", i["default:steel_ingot"], ""}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_wheel",
	recipe = {
		{"", i["default:coal_lump"], ""},
		{i["default:coal_lump"], i["default:steel_ingot"], i["default:coal_lump"]},
		{"", i["default:coal_lump"], ""}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_engine",
	recipe = {
		{i["default:copper_ingot"], "", i["default:copper_ingot"]},
		{i["default:steel_ingot"], i["default:mese_crystal"], i["default:steel_ingot"]},
		{"", i["default:steel_ingot"], ""}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_body",
	recipe = {
		{"", i["default:glass"], ""},
		{i["default:glass"], i["default:steel_ingot"], i["default:glass"]},
		{"", "", ""}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_bullet_item 5",
	recipe = {
		{i["default:coal_lump"], i["default:iron_lump"],},
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_missile_2_item",
	recipe = {
		{"", i["default:steel_ingot"], ""},
		{"", i["default:torch"], ""},
		{i["default:stick"], i["default:coal_lump"], i["default:stick"]}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_masda_spawner",
	recipe = {
		{"", i["dye:magenta"], ""},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_masda2_spawner",
	recipe = {
		{"", i["dye:orange"], ""},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_ute_spawner",
	recipe = {
		{"", i["dye:brown"], ""},
		{i["default:steel_ingot"], modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_ute2_spawner",
	recipe = {
		{"", i["dye:white"], ""},
		{i["default:steel_ingot"], modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_nizzan2_spawner",
	recipe = {
		{"", i["dye:green"], ""},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_nizzan_spawner",
	recipe = {
		{"", i["dye:brown"], ""},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_astonmaaton_spawner",
	recipe = {
		{"", i["dye:white"], ""},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_pooshe_spawner",
	recipe = {
		{"", i["dye:red"], ""},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_pooshe2_spawner",
	recipe = {
		{"", i["dye:yellow"], ""},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_lambogoni_spawner",
	recipe = {
		{"", i["dye:grey"], ""},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_lambogoni2_spawner",
	recipe = {
		{"", i["dye:yellow"], ""},
		{"", modname .. ":vehicles_body", i["dye:grey"]},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_fewawi_spawner",
	recipe = {
		{"", i["dye:red"], ""},
		{"", modname .. ":vehicles_body", i["default:glass"]},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_fewawi2_spawner",
	recipe = {
		{"", i["dye:blue"], ""},
		{"", modname .. ":vehicles_body", i["default:glass"]},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_tractor_spawner",
	recipe = {
		{"", "", ""},
		{modname .. ":vehicles_engine", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_wheel", i["farming:hoe_steel"]}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_musting_spawner",
	recipe = {
		{"", i["dye:violet"], ""},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_musting2_spawner",
	recipe = {
		{"", i["dye:blue"], ""},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_policecar_spawner",
	recipe = {
		{"", i["dye:blue"], i["dye:red"]},
		{"", modname .. ":vehicles_body", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_tank_spawner",
	recipe = {
		{"", modname .. ":vehicles_gun", ""},
		{modname .. ":vehicles_armor", modname .. ":vehicles_engine", modname .. ":vehicles_armor"},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_wheel", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_tank2_spawner",
	recipe = {
		{i["default:desert_sand"], modname .. ":vehicles_gun", ""},
		{modname .. ":vehicles_armor", modname .. ":vehicles_engine", modname .. ":vehicles_armor"},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_wheel", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_turret_spawner",
	recipe = {
		{"", modname .. ":vehicles_gun", ""},
		{modname .. ":vehicles_armor", modname .. ":vehicles_engine", modname .. ":vehicles_armor"},
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_jet_spawner",
	recipe = {
		{"", modname .. ":vehicles_gun", ""},
		{modname .. ":vehicles_jet_engine", i["default:steel_ingot"], modname .. ":vehicles_jet_engine"},
		{"", i["default:steel_ingot"], ""}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_plane_spawner",
	recipe = {
		{"", modname .. ":vehicles_propeller", ""},
		{i["default:steel_ingot"], modname .. ":vehicles_engine", i["default:steel_ingot"]},
		{"", i["default:steel_ingot"], ""}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_helicopter_spawner",
	recipe = {
		{"", modname .. ":vehicles_propeller", ""},
		{modname .. ":vehicles_propeller", modname .. ":vehicles_engine", i["default:glass"]},
		{"", i["default:steel_ingot"], ""}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_apache_spawner",
	recipe = {
		{"", modname .. ":vehicles_propeller", ""},
		{modname .. ":vehicles_propeller", modname .. ":vehicles_engine", i["default:glass"]},
		{"", modname .. ":vehicles_armor", i["default:steel_ingot"]}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_lightcycle_spawner",
	recipe = {
		{i["default:steel_ingot"], modname .. ":vehicles_engine", i["dye:cyan"]},
		{modname .. ":vehicles_wheel", i["default:steel_ingot"], modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_lightcycle2_spawner",
	recipe = {
		{i["default:steel_ingot"], modname .. ":vehicles_engine", i["dye:orange"]},
		{modname .. ":vehicles_wheel", i["default:steel_ingot"], modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_boat_spawner",
	recipe = {
		{"", "", ""},
		{i["default:steel_ingot"], modname .. ":vehicles_engine", i["default:steel_ingot"]},
		{i["default:steel_ingot"], i["default:steel_ingot"], i["default:steel_ingot"]}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_firetruck_spawner",
	recipe = {
		{"", i["dye:red"], ""},
		{modname .. ":vehicles_body", modname .. ":vehicles_engine", modname .. ":vehicles_body"},
		{modname .. ":vehicles_wheel", i["default:steel_ingot"], modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_geep_spawner",
	recipe = {
		{"", "", ""},
		{"", modname .. ":vehicles_engine", ""},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_armor", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_ambulance_spawner",
	recipe = {
		{"", "", ""},
		{modname .. ":vehicles_body", modname .. ":vehicles_body", i["dye:white"]},
		{modname .. ":vehicles_wheel", modname .. ":vehicles_engine", modname .. ":vehicles_wheel"}
	}
})

minetest.register_craft({
	output = modname .. ":vehicles_assaultsuit_spawner",
	recipe = {
		{modname .. ":vehicles_gun", i["default:glass"], modname .. ":vehicles_armor"},
		{"", modname .. ":vehicles_engine", ""},
		{modname .. ":vehicles_armor", "", modname .. ":vehicles_armor"}
	}
})


minetest.register_craft({
	output = modname .. ":vehicles_backpack",
	recipe = {
		{"group:wool", "group:wool", "group:wool"},
		{"group:stick", "", "group:stick"},
		{"", "group:wood", ""}
	}
})