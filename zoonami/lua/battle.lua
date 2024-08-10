-- Handles battles between player vs. computer and player vs. player

-- Local namespace
local battle = {}

-- Import functions
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local types = dofile(mod_path .. "/lua/types.lua")
local monsters = dofile(mod_path .. "/lua/monsters.lua")
local move_stats = dofile(mod_path .. "/lua/move_stats.lua")
local item_stats = dofile(mod_path .. "/lua/item_stats.lua")
local ai = dofile(mod_path .. "/lua/ai.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")
local biomes = dofile(mod_path .. "/lua/biomes.lua")

-- Battle settings
local settings = minetest.settings
local exp_multiplier = tonumber(settings:get("zoonami_exp_multiplier") or 1)

-- Global function to allow starting a battle
function zoonami.start_battle(mt_player_name, player_monsters, enemy_monsters, battle_type, battle_rules)
	battle.initialize(mt_player_name, player_monsters, enemy_monsters, battle_type, battle_rules)
end

-- Callback from fsc mod
function battle.fsc_callback(mt_player_obj, fields, context)
	local mt_player_name = mt_player_obj:get_player_name()
	if fields.quit then
		battle.stop(mt_player_name, context, fields)
		return true
	else
		battle.update(mt_player_name, fields, context)
	end
end

-- Prevents crashes if player leaves during battle and prevents malicious input
function battle.player_check(mt_player_name, context, check_context_lock)
	local mt_player_obj = minetest.get_player_by_name(mt_player_name)
	if not mt_player_obj then return false end
	local meta = mt_player_obj:get_meta()
	local battle_session_id = meta:get_string("zoonami_battle_session_id")
	if next(context) == nil or (context.session_id ~= battle_session_id) or (check_context_lock and context.locked) then
		return false
	else
		return mt_player_obj
	end
end

-- Set player invincibility during and after battle
function battle.player_invincibility(mt_player_obj, context, enable)
	local armor = mt_player_obj:get_armor_groups()
	if not context.player_armor.immortal then
		armor.immortal = enable and 1 or nil
		mt_player_obj:set_armor_groups(armor)
	end
end

-- Start PVP turn timer
function battle.start_turn_timer(mt_player_name, player, enemy, context)
	local mt_player_obj = minetest.get_player_by_name(mt_player_name)
	if not mt_player_obj then return end
	context.timer_hud_id = mt_player_obj:hud_add({
		 hud_elem_type = "text",
		 text = "Time: "..context.battle_rules.turn_time,
		 size = {x = 2},
		 number = 0xFFFFFF,
		 position = {x = 0.5, y = 0},
		 offset = {x = 0, y = 20},
		 alignment = {x = 0, y = 0},
		 scale = {x = 100, y = 100},
		 z_index = 150,
	})
	battle.turn_timer(mt_player_name, player, enemy, context, 0)
end

-- PVP Turn Timer Loop
function battle.turn_timer(mt_player_name, player, enemy, context, elapsed)
	local mt_player_obj = minetest.get_player_by_name(mt_player_name)
	if not mt_player_obj then return end
	if context.timer_hud_id and elapsed >= context.battle_rules.turn_time then
		if context.locked then
			context.fields_whitelist = {}
			minetest.after(1, function()
				battle.turn_timer(mt_player_name, player, enemy, context, elapsed + 1)
			end)
		else
			context.fields_whitelist = nil
			battle.fields_move(mt_player_name, player, enemy, nil, context)
		end
	elseif context.timer_hud_id then
		mt_player_obj:hud_change(context.timer_hud_id, "text", "Time: "..context.battle_rules.turn_time - elapsed)
		minetest.after(5, function()
			battle.turn_timer(mt_player_name, player, enemy, context, elapsed + 5)
		end)
	end
end

-- Stop PVP turn timer
function battle.stop_turn_timer(mt_player_obj, context)
	if context.timer_hud_id then
		mt_player_obj:hud_remove(context.timer_hud_id)
		context.timer_hud_id = false
	end
end

-- Prepares needed components for battling
function battle.initialize(mt_player_name, player_monsters, enemy_monsters, battle_type, battle_rules)
	local mt_player_obj = minetest.get_player_by_name(mt_player_name)
	if not mt_player_obj then return end
	local meta = mt_player_obj:get_meta()
	local context = {
		zoom = meta:get_float("zoonami_battle_gui_zoom"),
		music_volume = meta:get_float("zoonami_battle_music_volume"),
		sfx_volume = meta:get_float("zoonami_battle_sfx_volume"),
		chat_bar = meta:get("zoonami_battle_chat_bar"),
		chat_bar_visible = false,
		player_armor = mt_player_obj:get_armor_groups(),
		player_current_monster = nil,
		player_monsters = {},
		pvp_enemy = meta:get_string("zoonami_battle_pvp_enemy"),
		battle_type = battle_type,
		battle_rules = battle_rules,
		timer_hud_id = false,
		enemy_current_monster = nil,
		enemy_monsters = {},
		enemy_monster_count_ui = "",
		shield = 0,
		locked = false,
		fields_whitelist = nil,
		biome_background = biomes.background(mt_player_obj),
		coins = 0,
		rewards = {}
	}

	-- Make player invincible during battle
	battle.player_invincibility(mt_player_obj, context, true)
	
	-- Loads monsters and chooses first monster with 1 or more health
	local load_monsters = function(monsters_to_load, player_or_enemy)
		for i = 1, 5 do
			local monster = monsters_to_load["monster#"..i]
			monster = monster and monsters.load_stats(monster)
			if monster and monster.health > 0 and context[player_or_enemy.."_current_monster"] == nil then
				context[player_or_enemy.."_current_monster"] = i
			end
			if monster then
				monster.move_context = {}
				for k, v in pairs(monster.moves) do
					monster.move_context[v] = {
						cooldown = move_stats[v].cooldown,
						quantity = move_stats[v].quantity,
					}
				end
			end
			context[player_or_enemy.."_monsters"]["monster#"..i] = monster
		end
	end
	
	load_monsters(player_monsters, "player")
	load_monsters(enemy_monsters, "enemy")
	
	-- Load enemy monster count ui
	if context.battle_type == "trainer" or context.battle_type == "pvp" then
		for _ in pairs(context.enemy_monsters) do
			context.enemy_monster_count_ui = context.enemy_monster_count_ui.."●"
		end
	end
	
	-- Load chat bar
	if context.chat_bar then
		context.chat_bar = fs.background9(0, 6, 6, 0.75, "zoonami_button_3.png", "false", 8, context.zoom)..
			"style_type[field;noclip=true]"..
			fs.field(0.1, 6.1, 5.8, 0.55, "chat", "", "", context.zoom)..
			"field_close_on_enter[chat;false]"
	else
		context.chat_bar = ""
	end
	
	-- Generate battle session id to track when player leaves battle
	context.session_id = assert(SecureRandom()):next_bytes(16)
	meta:set_string("zoonami_battle_session_id", context.session_id)
	
	-- Reset PVP variables
	meta:set_int("zoonami_battle_priority", 0)
	meta:set_int("zoonami_battle_new_monster", 0)
	meta:set_string("zoonami_battle_pvp_move", "")
	
	-- Start music for the player
	if context.battle_type == "trainer" or context.battle_type == "pvp" then
		local music_handler = minetest.sound_play("zoonami_trainer_battle", {to_player = mt_player_name, gain = 0.4 * context.music_volume, fade = 1.8, loop = true})
		meta:set_string("zoonami_music_handler", music_handler)
	else
		local music_handler = minetest.sound_play("zoonami_wild_battle", {to_player = mt_player_name, gain = 0.4 * context.music_volume, fade = 1.8, loop = true})
		meta:set_string("zoonami_music_handler", music_handler)
	end
	
	-- Show the intro animation
	local formspec = 
		fs.header(6, 6, "true", "#00000000", context.zoom)..
		fs.animation(0, 0, 6, 6, "intro_animation", "zoonami_battle_intro_animation.png", 8, 130, 1, context.zoom)
	fsc.show(mt_player_name, formspec, context, battle.fsc_callback)
	
	-- Show battle formspec
	minetest.after(0.95, battle.update, mt_player_name, {main_menu = true, silent = true}, context)
