-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local sounds = dofile(mod_path .. "/lua/sounds.lua")

-- Berry Bushes
local function register_berry_bush(name, asset_name)
	minetest.register_node(modname .. ":zoonami_"..asset_name.."_berry_bush_1", {
		description = name.." Berry Bush",
		drawtype = "plantlike",
		visual_scale = 1,
		waving = 1,
		tiles = {"zoonami_"..asset_name.."_berry_bush_1.png"},
		inventory_image = "zoonami_"..asset_name.."_berry_bush_2.png",
		wield_image = "zoonami_"..asset_name.."_berry_bush_2.png",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		groups = {
			attached_node = 1,
			dig_by_piston = 1,
			dig_generic = 2,
			flammable = 3,
			flora = 1,
			handy = 1,
			snappy = 3,
			zoonami_berry_bush = 1,
		},
		sounds = sounds.leaves,
		selection_box = {
			type = "fixed",
			fixed = {-0.35, -0.5, -0.35, 0.35, 0.35, 0.35},
		},
		on_timer = function(pos, elapsed)
			local node = minetest.get_node(pos)
			local berry_bush_name = node.name:gsub("_1", "")
			minetest.set_node(pos, {name = berry_bush_name.."_2"})
		end,
		on_construct = function(pos)
			local timer = minetest.get_node_timer(pos)
			timer:start(math.random(480, 780))
		end,
		on_destruct = function(pos)
			minetest.get_node_timer(pos):stop()
		end,
		_mcl_blast_resistance = 0.2,
		_mcl_hardness = 0.2,
	})
	minetest.register_node(modname .. ":zoonami_"..asset_name.."_berry_bush_2", {
		description = name.." Berry Bush Stage 2",
		drawtype = "plantlike",
		visual_scale = 1,
		waving = 1,
		tiles = {"zoonami_"..asset_name.."_berry_bush_2.png"},
		inventory_image = "zoonami_"..asset_name.."_berry_bush_2.png",
		wield_image = "zoonami_"..asset_name.."_berry_bush_2.png",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		groups = {
			attached_node = 1,
			dig_by_piston = 1,
			dig_generic = 2,
			flammable = 3,
			flora = 1,
			handy = 1,
			not_in_creative_inventory = 1,
			snappy = 3,
		},
		sounds = sounds.leaves,
		selection_box = {
			type = "fixed",
			fixed = {-0.35, -0.5, -0.35, 0.35, 0.35, 0.35},
		},
		drop = {
			items = {
				{items = {modname .. ":zoonami_"..asset_name.."_berry"}},
				{items = {modname .. ":zoonami_"..asset_name.."_berry_bush_1"}}
			}
		},
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			if not player or not player:is_player() then return end
			local player_name = player:get_player_name()
			if minetest.is_protected(pos, player_name) then
				return
			end
			local newnode = (modname .. ":zoonami_"..asset_name.."_berry_bush_1")
			minetest.swap_node(pos, {name = newnode})
			local timer = minetest.get_node_timer(pos)
			timer:start(math.random(480, 780))
			local inv = player:get_inventory()
			local items = ItemStack(modname .. ":zoonami_"..asset_name.."_berry")
			minetest.after(0, function() 
				local leftover = inv:add_item("main", items)
				if leftover:get_count() > 0 then
					minetest.add_item(player:get_pos(), leftover)
				end
			end)
		end,
		_mcl_blast_resistance = 0.2,
		_mcl_hardness = 0.2,
	})
end

-- Berry Bushes
register_berry_bush("Blue", "blue")
register_berry_bush("Red", "red")
register_berry_bush("Orange", "orange")
register_berry_bush("Green", "green")

-- Flowers
local function register_flower(name, asset_name)
	minetest.register_node(modname .. ":zoonami_"..asset_name, {
		description = name,
		drawtype = "plantlike",
		inventory_image = "zoonami_"..asset_name..".png",
		tiles = {"zoonami_"..asset_name..".png"},
		paramtype = "light",
		visual_scale = 1,
		waving = 1,
		sunlight_propagates = true,
		walkable = false,
		groups = {
			attached_node = 1,
			dig_by_piston = 1,
			dig_generic = 3,
			flammable = 3,
			flora = 1,
			flower = 1,
			handy = 1,
			snappy = 3,
		},
		sounds = sounds.leaves,
		selection_box = {
			type = "fixed",
			fixed = {-0.3, -0.5, -0.3, 0.3, -0.2, 0.3},
		},
		_mcl_blast_resistance = 0.2,
		_mcl_hardness = 0.2,
	})
end

-- Flowers
register_flower("Daisy", "daisy")
register_flower("Blue Tulip", "blue_tulip")
register_flower("Zinnia", "zinnia")
register_flower("Sunflower", "sunflower")
register_flower("Tiger Lily", "tiger_lily")

