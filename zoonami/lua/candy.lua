-- Candy items used for morphing monsters

-- Local namespace
local candy = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Callback from fsc mod
function candy.fsc_callback(player, fields, context)
	if not fields.quit then
		candy.receive_fields(player, fields, context)
		return true
	end
end

-- Handle button presses
function candy.receive_fields(player, fields, context)
	local field_key = next(fields) or ""
	local monster_id = tonumber(string.match(field_key, "^monster#([12345])$"))
	if monster_id then
		local player_name = player:get_player_name()
		local meta = player:get_meta()
		local monster = meta:get_string("zoonami_monster_"..monster_id)
		monster = minetest.deserialize(monster)
		monster = monster and monsters.load_stats(monster)
		if monster then
			if monster.base.morphs_into and monster.level >= monster.base.morph_level and context.monster_types[string.lower(monster.type)] then
				local stack = ItemStack(modname .. ":zoonami_"..context.asset_name.." 1")
				local inv = player:get_inventory()
				local itemstack = inv:remove_item("main", stack)
				if not itemstack:is_empty() then
					local presets = {
						nickname = monster.nickname,
						personality = monster.personality,
						prisma_id = monster.prisma_id,
					}
					local new_monster = monsters.generate(monster.base.morphs_into, monster.level, presets)
					new_monster.starter_monster = monster.starter_monster
					local taught_moves = monsters.stats[new_monster.asset_name].taught_moves
					local extra_move = taught_moves[math.random(#taught_moves)]
					table.insert(new_monster.move_pool, extra_move)
					for i = 1, 4 do
						if not new_monster.moves[i] then
							new_monster.moves[i] = extra_move
							break
						end
					end
					meta:set_string("zoonami_monster_"..monster_id, minetest.serialize(monsters.save_stats(new_monster)))
					zoonami.monster_journal_tamed_monster(meta, new_monster.asset_name)
					minetest.sound_play("zoonami_level_up", {to_player = player_name, gain = 1}, true)
				end
			end
		end
	end
end

-- Show formspec
function candy.show_formspec(itemstack, player, context)
	local player_name = player:get_player_name()
	local meta = player:get_meta()
	local monster_slots = ""
	local monster_slots_row = 0
	for i = 1, 5 do
		local monster = meta:get_string("zoonami_monster_"..i)
		monster = minetest.deserialize(monster)
		monster = monster and monsters.load_stats(monster)
		if monster then
			if monster.base.morphs_into and monster.level >= monster.base.morph_level and context.monster_types[string.lower(monster.type)] then
				monster_slots = monster_slots..
					fs.button(1, 1.5 + (monster_slots_row * 1.5), 8, 1, "monster#"..i, (monster.nickname or monster.name).." Lvl "..monster.level.."\nH:"..monster.health.."/"..monster.max_health.."  E:"..monster.energy.."/"..monster.max_energy)..
					fs.image(1, 1.3 + (monster_slots_row * 1.5), 1.21, 1.21, "zoonami_"..monster.asset_name.."_front.png")
				monster_slots_row = monster_slots_row + 1
			end
		end
	end
	if monster_slots == "" then
		monster_slots = fs.textarea(1, 1.5, 8, 8, "None of the monsters in your party are able to morph using "..context.name.." at this time.")
	end
	local formspec = fs.header(10, 10, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_basic_"..context.background_color.."_background.png", "true", 50)..
		fs.font_style("button,image_button,label", "mono,bold", "*1", "#000000")..
		fs.font_style("textarea", "mono", "*0.94", "#000000")..
		fs.button_style(1, 8)..
		fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "basics", context.name)..
		fs.box(0, 0.5, 10, 0.5, "#00000000")..
		monster_slots
	fsc.show(player_name, formspec, context, candy.fsc_callback)
end

-- Register candy
function candy.register(name, asset_name, monster_types, background_color)
	local context = {}
	context.name = name
	context.asset_name = asset_name
	context.monster_types = monster_types
	context.background_color = background_color
	minetest.register_craftitem(modname .. ":zoonami_"..asset_name, {
		description = name,
		inventory_image = "zoonami_"..asset_name..".png",
		on_secondary_use = function (itemstack, user, pointed_thing)
			if not user or not user:is_player() then return end
			candy.show_formspec(itemstack, user, context)
		end,
		on_place = function(itemstack, placer, pointed_thing)
			if not placer or not placer:is_player() then return end
			local node = minetest.get_node_or_nil(pointed_thing.under)
			local def = node and minetest.registered_nodes[node.name] or {}
			if def.on_rightclick then
				return def.on_rightclick(pointed_thing.under, node, placer, itemstack)
			else
				candy.show_formspec(itemstack, placer, context)
			end
		end,
	})
end

-- Add candy
candy.register("Blue Candy", "blue_candy", {aquatic=true, avian=true, spirit=true}, "blue")
candy.register("Red Candy", "red_candy", {beast=true, warrior=true, mutant=true, fire=true}, "red")
candy.register("Orange Candy", "orange_candy", {rodent=true, robotic=true, rock=true}, "orange")
candy.register("Green Candy", "green_candy", {plant=true, insect=true, reptile=true}, "green")
