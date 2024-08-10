-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local fs = dofile(mod_path .. "/lua/formspec.lua")
local group = dofile(mod_path .. "/lua/group.lua")

-- Add crafting grid for compatible games that don't provide one
if minetest.get_modpath("exile_env_sounds") and minetest.get_modpath("sfinv") then
	sfinv.register_page(modname .. ":zoonami_crafting", {
		title = "Zoonami Crafting",
		get = function(self, player, context)
			local formspec = fs.image(4.75, 1.5, 1, 1, "sfinv_crafting_arrow.png", 1)..
				fs.list("current_player", "craft", 1.75, 0.5, 3, 3, 0, 1)..
				fs.list("current_player", "craftpreview", 5.75, 1.5, 1, 1, 0, 1)..
				fs.listring("current_player", "main")..
				fs.listring("current_player", "craft")
				
			return sfinv.make_formspec(player, context, formspec, true)
		end
	})
end

-- Jelly
local function register_jelly(asset_name)
	minetest.register_craft({
		output = modname .. ":zoonami_basic_"..asset_name.."_jelly 1",
		recipe = {
			{modname .. ":zoonami_"..asset_name.."_berry", modname .. ":zoonami_"..asset_name.."_berry"},
			{modname .. ":zoonami_"..asset_name.."_berry", modname .. ":zoonami_"..asset_name.."_berry"},
		}
	})

	minetest.register_craft({
		output = modname .. ":zoonami_improved_"..asset_name.."_jelly 1",
		recipe = {
			{modname .. ":zoonami_basic_"..asset_name.."_jelly", modname .. ":zoonami_basic_"..asset_name.."_jelly"},
			{modname .. ":zoonami_basic_"..asset_name.."_jelly", modname .. ":zoonami_basic_"..asset_name.."_jelly"},
		}
	})

	minetest.register_craft({
		output = modname .. ":zoonami_advanced_"..asset_name.."_jelly 1",
		recipe = {
			{modname .. ":zoonami_improved_"..asset_name.."_jelly", modname .. ":zoonami_improved_"..asset_name.."_jelly"},
			{modname .. ":zoonami_improved_"..asset_name.."_jelly", modname .. ":zoonami_improved_"..asset_name.."_jelly"},
		}
	})
end

-- Jelly
register_jelly("blue")
register_jelly("red")
register_jelly("orange")
register_jelly("green")

-- Candy
local function register_candy(asset_name)
	minetest.register_craft({
		output = modname .. ":zoonami_"..asset_name.."_candy 1",
		recipe = {
			{"", modname .. ":zoonami_improved_"..asset_name.."_jelly", ""},
			{modname .. ":zoonami_improved_"..asset_name.."_jelly", modname .. ":zoonami_"..asset_name.."_berry", modname .. ":zoonami_improved_"..asset_name.."_jelly"},
			{"", modname .. ":zoonami_improved_"..asset_name.."_jelly", ""},
		}
	})
end

-- Candy
register_candy("blue")
register_candy("red")
register_candy("orange")
register_candy("green")

-- Mystery Move Book
minetest.register_craft({
	output = modname .. ":zoonami_mystery_move_book 1",
	recipe = {
		{"group:zoonami_move_book", "group:zoonami_move_book", "group:zoonami_move_book"},
	}
})

-- Sanded Plank
minetest.register_craft({
	output = modname .. ":zoonami_sanded_plank 4",
	recipe = {
		{group.sand, group.wood},
	}
})

-- Stick
minetest.register_craft({
	output = modname .. ":zoonami_stick 2",
	recipe = {
		{modname .. ":zoonami_sanded_plank"},
	}
})