-- Mapgen Nodes
local function register_mapgen_node(name, asset_name)
	minetest.register_node(modname .. ":zoonami_"..asset_name, {
		description = name,
		drawtype = "airlike",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		drop = "",
		on_blast = function() end,
		groups = {not_in_creative_inventory = 1},
	})
end

-- Mapgen Nodes
register_mapgen_node("Monster Mapgen Spawn", "monster_mapgen_spawn")
register_mapgen_node("NPC Mapgen Spawn", "npc_mapgen_spawn")
register_mapgen_node("Village Path", "village_path")

-- Gravel Path
minetest.register_node(modname .. ":zoonami_gravel_path", {
	description = "Gravel Path",
	tiles = {"zoonami_gravel_path.png"},
	is_ground_content = false,
	groups = {
		crumbly = 2,
		dig_dirt = 3,
		handy = 1,
		shovely = 1,
		zoonami_path = 1,
	},
	sounds = sounds.gravel,
	_mcl_blast_resistance = 0.6,
	_mcl_hardness = 0.6,
})

-- Dirt Path
minetest.register_node(modname .. ":zoonami_dirt_path", {
	description = "Dirt Path",
	tiles = {"zoonami_dirt_path.png"},
	is_ground_content = false,
	groups = {
		crumbly = 2,
		dig_dirt = 3,
		handy = 1,
		shovely = 1,
		zoonami_path = 1,
	},
	sounds = sounds.gravel,
	_mcl_blast_resistance = 0.6,
	_mcl_hardness = 0.6,
})

-- White Brick
minetest.register_node(modname .. ":zoonami_white_brick", {
	description = "White Brick",
	tiles = {"zoonami_white_brick.png"},
	is_ground_content = false,
	groups = {
		cracky = 2,
		dig_stone = 2,
		pickaxey = 1,
	},
	sounds = sounds.stone,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})

-- Tile Nodes
local function register_tile_node(name, asset_name)
	minetest.register_node(modname .. ":zoonami_"..asset_name, {
		description = name,
		tiles = {"zoonami_"..asset_name..".png"},
		is_ground_content = false,
		groups = {
			cracky = 2,
			dig_stone = 2,
			pickaxey = 1,
		},
		sounds = sounds.stone,
		_mcl_blast_resistance = 6,
		_mcl_hardness = 1.5,
	})
end

-- Tile nodes
register_tile_node("Blue Tile", "blue_tile")
register_tile_node("Yellow Tile", "yellow_tile")
register_tile_node("Orange Tile", "orange_tile")
register_tile_node("Red Tile", "red_tile")
register_tile_node("White Tile", "white_tile")

-- Countertop
minetest.register_node(modname .. ":zoonami_countertop", {
	description = "Countertop",
	tiles = {"zoonami_countertop_top.png", "zoonami_countertop_top.png", "zoonami_countertop_side.png"},
	is_ground_content = false,
	groups = {
		axey = 1,
		choppy = 2,
		dig_tree = 2,
		flammable = 2,
		handy = 1,
		oddly_breakable_by_hand = 2,
	},
	sounds = sounds.wood,
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
})

-- Countertop Cabinet
minetest.register_node(modname .. ":zoonami_countertop_cabinet", {
	description = "Countertop Cabinet",
	tiles = {"zoonami_countertop_top.png", "zoonami_countertop_top.png", "zoonami_countertop_side.png", "zoonami_countertop_side.png", "zoonami_countertop_side.png", "zoonami_countertop_cabinet.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {
		axey = 1,
		choppy = 2,
		dig_tree = 2,
		flammable = 2,
		handy = 1,
		oddly_breakable_by_hand = 2,
	},
	sounds = sounds.wood,
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
})

-- Countertop Drawers
minetest.register_node(modname .. ":zoonami_countertop_drawers", {
	description = "Countertop Drawers",
	tiles = {"zoonami_countertop_top.png", "zoonami_countertop_top.png", "zoonami_countertop_side.png", "zoonami_countertop_side.png", "zoonami_countertop_side.png", "zoonami_countertop_drawers.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {
		axey = 1,
		choppy = 2,
		dig_tree = 2,
		flammable = 2,
		handy = 1,
		oddly_breakable_by_hand = 2,
	},
	sounds = sounds.wood,
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
})

-- Plank Floor
minetest.register_node(modname .. ":zoonami_plank_floor", {
	description = "Plank Floor",
	tiles = {"zoonami_plank_floor.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {
		axey = 1,
		choppy = 2,
		dig_tree = 2,
		flammable = 2,
		handy = 1,
		oddly_breakable_by_hand = 2,
		zoonami_floor = 1,
	},
	sounds = sounds.wood,
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
})