end

-- The main function that handles user input
function battle.update(mt_player_name, fields, context)
	local mt_player_obj = battle.player_check(mt_player_name, context, true)
	if not mt_player_obj then return end
	local player = context.player_monsters["monster#"..context.player_current_monster]
	local enemy = context.enemy_monsters["monster#"..context.enemy_current_monster]
	fields = fields or {}
	
	-- Store previous menu if chat message is being sent
	local previous_menu = context.menu
	
	-- Initialize formspec context variables
	context.menu = ""
	context.animation = ""
	context.animation_value = ""
	context.textbox = ""
	context.player_texture_modifier = ""
	context.enemy_texture_modifier = ""
	context.chat_bar_visible = false
	
	-- Start turn timer
	if context.battle_type == "pvp" and not context.timer_hud_id then
		battle.start_turn_timer(mt_player_name, player, enemy, context)
	end
	
	-- This allows limiting what fields can be sent via a whitelist
	if context.fields_whitelist then
		for k, v in pairs (fields) do
			if not context.fields_whitelist[k] then
				fields[k] = nil
			end
		end
	end
	
	-- Sort through field keys
	local filtered_fields = table.copy(fields)
	filtered_fields.chat = nil
	filtered_fields.key_enter = nil
	filtered_fields.items_scroll_container = nil
	local field_key = next(filtered_fields) or ""
	local field_item = tonumber(string.match(field_key, "^item#([1]?%d)$"))
	field_item = field_item and math.min(math.max(field_item, 1), 12)
	local field_move = tonumber(string.match(field_key, "^move#([1234])$"))
	local field_monster = tonumber(string.match(field_key, "^monster#([12345])$"))
	local field_chat = fields.chat and fields.chat ~= "" and fields.key_enter
	
	-- Only show chat bar when it can be used
	if fields.battle or fields.party or fields.items or fields.main_menu or field_chat then
		if not context.fields_whitelist then
			context.chat_bar_visible = true
		end
	end

	-- Play button press sound except when muted or battle sequence starts
	if not fields.silent and field_key ~= "" and not field_item and not field_move and not field_monster and not fields.move_skip then
		minetest.sound_play("zoonami_select", {to_player = mt_player_name, gain = 0.7 * context.sfx_volume}, true)
	end
	
	if fields.battle then
		battle.fields_battle(player, context)
	elseif fields.party then
		battle.fields_party(context)
	elseif fields.items then
		battle.fields_items(mt_player_name, player, enemy, context)
	elseif field_item then
		battle.fields_item(mt_player_name, player, enemy, field_item, context)
	elseif field_move or fields.move_skip then
		battle.fields_move(mt_player_name, player, enemy, field_move, context)
	elseif field_monster then
		battle.fields_monster(mt_player_name, player, enemy, field_monster, context)
	elseif field_chat then
		battle.fields_chat(mt_player_name, fields.chat, previous_menu, context)
	else
		battle.fields_main_menu(context)
	end
	
	-- Redraw formspec except when battle sequence starts or scrolling
	if fields.battle or fields.party or fields.items or fields.main_menu or field_chat then
		battle.redraw_formspec(mt_player_name, player, enemy, context)
	end
end

-- Shows the battle menu where the player can select a move
function battle.fields_battle(player, context)
	context.menu = context.menu..
		fs.menu_image_button(4.5, 4.5, 1.5, 0.5, 2, "main_menu", "Back", context.zoom)
	for i = 1, 4 do
		local x_coord = i > 2 and (i-3)*3 or (i-1)*3
		local y_coord = i > 2 and 5.5 or 5
		local move_name = player.moves[i]
		if move_name then
			local cooldown = player.move_context[move_name] and player.move_context[move_name].cooldown
			local quantity = player.move_context[move_name] and player.move_context[move_name].quantity
			context.menu = context.menu..
				fs.menu_image_button(x_coord, y_coord, 3, 0.5, 5, "move#"..i, move_stats[move_name].name, context.zoom)..
				fs.tooltip("move#"..i, move_stats.tooltip(move_name, cooldown, quantity), "#ffffff", "#000000")
		else
			context.menu = context.menu..
				fs.image(x_coord, y_coord, 3, 0.5, "zoonami_menu_button5.png", context.zoom)
		end
	end
end

