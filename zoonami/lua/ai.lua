local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

-- Handles the computer's artificial intelligence in battles

-- Local namespace
local ai = {}

-- Import functions
-- local mod_path = minetest.get_modpath("zoonami")
local move_stats = dofile(mod_path .. "/lua/move_stats.lua")
local types = dofile(mod_path .. "/lua/types.lua")

-- Returns the move the AI will use for each turn in battle
function ai.choose_move(player, enemy, context)
	local enemy = ai.hide_unusable_moves(enemy)
	local turns_ai_can_last = ai.predicted_turns_ai_can_last(player, enemy)
	local turns_opponent_can_last = ai.predicted_turns_opponent_can_last(player, enemy)
	local use_shield = ai.use_shield(player, enemy, turns_ai_can_last, turns_opponent_can_last)
	local use_health_recovery = ai.use_health_recovery(player, enemy)
	local use_energy_recovery = ai.use_energy_recovery(player, enemy)
	local selected_move = nil
	
	if use_shield then
		selected_move = use_shield
	elseif turns_ai_can_last > 1 and use_health_recovery then
		selected_move = use_health_recovery
	elseif turns_ai_can_last > 2 and use_energy_recovery then
		selected_move = use_energy_recovery
	elseif turns_ai_can_last > turns_opponent_can_last then
		selected_move = ai.efficient_attack(player, enemy)
	else
		local chance_of_switching, slot_id = ai.chance_of_ai_switching(player, enemy, context)
		if chance_of_switching >= math.random(100) then
			selected_move = {type = "monster", new_monster = slot_id}
		else
			selected_move = ai.max_attack(player, enemy, turns_ai_can_last)
		end
	end

	return selected_move
end

-- Helper function to hide moves that can't be used
function ai.hide_unusable_moves(enemy)
	local new_enemy = table.copy(enemy)
	for k, v in pairs (new_enemy.move_context) do
		local cooldown = new_enemy.move_context[k] and new_enemy.move_context[k].cooldown
		local move_cooldown = move_stats[k].cooldown
		local quantity = new_enemy.move_context[k] and new_enemy.move_context[k].quantity
		if (cooldown and cooldown < move_cooldown) or (quantity and quantity <= 0) then
			for k2, v2 in pairs(new_enemy.moves) do
				if v2 == k then
					new_enemy.moves[k2] = nil
				end
			end
		end
	end
	return new_enemy
end

-- Helper function to calculate damage dealt
function ai.damage_dealt(attacker, defender, move)
	if move.attack or move.counter_min or move.range_min then
		local counteract_bonus = move.counteract and (defender[string.lower(move.counteract)] - attacker[string.lower(move.counteract)]) / 2 or 0
		local counter_power = move.counter_min and ((attacker.max_health - attacker.health) / attacker.max_health) * (move.counter_max - move.counter_min) + move.counter_min
		local range_power = move.range_min and (move.range_min + move.range_max) / 2
		local move_power = move.attack or move.static or counter_power or range_power
		local effectiveness = move.type and types.effectiveness(string.lower(move.type), string.lower(defender.type)) or 1
		local type_bonus = move.type and attacker.type == move.type and 1.15 or 1
		local base_multiplier = move_power * effectiveness * type_bonus
		local base_attack = attacker.attack + counteract_bonus
		local base_damage = base_attack / (5 * math.sqrt(defender.defense / base_attack))
		local damage_dealt = math.ceil(base_damage * base_multiplier)
		return damage_dealt
	elseif move.static then
		local damage_dealt = math.ceil(move.static * defender.max_health)
		return damage_dealt
	else
		return 0
	end
end
	
-- Helper function to determine attacker vs defender effectiveness score
function ai.calculate_score(attacker, defender)
	local attack_effectiveness = types.effectiveness(string.lower(attacker.type), string.lower(defender.type))
	local defense_effectiveness = types.effectiveness(string.lower(defender.type), string.lower(attacker.type))
	local attack_score = (attack_effectiveness - 0.75) * 20
	local defense_score = (defense_effectiveness - 1.25) * -20
	local health_score = attacker.health / attacker.max_health
	local energy_score = attacker.energy / attacker.max_energy
	local dead_score = attacker.health == 0 and -1 or 0
	return attack_score * defense_score * health_score * energy_score + dead_score