-- Cube Floor
minetest.register_node(modname .. ":zoonami_cube_floor", {
	description = "Cube Floor",
	tiles = {"zoonami_cube_floor.png"},
	is_ground_content = false,
	groups = {
		axey = 1,
		choppy = 2,
		dig_tree = 2,
		flammable = 2,
		handy = 1,
		oddly_breakable_by_hand = 2,
		zoonami_floor = 1,
	},
	sounds = sounds.wood,
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
})

-- Bookshelf
minetest.register_node(modname .. ":zoonami_bookshelf", {
	description = "Bookshelf",
	tiles = {"zoonami_bookshelf_side.png", "zoonami_bookshelf_side.png", "zoonami_bookshelf_side.png", "zoonami_bookshelf_side.png", "zoonami_bookshelf_side.png", "zoonami_bookshelf_front.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {
		axey = 1,
		choppy = 2,
		dig_tree = 2,
		flammable = 2,
		handy = 1,
		oddly_breakable_by_hand = 2,
	},
	sounds = sounds.wood,
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
})

-- Wood Table
minetest.register_node(modname .. ":zoonami_wood_table", {
	description = "Wood Table",
	drawtype = "nodebox",
	tiles = {"zoonami_wood_table_top.png", "zoonami_node_blank.png", {name="zoonami_wood_table_side.png",backface_culling=false}},
	paramtype = "light",
	paramtype2 = "facedir",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {{-0.4375, -0.5, -0.4375, 0.4375, 0.5, 0.4375}},
	},
	is_ground_content = false,
	groups = {
		axey = 1,
		choppy = 2,
		dig_tree = 2,
		flammable = 2,
		handy = 1,
		oddly_breakable_by_hand = 2,
	},
	sounds = sounds.wood,
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
})

-- Wood Chair
minetest.register_node(modname .. ":zoonami_wood_chair", {
	description = "Wood Chair",
	drawtype = "mesh",
	mesh = "zoonami_wood_chair.obj",
	tiles = {"zoonami_wood_chair.png"},
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {
		axey = 1,
		choppy = 2,
		dig_tree = 2,
		flammable = 2,
		handy = 1,
		oddly_breakable_by_hand = 2,
	},
	sounds = sounds.wood,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})

-- NPC Wood Chair Timer
local function npc_wood_chair_timer(pos, elapsed)
	local above = vector.offset(pos, 0, 1, 0)
	local natural_light = minetest.get_natural_light(above, 0.5) or 0
	local artificial_light = minetest.get_node_light(above, 0) or 15
	if natural_light < 14 and natural_light > 0 and artificial_light >= 3 then
		return true
	else
		minetest.set_node(pos, {name = modname .. ":zoonami_npc_wood_chair_inactive"})
	end
end

-- NPC Wood Chair Active
minetest.register_node(modname .. ":zoonami_npc_wood_chair_active", {
	description = "NPC Wood Chair",
	drawtype = "mesh",
	mesh = "zoonami_wood_chair.obj",
	tiles = {"zoonami_wood_chair.png"},
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {
		axey = 1,
		choppy = 2,
		dig_tree = 2,
		flammable = 2,
		handy = 1,
		oddly_breakable_by_hand = 2,
	},
	sounds = sounds.wood,
	on_timer = npc_wood_chair_timer,
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(180.0)
		npc_wood_chair_timer(pos)
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if not player or not player:is_player() then return end
		local player_name = player:get_player_name()
		if npc_wood_chair_timer(pos) then
			minetest.chat_send_player(player_name, "NPC Chair Active")
		else
			minetest.chat_send_player(player_name, "NPC Chair Inactive")
		end
	end,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})

-- NPC Wood Chair Inactive
minetest.register_node(modname .. ":zoonami_npc_wood_chair_inactive", {
	description = "NPC Wood Chair",
	drawtype = "mesh",
	mesh = "zoonami_wood_chair.obj",
	tiles = {"zoonami_wood_chair.png"},
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {
		axey = 1,
		choppy = 2,
		dig_tree = 2,
		flammable = 2,
		handy = 1,
		not_in_creative_inventory = 1,
		oddly_breakable_by_hand = 2,
	},
	sounds = sounds.wood,
	drop = modname .. ":zoonami_npc_wood_chair_active",
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if not player or not player:is_player() then return end
		local player_name = player:get_player_name()
		minetest.chat_send_player(player_name, "NPC Chair Inactive")
	end,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})

-- Light
minetest.register_node(modname .. ":zoonami_light", {
	description = "Light",
	drawtype = "nodebox",
	tiles = {"zoonami_light_top.png", "zoonami_light_top.png", "zoonami_gray_side.png"},
	is_ground_content = false,
	paramtype = "light",
	light_source = 12,
	node_box = {
		type = "fixed",
		fixed = {{-0.2, 0.4375, -0.2, 0.2, 0.5, 0.2}},
	},
	groups = {
		choppy = 2,
		dig_generic = 3,
		handy = 1,
		oddly_breakable_by_hand = 3,
	},
	sounds = sounds.default,
	_mcl_blast_resistance = 0.2,
	_mcl_hardness = 0.2,
})