-- Shows the party menu where the player can select a monster
function battle.fields_party(context)
	context.menu = context.menu..
		fs.image(0, 0, 6, 6, "zoonami_battle_backpack_background.png", context.zoom)
	if not context.fields_whitelist then
		context.menu = context.menu..
			fs.menu_image_button(4.5, 5.5, 1.5, 0.5, 6, "main_menu", "Back", context.zoom)
	end
	for i = 1, 5 do
		if context.player_monsters["monster#"..i] then
			local monster = context.player_monsters["monster#"..i]
			context.menu = context.menu..
				fs.box(0.39, 0.3 + i - 0.9, 0.7, 0.7, monsters.stats[monster.asset_name].color, context.zoom)..
				fs.menu_image_button(0, 0.3 + i - 1, 6, 0.99, 3, "monster#"..i, (monster.nickname or monster.name).." Lvl "..monster.level.."\nH:"..monster.health.."/"..monster.max_health.."  E:"..monster.energy.."/"..monster.max_energy, context.zoom)
		else
			context.menu = context.menu..
				fs.box(0.39, 0.3 + i - 0.9, 0.7, 0.7, "#FFFFFFFF", context.zoom)..
				fs.menu_image_button(0, 0.3 + i - 1, 6, 0.99, 3, "monster#"..i, "Slot #"..i, context.zoom)
		end
	end
end

-- Shows the items menu where the player can select an item
function battle.fields_items(mt_player_name, player, enemy, context)
	local mt_player_obj = battle.player_check(mt_player_name, context, true)
	if not mt_player_obj then return end
	if context.battle_type ~= "wild" then
		context.locked = true
		context.textbox = fs.dialogue("Items can't be used in trainer battles.", context.zoom)
		battle.redraw_formspec(mt_player_name, player, enemy, context)
		minetest.after(4, function()
			context.locked = false
			battle.update(mt_player_name, {main_menu = true, silent = true}, context)
		end)
		return
	end
	local inv = mt_player_obj:get_inventory()
	local menu_slot_number = 0
	context.menu = fs.image(0, 0, 6, 6, "zoonami_battle_backpack_background.png", context.zoom)..
		fs.scroll_container(0, 0.3, 6, 5, "items_scroll_container", "vertical", "0.1", context.zoom)
	for i = 1, 12 do
		local stack = inv:get_stack("zoonami_backpack_items", i)
		local stack_name = stack:get_name()
		stack_name = stack_name:gsub(modname .. ":zoonami_", "")
		if item_stats[stack_name] then
			local item_name = item_stats[stack_name].name
			item_name = string.gsub(item_name, "(.+ .+) ", "%1\n")
			context.menu = context.menu..
			fs.box(0.39, 0.1 + menu_slot_number, 0.7, 0.7, item_stats[stack_name].color, context.zoom)..
			fs.menu_image_button(0, 0 + menu_slot_number, 6, 0.99, 3, "item#"..i, item_name.." x"..stack:get_count(), context.zoom)
			menu_slot_number = menu_slot_number + 1
		end
	end
	context.menu = context.menu..
		fs.scroll_container_end(0, 50, 1)..
		fs.scrollbar(5.75, 0.3, 0.25, 5, "vertical", "items_scroll_container", "0", context.zoom)..
		fs.menu_image_button(4.5, 5.5, 1.5, 0.5, 6, "main_menu", "Back", context.zoom)
end

-- Called when a player selects an item
function battle.fields_item(mt_player_name, player, enemy, field_number, context)
	local mt_player_obj = battle.player_check(mt_player_name, context, true)
	if not mt_player_obj then return end
	if context.battle_type ~= "wild" then return end
	context.locked = true
	local inv = mt_player_obj:get_inventory()
	local stack = inv:get_stack("zoonami_backpack_items", field_number)
	local stack_name = stack:get_name()
	stack_name = stack_name:gsub(modname .. ":zoonami_", "")
	if item_stats[stack_name] then
		local meta = mt_player_obj:get_meta()
		local player_move = item_stats[stack_name]
		local found_slot = false
		if player_move.type == "taming" then
			for i = 1, 5 do
				local monster = context.player_monsters["monster#"..i]
				if not monster then
					found_slot = true
					break
				end
			end
			if not found_slot then
				for i = 1, 25 do
					local monster = meta:get_string("zoonami_computer_folder_1_box_1_monster_"..i)
					if monster == "" then
						found_slot = true
						break
					end
				end
			end
		end
		if player_move.type == "taming" and not found_slot then
			context.textbox = fs.dialogue("Computer box is full. Monsters can't be tamed.", context.zoom)
			context.locked = false
			battle.fields_items(mt_player_name, player, enemy, context)
			context.locked = true
			battle.redraw_formspec(mt_player_name, player, enemy, context)
			minetest.after(4, function()
				context.locked = false
				battle.update(mt_player_name, {items = true, silent = true}, context)
			end)
		else
			local enemy_move = ai.choose_move(player, enemy, context)
			enemy_move = move_stats[enemy_move] or enemy_move
			battle.sequence(mt_player_name, player, enemy, context, player_move, enemy_move)
		end
	end
end

-- Called when a player selects a move or skips and checks if it can be used
function battle.fields_move(mt_player_name, player, enemy, field_number, context)
	context.locked = true
	local player_move_name = player.moves[field_number] or "skip"
	local move_cooldown = move_stats[player_move_name].cooldown
	local move_quantity = move_stats[player_move_name].quantity
	local cooldown = player.move_context[player_move_name] and player.move_context[player_move_name].cooldown
	local quantity = player.move_context[player_move_name] and player.move_context[player_move_name].quantity
	if cooldown and move_cooldown and cooldown < move_cooldown then
		context.textbox = fs.dialogue("Move cooldown needs to recharge.", context.zoom)
		battle.redraw_formspec(mt_player_name, player, enemy, context)
		minetest.after(4, function()
			context.locked = false
			battle.update(mt_player_name, {battle = true, silent = true}, context)
		end)
	elseif quantity and quantity <= 0 then
		context.textbox = fs.dialogue("Move quantity has reached zero.", context.zoom)
		battle.redraw_formspec(mt_player_name, player, enemy, context)
		minetest.after(4, function()
			context.locked = false
			battle.update(mt_player_name, {battle = true, silent = true}, context)
		end)
	elseif move_stats[player_move_name].energy > player.energy then
		context.textbox = fs.dialogue("Not enough energy to use that move.", context.zoom)
		battle.redraw_formspec(mt_player_name, player, enemy, context)
		minetest.after(4, function()
			context.locked = false
			battle.update(mt_player_name, {battle = true, silent = true}, context)
		end)
	elseif move_stats[player_move_name].energy <= player.energy then
		local player_move = move_stats[player_move_name]
		local enemy_move = ai.choose_move(player, enemy, context)
		enemy_move = move_stats[enemy_move] or enemy_move
		if context.battle_type == "pvp" then
			battle.pvp_move_initialize(mt_player_name, player, enemy, context, player_move)
		else
			battle.sequence(mt_player_name, player, enemy, context, player_move, enemy_move)
		end
	end
