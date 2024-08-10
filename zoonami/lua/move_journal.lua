-- Move Journal

-- Local namespace
local move_journal = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local move_stats = dofile(mod_path .. "/lua/move_stats.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Craft Item
minetest.register_craftitem(modname .. ":zoonami_move_journal", {
	description = "Zoonami Move Journal",
	inventory_image = "zoonami_move_journal.png",
	groups = {book = 1},
	stack_max = 1,
	on_secondary_use = function (itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end
		move_journal.formspec(user)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		if not placer or not placer:is_player() then return end
		local node = minetest.get_node_or_nil(pointed_thing.under)
		local def = node and minetest.registered_nodes[node.name] or {}
		if def.on_rightclick then
			return def.on_rightclick(pointed_thing.under, node, placer, itemstack)
		else
			move_journal.formspec(placer)
		end
	end,
})

-- Callback from fsc mod
function move_journal.fsc_callback(player, fields)
	if not fields.quit then
		move_journal.formspec(player, fields)
	end
end

-- Moves
move_journal.moves = {}
for k, v in pairs(move_stats) do
	if k ~= "skip" and k ~= "tooltip" then
		table.insert(move_journal.moves, v.asset_name)
	end
end
table.sort(move_journal.moves)

-- Navigation Header
function move_journal.navigation(meta)
	local formspec = fs.font_style("button,image_button,label,field", "mono,bold", "*1", "#000000")..
		fs.font_style("textarea", "mono", "*0.94", "#000000")..
		fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
		fs.box(2.7, 9.2, 4.5, 0.8, "#333333FF")..
		fs.box(2.75, 9.25, 4.4, 0.7, "#FFFFFFFF")..
		fs.field(2.8, 9.3, 4.3, 0.6, "search", "", "")..
		"field_close_on_enter[search;false]"..
		fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")..
		fs.image_button(0, 8.5, 10, 0.5, "zoonami_blank", "index", "Page "..meta.page.." of "..#move_journal.moves)..
		fs.box(0, 8.5, 10, 0.5, "#00000000")
	return formspec
end

-- Stats Page
function move_journal.stats(move)
	local formspec = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "title", move.name)..
		fs.box(0, 0.5, 10, 0.5, "#00000000")..
		fs.textarea(1, 1, 8, 3, move_stats.tooltip(move.asset_name))
	return formspec
end

-- Shows formspec
function move_journal.formspec(player, fields)
	local player_name = player:get_player_name()
	local stack = player:get_wielded_item()
	local meta = minetest.deserialize(stack:get_meta():get_string("meta"))
	fields = fields or {}
	local search = fields.search and string.lower(fields.search):gsub(" ", "_")
	fields.search = nil
	fields.move_animation = nil
	fields.key_enter = nil
	fields.key_enter_field = nil
	local field_key = next(fields) or ""
	
	-- Play sound
	if field_key ~= "" or search then
		minetest.sound_play("zoonami_guide_book_page_turn", {to_player = player_name, gain = 1}, true)
	end
	
	-- Initialize metadata if nil or if page is non-existent
	if meta == nil then
		meta = {page = 1}
	end
	
	-- Handle button presses
	if field_key == "next" then
		meta.page = meta.page + 1
	elseif field_key == "back" then
		meta.page = meta.page - 1
	elseif search and search ~= "" then
		local result = table.indexof(move_journal.moves, search)
		meta.page = result > 0 and result or meta.page
	end
	
	-- Handle current page
	if meta.page > #move_journal.moves then
		meta.page = 1
	elseif meta.page < 1 then
		meta.page = #move_journal.moves
	end
	
	-- Move
	local asset_name = move_journal.moves[meta.page]
	local move = move_stats[asset_name]
	
	-- Show formspec
	local formspec = fs.header(10, 10, "false", "#00000000")..
		fs.button_style(1, 8)..
		fs.background(0, 0, 10, 10, "zoonami_move_journal_blank_page.png")..
		move_journal.navigation(meta)..
		fs.image(0.9, 4.25, 4, 4, "zoonami_grassland_background.png")..
		fs.animation(0.9, 4.25, 4, 4, "move_animation", "zoonami_player_"..move.asset_name.."_animation.png", move.animation_frames, move.frame_length, 1)..
		fs.image(5.1, 4.25, 4, 4, "zoonami_grassland_background.png")..
		fs.animation(5.1, 4.25, 4, 4, "move_animation", "zoonami_enemy_"..move.asset_name.."_animation.png", move.animation_frames, move.frame_length, 1)..
		move_journal.stats(move)
	
	stack:get_meta():set_string("meta", minetest.serialize(meta))
	player:set_wielded_item(stack)
	fsc.show(player_name, formspec, false, move_journal.fsc_callback)
end