-- Pictures
local function register_picture(name, asset_name)
	minetest.register_node(modname .. ":zoonami_"..asset_name, {
		description = name,
		drawtype = "nodebox",
		inventory_image = "zoonami_"..asset_name..".png",
		tiles = {"zoonami_gray_side.png", "zoonami_gray_side.png", "zoonami_gray_side.png", "zoonami_gray_side.png", "zoonami_gray_side.png", "zoonami_"..asset_name..".png",},
		is_ground_content = false,
		sunlight_propagates = true,
		paramtype = "light",
		paramtype2 = "facedir",
		use_texture_alpha = "blend",
		node_box = {
			type = "fixed",
			fixed = {{-0.5, -0.5, 0.4375, 0.5, 0.5, 0.5}},
		},
		groups = {
			choppy = 3,
			dig_generic = 3,
			handy = 1,
			oddly_breakable_by_hand = 3,
		},
		sounds = sounds.default,
		_mcl_blast_resistance = 0.2,
		_mcl_hardness = 0.2,
	})
end

-- Pictures
register_picture("Beach Picture", "beach_picture")
register_picture("Flower Picture", "flower_picture")
register_picture("Island Picture", "island_picture")
register_picture("Sailboat Picture", "sailboat_picture")
register_picture("Springtime Picture", "springtime_picture")
register_picture("Starfish Picture", "starfish_picture")
register_picture("Tree Picture", "tree_picture")

-- Rugs
local function register_rug(name, asset_name)
	minetest.register_node(modname .. ":zoonami_"..asset_name, {
		description = name,
		drawtype = "nodebox",
		tiles = {"zoonami_"..asset_name.."_top.png", "zoonami_"..asset_name.."_side.png"},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {{-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}},
		},
		groups = {
			choppy = 3,
			dig_generic = 3,
			handy = 1,
			oddly_breakable_by_hand = 3,
		},
		sounds = sounds.default,
		_mcl_blast_resistance = 0.2,
		_mcl_hardness = 0.2,
	})
end

-- Rugs
register_rug("Blue Rug", "blue_rug")
register_rug("Yellow Rug", "yellow_rug")
register_rug("Orange Rug", "orange_rug")

-- Roofs
local function register_roof(name, asset_name)
	minetest.register_node(modname .. ":zoonami_"..asset_name, {
		description = name,
		tiles = {"zoonami_"..asset_name.."_top.png", "zoonami_"..asset_name.."_top.png", "zoonami_"..asset_name.."_side.png"},
		is_ground_content = false,
		groups = {
			cracky = 2,
			dig_stone = 2,
			pickaxey = 1,
		},
		sounds = sounds.stone,
		_mcl_blast_resistance = 6,
		_mcl_hardness = 1.5,
	})
	minetest.register_node(modname .. ":zoonami_"..asset_name.."_stairs", {
		description = name.." Stairs",
		drawtype = "nodebox",
		tiles = {"zoonami_"..asset_name.."_side.png"},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			}
		},
		groups = {
			cracky = 2,
			dig_stone = 2,
			pickaxey = 1,
		},
		sounds = sounds.stone,
		_mcl_blast_resistance = 6,
		_mcl_hardness = 1.5,
	})
end

-- Roofs
register_roof("Blue Roof", "blue_roof")
register_roof("Red Roof", "red_roof")

-- Crystal Glass
minetest.register_node(modname .. ":zoonami_crystal_glass", {
	description = "Crystal Glass",
	drawtype = "glasslike_framed_optional",
	tiles = {"zoonami_crystal_glass.png"},
	is_ground_content = false,
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "glasslikeliquidlevel",
	use_texture_alpha = "clip",
	groups = {
		cracky = 3,
		dig_glass = 1,
		glass = 1,
		handy = 1,
		oddly_breakable_by_hand = 3,
	},
	sounds = sounds.glass,
	_mcl_blast_resistance = 0.3,
	_mcl_hardness = 0.3,
})

-- Window
minetest.register_node(modname .. ":zoonami_window", {
	description = "Window",
	drawtype = "nodebox",
	inventory_image = "zoonami_window.png",
	tiles = {"zoonami_gray_side.png", "zoonami_gray_side.png", "zoonami_gray_side.png", "zoonami_gray_side.png", "zoonami_window.png"},
	is_ground_content = false,
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "facedir",
	use_texture_alpha = "blend",
	node_box = {
		type = "fixed",
		fixed = {{-0.5, -0.5, -0.03125, 0.5, 0.5, 0.03125}},
	},
	groups = {
		cracky = 3,
		dig_glass = 1,
		glass = 1,
		handy = 1,
		oddly_breakable_by_hand = 3,
	},
	sounds = sounds.glass,
	_mcl_blast_resistance = 0.3,
	_mcl_hardness = 0.3,
})

