local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()

mcl_trees.register_wood("acorn_oak",{
	readable_name = "Acorn Oak",
	sign_color="#625048",
	tree_schems_2x2 = {
		{ file = modpath.."/schematics/mcl_core_oak_balloon.mts"},
		{ file = modpath.."/schematics/mcl_core_oak_large_1.mts"},
		{ file = modpath.."/schematics/mcl_core_oak_large_2.mts"},
		{ file = modpath.."/schematics/mcl_core_oak_large_3.mts"},
		{ file = modpath.."/schematics/mcl_core_oak_large_4.mts"},
		{ file = modpath.."/schematics/mcl_core_oak_swamp.mts"},
		{ file = modpath.."/schematics/mcl_core_oak_v6.mts"},
		{ file = modpath.."/schematics/mcl_core_oak_classic.mts"},
	},
	tree = { tiles = {"z_acorn_tree_top.png", "z_acorn_tree_top.png","z_acorn_tree.png"} },
	leaves = {
		tiles = { "default_leaves.png" },
		color = "#77ab2f",
	},
	drop_apples = true,
	wood = { tiles = {"z_acorn_wood.png"}},
	door = {
		inventory_image = "z_acorn_door.png",
		tiles_bottom = {"z_acorn_door_bottom.png", "z_acorn_door_bottom_side.png"},
		tiles_top = {"z_acorn_door_top.png", "z_acorn_door_top_side.png"}
	},
	trapdoor = {
		tile_front = "z_acorn_door_top.png",
		tile_side = "z_acorn_door_side.png",
		wield_image = "z_acorn_door_top.png",
	},
	sapling = {
		tiles = {"z_acorn_sapling.png"},
		inventory_image = "z_acorn_sapling.png",
		wield_image = "z_acorn_sapling.png",
		_after_grow=mcl_trees.sapling_add_bee_nest,
	},
	--[[fence = {
		tiles = { "mcl_fences_fence_big_oak.png" },
	},
	fence_gate = {
		tiles = { "mcl_fences_fence_gate_big_oak.png" },
	},--]]
	potted_sapling = {
		image = "z_acorn_sapling.png",
	},
})
