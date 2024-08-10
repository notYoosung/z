-- Registers chat commands

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local move_stats = dofile(mod_path .. "/lua/move_stats.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Monster Stats
minetest.register_chatcommand("monster-stats", {
	func = function(name, param)
		param = tonumber(param) or 0
		param = math.floor(param)
		if param < 1 or param > 5 then
			return true, "Invalid number. Use 1, 2, 3, 4, or 5."
		end
		local player = minetest.get_player_by_name(name)
		if not player then
			return true, "Player must be online to view monster stats."
		end
		local meta = player:get_meta()
		local monster = meta:get_string("zoonami_monster_"..param)
		monster = minetest.deserialize(monster)
		monster = monster and monsters.load_stats(monster)
		if not monster then
			return true, "Monster Slot #"..param.." is empty."
		end
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
		local textarea = "Monster Slot #"..param..
			"\nName: "..monster.name..
			(monster.nickname and "\nNickname: "..monster.nickname or "")..
			"\nLevel: "..monster.level..
			"\nType: "..monster.type..
			"\n\nEnergy: "..monster.max_energy..
			"\nEnergy Cap: "..monster.base.energy_cap..
			"\n\nHealth: "..monster.max_health..
			"\nHealth Base: "..monster.base.health..
			"\nPer Level: "..monster.base.health_per_level..
			"\nBoost: "..((monster.boost.health - 1) * 100).."%"..
			"\n\nAttack: "..monster.attack..
			"\nAttack Base: "..monster.base.attack..
			"\nPer Level: "..monster.base.attack_per_level..
			"\nBoost: "..((monster.boost.attack - 1) * 100).."%"..
			"\n\nDefense: "..monster.defense..
			"\nDefense Base: "..monster.base.defense..
			"\nPer Level: "..monster.base.defense_per_level..
			"\nBoost: "..((monster.boost.defense - 1) * 100).."%"..
			"\n\nAgility: "..monster.agility..
			"\nAgility Base: "..monster.base.agility..
			"\nPer Level: "..monster.base.agility_per_level..
			"\nBoost: "..((monster.boost.agility - 1) * 100).."%"..
			"\n\nNext Level: "..exp_needed_for_level_up.." EXP"..
			"\nEXP Total: "..monster.exp_total.." EXP"..
			"\n\nTier: "..monster.base.tier..
			(monster.prisma_id and "\n\nPrisma Color: "..monster.prisma_id or "")..
			"\n\nPersonality: "..monster.personality..
			(monster.base.morph_level and "\n\nMorph Level: "..monster.base.morph_level or "")..
			(monster.base.morphs_into and "\nMorphs Into: "..monsters.stats[monster.base.morphs_into].name or "")..
			"\n\nMoves: "..monster_moves.."\n"
		local formspec = fs.header(12, 10, "false", "#00000000")..
			fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
			fs.font_style("textarea", "mono", "*1", "#FFFFFF")..
			fs.textarea(0.5, 0.5, 11, 9, textarea)
		fsc.show(name, formspec, nil, function() end)
		return true, "Showing stats for Monster Slot #"..param.."."
	end,
})

-- PVP Stats
minetest.register_chatcommand("pvp-stats", {
	func = function(name, param)
		local player_name = param:split(" ")[1] or ""
		local player = minetest.get_player_by_name(player_name)
		if not player then
			return true, "Player name is invalid or offline."
		end
		local meta = player:get_meta()
		local pvp_wins = meta:get_int("zoonami_pvp_wins")
		local pvp_loses = meta:get_int("zoonami_pvp_loses")
		local pvp_forfeits = meta:get_int("zoonami_pvp_forfeits")
		local message = player_name.." PVP Stats"..
			"\n\nPVP Wins: "..pvp_wins..
			"\nPVP Loses: "..pvp_loses..
			"\nPVP Forfeits: "..pvp_forfeits
		local formspec = fs.header(12, 10, "false", "#00000000")..
			fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
			fs.font_style("textarea", "mono", "*1", "#FFFFFF")..
			fs.textarea(0.5, 0.5, 11, 9, message)
		fsc.show(name, formspec, nil, function() end)
		return true, "Showing PVP stats for "..player_name.."."
	end,
})

-- Transfer Zoonami Coins
minetest.register_chatcommand("transfer-zc", {
	func = function(sender_name, param)
		local receiver_name = param:split(" ")[1] or ""
		if receiver_name == "" then
			return true, "Invalid player name."
		elseif sender_name == receiver_name then
			return true, "You can't transfer money to yourself."
		end
		local transfer_amount = param:split(" ")[2]
		transfer_amount = tonumber(transfer_amount) or 0
		transfer_amount = math.floor(transfer_amount)
		if transfer_amount <= 0 then
			return true, "Invalid amount. You must transfer at least 1 ZC."
		end
		local receiver_player = minetest.get_player_by_name(receiver_name)
		local sender_player = minetest.get_player_by_name(sender_name)
		if not sender_player or not receiver_player then
			return true, "Both players must be online to transfer ZC."
		end
		local sender_meta = sender_player:get_meta()
		local sender_zc = sender_meta:get_int("zoonami_coins")
		if sender_zc < transfer_amount then
			return true, "You don't have enough ZC to transfer that amount."
		end
		sender_meta:set_string("zoonami_coins", sender_zc - transfer_amount)
		local receiver_meta = receiver_player:get_meta()
		local receiver_zc = receiver_meta:get_int("zoonami_coins")
		receiver_meta:set_string("zoonami_coins", receiver_zc + transfer_amount)
		minetest.log("action", sender_name.." transfered "..transfer_amount.." ZC to "..receiver_name..".")
		minetest.chat_send_player(receiver_name, sender_name.." transfered "..transfer_amount.." ZC to you.")
		return true, "You transferred "..transfer_amount.." ZC to "..receiver_name.."."
	end,
})

-- Withdraw Zoonami Coins
minetest.register_chatcommand("withdraw-zc", {
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local inv = player:get_inventory()
		local meta = player:get_meta()
		local player_zc = meta:get_int("zoonami_coins")
		local withdrew_zc = tonumber(param) or 0
		withdrew_zc = math.floor(withdrew_zc)
		if withdrew_zc < 1 then
			return true, "Invalid number. Please try again."
		elseif withdrew_zc > player_zc then
			return true, "You don't have enough ZC to withdraw that amount."
		end
		local denominations = {1000, 100, 10, 1}
		local remaining_zc = withdrew_zc
		for i = 1, 4 do
			local max_stack = ItemStack(modname .. ":zoonami_"..denominations[i].."_zc_coin"):get_stack_max()
			local coin_count = math.floor(remaining_zc / denominations[i])
			while coin_count > 0 do
				local stack_count = math.min(coin_count, max_stack)
				local coin_stack = ItemStack(modname .. ":zoonami_"..denominations[i].."_zc_coin "..stack_count)
				local leftover = inv:add_item("main", coin_stack)
				if leftover:get_count() > 0 then
					minetest.add_item(player:get_pos(), leftover)
				end
				coin_count = coin_count - stack_count
				remaining_zc = remaining_zc - (stack_count * denominations[i])
			end
		end
		meta:set_int("zoonami_coins", player_zc - withdrew_zc)
		minetest.log("action", name.." withdrew "..withdrew_zc.." ZC from their bank.")
		minetest.sound_play("zoonami_coins", {to_player = name, gain = 0.9}, true)
		return true, "You withdrew "..withdrew_zc.." ZC."
	end,
})