-- Door Hidden Top Node
minetest.register_node(modname .. ":zoonami_door_top", {
	description = "Door Top",
	drawtype = "airlike",
	paramtype = "light",
	paramtype2 = "facedir",
	buildable_to = false,
	diggable = false,
	floodable = false,
	pointable = false,
	sunlight_propagates = true,
	walkable = true,
	on_blast = function() end,
	is_ground_content = false,
	drop = "",
	groups = {not_in_creative_inventory = 1},
	collision_box = {
		type = "fixed",
		fixed = {-15/32, 13/32, -15/32, -13/32, 1/2, -13/32},
	},
})

-- Doors
local function register_door(name, asset_name)
	for i = 1, 2 do
		local node_def = {}
		node_def.description = name
		node_def.drawtype = "mesh"
		node_def.mesh = "zoonami_door.obj"
		node_def.inventory_image = "zoonami_"..asset_name.."_item.png"
		node_def.wield_image = "zoonami_"..asset_name.."_item.png"
		if i == 1 then
			node_def.tiles = {{name = "zoonami_"..asset_name..".png", backface_culling = true}}
		else
			node_def.tiles = {{name = "zoonami_"..asset_name.."_open.png", backface_culling = true}}
		end
		node_def.is_ground_content = false
		node_def.sunlight_propagates = true
		node_def.paramtype = "light"
		node_def.paramtype2 = "facedir"
		node_def.use_texture_alpha = "clip"
		node_def.collision_box = {
			type = "fixed",
			fixed = {{-0.5, -0.5, -0.5, 0.5, 1.5, -0.375}},
		}
		node_def.selection_box = {
			type = "fixed",
			fixed = {{-0.5, -0.5, -0.5, 0.5, 1.5, -0.375}},
		}
		node_def.on_blast = function() end
		node_def.groups = {
			axey = 1,
			choppy = 2,
			dig_tree = 2,
			door = 1,
			handy = 1,
			oddly_breakable_by_hand = 2,
		}
		if i == 2 then
			node_def.groups.not_in_creative_inventory = 1
		end
		node_def.sounds = sounds.wood
		if i == 1 then
			node_def.on_place = function(itemstack, placer, pointed_thing)
				local pos = pointed_thing.above
				local top_pos = vector.offset(pos, 0, 1, 0)
				local top_node = minetest.get_node_or_nil(top_pos)
				local top_def = top_node and minetest.registered_nodes[top_node.name]
				local player_name = placer:get_player_name() or ""
				if not top_def or not top_def.buildable_to then
					return itemstack
				elseif minetest.is_protected(pos, player_name) or minetest.is_protected(top_pos, player_name) then
					return itemstack
				elseif not minetest.is_creative_enabled(player_name) then
					itemstack:take_item()
				end
				local dir = placer and minetest.dir_to_facedir(placer:get_look_dir()) or 0
				minetest.set_node(pos, {name = modname .. ":zoonami_"..asset_name, param2 = dir})
				minetest.set_node(top_pos, {name = modname .. ":zoonami_door_top", param2 = dir})
				return itemstack
			end
		end
		node_def.after_dig_node = function(pos, node, meta, digger)
			local above = vector.offset(pos, 0, 1, 0)
			minetest.remove_node(above)
			minetest.check_for_falling(above)
		end
		node_def.on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			if not player or not player:is_player() then return end
			local player_name = player:get_player_name() or ""
			local top_pos = vector.offset(pos, 0, 1, 0)
			local param2 = 0
			if i == 1 then
				param2 = node.param2 + 1
			else
				param2 = node.param2 - 1
			end
			param2 = param2 > 3 and 0 or param2 < 0 and 3 or param2
			if i == 1 then
				minetest.set_node(pos, {name = modname .. ":zoonami_"..asset_name.."_open",	param2 = param2})
			else
				minetest.set_node(pos, {name = modname .. ":zoonami_"..asset_name,	param2 = param2})
			end
		end
		node_def._mcl_blast_resistance = 3
		node_def._mcl_hardness = 2
		if i == 1 then
			minetest.register_node(modname .. ":zoonami_"..asset_name, node_def)
		else
			minetest.register_node(modname .. ":zoonami_"..asset_name.."_open", node_def)
		end
	end
end

-- Doors
register_door("Classic Door", "classic_door")

