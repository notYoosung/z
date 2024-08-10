-- Monster Journal

-- Local namespace
local monster_journal = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local move_stats = dofile(mod_path .. "/lua/move_stats.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Settings
local settings = minetest.settings
local monster_journal_progression = settings:get_bool("zoonami_monster_journal_progression") ~= false

-- Craft Item
minetest.register_craftitem(modname .. ":zoonami_monster_journal", {
	description = "Zoonami Monster Journal",
	inventory_image = "zoonami_monster_journal.png",
	groups = {book = 1},
	stack_max = 1,
	on_secondary_use = function (itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end
		monster_journal.formspec(user)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		if not placer or not placer:is_player() then return end
		local node = minetest.get_node_or_nil(pointed_thing.under)
		local def = node and minetest.registered_nodes[node.name] or {}
		if def.on_rightclick then
			return def.on_rightclick(pointed_thing.under, node, placer, itemstack)
		else
			monster_journal.formspec(placer)
		end
	end,
})

-- Global function to add a monster to the player's tamed monster list
function zoonami.monster_journal_tamed_monster(player_meta, monster_asset_name)
	local tamed_monsters = player_meta:get_string("zoonami_tamed_monsters")
	tamed_monsters = minetest.deserialize(tamed_monsters) or {}
	tamed_monsters[monster_asset_name] = true
	tamed_monsters = minetest.serialize(tamed_monsters)
	player_meta:set_string("zoonami_tamed_monsters", tamed_monsters)
end

-- Callback from fsc mod
function monster_journal.fsc_callback(player, fields, context)
	if not fields.quit then
		monster_journal.formspec(player, fields, context)
	end
end

-- Monsters
monster_journal.monsters = {}
for k, v in pairs(monsters.stats) do
	table.insert(monster_journal.monsters, v.asset_name)
end
table.sort(monster_journal.monsters)

-- Navigation Header
function monster_journal.navigation(meta)
	local formspec = fs.font_style("button,image_button,label,field", "mono,bold", "*1", "#000000")..
		fs.font_style("textarea", "mono", "*0.94", "#000000")..
		fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
		fs.box(2.7, 9.2, 4.5, 0.8, "#333333FF")..
		fs.box(2.75, 9.25, 4.4, 0.7, "#FFFFFFFF")..
		fs.field(2.8, 9.3, 4.3, 0.6, "search", "", "")..
		"field_close_on_enter[search;false]"..
		fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")..
		fs.image_button(0, 8.5, 10, 0.5, "zoonami_blank", "index", "Page "..meta.page.." of "..#monster_journal.monsters)..
		fs.box(0, 8.5, 10, 0.5, "#00000000")
	return formspec
end

-- Stats Page
function monster_journal.stats(monster)
	local textarea = monster.name.."\n"..
		"Type: "..monster.type.."\n\n"..
		"Energy Cap: "..monster.energy_cap.."\n\n"..
		"Health Base: "..monster.health.."\n"..
		"Per Level: "..monster.health_per_level.."\n\n"..
		"Attack Base: "..monster.attack.."\n"..
		"Per Level: "..monster.attack_per_level.."\n\n"..
		"Defense Base: "..monster.defense.."\n"..
		"Per Level: "..monster.defense_per_level.."\n\n"..
		"Agility Base: "..monster.agility.."\n"..
		"Per Level: "..monster.agility_per_level.."\n\n"..
		"EXP Per Level: "..monster.exp_per_level.."\n\n"..
		"Tier: "..monster.tier..
		(monster.morph_level and "\n\nMorph Level: "..monster.morph_level or "")..
		(monster.morphs_into and "\nMorphs Into: "..monsters.stats[monster.morphs_into].name or "")
	local formspec = fs.textarea(3, 0.5, 6.5, 7, textarea)
	return formspec
end

-- Moves Page
function monster_journal.moves(monster)
	local level_up_moves, taught_moves = "", ""
	for i = 0, 100 do
		if monster.level_up_moves[i] then
			level_up_moves = level_up_moves..
				"\nLevel "..i..": "..move_stats[monster.level_up_moves[i]].name
		end
	end
	table.sort(monster.taught_moves)
	for i = 1, #monster.taught_moves do
		taught_moves = taught_moves..
			"\n"..move_stats[monster.taught_moves[i]].name
	end
	local formspec = fs.textarea(3, 0.5, 6.5, 7, "Level Up Moves: "..level_up_moves.."\n\nTaught Moves:"..taught_moves)
	return formspec
end

-- Other Page
function monster_journal.other(monster)
	local spawn = {"on", "by", "light", "time", "height"}
	for k, v in pairs(spawn) do
		local results = monster["spawn_"..v] or {}
		for i = 1, #results do
			spawn[v] = (spawn[v] or "").."\n"..results[i]
		end
	end
	local text = "Spawn Chance: ".."\n"..monster.spawn_chance.."\n\n"..
		"Spawn On: "..spawn.on.."\n\n"..
		"Spawn By: "..(spawn.by or "").."\n\n"..
		"Spawn Light: "..spawn.light.."\n\n"..
		"Spawn Time: "..spawn.time.."\n\n"..
		"Spawn Height: "..spawn.height	
	local formspec = fs.textarea(3, 0.5, 6.5, 7, text)
	return formspec
end

-- Shows formspec
function monster_journal.formspec(player, fields, context)
	local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local stack = player:get_wielded_item()
	local meta = minetest.deserialize(stack:get_meta():get_string("meta"))
	fields = fields or {}
	context = context or {sub_page = "stats"}
	local search = fields.search and string.lower(fields.search)
	fields.search = nil
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
		local result = table.indexof(monster_journal.monsters, search)
		meta.page = result > 0 and result or meta.page
	end
	
	-- Handle current page
	if meta.page > #monster_journal.monsters then
		meta.page = 1
	elseif meta.page < 1 then
		meta.page = #monster_journal.monsters
	end
	
	-- Monster
	local asset_name = monster_journal.monsters[meta.page]
	local monster = monsters.stats[asset_name]
	
	-- Handle sub page
	local sub_page = ""
	if fields.sub_page_stats then
		context.sub_page = "stats"
	elseif fields.sub_page_moves then
		context.sub_page = "moves"
	elseif fields.sub_page_other then
		context.sub_page = "other"
	end
	sub_page = monster_journal[context.sub_page](monster)
	
	-- Check if monster has been tamed for progression unlock
	local tamed_monsters = minetest.deserialize(player_meta:get_string("zoonami_tamed_monsters")) or {}
	
	-- Show monster page if unlocked otherwise show question mark
	local formspec = ""
	if tamed_monsters[asset_name] or not monster_journal_progression then
		formspec = fs.header(10, 10, "false", "#00000000")..
			fs.button_style(1, 8)..
			fs.background(0, 0, 10, 10, "zoonami_monster_journal_blank_page.png")..
			monster_journal.navigation(meta)..
			fs.image(0.5, 1.5, 2.5, 2.5, "zoonami_"..asset_name.."_front.png")..
			fs.image(0.5, 4, 2.5, 2.5, "zoonami_"..asset_name.."_back.png")..
			sub_page..
			fs.button(3.2, 7.6, 2, 0.8, "sub_page_stats", "Stats")..
			fs.button(5.3, 7.6, 2, 0.8, "sub_page_moves", "Moves")..
			fs.button(7.4, 7.6, 2, 0.8, "sub_page_other", "Other")
	else
		formspec = fs.header(10, 10, "false", "#00000000")..
			fs.button_style(1, 8)..
			fs.background(0, 0, 10, 10, "zoonami_monster_journal_blank_page.png")..
			monster_journal.navigation(meta)..
			fs.button_style(2, 8)..
			fs.font_style("button", "mono,bold", 90, "#000000")..
			fs.button(2, 2, 6, 6, "?", "?")..
			fs.box(2, 2, 6, 6, "#00000000")
	end
	
	stack:get_meta():set_string("meta", minetest.serialize(meta))
	player:set_wielded_item(stack)
	fsc.show(player_name, formspec, context, monster_journal.fsc_callback)
end
