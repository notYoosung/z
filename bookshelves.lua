local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()

local F = minetest.formspec_escape
local C = minetest.colorize

local bookshelf_inv = minetest.settings:get_bool("mcl_bookshelf_inventories", true)


local drop_content = mcl_util.drop_items_from_meta_container("main")

local function on_blast(pos)
	local node = minetest.get_node(pos)
	drop_content(pos, node)
	minetest.remove_node(pos)
end

-- Simple protection checking functions
local function protection_check_move(pos, from_list, from_index, to_list, to_index, count, player)
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return 0
	else
		return count
	end
end

local function protection_check_put_take(pos, listname, index, stack, player)
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return 0
	elseif minetest.get_item_group(stack:get_name(), "book") ~= 0 or stack:get_name() == "mcl_enchanting:book_enchanted" then
		return stack:get_count()
	else
		return 0
	end
end

local function bookshelf_gui(pos, node, clicker)
	if not bookshelf_inv then return end
	local name = minetest.get_meta(pos):get_string("name")

	if name == "" then
		name = "Bookshelf"
	end

	local playername = clicker:get_player_name()

	minetest.show_formspec(playername,
		modname .. ":bookshelf_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z,
		table.concat({
			"formspec_version[4]",
			"size[11.75,10.425]",

			"label[0.375,0.375;" .. F(C(mcl_formspec.label_color, name)) .. "]",
			mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
			mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3, 0, "mcl_book_book_empty_slot.png"),
			"list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0.375,0.75;9,3;]",
			"label[0.375,4.7;" .. F(C(mcl_formspec.label_color, "Inventory")) .. "]",
			mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
			"list[current_player;main;0.375,5.1;9,3;9]",

			mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
			"list[current_player;main;0.375,9.05;9,1;]",
			"listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]",
			"listring[current_player;main]",
		})
	)
end

local function close_forms(pos)
	local players = minetest.get_connected_players()
	local formname = modname .. ":bookshelf_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
	for p = 1, #players do
		if vector.distance(players[p]:get_pos(), pos) <= 30 then
			minetest.close_formspec(players[p]:get_player_name(), formname)
		end
	end
end

-- Bookshelf
minetest.register_node(modname .. ":bookshelf", {
	description = "Bookshelf With Cardboard Boxes",
	tiles = { "mcl_books_bookshelf_top.png", "mcl_books_bookshelf_top.png", "z_bookshelf.png" },
	is_ground_content = false,
	groups = {
		handy = 1,
		axey = 1,
		deco_block = 1,
		material_wood = 1,
		flammable = 3,
		fire_encouragement = 30,
		fire_flammability = 20,
		container = 1
	},
	drop = modname .. ":bookshelf",
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 1.5,
	_mcl_hardness = 1.5,
	_mcl_silk_touch_drop = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 9 * 3)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		minetest.get_meta(pos):set_string("name", itemstack:get_meta():get_string("name"))
	end,
	allow_metadata_inventory_move = protection_check_move,
	allow_metadata_inventory_take = protection_check_put_take,
	allow_metadata_inventory_put = protection_check_put_take,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name() ..
			" moves stuff in bookshelf at " .. minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() ..
			" moves stuff to bookshelf at " .. minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() ..
			" takes stuff from bookshelf at " .. minetest.pos_to_string(pos))
	end,
	after_dig_node = drop_content,
	on_blast = on_blast,
	on_rightclick = bookshelf_gui,
	on_destruct = close_forms,
})

--[[minetest.register_craft({
	output = modname .. ":bookshelf",
	recipe = {
		{ "group:wood",     "group:wood",     "group:wood" },
		{ modname .. ":book", modname .. ":book", modname .. ":book" },
		{ "group:wood",     "group:wood",     "group:wood" },
	}
})--]]

minetest.register_craft({
	type = "fuel",
	recipe = modname .. ":bookshelf",
	burntime = 15,
})
