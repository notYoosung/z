local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local aliases = {
    ["default:steel_ingot"] = "mcl_core:iron_ingot",
    ["default:gold_ingot"] = "mcl_core:gold_ingot",
    ["default:tin_ingot"] = "mcl_copper:copper_ingot",
    ["default:tin_ingot"] = "mcl_copper:copper_ingot",
    ["default:steelblock"] = "mcl_core:ironblock",
}

for k, v in pairs(aliases) do
    minetest.register_alias(k, v)
end




local aliases = {
	["default:steel_ingot"] = "mcl_core:iron_ingot",
	["default:copper_ingot"] = "mcl_copper:copper_ingot",
	["default:iron_lump"] = "mcl_raw_ores:raw_iron",
	["default:copper_lump"] = "mcl_copper:raw_copper",
	["default:gold_lump"] = "mcl_raw_ores:raw_gold",
	["default:coal_lump"] = "mcl_core:coal_lump",
	["default:glass"] = "mcl_core:glass",
	["dye:red"] = "mcl_dyes:red",
	["dye:orange"] = "mcl_dyes:orange",
	["dye:yellow"] = "mcl_dyes:yellow",
	["dye:green"] = "mcl_dyes:green",
	["dye:blue"] = "mcl_dyes:blue",
	["dye:violet"] = "mcl_dyes:violet",
	["dye:magenta"] = "mcl_dyes:magenta",
	["dye:white"] = "mcl_dyes:white",
	["dye:cyan"] = "mcl_dyes:cyan",
	["dye:grey"] = "mcl_dyes:grey",
	["dye:black"] = "mcl_dyes:black",
	["dye:brown"] = "mcl_dyes:brown",
	["default:mese_crystal"] = "mesecons:redstone",
	["default:desert_sand"] = "mcl_core:redsand",
	["farming:hoe_steel"] = "mcl_farming:hoe_iron",
	["default:stick"] = "mcl_core:stick",
	["default:torch"] = "mcl_core:torch",
    ["default:steelblock"] = "mcl_core:ironblock",
}

for k, v in pairs(aliases) do
    minetest.register_alias(k, v)
end


dofile(modpath .. "/mcl_aliases.lua")