end

-- Predicts the how many turns the AI could last against the opponent
function ai.predicted_turns_ai_can_last(player, enemy)
	local turns = 0
	local total_damage = 0
	local player_energy = player.energy
	local estimated_damage_per_energy = {[0] = 0, [1] = 0.5, [2] = 1.0, [3] = 1.45, [4] = 1.6, [5] = 1.75, [6] = 2.1}
	
	while total_damage < enemy.health do
		local move = {}
		move.type = player.type
		move.energy = math.min(player_energy, 6)
		move.attack = estimated_damage_per_energy[move.energy]
		local damage_dealt = ai.damage_dealt(player, enemy, move)
		total_damage = total_damage + damage_dealt
		player_energy = player_energy - move.energy + 2
		turns = turns + 1
		-- Fail safe in case AI can't be damaged
		if turns >= 3 and total_damage == 0 then
			turns = 50
			total_damage = enemy.health
		end
	end
	
	return turns
end

-- Predicts the how many turns the opponent could last against the AI
function ai.predicted_turns_opponent_can_last(player, enemy)
	local turns = 0
	local total_damage = 0
	local ai_energy = enemy.energy
	
	while total_damage < player.health do
		local max_move_damage = 0
		local max_move_energy = 0
		for i = 1, 4 do
			local move = move_stats[enemy.moves[i] or ""]
			if move and move.energy <= ai_energy then
				local damage_dealt = ai.damage_dealt(enemy, player, move)
				if damage_dealt > max_move_damage then
					max_move_damage = damage_dealt
					max_move_energy = move.energy
				end
			end
		end
		total_damage = total_damage + max_move_damage
		ai_energy = ai_energy - max_move_energy + 2
		turns = turns + 1
		-- Fail safe in case player can't be damaged
		if turns >= 3 and total_damage == 0 then
			turns = 50
			total_damage = player.health
		end
	end
	
	return turns
end

-- Advises if AI has and should use a health recovery move
function ai.use_health_recovery(player, enemy)
	local best_move = {asset_name = nil, health = 0, energy = 1}
	
	for i = 1, 4 do
		local move = move_stats[enemy.moves[i] or ""]
		if move and move.heal and move.heal > 0.2 then
			if (move.heal * enemy.max_health) + enemy.health <= enemy.max_health + (enemy.max_health * move.heal * 0.1) then
				if move.heal / move.energy > best_move.health / best_move.energy then
					best_move.asset_name = move.asset_name
					best_move.health = move.heal
					best_move.energy = move.energy
				end
			end
		end
	end
	
	return best_move.energy <= enemy.energy and best_move.asset_name or false
end

-- Advises if AI has and should use an energy recovery move
function ai.use_energy_recovery(player, enemy)
	local best_move = {asset_name = nil, energy = 0}
	
	for i = 1, 4 do
		local move = move_stats[enemy.moves[i] or ""]
		if move and move.recover and move.recover > move.energy then
			if move.recover + enemy.energy < enemy.max_energy then
				if move.recover > best_move.energy then
					best_move.asset_name = move.asset_name
					best_move.energy = move.energy
				end
			end
		end
	end
	
	return best_move.energy <= enemy.energy and best_move.asset_name or false
end

-- Advises if AI has and should use a shield move
function ai.use_shield(player, enemy, turns_ai_can_last, turns_opponent_can_last)
	local best_move = {asset_name = nil}
	local score = ai.calculate_score(enemy, player)
	local chance = (60 - score) * math.min(turns_opponent_can_last / turns_ai_can_last, 1.1)
	
	if math.random(100) <= chance then
		for i = 1, 4 do
			local move = move_stats[enemy.moves[i] or ""]
			if move and move.shield and move.shield > 0.7 then
				if move.energy <= enemy.energy then
					if best_move.asset_name == nil or (move.energy == 0 and enemy.energy < enemy.max_energy) then
						best_move.asset_name = move.asset_name
					end
				end
			end
		end
	end
	
	return best_move.asset_name or false
end

