-- Manages everything involving the backpack and backpack formspec

-- Local namespace
local backpack = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local move_stats = dofile(mod_path .. "/lua/move_stats.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Craft Item
minetest.register_craftitem(modname .. ":zoonami_backpack", {
	description = "Zoonami Backpack",
	inventory_image = "zoonami_backpack.png",
	stack_max = 1,
	on_secondary_use = function (itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end
		backpack.show_formspec(user)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		if not placer or not placer:is_player() then return end
		local node = minetest.get_node_or_nil(pointed_thing.under)
		local def = node and minetest.registered_nodes[node.name] or {}
		if def.on_rightclick then
			return def.on_rightclick(pointed_thing.under, node, placer, itemstack)
		else
			backpack.show_formspec(placer)
		end
	end,
})

-- Callback from fsc mod
function backpack.fsc_callback(player, fields, context)
	if not fields.quit then
		backpack.receive_fields(player, fields, context)
	end
end

-- Handle button presses
function backpack.receive_fields(player, fields, context)
	local player_name = player:get_player_name()
	local meta = player:get_meta()
	local host = fields["battle_hosting&host_battle"]
	local join = fields["battle_hosting&join_battle"]
	local filtered_fields = table.copy(fields)
	filtered_fields.key_enter = nil
	filtered_fields.key_enter_field = nil
	filtered_fields.monsters_scroll_container = nil
	filtered_fields.rename_field = nil
	filtered_fields["battle_hosting&host_battle"] = fields.key_enter and host ~= "" and host or nil
	filtered_fields["battle_hosting&join_battle"] = fields.key_enter and join ~= "" and join or nil
	local field_key = next(filtered_fields) or ""
	local field_function = string.match(field_key, "^(.-)&")
	local field_sub_key = string.match(field_key, "^.-&(.*)$")
	if backpack.fields[field_function] and field_sub_key then
		backpack.fields[field_function](meta, field_sub_key, fields, player, context)
	end
	if field_key ~= "" then
		minetest.sound_play("zoonami_select2", {to_player = player_name, gain = 0.5}, true)
		backpack.show_formspec(player, fields, context)
	end
end

-- Button press functions
backpack.fields = {}

-- Change page
function backpack.fields.page(meta, field_sub_key, fields, player, context)
	local page = field_sub_key:split("&")[1]
	local subpage = field_sub_key:split("&")[2]
	local valid_pages = {monsters = true, stats = true, items = true, pvp = true, player_stats = true, settings = true}	
	if page and valid_pages[page] then
		meta:set_string("zoonami_backpack_page", page)
		meta:set_string("zoonami_backpack_subpage", subpage or "")
	end
end

-- Choose Starter Monster - Monsters Page
function backpack.fields.choose_starter_monster(meta, field_sub_key, fields, player, context)
	local zoonami_chose_starter = meta:get_string("zoonami_chose_starter")
	local monster_id = tonumber(string.match(field_sub_key, "^([123])$"))
	if zoonami_chose_starter ~= "true" and monster_id then
		meta:set_string("zoonami_chose_starter", "true")
		local monster_pool = {"burrlock", "merin", "scallapod"}
		local chosen_monster = monsters.generate(monster_pool[monster_id], 10, {})
		chosen_monster.starter_monster = true
		meta:set_string("zoonami_monster_1", minetest.serialize(monsters.save_stats(chosen_monster)))
		zoonami.monster_journal_tamed_monster(meta, monster_pool[monster_id])
	end
end

-- Move Monster - Monsters Page
function backpack.fields.move_monster(meta, field_sub_key, fields, player, context)
	local slot_id = tonumber(string.match(field_sub_key, "^([12345])_[-]?[1]$"))
	local direction = tonumber(string.match(field_sub_key, "^[12345]_([-]?[1])$"))
	if slot_id and direction then
		local new_slot_id = slot_id + direction
		if slot_id >= 1 and slot_id <=5 and new_slot_id >= 1 and new_slot_id <= 5 then
			local monster1 = meta:get_string("zoonami_monster_"..slot_id)
			local monster2 = meta:get_string("zoonami_monster_"..new_slot_id)
			meta:set_string("zoonami_monster_"..new_slot_id, monster1)
			meta:set_string("zoonami_monster_"..slot_id, monster2)
		end
	end
end

-- Showcase Monster - Monsters Page
function backpack.fields.showcase_monster(meta, field_sub_key, fields, player, context)
	local slot_id = tonumber(string.match(field_sub_key, "^([12345])$"))
	if slot_id then
		local player_name = player:get_player_name()
		local player_pos = player:get_pos()
		local showcase_id = meta:get_string("zoonami_showcase_monster_id")
		local random_id = assert(SecureRandom()):next_bytes(16)
		local monster = meta:get_string("zoonami_monster_"..slot_id)
		monster = minetest.deserialize(monster)
		if monster then
			if showcase_id ~= "" then
				local objs = minetest.get_objects_inside_radius(player_pos, 20)
				for _,obj in ipairs(objs) do
					if not obj:is_player() then
						local luaent = obj:get_luaentity()
						if luaent and luaent.name:find('zoonami_') then
							if luaent._showcase_id == showcase_id then
								luaent.object:remove()
								return
							end
						end
					end
				end
			end
			meta:set_string("zoonami_showcase_monster_id", random_id)
			local yaw = player:get_look_horizontal()
			local dir = vector.multiply(minetest.yaw_to_dir(yaw), 4)
			local start_pos = vector.add(player_pos, dir)
			for i = 1, 6 do
				local spawn_pos = vector.offset(start_pos, 0, i-2, 0)
				local node = minetest.get_node(spawn_pos)
				if node.name == "air" then
					local def = minetest.registered_entities[modname .. ":zoonami_"..monster.asset_name]
					spawn_pos = vector.offset(spawn_pos, 0, -def.initial_properties.collisionbox[2], 0)
					local staticdata = {
						prisma_id = monster.prisma_id,
						life_timer = 1,
						state = "follow",
						nametag = player_name,
						showcase_id = random_id,
						on_rightclick_disabled = true,
					}
					staticdata = minetest.serialize(staticdata)
					local obj = minetest.add_entity(spawn_pos, modname .. ":zoonami_"..monster.asset_name, staticdata)
					return
				end
			end
		end
	end
end

-- Remap Move - Monsters Page
function backpack.fields.remap_move(meta, field_sub_key, fields, player, context)
	local slot_id = tonumber(string.match(field_sub_key, "^([12345])_[1234]$"))
	local move_id = tonumber(string.match(field_sub_key, "^[12345]_([1234])$"))
	if slot_id and move_id then
		local monster = meta:get_string("zoonami_monster_"..slot_id)
		monster = minetest.deserialize(monster)
		if monster then
			local move_pool = table.copy(monster.move_pool)
			table.sort(move_pool)
			local current_move = monster.moves[move_id]
			local current_move_index = false
			local moves = {}
			for k, v in pairs (monster.moves) do
				moves[v] = true
			end
			for i, v in ipairs (move_pool) do
				if not current_move and not moves[v] then
					monster.moves[move_id] = move_pool[i]
					break
				elseif i == #move_pool then
					monster.moves[move_id] = nil
				elseif v == current_move or current_move_index then
					if not moves[move_pool[i+1]] then
						monster.moves[move_id] = move_pool[i+1]
						break
					end
					current_move_index = true
				end
			end
			meta:set_string("zoonami_monster_"..slot_id, minetest.serialize(monsters.save_stats(monster)))
		end
	end
end

-- Rename Monster - Stats Page
function backpack.fields.rename_monster(meta, field_sub_key, fields, player, context)
	local monster_id = field_sub_key
	local monster = meta:get_string("zoonami_monster_"..monster_id)
	monster = minetest.deserialize(monster)
	if monster then
		local nickname = minetest.formspec_escape(fields.rename_field or "")
		monster.nickname = nickname ~= "" and string.sub(nickname, 1, 9) or nil
		meta:set_string("zoonami_monster_"..monster_id, minetest.serialize(monsters.save_stats(monster)))
	end
end

-- Battle Hosting - PVP Page
function backpack.fields.battle_hosting(meta, field_sub_key, fields, player, context)
	local name = fields["battle_hosting&"..field_sub_key]:gsub('[^%w%-_]','')
	meta:set_string("zoonami_pvp_id", "")
	meta:set_string("zoonami_host_battle", "")
	meta:set_string("zoonami_join_battle", "")
	if field_sub_key == "host_battle" then
		local session_id = assert(SecureRandom()):next_bytes(16)
		meta:set_string("zoonami_pvp_id", session_id)
		meta:set_string("zoonami_host_battle", name)
	elseif field_sub_key == "join_battle" then
		meta:set_string("zoonami_join_battle", name)
	end
end

-- Battle Rules - PVP Page
function backpack.fields.battle_rules(meta, field_sub_key, fields, player, context)
	local pvp_id = meta:get_string("zoonami_pvp_id")
	local host_battle = meta:get_string("zoonami_host_battle")
	if pvp_id == "" and host_battle == "" then
		local rule, value = string.match(field_sub_key, "^(.*)&(.*)$")
		local valid_rules = {
			casual = {On = true, Off = true, default = "Off"},
			auto_level = {On = true, Off = true, default = "On"},
			max_level = {["-10"] = -10, ["10"] = 10, min = 10, max = 100, default = 100},
			turn_time = {["-10"] = -10, ["10"] = 10, min = 10, max = 120, default = 60},
			max_monsters = {["-1"] = -1, ["1"] = 1, min = 1, max = 5, default = 5},
			max_tier = {["-1"] = -1, ["1"] = 1, min = 1, max = 5, default = 1},
		}
		if rule and value and valid_rules[rule] and valid_rules[rule][value] then
			local battle_rules = minetest.deserialize(meta:get_string("zoonami_battle_rules")) or {}
			local new_rule = valid_rules[rule]
			if rule == "casual" or rule == "auto_level" then
				battle_rules[rule] = battle_rules[rule] == nil and new_rule.default or battle_rules[rule] == "Off" and "On" or "Off"
			else
				battle_rules[rule] = math.max(math.min((battle_rules[rule] or new_rule.default) + new_rule[value], new_rule.max), new_rule.min)
			end
			meta:set_string("zoonami_battle_rules", minetest.serialize(battle_rules))
		end
	end
end

-- Settings - Settings Page
function backpack.fields.settings(meta, field_sub_key, fields, player, context)
	local setting, value = string.match(field_sub_key, "^(.*)&(.*)$")
	local valid_settings = {
		backpack_gui_zoom = {["-0.1"] = -0.1, ["0.1"] = 0.1, min = 0.5, max = 4},
		battle_gui_zoom = {["-0.5"] = -0.5, ["0.5"] = 0.5, min = 1, max = 4},
		battle_music_volume = {["-0.1"] = -0.1, ["0.1"] = 0.1, min = 0, max = 2},
		battle_sfx_volume = {["-0.1"] = -0.1, ["0.1"] = 0.1, min = 0, max = 1},
		battle_chat_bar = {bool = true},
	}
	if setting and value and valid_settings[setting] and valid_settings[setting][value] then
		if value == "bool" then
			local new_value = meta:get("zoonami_"..setting) == nil and "true" or nil
			meta:set_string("zoonami_"..setting, new_value)
		else
			local current_value = meta:get_float("zoonami_"..setting)
			current_value = math.min(math.max(current_value + valid_settings[setting][value], valid_settings[setting].min), valid_settings[setting].max)
			meta:set_float("zoonami_"..setting, current_value)
		end
	end
end

-- Shows formspec
function backpack.show_formspec(player, fields, context)
	fields = fields or {}
	context = context or {}
	local fields_copy = table.copy(fields)
	local player_name = player:get_player_name()
	local meta = player:get_meta()
	context.zoom = meta:get_float("zoonami_backpack_gui_zoom")
	local page = meta:get_string("zoonami_backpack_page")
	local formspec = fs.header(9, 9, "true", "#00000000", context.zoom)..
		fs.list_colors("#777", "#5A5A5A", "#141318", "#30434C", "#FFF")..
		fs.button_style(1, 8)..
		backpack["fields_"..page](player, fields_copy, context)
	fsc.show(player_name, formspec, context, backpack.fsc_callback)
end

-- Monsters Page
function backpack.fields_monsters(player, fields, context)
	local meta = player:get_meta()
	local zoonami_chose_starter = meta:get_string("zoonami_chose_starter")
	local formspec = fs.backpack_header("page&settings", "page&items", "Monsters", context.zoom)
	if zoonami_chose_starter ~= "true" then
		formspec = formspec..
			fs.image_button(2.5, 1, 4, 0.59, "zoonami_blank", "label", "Choose a starter", context.zoom)..
			fs.box(2.5, 1, 4, 0.59, "#00000000", context.zoom)..
			fs.button(3, 2.5, 3, 0.51, "choose_starter_monster&1", "Burrlock", context.zoom)..
			fs.button(3, 4.5, 3, 0.51, "choose_starter_monster&2", "Merin", context.zoom)..
			fs.button(3, 6.5, 3, 0.51, "choose_starter_monster&3", "Scallapod", context.zoom)..
			fs.image(2.25, 2, 1.21, 1.21, "zoonami_burrlock_front.png", context.zoom)..
			fs.image(2.25, 4, 1.21, 1.21, "zoonami_merin_front.png", context.zoom)..
			fs.image(2.25, 6, 1.21, 1.21, "zoonami_scallapod_front.png", context.zoom)
	else
		local scroll_value = minetest.explode_scrollbar_event(fields.monsters_scroll_container).value
		formspec = formspec..
			fs.scroll_container(0, 1, 9, 7.55, "monsters_scroll_container", "vertical", "0.1", context.zoom)
		for i = 1, 5 do
			local monster = meta:get_string("zoonami_monster_"..i)
			monster = minetest.deserialize(monster)
			monster = monster and monsters.load_stats(monster)
			local y_spacing = ((i-1)*4)
			if monster then
				formspec = formspec..
					fs.image(0.7, 0.1+y_spacing, 2.4151, 2.4151, "zoonami_"..monster.asset_name.."_front"..(monster.prisma_id or "")..".png", context.zoom)..
					fs.label(3.4, 0.275+y_spacing, (monster.nickname or monster.name), context.zoom)..
					fs.label(3.4, 0.575+y_spacing, "Level: "..monster.level, context.zoom)..
					fs.label(3.4, 0.875+y_spacing, "Type: "..monster.type, context.zoom)..
					fs.label(3.4, 1.175+y_spacing, "Health: "..monster.health.."/"..monster.max_health, context.zoom)..
					fs.label(3.4, 1.475+y_spacing, "Energy: "..monster.energy.."/"..monster.max_energy, context.zoom)..
					fs.label(3.4, 1.775+y_spacing, "Attack: "..monster.attack, context.zoom)..
					fs.label(3.4, 2.075+y_spacing, "Defense: "..monster.defense, context.zoom)..
					fs.label(3.4, 2.375+y_spacing, "Agility: "..monster.agility, context.zoom)..
					fs.button(7.5, 0.1+y_spacing, 1, 0.45, "move_monster&"..i.."_-1", "▲", context.zoom)..
					fs.button(7.5, 0.6+y_spacing, 1, 0.45, "move_monster&"..i.."_1", "▼", context.zoom)..
					fs.font_style("button", "mono,bold", 18, "#EE3333", context.zoom)..
					fs.button(7.5, 1.1+y_spacing, 1, 0.45, "showcase_monster&"..i, "♥", context.zoom)..
					fs.font_style("button", "mono,bold", 24, "#3333EE", context.zoom)..
					fs.button(7.5, 1.6+y_spacing, 1, 0.45, "page&stats&"..i.."", "≡", context.zoom)..
					fs.font_style("button", "mono,bold", 16, "#000000", context.zoom)
				for ii = 1, 4 do
					local x_coord = ii > 2 and ((ii-2)*3)-1.5 or (ii*3)-1.5
					local y_coord = ii > 2 and 3.1 or 2.6
					if monster.moves[ii] then
						local move_name = monster.moves[ii]
						formspec = formspec..
							fs.menu_image_button(x_coord, y_coord+y_spacing, 3, 0.5, 5, "remap_move&"..i.."_"..ii, move_stats[move_name].name, context.zoom)..
							fs.tooltip("remap_move&"..i.."_"..ii, move_stats.tooltip(move_name), "#ffffff", "#000000")
					else
						formspec = formspec..
							fs.menu_image_button(x_coord, y_coord+y_spacing, 3, 0.5, 5, "remap_move&"..i.."_"..ii, "", context.zoom)
					end
				end
			else
				formspec = formspec..
					fs.box(0.7, 0.1+y_spacing, 7.7, 3.3, "#00000033", context.zoom)..
					fs.label(4, 1.6+y_spacing, "Slot #"..i, context.zoom)
			end
		end
		formspec = formspec..
			fs.scroll_container_end(0, 120, 20, context.zoom)..
			fs.scrollbar(8.72, 1, 0.21, 7.5, "vertical", "monsters_scroll_container", scroll_value, context.zoom)
	end
	return formspec
end

-- Monster Stats Page
function backpack.fields_stats(player, fields, context)
	local meta = player:get_meta()
	local subpage = meta:get_string("zoonami_backpack_subpage")
	local formspec = fs.font_style("button,image_button,tooltip,label", "mono,bold", 16, "#000000", context.zoom)..
		fs.font_style("textarea,field", "mono", 15, "#000000", context.zoom)..
		fs.background(0, 0, 9, 9, "zoonami_backpack_background.png", context.zoom)..
		fs.button(0.5, 0.5, 1.5, 0.5, "page&monsters", "Back", context.zoom)
	
	local monster = meta:get_string("zoonami_monster_"..subpage)
	monster = minetest.deserialize(monster)
	monster = monster and monsters.load_stats(monster)
	if monster then
		local next_level = monster.level + 1
		local next_exp_milestone = next_level * next_level * monster.base.exp_per_level
		local exp_needed_for_level_up = next_exp_milestone - monster.exp_total
		if monster.level >= 100 then
			exp_needed_for_level_up = 0
		end
		local monster_moves = ""
		for i = 1, #monster.move_pool do
			local move_name = monster.move_pool[i]
			monster_moves = monster_moves..
				(i > 1 and ", " or "")..move_stats[move_name].name
		end
		local textarea = "Name: "..monster.name..
			(monster.nickname and "\nNickname: "..monster.nickname or "")..
			"\nLevel: "..monster.level..
			"\nType: "..monster.type..
			"\n\nEnergy: "..monster.max_energy..
			"\n\nHealth: "..monster.max_health..
			"\nBoost: "..((monster.boost.health - 1) * 100).."%"..
			"\n\nAttack: "..monster.attack..
			"\nBoost: "..((monster.boost.attack - 1) * 100).."%"..
			"\n\nDefense: "..monster.defense..
			"\nBoost: "..((monster.boost.defense - 1) * 100).."%"..
			"\n\nAgility: "..monster.agility..
			"\nBoost: "..((monster.boost.agility - 1) * 100).."%"..
			"\n\nNext Level: "..exp_needed_for_level_up.." EXP"..
			"\nEXP Total: "..monster.exp_total.." EXP"..
			(monster.prisma_id and "\n\nPrisma Color: "..monster.prisma_id or "")..
			"\n\nPersonality: "..monster.personality..
			(monster.base.morph_level and "\n\nMorph Level: "..monster.base.morph_level or "")..
			(monster.base.morphs_into and "\nMorphs Into: "..monsters.stats[monster.base.morphs_into].name or "")..
			"\n\nMoves: "..monster_moves
		formspec = formspec..
			fs.image(0.5, 1.3, 2.4151, 2.4151, "zoonami_"..monster.asset_name.."_front"..(monster.prisma_id or "")..".png", context.zoom)..
			fs.field(0.5, 4, 2.5, 0.6, "rename_field", "", "", context.zoom)..
			"field_close_on_enter[rename_field;false]"..
			fs.button(0.5, 4.6, 2.5, 0.6, "rename_monster&"..subpage, "Rename", context.zoom)..
			fs.textarea(3.25, 1.3, 5.25, 7, textarea, context.zoom)
	end
	return formspec
end

-- Items Page
function backpack.fields_items(player, fields, context)
	local inv = player:get_inventory()
	local inv_size = inv:get_size("main")
	local inv_rows = math.floor(inv_size / 8)
	local inv_columns = inv_size / inv_rows
	local inv_margin = 0.75
	local inv_padding = 0.1
	local inv_slot_max_width = (9 - (inv_margin * 2) - ((inv_columns - 1) * inv_padding)) / inv_columns
	local inv_slot_max_height = (4 - ((inv_rows - 1) * inv_padding)) / inv_rows
	local inv_slot_size = math.min(inv_slot_max_width, inv_slot_max_height)
	local inv_x_pos = (9 - ((inv_margin * 2) + (inv_padding * (inv_columns - 1)) + (inv_slot_size * inv_columns))) / 2
	return fs.backpack_header("page&monsters", "page&pvp", "Items", context.zoom)..
		fs.list_style("false", 1, 0.25, context.zoom)..
		fs.list("current_player", "zoonami_backpack_items", 0.9, 1.5, 6, 2, 0, context.zoom)..
		fs.list_style("false", inv_slot_size, inv_padding, context.zoom)..
		fs.list("current_player", "main", inv_x_pos + inv_margin, 4.5, inv_columns, inv_rows, 0, context.zoom)..
		fs.listring("current_player", "main")..
		fs.listring("current_player", "zoonami_backpack_items")
end

-- PVP Page
function backpack.fields_pvp(player, fields, context)
	local player_name = player:get_player_name()
	local player_pos = player:get_pos()
	local meta = player:get_meta()
	local player_host_battle = meta:get("zoonami_host_battle")
	local player_join_battle = meta:get("zoonami_join_battle")
	local player_battle_rules = minetest.deserialize(meta:get_string("zoonami_battle_rules")) or {}
	local opponent = minetest.get_player_by_name(player_join_battle or "")
	local opponent_pos = opponent and opponent:get_pos() or vector.new()
	local opponent_meta = opponent and opponent:get_meta()
	local opponent_pvp_id = opponent_meta and opponent_meta:get_string("zoonami_pvp_id")
	local opponent_host_battle = opponent_meta and opponent_meta:get_string("zoonami_host_battle")
	local opponent_battle_rules = opponent_meta and minetest.deserialize(opponent_meta:get_string("zoonami_battle_rules")) or {}
	local accept_battle = fields.accept_battle
	local battle_distance = vector.distance(player_pos, opponent_pos)
	
	-- Default rules
	local rules = player_join_battle and opponent_battle_rules or player_battle_rules
	rules.casual = rules.casual or "On"
	rules.auto_level = rules.auto_level or "Off"
	rules.max_level = tonumber(rules.max_level or "100")
	rules.turn_time = rules.turn_time or "60"
	rules.max_monsters = tonumber(rules.max_monsters or "5")
	rules.max_tier = tonumber(rules.max_tier or "1")
	
	-- Set status
	local status = "Host or join a battle"
	if accept_battle and context.pvp_id ~= opponent_pvp_id then
		status = "Opponent stopped hosting"
		meta:set_string("zoonami_join_battle", "")
		context.pvp_id = nil
	elseif player_join_battle and opponent_host_battle == player_name and accept_battle and battle_distance > 15 then
		status = "You're too far away to battle "..player_join_battle
	elseif player_join_battle and opponent_host_battle == player_name then
		status = "Joined "..player_join_battle
		context.pvp_id = context.pvp_id or opponent_pvp_id
	elseif player_join_battle and opponent_host_battle ~= player_name then
		status = "That player isn't hosting"
		meta:set_string("zoonami_join_battle", "")
	elseif player_host_battle then
		status = "Waiting for "..player_host_battle
	end
	
	-- Try to start battle
	if player_join_battle and opponent_host_battle == player_name and accept_battle and context.pvp_id == opponent_pvp_id and battle_distance <= 15 then
		local player_monsters = {}
		local enemy_monsters = {}
		local monster_count = {player = 0, enemy = 0}
		local usable_monster_count = {player = 0, enemy = 0}
		
		local function monster_check(meta, party_monsters, player)
			for i = 1, 5 do
				local monster = meta:get_string("zoonami_monster_"..i)
				monster = minetest.deserialize(monster)
				monster = monster and monsters.load_stats(monster)
				if monster then
					if (monster.level <= rules.max_level or rules.auto_level == "On") and monster.base.tier >= rules.max_tier then
						if rules.auto_level == "On" then
							monster.level = rules.max_level
							monster.max_health = monster.base.health + math.floor(monster.base.health_per_level * monster.boost.health * monster.level)
							monster.max_energy = math.min(math.ceil((monster.level + 1) / 10) * 2, monster.base.energy_cap)
							monster.attack = monster.base.attack + math.floor(monster.base.attack_per_level * monster.boost.attack * monster.level)
							monster.defense = monster.base.defense + math.floor(monster.base.defense_per_level * monster.boost.defense * monster.level)
							monster.agility = monster.base.agility + math.floor(monster.base.agility_per_level * monster.boost.agility * monster.level)
							local level_up_moves = monster.base.level_up_moves
							for ii = 1, 4 do
								local move_level = table.indexof(level_up_moves, monster.moves[ii])
								if move_level and move_level > monster.level then
									monster.moves[ii] = nil
								end
							end
						end
						monster.health = monster.max_health
						monster.energy = monster.max_energy
						party_monsters["monster#"..i] = monster
						monster_count[player] = monster_count[player] + 1
						if monster.health > 0 then
							usable_monster_count[player] = usable_monster_count[player] + 1
						end
						if monster_count[player] >= rules.max_monsters then
							break
						end
					end
				end
			end
		end
		
		monster_check(meta, player_monsters, "player")
		monster_check(opponent_meta, enemy_monsters, "enemy")
		
		if usable_monster_count.player == 0 or usable_monster_count.enemy == 0 then
			status = "Unable to start battle as at least one player would have no monsters"
		else
			local battle_rules = {}
			battle_rules.casual = rules.casual == "On" and true or false
			battle_rules.turn_time = tonumber(rules.turn_time)
			meta:set_string("zoonami_host_battle", "")
			meta:set_string("zoonami_join_battle", "")
			opponent_meta:set_string("zoonami_pvp_id", "")
			opponent_meta:set_string("zoonami_host_battle", "")
			opponent_meta:set_string("zoonami_join_battle", "")
			meta:set_string("zoonami_battle_pvp_enemy", player_join_battle)
			opponent_meta:set_string("zoonami_battle_pvp_enemy", player_name)
			minetest.after(0, function()
				zoonami.start_battle(player_name, table.copy(player_monsters), table.copy(enemy_monsters), "pvp", table.copy(battle_rules))
				zoonami.start_battle(player_join_battle, table.copy(enemy_monsters), table.copy(player_monsters), "pvp", table.copy(battle_rules))
			end)
			return ""
		end
	end
	
	local battle_rules = ""
	if player_host_battle or player_join_battle and opponent_host_battle == player_name then
		local host_header = fs.label(3.4, 3.75, "Battle Rules", context.zoom)
		local join_header = fs.button(2.75, 3.6, 1.5, 0.6, "accept_battle", "Accept", context.zoom)..
				fs.button(4.75, 3.6, 1.5, 0.6, "battle_hosting&clear_battle", "Reject", context.zoom)
		local rules_text = "Casual: "..rules.casual..
			"\n\nAuto Level: "..rules.auto_level..
			"\n\nMax Level: "..rules.max_level..
			"\n\nTurn Time: "..rules.turn_time..
			"\n\nMax Monsters: "..rules.max_monsters..
			"\n\nMax Tier: "..rules.max_tier
		battle_rules = fs.font_style("textarea", "mono", 15, "#000000", context.zoom)..
			(player_host_battle and host_header or join_header)..
			fs.textarea(0.75, 4.35, 7, 5, rules_text, context.zoom)
	else
		battle_rules = fs.label(3.4, 3.75, "Battle Rules", context.zoom)..
			fs.label(0.75, 4.25, "Casual: "..rules.casual, context.zoom)..
			fs.button(7.5, 3.95, 0.755, 0.45, "battle_rules&casual&On", rules.casual == "On" and "●" or "○", context.zoom)..
			fs.label(0.75, 5, "Auto Level: "..rules.auto_level, context.zoom)..
			fs.button(7.5, 4.7, 0.755, 0.45, "battle_rules&auto_level&On", rules.auto_level == "On" and "●" or "○", context.zoom)..
			fs.label(0.75, 5.75, "Max Level: "..rules.max_level, context.zoom)..
			fs.button(6.65, 5.45, 0.755, 0.45, "battle_rules&max_level&-10", "-", context.zoom)..
			fs.button(7.5, 5.45, 0.755, 0.45, "battle_rules&max_level&10", "+", context.zoom)..
			fs.label(0.75, 6.5, "Turn Time: "..rules.turn_time, context.zoom)..
			fs.button(6.65, 6.15, 0.755, 0.45, "battle_rules&turn_time&-10", "-", context.zoom)..
			fs.button(7.5, 6.15, 0.755, 0.45, "battle_rules&turn_time&10", "+", context.zoom)..
			fs.label(0.75, 7.25, "Max Monsters: "..rules.max_monsters, context.zoom)..
			fs.button(6.65, 6.95, 0.755, 0.45, "battle_rules&max_monsters&-1", "-", context.zoom)..
			fs.button(7.5, 6.95, 0.755, 0.45, "battle_rules&max_monsters&1", "+", context.zoom)..
			fs.label(0.75, 8, "Max Tier: "..rules.max_tier, context.zoom)..
			fs.button(6.65, 7.7, 0.755, 0.45, "battle_rules&max_tier&-1", "-", context.zoom)..
			fs.button(7.5, 7.7, 0.755, 0.45, "battle_rules&max_tier&1", "+", context.zoom)
	end
	
	local formspec = fs.backpack_header("page&items", "page&player_stats", "PVP", context.zoom)..
		fs.label(0.75, 1.5, "Host Battle:", context.zoom)..
		fs.field(3.1, 1.2, 4, 0.6, "battle_hosting&host_battle", "", "", context.zoom)..
		"field_close_on_enter[battle_hosting&host_battle;false]"..
		fs.label(0.75, 2.25, "Join Battle:", context.zoom)..
		fs.field(3.1, 1.95, 4, 0.6, "battle_hosting&join_battle", "", "", context.zoom)..
		"field_close_on_enter[battle_hosting&join_battle;false]"..
		fs.font_style("textarea", "mono", 15, "#000000", context.zoom)..
		fs.textarea(0.75, 2.7, 6.5, 0.8, "Status: "..status, context.zoom)..
		fs.button(7.3, 2.65, 1.2, 0.6, "battle_hosting&clear_battle", "Clear", context.zoom)..
		battle_rules
	return formspec
end

-- Player Stats Page
function backpack.fields_player_stats(player, fields, context)
	local meta = player:get_meta()
	local player_zc = meta:get_int("zoonami_coins")
	local pvp_wins = meta:get_int("zoonami_pvp_wins")
	local pvp_loses = meta:get_int("zoonami_pvp_loses")
	local pvp_forfeits = meta:get_int("zoonami_pvp_forfeits")
	local formspec = fs.backpack_header("page&pvp", "page&settings", "Player Stats", context.zoom)..
		fs.label(0.75, 1.5, "Bank: "..player_zc.." ZC", context.zoom)..
		fs.label(0.75, 2.25, "PVP Wins: "..pvp_wins, context.zoom)..
		fs.label(0.75, 3, "PVP Loses: "..pvp_loses, context.zoom)..
		fs.label(0.75, 3.75, "PVP Forfeits: "..pvp_forfeits, context.zoom)
	return formspec
end

-- Settings Page
function backpack.fields_settings(player, fields, context)
	local meta = player:get_meta()
	local backpack_gui_zoom = meta:get_float("zoonami_backpack_gui_zoom")
	local battle_gui_zoom = meta:get_float("zoonami_battle_gui_zoom")
	local battle_music_volume = meta:get_float("zoonami_battle_music_volume")
	local battle_sfx_volume = meta:get_float("zoonami_battle_sfx_volume")
	local battle_chat_bar = meta:get("zoonami_battle_chat_bar")
	return fs.backpack_header("page&player_stats", "page&monsters", "Settings", context.zoom)..
		fs.label(0.75, 1.5, "Backpack GUI Zoom: "..string.format("%.1f", backpack_gui_zoom)*(100).."%", context.zoom)..
		fs.button(6.65, 1.2, 0.755, 0.45, "settings&backpack_gui_zoom&-0.1", "-", context.zoom)..
		fs.button(7.5, 1.2, 0.755, 0.45, "settings&backpack_gui_zoom&0.1", "+", context.zoom)..
		fs.label(0.75, 2.25, "Battle GUI Zoom: "..string.format("%.1f", battle_gui_zoom)*(100).."%", context.zoom)..
		fs.button(6.65, 1.95, 0.755, 0.45, "settings&battle_gui_zoom&-0.5", "-", context.zoom)..
		fs.button(7.5, 1.95, 0.755, 0.45, "settings&battle_gui_zoom&0.5", "+", context.zoom)..
		fs.label(0.75, 3, "Battle Music Volume: "..string.format("%.1f", battle_music_volume)*(100).."%", context.zoom)..
		fs.button(6.65, 2.7, 0.755, 0.45, "settings&battle_music_volume&-0.1", "-", context.zoom)..
		fs.button(7.5, 2.7, 0.755, 0.45, "settings&battle_music_volume&0.1", "+", context.zoom)..
		fs.label(0.75, 3.75, "Battle SFX Volume: "..string.format("%.1f", battle_sfx_volume)*(100).."%", context.zoom)..
		fs.button(6.65, 3.45, 0.755, 0.45, "settings&battle_sfx_volume&-0.1", "-", context.zoom)..
		fs.button(7.5, 3.45, 0.755, 0.45, "settings&battle_sfx_volume&0.1", "+", context.zoom)..
		fs.label(0.75, 4.5, "Battle Chat Bar: "..(battle_chat_bar and "On" or "Off"), context.zoom)..
		fs.button(7.5, 4.2, 0.755, 0.45, "settings&battle_chat_bar&bool", battle_chat_bar and "●" or "○", context.zoom)
end