-- Plank Floor
minetest.register_craft({
	output = modname .. ":zoonami_plank_floor 1",
	recipe = {
		{modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank"},
	}
})

-- Cube Floor
minetest.register_craft({
	output = modname .. ":zoonami_cube_floor 2",
	recipe = {
		{modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank"},
		{modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank"},
	}
})

-- Bookshelf
minetest.register_craft({
	output = modname .. ":zoonami_bookshelf 1",
	recipe = {
		{group.wood, modname .. ":zoonami_sanded_plank", group.wood},
		{"group:book", "group:book", "group:book"},
		{group.wood, modname .. ":zoonami_sanded_plank", group.wood},
	}
})

-- Countertop
minetest.register_craft({
	output = modname .. ":zoonami_countertop 1",
	recipe = {
		{group.stone, group.stone},
		{modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank"},
	}
})

-- Countertop Cabinet
minetest.register_craft({
	output = modname .. ":zoonami_countertop_cabinet 1",
	recipe = {
		{modname .. ":zoonami_countertop"},
	}
})

-- Countertop Drawers
minetest.register_craft({
	output = modname .. ":zoonami_countertop_drawers 1",
	recipe = {
		{modname .. ":zoonami_countertop_cabinet"},
	}
})

-- Countertop (Crafting Loop)
minetest.register_craft({
	output = modname .. ":zoonami_countertop 1",
	recipe = {
		{modname .. ":zoonami_countertop_drawers"},
	}
})

-- Light
minetest.register_craft({
	output = modname .. ":zoonami_light 2",
	recipe = {
		{modname .. ":zoonami_zeenite_ingot"},
		{modname .. ":zoonami_crystal_glass"},
	}
})

-- Blue Rug
minetest.register_craft({
	output = modname .. ":zoonami_blue_rug 2",
	recipe = {
		{modname .. ":zoonami_cloth", modname .. ":zoonami_blue_tulip", modname .. ":zoonami_cloth"},
	}
})

-- Yellow Rug
minetest.register_craft({
	output = modname .. ":zoonami_yellow_rug 2",
	recipe = {
		{modname .. ":zoonami_cloth", modname .. ":zoonami_sunflower", modname .. ":zoonami_cloth"},
	}
})

-- Orange Rug
minetest.register_craft({
	output = modname .. ":zoonami_orange_rug 2",
	recipe = {
		{modname .. ":zoonami_cloth", modname .. ":zoonami_tiger_lily", modname .. ":zoonami_cloth"},
	}
})

-- Wood Table
minetest.register_craft({
	output = modname .. ":zoonami_wood_table 1",
	recipe = {
		{modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank"},
		{"group:stick", "", "group:stick"},
		{"group:stick", "", "group:stick"},
	}
})

-- Wood Chair
minetest.register_craft({
	output = modname .. ":zoonami_wood_chair 1",
	recipe = {
		{modname .. ":zoonami_sanded_plank", "", ""},
		{modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank"},
		{"group:stick", "", "group:stick"},
	}
})

-- NPC Wood Chair
minetest.register_craft({
	type = "shapeless",
	output = modname .. ":zoonami_npc_wood_chair_active 1",
	recipe = {modname .. ":zoonami_wood_chair", modname .. ":zoonami_100_zc_coin"}
})

-- Classic Door
minetest.register_craft({
	output = modname .. ":zoonami_classic_door 1",
	recipe = {
		{"group:stick", "group:stick"},
		{modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank"},
		{modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank"},
	}
})

-- Gravel Path
minetest.register_craft({
	output = modname .. ":zoonami_gravel_path 4",
	recipe = {
		{group.sand, group.sand},
		{group.stone, group.stone},
	}
})

-- Dirt Path
minetest.register_craft({
	output = modname .. ":zoonami_dirt_path 4",
	recipe = {
		{group.sand, group.sand},
		{group.soil, group.soil},
	}
})

-- White Brick
minetest.register_craft({
	output = modname .. ":zoonami_white_brick 8",
	recipe = {
		{group.stone, group.stone, group.stone},
		{group.stone, modname .. ":zoonami_daisy", group.stone},
		{group.stone, group.stone, group.stone},
	}
})

-- Tile Nodes
local function tile_node_craft(asset_name, flower_name)
	minetest.register_craft({
		output = modname .. ":zoonami_"..asset_name.." 4",
		recipe = {
			{"", group.stone, ""},
			{group.stone, flower_name, group.stone},
			{"", group.stone, ""},
		}
	})
end

-- Tile Nodes
tile_node_craft("blue_tile", modname .. ":zoonami_blue_tulip")
tile_node_craft("yellow_tile", modname .. ":zoonami_sunflower")
tile_node_craft("orange_tile", modname .. ":zoonami_tiger_lily")
tile_node_craft("red_tile", modname .. ":zoonami_zinnia")
tile_node_craft("white_tile", modname .. ":zoonami_daisy")

-- Blue Roof
minetest.register_craft({
	output = modname .. ":zoonami_blue_roof 8",
	recipe = {
		{group.stone, group.stone, group.stone},
		{group.stone, modname .. ":zoonami_blue_tulip", group.stone},
		{group.stone, group.stone, group.stone},
	}
})

-- Blue Roof Stairs
minetest.register_craft({
	output = modname .. ":zoonami_blue_roof_stairs 3",
	recipe = {
		{"", modname .. ":zoonami_blue_roof"},
		{modname .. ":zoonami_blue_roof", modname .. ":zoonami_blue_roof"},
	}
})

-- Red Roof
minetest.register_craft({
	output = modname .. ":zoonami_red_roof 8",
	recipe = {
		{group.stone, group.stone, group.stone},
		{group.stone, modname .. ":zoonami_zinnia", group.stone},
		{group.stone, group.stone, group.stone},
	}
})

-- Red Roof Stairs
minetest.register_craft({
	output = modname .. ":zoonami_red_roof_stairs 3",
	recipe = {
		{"", modname .. ":zoonami_red_roof"},
		{modname .. ":zoonami_red_roof", modname .. ":zoonami_red_roof"},
	}
})

-- Crystal Glass
minetest.register_craft({
	type = "cooking",
	output = modname .. ":zoonami_crystal_glass",
	recipe = modname .. ":zoonami_crystal_wall",
	cooktime = 3,
})

-- Window
minetest.register_craft({
	output = modname .. ":zoonami_window 8",
	recipe = {
		{modname .. ":zoonami_crystal_glass", modname .. ":zoonami_crystal_glass"},
		{modname .. ":zoonami_crystal_glass", modname .. ":zoonami_crystal_glass"},
	}
})

-- Door
minetest.register_craft({
	output = modname .. ":zoonami_door 1",
	recipe = {
		{modname .. ":zoonami_window", modname .. ":zoonami_window"},
		{modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank"},
		{modname .. ":zoonami_sanded_plank", modname .. ":zoonami_sanded_plank"},
	}
})

-- Cloth
minetest.register_craft({
	type = "shapeless",
	output = modname .. ":zoonami_cloth 1",
	recipe = {"group:stick", "group:wool", "group:stick"}
})

-- Paper
minetest.register_craft({
	output = modname .. ":zoonami_paper 1",
	recipe = {
		{group.sand, modname .. ":zoonami_sanded_plank"},
	}
})

-- Pictures
local function picture_craft(output, input)
	minetest.register_craft({
		output = output,
		recipe = input and {{input}} or {
			{"group:stick", "group:stick", "group:stick"},
			{"group:stick", modname .. ":zoonami_paper", "group:stick"},
			{"group:stick", "group:stick", "group:stick"},
		}
	})
end

-- Pictures
picture_craft(modname .. ":zoonami_beach_picture 1")
picture_craft(modname .. ":zoonami_flower_picture 1", modname .. ":zoonami_beach_picture")
picture_craft(modname .. ":zoonami_island_picture 1", modname .. ":zoonami_flower_picture")
picture_craft(modname .. ":zoonami_sailboat_picture 1", modname .. ":zoonami_island_picture")
picture_craft(modname .. ":zoonami_springtime_picture 1", modname .. ":zoonami_sailboat_picture")
picture_craft(modname .. ":zoonami_starfish_picture 1", modname .. ":zoonami_springtime_picture")
picture_craft(modname .. ":zoonami_tree_picture 1", modname .. ":zoonami_starfish_picture")
picture_craft(modname .. ":zoonami_beach_picture 1", modname .. ":zoonami_tree_picture")

-- Guide Book
minetest.register_craft({
	output = modname .. ":zoonami_guide_book 1",
	recipe = {
		{modname .. ":zoonami_paper"},
		{modname .. ":zoonami_paper"},
		{modname .. ":zoonami_paper"},
	}
})

-- Monster Journal
minetest.register_craft({
	output = modname .. ":zoonami_monster_journal 1",
	recipe = {
		{modname .. ":zoonami_guide_book"}
	}
})

-- Move Journal
minetest.register_craft({
	output = modname .. ":zoonami_move_journal 1",
	recipe = {
		{modname .. ":zoonami_monster_journal"}
	}
})

-- Guide Book (Crafting Loop)
minetest.register_craft({
	output = modname .. ":zoonami_guide_book 1",
	recipe = {
		{modname .. ":zoonami_move_journal"}
	}
})

-- Backpack
minetest.register_craft({
	output = modname .. ":zoonami_backpack 1",
	recipe = {
		{modname .. ":zoonami_cloth", modname .. ":zoonami_cloth", modname .. ":zoonami_cloth"},
		{modname .. ":zoonami_cloth", "", modname .. ":zoonami_cloth"},
		{modname .. ":zoonami_cloth", modname .. ":zoonami_cloth", modname .. ":zoonami_cloth"},
	}
})

-- Zeenite Ingot
minetest.register_craft({
	type = "cooking",
	output = modname .. ":zoonami_zeenite_ingot",
	recipe = modname .. ":zoonami_zeenite_lump",
})

-- Zeenite Ingot
minetest.register_craft({
	output = modname .. ":zoonami_zeenite_ingot 9",
	recipe = {
		{modname .. ":zoonami_zeenite_block"}
	}
})

-- Zeenite Block
minetest.register_craft({
	output = modname .. ":zoonami_zeenite_block 1",
	recipe = {
		{modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot"},
		{modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot"},
		{modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot"},
	}
})

-- Empty Pail
minetest.register_craft({
	output = modname .. ":zoonami_pail_empty",
	recipe = {
		{modname .. ":zoonami_zeenite_ingot", "", modname .. ":zoonami_zeenite_ingot"},
		{"", modname .. ":zoonami_zeenite_ingot", ""},
	}
})

-- Monster Repellent
minetest.register_craft({
	output = modname .. ":zoonami_monster_repellent",
	recipe = {
		{"group:stick"},
		{modname .. ":zoonami_zeenite_ingot"},
		{modname .. ":zoonami_zeenite_ingot"},
	}
})

-- Healer
minetest.register_craft({
	output = modname .. ":zoonami_healer 1",
	recipe = {
		{modname .. ":zoonami_window", modname .. ":zoonami_window", modname .. ":zoonami_window"},
		{modname .. ":zoonami_crystal_fragment", modname .. ":zoonami_crystal_fragment", modname .. ":zoonami_crystal_fragment"},
		{modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot"},
	}
})

-- Computer
minetest.register_craft({
	output = modname .. ":zoonami_computer 1",
	recipe = {
		{modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot"},
		{modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_window", modname .. ":zoonami_zeenite_ingot"},
		{modname .. ":zoonami_crystal_fragment", modname .. ":zoonami_crystal_fragment", modname .. ":zoonami_crystal_fragment"},
	}
})

-- Trading Machine
minetest.register_craft({
	output = modname .. ":zoonami_trading_machine 1",
	recipe = {
		{modname .. ":zoonami_computer", modname .. ":zoonami_zeenite_block", modname .. ":zoonami_computer"},
	}
})

-- Vending Machine
minetest.register_craft({
	output = modname .. ":zoonami_vending_machine 1",
	recipe = {
		{modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_zeenite_ingot"},
		{modname .. ":zoonami_zeenite_ingot", modname .. ":zoonami_window", modname .. ":zoonami_computer"},
		{modname .. ":zoonami_zeenite_ingot", "group:door", modname .. ":zoonami_zeenite_ingot"},
	}
})

-- Prism
minetest.register_craft({
	output = modname .. ":zoonami_prism 1",
	recipe = {
		{"", modname .. ":zoonami_crystal_glass", ""},
		{modname .. ":zoonami_crystal_glass", modname .. ":zoonami_crystal_glass", modname .. ":zoonami_crystal_glass"},
		{"", modname .. ":zoonami_crystal_glass", ""},
	}
})

-- 1000 ZC to 100 ZC
minetest.register_craft({
	output = modname .. ":zoonami_100_zc_coin 10",
	recipe = {
		{modname .. ":zoonami_1000_zc_coin"},
	}
})

-- 100 ZC to 10 ZC
minetest.register_craft({
	output = modname .. ":zoonami_10_zc_coin 10",
	recipe = {
		{modname .. ":zoonami_100_zc_coin"},
	}
})

-- 10 ZC to 1 ZC
minetest.register_craft({
	output = modname .. ":zoonami_1_zc_coin 10",
	recipe = {
		{modname .. ":zoonami_10_zc_coin"},
	}
})