end

-- Called when a player wants to switch monsters
function battle.fields_monster(mt_player_name, player, enemy, field_number, context)
	local mt_player_obj = battle.player_check(mt_player_name, context, true)
	if not mt_player_obj then return end
	if context.player_monsters["monster#"..field_number] then
		context.locked = true
		if context.player_monsters["monster#"..field_number].health <= 0 then
			context.textbox = fs.dialogue("That monster is too tired to battle.", context.zoom)
		elseif context.player_current_monster == field_number then
			context.textbox = fs.dialogue("That monster is already battling.", context.zoom)
		end
		if context.player_monsters["monster#"..field_number].health > 0 and context.textbox == "" then
			local player_move = {type = "monster", new_monster = field_number}
			local enemy_move = ai.choose_move(player, enemy, context)
			enemy_move = move_stats[enemy_move] or enemy_move
			if context.fields_whitelist then
				if context.battle_type == "pvp" then
					local meta = mt_player_obj:get_meta()
					meta:set_int("zoonami_battle_new_monster", field_number)
				end
				context.fields_whitelist = nil
				context.player_current_monster = field_number
				player = context.player_monsters["monster#"..field_number]
				battle.regain_energy(player, enemy)
				battle.increment_move_cooldown(player, enemy)
				context.locked = false
				battle.update(mt_player_name, {main_menu = true}, context)
			else
				if context.battle_type == "pvp" then
					battle.pvp_move_initialize(mt_player_name, player, enemy, context, player_move)
				else
					battle.sequence(mt_player_name, player, enemy, context, player_move, enemy_move)
				end
			end
		else
			battle.fields_party(context)
			battle.redraw_formspec(mt_player_name, player, enemy, context)
			minetest.after(4, function()
				context.locked = false
				battle.update(mt_player_name, {party = true, silent = true}, context)
			end)
		end
	end
end

-- Sends chat message from chat bar
function battle.fields_chat(mt_player_name, message, previous_menu, context)
	context.menu = previous_menu.." "
	local shout_priv = minetest.check_player_privs(mt_player_name, {shout = true})
	if shout_priv then
		for i, v in ipairs(minetest.registered_on_chat_messages) do
			if v(mt_player_name, message) then
				return
			end
		end
		minetest.log("action", "CHAT: "..minetest.format_chat_message(mt_player_name, message))
		minetest.chat_send_all(minetest.format_chat_message(mt_player_name, message))
	else
		minetest.chat_send_player(mt_player_name, "-!- You don't have permission to shout.")
	end
end

-- Displays the main menu
function battle.fields_main_menu(context)
	context.menu = fs.menu_image_button(0, 5, 1.5, 1, 1, "battle", "Battle", context.zoom)..
	fs.menu_image_button(1.5, 5, 1.51, 1, 1, "party", "Party", context.zoom)..
	fs.menu_image_button(3, 5, 1.5, 1, 1, "items", "Items", context.zoom)..
	fs.menu_image_button(4.5, 5, 1.51, 1, 1, "move_skip", "Skip", context.zoom)
end

-- Initializes PVP components before waiting for opponent
function battle.pvp_move_initialize(mt_player_name, player, enemy, context, player_move)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	local meta = mt_player_obj:get_meta()
	meta:set_string("zoonami_battle_pvp_move", minetest.serialize(player_move))
	meta:set_int("zoonami_battle_priority", 0)
	context.textbox = fs.dialogue("Waiting for opponent...", context.zoom)
	battle.redraw_formspec(mt_player_name, player, enemy, context)
	battle.stop_turn_timer(mt_player_obj, context)
	battle.pvp_move_wait(mt_player_name, player, enemy, context, player_move)
end

-- Waits for PVP opponent to make a move then starts the battle sequence
function battle.pvp_move_wait(mt_player_name, player, enemy, context, player_move)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	local meta = mt_player_obj:get_meta()
	local enemy_player = minetest.get_player_by_name(context.pvp_enemy or "")
	local enemy_meta = enemy_player and enemy_player:get_meta()
	local enemy_move = enemy_meta and enemy_meta:get_string("zoonami_battle_pvp_move")
	local enemy_opponent = enemy_meta and enemy_meta:get_string("zoonami_battle_pvp_enemy") or ""
	if enemy_opponent ~= mt_player_name then
		context.textbox = fs.dialogue("Opponent has left the battle...", context.zoom)
		battle.redraw_formspec(mt_player_name, player, enemy, context)
		minetest.after(4, battle.stop, mt_player_name, context)
	elseif enemy_move and enemy_move ~= "" then
		local enemy_priority = enemy_meta:get_int("zoonami_battle_priority")
		local player_priority = meta:get_int("zoonami_battle_priority")
		if enemy_priority == 0 and player_priority == 0 then
			player_priority = 1 * (math.random() >= 0.5 and 1 or -1)
			enemy_priority = player_priority * -1
			enemy_meta:set_int("zoonami_battle_priority", player_priority)
			meta:set_int("zoonami_battle_priority", enemy_priority)
		end
		enemy_move = minetest.deserialize(enemy_move)
		enemy_meta:set_string("zoonami_battle_pvp_move", "")
		battle.sequence(mt_player_name, player, enemy, context, player_move, enemy_move)
	else
		minetest.after(2, battle.pvp_move_wait, mt_player_name, player, enemy, context, player_move)
	end
end

