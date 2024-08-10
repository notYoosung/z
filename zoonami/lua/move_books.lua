-- Creates all of the move books

-- Local namespace
local move_books = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local move_stats = dofile(mod_path .. "/lua/move_stats.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- List of all move books
move_books.list = {
	[1] = {name = "Barrier", asset_name = "barrier"},
	[2] = {name = "Boil", asset_name = "boil"},
	[3] = {name = "Diced", asset_name = "diced"},
	[4] = {name = "Flash Fire", asset_name = "flash_fire"},
	[5] = {name = "Force Field", asset_name = "force_field"},
	[6] = {name = "Ground Pound", asset_name = "ground_pound"},
	[7] = {name = "Guard", asset_name = "guard"},
	[8] = {name = "Inferno", asset_name = "inferno"},
	[9] = {name = "Pinpoint", asset_name = "pinpoint"},
	[10] = {name = "Rage", asset_name = "rage"},
	[11] = {name = "Refresh", asset_name = "refresh"},
	[12] = {name = "Rest", asset_name = "rest"},
	[13] = {name = "Restore", asset_name = "restore"},
	[14] = {name = "Slice", asset_name = "slice"},
	[15] = {name = "Split", asset_name = "split"},
	[16] = {name = "Swirl", asset_name = "swirl"},
	[17] = {name = "Thorns", asset_name = "thorns"},
	[18] = {name = "Toxin", asset_name = "toxin"},
	[19] = {name = "Ultrasonic", asset_name = "ultrasonic"},
	[20] = {name = "Void", asset_name = "void"},
	[21] = {name = "Whirlwind", asset_name = "whirlwind"},
}

-- Callback from fsc mod
function move_books.fsc_callback(player, fields, context)
	if not fields.quit then
		move_books.receive_fields(player, fields, context)
		return true
	end
end

-- Handle button presses
function move_books.receive_fields(player, fields, context)
	local field_key = next(fields) or ""
	local monster_id = tonumber(string.match(field_key, "^monster#([12345])$"))
	if monster_id then
		local player_name = player:get_player_name()
		local meta = player:get_meta()
		local monster = meta:get_string("zoonami_monster_"..monster_id)
		monster = minetest.deserialize(monster)
		if monster then
			local base_stats = monsters.stats[monster.asset_name]
			local can_learn_move = false
			local already_learned_move = false
			for ii = 1, #base_stats.taught_moves do
				if base_stats.taught_moves[ii] == context.asset_name then
					can_learn_move = true
					break
				end
			end
			for ii = 1, #monster.move_pool do
				if monster.move_pool[ii] == context.asset_name then
					already_learned_move = true
					break
				end
			end
			if can_learn_move and not already_learned_move then
				local stack = ItemStack(modname .. ":zoonami_move_book_"..context.asset_name.." 1")
				local inv = player:get_inventory()
				local itemstack = inv:remove_item("main", stack)
				if not itemstack:is_empty() then
					table.insert(monster.move_pool, context.asset_name)
					meta:set_string("zoonami_monster_"..monster_id, minetest.serialize(monster))
					minetest.sound_play("zoonami_level_up", {to_player = player_name, gain = 1}, true)
				end
			end
		end
	end
end

-- Show formspec
function move_books.show_formspec(itemstack, player, context)
	local player_name = player:get_player_name()
	local meta = player:get_meta()
	local monster_slots = ""
	local monster_slots_row = 0
	for i = 1, 5 do
		local monster = meta:get_string("zoonami_monster_"..i)
		monster = minetest.deserialize(monster)
		monster = monster and monsters.load_stats(monster)
		if monster then
			local can_learn_move = false
			local already_learned_move = false
			for ii = 1, #monster.base.taught_moves do
				if monster.base.taught_moves[ii] == context.asset_name then
					can_learn_move = true
					break
				end
			end
			for ii = 1, #monster.move_pool do
				if monster.move_pool[ii] == context.asset_name then
					already_learned_move = true
					break
				end
			end
			if can_learn_move and not already_learned_move then
				monster_slots = monster_slots..
					fs.button(1, 1.5 + (monster_slots_row * 1.5), 8, 1, "monster#"..i, (monster.nickname or monster.name).." Lvl "..monster.level.."\nH:"..monster.health.."/"..monster.max_health.."  E:"..monster.energy.."/"..monster.max_energy)..
					fs.image(1, 1.3 + (monster_slots_row * 1.5), 1.21, 1.21, "zoonami_"..monster.asset_name.."_front.png")
				monster_slots_row = monster_slots_row + 1
			end
		end
	end
	if monster_slots == "" then
		monster_slots = fs.textarea(0.5, 1.5, 9, 9, "None of the monsters in your party can learn this move or the monsters have already learned it.")
	end
	local formspec = fs.header(10, 10, "false", "#00000000")..
		fs.background(0, 0, 10, 10, "zoonami_move_book_blank_page.png")..
		fs.font_style("button,image_button,label", "mono,bold", "*1", "#000000")..
		fs.font_style("textarea", "mono", "*0.94", "#000000")..
		fs.button_style(1, 8)..
		fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "basics", "Teach "..context.name)..
		fs.box(0, 0.5, 10, 0.5, "#00000000")..
		monster_slots
	fsc.show(player_name, formspec, context, move_books.fsc_callback)
