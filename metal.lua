local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()



minetest.register_node(modname .. ":metal_block", {
    description = "Metal Block",
    tiles = {"z_metal_block.png"},
	is_ground_content = false,
    groups = {pickaxey=1, z_metal=1},
    sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
    _mcl_hardness = 5,
})

minetest.register_node(modname .. ":metal_smooth", {
    description = "Smooth Metal Block",
    tiles = {"z_metal_block_smooth.png"},
	is_ground_content = false,
    groups = {pickaxey=1, z_metal=1},
    sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
    _mcl_hardness = 5,
})

minetest.register_node(modname .. ":metal_cut", {
    description = "Cut Metal Block",
    tiles = {"z_metal_cut.png"},
	is_ground_content = false,
    groups = {pickaxey=1, z_metal=1},
    sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
    _mcl_hardness = 5,
})

minetest.register_node(modname .. ":metal_cracked", {
    description = "Cracked Metal Block",
    tiles = {"z_metal_block_cracked.png"},
	is_ground_content = false,
    groups = {pickaxey=1, z_metal=1},
    sounds = mcl_sounds.node_sound_metal_defaults(),
    light_source = 8,
	_mcl_blast_resistance = 6,
    _mcl_hardness = 5,
})

minetest.register_node(modname .. ":metal_glistering", {
    description = "Glistering Metal Block",
    tiles = {"z_metal_glistering.png"},
	is_ground_content = false,
    groups = {pickaxey=1, z_metal=1},
    sounds = mcl_sounds.node_sound_metal_defaults(),
    light_source = 4,
	_mcl_blast_resistance = 6,
    _mcl_hardness = 5,
})

minetest.register_node(modname .. ":metal_pillar", {
    description = "Metal Pillar",
    tiles = {"z_metal_pillar_top.png", "z_metal_pillar_top.png", "z_metal_pillar_side.png"},
	is_ground_content = false,
    groups = {pickaxey=1, z_metal=1},
    sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
    _mcl_hardness = 5,
})