-- Battle sequence after both the player and enemy have chosen a move
function battle.sequence(mt_player_name, player, enemy, context, player_move, enemy_move)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	local meta = mt_player_obj:get_meta()
	
	local function sequence(attacker, defender, opponents_move)
		local delay = 0
		context.animation = ""
		context.animation_value = ""
		if attacker[2].type == "skip" then
			battle.skip(mt_player_name, context, attacker, attacker[2])
		elseif attacker[2].type == "taming" then
			delay = battle.taming(mt_player_name, context, attacker, defender)
		elseif attacker[2].type == "monster" then
			player, enemy = battle.switch_monster(mt_player_name, player, enemy, context, attacker, defender)
		else
			battle.attack(mt_player_name, context, attacker[1], defender[1], attacker[2], attacker[3], attacker[4], attacker[5], attacker[6], defender[5], defender[6], opponents_move)
		end
		battle.redraw_formspec(mt_player_name, player, enemy, context)
		return delay
	end
	
	local function stop(delay)
		if delay == "stop" then
			return true
		elseif player.health == 0 or enemy.health == 0 then
			minetest.after(4 + delay, battle.death, mt_player_name, player, enemy, context)
			return true
		end
	end
	
	local attacker = {player, player_move, "Your ", "player", 2, 0.4}
	local defender = {enemy, enemy_move, "Enemy ", "enemy", 4.415, 3}
	local higher_priority = (enemy_move.priority or 0) > (player_move.priority or 0)
	local equal_priority = (enemy_move.priority or 0) == (player_move.priority or 0)
	local higher_agility = enemy.agility > player.agility
	local equal_agility = enemy.agility == player.agility
	local pvp_priority = meta:get_int("zoonami_battle_priority")
	local random_priority = pvp_priority == 0 and math.random(2) == 1
	if higher_priority or equal_priority and (higher_agility or equal_agility and (pvp_priority == -1 or random_priority)) then
		attacker, defender = defender, attacker
	end
	
	local delay = sequence(attacker, defender)
	if not stop(delay) then
		minetest.after(4 + delay, function()
			delay = sequence(defender, attacker, attacker[2])
			if not stop(delay) then
				minetest.after(4 + delay, function()
					battle.regain_energy(player, enemy)
					battle.increment_move_cooldown(player, enemy)
					context.locked = false
					battle.update(mt_player_name, {main_menu = true, silent = true}, context)
				end)
			end
		end)
	end
end

-- Regain energy each turn
function battle.regain_energy(player, enemy)
	if player.health > 0 then
		player.energy = math.min(player.energy + 2, player.max_energy)
	end
	if enemy.health > 0 then
		enemy.energy = math.min(enemy.energy + 2, enemy.max_energy)
	end
end

-- Increment move cooldown
function battle.increment_move_cooldown(player, enemy)
	for k, v in pairs (player.move_context) do
		if player.move_context[k].cooldown then
			player.move_context[k].cooldown = math.min(player.move_context[k].cooldown + 1, move_stats[k].cooldown)
		end
	end
	for k, v in pairs (enemy.move_context) do
		if enemy.move_context[k].cooldown then
			enemy.move_context[k].cooldown = math.min(enemy.move_context[k].cooldown + 1, move_stats[k].cooldown)
		end
	end
end

-- Skip
function battle.skip(mt_player_name, context, attacker, move)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	local attacker_name = attacker[4] == "player" and attacker[1].nickname or attacker[1].name
	context.textbox = fs.dialogue(attacker[3]..attacker_name.." used Skip.", context.zoom)
	minetest.sound_play(move.sound, {to_player = mt_player_name, gain = move.volume * context.sfx_volume}, true)
end

-- Taming
function battle.taming(mt_player_name, context, attacker, defender)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	local taming_chance = {common = 3500, uncommon = 5500, rare = 7500, mythical = 15000, legendary = 19000}
	local spawn_chance = monsters.stats[defender[1].asset_name].spawn_chance
	local taming_effectiveness = attacker[2].effective_types[defender[1].type] and 1.2 or 1
	local taming_amount = attacker[2].amount * taming_effectiveness
	local level = defender[1].level
	local health_percentage = defender[1].health / defender[1].max_health
	local tame_chance = math.ceil((taming_chance[spawn_chance] / taming_amount) * ((level / 10) * 0.05) * (health_percentage + 0.2))
	local result = math.random(tame_chance) == 1 and "tamed" or "untamed"
	local delay = result == "tamed" and "stop" or 3
	local stack = ItemStack(modname .. ":zoonami_"..attacker[2].asset_name.." 1")
	local inv = mt_player_obj:get_inventory()
	local attacker_name = attacker[4] == "player" and attacker[1].nickname or attacker[1].name
	inv:remove_item("zoonami_backpack_items", stack)
	context.textbox = fs.dialogue(attacker[3]..attacker_name.." used "..attacker[2].name..".", context.zoom)
	context.animation = fs.image(3.4, 1.8, 0.604, 0.604, "zoonami_"..attacker[2].asset_name..".png", context.zoom)
	local dialogue = result == "tamed" and " is tamed!" or " is still wild."
	minetest.after(4, function()
		context.textbox = fs.dialogue(defender[1].name..dialogue, context.zoom)
		context.animation = ""
		if result == "tamed" then
			local tamed_pos = minetest.pos_to_string(mt_player_obj:get_pos(), 0)
			local prisma_log = defender[1].prisma_id and "prisma " or ""
			local meta = mt_player_obj:get_meta()
			local found_slot = false
			for i = 1, 5 do
				local monster = context.player_monsters["monster#"..i]
				if not monster then
					context.player_monsters["monster#"..i] = defender[1]
					found_slot = true
					break
				end
			end
			if not found_slot then
				for i = 1, 25 do
					local monster = meta:get_string("zoonami_computer_folder_1_box_1_monster_"..i)
					if monster == "" then
						local tamed_monster = monsters.save_stats(defender[1])
						meta:set_string("zoonami_computer_folder_1_box_1_monster_"..i, minetest.serialize(tamed_monster))
						found_slot = true
						break
					end
				end
			end
			minetest.log("action", mt_player_name.." tamed a wild "..prisma_log..defender[1].name.." at "..tamed_pos)
			minetest.sound_play("zoonami_level_up", {to_player = mt_player_name, gain = 1 * context.sfx_volume}, true)
			zoonami.monster_journal_tamed_monster(meta, defender[1].asset_name)
			minetest.after(4, battle.stop, mt_player_name, context)
		end
		battle.redraw_formspec(mt_player_name, attacker[1], defender[1], context)
	end)
	return delay
end

