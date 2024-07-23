-- Berry juice items used for healing monsters

-- Local namespace
local berry_juice = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Callback from fsc mod
function berry_juice.fsc_callback(player, fields, context)
	if not fields.quit then
		berry_juice.receive_fields(player, fields, context)
		return true
	end
end

-- Handle button presses
function berry_juice.receive_fields(player, fields, context)
	local player_name = player:get_player_name()
	local meta = player:get_meta()
	local field_key = next(fields) or ""
	local monster_id = tonumber(string.match(field_key, "^monster#([12345])$"))
	
	if monster_id and context.item_type == "party_heal" then
		local stack = ItemStack(modname .. ":zoonami_"..context.asset_name.." 1")
		local inv = player:get_inventory()
		local itemstack = inv:remove_item("main", stack)
		if not itemstack:is_empty() then
			for i = 1, 5 do
				local monster = meta:get_string("zoonami_monster_"..i)
				monster = minetest.deserialize(monster)
				monster = monster and monsters.load_stats(monster)
				if monster then
					monster.health = monster.max_health
					monster.energy = monster.max_energy
					meta:set_string("zoonami_monster_"..i, minetest.serialize(monsters.save_stats(monster)))
				end
			end
			minetest.chat_send_player(player_name, "Your monsters are fully healed.")
			minetest.sound_play("zoonami_healer", {to_player = player_name, gain = 0.5}, true)
		end
	elseif monster_id and context.item_type == "single_heal" then
		local monster = meta:get_string("zoonami_monster_"..monster_id)
		monster = minetest.deserialize(monster)
		monster = monster and monsters.load_stats(monster)
		if monster and monster.health < monster.max_health then
			local stack = ItemStack(modname .. ":zoonami_"..context.asset_name.." 1")
			local inv = player:get_inventory()
			local itemstack = inv:remove_item("main", stack)
			if not itemstack:is_empty() then
				monster.health = monster.max_health
				monster.energy = monster.max_energy
				meta:set_string("zoonami_monster_"..monster_id, minetest.serialize(monsters.save_stats(monster)))
				minetest.chat_send_player(player_name, (monster.nickname or monster.name).." is fully healed.")
				minetest.sound_play("zoonami_healer", {to_player = player_name, gain = 0.5}, true)
			end
		end
	end
end

-- Show formspec
function berry_juice.show_formspec(itemstack, player, context)
	local player_name = player:get_player_name()
	local meta = player:get_meta()
	local monster_slots = ""
	local monster_slots_row = 0
	
	if context.item_type == "party_heal" then
		for i = 1, 5 do
			local monster = meta:get_string("zoonami_monster_"..i)
			monster = minetest.deserialize(monster)
			monster = monster and monsters.load_stats(monster)
			if monster and monster.health < monster.max_health then
				monster_slots = fs.button(1, 1.5 + (monster_slots_row * 1.5), 8, 1, "monster#"..i, "Heal all monsters in party")
				break
			end
		end
	elseif context.item_type == "single_heal" then
		for i = 1, 5 do
			local monster = meta:get_string("zoonami_monster_"..i)
			monster = minetest.deserialize(monster)
			monster = monster and monsters.load_stats(monster)
			if monster and monster.health < monster.max_health then
				monster_slots = monster_slots..
					fs.button(1, 1.5 + (monster_slots_row * 1.5), 8, 1, "monster#"..i, (monster.nickname or monster.name).." Lvl "..monster.level.."\nH:"..monster.health.."/"..monster.max_health.."  E:"..monster.energy.."/"..monster.max_energy)..
					fs.image(1, 1.3 + (monster_slots_row * 1.5), 1.21, 1.21, "zoonami_"..monster.asset_name.."_front.png")
				monster_slots_row = monster_slots_row + 1
			end
		end
	end
	
	if monster_slots == "" then
		monster_slots = fs.textarea(1, 1.5, 8, 8, "All of the monsters in your party are already at full health.")
	end
	
	local formspec = fs.header(10, 10, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_basic_"..context.background_color.."_background.png", "true", 50)..
		fs.font_style("button,image_button,label", "mono,bold", "*1", "#000000")..
		fs.font_style("textarea", "mono", "*0.94", "#000000")..
		fs.button_style(1, 8)..
		fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "item_name", context.name)..
		fs.box(0, 0.5, 10, 0.5, "#00000000")..
		monster_slots
	fsc.show(player_name, formspec, context, berry_juice.fsc_callback)
end

-- Register berry juice
function berry_juice.register(name, asset_name, item_type, background_color)
	local context = {}
	context.name = name
	context.asset_name = asset_name
	context.item_type = item_type
	context.background_color = background_color
	minetest.register_craftitem(modname .. ":zoonami_"..asset_name, {
		description = name,
		inventory_image = "zoonami_"..asset_name..".png",
		on_secondary_use = function (itemstack, user, pointed_thing)
			if not user or not user:is_player() then return end
			berry_juice.show_formspec(itemstack, user, context)
		end,
		on_place = function(itemstack, placer, pointed_thing)
			if not placer or not placer:is_player() then return end
			local node = minetest.get_node_or_nil(pointed_thing.under)
			local def = node and minetest.registered_nodes[node.name] or {}
			if def.on_rightclick then
				return def.on_rightclick(pointed_thing.under, node, placer, itemstack)
			else
				berry_juice.show_formspec(itemstack, placer, context)
			end
		end,
	})
end

-- Add berry_juice
berry_juice.register("Simple Berry Juice", "simple_berry_juice", "single_heal", "blue")
berry_juice.register("Super Berry Juice", "super_berry_juice", "party_heal", "pink")
