-- Monster trading machine node and formspec

-- Local namespace
local trading_machine = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local move_stats = dofile(mod_path .. "/lua/move_stats.lua")
local sounds = dofile(mod_path .. "/lua/sounds.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Callback from fsc mod
function trading_machine.fsc_callback(player, fields, context)
	if fields.quit then
		trading_machine.end_session(player, context)
	else
		trading_machine.validate_session(context)
		trading_machine.formspec(player, fields, context)
	end
end

-- Get slots
function trading_machine.get_slots(context)
	local node_meta = minetest.get_meta(context.pos)
	local slots = {}
	for i = 1, 2 do
		slots[i] = {
			id = i,
			name = node_meta:get_string("zoonami_slot"..i.."_name"),
			session_id = node_meta:get_string("zoonami_slot"..i.."_session_id"),
			monster_id = node_meta:get_int("zoonami_slot"..i.."_monster_id"),
			ready = node_meta:get_string("zoonami_slot"..i.."_ready"),
		}
	end
	return slots[1], slots[2]
end

-- End session
function trading_machine.end_session(player, context)
	local player_name = player:get_player_name()
	local node_meta = minetest.get_meta(context.pos)
	local slots = {}
	slots[1], slots[2] = trading_machine.get_slots(context)
	node_meta:set_string("zoonami_slot1_ready", "")
	node_meta:set_string("zoonami_slot2_ready", "")
	for i = 1, 2 do
		if player_name == slots[i].name then
			node_meta:set_string("zoonami_slot"..i.."_name", "")
			node_meta:set_string("zoonami_slot"..i.."_session_id", "")
			node_meta:set_int("zoonami_slot"..i.."_monster_id", 0)
			local friend_slot_id = i == 1 and 2 or 1
			local friend = minetest.get_player_by_name(slots[friend_slot_id].name)
			if friend then
				trading_machine.fsc_callback(friend, {}, context)
			end
		end
	end
end

-- Clear session
function trading_machine.clear_session(context)
	local node_meta = minetest.get_meta(context.pos)
	node_meta:set_string("zoonami_slot1_name", "")
	node_meta:set_string("zoonami_slot1_session_id", "")
	node_meta:set_int("zoonami_slot1_monster_id", 0)
	node_meta:set_string("zoonami_slot1_ready", "")
	node_meta:set_string("zoonami_slot2_name", "")
	node_meta:set_string("zoonami_slot2_session_id", "")
	node_meta:set_int("zoonami_slot2_monster_id", 0)
	node_meta:set_string("zoonami_slot2_ready", "")
end

-- Validate session
function trading_machine.validate_session(context)
	local slot1, slot2 = trading_machine.get_slots(context)
	local player1 = minetest.get_player_by_name(slot1.name)
	local player2 = minetest.get_player_by_name(slot2.name)
	local player1_meta = player1 and player1:get_meta()
	local player2_meta = player2 and player2:get_meta()
	local player1_session_id = player1_meta and player1_meta:get_string("zoonami_trade_session_id") or ""
	local player2_session_id = player2_meta and player2_meta:get_string("zoonami_trade_session_id") or ""
	if player1_session_id ~= slot1.session_id or player2_session_id ~= slot2.session_id then
		trading_machine.clear_session(context)
	end
end

-- Return stats formspec
function trading_machine.monster_stats(meta, slot, x_pos)
	local formspec = ""
	local monster = meta:get_string("zoonami_monster_"..slot.monster_id)
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
			fs.textarea(x_pos, 1.6, 6.4, 7.1, textarea)
	end
	
	return formspec
end

-- Trading Machine Formspec
function trading_machine.formspec(player, fields, context)
	local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local player_slot = nil
	local friend_slot = nil
	local friend_update = nil
	local node_meta = minetest.get_meta(context.pos)
	local slot1, slot2 = trading_machine.get_slots(context)
	local field_key = next(fields) or ""
	local monster_id = tonumber(string.match(field_key, "^monster#([12345])$"))
	local ready = string.match(field_key, "^ready$")
	local cancel = string.match(field_key, "^cancel$")
	
	-- Determine player slot or return if there's already two players 
	if slot1.name == player_name then
		player_slot = slot1
		friend_slot = slot2
	elseif slot2.name == player_name then
		player_slot = slot2
		friend_slot = slot1
	elseif slot1.name == "" then
		local session_id = assert(SecureRandom()):next_bytes(16)
		node_meta:set_string("zoonami_slot1_session_id", session_id)
		player_meta:set_string("zoonami_trade_session_id", session_id)
		slot1.session_id = tostring(session_id)
		node_meta:set_string("zoonami_slot1_name", player_name)
		slot1.name = node_meta:get_string("zoonami_slot1_name")
		player_slot = slot1
		friend_slot = slot2
		friend_update = true
	elseif slot2.name == "" then
		local session_id = assert(SecureRandom()):next_bytes(16)
		node_meta:set_string("zoonami_slot2_session_id", session_id)
		player_meta:set_string("zoonami_trade_session_id", session_id)
		slot2.session_id = tostring(session_id)
		node_meta:set_string("zoonami_slot2_name", player_name)
		slot2.name = node_meta:get_string("zoonami_slot2_name")
		player_slot = slot2
		friend_slot = slot1
		friend_update = true
	else
		return
	end
	
	-- Friend meta
	local friend = minetest.get_player_by_name(friend_slot.name)
	local friend_meta = friend and friend:get_meta()
	
	-- Handle monster selection
	if monster_id and player_slot.ready == "" then
		local monster = player_meta:get_string("zoonami_monster_"..monster_id)
		monster = minetest.deserialize(monster)
		if monster and not monster.starter_monster then
			node_meta:set_int("zoonami_slot"..player_slot.id.."_monster_id", monster_id)
			player_slot.monster_id = node_meta:get_int("zoonami_slot"..player_slot.id.."_monster_id")
			friend_update = true
		end
	elseif ready and player_slot.monster_id ~= 0 and friend_slot.monster_id ~= 0 then
		node_meta:set_string("zoonami_slot"..player_slot.id.."_ready", "true")
		player_slot.ready = "true"
		friend_update = true
	elseif cancel and player_slot.monster_id ~= 0 then
		node_meta:set_int("zoonami_slot"..player_slot.id.."_monster_id", 0)
		player_slot.monster_id = 0
		node_meta:set_string("zoonami_slot"..player_slot.id.."_ready", "")
		player_slot.ready = ""
		node_meta:set_string("zoonami_slot"..friend_slot.id.."_ready", "")
		friend_slot.ready = ""
		friend_update = true
	end
	
	-- Complete the trade if both players are ready
	if player_slot.ready == "true" and friend_slot.ready == "true" then
		local monster1 = player_meta:get_string("zoonami_monster_"..player_slot.monster_id)
		local monster2 = friend_meta:get_string("zoonami_monster_"..friend_slot.monster_id)
		monster1 = minetest.deserialize(monster1)
		monster1 = monster1 and monsters.load_stats(monster1)
		monster2 = minetest.deserialize(monster2)
		monster2 = monster2 and monsters.load_stats(monster2)
		if monster1 and monster2 then
			monster1.nickname = nil
			monster2.nickname = nil
			player_meta:set_string("zoonami_monster_"..player_slot.monster_id, minetest.serialize(monsters.save_stats(monster2)))
			friend_meta:set_string("zoonami_monster_"..friend_slot.monster_id, minetest.serialize(monsters.save_stats(monster1)))
			minetest.sound_play("zoonami_level_up", {to_player = player_slot.name, gain = 1}, true)
			minetest.sound_play("zoonami_level_up", {to_player = friend_slot.name, gain = 1}, true)
			zoonami.monster_journal_tamed_monster(player_meta, monster2.asset_name)
			zoonami.monster_journal_tamed_monster(friend_meta, monster1.asset_name)
			minetest.log("action", player_slot.name.." traded "..monster1.name.." and "..friend_slot.name.." traded "..monster2.name)
		end
		trading_machine.clear_session(context)
		minetest.close_formspec(player_slot.name, "")
		minetest.close_formspec(friend_slot.name, "")
		return
	end
	
	-- Show formspec
	local formspec = fs.header(14, 10, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_blue_background.png", "true", 88)..
		fs.box(6.95, 0.1, 0.1, 10, "#000000FF")..
		fs.box(0.5, 1.5, 6.4, 7.3, "#00000022")..
		fs.box(7.1, 1.5, 6.4, 7.3, "#00000022")..
		fs.font_style("button,image_button,label", "mono,bold", "*1", "#000000")..
		fs.font_style("textarea", "mono", "*0.94", "#000000")..
		fs.button_style(1, 8)
	
	-- Show monster slots or show stats if already selected
	if player_slot.monster_id == 0 then
		local monster_slots = ""
		for i = 1, 5 do
			local monster = player_meta:get_string("zoonami_monster_"..i)
			monster = minetest.deserialize(monster)
			monster = monster and monsters.load_stats(monster)
			if monster then
				monster_slots = monster_slots..
					fs.button(0.5, 1.85 + (i - 1) * 1.4, 6.4, 1, "monster#"..i, (monster.nickname or monster.name).." Lvl "..monster.level.."\nH:"..monster.health.."/"..monster.max_health.."  E:"..monster.energy.."/"..monster.max_energy)..
					fs.image(0.5, 1.65 + (i - 1) * 1.4, 1.21, 1.21, "zoonami_"..monster.asset_name.."_front.png")
			else
				monster_slots = monster_slots..
					fs.button(0.5, 1.85 + (i - 1) * 1.4, 6.4, 1, "monster#0", "Slot #"..i)
			end
		end
		if monster_id and player_slot.ready == "" then
			formspec = formspec..
				fs.textarea(0.5, 0.5, 6.4, 1, "Can't trade your starter monster...")..
				monster_slots
		else
			formspec = formspec..
				fs.textarea(0.5, 0.5, 6.4, 1, "Select your monster to trade...")..
				monster_slots
		end
	else
		if player_slot.ready == "true" then
			formspec = formspec..
				fs.textarea(0.5, 0.5, 6.4, 1, player_slot.name.." is ready to trade!")..
				trading_machine.monster_stats(player_meta, player_slot, 0.5)
		else
			formspec = formspec..
				fs.textarea(0.5, 0.5, 6.4, 1, player_slot.name.." selected a monster...")..
				trading_machine.monster_stats(player_meta, player_slot, 0.5)
		end
	end
	
	if friend_slot.name == "" then
		formspec = formspec..
			fs.textarea(7.1, 0.5, 6.4, 0.9, "Waiting for player...")
	elseif friend_slot.monster_id == 0 then
		formspec = formspec..
			fs.textarea(7.1, 0.5, 6.4, 0.9, "Waiting for "..friend_slot.name.." to select a monster...")
	else
		if friend_slot.ready == "true" then
			formspec = formspec..
				fs.textarea(7.1, 0.5, 6.4, 0.9, friend_slot.name.." is ready to trade!")..
				trading_machine.monster_stats(friend_meta, friend_slot, 7.1)
		else
			formspec = formspec..
				fs.textarea(7.1, 0.5, 6.4, 0.9, friend_slot.name.." selected a monster...")..
				trading_machine.monster_stats(friend_meta, friend_slot, 7.1)
		end
	end
	
	formspec = formspec..
		fs.button(4.95, 9, 2, 1, "ready", "Trade")..
		fs.button(7.05, 9, 2, 1, "cancel", "Cancel")
	
	if friend and friend_update then
		trading_machine.formspec(friend, {}, context)
	end
	
	fsc.show(player_slot.name, formspec, context, trading_machine.fsc_callback)
end

-- Trading Machine
minetest.register_node(modname .. ":zoonami_trading_machine", {
	description = "Trading Machine",
	drawtype = "mesh",
	mesh = "zoonami_trading_machine.obj",
	tiles = {"zoonami_trading_machine.png"},
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {
		cracky = 1,
		dig_stone = 2,
		pickaxey = 4,
	},
	sounds = sounds.stone,
	on_blast = function() end,
	can_dig = function(pos, player)
		local slot1, slot2 = trading_machine.get_slots({pos = pos})
		if slot1.name == "" and slot2.name == "" then
			return true
		end
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if player and player:is_player() then
			local meta = player:get_meta()
			meta:set_string("zoonami_trade_session_id", "")
			trading_machine.fsc_callback(player, {}, {pos = pos})
		end
	end,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})