-- Switch Monster
function battle.switch_monster(mt_player_name, player, enemy, context, attacker, defender)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return player, enemy end
	context[attacker[4].."_current_monster"] = attacker[2].new_monster
	attacker[1] = context[attacker[4].."_monsters"]["monster#"..context[attacker[4].."_current_monster"]]
	local attacker_name = attacker[4] == "player" and attacker[1].nickname or attacker[1].name
	context.textbox = fs.dialogue(attacker[3]..attacker_name.." switched in.", context.zoom)
	player = context.player_monsters["monster#"..context.player_current_monster]
	enemy = context.enemy_monsters["monster#"..context.enemy_current_monster]
	minetest.sound_play("zoonami_switch", {to_player = mt_player_name, gain = 1 * context.sfx_volume}, true)
	return player, enemy
end

-- Move damage and animation
function battle.attack(mt_player_name, context, attacker, defender, move, prefix, animation_name, damage_pos_x, damage_pos_y, recover_pos_x, recover_pos_y, opponents_move)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	local attacker_name = animation_name == "player" and attacker.nickname or attacker.name
	attacker.energy = attacker.energy - move.energy
	
	-- Calculate shield and resistance
	local shield = 1
	local resistance = 1
	if opponents_move then
		local stats = move_stats[opponents_move.asset_name]
		if stats and stats.shield then
			shield = 1 - stats.shield
		end
		if stats and stats.resistance and move.type then
			resistance = 1 - (stats.resistance[string.lower(move.type)] or 0)
		end
	end
	
	-- Damage dealt
	local effectiveness = move.type and types.effectiveness(string.lower(move.type), string.lower(defender.type)) or 1
	local damage_dealt = nil
	if move.attack or move.counter_min or move.range_min then
		local counteract_bonus = move.counteract and (defender[string.lower(move.counteract)] - attacker[string.lower(move.counteract)]) / 2 or 0
		local counter_power = move.counter_min and ((attacker.max_health - attacker.health) / attacker.max_health) * (move.counter_max - move.counter_min) + move.counter_min
		local range_power = move.range_min and math.random(move.range_min * 100, move.range_max * 100) / 100
		local move_power = move.attack or move.static or counter_power or range_power
		local type_bonus = move.type and attacker.type == move.type and 1.15 or 1
		local base_multiplier = move_power * effectiveness * type_bonus
		local base_attack = attacker.attack + counteract_bonus
		local base_damage = base_attack / (5 * math.sqrt(defender.defense / base_attack))
		damage_dealt = math.ceil(base_damage * base_multiplier * shield * resistance)
	elseif move.static then
		damage_dealt = math.ceil(move.static * defender.max_health * shield)
	end
	
	if damage_dealt then
		context.animation_value = context.animation_value..
			fs.font_style("label", "mono,bold", 28, "#FF2407", context.zoom)..
			fs.label(damage_pos_x, damage_pos_y, damage_dealt*-1, context.zoom)
		defender.health = math.max(defender.health - damage_dealt, 0)
	end
	
	-- Recovering and Healing
	if move.recover then
		local font_size = move.heal and 24 or 28
		local pos_x = move.heal and recover_pos_x - 0.25 or recover_pos_x
		attacker.energy = math.min(attacker.energy + move.recover, attacker.max_energy)
		context.animation_value = context.animation_value..
			fs.font_style("label", "mono,bold", font_size, "#2C61A6", context.zoom)..
			fs.label(pos_x, recover_pos_y, "+"..move.recover, context.zoom)
	end
	
	if move.heal then
		local font_size = move.recover and 24 or 28
		local pos_x = move.recover and recover_pos_x + 0.47 or recover_pos_x
		local healing = math.ceil(move.heal * attacker.max_health)
		attacker.health = math.min(attacker.health + healing, attacker.max_health)
		context.animation_value = context.animation_value..
			fs.font_style("label", "mono,bold", font_size, "#0D720D", context.zoom)..
			fs.label(pos_x, recover_pos_y, "+"..healing, context.zoom)
	end
	
	-- Move cooldown and quantity
	if move.cooldown then
		attacker.move_context[move.asset_name].cooldown = -1
	end
	
	if move.quantity then
		attacker.move_context[move.asset_name].quantity = attacker.move_context[move.asset_name].quantity - 1
	end
	
	-- Set animation and play sound
	context.animation = fs.animation(0, 0, 6, 6, "move_animation", "zoonami_"..animation_name.."_"..move.asset_name.."_animation.png", move.animation_frames, move.frame_length, 1, context.zoom)
	local dialogue = effectiveness > 1 and "It's effective!" or effectiveness < 1 and "It's not effective." or ""
	context.textbox = fs.dialogue(prefix..attacker_name.." used "..move.name..". "..dialogue, context.zoom)
	minetest.sound_play(move.sound, {to_player = mt_player_name, gain = move.volume * context.sfx_volume}, true)
end