-- Healer
minetest.register_node(modname .. ":zoonami_healer", {
	description = "Zoonami Healer",
	tiles = {"zoonami_healer_top.png", "zoonami_healer_bottom.png", "zoonami_healer_side.png", "zoonami_healer_side.png", "zoonami_healer_side.png", "zoonami_healer_front.png"},
	is_ground_content = false,
	paramtype2 = "facedir",
	groups = {
		cracky = 1,
		dig_stone = 2,
		pickaxey = 4,
	},
	sounds = sounds.stone,
	drop = "",
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if not player or not player:is_player() then return end
		local player_name = player:get_player_name()
		local meta = player:get_meta()
		for i = 1, 5 do
			local monster = meta:get_string("zoonami_monster_"..i)
			monster = minetest.deserialize(monster)
			monster = monster and monsters.load_stats(monster)
			if monster then
				monster.health = monster.max_health
				monster.energy = monster.max_energy
				meta:set_string("zoonami_monster_"..i, minetest.serialize(monsters.save_stats(monster)))
			end
		end
		minetest.chat_send_player(player_name, "Your monsters are fully healed.")
		minetest.sound_play("zoonami_healer", {to_player = player_name, gain = 0.5}, true)
	end,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})

-- Zeenite Ore
minetest.register_node(modname .. ":zoonami_zeenite_ore", {
	description = "Zeenite Ore",
	tiles = {"zoonami_stone.png^zoonami_zeenite_ore.png"},
	groups = {
		cracky = 3,
		dig_stone = 2,
		pickaxey = 4,
	},
	drop = modname .. ":zoonami_zeenite_lump",
	sounds = sounds.stone,
	_mcl_blast_resistance = 3,
	_mcl_hardness = 3,
})

-- Zeenite Ore (Dynamic Stone Texture)
minetest.register_on_mods_loaded(function()
	local stone_texture = minetest.registered_nodes["mapgen_stone"]
	if stone_texture then
		minetest.override_item(modname .. ":zoonami_zeenite_ore", {
			tiles = {stone_texture.tiles[1].."^zoonami_zeenite_ore.png"},
		})
	end
end)

-- Zeenite Block
minetest.register_node(modname .. ":zoonami_zeenite_block", {
	description = "Zeenite Block",
	tiles = {"zoonami_zeenite_block.png"},
	is_ground_content = false,
	groups = {
		cracky = 1,
		dig_stone = 2,
		pickaxey = 4,
	},
	sounds = sounds.stone,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 5,
})

-- Crystal Wall
minetest.register_node(modname .. ":zoonami_crystal_wall", {
	description = "Crystal Wall",
	tiles = {"zoonami_crystal_wall.png"},
	is_ground_content = false,
	groups = {
		cracky = 2,
		dig_stone = 2,
		pickaxey = 1,
	},
	sounds = sounds.glass,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
})

-- Crystal Fragment Block
minetest.register_node(modname .. ":zoonami_crystal_fragment_block", {
	description = "Crystal Fragment Block",
	drawtype = "plantlike",
	visual_scale = 1,
	tiles = {"zoonami_crystal_fragment.png"},
	paramtype = "light",
	is_ground_content = false,
	drop = modname .. ":zoonami_crystal_fragment 1",
	groups = {
		cracky = 2,
		dig_stone = 2,
		pickaxey = 1,
	},
	sounds = sounds.glass,
	on_blast = function() end,
	can_dig = function(pos, player)
		local nodes = minetest.find_node_near(pos, 6, modname .. ":zoonami_crystal_light_on", false)
		return not nodes and true or false
	end,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
})

-- Crystal Light Off
minetest.register_node(modname .. ":zoonami_crystal_light_off", {
	description = "Crystal Light Off",
	tiles = {"zoonami_crystal_light_off.png"},
	is_ground_content = false,
	drop = modname .. ":zoonami_crystal_wall",
	on_blast = function() end,
	groups = {
		cracky = 2,
		dig_stone = 2,
		not_in_creative_inventory = 1,
		pickaxey = 1,
	},
	sounds = sounds.glass,
	can_dig = function(pos, player)
		local nodes = minetest.find_node_near(pos, 6, modname .. ":zoonami_crystal_fragment_block", false)
		return not nodes and true or false
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if not player or not player:is_player() then return end
		local light_off = (modname .. ":zoonami_crystal_light_off")
		local light_on = (modname .. ":zoonami_crystal_light_on")
		local pos1 = vector.offset(pos, 0, 0, 0)
		local pos2 = vector.offset(pos, 1, 0, 0)
		local pos3 = vector.offset(pos, -1, 0, 0)
		local pos4 = vector.offset(pos, 0, 0, 1)
		local pos5 = vector.offset(pos, 0, 0, -1)
		local pos_list = {pos1, pos2, pos3, pos4, pos5}
		for i, v in ipairs(pos_list) do
			node = minetest.get_node(v)
			if node.name == modname .. ":zoonami_crystal_light_off" then
				minetest.swap_node(v, {name = light_on})
			elseif node.name == modname .. ":zoonami_crystal_light_on" then
				minetest.swap_node(v, {name = light_off})
			end
		end
	end,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
})

