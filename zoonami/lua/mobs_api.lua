-- Mobs API based on Mobs mod by PilzAdam (see LICENSE.txt for more details)

-- Local namespace
local mobs_api = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local npc_stats = dofile(mod_path .. "/lua/npc_stats.lua")
local group = dofile(mod_path .. "/lua/group.lua")

-- Mob settings
local settings = minetest.settings
local mob_collisions = settings:get_bool("zoonami_mob_collisions") or false
local mob_ai = settings:get_bool("zoonami_mob_ai") ~= false
local mob_ai_interval = 1

function mobs_api.register_mob(name, def)
	minetest.register_entity(name, {
		_name = name,
		_type = def.type,
		_swim = def.swim,
		_float = def.float,
		_sink = def.sink,
		_drown = def.drown,
		_burn = def.burn,
		_walk_velocity = def.walk_velocity,
		_stay_near = def.stay_near,
		_state = "stand",
		_animation = def.animation,
		_life_timer = 1800,
		_prevent_despawn = def.prevent_despawn,
		_texture_list = def.texture_list,
		_armor_groups = def.armor_groups,
		on_rightclick = def.on_rightclick,
		
		initial_properties = {
			hp_max = def.hp_max,
			textures = def.textures,
			physical = true,
			collide_with_objects = mob_collisions,
			collisionbox = def.collisionbox,
			visual = def.visual,
			visual_size = def.visual_size,
			mesh = def.mesh,
			stepheight = def.stepheight,
			makes_footstep_sound = def.makes_footstep_sound,
		},
		
		_set_velocity = function(self, velocity)
			local yaw = self.object:get_yaw()
			local x = math.sin(yaw) * -velocity
			local z = math.cos(yaw) * velocity
			self.object:set_velocity(vector.new(x, 0, z))
		end,
		
		_set_movement_state = function(self, state, animation)
			self._state = state
			animation = animation or state
			if self._animation and animation then
				self.object:set_animation(
					{x = self._animation[animation.."_start"],
					y = self._animation[animation.."_end"]},
					self._animation.speed_normal or 15, 0
				)
			end
		end,
		
		on_step = mob_ai and function(self, dtime)
			self._on_step_timer = (self._on_step_timer or math.random() * 2) + dtime
			if self._on_step_timer < mob_ai_interval then
				return
			end
			local total_dtime = self._on_step_timer
			self._walk_timer = self._walk_timer and self._walk_timer - self._on_step_timer
			self._on_step_timer = 0
			
			-- Despawn timer
			local mob_pos = self.object:get_pos()
			if not self._prevent_despawn then
				self._life_timer = self._life_timer - total_dtime
			end
			if self._life_timer <= 0 then
				local player_count = 0
				for _,obj in pairs(minetest.get_objects_inside_radius(mob_pos, 20)) do
					if obj:is_player() then
						player_count = player_count + 1
						break
					end
				end
				if player_count == 0 then
					self.object:remove()
					return
				end
			end
			
			-- Movement states
			if self._state == "stand" then
				if math.random(1, 4) == 1 then
					self.object:set_yaw(self.object:get_yaw()+((math.random(0,360)-180)/180*math.pi))
				end
				if self._walk_velocity > 0 and math.random(1, 100) <= 30 then
					if self._stay_near then
						local pos1 = vector.offset(mob_pos, 12, -4, 12)
						local pos2 = vector.offset(mob_pos, -12, 2, -12)
						local nodes = minetest.find_nodes_in_area_under_air(pos1, pos2, self._stay_near)
						if #nodes > 0 then
							local node_pos = nodes[math.random(#nodes)]
							node_pos = vector.offset(node_pos, math.random(-8, 8), 0, math.random(-8, 8))
							self._walk_timer = vector.distance(mob_pos, node_pos) * 0.5
							local yaw = minetest.dir_to_yaw(vector.direction(mob_pos, node_pos))
							self.object:set_yaw(yaw)
						end
					end
					self:_set_velocity(self._walk_velocity)
					self:_set_movement_state("walk")
				end
			elseif self._state == "walk" then
				if math.random(1, 100) <= 30 and not self._walk_timer then
					self.object:set_yaw(self.object:get_yaw()+((math.random(0,360)-180)/180*math.pi))
					self:_set_velocity(self._walk_velocity)
				end
				if math.random(1, 100) <= 20 and not self._walk_timer or self._walk_timer and self._walk_timer <= 0 then
					self._walk_timer = nil
					self.object:set_velocity(vector.new())
					self:_set_movement_state("stand")
				end
			elseif self._state == "follow" then
				local player_pos = nil
				local showcase_id = nil
				for _,obj in pairs(minetest.get_objects_inside_radius(mob_pos, 20)) do
					if obj:is_player() and obj:get_player_name() == self._nametag then
						player_pos = obj:get_pos()
						showcase_id = obj:get_meta():get_string("zoonami_showcase_monster_id")
						break
					end
				end
				if showcase_id and showcase_id == self._showcase_id then
					if vector.distance(player_pos, mob_pos) > 4.7 then
						local vec = vector.subtract(player_pos, mob_pos)
						local yaw = (math.atan(vec.z / vec.x) + math.pi / 2)
						yaw = player_pos.x > mob_pos.x and yaw + math.pi or yaw
						self.object:set_yaw(yaw)
						self:_set_velocity(2)
					else
						self.object:set_velocity(vector.new())
					end
				else
					self.object:remove()
					return
				end
			end
			
			-- Surrounding environment
			local feet_offset = self.initial_properties.collisionbox[2]
			local head_offset = self.initial_properties.collisionbox[5]
			local feet_pos = vector.offset(mob_pos, 0, feet_offset*0.98, 0)
			local feet_node = minetest.get_node(feet_pos) or {}
			local feet_groups = minetest.registered_nodes[feet_node.name]
			feet_groups = feet_groups and feet_groups.groups or {}
			local head_pos = vector.offset(mob_pos, 0, head_offset*0.5, 0)
			local head_node = minetest.get_node(head_pos) or {}
			local head_groups = minetest.registered_nodes[head_node.name]
			head_groups = head_groups and head_groups.groups or {}
			local velocity = self.object:get_velocity()
			
			-- Cliff and liquid avoidance modified from Mobs Redo by TenPlus1 (see LICENSE.txt for more details)
			if not self._swim and not self._sink and self._state == "walk" then
				local fear_height = 1.1
				local yaw = self.object:get_yaw() or 0
				local dir_x = -math.sin(yaw) * (self.initial_properties.collisionbox[4] + 0.6)
				local dir_z = math.cos(yaw) * (self.initial_properties.collisionbox[4] + 0.6)
				local pos = self.object:get_pos()
				local start_pos = vector.offset(pos, dir_x, self.initial_properties.collisionbox[2], dir_z)
				local end_pos = vector.offset(start_pos, 0, -fear_height, 0)
				local free_fall, blocker = minetest.line_of_sight(start_pos, end_pos)
				
				if free_fall then
					self.object:set_velocity(vector.new())
					self:_set_movement_state("stand")
				elseif blocker then
					local blocker_node = minetest.get_node(blocker)
					local blocker_groups = minetest.registered_nodes[blocker_node.name]
					blocker_groups = blocker_groups and blocker_groups.groups or {}
					if blocker_groups.water and not feet_groups.water then
						self.object:set_velocity(vector.new())
						self:_set_movement_state("stand")
					end
				end
			end
			
			-- Burning, drowning, floating, and swimming
			if self._burn and (feet_groups.lava or head_groups.lava) then
				self.object:remove()
			elseif self._drown and (feet_groups.water or head_groups.water) then
				self.object:remove()
			elseif self._float then
				if feet_groups.liquid then
					velocity.y = head_groups.liquid and 0.15 or -0.15
					self.object:set_velocity(velocity)
					self.object:set_acceleration(vector.new())
				else
					self.object:set_acceleration(vector.new(0, -10, 0))
				end
			elseif self._swim then
				if feet_node.name == "air" then
					velocity = vector.new(0, -7, 0)
				elseif self._state == "stand" then
					velocity.y = 0
				else
					local above_pos = vector.offset(mob_pos, 0, head_offset+1.5, 0)
					local above_node = minetest.get_node(above_pos) or {}
					if above_node.name == "air" then
						velocity.y = (math.random(-3, -1) / 10)
					else
						velocity.y = (math.random(-2, 3) / 10)
					end
				end
				self.object:set_velocity(velocity)
			end
		end,
		
		on_activate = function(self, staticdata, dtime_s)
			local new_properties = {}
			local y = mob_ai and self._swim and 0 or -10
			self.object:set_acceleration(vector.new(0, y, 0))
			self.object:set_velocity(vector.new())
			self.object:set_yaw(math.random(1, 360)/180*math.pi)
			self.object:set_armor_groups(self._armor_groups)
			self:_set_movement_state("stand")
			if staticdata then
				local tmp = minetest.deserialize(staticdata)
				if tmp then
					self._life_timer = tmp.life_timer or self._life_timer
					self._prisma_id = tmp.prisma_id or self._prisma_id
					self._state = tmp.state or self._state
					self._nametag = tmp.nametag or self.nametag
					self._showcase_id = tmp.showcase_id or self._showcase_id
					self._on_rightclick_disabled = tmp.on_rightclick_disabled
					self.on_rightclick = tmp.on_rightclick_disabled and function() end or self.on_rightclick
					if self._type == "npc" then
						self._dynamic_textures = tmp.dynamic_textures or tmp.textures
						self._difficulty = tmp.difficulty
						self._assigned_monsters = tmp.assigned_monsters
						self._assigned_messages = tmp.assigned_messages
						self._assigned_items = tmp.assigned_items
						self._previous_day = tmp.previous_day
					end
				end
			end
			if self._life_timer <= 0 then
				self.object:remove()
				return
			end
			if not self._dynamic_textures and self._texture_list then
				self._dynamic_textures = self._texture_list[math.random(#self._texture_list)]
			end
			if self._dynamic_textures then
				new_properties.textures = self._dynamic_textures
			end
			if self._prisma_id and not self._prisma_id_set then
				self._prisma_id_set = true
				local new_textures = {}
				for i = 1, #self.initial_properties.textures do
					new_textures[i] = string.gsub(self.initial_properties.textures[i], "%.png", self._prisma_id..".png", 1)
				end
				new_properties.textures = new_textures
			end
			if self._nametag then
				new_properties.nametag = self._nametag
			end
			if new_properties.textures or new_properties.nametag then
				self.object:set_properties(new_properties)
			end
		end,
		
		get_staticdata = function(self)
			local tmp = {
				life_timer = self._life_timer,
				dynamic_textures = self._dynamic_textures,
				prisma_id = self._prisma_id,
				nametag = self._nametag,
				showcase_id = self._showcase_id,
				on_rightclick_disabled = self._on_rightclick_disabled,
				spawn_min_level = self._spawn_min_level,
				spawn_max_level = self._spawn_max_level,
				difficulty = self._difficulty,
				assigned_monsters = self._assigned_monsters,
				assigned_messages = self._assigned_messages,
				assigned_items = self._assigned_items,
				previous_day = self._previous_day
			}
			return minetest.serialize(tmp)
		end,
	})
end

function mobs_api.register_egg(asset_name, description, texture)
	minetest.register_craftitem(modname .. ":zoonami_spawn_"..asset_name, {
		description = description,
		inventory_image = texture,
		groups = {spawn_egg = 1},
		on_place = function(itemstack, placer, pointed_thing)
			if not placer or not placer:is_player() then return end
			local node = minetest.get_node_or_nil(pointed_thing.under)
			local node_def = node and minetest.registered_nodes[node.name] or {}
			if node_def.on_rightclick then
				return node_def.on_rightclick(pointed_thing.under, node, placer, itemstack)
			else
				local staticdata = nil
				local inv = placer:get_inventory()
				local def = minetest.registered_entities[modname .. ":zoonami_"..asset_name]
				if def._type == "monster" and inv:contains_item("main", modname .. ":zoonami_prism") then
					staticdata = {prisma_id = 1}
				end
				local pos = pointed_thing.above
				pos.y = pos.y - def.initial_properties.collisionbox[2]
				minetest.add_entity(pos, modname .. ":zoonami_"..asset_name, minetest.serialize(staticdata))
				local creative_mode = minetest.settings:get_bool("creative_mode")
				local creative_privs = minetest.check_player_privs(placer,{creative = true})
				if not creative_mode and not creative_privs then
					itemstack:take_item()
					return itemstack
				end
			end
		end,
	})
end

-- Mob spawn lookup table
mobs_api.mob = {}
mobs_api.mob.spawn_table = {}
mobs_api.mob.rarity = {"common", "uncommon", "rare", "mythical", "legendary"}
mobs_api.mob.time = {"day", "night"}
mobs_api.mob.light = {"bright", "medium", "dark"}
mobs_api.mob.height = {"sky", "aboveground", "underground", "bedrock"}
mobs_api.mob.node = {group.choppy, group.cracky, group.crumbly, group.grass, group.lava, group.leaves, group.sand, group.snowy, group.stone, group.water}

-- Return if any monsters spawn in the following conditions
function mobs_api.mob.spawn_table_lookup(rarity, times, light, height, node)
	if mobs_api.mob.spawn_table[rarity] and
	   mobs_api.mob.spawn_table[rarity][times] and
	   mobs_api.mob.spawn_table[rarity][times][light] and
	   mobs_api.mob.spawn_table[rarity][times][light][height] and
	   mobs_api.mob.spawn_table[rarity][times][light][height][node] then
		return mobs_api.mob.spawn_table[rarity][times][light][height][node]
	end
end

-- Adds mobs to spawn lookup table
function mobs_api.mob.register_spawn(mob)
	local spawn_table = mobs_api.mob.spawn_table
	local rarity = mob.spawn_chance
	local times = mob.spawn_time
	local light = mob.spawn_light
	local height = mob.spawn_height
	local nodes = mob.spawn_on
	
	for i1 = 1, #times do
		for i2 = 1, #light do
			for i3 = 1, #height do
				for i4 = 1, #nodes do
					spawn_table[rarity] = spawn_table[rarity] or {}
					spawn_table[rarity][times[i1]] = spawn_table[rarity][times[i1]] or {}
					spawn_table[rarity][times[i1]][light[i2]] = spawn_table[rarity][times[i1]][light[i2]] or {}
					spawn_table[rarity][times[i1]][light[i2]][height[i3]] = spawn_table[rarity][times[i1]][light[i2]][height[i3]] or {}
					spawn_table[rarity][times[i1]][light[i2]][height[i3]][nodes[i4]] = spawn_table[rarity][times[i1]][light[i2]][height[i3]][nodes[i4]] or {}
					local names = spawn_table[rarity][times[i1]][light[i2]][height[i3]][nodes[i4]]
					names[#names + 1] = mob.asset_name
				end
			end
		end
	end
end

-- Mob spawn step settings
local prisma_chance = tonumber(settings:get("zoonami_prisma_chance") or 1500)
local spawn_in_protected_areas = settings:get_bool("zoonami_spawn_in_protected_areas") or false
local max_nearby_npcs = tonumber(settings:get("zoonami_max_nearby_npcs") or 1)
local max_nearby_mobs = tonumber(settings:get("zoonami_max_nearby_mobs") or 2)
local spawn_interval = tonumber(settings:get("zoonami_spawn_interval") or 8)
local spawn_timer = spawn_interval
local abr = minetest.get_mapgen_setting('active_block_range')
local mg_name = minetest.get_mapgen_setting("mg_name")
local sky_height_level = mg_name == "v6" and 30 or mg_name == "flat" and 53 or 70

-- Spawn step based on Cube Mobs by Xanthus (see LICENSE.txt for more details)
function mobs_api.mob.spawn_step(dtime)
	spawn_timer = spawn_timer - dtime
	if spawn_timer > 0 then 
		return
	end
	spawn_timer = spawn_interval

	for _, player in pairs(minetest.get_connected_players()) do
		local player_pos = player:get_pos()
		local node_pos = nil
		local spawn_pos = nil
		local failed_attempts = 0
		local nearby_mobs = 0
		local yaw = (math.random(0, 360) - 180) / 180 * math.pi
		local cave_modifier = player_pos.y < -8 and 0.25 or 1
		local dist = abr * 16 * cave_modifier * (math.random() * 0.5 + 0.75)
		local dir = vector.multiply(minetest.yaw_to_dir(yaw),dist)
		local pos2 = vector.add(player_pos, dir)
		pos2.y = pos2.y - 5
		
		-- Determines if spawn attempt is for an NPC
		local npc_chair_start = vector.offset(pos2, -10, -10, -10)
		local npc_chair_end = vector.offset(pos2, 10, 10, 10)
		local npc_spawn = minetest.find_nodes_in_area(npc_chair_start, npc_chair_end, modname .. ":zoonami_npc_wood_chair_active")
		npc_spawn = npc_spawn[1]
		
		-- Prevent spawning if too many mobs nearby
		local objs = minetest.get_objects_inside_radius(pos2, 20)
		for _,obj in pairs(objs) do
			if not obj:is_player() then
				local luaent = obj:get_luaentity()
				if luaent and luaent.name:find('zoonami:') then
					if not npc_spawn or npc_spawn and luaent._type == "npc" then
						nearby_mobs = nearby_mobs + 1
						if npc_spawn and nearby_mobs > max_nearby_npcs or not npc_spawn and nearby_mobs > max_nearby_mobs then
							goto continue
						end
					end
				end
			end
		end
		
		-- pos2 is center of where we want to search
		-- pos_spawn_start and pos_spawn_end define corners
		local pos_spawn_start = npc_spawn and vector.offset(npc_spawn, -10, -3, -10) or vector.offset(pos2, -4, -15, -4)
		local pos_spawn_end = npc_spawn and vector.offset(npc_spawn, 10, 1, 10) or vector.offset(pos2, 4, 15, 4)
		local potential_spawns = minetest.find_nodes_in_area_under_air(pos_spawn_start, pos_spawn_end, mobs_api.mob.node)
		
		-- Stop if there are no potential spawn spaces
		if #potential_spawns < 1 then
			goto continue
		end

		-- Find random spawn outside of protected areas
		-- Spawning fails after 10 attempts
		while not node_pos do
			local random_pos = potential_spawns[math.random(#potential_spawns)]
			if spawn_in_protected_areas or not minetest.is_protected(random_pos, "") then
				node_pos = vector.new(random_pos)
			else
				failed_attempts = failed_attempts + 1
				if failed_attempts >= 10 then
					goto continue
				end
			end
		end
		
		if npc_spawn then
			mobs_api.mob.spawn_npc(node_pos)
		else
			mobs_api.mob.spawn(node_pos)
		end
		::continue::
	end
end

-- Spawn NPC in village
function mobs_api.mob.spawn_npc(node_pos)
	local npcs = {"chatterbox", "chatterbox", "trainer", "trainer", "merchant"}
	local asset_name = npcs[math.random(#npcs)]
	local def = minetest.registered_entities[modname .. ":zoonami_"..asset_name]
	node_pos.y = node_pos.y + 1 - def.initial_properties.collisionbox[2]
	minetest.add_entity(node_pos, modname .. ":zoonami_"..asset_name)
end

-- Spawn mob
function mobs_api.mob.spawn(node_pos)
	local spawn_pos = vector.offset(node_pos, 0, 1, 0)
	
	local rarity = math.random()
	if rarity >= 0.999 then
		rarity = "legendary"
	elseif rarity >= 0.997 then
		rarity = "mythical"
	elseif rarity >= 0.987 then
		rarity = "rare"
	elseif rarity >= 0.887 then
		rarity = "uncommon"
	else
		rarity = "common"
	end
	
	local current_time = minetest.get_timeofday()
	local day_or_night = nil
	if current_time > 0.8 or current_time < 0.25 then
		day_or_night = "night"
	else
		day_or_night = "day"
	end
	
	local light_pos = {}
	local light_level = minetest.get_node_light(spawn_pos)
	if not light_level then
		return
	elseif light_level >= 10 then
		light_level = "bright"
	elseif light_level >= 5 then
		light_level = "medium"
	elseif light_level >= 0 then
		light_level = "dark"
	end
	
	local height_level = spawn_pos.y
	if height_level > sky_height_level then
		height_level = "sky"
	elseif height_level > -5 then
		height_level = "aboveground"
	elseif height_level > -500 then
		height_level = "underground"
	else
		height_level = "bedrock"
	end
	
	local node = minetest.get_node(node_pos)
	local node_def = minetest.registered_nodes[node.name]
	local node_groups = node_def and node_def.groups
	local node_group_matches = {}
	local node_group = nil

	for i, v in pairs(mobs_api.mob.node) do
		local group = v:split(":")[2]
		if node_groups[group] then
			node_group_matches[#node_group_matches + 1] = v
		end
	end

	if #node_group_matches >= 1 then
		local mob_count_total = 0
		for i = 1, #node_group_matches do
			local count = mobs_api.mob.spawn_table_lookup(rarity, day_or_night, light_level, height_level, node_group_matches[i]) or {}
			mob_count_total = mob_count_total + #count
		end
		for i = 1, #node_group_matches do
			local count = mobs_api.mob.spawn_table_lookup(rarity, day_or_night, light_level, height_level, node_group_matches[i]) or {}
			if #count >= math.random(mob_count_total) or i == #node_group_matches then
				node_group = node_group_matches[i]
				break
			end
		end
	end
	
	local mob_list = table.copy(mobs_api.mob.spawn_table_lookup(rarity, day_or_night, light_level, height_level, node_group) or {})
	local spawn_by_start = vector.offset(spawn_pos, -10, -10, -10)
	local spawn_by_end = vector.offset(spawn_pos, 10, 10, 10)
	while #mob_list > 0 do
		local mob_name = table.remove(mob_list, math.random(#mob_list))
		local spawn_by = nil
		local staticdata = nil
		if monsters.stats[mob_name] then
			spawn_by = monsters.stats[mob_name].spawn_by
			if math.random(prisma_chance) == 1 then
				staticdata = {prisma_id = 1}
				staticdata = minetest.serialize(staticdata)
			end
		elseif npc_stats.npc[mob_name] then
			spawn_by = npc_stats.npc[mob_name].spawn_by
		end
		
		local found_nearby = spawn_by and minetest.find_nodes_in_area(spawn_by_start, spawn_by_end, spawn_by)
		found_nearby = found_nearby and #found_nearby > 0
		if not spawn_by or spawn_by and found_nearby then
			local def = minetest.registered_entities[modname .. ":zoonami_"..mob_name]
			spawn_pos.y = spawn_pos.y - def.initial_properties.collisionbox[2]
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
			minetest.add_entity(spawn_pos, modname .. ":zoonami_"..mob_name, staticdata)
			mob_list = {}
		end
	end
end

return mobs_api