end

-- Register move books
for i = 1, #move_books.list do
	local name = move_books.list[i].name
	local asset_name = move_books.list[i].asset_name
	local context = {}
	context.name = name
	context.asset_name = asset_name
	minetest.register_craftitem(modname .. ":zoonami_move_book_"..asset_name, {
		description = "Move Book: "..name,
		inventory_image = "zoonami_move_book.png",
		groups = {zoonami_move_book = 1},
		on_secondary_use = function (itemstack, user, pointed_thing)
			if not user or not user:is_player() then return end
			move_books.show_formspec(itemstack, user, context)
		end,
		on_place = function(itemstack, placer, pointed_thing)
			if not placer or not placer:is_player() then return end
			local node = minetest.get_node_or_nil(pointed_thing.under)
			local def = node and minetest.registered_nodes[node.name] or {}
			if def.on_rightclick then
				return def.on_rightclick(pointed_thing.under, node, placer, itemstack)
			else
				move_books.show_formspec(itemstack, placer, context)
			end
		end,
	})
end

-- Use Mystery Move Book
function move_books.use_mystery_move_book(itemstack, player, pointed_thing)
	local player_name = player:get_player_name()
	local inv = player:get_inventory()
	local random_book = move_books.list[math.random(#move_books.list)]
	local items = ItemStack(modname .. ":zoonami_move_book_"..random_book.asset_name)
	minetest.after(0, function() 
		local leftover = inv:add_item("main", items)
		if leftover:get_count() > 0 then
			minetest.add_item(player:get_pos(), leftover)
		end
	end)
	minetest.sound_play("zoonami_level_up", {to_player = player_name, gain = 1}, true)
	itemstack:take_item()
	return itemstack
end

-- Mystery Move Book
minetest.register_craftitem(modname .. ":zoonami_mystery_move_book", {
	description = "Mystery Move Book",
	inventory_image = "zoonami_mystery_move_book.png",
	on_secondary_use = function (itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end
		return move_books.use_mystery_move_book(itemstack, user, pointed_thing)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		if not placer or not placer:is_player() then return end
		local node = minetest.get_node_or_nil(pointed_thing.under)
		local def = node and minetest.registered_nodes[node.name] or {}
		if def.on_rightclick then
			return def.on_rightclick(pointed_thing.under, node, placer, itemstack)
		else
			return move_books.use_mystery_move_book(itemstack, placer, pointed_thing)
		end
	end,
})