-- Crystal Light On
minetest.register_node(modname .. ":zoonami_crystal_light_on", {
	description = "Crystal Light On",
	tiles = {"zoonami_crystal_light_on.png"},
	is_ground_content = false,
	drop = modname .. ":zoonami_crystal_wall",
	on_blast = function() end,
	groups = {
		cracky = 2,
		dig_stone = 2,
		not_in_creative_inventory = 1,
		pickaxey = 1,
	},
	sounds = sounds.glass,
	can_dig = function(pos, player)
		local nodes = minetest.find_node_near(pos, 6, modname .. ":zoonami_crystal_fragment_block", false)
		return not nodes and true or false
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if not player or not player:is_player() then return end
		local light_off = (modname .. ":zoonami_crystal_light_off")
		local light_on = (modname .. ":zoonami_crystal_light_on")
		local pos1 = vector.offset(pos, 0, 0, 0)
		local pos2 = vector.offset(pos, 1, 0, 0)
		local pos3 = vector.offset(pos, -1, 0, 0)
		local pos4 = vector.offset(pos, 0, 0, 1)
		local pos5 = vector.offset(pos, 0, 0, -1)
		local pos_list = {pos1, pos2, pos3, pos4, pos5}
		for i, v in ipairs(pos_list) do
			node = minetest.get_node(v)
			if node.name == modname .. ":zoonami_crystal_light_off" then
				minetest.swap_node(v, {name = light_on})
			elseif node.name == modname .. ":zoonami_crystal_light_on" then
				minetest.swap_node(v, {name = light_off})
			end
		end
	end,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
})

-- Excavation Core
minetest.register_node(modname .. ":zoonami_excavation_core", {
	description = "Excavation Core",
	tiles = {"zoonami_excavation_core.png"},
	is_ground_content = false,
	drop = "",
	groups = {
		dig_immediate = 2,
		not_in_creative_inventory = 1,
	},
	sounds = sounds.stone,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if not digger or not digger:is_player() then
			return
		end
		local inv = digger:get_inventory()
		local pos1 = vector.subtract(pos, 5)
		local pos2 = vector.add(pos, 5)
		local all_debris = minetest.find_nodes_in_area(pos1, pos2, modname .. ":zoonami_excavation_debris", false)
		for i = 1, #all_debris do
			local check_pos = vector.offset(all_debris[i], 0, 1, 0)
			local node = minetest.get_node(check_pos)
			node = minetest.registered_nodes[node.name] or {}
			if node.liquidtype ~= "none" or node.light_source ~= 0 or node.name == "air" or node.name == modname .. ":zoonami_excavation_debris" then
				minetest.set_node(all_debris[i], {name = "air"})
			else
				minetest.bulk_set_node(all_debris, {name = "air"})
				return
			end
		end
		local item_pool = {}
		item_pool[1] = {name = modname .. ":zoonami_blue_berry", count = math.random(4, 12), chance = math.random(1, 2)}
		item_pool[2] = {name = modname .. ":zoonami_red_berry", count = math.random(4, 12), chance = math.random(1, 2)}
		item_pool[3] = {name = modname .. ":zoonami_orange_berry", count = math.random(4, 12), chance = math.random(1, 2)}
		item_pool[4] = {name = modname .. ":zoonami_green_berry", count = math.random(4, 12), chance = math.random(1, 2)}
		item_pool[5] = {name = modname .. ":zoonami_blue_berry_bush_1", count = 1, chance = math.random(1, 15)}
		item_pool[6] = {name = modname .. ":zoonami_red_berry_bush_1", count = 1, chance = math.random(1, 15)}
		item_pool[7] = {name = modname .. ":zoonami_orange_berry_bush_1", count = 1, chance = math.random(1, 15)}
		item_pool[8] = {name = modname .. ":zoonami_green_berry_bush_1", count = 1, chance = math.random(1, 15)}
		item_pool[9] = {name = modname .. ":zoonami_mystery_egg", count = 1, chance = math.random(1, 15)}
		item_pool[10] = {name = modname .. ":zoonami_mystery_move_book", count = math.random(1, 3), chance = 1}
		item_pool[11] = {name = modname .. ":zoonami_golden_jelly", count = 1, chance = math.random(1, 2000)}
		for i = 1, #item_pool do
			if item_pool[i].chance == 1 then
				local item = ItemStack(item_pool[i].name.." "..item_pool[i].count)
				minetest.after(0, function()
					local leftover = inv:add_item("main", item)
					if leftover:get_count() > 0 then
						minetest.add_item(pos, leftover)
					end
				end)
			end
		end
	end,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
})

