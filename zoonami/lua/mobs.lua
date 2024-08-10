-- Adds monster mobs and NPC mobs via mobs api

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local npc_stats = dofile(mod_path .. "/lua/npc_stats.lua")
local mobs_api = dofile(mod_path .. "/lua/mobs_api.lua")
local mobs_3d = nil

-- Mob settings
local settings = minetest.settings
local generate_villages = settings:get_bool("zoonami_generate_villages") ~= false
local prepopulate_villages = settings:get_bool("zoonami_prepopulate_villages") ~= false
local prepopulate_world = settings:get_bool("zoonami_prepopulate_world") ~= false
local prepopulate_world_multiplier = tonumber(settings:get("zoonami_prepopulate_world_multiplier") or 1)
local mobs_spawn_around_players = settings:get_bool("zoonami_mobs_spawn_around_players") ~= false
local mg_name = minetest.get_mapgen_setting("mg_name")

-- Use 3D mobs mod if installed and enabled
-- if minetest.get_modpath("zoonami_3d_mobs") and zoonami_3d_mobs then
	-- if settings:get_bool("zoonami_3d_mobs") ~= false then
		mobs_3d = zoonami_3d_mobs.mobs()
	-- end
-- end

-- Register all monsters with mobs api
for k, v in pairs(monsters.stats) do
	local monster = v
	local collisionbox = monster.spawn_collisionbox
	local visual = "upright_sprite"
	local visual_size = monster.spawn_visual_size
	local mesh = nil
	local textures = {"zoonami_"..monster.asset_name.."_front.png", "zoonami_"..monster.asset_name.."_back.png"}
	
	if mobs_3d then
		local mob = mobs_3d[monster.asset_name]
		if mob then
			collisionbox = mob.collision_box
			visual = "mesh"
			visual_size = mob.visual_size
			mesh = mob.mesh
			textures = {mob.texture}
		end
	end
	
	mobs_api.register_mob(modname .. ":zoonami_"..monster.asset_name, {
		type = "monster",
		hp_max = 1,
		armor_groups = {},
		collisionbox = collisionbox,
		visual = visual,
		visual_size = visual_size,
		mesh = mesh,
		textures = textures,
		makes_footstep_sound = true,
		swim = monster.spawn_swim,
		float = monster.spawn_float,
		sink = monster.spawn_sink,
		drown = monster.spawn_drown,
		burn = monster.spawn_burn,
		walk_velocity = monster.spawn_walk_velocity,
		stepheight = monster.spawn_swim and 0 or 1.1,
		on_rightclick = function(self, clicker)
			-- Check if clicker has any Zoonami monsters and if any have more than 0 health before starting battle
			if not clicker or not clicker:is_player() then return end
			local meta = clicker:get_meta()
			local player_monsters = {}
			local able_to_battle = false
			local average_player_level = 0
			for i = 1, 5 do
				local monster = meta:get_string("zoonami_monster_"..i)
				monster = minetest.deserialize(monster)
				if monster then
					player_monsters["monster#"..i] = monster
					average_player_level = average_player_level == 0 and monster.level or (average_player_level + monster.level) / 2
					if monster.health > 0 then
						able_to_battle = true
					end
				end
			end
			if able_to_battle then
				local mt_player_name = clicker:get_player_name()
				local min_level = self._spawn_min_level or monster.spawn_min_level
				local max_level = self._spawn_max_level or monster.spawn_max_level
				local weight_ratio = (math.min(math.max(average_player_level / max_level, 1.2), 1.6) - 1.2) * 1.66
				local random_level = math.random(min_level, max_level)
				local weighted_level = math.random(random_level, max_level)
				local level = math.floor((random_level * (1 - weight_ratio) + weighted_level * weight_ratio) + 0.5)
				local presets = {prisma_id = self._prisma_id}
				local enemy_monsters = {
					["monster#1"] = monsters.generate(monster.asset_name, level, presets)
				}
				self.object:remove()
				zoonami.start_battle(mt_player_name, player_monsters, enemy_monsters, "wild")
			end
		end,
	})
	
	mobs_api.register_egg(monster.asset_name, "Spawn "..monster.name, "zoonami_"..monster.asset_name.."_front.png")
	
	mobs_api.mob.register_spawn(monster)
end

-- Register all NPCs with mobs api
for k, v in pairs(npc_stats.npc) do
	local npc = v
	mobs_api.register_mob(modname .. ":zoonami_"..npc.asset_name, {
		type = "npc",
		hp_max = 20,
		armor_groups = npc.armor_groups,
		collisionbox = {-0.35,-1.0,-0.35, 0.35,0.8,0.35},
		visual = "mesh",
		mesh = "zoonami_npc.b3d",
		texture_list = npc.texture_list,
		makes_footstep_sound = true,
		float = npc.spawn_float,
		burn = npc.spawn_burn,
		walk_velocity = npc.spawn_walk_velocity,
		stepheight = 1.1,
		stay_near = npc.stay_near,
		prevent_despawn = npc.prevent_despawn,
		on_rightclick = npc.on_rightclick,
		animation = {
			speed_normal = 15,
			speed_run = 20,
			stand_start = 0,
			stand_end = 79,
			walk_start = 168,
			walk_end = 187,
			run_start = 168,
			run_end = 187,
			punch_start = 200,
			punch_end = 219,
		},
	})
	
	mobs_api.register_egg(npc.asset_name, "Spawn "..npc.name, "zoonami_spawn_"..npc.asset_name..".png")
	
	if npc.spawn_chance then
		mobs_api.mob.register_spawn(npc)
	end
end

-- Spawn mobs in the wild and in villages near players
if mobs_spawn_around_players then
	minetest.register_globalstep(mobs_api.mob.spawn_step)
end

-- Generate wild monsters during mapgen
if prepopulate_world and prepopulate_world_multiplier > 0 then
	minetest.register_lbm({
		label = "Zoonami Mapgen Monster Spawning",
		name = modname .. ":zoonami_mapgen_monster_spawning",
		nodenames = {modname .. ":zoonami_monster_mapgen_spawn"},
		run_at_every_load = true,
		action = function(pos, node)
			minetest.after(2, function()
				minetest.set_node(pos, {name = "air"})
				pos.y = pos.y - 1
				mobs_api.mob.spawn(pos)
			end)
		end,
	})
end

-- Generate NPCs in villages
if generate_villages and prepopulate_villages and mg_name ~= "v6" then
	minetest.register_lbm({
		label = "Zoonami NPC Village Spawning",
		name = modname .. ":zoonami_npc_village_spawning",
		nodenames = {modname .. ":zoonami_npc_mapgen_spawn"},
		run_at_every_load = true,
		action = function(pos, node)
			minetest.after(2, function()
				minetest.set_node(pos, {name = "air"})
				pos.y = pos.y + 1
				local npc_types = {"chatterbox", "trainer"}
				local random_type = npc_types[math.random(#npc_types)]
				minetest.add_entity(pos, modname .. ":zoonami_"..random_type)
			end)
		end,
	})
end