-- Death Sequence
function battle.death(mt_player_name, player, enemy, context)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	local meta = mt_player_obj:get_meta()
	context.animation = ""
	context.animation_value = ""
	local dead_monster = player.health == 0 and player or enemy
	local dead_owner = player.health == 0 and "player" or "enemy"
	local another_monster = false
	for i = 1, 5 do
		local monster = context[dead_owner.."_monsters"]["monster#"..i]
		if monster and monster.health > 0 then
			another_monster = true
		end
	end
	if dead_owner == "enemy" and context.battle_type == "pvp" then
		context.textbox = fs.dialogue("Enemy "..dead_monster.name.." is too weak to battle.", context.zoom)
		context.enemy_texture_modifier = "^[opacity:0"
		context.enemy_monster_count_ui = context.enemy_monster_count_ui:gsub(".[\128-\191]*", "", 1).."○"
		if another_monster then
			minetest.after(4, function()
				context.textbox = fs.dialogue("Waiting for opponent...", context.zoom)
				battle.redraw_formspec(mt_player_name, player, enemy, context)
				battle.pvp_death_switch_wait(mt_player_name, player, enemy, context)
			end)
		else
			minetest.after(4, function()
				if context.battle_rules and not context.battle_rules.casual then
					local pvp_wins = meta:get_int("zoonami_pvp_wins")
					meta:set_int("zoonami_pvp_wins", pvp_wins + 1)
				end
				context.textbox = fs.dialogue("You won the battle!", context.zoom)
				battle.redraw_formspec(mt_player_name, player, enemy, context)
			end)
			minetest.after(8, battle.stop, mt_player_name, context)
		end
	elseif dead_owner == "enemy" then
		context.textbox = fs.dialogue("Enemy "..dead_monster.name.." is too weak to battle.", context.zoom)
		context.enemy_texture_modifier = "^[opacity:0"
		if context.battle_type == "trainer" then
			context.enemy_monster_count_ui = context.enemy_monster_count_ui:gsub(".[\128-\191]*", "", 1).."○"
		end
		battle.add_rewards(context, enemy)
		if another_monster then
			minetest.after(8, function()
				context.enemy_current_monster = ai.choose_monster(player, enemy, context)
				enemy = context.enemy_monsters["monster#"..context.enemy_current_monster]
				context.textbox = fs.dialogue("Enemy "..enemy.name.." switched in.", context.zoom)
				context.enemy_texture_modifier = ""
				battle.redraw_formspec(mt_player_name, player, enemy, context)
				minetest.after(4, function()
					battle.regain_energy(player, enemy)
					battle.increment_move_cooldown(player, enemy)
					context.locked = false
					battle.update(mt_player_name, {main_menu = true, silent = true}, context)
				end)
			end)
		else
			minetest.after(8, battle.stop, mt_player_name, context)
		end
		battle.give_exp(mt_player_name, player, enemy, context)
	elseif dead_owner == "player" then
		context.textbox = fs.dialogue("Your "..(dead_monster.nickname or dead_monster.name).." is too weak to battle.", context.zoom)
		context.player_texture_modifier = "^[opacity:0"
		if another_monster then
			minetest.after(4, function()
				context.fields_whitelist = {party = true}
				for i = 1, 5 do
					context.fields_whitelist["monster#"..i] = true
				end
				context.locked = false
				battle.update(mt_player_name, {party = true}, context)
			end)
		elseif context.battle_type == "pvp" then
			minetest.after(4, function()
				if context.battle_rules and not context.battle_rules.casual then
					local pvp_loses = meta:get_int("zoonami_pvp_loses")
					meta:set_int("zoonami_pvp_loses", pvp_loses + 1)
				end
				context.textbox = fs.dialogue("You lost the battle.", context.zoom)
				battle.redraw_formspec(mt_player_name, player, enemy, context)
			end)
			minetest.after(8, battle.stop, mt_player_name, context)
		else
			minetest.after(4, battle.stop, mt_player_name, context, {quit = true})
		end
	end
	battle.redraw_formspec(mt_player_name, player, enemy, context)
end

-- Waits for the PVP opponent to choose a new monster after previous monster dies in death sequence function
function battle.pvp_death_switch_wait(mt_player_name, player, enemy, context)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	local enemy_player = minetest.get_player_by_name(context.pvp_enemy or "")
	local enemy_meta = enemy_player and enemy_player:get_meta()
	local enemy_move = enemy_meta and enemy_meta:get_int("zoonami_battle_new_monster")
	if enemy_move and enemy_move ~= 0 then
		context.enemy_current_monster = enemy_move
		enemy = context.enemy_monsters["monster#"..context.enemy_current_monster]
		enemy_meta:set_int("zoonami_battle_new_monster", 0)
		context.enemy_texture_modifier = ""
		battle.regain_energy(player, enemy)
		battle.increment_move_cooldown(player, enemy)
		context.locked = false
		battle.update(mt_player_name, {main_menu = true, silent = true}, context)
	else
		minetest.after(2, battle.pvp_death_switch_wait, mt_player_name, player, enemy, context)
	end
end