-- Excavation Debris
minetest.register_node(modname .. ":zoonami_excavation_debris", {
	description = "Excavation Debris",
	tiles = {"zoonami_excavation_debris.png"},
	is_ground_content = false,
	drop = "",
	groups = {
		dig_immediate = 2,
		not_in_creative_inventory = 1,
	},
	sounds = sounds.stone,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local core_pos = minetest.find_node_near(pos, 8, modname .. ":zoonami_excavation_core", false)
		if not core_pos then return end
		local pos1 = vector.subtract(core_pos, 5)
		local pos2 = vector.add(core_pos, 5)
		local nodes = {modname .. ":zoonami_excavation_core", modname .. ":zoonami_excavation_debris"}
		local all_debris = minetest.find_nodes_in_area(pos1, pos2, nodes, false)
		minetest.bulk_set_node(all_debris, {name = "air"})
	end,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
})

-- Mystery Egg
minetest.register_node(modname .. ":zoonami_mystery_egg", {
	description = "Mystery Egg",
	drawtype = "mesh",
	mesh = "zoonami_mystery_egg.obj",
	tiles = {"zoonami_mystery_egg.png"},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	collision_box = {
		type = "fixed",
		fixed = {{-0.3, -0.5, -0.3, 0.3, 0.3, 0.3}},
	},
	selection_box = {
		type = "fixed",
		fixed = {{-0.3, -0.5, -0.3, 0.3, 0.3, 0.3}},
	},
	groups = {
		cracky = 3,
		dig_stone = 1,
		handy = 3,
		oddly_breakable_by_hand = 3,
	},
	on_timer = function(pos, elapsed)
		minetest.set_node(pos, {name = "air"})
		local monster_pool = {"brontore", "rampede", "ruptore"}
		local monster = monster_pool[math.random(#monster_pool)]
		local def = minetest.registered_entities[modname .. ":zoonami_"..monster]
		local spawn_pos = vector.offset(pos, 0, -def.collisionbox[2], 0)
		local prisma_chance = tonumber(minetest.settings:get("zoonami_prisma_chance") or 1500)
		local staticdata = nil
		if math.random(prisma_chance) == 1 then
			staticdata = {prisma_id = 1}
		end
		minetest.add_entity(pos, modname .. ":zoonami_"..monster, minetest.serialize(staticdata))
	end,
	preserve_metadata = function(pos, oldnode, oldmeta, drops)
		local meta = drops[1]:get_meta()
		meta:set_int("light", oldmeta.light or 0)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local stack_meta = itemstack:get_meta()
		local light = stack_meta:get_int("light")
		meta:set_int("light", light > 0 and light or math.random(1, 14))
	end,
	on_destruct = function(pos)
		minetest.get_node_timer(pos):stop()
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if not player or not player:is_player() then return end
		local player_name = player:get_player_name()
		local meta = minetest.get_meta(pos)
		local light = meta:get_int("light")
		local current_light = minetest.get_node_light(pos) or 0
		local timer = minetest.get_node_timer(pos)
		if minetest.is_protected(pos, player_name) then
			return
		end
		if light == current_light and not timer:is_started() then
			timer:start(5)
			minetest.chat_send_player(player_name, "The egg is hatching!")
		elseif light > current_light then
			minetest.chat_send_player(player_name, "The egg needs more light to hatch.")
		elseif light < current_light then
			minetest.chat_send_player(player_name, "The egg needs less light to hatch.")
		end
	end,
	sounds = sounds.stone,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
})

-- Crystal Water Source
minetest.register_node(modname .. ":zoonami_crystal_water_source", {
	description = "Crystal Water Source",
	drawtype = "liquid",
	tiles = {
		{
			name = "zoonami_crystal_water_source_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 4.0,},
		},
		{
			name = "zoonami_crystal_water_source_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 4.0,},
		},
	},
	paramtype = "light",
	use_texture_alpha = "blend",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = modname .. ":zoonami_crystal_water_flowing",
	liquid_alternative_source = modname .. ":zoonami_crystal_water_source",
	liquid_viscosity = 1,
	post_effect_color = "#5DD3E277",
	groups = {
		cools_lava = 1,
		liquid = 3,
		water = 3,
	},
	sounds = sounds.water,
})

-- Crystal Water Flowing
minetest.register_node(modname .. ":zoonami_crystal_water_flowing", {
	description = "Crystal Water Flowing",
	drawtype = "flowingliquid",
	tiles = {"zoonami_crystal_water_source.png"},
	special_tiles = {
		{
			name = "zoonami_crystal_water_flowing_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 1.2,},
		},
		{
			name = "zoonami_crystal_water_flowing_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 1.2,},
		},
	},
	paramtype = "light",
	paramtype2 = "flowingliquid",
	use_texture_alpha = "blend",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = modname .. ":zoonami_crystal_water_flowing",
	liquid_alternative_source = modname .. ":zoonami_crystal_water_source",
	liquid_viscosity = 1,
	post_effect_color = "#5DD3E277",
	groups = {
		cools_lava = 1,
		liquid = 3,
		not_in_creative_inventory = 1,
		water = 3,
	},
	sounds = sounds.water,
})