minetest.register_node(modname .. ":metal_pipe", {
	description = "Metal Pipe",
	tiles = {
		"z_metal_block_smooth.png",
		"z_metal_block_smooth.png",
		"z_metal_pipe.png",
		"z_metal_pipe.png",
		"z_metal_pipe.png",
		"z_metal_pipe.png",
	},
	drawtype = "nodebox",
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	light_source = 0,
	sunlight_propagates = true,
	groups = { pickaxey=3, deco_block=1 },
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.125, 0.125, -0.4375, 0.125}, -- Base
			{-0.0625, -0.4375, -0.0625, 0.0625, 0.4375, 0.0625}, -- Rod
			{-0.125, 0.5, -0.125, 0.125, 0.4375, 0.125}, -- top- ?
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}, -- Base
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}, -- Base
		},
	},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" or not placer or not placer:is_player() then
			return itemstack
		end

		local p0 = pointed_thing.under
		local p1 = pointed_thing.above
		local param2 = 0

		local placer_pos = placer:get_pos()
		if placer_pos then
			local dir = {
				x = p1.x - placer_pos.x,
				y = p1.y - placer_pos.y,
				z = p1.z - placer_pos.z
			}
			param2 = minetest.dir_to_facedir(dir)
		end

		if p0.y - 1 == p1.y then
			param2 = 20
		elseif p0.x - 1 == p1.x then
			param2 = 16
		elseif p0.x + 1 == p1.x then
			param2 = 12
		elseif p0.z - 1 == p1.z then
			param2 = 8
		elseif p0.z + 1 == p1.z then
			param2 = 4
		end

		return minetest.item_place(itemstack, placer, pointed_thing, param2)
	end,

	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 5,
})
minetest.register_node(modname .. ":metal_pipe_elbow", {
	description = "Metal Pipe Elbow",
	tiles = {
		"z_metal_block_smooth.png",
		"z_metal_block_smooth.png",
		"z_metal_pipe.png",
		"z_metal_pipe.png",
		"z_metal_pipe.png",
		"z_metal_pipe.png",
	},
	drawtype = "nodebox",
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	light_source = 0,
	sunlight_propagates = true,
	groups = { pickaxey=3, deco_block=1 },
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.125, 0.125, -0.4375, 0.125}, -- Base
			{-0.0625, -0.4375, -0.0625, 0.0625, 0.0625, 0.0625}, -- Rod
			{-0.0625, -0.0625, 0.0625, 0.0625, 0.0625, 0.4375}, -- Angled Rod
			{-0.125, -0.125, 0.5, 0.125, 0.125, 0.4375}, -- Angled End
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}, -- Base
			{-0.125, -0.125, 0.125, 0.125, 0.125, 0.5}, -- Angled
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.125, 0.125, 0.125, 0.125}, -- Base
			{-0.125, -0.125, 0.125, 0.125, 0.125, 0.5}, -- Angled
		},
	},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" or not placer or not placer:is_player() then
			return itemstack
		end

		local p0 = pointed_thing.under
		local p1 = pointed_thing.above
		local param2 = 0

		local placer_pos = placer:get_pos()
		if placer_pos then
			local dir = {
				x = p1.x - placer_pos.x,
				y = p1.y - placer_pos.y,
				z = p1.z - placer_pos.z
			}
			param2 = minetest.dir_to_facedir(dir)
		end

		if p0.y - 1 == p1.y then
			param2 = 20
		elseif p0.x - 1 == p1.x then
			param2 = 16
		elseif p0.x + 1 == p1.x then
			param2 = 12
		elseif p0.z - 1 == p1.z then
			param2 = 8
		elseif p0.z + 1 == p1.z then
			param2 = 4
		end

		return minetest.item_place(itemstack, placer, pointed_thing, param2)
	end,

	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 5,
})
minetest.register_node(modname .. ":metal_pipe_tee", {
	description = "Metal Pipe Tee",
	tiles = {
		"z_metal_block_smooth.png",
		"z_metal_block_smooth.png",
		"z_metal_pipe.png",
		"z_metal_pipe.png",
		"z_metal_pipe.png",
		"z_metal_pipe.png",
	},
	drawtype = "nodebox",
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	light_source = 0,
	sunlight_propagates = true,
	groups = { pickaxey=3, deco_block=1 },
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.125, 0.125, -0.4375, 0.125}, -- Base
			{-0.0625, -0.4375, -0.0625, 0.0625, 0.4375, 0.0625}, -- Rod
			{-0.125, 0.5, -0.125, 0.125, 0.4375, 0.125}, -- Top
			{-0.0625, -0.0625, 0.0625, 0.0625, 0.0625, 0.4375}, -- Angled Rod
			{-0.125, -0.125, 0.5, 0.125, 0.125, 0.4375}, -- Angled End
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}, -- Base
			{-0.125, -0.125, 0.125, 0.125, 0.125, 0.5}, -- Angled
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}, -- Base
			{-0.125, -0.125, 0.125, 0.125, 0.125, 0.5}, -- Angled
		},
	},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" or not placer or not placer:is_player() then
			return itemstack
		end

		local p0 = pointed_thing.under
		local p1 = pointed_thing.above
		local param2 = 0

		local placer_pos = placer:get_pos()
		if placer_pos then
			local dir = {
				x = p1.x - placer_pos.x,
				y = p1.y - placer_pos.y,
				z = p1.z - placer_pos.z
			}
			param2 = minetest.dir_to_facedir(dir)
		end

		if p0.y - 1 == p1.y then
			param2 = 20
		elseif p0.x - 1 == p1.x then
			param2 = 16
		elseif p0.x + 1 == p1.x then
			param2 = 12
		elseif p0.z - 1 == p1.z then
			param2 = 8
		elseif p0.z + 1 == p1.z then
			param2 = 4
		end

		return minetest.item_place(itemstack, placer, pointed_thing, param2)
	end,

	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 5,
})


minetest.register_craftitem(modname .. ":metal_lump", {
    description = "Metal Lump",
    inventory_image = "z_metal_lump.png"
})

minetest.register_craftitem(modname .. ":metal_ingot", {
    description = "Metal Ingot",
    inventory_image = "z_metal_ingot.png"
})



local metal_block = modname .. ":metal_block"
local metal_ingot = modname .. ":metal_ingot"
local metal_lump = modname .. ":metal_lump"
minetest.register_craft({
	output = metal_block,
	recipe = {
		{metal_ingot, metal_ingot, metal_ingot},
		{metal_ingot, metal_ingot, metal_ingot},
		{metal_ingot, metal_ingot, metal_ingot}
	}
})

minetest.register_craft({
	output = metal_ingot .. " 9",
    type = "shapeless",
	recipe = {
		metal_block
	},
})

minetest.register_craft({
	type = "cooking",
	output = metal_ingot,
	recipe = metal_lump,
	cooktime = 10,
})
