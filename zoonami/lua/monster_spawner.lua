-- Monster Spawner node and formspec

-- Local namespace
local monster_spawner = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local group = dofile(mod_path .. "/lua/group.lua")
local monsters = dofile(mod_path .. "/lua/monsters.lua")
local sounds = dofile(mod_path .. "/lua/sounds.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Mob settings
local settings = minetest.settings
local max_nearby_mobs = tonumber(settings:get("zoonami_max_nearby_mobs") or 2)

-- Monster names
local monster_names = {""}
for k, v in pairs(monsters.stats) do
	table.insert(monster_names, v.asset_name)
end
table.sort(monster_names)

-- Generate lists
local length, interval, monster, rarity, spawn_on, level = {}, {}, {}, {}, {}, {}
length.list = {"2","5","10","15","20","25","30","35","40","45","50"}
interval.list = {"5","10","15","20","25","30","35","40","45","50","55","60"}
monster.list = monster_names
rarity.list = {"Common", "Uncommon", "Rare", "Mythical", "Legendary"}
spawn_on.list = {"Choppy", "Cracky", "Crumbly", "Grass", "Lava", "Sand", "Snowy", "Stone", "Water"}
level.list = {"1","5","10","15","20","25","30","35","40","45","50","55","60","65","70","75","80","85","90","95","100"}

-- Generate indexes
length.index, interval.index, monster.index, rarity.index, spawn_on.index, level.index = {}, {}, {}, {}, {}, {}
for k, v in pairs(length.list) do length.index[v] = k end
for k, v in pairs(interval.list) do interval.index[v] = k end
for k, v in pairs(monster.list) do monster.index[v] = k end
for k, v in pairs(rarity.list) do rarity.index[v] = k end
for k, v in pairs(spawn_on.list) do spawn_on.index[v] = k end
for k, v in pairs(level.list) do level.index[v] = k end

-- Generate dropdowns
length.dropdown = table.concat(length.list, ",")
interval.dropdown = table.concat(interval.list, ",")
monster.dropdown = table.concat(monster.list, ",")
rarity.dropdown = table.concat(rarity.list, ",")
spawn_on.dropdown = table.concat(spawn_on.list, ",")
level.dropdown = table.concat(level.list, ",")

-- Validate meta values
function monster_spawner.meta(meta)
	local new_meta = {}
	new_meta.width = length.index[meta.width] and meta.width or "2"
	new_meta.height = length.index[meta.height] and meta.height or "2"
	new_meta.interval = interval.index[meta.interval] and meta.interval or "5"
	for i = 1, 7 do
		local meta_name = meta["monster"..i.."_name"]
		local meta_rarity = meta["monster"..i.."_rarity"] or rarity.list[1]
		local meta_spawn_on = meta["monster"..i.."_spawn_on"] or spawn_on.list[1]
		local meta_min_level = meta["monster"..i.."_min_level"] or level.list[1]
		local meta_max_level = meta["monster"..i.."_max_level"] or level.list[1]
		meta_max_level = tonumber(meta_min_level) > tonumber(meta_max_level) and meta_min_level or meta_max_level
		new_meta["monster"..i.."_name"] = monster.index[meta_name] and string.len(meta_name) > 0 and meta_name
		new_meta["monster"..i.."_rarity"] = rarity.index[meta_rarity] and meta_rarity
		new_meta["monster"..i.."_spawn_on"] = spawn_on.index[meta_spawn_on] and meta_spawn_on
		new_meta["monster"..i.."_min_level"] = level.index[meta_min_level] and meta_min_level
		new_meta["monster"..i.."_max_level"] = level.index[meta_max_level] and meta_max_level
	end
	return new_meta
end

-- Monster Spawner Formspec
function monster_spawner.formspec(player, fields, context)
	local creative_mode = minetest.settings:get_bool("creative_mode")
	local creative_privs = minetest.check_player_privs(player,{creative = true})
	fields = fields or {}
	if fields.quit or not (creative_mode or creative_privs) then
		return true
	end
	
	local node_meta = minetest.get_meta(context.node_pos)
	local meta = minetest.deserialize(node_meta:get_string("meta")) or {}
	local player_name = player:get_player_name() or ""
	context = context or {}
	
	local field_key = next(fields) or ""
	meta[field_key] = fields[field_key]
	meta = monster_spawner.meta(meta)
	node_meta:set_string("meta", minetest.serialize(meta))
	
	if meta.monster1_name or meta.monster2_name or meta.monster3_name or meta.monster4_name or
	meta.monster5_name or meta.monster6_name or meta.monster7_name then
		local timer = minetest.get_node_timer(context.node_pos)
		timer:start(tonumber(meta.interval))
	else
		minetest.get_node_timer(context.node_pos):stop()
	end
	
	local formspec = fs.header(11, 10.5, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
		fs.label(1, 0.6, "Width")..
		"dropdown[1,1;2,0.75;width;"..length.dropdown..";"..length.index[meta.width]..";false]"..
		fs.label(4.5, 0.6, "Height")..
		"dropdown[4.5,1;2,0.75;height;"..length.dropdown..";"..length.index[meta.height]..";false]"..
		fs.label(8, 0.6, "Interval")..
		"dropdown[8,1;2,0.75;interval;"..interval.dropdown..";"..interval.index[meta.interval]..";false]"..
		fs.label(0.5, 2.5, "Monster, Rarity, Spawn On, Min/Max Level")
		
	-- Generate 7 monster slots
	for i = 1, 7 do
		local y = 2 + (i * 1)
		local index = {
			monster = monster.index[meta["monster"..i.."_name"]] or 1,
			rarity = rarity.index[meta["monster"..i.."_rarity"]] or 1,
			spawn_on = spawn_on.index[meta["monster"..i.."_spawn_on"]] or 1,
			min_level = level.index[meta["monster"..i.."_min_level"]] or 1,
			max_level = level.index[meta["monster"..i.."_max_level"]] or 1,
		}
		formspec = formspec..
			"dropdown[0.5,"..y..";2.4,0.75;monster"..i.."_name;"..monster.dropdown..";"..index.monster..";false]"..
			"dropdown[3,"..y..";2.4,0.75;monster"..i.."_rarity;"..rarity.dropdown..";"..index.rarity..";false]"..
			"dropdown[5.5,"..y..";1.9,0.75;monster"..i.."_spawn_on;"..spawn_on.dropdown..";"..index.spawn_on..";false]"..
			"dropdown[7.5,"..y..";1.4,0.75;monster"..i.."_min_level;"..level.dropdown..";"..index.min_level..";false]"..
			"dropdown[9,"..y..";1.4,0.75;monster"..i.."_max_level;"..level.dropdown..";"..index.max_level..";false]"
	end
	
	fsc.show(player_name, formspec, context, monster_spawner.formspec)
end

-- Monster Spawner Timer
function monster_spawner.timer(pos, elapsed)
	local node_meta = minetest.get_meta(pos)
	local meta = minetest.deserialize(node_meta:get_string("meta")) or {}
	meta = monster_spawner.meta(meta)
	meta.width = tonumber(meta.width)
	meta.height = tonumber(meta.height)
	local spawn_on = {group.choppy, group.cracky, group.crumbly, group.grass, group.lava, group.sand, group.snowy, group.stone, group.water}
	local nearby_mobs = 0
	
	local pos_spawn_start = vector.offset(pos, -meta.width, -meta.height, -meta.width)
	local pos_spawn_end = vector.offset(pos, meta.width, meta.height, meta.width)
	local potential_spawns = minetest.find_nodes_in_area_under_air(pos_spawn_start, pos_spawn_end, spawn_on)
	
	-- Stop if there are no potential spawn spaces
	if #potential_spawns < 1 then
		return true
	end
	
	local spawn_pos = potential_spawns[math.random(#potential_spawns)]
	
	-- Prevent spawning if too many mobs nearby
	local objs = minetest.get_objects_inside_radius(spawn_pos, 20)
	for _,obj in ipairs(objs) do
		if not obj:is_player() then
			local luaent = obj:get_luaentity()
			if luaent and luaent.name:find('zoonami_') then
				nearby_mobs = nearby_mobs + 1
				if nearby_mobs > max_nearby_mobs then
					return true
				end
			end
		end
	end
	
	local rarity = math.random()
	if rarity >= 0.999 then
		rarity = "Legendary"
	elseif rarity >= 0.997 then
		rarity = "Mythical"
	elseif rarity >= 0.987 then
		rarity = "rare"
	elseif rarity >= 0.887 then
		rarity = "Uncommon"
	else
		rarity = "Common"
	end
	
	local node = minetest.get_node(spawn_pos)
	local node_def = minetest.registered_nodes[node.name]
	local node_groups = node_def and node_def.groups
	local node_group_matches = {}
	local node_group = nil

	for i, v in pairs(spawn_on) do
		local group = v:split(":")[2]
		if node_groups[group] then
			node_group_matches[#node_group_matches + 1] = v
		end
	end

	if #node_group_matches > 1 then
		node_group = node_group_matches[math.random(#node_group_matches)]
	elseif #node_group_matches == 1 then
		node_group = node_group_matches[1]
	end
	
	if not node_group then
		return true
	end
	
	local potential_monsters = {}
	
	for i = 1, 7 do
		if meta["monster"..i.."_name"] then
			if (meta["monster"..i.."_rarity"] or "Common") == rarity then
				if group[string.lower(meta["monster"..i.."_spawn_on"] or "Choppy")] == node_group then
					table.insert(potential_monsters, i)
				end
			end
		end
	end
	
	if #potential_monsters > 0 then
		local slot_id = potential_monsters[math.random(#potential_monsters)]
		local mob_name = meta["monster"..slot_id.."_name"]
		local min_level = tonumber(meta["monster"..slot_id.."_min_level"])
		local max_level = tonumber(meta["monster"..slot_id.."_max_level"])
		
		spawn_pos.y = spawn_pos.y + 1
		local def = minetest.registered_entities[modname .. ":zoonami_"..mob_name]
		spawn_pos.y = spawn_pos.y - def.collisionbox[2]
		if node_group == "group:water" or node_group == "group:lava" then
			for i = 1, 5 do
				spawn_pos.y = spawn_pos.y - 1
				local node = minetest.get_node(spawn_pos)
				local node_def = minetest.registered_nodes[node.name]
				local node_groups = node_def and node_def.groups
				if not node_groups.water and not node_groups.lava then
					spawn_pos.y = spawn_pos.y + 1
					break
				end
			end
		end
		local obj = minetest.add_entity(spawn_pos, modname .. ":zoonami_"..mob_name, minetest.serialize(staticdata))
		local luaent = obj and obj:get_luaentity() or {}
		luaent._spawn_min_level = min_level
		luaent._spawn_max_level = max_level
		luaent.object:set_properties(luaent)
	end
	
	return true
end

-- Monster Spawner
minetest.register_node(modname .. ":zoonami_monster_spawner", {
	description = "Zoonami Monster Spawner",
	tiles = {"zoonami_monster_spawner.png"},
	is_ground_content = false,
	paramtype2 = "facedir",
	groups = {
		cracky = 1,
		dig_stone = 2,
		pickaxey = 4,
	},
	sounds = sounds.stone,
	drop = "",
	on_timer = monster_spawner.timer,
	on_destruct = function(pos)
		minetest.get_node_timer(pos):stop()
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if not player or not player:is_player() then return end
		monster_spawner.formspec(player, {}, {node_pos = pos})
	end,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})