-- Adds rewards that will be given after battle
function battle.add_rewards(context, enemy)
	if context.battle_type == "pvp" then return end
	local coins = (math.log(enemy.level + 10, 10) * 24) - 22
	local trainer_bonus = context.battle_type == "trainer" and 1.5 or 1
	context.coins = math.ceil(context.coins + (coins * trainer_bonus))
	local rewards_chance = monsters.stats[enemy.asset_name].rewards_chance
	if math.random(rewards_chance) == 1 then
		local rewards = monsters.stats[enemy.asset_name].rewards
		table.insert(context.rewards, rewards[math.random(#rewards)])
		if math.random(3) == 1 then
			table.insert(context.rewards, rewards[math.random(#rewards)])
		end
	end
end

-- Give EXP
function battle.give_exp(mt_player_name, player, enemy, context)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	if context.battle_type == "pvp" then
		battle.redraw_formspec(mt_player_name, player, enemy, context)
	elseif player.level < 100 then
		local exp_gained = math.floor((enemy.level * enemy.base.exp_per_level / 1.5) * exp_multiplier)
		player.exp_total = player.exp_total + exp_gained
		local new_level = math.min(math.floor(math.sqrt(player.exp_total / player.base.exp_per_level)),100)
		if player.level ~= new_level then
			local new_move = nil
			for i = player.level + 1, new_level do
				new_move = new_move or player.base.level_up_moves[i]
				table.insert(player.move_pool, player.base.level_up_moves[i])
			end
			player.level = new_level
			player = monsters.load_stats(player)
			minetest.after(4, function()
            	minetest.sound_play("zoonami_level_up", {to_player = mt_player_name, gain = 1 * context.sfx_volume}, true)
            	if new_move then
					context.textbox = fs.dialogue((player.nickname or player.name).." grew to level "..player.level.." and learned "..move_stats[new_move].name.."!", context.zoom)
            	else
					context.textbox = fs.dialogue((player.nickname or player.name).." grew to level "..player.level.."!", context.zoom)
				end
				battle.redraw_formspec(mt_player_name, player, enemy, context)
			end)
		else
			minetest.after(4, function()
				context.textbox = fs.dialogue((player.nickname or player.name).." gained "..exp_gained.." EXP!", context.zoom)
				battle.redraw_formspec(mt_player_name, player, enemy, context)
			end)
		end
	end
end

-- Ends the entire battle and saves the monster stats
function battle.stop(mt_player_name, context, fields)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	fields = fields or {}
	local meta = mt_player_obj:get_meta()
	if context.battle_type ~= "pvp" then
		for i = 1, 5 do
			local monster = context.player_monsters["monster#"..i]
			if monster then
				monster.energy = monster.max_energy
				meta:set_string("zoonami_monster_"..i, minetest.serialize(monsters.save_stats(monster)))
			end
		end
	end
	minetest.sound_fade(tonumber(meta:get_string("zoonami_music_handler")), 1.8, 0)
	meta:set_string("zoonami_battle_session_id", "0")
	if not fields.quit and (#context.rewards > 0 or context.coins > 0) then
		battle.rewards(mt_player_name, context)
	else
		if fields.quit and context.battle_rules and not context.battle_rules.casual then
			local pvp_forfeits = meta:get_int("zoonami_pvp_forfeits")
			meta:set_int("zoonami_pvp_forfeits", pvp_forfeits + 1)
		end
		meta:set_string("zoonami_battle_pvp_enemy", "")
		battle.stop_turn_timer(mt_player_obj, context)
		battle.player_invincibility(mt_player_obj, context, false)
		minetest.close_formspec(mt_player_name, "")
	end
end

-- Shows rewards formspec if any were dropped
function battle.rewards(mt_player_name, context)
	local mt_player_obj = minetest.get_player_by_name(mt_player_name)
	if not mt_player_obj then return end
	local meta = mt_player_obj:get_meta()
	local spacing = 6 / (#context.rewards + 1)
	local formspec = fs.header(6, 6, "true", "#00000000", context.zoom)..
		fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88, context.zoom)..
		fs.button_style(1, 8)..
		fs.font_style("image_button,tooltip,label", "mono,bold", 20, "#eeeeee", context.zoom)..
		fs.font_style("button", "mono,bold", 16, "#000000", context.zoom)..
		fs.label(1.4, 0.5, "Battle Rewards", context.zoom)
	if #context.rewards > 0 then
		formspec = formspec..
			fs.image_button(0, 1.5, 6, 0.59, "zoonami_blank", "label", context.coins.." ZC", context.zoom)..
			fs.box(0, 1.5, 6, 0.59, "#00000000", context.zoom)..
			fs.button(0.25, 5, 2.75, 0.75, "claim", "Claim Items", context.zoom)..
			fs.button(3, 5, 2.75, 0.75, "discard", "Discard Items", context.zoom)
	else
		formspec = formspec..
			fs.image_button(0, 2.5, 6, 0.59, "zoonami_blank", "label", context.coins.." ZC", context.zoom)..
			fs.box(0, 2.5, 6, 0.59, "#00000000", context.zoom)..
			fs.button(2, 5, 2, 0.5, "ok", "Ok", context.zoom)
	end
	for i = 1, #context.rewards do
		formspec = formspec..
			fs.item_image_button((spacing*i)-0.5, 2.5, 1, 1, context.rewards[i], "reward#"..i, context.zoom)
	end
	fsc.show(mt_player_name, formspec, context, battle.rewards_fsc_callback)
end

-- Rewards callback from fsc mod
function battle.rewards_fsc_callback(mt_player_obj, fields, context)
	local mt_player_name = mt_player_obj:get_player_name()
	local meta = mt_player_obj:get_meta()
	local player_zc = meta:get_int("zoonami_coins")
	meta:set_int("zoonami_coins", player_zc + context.coins)
	if not fields.discard then
		local inv = mt_player_obj:get_inventory()
		for _,v in pairs(context.rewards) do
			local leftover = inv:add_item("main", v)
			if leftover:get_count() > 0 then
				minetest.add_item(mt_player_obj:get_pos(), leftover)
			end
		end
	end
	battle.stop_turn_timer(mt_player_obj, context)
	battle.player_invincibility(mt_player_obj, context, false)
	return true
end

-- Creates the formspec and shows it to the player
function battle.redraw_formspec(mt_player_name, player, enemy, context)
	local mt_player_obj = battle.player_check(mt_player_name, context, false)
	if not mt_player_obj then return end
	local formspec = 
        fs.header(6, 6, "true", "#00000000", context.zoom)..
		fs.background(0, 0, 6, 6, context.biome_background, context.zoom)..
		(context.chat_bar_visible and context.chat_bar or "")..
		fs.image(3.585, 0, 2.4151, 2.4151, "zoonami_"..enemy.asset_name.."_front"..(enemy.prisma_id or "")..".png"..context.enemy_texture_modifier, context.zoom)..
		fs.image(0, 2.4151, 2.4151, 2.4151, "zoonami_"..player.asset_name.."_back"..(player.prisma_id or "")..".png"..context.player_texture_modifier, context.zoom)..
		context.animation..
		fs.image(0, 0, 6, 6, "zoonami_textboxes_background.png", context.zoom)..
		(enemy.prisma_id and fs.image(3.2, 0.05, 0.314, 0.314, "zoonami_prisma_icon.png^[opacity:180", context.zoom) or "")..
		(player.prisma_id and fs.image(5.65, 2.75, 0.314, 0.314, "zoonami_prisma_icon.png^[opacity:180", context.zoom) or "")..
		fs.font_style("button,image_button,tooltip,label", "mono,bold", 16, "#000000", context.zoom)..
		fs.font_style("textarea", "mono,bold", 15, "#000000", context.zoom)..
		fs.label(0.1, 0.3, enemy.name, context.zoom)..
		fs.label(0.1, 0.6, "Level: "..enemy.level, context.zoom)..
		fs.box(1.5, 0.75, enemy.health/enemy.max_health*2, 0.25, "#25C425FF", context.zoom)..
		fs.label(0.1, 0.9, "Health: "..enemy.health.."/"..enemy.max_health, context.zoom)..
		fs.box(1.5, 1.05, enemy.energy/enemy.max_energy*2, 0.25, "#29B4DBFF", context.zoom)..
		fs.label(0.1, 1.2, "Energy: "..enemy.energy.."/"..enemy.max_energy, context.zoom)..
		fs.label(0.1, 1.42, context.enemy_monster_count_ui, context.zoom)..
		fs.label(2.515, 2.975, (player.nickname or player.name), context.zoom)..
		fs.label(2.515, 3.275, "Level: "..player.level, context.zoom)..
		fs.box(3.915, 3.425, player.health/player.max_health*2, 0.25, "#25C425FF", context.zoom)..
		fs.label(2.515, 3.575, "Health: "..player.health.."/"..player.max_health, context.zoom)..
		fs.box(3.915, 3.725, player.energy/player.max_energy*2, 0.25, "#29B4DBFF", context.zoom)..
		fs.label(2.515, 3.875, "Energy: "..player.energy.."/"..player.max_energy, context.zoom)..
		context.menu..
		context.textbox..
		context.animation_value
	fsc.show(mt_player_name, formspec, context, battle.fsc_callback)
end