-- Prioritizes energy efficient attacks
function ai.efficient_attack(player, enemy)
	local best_move = {asset_name = nil, damage = 0, energy = 1, energy_for_ko = 99}
	
	for i = 1, 4 do
		local move = move_stats[enemy.moves[i] or ""]
		if move and move.energy <= enemy.max_energy then
			local damage_dealt = ai.damage_dealt(enemy, player, move)
			local damage_efficient = damage_dealt / move.energy > best_move.damage / best_move.energy and true or false
			local in_ko_range = damage_dealt >= player.health or best_move.damage >= player.health and true or false
			local energy_for_ko = math.ceil(player.health / damage_dealt) * move.energy
			
			if in_ko_range then
				if energy_for_ko < best_move.energy_for_ko or energy_for_ko == best_move.energy_for_ko and damage_efficient then
					best_move.asset_name = move.asset_name
					best_move.damage = damage_dealt
					best_move.energy = move.energy
					best_move.energy_for_ko = energy_for_ko
				end
			elseif damage_efficient then
				best_move.asset_name = move.asset_name
				best_move.damage = damage_dealt
				best_move.energy = move.energy
				best_move.energy_for_ko = energy_for_ko
			end
		end
	end
	
	return best_move.energy <= enemy.energy and best_move.asset_name or "skip"
end

-- Prioritizes high damage attacks
function ai.max_attack(player, enemy, turns_ai_can_last)
	local best_move = {asset_name = nil, damage = 0, energy = 1, energy_for_ko = 99, priority = -10}
	
	for i = 1, 4 do
		local move = move_stats[enemy.moves[i] or ""]
		if move and move.energy <= enemy.energy then
			local damage_dealt = ai.damage_dealt(enemy, player, move)
			local in_ko_range = damage_dealt >= player.health or best_move.damage >= player.health and true or false
			local energy_for_ko = math.ceil(player.health / damage_dealt) * move.energy
			
			if in_ko_range then
				if energy_for_ko < best_move.energy_for_ko or 
				energy_for_ko == best_move.energy_for_ko and move.priority > best_move.priority or
				energy_for_ko == best_move.energy_for_ko and move.priority == best_move.priority and damage_dealt > best_move.damage then
					best_move.asset_name = move.asset_name
					best_move.damage = damage_dealt
					best_move.energy = move.energy
					best_move.energy_for_ko = energy_for_ko
					best_move.priority = move.priority
				end
			elseif player.agility >= enemy.agility and turns_ai_can_last <= 2 then
				if move.priority > best_move.priority and damage_dealt > 0 or
				move.priority == best_move.priority and energy_for_ko < best_move.energy_for_ko or 
				move.priority == best_move.priority and energy_for_ko == best_move.energy_for_ko and damage_dealt > best_move.damage then
					best_move.asset_name = move.asset_name
					best_move.damage = damage_dealt
					best_move.energy_for_ko = energy_for_ko
					best_move.priority = move.priority
				end
			elseif damage_dealt > best_move.damage or damage_dealt == best_move.damage and energy_for_ko <= best_move.energy_for_ko then
				best_move.asset_name = move.asset_name
				best_move.damage = damage_dealt
				best_move.energy_for_ko = energy_for_ko
				best_move.priority = move.priority
			end
		end
	end
	
	return best_move.asset_name or "skip"
end

-- Calculates the chance the AI should switch monsters and who to switch to
function ai.chance_of_ai_switching(player, enemy, context)
	-- Chance can range from 0 (no chance) to 100 (very likely) 
	local chance = 0
	local slot_id = nil
	
	-- AI monster score
	local score = ai.calculate_score(enemy, player)
	
	-- Check AI's other monsters scores
	for i = 1, 5 do
		local monster2 = context.enemy_monsters["monster#"..i]
		if monster2 and monster2.health > 0 and i ~= context.enemy_current_monster then
			local score2 = ai.calculate_score(monster2, player)
			if score2 >= score and score2 - score > chance then
				chance = score2 - score
				slot_id = i
			end
		end
	end
	
	-- If AI is slower than player, reduce chance of switching before attack
	if enemy.agility < player.agility then
		chance = chance / 2
	end
	
	return chance, slot_id
end

-- Chooses a new monster
function ai.choose_monster(player, enemy, context)
	local chance, slot_id = ai.chance_of_ai_switching(player, enemy, context)
	return slot_id
end

return ai
