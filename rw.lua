local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()



-- local RW_ammo_capabilities = {}

local rwtools = {}

local rw = {}

local l = {
	"node",
	"craftitem",
	"tool",
}

for i, v in ipairs(l) do
	rw["register_" .. v] = function(name, def)
	
		local defaultdef = {
		}
		local defaultgroups = {
			not_in_creative_inventory = 1,
		}

		if v == "tool" then
			defaultdef.on_use = function() return end
			-- defaultdef.wield_scale = mcl_vars.tool_wield_scale
			defaultdef._mcl_toollike_wield = true
			defaultgroups.weapon = 1
			defaultgroups.weapon_ranged = 1

			defaultgroups.not_in_creative_inventory = 0
			if not name:match("_r+$")
				and not name:match("_rld$")
				and not name:match("_uld$")
			then
				table.insert(rwtools, name)
			end
		elseif v == "craftitem" then

			if name == modname .. ":rw_diamond_shuriken" or
			   name == modname .. ":rw_hand_grenade"
			then
				defaultgroups.not_in_creative_inventory = 0
				table.insert(rwtools, name)
			end
			-- local ammoname = string.gsub(name, modname .. ":rw_", "")
			-- minetest.log(tostring(ammoname))
			-- RW_ammo_capabilities[ammoname] = def.RW_ammo_capabilities
		end
		
		for i, v in pairs(def) do
			defaultdef[i] = v
		end
		if def.groups then
			for i, v in pairs(def.groups) do
				defaultgroups[i] = v
			end
		end
		
		defaultdef.groups = defaultgroups

		local showlist = {
		}
		for i, v in ipairs(showlist) do
			if modname .. ":rw_" .. v == name then
				defaultdef.groups.not_in_creative_inventory = 0
			end
		end

		minetest["register_" .. v](name, defaultdef)
	end
	
end

rw.sound_play = function(spec, parameters, e)
	if parameters.gain ~= nil then
		parameters.gain = parameters.gain * 0.1
	else
		parameters.gain = 0.1
	end
	minetest.sound_play(spec, parameters, e)
end


minetest.register_chatcommand("rw", {
    privs = {
        server = true,
    },
    func = function(name, param)
		local pos = minetest.get_player_by_name(name):getpos()
		for k, v in ipairs(rwtools) do
			-- minetest.chat_send_player(name, "Spawning Item at " .. minetest.pos_to_string(pos) .. ", please wait")
			minetest.spawn_item(pos, v)
		end
		return true, "successfully spawned"
    end,
})



local function damage_particles(pos, is_critical)
	if is_critical then
		minetest.add_particlespawner({
			amount = 15,
			time = 0.1,
			minpos = vector.offset(pos, -0.5, -0.5, -0.5),
			maxpos = vector.offset(pos, 0.5, 0.5, 0.5),
			minvel = vector.new(-0.1, -0.1, -0.1),
			maxvel = vector.new(0.1, 0.1, 0.1),
			minexptime = 1,
			maxexptime = 2,
			minsize = 1.5,
			maxsize = 1.5,
			collisiondetection = false,
			vertical = false,
			texture = "mcl_particles_crit.png^[colorize:#bc7a57:127",
		})
	end
end



local enable_pvp = minetest.settings:get_bool("enable_pvp")

-- Time in seconds after which a stuck arrow is deleted
local ARROW_TIMEOUT = 60
-- Time after which stuck arrow is rechecked for being stuck
local STUCK_RECHECK_TIME = 5

--local GRAVITY = 9.81

local YAW_OFFSET = -math.pi/2

local function dir_to_pitch(dir)
	--local dir2 = vector.normalize(dir)
	local xz = math.abs(dir.x) + math.abs(dir.z)
	return -math.atan2(-dir.y, xz)
end

local function random_arrow_positions(positions, placement)
	if positions == "x" then
		return math.random(-4, 4)
	elseif positions == "y" then
		return math.random(0, 10)
	end
	if placement == "front" and positions == "z" then
		return 3
	elseif placement == "back" and positions == "z" then
		return -3
	end
	return 0
end



function node_sound_wood_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="default_wood_footstep", gain=0.15}
	table.dug = table.dug or
			{name="default_wood_footstep", gain=1.0}
	table.dig = table.dig or
			{name="default_dig_choppy", gain=0.4}
	return table
end


if minetest.global_exists("armor") and armor.attributes then
	table.insert(armor.attributes, "bullet_res")
	table.insert(armor.attributes, "ammo_save")
	table.insert(armor.attributes, "ranged_dmg")
end

--[[rw.register_node(
	modname .. ":rw_antigun_block",
	{
		description = "" ..
			core.colorize("#35cdff", "Anti-gun block\n") ..
				core.colorize(
					"#FFFFFF",
					"Prevents people from using guns, in 10 node radius to each side from this block"
				),
		tiles = {"antigun_block.png"},
		groups = {choppy = 3, oddly_breakable_by_hand = 3},
		sounds = default.node_sound_wood_defaults()
	}
)--]]
----
---- gun_funcs
----

local function update_ammo_counter_on_gun(gunMeta)
	gunMeta:set_string("count_meta", tostring(gunMeta:get_int("RW_bullets")))
end

make_sparks = function(pos)
	rw.sound_play("ricochet", {pos = pos, gain = 0.75})
	for i = 1, 9 do
		minetest.add_particle(
			{
				pos = pos,
				velocity = {x = math.random(-6.0, 6.0), y = math.random(-10.0, 15.0), z = math.random(-6.0, 6.0)},
				acceleration = {x = math.random(-9.0, 9.0), y = math.random(-15.0, -3.0), z = math.random(-9.0, 9.0)},
				expirationtime = 1.0,
				size = math.random(1, 2),
				collisiondetection = true,
				vertical = false,
				texture = "spark.png",
				glow = 25
			}
		)
	end
end

local max_gun_efficiency = tonumber(minetest.settings:get(modname .. "_max_gun_efficiency")) or 300

rangedweapons_gain_skill = function(player, skill, chance)
	--[[if math.random(1, chance) == 1 then
		local p_meta = player:get_meta()
		local skill_num = p_meta:get_int(skill)
		if skill_num < max_gun_efficiency then
			p_meta:set_int(skill, skill_num + 1)
			minetest.chat_send_player(
				player:get_player_name(),
				"" .. core.colorize("#25c200", "You've improved your skill with this type of gun!")
			)
		end
	end--]]
end

rangedweapons_reload_gun = function(itemstack, player)
	local playeriscreative = minetest.is_creative_enabled(player:get_player_name())
	
	local GunCaps = itemstack:get_definition().RW_gun_capabilities

	local gun_unload_sound = ""
	if GunCaps ~= nil then
		gun_unload_sound = GunCaps.gun_unload_sound or ""
	end

	rw.sound_play(gun_unload_sound, {pos = player:get_pos()})

	local gun_reload = 0.25

	if GunCaps ~= nil then
		gun_reload = GunCaps.gun_reload or 0.25
	end

	local playerMeta = player:get_meta()
	local gunMeta = itemstack:get_meta()

	gunMeta:set_float("RW_reload_delay", gun_reload)

	playerMeta:set_float("rw_cooldown", gun_reload)

	local player_has_ammo = 0
	local clipSize = 0
	local reload_ammo = ""

	if GunCaps.suitable_ammo ~= nil then
		local inv = player:get_inventory()
		for i = 1, inv:get_size("main") do
			for _, ammo in pairs(GunCaps.suitable_ammo) do
				if inv:get_stack("main", i):get_name() == ammo[1] then
					reload_ammo = inv:get_stack("main", i)
					clipSize = ammo[2]

					player_has_ammo = 1
					break
				end
			end

			if player_has_ammo == 1 then
				break
			end
		end
		if player_has_ammo == 0 and playeriscreative then
			ammo = GunCaps.suitable_ammo[1]
			
			reload_ammo = ItemStack(ammo[1] .. " 65535")
			clipSize = ammo[2]

			player_has_ammo = 1
		end
	end

	if player_has_ammo == 1 then
		local gunMeta = itemstack:get_meta()
		local ammoCount = gunMeta:get_int("RW_bullets")
		local ammoName = gunMeta:get_string("RW_ammo_name")
		local inv = player:get_inventory()

		if minetest.settings:get_bool(modname .. "_infinite_ammo", false) or playeriscreative then
			gunMeta:set_int("RW_bullets", clipSize)
		else
			inv:add_item("main", ammoName .. " " .. ammoCount)

			if inv:contains_item("main", reload_ammo:get_name() .. " " .. clipSize) then
				if not playeriscreative then
					inv:remove_item("main", reload_ammo:get_name() .. " " .. clipSize)
				end
				gunMeta:set_int("RW_bullets", clipSize)
			else
				gunMeta:set_int("RW_bullets", reload_ammo:get_count())
				if not playeriscreative then
					inv:remove_item("main", reload_ammo:get_name() .. " " .. reload_ammo:get_count())
				end
			end
		end

		gunMeta:set_string("RW_ammo_name", reload_ammo:get_name())

		update_ammo_counter_on_gun(gunMeta)

		if GunCaps.gun_magazine ~= nil then
			local pos = player:get_pos()
			local dir = player:get_look_dir()
			local yaw = player:get_look_horizontal()
			if pos and dir and yaw then
				pos.y = pos.y + 1.4
				local obj = minetest.add_entity(pos, modname .. ":rw_mag")
				if obj then
					obj:set_properties({textures = {GunCaps.gun_magazine}})
					obj:set_velocity({x = dir.x * 2, y = dir.y * 2, z = dir.z * 2})
					obj:set_acceleration({x = 0, y = -5, z = 0})
					obj:set_rotation({x = 0, y = yaw - math.pi / 2, z = 0})
				end
			end
		end

		if GunCaps.gun_unloaded ~= nil then
			itemstack:set_name(GunCaps.gun_unloaded)
		end
	end
end

rangedweapons_single_load_gun = function(itemstack, player)
	local playeriscreative = minetest.is_creative_enabled(player:get_player_name())
	
	local GunCaps = itemstack:get_definition().RW_gun_capabilities

	if GunCaps ~= nil then
		gun_unload_sound = GunCaps.gun_unload_sound or ""
	end

	rw.sound_play(gun_unload_sound, {pos = player:get_pos()})

	local gun_reload = 0.25

	if GunCaps ~= nil then
		gun_reload = GunCaps.gun_reload or 0.25
	end

	local playerMeta = player:get_meta()
	local gunMeta = itemstack:get_meta()

	gunMeta:set_float("RW_reload_delay", gun_reload)

	playerMeta:set_float("rw_cooldown", gun_reload)

	local player_has_ammo = 0
	local clipSize = 0
	local reload_ammo = ""

	if GunCaps.suitable_ammo ~= nil then
		local inv = player:get_inventory()
		for i = 1, inv:get_size("main") do
			for _, ammo in pairs(GunCaps.suitable_ammo) do
				if inv:get_stack("main", i):get_name() == ammo[1] then
					reload_ammo = inv:get_stack("main", i)
					clipSize = ammo[2]

					player_has_ammo = 1
					break
				end
			end
			if player_has_ammo == 0 and playeriscreative then
				local ammo = GunCaps.suitable_ammo[1]
				
				reload_ammo = ItemStack(ammo[1] .. " 65535")
				clipSize = ammo[2]
	
				player_has_ammo = 1
			end
	
			if player_has_ammo == 1 then
				break
			end
		end
		if player_has_ammo == 0 and playeriscreative then
			ammo = GunCaps.suitable_ammo[1]
			
			reload_ammo = ItemStack(ammo[1] .. " 65535")
			clipSize = ammo[2]
		end
	end

	if player_has_ammo == 1 then
		local gunMeta = itemstack:get_meta()
		local ammoCount = gunMeta:get_int("RW_bullets")
		local ammoName = gunMeta:get_string("RW_ammo_name")
		local inv = player:get_inventory()

		if ammoName ~= reload_ammo:get_name() then
			inv:add_item("main", ammoName .. " " .. ammoCount)
			gunMeta:set_int("RW_bullets", 0)
		end

		if (inv:contains_item("main", reload_ammo:get_name()) or playeriscreative) and gunMeta:get_int("RW_bullets") < clipSize then
			if not minetest.settings:get_bool(modname .. "_infinite_ammo", false) or not playeriscreative then
				inv:remove_item("main", reload_ammo:get_name())
			end
			gunMeta:set_int("RW_bullets", gunMeta:get_int("RW_bullets") + 1)
		end

		gunMeta:set_string("RW_ammo_name", reload_ammo:get_name())

		update_ammo_counter_on_gun(gunMeta)

		if GunCaps.gun_unloaded ~= nil then
			itemstack:set_name(GunCaps.gun_unloaded)
		end
	end
end

rangedweapons_yeet = function(itemstack, player)
	local playeriscreative = minetest.is_creative_enabled(player:get_player_name())
	
	--[[if minetest.find_node_near(player:get_pos(), 10, modname .. ":rw_antigun_block") then
		minetest.chat_send_player(
			player:get_player_name(),
			"" .. core.colorize("#ff0000", "throwable weapons are prohibited in this area!")
		)
	else--]]
		local ThrowCaps = itemstack:get_definition().RW_throw_capabilities
		local playerMeta = player:get_meta()

		local throw_cooldown = 0
		if ThrowCaps ~= nil then
			throw_cooldown = ThrowCaps.throw_cooldown or 0
		end

		if playerMeta:get_float("rw_cooldown") <= 0 then
			playerMeta:set_float("rw_cooldown", throw_cooldown)

			local throw_damage = {fleshy = 1}
			local throw_sound = "throw"
			local throw_velocity = 20
			local throw_accuracy = 100
			local throw_cooling = 0
			local throw_crit = 0
			local throw_critEffc = 1
			local throw_projectiles = 1
			local throw_mobPen = 0
			local throw_nodePen = 0
			local throw_dps = 0
			local throw_gravity = 0
			local throw_door_breaking = 0
			local throw_skill = ""
			local throw_skillChance = 0
			local throw_smokeSize = 0
			local throw_ent = modname .. ":rw_shot_bullet"
			local throw_visual = "wielditem"
			local throw_texture = modname .. ":rw_shot_bullet_visual"
			local throw_glass_breaking = 0
			local throw_particles = {}
			local throw_sparks = 0
			local throw_bomb_ignite = 0
			local throw_size = 0
			local throw_glow = 0
			local OnCollision = function()
			end

			if ThrowCaps ~= nil then
				throw_damage = ThrowCaps.throw_damage or {fleshy = 1}
				throw_sound = ThrowCaps.throw_sound or "glock"
				throw_velocity = ThrowCaps.throw_velocity or 20
				throw_accuracy = ThrowCaps.throw_accuracy or 100
				throw_cooling = ThrowCaps.throw_cooling or itemstack:get_name()
				throw_crit = ThrowCaps.throw_crit or 0
				throw_critEffc = ThrowCaps.throw_critEffc or 1
				throw_projectiles = ThrowCaps.throw_projectiles or 1
				throw_mobPen = ThrowCaps.throw_mob_penetration or 0
				throw_nodePen = ThrowCaps.throw_node_penetration or 0
				throw_dps = ThrowCaps.throw_dps or 0
				throw_gravity = ThrowCaps.throw_gravity or 0
				throw_door_breaking = ThrowCaps.throw_door_breaking or 0
				throw_ent = ThrowCaps.throw_entity or modname .. ":rw_shot_bullet"
				throw_visual = ThrowCaps.throw_visual or "wielditem"
				throw_texture = ThrowCaps.throw_texture or modname .. ":rw_shot_bullet_visual"
				throw_glass_breaking = ThrowCaps.throw_glass_breaking or 0
				throw_particles = ThrowCaps.throw_particles or nil
				throw_sparks = ThrowCaps.throw_sparks or 0
				throw_bomb_ignite = ThrowCaps.ignites_explosives or 0
				throw_size = ThrowCaps.throw_projectile_size or 0
				throw_glow = ThrowCaps.throw_projectile_glow or 0
				OnCollision = ThrowCaps.OnCollision or function()
					end

				if ThrowCaps.throw_skill ~= nil then
					throw_skill = ThrowCaps.throw_skill[1] or ""
					throw_skillChance = ThrowCaps.throw_skill[2] or 0
				else
					throw_skill = ""
					throw_skillChance = 0
				end
			end

			if throw_skillChance > 0 and throw_skill ~= "" then
				rangedweapons_gain_skill(player, throw_skill, throw_skillChance)
			end

			local skill_value = 1
			if throw_skill ~= "" then
				skill_value = playerMeta:get_int(throw_skill) / 100
			end

			rangedweapons_launch_projectile(
				player,
				throw_projectiles,
				throw_damage,
				throw_ent,
				throw_visual,
				throw_texture,
				throw_sound,
				throw_velocity,
				throw_accuracy,
				skill_value,
				OnCollision,
				throw_crit,
				throw_critEffc,
				throw_mobPen,
				throw_nodePen,
				0,
				"",
				"",
				"",
				throw_dps,
				throw_gravity,
				throw_door_breaking,
				throw_glass_breaking,
				throw_particles,
				throw_sparks,
				throw_bomb_ignite,
				throw_size,
				0,
				itemstack:get_wear(),
				throw_glow
			)
			
			if not playeriscreative then
				itemstack:take_item()
			end
		end
	--end
end

rangedweapons_shoot_gun = function(itemstack, player)
	local playeriscreative = minetest.is_creative_enabled(player:get_player_name())

	--[[if minetest.find_node_near(player:get_pos(), 10, modname .. ":rw_antigun_block") then
		rw.sound_play("empty", {pos = player:get_pos()})
		minetest.chat_send_player(
			player:get_player_name(),
			"" .. core.colorize("#ff0000", "Guns are prohibited in this area!")
		)
	else--]]
		local gun_cooldown = 0
		local GunCaps = itemstack:get_definition().RW_gun_capabilities
		local gun_ammo_save = 0

		if GunCaps ~= nil then
			gun_cooldown = GunCaps.gun_cooldown or 0
			gun_ammo_save = GunCaps.ammo_saving or 0
		end

		local gunMeta = itemstack:get_meta()
		local playerMeta = player:get_meta()

		if gunMeta:get_int("RW_bullets") > 0 and playerMeta:get_float("rw_cooldown") <= 0 then
			playerMeta:set_float("rw_cooldown", gun_cooldown)

			if math.random(1, 100) > gun_ammo_save then
				gunMeta:set_int("RW_bullets", gunMeta:get_int("RW_bullets") - 1)
			end

			update_ammo_counter_on_gun(gunMeta)

			local OnCollision = function()
			end

			local bulletStack = ItemStack({name = gunMeta:get_string("RW_ammo_name")})
			local AmmoCaps = bulletStack:get_definition().RW_ammo_capabilities

			local gun_damage = {fleshy = 1}
			local gun_sound = "glock"
			local gun_velocity = 20
			local gun_accuracy = 100
			local gun_cooling = 0
			local gun_crit = 0
			local gun_critEffc = 1
			local gun_projectiles = 1
			local gun_mobPen = 0
			local gun_nodePen = 0
			local gun_shell = 0
			local gun_durability = 0
			local gun_dps = 0
			local gun_gravity = 0
			local gun_door_breaking = 0
			local gun_skill = ""
			local gun_skillChance = 0
			local gun_smokeSize = 0

			local bullet_damage = {fleshy = 0}
			local bullet_velocity = 0
			local bullet_ent = modname .. ":rw_shot_bullet"
			local bullet_visual = "wielditem"
			local bullet_texture = modname .. ":rw_shot_bullet_visual"
			local bullet_crit = 0
			local bullet_critEffc = 0
			local bullet_projMult = 1
			local bullet_mobPen = 0
			local bullet_nodePen = 0
			local bullet_shell_ent = modname .. ":rw_empty_shell"
			local bullet_shell_visual = "wielditem"
			local bullet_shell_texture = modname .. ":rw_shelldrop"
			local bullet_dps = 0
			local bullet_gravity = 0
			local bullet_glass_breaking = 0
			local bullet_particles = {}
			local bullet_sparks = 0
			local bullet_bomb_ignite = 0
			local bullet_size = 0
			local bullet_glow = 20

			if GunCaps ~= nil then
				gun_damage = GunCaps.gun_damage or {fleshy = 1}
				gun_sound = GunCaps.gun_sound or "glock"
				gun_velocity = GunCaps.gun_velocity or 20
				gun_accuracy = GunCaps.gun_accuracy or 100
				gun_cooling = GunCaps.gun_cooling or itemstack:get_name()
				gun_crit = GunCaps.gun_crit or 0
				gun_critEffc = GunCaps.gun_critEffc or 1
				gun_projectiles = GunCaps.gun_projectiles or 1
				gun_mobPen = GunCaps.gun_mob_penetration or 0
				gun_nodePen = GunCaps.gun_node_penetration or 0
				gun_shell = GunCaps.has_shell or 0
				gun_durability = GunCaps.gun_durability or 0
				gun_dps = GunCaps.gun_dps or 0
				gun_ammo_save = GunCaps.ammo_saving or 0
				gun_gravity = GunCaps.gun_gravity or 0
				gun_door_breaking = GunCaps.gun_door_breaking or 0
				gun_smokeSize = GunCaps.gun_smokeSize or 0

				if GunCaps.gun_skill ~= nil then
					gun_skill = GunCaps.gun_skill[1] or ""
					gun_skillChance = GunCaps.gun_skill[2] or 0
				else
					gun_skill = ""
					gun_skillChance = 0
				end
			end

			if gun_skillChance > 0 and gun_skill ~= "" then
				rangedweapons_gain_skill(player, gun_skill, gun_skillChance)
			end

			if AmmoCaps ~= nil then
				OnCollision = AmmoCaps.OnCollision or function()
					end
				bullet_damage = AmmoCaps.ammo_damage or {fleshy = 1}
				bullet_velocity = AmmoCaps.ammo_velocity or 0
				bullet_ent = AmmoCaps.ammo_entity or modname .. ":rw_shot_bullet"
				bullet_visual = AmmoCaps.ammo_visual or "wielditem"
				bullet_texture = AmmoCaps.ammo_texture or modname .. ":rw_shot_bullet_visual"
				bullet_crit = AmmoCaps.ammo_crit or 0
				bullet_critEffc = AmmoCaps.ammo_critEffc or 0
				bullet_projMult = AmmoCaps.ammo_projectile_multiplier or 1
				bullet_mobPen = AmmoCaps.ammo_mob_penetration or 0
				bullet_nodePen = AmmoCaps.ammo_node_penetration or 0
				bullet_shell_ent = AmmoCaps.shell_entity or modname .. ":rw_empty_shell"
				bullet_shell_visual = AmmoCaps.shell_visual or "wielditem"
				bullet_shell_texture = AmmoCaps.shell_texture or modname .. ":rw_shelldrop"
				bullet_dps = AmmoCaps.ammo_dps or 0
				bullet_gravity = AmmoCaps.ammo_gravity or 0
				bullet_glass_breaking = AmmoCaps.ammo_glass_breaking or 0
				bullet_particles = AmmoCaps.ammo_particles or nil
				bullet_sparks = AmmoCaps.has_sparks or 0
				bullet_bomb_ignite = AmmoCaps.ignites_explosives or 0
				bullet_size = AmmoCaps.ammo_projectile_size or 0.0050
				bullet_glow = AmmoCaps.ammo_projectile_glow or 20
			end

			local combined_crit = gun_crit + bullet_crit
			local combined_critEffc = gun_critEffc + bullet_critEffc
			local combined_velocity = gun_velocity + bullet_velocity
			local combined_projNum = math.ceil(gun_projectiles * bullet_projMult)
			local combined_mobPen = gun_mobPen + bullet_mobPen
			local combined_nodePen = gun_nodePen + bullet_nodePen
			local combined_dps = gun_dps + bullet_dps
			local combined_dmg = {}
			local combined_gravity = gun_gravity + bullet_gravity

			for _, gunDmg in pairs(gun_damage) do
				if bullet_damage[_] ~= nil then
					combined_dmg[_] = gun_damage[_] + bullet_damage[_]
				else
					combined_dmg[_] = gun_damage[_]
				end
			end
			for _, bulletDmg in pairs(bullet_damage) do
				if gun_damage[_] == nil then
					combined_dmg[_] = bullet_damage[_]
				end
			end

			--minetest.chat_send_all(minetest.serialize(combined_dmg))

			local skill_value = 1
			if gun_skill ~= "" then
				skill_value = playerMeta:get_int(gun_skill) / 100
			end

			rangedweapons_launch_projectile(
				player,
				combined_projNum,
				combined_dmg,
				bullet_ent,
				bullet_visual,
				bullet_texture,
				gun_sound,
				combined_velocity,
				gun_accuracy,
				skill_value,
				OnCollision,
				combined_crit,
				combined_critEffc,
				combined_mobPen,
				combined_nodePen,
				gun_shell,
				bullet_shell_ent,
				bullet_shell_texture,
				bullet_shell_visual,
				combined_dps,
				combined_gravity,
				gun_door_breaking,
				bullet_glass_breaking,
				bullet_particles,
				bullet_sparks,
				bullet_bomb_ignite,
				bullet_size,
				gun_smokeSize,
				0,
				bullet_glow
			)

			if minetest.settings:get_bool(modname .. "_gun_wear", true) and not playeriscreative then
				itemstack:add_wear(65535 / gun_durability)
			end
			itemstack:set_name(gun_cooling)
		end
	--end
end

rangedweapons_shoot_powergun = function(itemstack, player)
	local playeriscreative = minetest.is_creative_enabled(player:get_player_name())

	--[[if minetest.find_node_near(player:get_pos(), 10, modname .. ":rw_antigun_block") then
		rw.sound_play("empty", {pos = player:get_pos()})
		minetest.chat_send_player(
			player:get_player_name(),
			"" .. core.colorize("#ff0000", "Guns are prohibited in this area!")
		)
	else--]]
		local power_cooldown = 0
		local power_consumption = 0
		local PowerCaps = itemstack:get_definition().RW_powergun_capabilities

		if PowerCaps ~= nil then
			power_cooldown = PowerCaps.power_cooldown or 0
			power_consumption = PowerCaps.power_consumption or 0
		end

		local inv = player:get_inventory()
		local playerMeta = player:get_meta()

		if
			(inv:contains_item("main", modname .. ":rw_power_particle " .. PowerCaps.power_consumption) or playeriscreative) and
				playerMeta:get_float("rw_cooldown") <= 0
		 then
			playerMeta:set_float("rw_cooldown", power_cooldown)

			local OnCollision = function()
			end

			local power_damage = {fleshy = 1}
			local power_sound = "laser"
			local power_velocity = 20
			local power_accuracy = 100
			local power_cooling = 0
			local power_crit = 0
			local power_critEffc = 1
			local power_mobPen = 0
			local power_nodePen = 0
			local power_durability = 0
			local power_dps = 0
			local power_gravity = 0
			local power_door_breaking = 0
			local power_skill = ""
			local power_skillChance = 0
			local power_ent = modname .. ":rw_shot_bullet"
			local power_visual = "wielditem"
			local power_texture = modname .. ":rw_shot_bullet_visual"
			local power_glass_breaking = 0
			local power_particles = {}
			local power_sparks = 0
			local power_bomb_ignite = 0
			local power_size = 0
			local power_glow = 20
			local power_projectiles = 1

			if PowerCaps ~= nil then
				power_damage = PowerCaps.power_damage or {fleshy = 1}
				power_sound = PowerCaps.power_sound or "glock"
				power_velocity = PowerCaps.power_velocity or 20
				power_accuracy = PowerCaps.power_accuracy or 100
				power_cooling = PowerCaps.power_cooling or itemstack:get_name()
				power_crit = PowerCaps.power_crit or 0
				power_critEffc = PowerCaps.power_critEffc or 1
				power_projectiles = PowerCaps.power_projectiles or 1
				power_mobPen = PowerCaps.power_mob_penetration or 0
				power_nodePen = PowerCaps.power_node_penetration or 0
				power_durability = PowerCaps.power_durability or 0
				power_dps = PowerCaps.power_dps or 0
				power_gravity = PowerCaps.power_gravity or 0
				power_door_breaking = PowerCaps.power_door_breaking or 0
				OnCollision = PowerCaps.OnCollision or function()
					end
				power_ent = PowerCaps.power_entity or modname .. ":rw_shot_bullet"
				power_visual = PowerCaps.power_visual or "wielditem"
				power_texture = PowerCaps.power_texture or modname .. ":rw_shot_bullet_visual"
				power_glass_breaking = PowerCaps.power_glass_breaking or 0
				power_particles = PowerCaps.power_particles or nil
				power_sparks = PowerCaps.has_sparks or 0
				power_bomb_ignite = PowerCaps.ignites_explosives or 0
				power_size = PowerCaps.power_projectile_size or 0.0050
				power_glow = PowerCaps.power_projectile_glow or 20

				if PowerCaps.power_skill ~= nil then
					power_skill = PowerCaps.power_skill[1] or ""
					power_skillChance = PowerCaps.power_skill[2] or 0
				else
					power_skill = ""
					power_skillChance = 0
				end
			end

			if power_skillChance > 0 and power_skill ~= "" then
				rangedweapons_gain_skill(player, power_skill, power_skillChance)
			end

			local skill_value = 1
			if power_skill ~= "" then
				skill_value = playerMeta:get_int(power_skill) / 100
			end

			rangedweapons_launch_projectile(
				player,
				power_projectiles,
				power_damage,
				power_ent,
				power_visual,
				power_texture,
				power_sound,
				power_velocity,
				power_accuracy,
				skill_value,
				OnCollision,
				power_crit,
				power_critEffc,
				power_mobPen,
				power_nodePen,
				0,
				"",
				"",
				"",
				power_dps,
				power_gravity,
				power_door_breaking,
				power_glass_breaking,
				power_particles,
				power_sparks,
				power_bomb_ignite,
				power_size,
				0,
				0,
				power_glow
			)

			if minetest.settings:get_bool(modname .. "_gun_wear", true) and not playeriscreative then
				itemstack:add_wear(65535 / power_durability)
			end
			itemstack:set_name(power_cooling)
			
			if not playeriscreative then
				inv:remove_item("main", modname .. ":rw_power_particle " .. PowerCaps.power_consumption)
			end
		end
	--end
end

rangedweapons_launch_projectile = function(
	player,
	projNum,
	projDmg,
	projEnt,
	visualType,
	texture,
	shoot_sound,
	combined_velocity,
	accuracy,
	skill_value,
	ColResult,
	projCrit,
	projCritEffc,
	mobPen,
	nodePen,
	has_shell,
	shellEnt,
	shellTexture,
	shellVisual,
	dps,
	gravity,
	door_break,
	glass_break,
	bullet_particles,
	sparks,
	ignite,
	size,
	smokeSize,
	proj_wear,
	proj_glow)
	--minetest.chat_send_all(accuracy)

	----------------------------------
	local pos = player:get_pos()
	local dir = player:get_look_dir()
	local yaw = player:get_look_horizontal()
	local svertical = player:get_look_vertical()

	if pos and dir and yaw then
		rw.sound_play(shoot_sound, {pos = pos, max_hear_distance = 500})
		pos.y = pos.y + 1.45

		if has_shell > 0 and minetest.settings:get_bool(modname .. "_animate_empty_shells", true) then
			local shl = minetest.add_entity(pos, shellEnt)
			shl:set_velocity({x = dir.x * -10, y = dir.y * -10, z = dir.z * -10})
			shl:set_acceleration({x = dir.x * -5, y = -10, z = dir.z * -5})
			shl:set_rotation({x = 0, y = yaw - math.pi / 2, z = -svertical})
			shl:set_properties(
				{
					textures = {shellTexture},
					visual = shellVisual
				}
			)
		end

		if smokeSize > 0 then
			--[[minetest.add_particle(
				{
					pos = pos,
					velocity = {
						x = (dir.x * 3) + (math.random(-10, 10) / 10),
						y = (dir.y * 3) + (math.random(-10, 10) / 10),
						z = (dir.z * 3) + (math.random(-10, 10) / 10)
					},
					acceleration = {x = dir.x * -3, y = 2, z = dir.z * -3},
					expirationtime = math.random(5, 10) / 10,
					size = smokeSize / 2,
					collisiondetection = false,
					vertical = false,
					texture = "tnt_smoke.png",
					glow = 5
				}
			)--]]
		end

		local projectiles = projNum or 1
		for i = 1, projectiles do
			local obj = minetest.add_entity(pos, projEnt)
			local ent = obj:get_luaentity()

			obj:set_properties(
				{
					textures = {texture},
					visual = visualType,
					collisionbox = {-size, -size, -size, size, size, size},
					glow = proj_glow
				}
			)
			ent.owner = player:get_player_name()
			if obj then
				ent.damage = projDmg
				ent.crit = projCrit
				ent.critEffc = projCritEffc
				ent.OnCollision = ColResult
				ent.mobPen = mobPen
				ent.nodePen = nodePen
				ent.dps = dps
				ent.door_break = door_break
				ent.glass_break = glass_break
				ent.skill_value = skill_value
				ent.bullet_particles = bullet_particles
				ent.sparks = sparks
				ent.ignite = ignite
				ent.size = size
				ent.timer = 0 + (combined_velocity / 2000)
				ent.wear = proj_wear
				local acc = (((100 - accuracy) / 10) / skill_value) or 0
				obj:set_velocity(
					{
						x = (dir.x * combined_velocity + math.random(-acc, acc))*3,
						y = (dir.y * combined_velocity + math.random(-acc, acc))*3,
						z = (dir.z * combined_velocity + math.random(-acc, acc))*3
					}
				)
				-- obj:set_acceleration({x = 0, y = -gravity, z = 0})
				obj:set_rotation({x = 0, y = yaw - math.pi / 2, z = -svertical})
			end
		end
	end
end

eject_shell = function(itemstack, player, rld_item, rld_time, rldsound, shell)
	itemstack:set_name(rld_item)
	local meta = player:get_meta()
	meta:set_float("rw_cooldown", rld_time)

	local gunMeta = itemstack:get_meta()

	local bulletStack = ItemStack({name = gunMeta:get_string("RW_ammo_name")})

	local pos = player:get_pos()
	rw.sound_play(rldsound, {pos = pos})
	local dir = player:get_look_dir()
	local yaw = player:get_look_horizontal()
	if pos and dir and yaw then
		pos.y = pos.y + 1.6
		local obj = minetest.add_entity(pos, modname .. ":rw_empty_shell")

		if bulletStack ~= "" then
			local AmmoCaps = bulletStack:get_definition().RW_ammo_capabilities

			local bullet_shell_visual = "wielditem"
			local bullet_shell_texture = modname .. ":rw_shelldrop"

			bullet_shell_visual = AmmoCaps.shell_visual or "wielditem"
			bullet_shell_texture = AmmoCaps.shell_texture or modname .. ":rw_shelldrop"

			obj:set_properties({textures = {bullet_shell_texture}})
			obj:set_properties({visual = bullet_shell_visual})
		end
		if obj then
			obj:set_velocity({x = dir.x * -10, y = dir.y * -10, z = dir.z * -10})
			obj:set_acceleration({x = dir.x * -5, y = -10, z = dir.z * -5})
			obj:set_yaw(yaw - math.pi / 2)
		end
	end
end
---------------------------------------------------

local cooldown_stuff = (function()
	minetest.register_globalstep(function(dtime, player)
		for _, player in pairs(minetest.get_connected_players()) do
			local w_item = player:get_wielded_item()
			local controls = player:get_player_control()
			if controls.zoom then
				if w_item:get_definition().weapon_zoom ~= nil then
		
					
					local wpn_zoom = w_item:get_definition().weapon_zoom
					-- if player:get_properties().zoom_fov ~= wpn_zoom then
					-- 	player:set_properties({zoom_fov = wpn_zoom})
					
					-- end
					
					-- if player:get_fov() ~= wpn_zoom then
					player:set_fov(wpn_zoom, false, 0.1)
					-- end
					
				elseif w_item:get_definition().weapon_zoom == nil then
					-- player:hud_change(scope_hud, "text", "empty_icon.png")
					if player:get_inventory():contains_item(
						"main", "binoculars:binoculars") then
						local new_zoom_fov = 10
						if player:get_properties().zoom_fov ~= new_zoom_fov then
							player:set_properties({zoom_fov = new_zoom_fov})
						end
					else
						local new_zoom_fov = 0
						if player:get_properties().zoom_fov ~= new_zoom_fov then
							player:set_properties({zoom_fov = new_zoom_fov})
						end
					end
					
				end
				
				-- player:hud_change(scope_hud, "text", "scopehud.png")
			else
				-- player:hud_change(scope_hud, "text", "empty_icon.png")
				player:set_fov(86.1, false, 0.1)

			end
			
			
			
			local u_meta = player:get_meta()
			local cool_down = u_meta:get_float("rw_cooldown") or 0
	
	
			if u_meta:get_float("rw_cooldown") > 0 then
				u_meta:set_float("rw_cooldown", cool_down - dtime)
			end
	
			local itemstack = player:get_wielded_item()
	
			if controls.LMB then
				if player:get_wielded_item():get_definition().RW_gun_capabilities then
					if
						player:get_wielded_item():get_definition().RW_gun_capabilities.automatic_gun and player:get_wielded_item():get_definition().RW_gun_capabilities.automatic_gun > 0 then
	
						rangedweapons_shoot_gun(itemstack, player)
						player:set_wielded_item(itemstack)
					end end
	
				if player:get_wielded_item():get_definition().RW_powergun_capabilities then
					if player:get_wielded_item():get_definition().RW_powergun_capabilities.automatic_gun and player:get_wielded_item():get_definition().RW_powergun_capabilities.automatic_gun > 0 then
	
						rangedweapons_shoot_powergun(itemstack, player)
						player:set_wielded_item(itemstack)
					end end
	
			end
	
	
	
			--minetest.chat_send_all(u_meta:get_float("rw_cooldown"))
	
			if u_meta:get_float("rw_cooldown") <= 0 then
				if player:get_wielded_item():get_definition().loaded_gun ~= nil then
					local itemstack = player:get_wielded_item()
	
					if player:get_wielded_item():get_definition().loaded_sound ~= nil then
						rw.sound_play(itemstack:get_definition().loaded_sound, {pos = player:get_pos()})
					end
					itemstack:set_name(player:get_wielded_item():get_definition().loaded_gun)
					player:set_wielded_item(itemstack)
				end
	
				if player:get_wielded_item():get_definition().rw_next_reload ~= nil then
					local itemstack = player:get_wielded_item()
					if itemstack:get_definition().load_sound ~= nil then
						rw.sound_play(itemstack:get_definition().load_sound, {pos = player:get_pos()})
					end
					local gunMeta = itemstack:get_meta()
					u_meta:set_float("rw_cooldown",gunMeta:get_float("RW_reload_delay"))
					itemstack:set_name(player:get_wielded_item():get_definition().rw_next_reload)
					player:set_wielded_item(itemstack)
				end
			end
	
		end
	end)
end)()

skills = (function()
	minetest.register_on_joinplayer(function(player)
		local meta = player:get_meta()
		if meta:get_int("handgun_skill") == 0
		then
			meta:set_int("handgun_skill",100)
		end
		if meta:get_int("mp_skill") == 0
		then
			meta:set_int("mp_skill",100)
		end
		if meta:get_int("smg_skill") == 0
		then
			meta:set_int("smg_skill",100)
		end
		if meta:get_int("shotgun_skill") == 0
		then
			meta:set_int("shotgun_skill",100)
		end
		if meta:get_int("heavy_skill") == 0
		then
			meta:set_int("heavy_skill",100)
		end
		if meta:get_int("arifle_skill") == 0
		then
			meta:set_int("arifle_skill",100)
		end
		if meta:get_int("revolver_skill") == 0
		then
			meta:set_int("revolver_skill",100)
		end
		if meta:get_int("rifle_skill") == 0
		then
			meta:set_int("rifle_skill",100)
		end
		if meta:get_int("throw_skill") == 0
		then
			meta:set_int("throw_skill",100)
		end
	end)
	
	
	minetest.register_chatcommand("gunskills", {
		func = function(name, param)
			for _, player in pairs(minetest.get_connected_players()) do
				local meta = player:get_meta()
				local handguns = meta:get_int("handgun_skill")
				local mps = meta:get_int("mp_skill")
				local smgs = meta:get_int("smg_skill")
				local shotguns = meta:get_int("shotgun_skill")
				local heavy = meta:get_int("heavy_skill")
				local arifle = meta:get_int("arifle_skill")
				local revolver = meta:get_int("revolver_skill")
				local rifle = meta:get_int("rifle_skill")
				local throw = meta:get_int("throw_skill")
				minetest.show_formspec(name, modname .. ":rw_gunskills_form",
					"size[11,7]"..
					"label[0,0;Gun efficiency: increases damage, accuracy and crit chance.]"..
					"image[0,1;1,1;handgun_img.png]"..
					"label[1,1.2;Handgun efficiency: " .. handguns .. "%]"..
					"image[0,2;1,1;machinepistol_img.png]"..
					"label[1,2.2;M.Pistol efficiency: " .. mps .. "%]"..
					"image[0,3;1,1;smg_img.png]"..
					"label[1,3.2;S.M.G efficiency: " .. smgs .. "%]"..
					"image[0,4;1,1;shotgun_img.png]"..
					"label[1,4.2;Shotgun efficiency: " .. shotguns .. "%]"..
					"image[0,5;1,1;heavy_img.png]"..
					"label[1,5.2;Heavy.MG efficiency: " .. heavy .. "%]"..
					"image[0,6;1,1;arifle_img.png]"..
					"label[1,6.2;A.rifle efficiency: " .. arifle .. "%]"..
					"image[5,1;1,1;revolver_img.png]"..
					"label[6,1.2;Revl./mgn. efficiency: " .. revolver .. "%]"..
					"image[5,2;1,1;rifle_img.png]"..
					"label[6,2.2;Rifle efficiency: " .. rifle .. "%]"..
					"image[5,3;1,1;yeetable_img.png]"..
					"label[6,3.2;Throwing efficiency: " .. throw .. "%]"..
					"button_exit[9,0;2,1;exit;Done]")
	
			end
		end
	})
end)()

misc = (function()
	rw.register_craftitem(modname .. ":rw_shell_shotgundrop", {
		wield_scale = {x=2.5,y=1.5,z=1.0},
		inventory_image = "shelldrop_shotgun.png",
	})
	
	rw.register_craftitem(modname .. ":rw_shell_whitedrop", {
		wield_scale = {x=2.5,y=1.5,z=1.0},
		inventory_image = "shelldrop_white.png",
	})
	
	rw.register_craftitem(modname .. ":rw_shell_grenadedrop", {
		wield_scale = {x=2.5,y=1.5,z=3.0},
		inventory_image = "shelldrop_grenade.png",
	})
	
	rw.register_craftitem(modname .. ":rw_shelldrop", {
		wield_scale = {x=2.5,y=1.5,z=1.0},
		inventory_image = "shelldrop.png",
	})
	
	rw.register_craftitem(modname .. ":rw_plastic_sheet", {
		description = "" ..core.colorize("#35cdff","Black plastic sheet\n")..core.colorize("#FFFFFF", "Used in guncraft"),
		inventory_image = "plastic_sheet.png",
	})
	
	rw.register_craftitem(modname .. ":rw_gunsteel_ingot", {
		description = "" ..core.colorize("#35cdff","GunSteel ingot\n")..core.colorize("#FFFFFF", "A strong, but light alloy, used in guncraft"),
		inventory_image = "gunsteel_ingot.png",
	})
	
	rw.register_craftitem(modname .. ":rw_ultra_gunsteel_ingot", {
		description = "" ..core.colorize("#35cdff","Ultra-GunSteel ingot\n")..core.colorize("#FFFFFF", "A even stronger alloy, for even stronger guns."),
		inventory_image = "ultra_gunsteel_ingot.png",
	})
	
	rw.register_craftitem(modname .. ":rw_gun_power_core", {
		description = "" ..core.colorize("#35cdff","Gun Power Core\n")..core.colorize("#FFFFFF", "A powerful core, for making the most powerful weapons"),
		inventory_image = "gun_power_core.png",
	})
	
	rw.register_craftitem(modname .. ":rw_power_particle", {
		description = "" ..core.colorize("#35cdff","Power Particle\n")..core.colorize("#FFFFFF", "A power unit, that strangelly can be carryed arround with no vessel, used by power guns"),
		stack_max = 10000,
		inventory_image = "power_particle.png",
	})
end)()

bullet_knockback = (function()
	function projectile_kb(victim,projectile,kbamount)
	
		if victim:get_pos() and projectile:get_pos() then
			rw_proj_kb_pos_x = victim:get_pos().x - projectile:get_pos().x
			rw_proj_kb_pos_y = victim:get_pos().y - projectile:get_pos().y
			rw_proj_kb_pos_z = victim:get_pos().z - projectile:get_pos().z
		else
			rw_proj_kb_pos_x = 1
			rw_proj_kb_pos_y = 1
			rw_proj_kb_pos_z = 1
		end
	
		victim:add_player_velocity({x=kbamount*(rw_proj_kb_pos_x*2),y= kbamount*(math.abs(rw_proj_kb_pos_y)/2), z=kbamount*(rw_proj_kb_pos_z*2)})
	
	end
end)()


forbidden_ents = {
	"",
}


minetest.register_alias(modname .. ":rw_726mm", modname .. ":rw_762mm")

rw.register_craftitem(modname .. ":rw_shot_bullet_visual", {
	wield_scale = {x=1.0,y=1.0,z=1.0},
	inventory_image = "bulletshot.png",
})


local rangedweapons_shot_bullet = {
	timer = 0,
	initial_properties = {
		physical = true,
		hp_max = 420,
		glow = 100,
		visual = "wielditem",
		visual_size = {x=0.75, y=0.75},
		textures = {modname .. ":rw_shot_bullet_visual"},
		_lastpos = {},
			collide_with_objects = true,
		collisionbox = {-0.0050, -0.0050, -0.0050, 0.0050, 0.0050, 0.0050},
	},
	_fire_damage_resistant = true,
	_lastpos={},
	_startpos=nil,
	_damage=1,	-- Damage on impact
	_is_critical=false, -- Whether this arrow would deal critical damage
	_stuck=false,   -- Whether arrow is stuck
	_lifetime=0,-- Amount of time (in seconds) the arrow has existed
	_stuckrechecktimer=nil,-- An additional timer for periodically re-checking the stuck status of an arrow
	_stuckin=nil,	--Position of node in which arow is stuck.
	_shooter=nil,	-- ObjectRef of player or mob who shot it
	_is_arrow = true,
	_in_player = false,
	_blocked = false,
	_viscosity=0,   -- Viscosity of node the arrow is currently in
	_deflection_cooloff=0, -- Cooloff timer after an arrow deflection, to prevent many deflections in quick succession
}

local use_particles = minetest.settings:get_bool(modname .. "_impact_particles", true)
local max_lifetime = tonumber(minetest.settings:get(modname .. "_bullet_lifetime")) or 10.0

local function generic_proj_on_step(self, dtime, moveresult, customops)
	mcl_burning.tick(self.object, dtime, self)
	-- mcl_burning.tick may remove object immediately
	if not self.object:get_pos() then return end
	
	if self.owner == nil then
		self.object:remove()
		return
	end

	local specialops = {}
	local defaultops = {
		on_hit_node = function(self, node)
			if self == nil then return end
			if self.OnCollision ~= nil then
				self.OnCollision(self.owner, self, node)
			end

			rw.sound_play("default_dig_cracky", {
				object = self.object,
				max_hear_distance = 32
			}, true)
			mcl_burning.extinguish(self.object)
			
			self.object:remove()
		end,
		on_hit_object = function(this, obj, is_player)
			if this == nil then return end
			if this.OnCollision ~= nil then
				this.OnCollision(this.owner, this, obj)
			end

			rw.sound_play("default_punch", {
				object = obj,
				max_hear_distance = 32
			}, true)
			mcl_burning.extinguish(this.object)
			this.object:remove()
		end,
	}
	
	
	for k, v in pairs(defaultops) do
		specialops[k] = function(...)
			if customops and customops[k] then
				customops[k](...)
			end
			defaultops[k](...)
		end
	end




	local pos = self.object:get_pos()
	local dpos = vector.round(vector.new(pos)) -- digital pos
	local node = minetest.get_node(dpos)

	self.timer = self.timer + dtime
	if self.timer > max_lifetime then
		mcl_burning.extinguish(self.object)
		self.object:remove()
		return
	end


	local owner = minetest.get_player_by_name(self.owner)

			
	local closest_object
	local closest_distance


	local arrow_dir = self.object:get_velocity()
	--create a raycast from the arrow based on the velocity of the arrow to deal with lag
	local raycast = minetest.raycast(pos, vector.add(pos, vector.multiply(arrow_dir, 0.1)), true, false)
	for hitpoint in raycast do
		if hitpoint.type == "object" then
			local reflua = hitpoint.ref:get_luaentity()
			-- find the closest object that is in the way of the arrow
			local ok = false
			if hitpoint.ref:is_player() and hitpoint.ref ~= owner then
				ok = true
			elseif not hitpoint.ref:is_player() and reflua then
				if (reflua.is_mob or reflua._hittable_by_projectile or reflua._vitals ~= nil) then
					ok = true
				end
			end
			if ok then
				local dist = vector.distance(hitpoint.ref:get_pos(), pos)
				if not closest_object or not closest_distance then
					closest_object = hitpoint.ref
					closest_distance = dist
				elseif dist < closest_distance then
					closest_object = hitpoint.ref
					closest_distance = dist
				end
			end
		end
	end

	if closest_object then
		local obj = closest_object
		local is_player = obj:is_player()
		local lua = obj:get_luaentity()
		if obj ~= owner and (is_player or (lua and (lua.is_mob or lua._hittable_by_projectile or lua.indicate_damage or lua._vitals))) then
			if obj:get_hp() > 0 or creatura.is_alive(obj) then
				-- Check if there is no solid node between arrow and object
				local ray = minetest.raycast(self.object:get_pos(), obj:get_pos(), true)
				for pointed_thing in ray do
					if pointed_thing.type == "object" and pointed_thing.ref == closest_object then
						-- Target reached! We can proceed now.
						break
					elseif pointed_thing.type == "node" then
						local nn = minetest.get_node(minetest.get_pointed_thing_position(pointed_thing)).name
						local def = minetest.registered_nodes[nn]
						if (not def) or def.walkable then
							-- There's a node in the way. Delete arrow without damage
							specialops.on_hit_node(self, minetest.get_node(minetest.get_pointed_thing_position(pointed_thing)))
							return
						end
					end
				end

				-- Punch target object
				damage_particles(--[[vector.add(]]pos--[[, vector.multiply(self.object:get_velocity(), 0.0))]], true)
				if mcl_burning.is_burning(self.object) then
					mcl_burning.set_on_fire(obj, 5)
				end
				mcl_util.deal_damage(obj, self.damage.fleshy or self._damage or 10, {type = "arrow", source = self._shooter, direct = self.object})
				if self._extra_hit_func then
					self._extra_hit_func(obj)
				end
				if obj.indicate_damage ~= nil then
					obj:hurt(damage)
					obj:indicate_damage()
				end	
				
				
				if is_player then
					if self._shooter and self._shooter:is_player() then
						-- “Ding” sound for hitting another player
						rw.sound_play({name="mcl_bows_hit_player", gain=0.1}, {to_player=owner:get_player_name()}, true)
					end
				end
				
				if not self._in_player and not self._blocked then
					rw.sound_play({name="default_dig_cracky", gain=0.3}, {pos=self.object:get_pos(), max_hear_distance=16}, true)
				end
				specialops.on_hit_object(self, obj, is_player)
				return
			end
			if not obj:is_player() then
				specialops.on_hit_object(self, obj, false)
			end
			return
		end
	end
	
	if self._lastpos == nil then
		self._lastpos = pos
	end

	-- Check for node collision
	if self._lastpos.x~=nil and not self._stuck then
		-- local def = minetest.registered_nodes[node.name]
		local vel = self.object:get_velocity()
		-- Arrow has stopped in one axis, so it probably hit something.
		-- This detection is a bit clunky, but sadly, MT does not offer a direct collision detection for us. :-(
		if (math.abs(vel.x) < 0.0001) or (math.abs(vel.z) < 0.0001) or (math.abs(vel.y) < 0.00001) then
			specialops.on_hit_node(self, minetest.get_node(self.object:get_pos()))
			-- return
		end
	end

	-- Update yaw
	if not self._stuck then
		local vel = self.object:get_velocity() or {x=0, y=0, z=0}
		local yaw = minetest.dir_to_yaw(vel)+YAW_OFFSET
		local pitch = dir_to_pitch(vel)
		self.object:set_rotation({ x = 0, y = yaw, z = pitch })
	end

	-- Update internal variable
	self._lastpos = pos


end



ammo = (function()	
	----------------------------------------------
	
	rangedweapons_shot_bullet.on_step = function(self, dtime, moveresult)
		generic_proj_on_step(self, dtime, moveresult)
	end
	
	----------------------------------------------------------------
	
	
	minetest.register_entity(modname .. ":rw_shot_bullet", rangedweapons_shot_bullet) 
	
	
	
	---
	--- actual mags
	---
	
	---
	--- visual drop mags
	---
	
	rw.register_craftitem(modname .. ":rw_drum_mag", {
		wield_scale = {x=1.0,y=1.0,z=1.5},
		inventory_image = "drum_mag.png",
	})
	
	rw.register_craftitem(modname .. ":rw_handgun_mag_black", {
		wield_scale = {x=0.6,y=0.6,z=0.8},
		inventory_image = "magazine_handgun.png",
	})
	local rangedweapons_mag = {
		physical = false,
		timer = 0,
		visual = "wielditem",
		visual_size = {x=0.3, y=0.3},
		textures = {modname .. ":rw_handgun_mag_black"},
		_lastpos= {},
		collisionbox = {0, 0, 0, 0, 0, 0},
	}
	rangedweapons_mag.on_step = function(self, dtime, pos)
		self.timer = self.timer + dtime
		local pos = self.object:get_pos()
		local node = minetest.get_node(pos)
		if self._lastpos.y ~= nil then
			if minetest.registered_nodes[node.name] ~= nil then
				if minetest.registered_nodes[node.name].walkable then
					local vel = self.object:get_velocity()
					local acc = self.object:get_acceleration()
					self.object:set_velocity({x=0, y=0, z=0})
					self.object:set_acceleration({x=0, y=0, z=0})
				end
			end
		end
		if self.timer > 2.0 then
			self.object:remove()
		end
		self._lastpos= {x = pos.x, y = pos.y, z = pos.z}
	end
	
	minetest.register_entity(modname .. ":rw_mag", rangedweapons_mag)
	
	rw.register_craftitem(modname .. ":rw_handgun_mag_white", {
		wield_scale = {x=0.6,y=0.6,z=0.8},
		inventory_image = "handgun_mag_white.png",
	})
	
	rw.register_craftitem(modname .. ":rw_machinepistol_mag", {
		wield_scale = {x=0.6,y=0.6,z=0.8},
		inventory_image = "machinepistol_mag.png",
	})
	
	rw.register_craftitem(modname .. ":rw_assaultrifle_mag", {
		wield_scale = {x=0.6,y=0.6,z=0.8},
		inventory_image = "assaultrifle_mag.png",
	})
	
	rw.register_craftitem(modname .. ":rw_rifle_mag", {
		wield_scale = {x=0.6,y=0.6,z=0.8},
		inventory_image = "rifle_mag.png",
	})
	
	rw.register_craftitem(modname .. ":rw_9mm", {
		stack_max= 500,
		wield_scale = {x=0.4,y=0.4,z=1.2},
			description = "" ..core.colorize("#35cdff","9x19mm Parabellum\n")..core.colorize("#FFFFFF", "Bullet damage: 1 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 0.25 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 1% \n") ..core.colorize("#FFFFFF", "Bullet velocity: 25 \n") ..core.colorize("#FFFFFF", "Bullet knockback: 1 \n")   ..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "9mm.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=1,knockback=1},
			ammo_critEffc = 0.25,
			ammo_crit = 1,
			ammo_velocity = 25,
			ammo_glass_breaking = 1,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "wielditem",
			ammo_texture = modname .. ":rw_shot_bullet_visual",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shelldrop",
			ammo_projectile_size = 0.0050,
			has_sparks = 1,
			ignites_explosives = 1,
		}
	})
	rw.register_craftitem(modname .. ":rw_45acp", {
		stack_max= 450,
		wield_scale = {x=0.4,y=0.4,z=1.2},
		description = "" ..core.colorize("#35cdff",".45ACP catridge\n")..core.colorize("#FFFFFF", "Bullet damage: 2 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 0.50 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 2% \n")
	..core.colorize("#FFFFFF", "Bullet velocity: 20 \n") 
	..core.colorize("#FFFFFF", "Bullet knockback: 2 \n") ..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "45acp.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=2,knockback=1},
			ammo_critEffc = 0.50,
			ammo_crit = 1,
			ammo_velocity = 20,
			ammo_glass_breaking = 1,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "wielditem",
			ammo_texture = modname .. ":rw_shot_bullet_visual",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shelldrop",
			ammo_projectile_size = 0.0050,
			has_sparks = 1,
			ignites_explosives = 1,
		},
	})
	rw.register_craftitem(modname .. ":rw_10mm", {
		stack_max= 400,
		wield_scale = {x=0.4,y=0.4,z=1.2},
		description = "" ..core.colorize("#35cdff","10mm Auto\n")..core.colorize("#FFFFFF", "Bullet damage: 2 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency:0.30 \n") ..core.colorize("#FFFFFF", "Bullet velocity: 25 \n") 
	..core.colorize("#FFFFFF", "Bullet knockback: 1 \n")  ..core.colorize("#FFFFFF", "Bullet crit chance: 1% \n") ..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "10mm.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=2,knockback=1},
			ammo_critEffc = 0.3,
			ammo_crit = 1,
			ammo_velocity = 25,
			ammo_glass_breaking = 1,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "wielditem",
			ammo_texture = modname .. ":rw_shot_bullet_visual",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shell_whitedrop",
			ammo_projectile_size = 0.0050,
			has_sparks = 1,
			ignites_explosives = 1,
		}
	})
	
	
	rw.register_craftitem(modname .. ":rw_357", {
		stack_max= 150,
		wield_scale = {x=0.4,y=0.4,z=1.2},
		description = "" ..core.colorize("#35cdff",".357 magnum round\n")..core.colorize("#FFFFFF", "Bullet damage: 4 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 0.6 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 3% \n") ..core.colorize("#FFFFFF", "Bullet knockback: 5 \n") ..core.colorize("#FFFFFF", "Bullet enemy Penetration: 5%\n") ..core.colorize("#FFFFFF", "Bullet velocity: 45 \n")	..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "357.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=4,knockback=5},
			ammo_critEffc = 0.6,
			ammo_crit = 3,
			ammo_velocity = 45,
			ammo_glass_breaking = 1,
			ammo_mob_penetration = 5,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "wielditem",
			ammo_texture = modname .. ":rw_shot_bullet_visual",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shelldrop",
			ammo_projectile_size = 0.0050,
			has_sparks = 1,
			ignites_explosives = 1,
		}
	})
	
	rw.register_craftitem(modname .. ":rw_50ae", {
		stack_max= 100,
		wield_scale = {x=0.6,y=0.6,z=1.5},
		description = "" ..core.colorize("#35cdff",".50AE catridge\n")..core.colorize("#FFFFFF", "Bullet damage: 8 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 0.9 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 6% \n") ..core.colorize("#FFFFFF", "Bullet knockback: 10 \n") ..core.colorize("#FFFFFF", "Bullet enemy Penetration: 15%\n") ..core.colorize("#FFFFFF", "Bullet velocity: 55 \n")	..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "50ae.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=8,knockback=10},
			ammo_critEffc = 0.9,
			ammo_crit = 6,
			ammo_velocity = 55,
			ammo_glass_breaking = 1,
			ammo_mob_penetration = 15,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "wielditem",
			ammo_texture = modname .. ":rw_shot_bullet_visual",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shelldrop",
			ammo_projectile_size = 0.0050,
			has_sparks = 1,
			ignites_explosives = 1,
		}
	})
	
	rw.register_craftitem(modname .. ":rw_44", {
		stack_max= 150,
		wield_scale = {x=0.4,y=0.4,z=1.2},
		description = "" ..core.colorize("#35cdff",".44 magnum round\n")..core.colorize("#FFFFFF", "Bullet damage: 4 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 0.7 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 4% \n") ..core.colorize("#FFFFFF", "Bullet knockback: 6 \n") ..core.colorize("#FFFFFF", "Bullet enemy Penetration: 6%\n") ..core.colorize("#FFFFFF", "Bullet velocity: 50 \n")  ..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "44.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=4,knockback=6},
			ammo_critEffc = 0.7,
			ammo_crit = 4,
			ammo_velocity = 50,
			ammo_glass_breaking = 1,
			ammo_mob_penetration = 6,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "wielditem",
			ammo_texture = modname .. ":rw_shot_bullet_visual",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shelldrop",
			ammo_projectile_size = 0.0050,
			has_sparks = 1,
			ignites_explosives = 1,
		}
	})
	rw.register_craftitem(modname .. ":rw_762mm", {
		stack_max= 250,
		wield_scale = {x=0.4,y=0.4,z=1.2},
		description = "" ..core.colorize("#35cdff","7.62mm round\n")..core.colorize("#FFFFFF", "Bullet damage: 4 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 0.5 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 2% \n") ..core.colorize("#FFFFFF", "Bullet velocity: 40 \n") ..core.colorize("#FFFFFF", "Bullet knockback: 4 \n") ..core.colorize("#FFFFFF", "Bullet enemy Penetration: 5%\n")   ..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "762mm.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=4,knockback=4},
			ammo_critEffc = 0.5,
			ammo_crit = 2,
			ammo_velocity = 40,
			ammo_glass_breaking = 1,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "wielditem",
			ammo_texture = modname .. ":rw_shot_bullet_visual",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shelldrop",
			ammo_mob_penetration = 5,
			ammo_projectile_size = 0.0050,
			has_sparks = 1,
			ignites_explosives = 1,
		},
	})
	rw.register_craftitem(modname .. ":rw_556mm", {
		stack_max= 300,
		wield_scale = {x=0.4,y=0.4,z=1.2},
		description = "" ..core.colorize("#35cdff","5.56mm round\n")..core.colorize("#FFFFFF", "Bullet damage: 3 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 0.4 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 2% \n") ..core.colorize("#FFFFFF", "Bullet velocity: 35 \n") ..core.colorize("#FFFFFF", "Bullet knockback: 3 \n")	..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "556mm.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=3,knockback=3},
			ammo_critEffc = 0.4,
			ammo_crit = 2,
			ammo_velocity = 35,
			ammo_glass_breaking = 1,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "wielditem",
			ammo_texture = modname .. ":rw_shot_bullet_visual",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shelldrop",
			ammo_projectile_size = 0.0050,
			has_sparks = 1,
			ignites_explosives = 1,
		},
	})
	rw.register_craftitem(modname .. ":rw_shell", {
		stack_max= 50,
		wield_scale = {x=0.4,y=0.4,z=1.2},
		description = "" ..core.colorize("#35cdff","12 Gauge shell\n")..core.colorize("#FFFFFF", "Bullet damage: 2 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 0.15 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 1% \n") ..core.colorize("#FFFFFF", "Bullet velocity: 20 \n") ..core.colorize("#FFFFFF", "Bullet knockback: 4 \n") ..core.colorize("#FFFFFF", "Bullet gravity: 5 \n")  ..core.colorize("#FFFFFF", "Bullet projectile multiplier: 1.5x\n")   ..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "shell.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=2,knockback=4},
			ammo_projectile_multiplier = 1.5,
			ammo_critEffc = 0.15,
			ammo_crit = 1,
			ammo_velocity = 20,
			ammo_glass_breaking = 1,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "sprite",
			ammo_texture = "buckball.png",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shell_shotgundrop",
			ammo_gravity = 5,
			ammo_projectile_size = 0.00175,
			ammo_projectile_glow = 0,
			has_sparks = 1,
			ignites_explosives = 1,
		},
	})
	rw.register_craftitem(modname .. ":rw_308winchester", {
		stack_max= 75,
		wield_scale = {x=0.4,y=0.4,z=1.2},
		description = "" ..core.colorize("#35cdff",".308 winchester round\n")..core.colorize("#FFFFFF", "Bullet damage: 8 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 0.75 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 4% \n") ..core.colorize("#FFFFFF", "Bullet velocity: 60 \n") ..core.colorize("#FFFFFF", "Bullet knockback: 10 \n") ..core.colorize("#FFFFFF", "Damage gain over 1 sec of flight time: 40 \n") ..core.colorize("#FFFFFF", "Bullet enemy Penetration: 20%\n") ..core.colorize("#FFFFFF", "Bullet node Penetration: 10%\n")	  ..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "308winchester.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=8,knockback=10},
			ammo_critEffc = 0.75,
			ammo_crit = 2,
			ammo_velocity = 60,
			ammo_glass_breaking = 1,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "wielditem",
			ammo_texture = modname .. ":rw_shot_bullet_visual",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shelldrop",
			ammo_mob_penetration = 20,
			ammo_node_penetration = 10,
			ammo_projectile_size = 0.0050,
			ammo_dps = 40,
			has_sparks = 1,
			ignites_explosives = 1,
		},
	})
	
	rw.register_craftitem(modname .. ":rw_408cheytac", {
		stack_max= 40,
		wield_scale = {x=0.65,y=0.65,z=1.5},
		description = "" ..core.colorize("#35cdff",".408 chey tac\n")..core.colorize("#FFFFFF", "Bullet damage: 10 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 0.8 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 5% \n") ..core.colorize("#FFFFFF", "Bullet velocity: 70 \n") ..core.colorize("#FFFFFF", "Bullet knockback: 15 \n") ..core.colorize("#FFFFFF", "Damage gain over 1 sec of flight time: 80 \n") ..core.colorize("#FFFFFF", "Bullet enemy Penetration: 45%\n") ..core.colorize("#FFFFFF", "Bullet node Penetration: 20%\n")	  ..core.colorize("#FFFFFF", "Ammunition for some guns"),
		inventory_image = "408cheytac.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=10,knockback=15},
			ammo_critEffc = 0.8,
			ammo_crit = 5,
			ammo_velocity = 70,
			ammo_glass_breaking = 1,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "wielditem",
			ammo_texture = modname .. ":rw_shot_bullet_visual",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shelldrop",
			ammo_mob_penetration = 45,
			ammo_node_penetration = 20,
			ammo_projectile_size = 0.0050,
			ammo_dps = 80,
			has_sparks = 1,
			ignites_explosives = 1,
		},
	})
	
	rw.register_craftitem(modname .. ":rw_40mm", {
		stack_max= 25,
		wield_scale = {x=0.8,y=0.8,z=2.4},
		description = "" ..core.colorize("#35cdff",".40mm grenade\n")..core.colorize("#FFFFFF", "Bullet damage: 10 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 1.0 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 1% \n") ..core.colorize("#FFFFFF", "Bullet velocity: 15 \n") ..core.colorize("#FFFFFF", "Bullet knockback: 10 \n") ..core.colorize("#FFFFFF", "Bullet gravity: 5 \n")  ..core.colorize("#FFFFFF", "explodes on impact with a radius of 2\n")  ..core.colorize("#FFFFFF", "Ammunition for grenade launchers"),
		inventory_image = "40mm.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=10,knockback=15},
			ammo_critEffc = 1.0,
			ammo_crit = 1,
			ammo_velocity = 15,
			ammo_glass_breaking = 1,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "sprite",
			ammo_texture = "rocket_fly.png",
			shell_entity = modname .. ":rw_empty_shell",
			shell_visual = "wielditem",
			shell_texture = modname .. ":rw_shell_grenadedrop",
			ammo_projectile_size = 0.15,
			has_sparks = 1,
			ammo_gravity = 5,
			ignites_explosives = 1,
			
			OnCollision = function(player,bullet,target)
				mcl_explosions.explode(bullet.object:get_pos(), 2, {drop_chance = 1.0}, nil)
			end,
			ammo_particles = {
				velocity = {x=1,y=1,z=1},
				acceleration = {x=1,y=1,z=1},
				collisiondetection = true,
				lifetime = 1,
				texture = "tnt_smoke.png",
				minsize = 50,
				maxsize = 75,
				pos_randomness = 50,
				glow = 20,
				gravity = 10,
				amount = {1,1}
			},
		},
	})
	
	rw.register_craftitem(modname .. ":rw_rocket", {
		stack_max= 15,
		wield_scale = {x=1.2,y=1.2,z=2.4},
		description = "" ..core.colorize("#35cdff","rocket\n")..core.colorize("#FFFFFF", "Bullet damage: 15 \n") ..core.colorize("#FFFFFF", "Bullet crit efficiency: 1.0 \n") ..core.colorize("#FFFFFF", "Bullet crit chance: 1% \n") ..core.colorize("#FFFFFF", "Bullet velocity: 20 \n") ..core.colorize("#FFFFFF", "Bullet knockback: 20 \n") ..core.colorize("#FFFFFF", "Bullet gravity: 5 \n")  ..core.colorize("#FFFFFF", "explodes on impact with a radius of 3\n")  ..core.colorize("#FFFFFF", "Ammunition for rocket launchers"),
		inventory_image = "rocket.png",
		RW_ammo_capabilities = {
			ammo_damage = {fleshy=15,knockback=20},
			ammo_critEffc = 1.0,
			ammo_crit = 1,
			ammo_velocity = 20,
			ammo_glass_breaking = 1,
			ammo_entity = modname .. ":rw_shot_bullet",
			ammo_visual = "sprite",
			ammo_texture = "rocket_fly.png",
			ammo_projectile_size = 0.15,
			has_sparks = 1,
			ignites_explosives = 1,
	
			OnCollision = function(player,bullet,target)
				mcl_explosions.explode(bullet.object:get_pos(), 3, {drop_chance = 1.0}, nil)
			end,
			ammo_particles = {
				velocity = {x=1,y=1,z=1},
				acceleration = {x=1,y=1,z=1},
				collisiondetection = true,
				lifetime = 1,
				texture = "tnt_smoke.png",
				minsize = 50,
				maxsize = 75,
				pos_randomness = 50,
				glow = 20,
				gravity = 10,
				amount = {1,1}
			},
		},
	})
end)()

crafting = (function()

end)()

--if minetest.settings:get_bool(modname .. "_shurikens", true) then
shurikens = (function()
	rw.register_craftitem(modname .. ":rw_wooden_shuriken", {
		description = "" ..core.colorize("#35cdff","Wooden shuriken\n") ..core.colorize("#FFFFFF", "Ranged damage: 2\n") ..core.colorize("#FFFFFF", "Accuracy: 80%\n") ..core.colorize("#FFFFFF", "knockback: 5\n") ..core.colorize("#FFFFFF", "Critical chance: 6%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2x\n") ..core.colorize("#FFFFFF", "Shuriken survival rate: 10%\n") ..core.colorize("#FFFFFF", "Projectile gravity: 10\n") ..core.colorize("#FFFFFF", "Throwing cooldown: 0.35\n") ..core.colorize("#FFFFFF", "Projectile velocity: 25"),
		range = 0,
		stack_max= 100,
		wield_scale = {x=0.6,y=0.6,z=0.5},
		inventory_image = "wooden_shuriken.png",
		RW_throw_capabilities = {
			throw_damage = {fleshy=2,knockback=5},
			throw_crit = 6,
			throw_critEffc = 2.0,
			throw_skill = {"throw_skill",35},
			throw_velocity = 25,
			throw_accuracy = 80,
			throw_cooldown = 0.35,
			throw_projectiles = 1,
			throw_gravity = 10,
			throw_sound = "throw",
			throw_dps = 0,
			throw_mob_penetration = 0,
			throw_node_penetration = 0,
			throw_entity = modname .. ":rw_shot_bullet",
			throw_visual = "wielditem",
			throw_texture = modname .. ":rw_wooden_shuriken",
			throw_projectile_size = 0.15,
			throw_glass_breaking = 0,
			has_sparks = 0,
			ignites_explosives = 0,
			throw_door_breaking = 0,
			OnCollision = function(player,bullet,target)
				if math.random(1, 100) <= 10 then
					minetest.add_item(bullet.object:get_pos(), modname .. ":rw_wooden_shuriken") end end,
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_yeet(itemstack, user)
			return itemstack
		end,
	})
	
	
	rw.register_craftitem(modname .. ":rw_stone_shuriken", {
		description = "" ..core.colorize("#35cdff","Stone shuriken\n") ..core.colorize("#FFFFFF", "Ranged damage: 4\n") ..core.colorize("#FFFFFF", "Accuracy: 75%\n") ..core.colorize("#FFFFFF", "knockback: 8\n") ..core.colorize("#FFFFFF", "Critical chance: 7%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.1x\n") ..core.colorize("#FFFFFF", "Shuriken survival rate: 15%\n") ..core.colorize("#FFFFFF", "Projectile gravity: 15\n") ..core.colorize("#FFFFFF", "Throwing cooldown: 0.35\n") ..core.colorize("#FFFFFF", "Projectile velocity: 20"),
		range = 0,
		stack_max= 125,
		wield_scale = {x=0.6,y=0.6,z=0.5},
		inventory_image = "stone_shuriken.png",
		RW_throw_capabilities = {
			throw_damage = {fleshy=4,knockback=8},
			throw_crit = 7,
			throw_critEffc = 2.1,
			throw_skill = {"throw_skill",30},
			throw_velocity = 20,
			throw_accuracy = 75,
			throw_cooldown = 0.5,
			throw_projectiles = 1,
			throw_gravity = 15,
			throw_sound = "throw",
			throw_dps = 0,
			throw_mob_penetration = 0,
			throw_node_penetration = 0,
			throw_entity = modname .. ":rw_shot_bullet",
			throw_visual = "wielditem",
			throw_texture = modname .. ":rw_stone_shuriken",
			throw_projectile_size = 0.15,
			throw_glass_breaking = 1,
			has_sparks = 0,
			ignites_explosives = 0,
			throw_door_breaking = 0,
			OnCollision = function(player,bullet,target)
				if math.random(1, 100) <= 15 then
					minetest.add_item(bullet.object:get_pos(), modname .. ":rw_stone_shuriken") end end,
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_yeet(itemstack, user)
			return itemstack
		end,
	})
	
	
	rw.register_craftitem(modname .. ":rw_steel_shuriken", {
		description = "" ..core.colorize("#35cdff","Steel shuriken\n") ..core.colorize("#FFFFFF", "Ranged damage: 6\n") ..core.colorize("#FFFFFF", "Accuracy: 85%\n") ..core.colorize("#FFFFFF", "knockback: 3\n") ..core.colorize("#FFFFFF", "Critical chance: 8%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.2x\n") ..core.colorize("#FFFFFF", "Shuriken survival rate: 35%\n") ..core.colorize("#FFFFFF", "Projectile gravity: 8\n") ..core.colorize("#FFFFFF", "Throwing cooldown: 0.25\n") ..core.colorize("#FFFFFF", "Projectile velocity: 30"),
		range = 0,
		stack_max= 150,
		wield_scale = {x=0.6,y=0.6,z=0.5},
		inventory_image = "steel_shuriken.png",
		RW_throw_capabilities = {
			throw_damage = {fleshy=6,knockback=3},
			throw_crit = 8,
			throw_critEffc = 2.2,
			throw_skill = {"throw_skill",40},
			throw_velocity = 30,
			throw_accuracy = 85,
			throw_cooldown = 0.25,
			throw_projectiles = 1,
			throw_gravity = 8,
			throw_sound = "throw",
			throw_dps = 0,
			throw_mob_penetration = 0,
			throw_node_penetration = 0,
			throw_entity = modname .. ":rw_shot_bullet",
			throw_visual = "wielditem",
			throw_texture = modname .. ":rw_steel_shuriken",
			throw_projectile_size = 0.15,
			throw_glass_breaking = 0,
			has_sparks = 1,
			ignites_explosives = 0,
			throw_door_breaking = 0,
			OnCollision = function(player,bullet,target)
				if math.random(1, 100) <= 35 then
					minetest.add_item(bullet.object:get_pos(), modname .. ":rw_steel_shuriken") end end,
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_yeet(itemstack, user)
			return itemstack
		end,
	})
	
	rw.register_craftitem(modname .. ":rw_bronze_shuriken", {
		description = "" ..core.colorize("#35cdff","Bronze shuriken\n") ..core.colorize("#FFFFFF", "Ranged damage: 6\n") ..core.colorize("#FFFFFF", "Accuracy: 85%\n") ..core.colorize("#FFFFFF", "knockback: 3\n") ..core.colorize("#FFFFFF", "Critical chance: 8%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.2x\n") ..core.colorize("#FFFFFF", "Shuriken survival rate: 30%\n") ..core.colorize("#FFFFFF", "Projectile gravity: 8\n") ..core.colorize("#FFFFFF", "Throwing cooldown: 0.25\n") ..core.colorize("#FFFFFF", "Projectile velocity: 30"),
		range = 0,
		stack_max= 150,
		wield_scale = {x=0.6,y=0.6,z=0.5},
		inventory_image = "bronze_shuriken.png",
		RW_throw_capabilities = {
			throw_damage = {fleshy=6,knockback=3},
			throw_crit = 8,
			throw_critEffc = 2.2,
			throw_skill = {"throw_skill",40},
			throw_velocity = 30,
			throw_accuracy = 85,
			throw_cooldown = 0.25,
			throw_projectiles = 1,
			throw_gravity = 8,
			throw_sound = "throw",
			throw_dps = 0,
			throw_mob_penetration = 0,
			throw_node_penetration = 0,
			throw_entity = modname .. ":rw_shot_bullet",
			throw_visual = "wielditem",
			throw_texture = modname .. ":rw_bronze_shuriken",
			throw_projectile_size = 0.15,
			throw_glass_breaking = 0,
			has_sparks = 1,
			ignites_explosives = 0,
			throw_door_breaking = 0,
			OnCollision = function(player,bullet,target)
				if math.random(1, 100) <= 30 then
					minetest.add_item(bullet.object:get_pos(), modname .. ":rw_bronze_shuriken") end end,
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_yeet(itemstack, user)
			return itemstack
		end,
	})
	
	rw.register_craftitem(modname .. ":rw_golden_shuriken", {
		description = "" ..core.colorize("#35cdff","Golden shuriken\n") ..core.colorize("#FFFFFF", "Ranged damage: 8\n") ..core.colorize("#FFFFFF", "Accuracy: 75%\n") ..core.colorize("#FFFFFF", "knockback: 10\n") ..core.colorize("#FFFFFF", "Critical chance: 12%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.5x\n") ..core.colorize("#FFFFFF", "Shuriken survival rate: 25%\n") ..core.colorize("#FFFFFF", "Projectile gravity: 15\n") ..core.colorize("#FFFFFF", "Throwing cooldown: 0.4\n") ..core.colorize("#FFFFFF", "Projectile velocity: 25"),
		range = 0,
		stack_max= 175,
		wield_scale = {x=0.6,y=0.6,z=0.5},
		inventory_image = "golden_shuriken.png",
		RW_throw_capabilities = {
			throw_damage = {fleshy=8,knockback=10},
			throw_crit = 12,
			throw_critEffc = 2.5,
			throw_skill = {"throw_skill",35},
			throw_velocity = 25,
			throw_accuracy = 75,
			throw_cooldown = 0.4,
			throw_projectiles = 1,
			throw_gravity = 15,
			throw_sound = "throw",
			throw_dps = 0,
			throw_mob_penetration = 0,
			throw_node_penetration = 0,
			throw_entity = modname .. ":rw_shot_bullet",
			throw_visual = "wielditem",
			throw_texture = modname .. ":rw_golden_shuriken",
			throw_projectile_size = 0.15,
			throw_glass_breaking = 1,
			has_sparks = 1,
			ignites_explosives = 0,
			throw_door_breaking = 0,
			OnCollision = function(player,bullet,target)
				if math.random(1, 100) <= 25 then
					minetest.add_item(bullet.object:get_pos(), modname .. ":rw_golden_shuriken") end end,
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_yeet(itemstack, user)
			return itemstack
		end,
	})
	
	rw.register_craftitem(modname .. ":rw_mese_shuriken", {
		description = "" ..core.colorize("#35cdff","MESE shuriken\n") ..core.colorize("#FFFFFF", "Ranged damage: 7\n") ..core.colorize("#FFFFFF", "Accuracy: 90%\n") ..core.colorize("#FFFFFF", "knockback: 2\n") ..core.colorize("#FFFFFF", "Critical chance: 9%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.3x\n") ..core.colorize("#FFFFFF", "Shuriken survival rate: 50%\n") ..core.colorize("#FFFFFF", "Projectile gravity: 5\n") ..core.colorize("#FFFFFF", "Throwing cooldown: 0.2\n") ..core.colorize("#FFFFFF", "Enemy penetration: 25%\n")  ..core.colorize("#FFFFFF", "Projectile velocity: 35"),
		range = 0,
		stack_max= 175,
		wield_scale = {x=0.6,y=0.6,z=0.5},
		inventory_image = "mese_shuriken.png",
		RW_throw_capabilities = {
			throw_damage = {fleshy=7,knockback=2},
			throw_crit = 9,
			throw_critEffc = 2.3,
			throw_skill = {"throw_skill",45},
			throw_velocity = 35,
			throw_accuracy = 90,
			throw_cooldown = 0.2,
			throw_projectiles = 1,
			throw_gravity = 5,
			throw_sound = "throw",
			throw_dps = 0,
			throw_mob_penetration = 25,
			throw_node_penetration = 0,
			throw_entity = modname .. ":rw_shot_bullet",
			throw_visual = "wielditem",
			throw_texture = modname .. ":rw_mese_shuriken",
			throw_projectile_size = 0.15,
			throw_glass_breaking = 1,
			has_sparks = 1,
			ignites_explosives = 0,
			throw_door_breaking = 0,
			OnCollision = function(player,bullet,target)
				if math.random(1, 100) <= 50 then
					minetest.add_item(bullet.object:get_pos(), modname .. ":rw_mese_shuriken") end end,
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_yeet(itemstack, user)
			return itemstack
		end,
	})
	
	rw.register_craftitem(modname .. ":rw_diamond_shuriken", {
		description = "" ..core.colorize("#35cdff","Diamond shuriken\n") ..core.colorize("#FFFFFF", "Ranged damage: 8\n") ..core.colorize("#FFFFFF", "Accuracy: 95%\n") ..core.colorize("#FFFFFF", "knockback: 2\n") ..core.colorize("#FFFFFF", "Critical chance: 10%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.4x\n") ..core.colorize("#FFFFFF", "Shuriken survival rate: 60%\n") ..core.colorize("#FFFFFF", "Projectile gravity: 5\n") ..core.colorize("#FFFFFF", "Throwing cooldown: 0.15\n") ..core.colorize("#FFFFFF", "Enemy penetration: 33%\n")  ..core.colorize("#FFFFFF", "Projectile velocity: 40"),
		range = 0,
		stack_max= 200,
		wield_scale = {x=0.6,y=0.6,z=0.5},
		inventory_image = "diamond_shuriken.png",
		RW_throw_capabilities = {
			throw_damage = {fleshy=8,knockback=2},
			throw_crit = 10,
			throw_critEffc = 2.4,
			throw_skill = {"throw_skill",50},
			throw_velocity = 40,
			throw_accuracy = 95,
			throw_cooldown = 0.15,
			throw_projectiles = 1,
			throw_gravity = 5,
			throw_sound = "throw",
			throw_dps = 0,
			throw_mob_penetration = 33,
			throw_node_penetration = 0,
			throw_entity = modname .. ":rw_shot_bullet",
			throw_visual = "wielditem",
			throw_texture = modname .. ":rw_diamond_shuriken",
			throw_projectile_size = 0.15,
			throw_glass_breaking = 1,
			has_sparks = 1,
			ignites_explosives = 0,
			throw_door_breaking = 0,
			OnCollision = function(player,bullet,target)
				if math.random(1, 100) <= 60 then
					minetest.add_item(bullet.object:get_pos(), modname .. ":rw_diamond_shuriken") end end,
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_yeet(itemstack, user)
			return itemstack
		end,
	})
end)()

--end

--if minetest.settings:get_bool(modname .. "_handguns", true) then
makarov = (function()
	rw.register_tool(modname .. ":rw_makarov_rld", {
		stack_max= 1,
		wield_scale = {x=0.9,y=0.9,z=1.0},
		description = "",
		range = 0,
		loaded_gun = modname .. ":rw_makarov",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "makarov_rld.png",
	})
	rw.register_tool(modname .. ":rw_makarov_r", {
		stack_max= 1,
		wield_scale = {x=0.9,y=0.9,z=1.0},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_makarov_rr",
		load_sound = "handgun_mag_in",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "makarov.png",
	})
	
	rw.register_tool(modname .. ":rw_makarov_rr", {
		stack_max= 1,
		wield_scale = {x=0.9,y=0.9,z=1.0},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_makarov_rrr",
		load_sound = "reload_a",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "makarov.png",
	})
	
	rw.register_tool(modname .. ":rw_makarov_rrr", {
		stack_max= 1,
		wield_scale = {x=0.9,y=0.9,z=1.0},
		description = "",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		rw_next_reload = modname .. ":rw_makarov",
		load_sound = "reload_b",
		inventory_image = "makarov_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_makarov", {
		description = "" ..core.colorize("#35cdff","Makarov pistol\n") ..core.colorize("#FFFFFF", "Gun damage: 3\n")..core.colorize("#FFFFFF", "Accuracy: 90%\n")  ..core.colorize("#FFFFFF", "gun knockback: 3\n") ..core.colorize("#FFFFFF", "Gun crit chance: 10%\n")..core.colorize("#FFFFFF", "Critical efficiency: 2x\n") ..core.colorize("#FFFFFF", "Reload delay: 1.1\n")..core.colorize("#FFFFFF", "Clip size: 8\n") ..core.colorize("#FFFFFF", "Ammunition: 9x19mm Parabellum\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.5\n") ..core.colorize("#FFFFFF", "Gun type: Handgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 20"),
		range = 0,
		wield_scale = {x=0.9,y=0.9,z=1.0},
		inventory_image = "makarov.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=3,knockback=3},
			gun_crit = 10,
			gun_critEffc = 2.0,
			suitable_ammo = {{modname .. ":rw_9mm",8}},
			gun_skill = {"handgun_skill",40},
			gun_magazine = modname .. ":rw_handgun_mag_black",
			gun_unloaded = modname .. ":rw_makarov_r",
			gun_cooling = modname .. ":rw_makarov_rld",
			gun_velocity = 20,
			gun_accuracy = 90,
			gun_cooldown = 0.5,
			gun_reload = 1.1/4,
			gun_projectiles = 1,
			gun_smokeSize = 5,
			has_shell = 1,
			gun_durability = 450,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "glock",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

--[[luger = (function()
	------------reload--------------------
	rw.register_tool(modname .. ":rw_luger_r", {
		stack_max= 1,
		wield_scale = {x=0.9,y=0.9,z=1.0},
		description = "",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		rw_next_reload = modname .. ":rw_luger_rr",
		load_sound = "handgun_mag_in",
		inventory_image = "luger.png",
	})
	rw.register_tool(modname .. ":rw_luger_rr", {
		stack_max= 1,
		wield_scale = {x=0.9,y=0.9,z=1.0},
		description = "",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		rw_next_reload = modname .. ":rw_luger_rrr",
		load_sound = "reload_a",
		inventory_image = "luger.png",
	})
	rw.register_tool(modname .. ":rw_luger_rrr", {
		stack_max= 1,
		wield_scale = {x=0.9,y=0.9,z=1.0},
		description = "",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		rw_next_reload = modname .. ":rw_luger",
		load_sound = "reload_b",
		inventory_image = "luger_rld.png",
	})
	rw.register_tool(modname .. ":rw_luger_rld", {
		stack_max= 1,
		wield_scale = {x=0.9,y=0.9,z=1.0},
		description = "",
		range = 0,
		loaded_gun = modname .. ":rw_luger",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "luger_rld.png",
	})
	-----------------gun--------------
	
	rw.register_tool(modname .. ":rw_luger", {
		description = "" ..core.colorize("#35cdff","Luger P08\n") ..core.colorize("#FFFFFF", "Ranged damage: 4\n")..core.colorize("#FFFFFF", "Accuracy: 92%\n")  ..core.colorize("#FFFFFF", "Gun knockback: 3\n") ..core.colorize("#FFFFFF", "Critical chance: 10%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2x\n") ..core.colorize("#FFFFFF", "Ammunition: 9x19mm parabellum\n")..core.colorize("#FFFFFF", "Reload delay: 1.0\n")..core.colorize("#FFFFFF", "Clip size: 8\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.625\n") ..core.colorize("#FFFFFF", "Gun type: Handgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 20"),
		range = 0,
		wield_scale = {x=0.9,y=0.9,z=1.0},
		inventory_image = "luger.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=4,knockback=3},
			gun_crit = 10,
			gun_critEffc = 2.0,
			suitable_ammo = {{modname .. ":rw_9mm",8}},
			gun_skill = {"handgun_skill",40},
			gun_magazine = modname .. ":rw_handgun_mag_black",
			gun_unloaded = modname .. ":rw_luger_r",
			gun_cooling = modname .. ":rw_luger_rld",
			gun_velocity = 20,
			gun_accuracy = 92,
			gun_cooldown = 0.625,
			gun_reload = 1.0/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_durability = 600,
			gun_smokeSize = 5,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "glock",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

beretta = (function()
	rw.register_tool(modname .. ":rw_beretta_rld", {
		stack_max= 1,
		wield_scale = {x=1.1,y=1.1,z=1.05},
		description = "",
		range = 0,
		loaded_gun = modname .. ":rw_beretta",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "beretta_rld.png",
	})
	rw.register_tool(modname .. ":rw_beretta_r", {
		stack_max= 1,
		wield_scale = {x=1.1,y=1.1,z=1.05},
		description = "",
		rw_next_reload = modname .. ":rw_beretta",
		load_sound = "handgun_mag_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "beretta_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_beretta", {
		description = "" ..core.colorize("#35cdff","Beretta M9\n") ..core.colorize("#FFFFFF", "Gun damage: 4\n")..core.colorize("#FFFFFF", "Accuracy: 94%\n")  ..core.colorize("#FFFFFF", "gun knockback: 4\n") ..core.colorize("#FFFFFF", "Gun crit chance: 13%\n")..core.colorize("#FFFFFF", "Critical efficiency: 2.1x\n") ..core.colorize("#FFFFFF", "Reload delay: 0.5\n")..core.colorize("#FFFFFF", "Clip size: 15\n") ..core.colorize("#FFFFFF", "Ammunition: 9x19mm Parabellum\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.4\n") ..core.colorize("#FFFFFF", "Gun type: Handgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 25"),
		wield_scale = {x=1.1,y=1.1,z=1.05},
		range = 0,
		inventory_image = "beretta.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=4,knockback=4},
			gun_crit = 15,
			gun_critEffc = 2.1,
			suitable_ammo = {{modname .. ":rw_9mm",15}},
			gun_skill = {"handgun_skill",43},
			gun_magazine = modname .. ":rw_handgun_mag_black",
			gun_unloaded = modname .. ":rw_beretta_r",
			gun_cooling = modname .. ":rw_beretta_rld",
			gun_velocity = 25,
			gun_accuracy = 94,
			gun_cooldown = 0.4,
			gun_reload = 0.5,
			gun_projectiles = 1,
			has_shell = 1,
			gun_durability = 1150,
			gun_smokeSize = 5,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "beretta",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

m1991 = (function()
	rw.register_tool(modname .. ":rw_m1991_rld", {
		stack_max= 1,
		wield_scale = {x=1.1,y=1.1,z=1.05},
		description = "",
		range = 0,
		loaded_gun = modname .. ":rw_m1991",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m1991_rld.png",
	})
	rw.register_tool(modname .. ":rw_m1991_r", {
		stack_max= 1,
		wield_scale = {x=1.1,y=1.1,z=1.05},
		description = "",
		rw_next_reload = modname .. ":rw_m1991_rr",
		load_sound = "handgun_mag_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m1991.png",
	})
	rw.register_tool(modname .. ":rw_m1991_rr", {
		stack_max= 1,
		wield_scale = {x=1.1,y=1.1,z=1.05},
		description = "",
		rw_next_reload = modname .. ":rw_m1991_rrr",
		load_sound = "reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m1991.png",
	})
	rw.register_tool(modname .. ":rw_m1991_rrr", {
		stack_max= 1,
		wield_scale = {x=1.1,y=1.1,z=1.05},
		description = "",
		rw_next_reload = modname .. ":rw_m1991",
		load_sound = "reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m1991_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_m1991", {
		description = "" ..core.colorize("#35cdff","m1991\n") ..core.colorize("#FFFFFF", "Gun damage: 4\n")..core.colorize("#FFFFFF", "Accuracy: 92%\n")  ..core.colorize("#FFFFFF", "gun knockback: 4\n") ..core.colorize("#FFFFFF", "Gun crit chance: 13%\n")..core.colorize("#FFFFFF", "Critical efficiency: 2.1x\n") ..core.colorize("#FFFFFF", "Reload delay: 1.0\n")..core.colorize("#FFFFFF", "Clip size: 8\n") ..core.colorize("#FFFFFF", "Ammunition: .45acp\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.4\n") ..core.colorize("#FFFFFF", "Gun type: Handgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 25"),
		wield_scale = {x=1.1,y=1.1,z=1.05},
		range = 0,
		inventory_image = "m1991.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=4,knockback=4},
			gun_crit = 15,
			gun_critEffc = 2.1,
			suitable_ammo = {{modname .. ":rw_45acp",8}},
			gun_skill = {"handgun_skill",40},
			gun_magazine = modname .. ":rw_handgun_mag_black",
			gun_unloaded = modname .. ":rw_m1991_r",
			gun_cooling = modname .. ":rw_m1991_rld",
			gun_velocity = 25,
			gun_accuracy = 92,
			gun_cooldown = 0.4,
			gun_reload = 1.0/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_durability = 1000,
			gun_smokeSize = 5,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "beretta",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
end)()]]

glock17 = (function()
	rw.register_tool(modname .. ":rw_glock17_rld", {
		stack_max= 1,
		wield_scale = {x=1.1,y=1.1,z=1.05},
		description = "",
		loaded_gun = modname .. ":rw_glock17",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "glock17_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_glock17_r", {
		stack_max= 1,
		wield_scale = {x=1.2,y=1.2,z=1.2},
		description = "",
		rw_next_reload = modname .. ":rw_glock17_rr",
		load_sound = "handgun_mag_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "glock17.png",
	})
	
	rw.register_tool(modname .. ":rw_glock17_rr", {
		stack_max= 1,
		wield_scale = {x=1.2,y=1.2,z=1.2},
		description = "",
		rw_next_reload = modname .. ":rw_glock17_rrr",
		load_sound = "reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "glock17.png",
	})
	
	rw.register_tool(modname .. ":rw_glock17_rrr", {
		stack_max= 1,
		wield_scale = {x=1.2,y=1.2,z=1.2},
		description = "",
		rw_next_reload = modname .. ":rw_glock17",
		load_sound = "reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "glock17_rld.png",
	})
	
	
	
	
	rw.register_tool(modname .. ":rw_glock17", {
			description = "" ..core.colorize("#35cdff","Glock 17\n") ..core.colorize("#FFFFFF", "Gun damage: 5\n") ..core.colorize("#FFFFFF", "Accuracy: 96%\n") ..core.colorize("#FFFFFF", "Gun knockback: 4\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 15%\n") ..core.colorize("#FFFFFF", "Gun Critical efficiency: 2.2x\n") ..core.colorize("#FFFFFF", "Reload delay: 0.9\n")..core.colorize("#FFFFFF", "Clip size: 17/17/17\n") ..core.colorize("#FFFFFF", "Ammunition: 9x19mm Parabellum/10mm Auto/.45acp\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.35\n") ..core.colorize("#FFFFFF", "Gun type: Handgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 30"),
		wield_scale = {x=1.2,y=1.2,z=1.2},
		range = 0,
		inventory_image = "glock17.png",
	RW_gun_capabilities = {
			gun_damage = {fleshy=5,knockback=4},
			gun_crit = 15,
			gun_critEffc = 2.2,
			suitable_ammo = {{modname .. ":rw_9mm",17},{modname .. ":rw_10mm",17},{modname .. ":rw_45acp",17}},
			gun_skill = {"handgun_skill",45},
			gun_magazine = modname .. ":rw_handgun_mag_black",
			gun_unloaded = modname .. ":rw_glock17_r",
			gun_cooling = modname .. ":rw_glock17_rld",
			gun_velocity = 30,
			gun_accuracy = 96,
			gun_cooldown = 0.35,
			gun_reload = 0.9/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_durability = 1400,
			gun_smokeSize = 5,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "glock",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
	rangedweapons_reload_gun(itemstack, user)
	return itemstack
	end,
		on_use = function(itemstack, user, pointed_thing)
	rangedweapons_shoot_gun(itemstack, user)
	return itemstack
		end,
	})
end)()

deagle = (function()
	--[[rw.register_tool(modname .. ":rw_deagle_rld", {
		stack_max= 1,
		wield_scale = {x=1.25,y=1.25,z=1.5},
		description = "",
		range = 0,
		loaded_gun = modname .. ":rw_deagle",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "deagle_rld.png",
	})
	rw.register_tool(modname .. ":rw_deagle_r", {
		stack_max= 1,
		wield_scale = {x=1.25,y=1.25,z=1.5},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_deagle",
		load_sound = "handgun_mag_in",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "deagle_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_deagle", {
		description = "" ..core.colorize("#35cdff","Desert Eagle\n")..core.colorize("#FFFFFF", "Ranged damage: 11\n") ..core.colorize("#FFFFFF", "Accuracy: 85%\n") ..core.colorize("#FFFFFF", "knockback: 6\n")  ..core.colorize("#FFFFFF", "Critical chance: 20%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 3x\n")..core.colorize("#FFFFFF", "Reload delay: 0.6\n")..core.colorize("#FFFFFF", "Clip size: 9/8/7\n")  ..core.colorize("#FFFFFF", "Ammunition: .357 Magnum rounds/.44 magnum rounds/.50AE catridges\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.7\n") ..core.colorize("#FFFFFF", "Gun type: Magnum\n") ..core.colorize("#FFFFFF", "Block penetration: 5%\n")
		..core.colorize("#FFFFFF", "penetration: 15%\n")..core.colorize("#FFFFFF", "Bullet velocity: 50"),
		wield_scale = {x=1.25,y=1.25,z=1.5},
		range = 0,
		inventory_image = "deagle.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=11,knockback=6},
			gun_crit = 20,
			gun_critEffc = 2.2,
			suitable_ammo = {{modname .. ":rw_357",9},{modname .. ":rw_44",8},{modname .. ":rw_50ae",7}},
			gun_skill = {"revolver_skill",40},
			gun_magazine = modname .. ":rw_handgun_mag_white",
			gun_unloaded = modname .. ":rw_deagle_r",
			gun_cooling = modname .. ":rw_deagle_rld",
			gun_velocity = 50,
			gun_accuracy = 85,
			gun_cooldown = 0.7,
			gun_reload = 0.6/1,
			gun_projectiles = 1,
			has_shell = 1,
			gun_durability = 900,
			gun_smokeSize = 7,
			gun_mob_penetration = 15,
			gun_node_penetration = 5,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "deagle",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})]]
	
	rw.register_tool(modname .. ":rw_golden_deagle_rld", {
		stack_max= 1,
		wield_scale = {x=1.25,y=1.25,z=1.5},
		description = "",
		range = 0,
		loaded_gun = modname .. ":rw_golden_deagle",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "golden_deagle_rld.png",
	})
	rw.register_tool(modname .. ":rw_golden_deagle_r", {
		stack_max= 1,
		wield_scale = {x=1.25,y=1.25,z=1.5},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_golden_deagle",
		load_sound = "handgun_mag_in",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "golden_deagle_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_golden_deagle", {
		description = "" ..core.colorize("#35cdff","Golden Desert Eagle\n")..core.colorize("#FFFFFF", "Ranged damage: 14\n") ..core.colorize("#FFFFFF", "Accuracy: 90%\n") ..core.colorize("#FFFFFF", "knockback: 6\n")  ..core.colorize("#FFFFFF", "Critical chance: 23%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 3x\n")..core.colorize("#FFFFFF", "Reload delay: 0.6\n")..core.colorize("#FFFFFF", "Clip size: 9/8/7\n")  ..core.colorize("#FFFFFF", "Ammunition: .357 Magnum rounds/.44 magnum rounds/.50AE catridges\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.75\n") ..core.colorize("#FFFFFF", "Gun type: Magnum\n") ..core.colorize("#FFFFFF", "Block penetration: 5%\n")
		..core.colorize("#FFFFFF", "penetration: 15%\n")..core.colorize("#FFFFFF", "Bullet velocity: 50"),
		wield_scale = {x=1.25,y=1.25,z=1.5},
		range = 0,
		inventory_image = "golden_deagle.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=14,knockback=6},
			gun_crit = 23,
			gun_critEffc = 2.2,
			suitable_ammo = {{modname .. ":rw_357",9},{modname .. ":rw_44",8},{modname .. ":rw_50ae",7}},
			gun_skill = {"revolver_skill",38},
			gun_magazine = modname .. ":rw_handgun_mag_white",
			gun_unloaded = modname .. ":rw_golden_deagle_r",
			gun_cooling = modname .. ":rw_golden_deagle_rld",
			gun_velocity = 50,
			gun_accuracy = 90,
			gun_cooldown = 0.75,
			gun_reload = 0.6/1,
			gun_projectiles = 1,
			has_shell = 1,
			gun_durability = 1000,
			gun_smokeSize = 7,
			gun_mob_penetration = 15,
			gun_node_penetration = 5,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "deagle",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

--end

--if minetest.settings:get_bool("rangedweapon_forceguns", true) then
forcegun = (function()
	local proj_dir
	
	rw.register_tool(modname .. ":rw_forcegun", {
		description = "" ..core.colorize("#35cdff","Force gun\n") ..core.colorize("#FFFFFF", "Completelly harmless... by itself...\n")..core.colorize("#FFFFFF", "It's projectile will push either the entity it hits directly, or everyone near the node it collides with far away.\n")  ..core.colorize("#FFFFFF", "Perfect for rocket-jumping or YEETing enemies away.\n")..core.colorize("#FFFFFF", "Power usage: 40\n")..core.colorize("#FFFFFF", "Gun type:Power Special-gun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 60"),
		range = 0,
		wield_scale = {x=2.0,y=2.0,z=1.75},
		inventory_image = "forcegun.png",
		on_use = function(itemstack, user, pointed_thing)
			local playeriscreative = minetest.is_creative_enabled(user:get_player_name())

			local pos = user:get_pos()
			local dir = user:get_look_dir()
			local yaw = user:get_look_horizontal()
			local inv = user:get_inventory()
			if playeriscreative or inv:contains_item("main", modname .. ":rw_power_particle 40") then
				if pos and dir then
					if not playeriscreative then
						inv:remove_item("main", modname .. ":rw_power_particle 25")
					end
					pos.y = pos.y + 1.5
					local obj = minetest.add_entity(pos, modname .. ":rw_forceblast")
					if obj then
						rw.sound_play("rocket", {object=obj})
						obj:set_velocity({x=dir.x * 60, y=dir.y * 60, z=dir.z * 60})
	
						obj:set_yaw(yaw - math.pi/2)
						proj_dir = dir
						local ent = obj:get_luaentity()
						if ent then
							ent.player = ent.player or user
						end
					end
				end
			end
		end,
	})
	
	local rangedweapons_forceblast = {
		timer = 0,
		initial_properties = {
			physical = true,
			hp_max = 420,
			glow = 30,
			visual = "sprite",
			visual_size = {x=0.4, y=0.4,},
			textures = {"force_bullet.png"},
			_lastpos = {},
			collide_with_objects = false,
			collisionbox = {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
		},
	}
	
	rangedweapons_forceblast.on_step = function(self, dtime, moveresult)
		--[[generic_proj_on_step(self, dtime, moveresult, {
			on_hit_object = function(self, collide_with)
				local pos = self.object:get_pos()
				proj_dir = proj_dir or ({x=0,y=0,z=0})

				if collide_with:is_player() then

					collide_with:add_player_velocity({x=proj_dir.x * 20, y=5+ (proj_dir.y * 20), z=proj_dir.z * 20})
				else
					collide_with:add_velocity({x=proj_dir.x * 20, y=5+ (proj_dir.y * 20), z=proj_dir.z * 20})

				end
				minetest.add_particle({
					pos = ({x = pos.x, y = pos.y, z = pos.z}),
					velocity ={x=0,y=0,z=0},
					acceleration ={x=0,y=0,z=0},
					expirationtime = 0.20,
					size = 16,
					collisiondetection = true,
					collision_removal = false,
					vertical = false,
					texture = "force_blast.png",
					glow = 20,
					animation = {type="vertical_frames", aspect_w=64, aspect_h=64, length = 0.20,},
				})
				self.object:remove()
			end
		})
		--]]

		self.timer = self.timer + dtime
		local pos = self.object:get_pos()
		proj_dir = proj_dir or ({x=0,y=0,z=0})
	
		if self.timer > 10 then
			self.object:remove()
		end
	
		if self.timer > 0.05 then
			self.object:set_properties({collide_with_objects = true})
		end
	
		if moveresult.collides == true then
			if moveresult.collisions[1] ~= nil then
	
				if moveresult.collisions[1].type == "object" then
				end
	
				if moveresult.collisions[1].type == "node" then
	
					local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 7)
					for k, obj in pairs(objs) do
	
						local posd_x = 1
						local posd_y = 1
						local posd_z = 1
	
						if obj:get_pos() then
							posd_x = pos.x - obj:get_pos().x
							posd_y = pos.y - obj:get_pos().y
							posd_z = pos.z - obj:get_pos().z
						end
	
	
						if posd_y < 0 and posd_y > -1 then posd_y = -1 end
						if posd_y > 0 and posd_y < 1 then posd_y = 1 end
	
						if posd_y > 0 then posd_y=posd_y*3 end
	
						posd_y = (posd_y + 0.5) * (((math.abs(posd_x)+0.5)+(math.abs(posd_z)+0.5))/2)
	
						if posd_y > -1.0 and posd_y < 0 then posd_y = -1.0 end
	
						if obj:get_luaentity() ~= nil then
							if obj:get_luaentity().name ~= modname .. ":rw_forceblast" and 
							obj:get_luaentity().name ~= "mcl_chests:chest" and
							obj:get_luaentity().name ~= "mcl_itemframes:item" and
							obj:get_luaentity().name ~= "mcl_enchanting:book"
							then
								obj:add_velocity({x=10*(-posd_x), y=30*(-1/posd_y), z=10*(-posd_z)})
								self.object:remove()
							end
						else
							obj:add_player_velocity({x=30*((-posd_x)/(1+math.abs(posd_x))), y=25*(-1/posd_y), z=30*((-posd_z)/(1+math.abs(posd_z)))})
							self.object:remove()
	
						end
					end
	
					minetest.add_particle({
						pos = ({x = pos.x, y = pos.y, z = pos.z}),
						velocity ={x=0,y=0,z=0},
						acceleration ={x=0,y=0,z=0},
						expirationtime = 0.20,
						size = 128,
						collisiondetection = true,
						collision_removal = false,
						vertical = false,
						texture = "force_blast.png",
						glow = 20,
						animation = {type="vertical_frames", aspect_w=64, aspect_h=64, length = 0.20,},
					})
					self.object:remove()
				end
	
				self._lastpos= {x = pos.x, y = pos.y, z = pos.z}
			end
		end
	end
	
	
	minetest.register_entity(modname .. ":rw_forceblast", rangedweapons_forceblast)
end)()

--end

--if minetest.settings:get_bool(modname .. "_javelins", true) then
javelin = (function()
	rw.register_craftitem(modname .. ":rw_thrown_javelin", {
		wield_scale = {x=2.0,y=2.0,z=1.0},
		inventory_image = "thrown_javelin.png",
	})
	
	rw.register_tool(modname .. ":rw_javelin", {
		description = "" ..core.colorize("#35cdff","Javelin\n") ..core.colorize("#FFFFFF", "Melee damage: 8\n") ..core.colorize("#FFFFFF", "Melee range: 4.5\n")..core.colorize("#FFFFFF", "Full punch interval: 1.25\n")  ..core.colorize("#FFFFFF", "Ranged damage: 9\n") ..core.colorize("#FFFFFF", "Accuracy: 92%\n") ..core.colorize("#FFFFFF", "knockback: 10\n") ..core.colorize("#FFFFFF", "Critical chance: 11%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.5x\n") ..core.colorize("#FFFFFF", "Projectile gravity: 6\n") ..core.colorize("#FFFFFF", "Projectile velocity: 35\n") ..core.colorize("#FFFFFF", "Enemy penetration: 50%\n") ..core.colorize("#ffc000", "Right-click to throw, Left-click to stab\n")..core.colorize("#ffc000", "Throwing wears the javelin out 5x faster than stabbing.") ,
		wield_scale = {x=2.0,y=2.0,z=1.0},
		range = 4.5,
		inventory_image = "javelin.png",
		tool_capabilities = {
			full_punch_interval = 1.25,
			max_drop_level = 0,
			groupcaps = {
				stabby = {times={[1]=0.25, [2]=0.50, [3]=0.75}, uses=66.6, maxlevel=2},
			},
			damage_groups = {fleshy=8,knockback=10},
		},
		RW_throw_capabilities = {
			throw_damage = {fleshy=9,knockback=10},
			throw_crit = 11,
			throw_critEffc = 2.5,
			throw_skill = {"throw_skill",20},
			throw_velocity = 40,
			throw_accuracy = 92,
			throw_cooldown = 0.0,
			throw_projectiles = 1,
			throw_gravity = 6,
			throw_sound = "throw",
			throw_dps = 0,
			throw_mob_penetration = 50,
			throw_node_penetration = 0,
			throw_entity = modname .. ":rw_shot_bullet",
			throw_visual = "wielditem",
			throw_texture = modname .. ":rw_thrown_javelin",
			throw_projectile_size = 0.15,
			throw_glass_breaking = 1,
			has_sparks = 1,
			ignites_explosives = 0,
			throw_door_breaking = 0,
			OnCollision = function(player,bullet,target)
				local throwDur = 40
				if bullet.wear+(65535/throwDur) < 65535 then
					javStack = {name=modname .. ":rw_javelin",wear=(bullet.wear)+(65535/throwDur)}
					minetest.add_item(bullet.object:get_pos(),javStack) end end,
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_yeet(itemstack, user)
			return itemstack
		end,
	})
end)()

--end

--if minetest.settings:get_bool(modname .. "_power_weapons", true) then
generator = (function()
	rw.register_node(modname .. ":rw_generator", {
		description = "" ..core.colorize("#35cdff","Power particle generator\n")..core.colorize("#FFFFFF", "generates 1 power particle every 3 seconds (can hold up to 200). Punch to harvest them"),
		tiles = {
			"generator_top.png",
			"generator_bottom.png",
			"generator_side.png",
			"generator_side.png",
			"generator_side.png",
			"generator_side.png"
		},
		paramtype = "light",
		light_source = 9,
		groups = {cracky = 3, oddly_breakable_by_hand = 3},
		on_timer = function(pos, elapsed)
			minetest.get_node_timer(pos):start(3)
			local nodemeta = minetest.get_meta(pos)
			if nodemeta:get_int("power_generated") < 200 then
				nodemeta:set_int("power_generated",nodemeta:get_int("power_generated")+1)
				nodemeta:set_string("infotext", "currently generated power:"..nodemeta:get_int("power_generated"))
			end
		end,
		on_punch = function(pos, node, puncher)
			local nodemeta = minetest.get_meta(pos)
			local inv = puncher:get_inventory()
			inv:add_item("main", modname .. ":rw_power_particle "..nodemeta:get_int("power_generated")) 
			nodemeta:set_int("power_generated",0)
			nodemeta:set_string("infotext", "currently generated power:"..nodemeta:get_int("power_generated"))
		end,
		on_construct = function(pos)
			minetest.get_node_timer(pos):start(3)
		end,
		sounds = node_sound_wood_defaults(),
	})
end)()

laser_blaster = (function()
	rw.register_craftitem(modname .. ":rw_blue_ray_visual", {
		wield_scale = {x=1.75,y=1.75,z=1.75},
		inventory_image = "blue_ray.png",
	})
	
	rw.register_tool(modname .. ":rw_laser_blaster", {
		stack_max= 1,
		wield_scale = {x=1.15,y=1.15,z=1.15},
		description = "" ..core.colorize("#35cdff","Laser blaster\n") ..core.colorize("#FFFFFF", "Ranged damage: 15\n") ..core.colorize("#FFFFFF", "accuracy: 100%\n") ..core.colorize("#FFFFFF", "knockback: 0\n")  ..core.colorize("#FFFFFF", "Critical chance: 10%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n")  ..core.colorize("#FFFFFF", "Power usage: 10\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.3\n") ..core.colorize("#FFFFFF", "Enemy penetration: 50%\n") ..core.colorize("#FFFFFF", "Gun type: power pistol\n") ..core.colorize("#FFFFFF", "Bullet velocity: 65"),
		range = 0,
		inventory_image = "laser_blaster.png",
		RW_powergun_capabilities = {
			power_damage = {fleshy=15,knockback=0},
			power_crit = 10,
			power_critEffc = 2.0,
			power_skill = {"",1},
			power_cooling = modname .. ":rw_laser_blaster",
			power_velocity = 65,
			power_accuracy = 100,
			power_cooldown = 0.3,
			power_projectiles = 1,
			power_durability = 5000,
			power_sound = "laser",
			power_glass_breaking = 1,
			power_door_breaking = 1,
			power_dps = 0,
			power_mob_penetration = 50,
			power_node_penetration = 0,
			power_dps = 0,
			power_consumption = 10,
			power_entity = modname .. ":rw_shot_bullet",
			power_visual = "wielditem",
			power_texture = modname .. ":rw_blue_ray_visual",
			power_projectile_size = 0.1,
			has_sparks = 0,
			ignites_explosives = 1,
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_powergun(itemstack, user)
			return itemstack
		end,
	
	})
end)()

laser_rifle = (function()
	rw.register_craftitem(modname .. ":rw_red_ray_visual", {
		wield_scale = {x=1.5,y=1.5,z=2.0},
		inventory_image = "red_ray.png",
	})
	
	rw.register_tool(modname .. ":rw_laser_rifle", {
		wield_scale = {x=1.9,y=1.9,z=2.5},
		description = "" ..core.colorize("#35cdff","Laser rifle\n") ..core.colorize("#FFFFFF", "Ranged damage: 12\n") ..core.colorize("#FFFFFF", "accuracy: 100%\n") ..core.colorize("#FFFFFF", "knockback: 0\n")  ..core.colorize("#FFFFFF", "Critical chance: 9%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n")  ..core.colorize("#FFFFFF", "Power usage: 8\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.1 (full-auto)\n") ..core.colorize("#FFFFFF", "Enemy penetration: 40%\n") ..core.colorize("#FFFFFF", "Gun type: power assault rifle\n") ..core.colorize("#FFFFFF", "Bullet velocity: 60"),
		range = 0,
		RW_powergun_capabilities = {
			automatic_gun = 1,
			power_damage = {fleshy=12,knockback=0},
			power_crit = 9,
			power_critEffc = 2.0,
			power_skill = {"",1},
			power_cooling = modname .. ":rw_laser_rifle",
			power_velocity = 60,
			power_accuracy = 100,
			power_cooldown = 0.1,
			power_projectiles = 1,
			power_durability = 12500,
			power_sound = "laser",
			power_glass_breaking = 1,
			power_door_breaking = 1,
			power_dps = 0,
			power_mob_penetration = 40,
			power_node_penetration = 0,
			power_dps = 0,
			power_consumption = 8,
			power_entity = modname .. ":rw_shot_bullet",
			power_visual = "wielditem",
			power_texture = modname .. ":rw_red_ray_visual",
			power_projectile_size = 0.075,
			has_sparks = 0,
			ignites_explosives = 1,
		},
		inventory_image = "laser_rifle.png",
	})
end)()

laser_shotgun = (function()
	rw.register_tool(modname .. ":rw_laser_shotgun", {
		stack_max= 1,
		wield_scale = {x=2.0,y=2.0,z=1.75},
		description = "" ..core.colorize("#35cdff","Laser shotgun\n") ..core.colorize("#FFFFFF", "Ranged damage: 10\n") ..core.colorize("#FFFFFF", "accuracy: 40%\n") ..core.colorize("#FFFFFF", "projectiles: 6\n") ..core.colorize("#FFFFFF", "knockback: 0\n")  ..core.colorize("#FFFFFF", "Critical chance: 8%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.2x\n")  ..core.colorize("#FFFFFF", "Power usage: 30\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.5\n") ..core.colorize("#FFFFFF", "Enemy penetration: 40%\n") ..core.colorize("#FFFFFF", "Gun type: power pistol\n") ..core.colorize("#FFFFFF", "Bullet velocity: 55"),
		range = 0,
		inventory_image = "laser_shotgun.png",
		RW_powergun_capabilities = {
			power_damage = {fleshy=10,knockback=0},
			power_crit = 8,
			power_critEffc = 2.2,
			power_skill = {"",1},
			power_cooling = modname .. ":rw_laser_shotgun",
			power_velocity = 55,
			power_accuracy = 40,
			power_cooldown = 0.5,
			power_projectiles = 1,
			power_durability = 2000,
			power_sound = "laser",
			power_glass_breaking = 1,
			power_door_breaking = 1,
			power_dps = 0,
			power_mob_penetration = 40,
			power_node_penetration = 0,
			power_dps = 0,
			power_consumption = 30,
			power_entity = modname .. ":rw_shot_bullet",
			power_visual = "sprite",
			power_texture = "green_ray.png",
			power_projectile_size = 0.005,
			power_projectiles = 6,
			has_sparks = 0,
			ignites_explosives = 1,
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_powergun(itemstack, user)
			return itemstack
		end,
	
	})
end)()

--end

--if minetest.settings:get_bool(modname .. "_machine_pistols", true) then
--[[tmp = (function()
	rw.register_tool(modname .. ":rw_tmp_r", {
		stack_max= 1,
		wield_scale = {x=1.15,y=1.15,z=1.15},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_tmp_rr",
		load_sound = "handgun_mag_in",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "tmp_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_tmp_rr", {
		stack_max= 1,
		wield_scale = {x=1.15,y=1.15,z=1.15},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_tmp_rrr",
		load_sound = "reload_a",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "tmp.png",
	})
	
	rw.register_tool(modname .. ":rw_tmp_rrr", {
		stack_max= 1,
		wield_scale = {x=1.15,y=1.15,z=1.15},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_tmp",
		load_sound = "reload_b",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "tmp.png",
	})
	
	rw.register_tool(modname .. ":rw_tmp", {
		stack_max= 1,
		wield_scale = {x=1.15,y=1.15,z=1.15},
		description = "" ..core.colorize("#35cdff","Steyr T.M.P.\n") ..core.colorize("#FFFFFF", "Gun damage: 1\n") ..core.colorize("#FFFFFF", "accuracy: 64%\n") ..core.colorize("#FFFFFF", "Gun knockback: 0\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 4%\n")..core.colorize("#FFFFFF", "Critical efficiency: 1.85x\n")   ..core.colorize("#FFFFFF", "Reload delay: 1.0\n") ..core.colorize("#FFFFFF", "Clip size: 30\n")   ..core.colorize("#FFFFFF", "Ammunition: 9x19mm parabellum\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.066(full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: machine pistol\n") ..core.colorize("#FFFFFF", "Bullet velocity: 20"),
		range = 0,
		inventory_image = "tmp.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=1,knockback=0},
			gun_crit = 4,
			gun_critEffc = 1.85,
			suitable_ammo = {{modname .. ":rw_9mm",30}},
			gun_skill = {"mp_skill",85},
			gun_magazine = modname .. ":rw_machinepistol_mag",
			gun_unloaded = modname .. ":rw_tmp_r",
			gun_velocity = 20,
			gun_accuracy = 64,
			gun_cooldown = 0.066,
			gun_reload = 1.0/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1200,
			gun_smokeSize = 4,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "machine_pistol",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

tec9 = (function()
	rw.register_tool(modname .. ":rw_tec9_r", {
		stack_max= 1,
		wield_scale = {x=1.25,y=1.25,z=1.50},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_tec9_rr",
		load_sound = "handgun_mag_in",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "tec9_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_tec9_rr", {
		stack_max= 1,
		wield_scale = {x=1.25,y=1.25,z=1.50},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_tec9_rrr",
		load_sound = "reload_a",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "tec9.png",
	})
	
	rw.register_tool(modname .. ":rw_tec9_rrr", {
		stack_max= 1,
		wield_scale = {x=1.25,y=1.25,z=1.50},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_tec9",
		load_sound = "reload_b",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "tec9.png",
	})
	
	rw.register_tool(modname .. ":rw_tec9", {
		stack_max= 1,
		wield_scale = {x=1.25,y=1.25,z=1.50},
		description = "" ..core.colorize("#35cdff","TEC-9\n") ..core.colorize("#FFFFFF", "Gun damage: 1\n") ..core.colorize("#FFFFFF", "accuracy: 75%\n") ..core.colorize("#FFFFFF", "Gun knockback: 0\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 9%\n") ..core.colorize("#FFFFFF", "Gun Critical efficiency: 1.9x\n") ..core.colorize("#FFFFFF", "Reload delay: 1.0\n") ..core.colorize("#FFFFFF", "Clip size: 50\n")   ..core.colorize("#FFFFFF", "Ammunition: 9x19mm parabellum\n")  ..core.colorize("#FFFFFF", "Rate of fire: 0.2\n") ..core.colorize("#FFFFFF", "Gun type: machine pistol\n") ..core.colorize("#FFFFFF", "Bullet velocity: 20"),
		range = 0,
		inventory_image = "tec9.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=1,knockback=0},
			gun_crit = 9,
			gun_critEffc = 1.9,
			suitable_ammo = {{modname .. ":rw_9mm",50}},
			gun_skill = {"mp_skill",80},
			gun_magazine = modname .. ":rw_machinepistol_mag",
			gun_unloaded = modname .. ":rw_tec9_r",
			gun_velocity = 20,
			gun_accuracy = 75,
			gun_cooldown = 0.2,
			gun_reload = 1.0/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1100,
			gun_smokeSize = 4,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "machine_pistol",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	})
end)()--]]

uzi = (function()
	rw.register_tool(modname .. ":rw_uzi_r", {
		stack_max= 1,
		wield_scale = {x=1.6,y=1.6,z=1.10},
		description = "",
		rw_next_reload = modname .. ":rw_uzi_rr",
		load_sound = "handgun_mag_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "uzi_rld.png",
	})
	rw.register_tool(modname .. ":rw_uzi_rr", {
		stack_max= 1,
		wield_scale = {x=1.6,y=1.6,z=1.10},
		description = "",
		rw_next_reload = modname .. ":rw_uzi_rrr",
		load_sound = "reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "uzi.png",
	})
	rw.register_tool(modname .. ":rw_uzi_rrr", {
		stack_max= 1,
		wield_scale = {x=1.6,y=1.6,z=1.10},
		description = "",
		rw_next_reload = modname .. ":rw_uzi",
		load_sound = "reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "uzi.png",
	})
	-------------------------------------------
	
	rw.register_tool(modname .. ":rw_uzi", {
		stack_max= 1,
		wield_scale = {x=1.6,y=1.6,z=1.10},
		description = "" ..core.colorize("#35cdff","UZI\n") ..core.colorize("#FFFFFF", "Ranged damage: 2\n") ..core.colorize("#FFFFFF", "accuracy: 72%\n") ..core.colorize("#FFFFFF", "knockback: 0\n") ..core.colorize("#FFFFFF", "Reload delay: 1.2\n")  ..core.colorize("#FFFFFF", "Clip size: 40/22\n") ..core.colorize("#FFFFFF", "Critical chance: 5%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 1.9x\n")  ..core.colorize("#FFFFFF", "Ammunition: 9x19mm parabellum/.45acp\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.08 (full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: machine pistol\n") ..core.colorize("#FFFFFF", "Bullet velocity: 25"),
		range = 0,
		inventory_image = "uzi.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=2,knockback=0},
			gun_crit = 5,
			gun_critEffc = 1.9,
			suitable_ammo = {{modname .. ":rw_9mm",40},{modname .. ":rw_45acp",22}},
			gun_skill = {"mp_skill",80},
			gun_magazine = modname .. ":rw_machinepistol_mag",
			gun_unloaded = modname .. ":rw_uzi_r",
			gun_velocity = 25,
			gun_accuracy = 72,
			gun_cooldown = 0.08,
			gun_reload = 1.2/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1500,
			gun_smokeSize = 4,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "machine_pistol",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

--[[kriss_sv = (function()
	rw.register_tool(modname .. ":rw_kriss_sv_r", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.15},
		description = "",
		rw_next_reload = modname .. ":rw_kriss_sv_rr",
		load_sound = "handgun_mag_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "kriss_sv_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_kriss_sv_rr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.15},
		description = "",
		rw_next_reload = modname .. ":rw_kriss_sv_rrr",
		load_sound = "reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "kriss_sv.png",
	})
	
	rw.register_tool(modname .. ":rw_kriss_sv_rrr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.15},
		description = "",
		rw_next_reload = modname .. ":rw_kriss_sv",
		load_sound = "reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "kriss_sv.png",
	})
	
	
	rw.register_tool(modname .. ":rw_kriss_sv", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.15},
		description = "" ..core.colorize("#35cdff","Kriss Super V\n") ..core.colorize("#FFFFFF", "Gun damage: 1\n") ..core.colorize("#FFFFFF", "accuracy: 60%\n") ..core.colorize("#FFFFFF", "Gun knockback: 0\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 6%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 1.85x\n") ..core.colorize("#FFFFFF", "Reload delay: 0.9\n") ..core.colorize("#FFFFFF", "Clip size: 33/33/13\n")   ..core.colorize("#FFFFFF", "Ammunition: 9x19mm parabellum/10mm auto/.45 acp\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.05\n") ..core.colorize("#FFFFFF", "Gun type: machine pistol\n") ..core.colorize("#FFFFFF", "Bullet velocity: 20"),
		range = 0,
		inventory_image = "kriss_sv.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=1,knockback=0},
			gun_crit = 6,
			gun_critEffc = 1.95,
			suitable_ammo = {{modname .. ":rw_9mm",33},{modname .. ":rw_10mm",33},{modname .. ":rw_45acp",13}},
			gun_skill = {"mp_skill",90},
			gun_magazine = modname .. ":rw_machinepistol_mag",
			gun_unloaded = modname .. ":rw_kriss_sv_r",
			gun_velocity = 20,
			gun_accuracy = 60,
			gun_cooldown = 0.05,
			gun_reload = 0.9/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1750,
			gun_smokeSize = 4,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "machine_pistol",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	})
end)()--]]

--end
--if minetest.settings:get_bool(modname .. "_shotguns", true) then
remington = (function()
	rw.register_tool(modname .. ":rw_remington_rld", {
		stack_max= 1,
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		loaded_gun = modname .. ":rw_remington",
		loaded_sound = "shotgun_reload_b",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "remington_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_remington", {
		description = "" ..core.colorize("#35cdff","Remington 870\n") ..core.colorize("#FFFFFF", "Ranged damage: 5\n") ..core.colorize("#FFFFFF", "projectiles: 8\n") ..core.colorize("#FFFFFF", "Gun gravity: 5\n") ..core.colorize("#FFFFFF", "Accuracy: 40%\n")..core.colorize("#FFFFFF", "knockback: 5\n") ..core.colorize("#FFFFFF", "Critical chance: 4%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n") ..core.colorize("#FFFFFF", "Ammunition: 12 gauge shells\n") ..core.colorize("#FFFFFF", "Pump delay: 0.8\n")..core.colorize("#FFFFFF", "Clip size: 4\n") ..core.colorize("#27a600", "Gun is ready to fire!\n") ..core.colorize("#fff21c", "Right-click to load in a bullet!\n")  ..core.colorize("#FFFFFF", "Gun type: shotgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 18"),
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		inventory_image = "remington.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=5,knockback=5},
			gun_crit = 4,
			gun_critEffc = 2.0,
			suitable_ammo = {{modname .. ":rw_shell",8}},
			gun_skill = {"shotgun_skill",20},
			gun_unloaded = modname .. ":rw_remington_rld",
			gun_cooling = modname .. ":rw_remington_uld",
			gun_velocity = 18,
			gun_accuracy = 40,
			gun_cooldown = 0.8,
			gun_gravity = 5,
			gun_reload = 0.25,
			gun_projectiles = 4,
			has_shell = 0,
			gun_durability = 275,
			gun_smokeSize = 14,
			gun_door_breaking = 1,
			gun_sound = "shotgun_shot",
			gun_unload_sound = "shell_insert",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_single_load_gun(itemstack, user, "")
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
	
	rw.register_tool(modname .. ":rw_remington_uld", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		range = 0,
		description = "" ..core.colorize("#35cdff","Remington 870\n") ..core.colorize("#FFFFFF", "Ranged damage: 1\n") ..core.colorize("#FFFFFF", "projectiles: 4\n") ..core.colorize("#FFFFFF", "Gun gravity: 5\n") ..core.colorize("#FFFFFF", "Accuracy: 40%\n")..core.colorize("#FFFFFF", "knockback: 5\n") ..core.colorize("#FFFFFF", "Critical chance: 4%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n") ..core.colorize("#FFFFFF", "Ammunition: 12 gauge shells\n") ..core.colorize("#FFFFFF", "Pump delay: 0.8\n")..core.colorize("#FFFFFF", "Clip size: 4\n") ..core.colorize("#be0d00", "Right-click, to eject the empty shell!\n") ..core.colorize("#fff21c", "Right-click to load in a bullet!\n")  ..core.colorize("#FFFFFF", "Gun type: shotgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 20"),
		inventory_image = "remington.png",
		groups = {not_in_creative_inventory = 1},
		on_use = function(user)
			rw.sound_play("empty", {user})
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			eject_shell(itemstack,user,modname .. ":rw_remington_rld",0.8,modname .. "_shotgun_reload_a",modname .. ":rw_empty_shell")
			return itemstack
		end,
	})
end)()

--[[
spas12 = (function()
	rw.register_tool(modname .. ":rw_spas12_rld", {
		stack_max= 1,
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		loaded_gun = modname .. ":rw_spas12",
		loaded_sound = "shotgun_reload_b",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "spas12_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_spas12", {
		description = "" ..core.colorize("#35cdff","spas-12\n") ..core.colorize("#FFFFFF", "Ranged damage: 3\n") ..core.colorize("#FFFFFF", "projectiles: 6\n") ..core.colorize("#FFFFFF", "Gun gravity: 3\n") ..core.colorize("#FFFFFF", "Accuracy: 52%\n")..core.colorize("#FFFFFF", "knockback: 7\n") ..core.colorize("#FFFFFF", "Critical chance: 7%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.1x\n") ..core.colorize("#FFFFFF", "Ammunition: 12 gauge shells\n") ..core.colorize("#FFFFFF", "Pump delay: 0.45\n")..core.colorize("#FFFFFF", "Clip size: 8\n") ..core.colorize("#27a600", "Gun is ready to fire!\n") ..core.colorize("#fff21c", "Right-click to load in a bullet!\n")  ..core.colorize("#FFFFFF", "Gun type: shotgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 32"),
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		inventory_image = "spas12.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=3,knockback=7},
			gun_crit = 7,
			gun_critEffc = 2.1,
			suitable_ammo = {{modname .. ":rw_shell",8}},
			gun_skill = {"shotgun_skill",20},
			gun_unloaded = modname .. ":rw_spas12_rld",
			gun_cooling = modname .. ":rw_spas12_uld",
			gun_velocity = 32,
			gun_accuracy = 52,
			gun_cooldown = 0.45,
			gun_gravity = 3,
			gun_reload = 0.25,
			gun_projectiles = 6,
			has_shell = 0,
			gun_durability = 550,
			gun_smokeSize = 15,
			gun_door_breaking = 1,
			gun_sound = "shotgun_shot",
			gun_unload_sound = "shell_insert",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_single_load_gun(itemstack, user, "")
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
	
	rw.register_tool(modname .. ":rw_spas12_uld", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		range = 0,
		description = "" ..core.colorize("#35cdff","spas-12\n") ..core.colorize("#FFFFFF", "Ranged damage: 2\n") ..core.colorize("#FFFFFF", "projectiles: 6\n") ..core.colorize("#FFFFFF", "Gun gravity: 3\n") ..core.colorize("#FFFFFF", "Accuracy: 52%\n")..core.colorize("#FFFFFF", "knockback: 7\n") ..core.colorize("#FFFFFF", "Critical chance: 7%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.1x\n") ..core.colorize("#FFFFFF", "Ammunition: 12 gauge shells\n") ..core.colorize("#FFFFFF", "Pump delay: 0.45\n")..core.colorize("#FFFFFF", "Clip size: 8\n") ..core.colorize("#be0d00", "Right-click, to eject the empty shell!\n") ..core.colorize("#fff21c", "Right-click to load in a bullet!\n")  ..core.colorize("#FFFFFF", "Gun type: shotgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 28"),
		inventory_image = "spas12.png",
		groups = {not_in_creative_inventory = 1},
		on_use = function(itemstack, user)
			rw.sound_play("empty", {pos = user:get_pos()})
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			eject_shell(itemstack,user,modname .. ":rw_spas12_rld",0.6,modname .. "_shotgun_reload_a",modname .. ":rw_empty_shell")
			return itemstack
		end,
	})
end)()

benelli = (function()
	rw.register_tool(modname .. ":rw_benelli_rld", {
		stack_max= 1,
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		loaded_gun = modname .. ":rw_benelli",
		loaded_sound = "shotgun_reload_b",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "benelli_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_benelli", {
		description = "" ..core.colorize("#35cdff","benelli m3\n") ..core.colorize("#FFFFFF", "Ranged damage: 2\n") ..core.colorize("#FFFFFF", "projectiles: 5\n") ..core.colorize("#FFFFFF", "Gun gravity: 4\n") ..core.colorize("#FFFFFF", "Accuracy: 48%\n")..core.colorize("#FFFFFF", "knockback: 6\n") ..core.colorize("#FFFFFF", "Critical chance: 6%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n") ..core.colorize("#FFFFFF", "Ammunition: 12 gauge shells\n") ..core.colorize("#FFFFFF", "Pump delay: 0.6\n")..core.colorize("#FFFFFF", "Clip size: 7\n") ..core.colorize("#27a600", "Gun is ready to fire!\n") ..core.colorize("#fff21c", "Right-click to load in a bullet!\n")  ..core.colorize("#FFFFFF", "Gun type: shotgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 26"),
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		inventory_image = "benelli.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=2,knockback=6},
			gun_crit = 6,
			gun_critEffc = 2.0,
			suitable_ammo = {{modname .. ":rw_shell",7}},
			gun_skill = {"shotgun_skill",20},
			gun_unloaded = modname .. ":rw_benelli_rld",
			gun_cooling = modname .. ":rw_benelli_uld",
			gun_velocity = 25,
			gun_accuracy = 48,
			gun_cooldown = 0.6,
			gun_gravity = 4,
			gun_reload = 0.25,
			gun_projectiles = 5,
			has_shell = 0,
			gun_durability = 325,
			gun_smokeSize = 14,
			gun_door_breaking = 1,
			gun_sound = "shotgun_shot",
			gun_unload_sound = "shell_insert",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_single_load_gun(itemstack, user, "")
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
	
	rw.register_tool(modname .. ":rw_benelli_uld", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		range = 0,
		description = "" ..core.colorize("#35cdff","benelli m3\n") ..core.colorize("#FFFFFF", "Ranged damage: 2\n") ..core.colorize("#FFFFFF", "projectiles: 5\n") ..core.colorize("#FFFFFF", "Gun gravity: 4\n") ..core.colorize("#FFFFFF", "Accuracy: 48%\n")..core.colorize("#FFFFFF", "knockback: 6\n") ..core.colorize("#FFFFFF", "Critical chance: 6%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n") ..core.colorize("#FFFFFF", "Ammunition: 12 gauge shells\n") ..core.colorize("#FFFFFF", "Pump delay: 0.6\n")..core.colorize("#FFFFFF", "Clip size: 7\n") ..core.colorize("#be0d00", "Right-click, to eject the empty shell!\n") ..core.colorize("#fff21c", "Right-click to load in a bullet!\n")  ..core.colorize("#FFFFFF", "Gun type: shotgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 25"),
		inventory_image = "benelli.png",
		groups = {not_in_creative_inventory = 1},
		on_use = function(itemstack, user)
			rw.sound_play("empty", {pos = user:get_pos()})
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			eject_shell(itemstack,user,modname .. ":rw_benelli_rld",0.6,modname .. "_shotgun_reload_a",modname .. ":rw_empty_shell")
			return itemstack
		end,
	})
end)()
--]]

--end
--if minetest.settings:get_bool(modname .. "_auto_shotguns", true) then
jackhammer = (function()
	rw.register_tool(modname .. ":rw_jackhammer_r", {
		stack_max= 1,
		wield_scale = {x=2.6,y=2.6,z=1.8},
		description = "",
		rw_next_reload = modname .. ":rw_jackhammer_rr",
		load_sound = "rifle_clip_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "jackhammer_rld.png",
	})
	rw.register_tool(modname .. ":rw_jackhammer_rr", {
		stack_max= 1,
		wield_scale = {x=2.6,y=2.6,z=1.8},
		description = "",
		rw_next_reload = modname .. ":rw_jackhammer_rrr",
		load_sound = "reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "jackhammer.png",
	})
	rw.register_tool(modname .. ":rw_jackhammer_rrr", {
		stack_max= 1,
		wield_scale = {x=2.6,y=2.6,z=1.8},
		description = "",
		rw_next_reload = modname .. ":rw_jackhammer",
		load_sound = "reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "jackhammer.png",
	})
	-------------------------------------------
	
	rw.register_tool(modname .. ":rw_jackhammer", {
		stack_max= 1,
		wield_scale = {x=2.6,y=2.6,z=1.8},
		description = "" ..core.colorize("#35cdff","Jackhammer\n") ..core.colorize("#FFFFFF", "Ranged damage: 3\n") ..core.colorize("#FFFFFF", "projectiles: 8\n") ..core.colorize("#FFFFFF", "Gun gravity: 3\n") ..core.colorize("#FFFFFF", "accuracy: 35%\n") ..core.colorize("#FFFFFF", "knockback: 6\n") ..core.colorize("#FFFFFF", "Reload delay: 1.6\n")  ..core.colorize("#FFFFFF", "Clip size: 10\n") ..core.colorize("#FFFFFF", "Critical chance: 7%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.2x\n")  ..core.colorize("#FFFFFF", "Ammunition: 12 gauge shell\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.25 (full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: shotgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 30"),
		range = 0,
		inventory_image = "jackhammer.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=3,knockback=6},
			gun_crit = 7,
			gun_critEffc = 2.2,
			suitable_ammo = {{modname .. ":rw_shell",10}},
			gun_skill = {"shotgun_skill",35},
			gun_magazine = modname .. ":rw_drum_mag",
			gun_unloaded = modname .. ":rw_jackhammer_r",
			gun_velocity = 30,
			gun_accuracy = 35,
			gun_cooldown = 0.25,
			gun_reload = 1.6/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_durability = 825,
			gun_smokeSize = 9,
			gun_door_breaking = 1,
			gun_projectiles = 8,
			gun_gravity = 3,
			gun_unload_sound = "rifle_clip_out",
			gun_sound = "shotgun_shot",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

--[[
aa12 = (function()
	rw.register_tool(modname .. ":rw_aa12_r", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.4},
		description = "",
		rw_next_reload = modname .. ":rw_aa12_rr",
		load_sound = "rifle_clip_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "aa12_rld.png",
	})
	rw.register_tool(modname .. ":rw_aa12_rr", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.4},
		description = "",
		rw_next_reload = modname .. ":rw_aa12_rrr",
		load_sound = "reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "aa12.png",
	})
	rw.register_tool(modname .. ":rw_aa12_rrr", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.4},
		description = "",
		rw_next_reload = modname .. ":rw_aa12",
		load_sound = "reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "aa12.png",
	})
	-------------------------------------------
	
	rw.register_tool(modname .. ":rw_aa12", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.4},
		description = "" ..core.colorize("#35cdff","AA-12\n") ..core.colorize("#FFFFFF", "Ranged damage: 1\n") ..core.colorize("#FFFFFF", "projectiles: 5\n") ..core.colorize("#FFFFFF", "Gun gravity: 4\n") ..core.colorize("#FFFFFF", "accuracy: 40%\n") ..core.colorize("#FFFFFF", "knockback: 5\n") ..core.colorize("#FFFFFF", "Reload delay: 1.5\n")  ..core.colorize("#FFFFFF", "Clip size: 20\n") ..core.colorize("#FFFFFF", "Critical chance: 5%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n")  ..core.colorize("#FFFFFF", "Ammunition: 12 gauge shell\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.2 (full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: shotgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 25"),
		range = 0,
		inventory_image = "aa12.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=1,knockback=5},
			gun_crit = 5,
			gun_critEffc = 2.0,
			suitable_ammo = {{modname .. ":rw_shell",20}},
			gun_skill = {"shotgun_skill",40},
			gun_magazine = modname .. ":rw_drum_mag",
			gun_unloaded = modname .. ":rw_aa12_r",
			gun_velocity = 25,
			gun_accuracy = 40,
			gun_cooldown = 0.2,
			gun_reload = 1.5/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_durability = 750,
			gun_smokeSize = 8,
			gun_door_breaking = 1,
			gun_projectiles = 5,
			gun_gravity = 4,
			gun_unload_sound = "rifle_clip_out",
			gun_sound = "shotgun_shot",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	})
end)()
--]]

--end
--if minetest.settings:get_bool(modname .. "_smgs", true) then
mp5 = (function()
	rw.register_tool(modname .. ":rw_mp5_r", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.20},
		description = "",
		rw_next_reload = modname .. ":rw_mp5_rr",
		load_sound = "handgun_mag_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "mp5_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_mp5_rr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.20},
		description = "",
		rw_next_reload = modname .. ":rw_mp5_rrr",
		load_sound = "reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "mp5.png",
	})
	
	rw.register_tool(modname .. ":rw_mp5_rrr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.20},
		description = "",
		rw_next_reload = modname .. ":rw_mp5",
		load_sound = "reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "mp5.png",
	})
	
	
	rw.register_tool(modname .. ":rw_mp5", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.20},
		description = "" ..core.colorize("#35cdff","MP5\n") ..core.colorize("#FFFFFF", "Gun damage: 3\n") ..core.colorize("#FFFFFF", "accuracy: 74%\n") ..core.colorize("#FFFFFF", "Gun knockback: 1\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 7%\n")..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n")   ..core.colorize("#FFFFFF", "Reload delay: 1.0\n") ..core.colorize("#FFFFFF", "Clip size: 40/40\n")   ..core.colorize("#FFFFFF", "Ammunition: 9x19mm parabellum/10mm auto\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.075(full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: sub-machinegun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 25"),
		range = 0,
		inventory_image = "mp5.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=3,knockback=1},
			gun_crit = 7,
			gun_critEffc = 2.0,
			suitable_ammo = {{modname .. ":rw_9mm",40},{modname .. ":rw_10mm",40}},
			gun_skill = {"smg_skill",75},
			gun_magazine = modname .. ":rw_machinepistol_mag",
			gun_unloaded = modname .. ":rw_mp5_r",
			gun_velocity = 25,
			gun_accuracy = 74,
			gun_cooldown = 0.075,
			gun_reload = 1.0/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1600,
			gun_smokeSize = 4,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "machine_pistol",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

--[[ump = (function()
	rw.register_tool(modname .. ":rw_ump_r", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.25},
		description = "",
		rw_next_reload = modname .. ":rw_ump_rr",
		load_sound = "handgun_mag_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "ump_rld.png",
	})
	rw.register_tool(modname .. ":rw_ump_rr", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.25},
		description = "",
		rw_next_reload = modname .. ":rw_ump_rrr",
		load_sound = "reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "ump.png",
	})
	rw.register_tool(modname .. ":rw_ump_rrr", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.25},
		description = "",
		rw_next_reload = modname .. ":rw_ump",
		load_sound = "reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "ump.png",
	})
	-------------------------------------------
	
	rw.register_tool(modname .. ":rw_ump", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.25},
		description = "" ..core.colorize("#35cdff","UMP-9\n") ..core.colorize("#FFFFFF", "Ranged damage: 5\n") ..core.colorize("#FFFFFF", "accuracy: 79%\n") ..core.colorize("#FFFFFF", "knockback: 1\n") ..core.colorize("#FFFFFF", "Reload delay: 1.25\n")  ..core.colorize("#FFFFFF", "Clip size: 25/25\n") ..core.colorize("#FFFFFF", "Critical chance: 9%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n")  ..core.colorize("#FFFFFF", "Ammunition: 9x19mm parabellum/.45acp\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.115 (full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: smg\n") ..core.colorize("#FFFFFF", "Bullet velocity: 32"),
		range = 0,
		inventory_image = "ump.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=5,knockback=1},
			gun_crit = 9,
			gun_critEffc = 2.0,
			suitable_ammo = {{modname .. ":rw_9mm",25},{modname .. ":rw_45acp",25}},
			gun_skill = {"smg_skill",60},
			gun_magazine = modname .. ":rw_machinepistol_mag",
			gun_unloaded = modname .. ":rw_ump_r",
			gun_velocity = 32,
			gun_accuracy = 79,
			gun_cooldown = 0.115,
			gun_reload = 1.25/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1500,
			gun_smokeSize = 4,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "smg",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

mp40 = (function()
	rw.register_tool(modname .. ":rw_mp40_r", {
		wield_scale = {x=1.75,y=1.75,z=1.5},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_mp40_rr",
		load_sound = "handgun_mag_in",
		inventory_image = "mp40_rld.png",
		groups = {not_in_creative_inventory = 1},
	})
	rw.register_tool(modname .. ":rw_mp40_rr", {
		wield_scale = {x=1.75,y=1.75,z=1.5},
		description = "",
		range = 0,
		rw_next_reload = modname .. ":rw_mp40_rrr",
		load_sound = "reload_a",
		inventory_image = "mp40.png",
		groups = {not_in_creative_inventory = 1},
	})
	rw.register_tool(modname .. ":rw_mp40_rrr", {
		wield_scale = {x=1.75,y=1.75,z=1.5},
		description = "",
		range = 0,
		inventory_image = "mp40.png",
		rw_next_reload = modname .. ":rw_mp40",
		load_sound = "reload_b",
		groups = {not_in_creative_inventory = 1},
	})
	
	rw.register_tool(modname .. ":rw_mp40", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.5},
		description = "" ..core.colorize("#35cdff","MP-40\n") ..core.colorize("#FFFFFF", "Ranged damage: 2\n") ..core.colorize("#FFFFFF", "accuracy: 75%\n") ..core.colorize("#FFFFFF", "Gun knockback: 1\n")  ..core.colorize("#FFFFFF", "Critical chance: 8%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2x\n")  ..core.colorize("#FFFFFF", "Ammunition: 9x19mm parabellum\n") ..core.colorize("#FFFFFF", "Clip size: 32\n") ..core.colorize("#FFFFFF", "Reload delay: 1.3\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.14\n") ..core.colorize("#FFFFFF", "Gun type: sub-machinegun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 25"),
		range = 0,
		inventory_image = "mp40.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=2,knockback=1},
			gun_crit = 8,
			gun_critEffc = 2.0,
			suitable_ammo = {{modname .. ":rw_9mm",32}},
			gun_skill = {"smg_skill",75},
			gun_magazine = modname .. ":rw_machinepistol_mag",
			gun_unloaded = modname .. ":rw_mp40_r",
			gun_velocity = 25,
			gun_accuracy = 75,
			gun_cooldown = 0.14,
			gun_reload = 1.3/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1500,
			gun_smokeSize = 4,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "machine_pistol",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	
	})
end)()

thompson = (function()
	rw.register_tool(modname .. ":rw_thompson_r", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.25},
		description = "",
		rw_next_reload = modname .. ":rw_thompson_rr",
		load_sound = "handgun_mag_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "thompson_rld.png",
	})
	rw.register_tool(modname .. ":rw_thompson_rr", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.25},
		description = "",
		rw_next_reload = modname .. ":rw_thompson_rrr",
		load_sound = "reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "thompson.png",
	})
	rw.register_tool(modname .. ":rw_thompson_rrr", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.25},
		description = "",
		rw_next_reload = modname .. ":rw_thompson",
		load_sound = "reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "thompson.png",
	})
	-------------------------------------------
	
	rw.register_tool(modname .. ":rw_thompson", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.25},
		description = "" ..core.colorize("#35cdff","Thompson SMG\n") ..core.colorize("#FFFFFF", "Ranged damage: 4\n") ..core.colorize("#FFFFFF", "accuracy: 75%\n") ..core.colorize("#FFFFFF", "knockback: 1\n") ..core.colorize("#FFFFFF", "Reload delay: 1.4\n")  ..core.colorize("#FFFFFF", "Clip size: 30/30\n") ..core.colorize("#FFFFFF", "Critical chance: 8%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n")  ..core.colorize("#FFFFFF", "Ammunition: 10mm auto/.45acp\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.1 (full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: smg\n") ..core.colorize("#FFFFFF", "Bullet velocity: 30"),
		range = 0,
		inventory_image = "thompson.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=4,knockback=1},
			gun_crit = 8,
			gun_critEffc = 2.0,
			suitable_ammo = {{modname .. ":rw_10mm",30},{modname .. ":rw_45acp",30}},
			gun_skill = {"smg_skill",65},
			gun_magazine = modname .. ":rw_machinepistol_mag",
			gun_unloaded = modname .. ":rw_thompson_r",
			gun_velocity = 30,
			gun_accuracy = 75,
			gun_cooldown = 0.1,
			gun_reload = 1.4/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1250,
			gun_smokeSize = 4,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "smg",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	})
end)()--]]

--end
--if minetest.settings:get_bool(modname .. "_rifles", true) then
--[[awp = (function()
	rw.register_tool(modname .. ":rw_awp_uld", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		range = 0,
		description = "" ..core.colorize("#35cdff","A.W.P. \n") ..core.colorize("#FFFFFF", "Ranged damage:18 + 35/sec of bullet lifetime\n")..core.colorize("#FFFFFF", "Accuracy: 100%\n") ..core.colorize("#FFFFFF", "knockback: 15\n") ..core.colorize("#FFFFFF", "Critical chance: 30%\n") ..core.colorize("#FFFFFF", "Critical efficiency: x3\n") ..core.colorize("#FFFFFF", "Ammunition: 7.62mm round/308.Winchester rounds\n") ..core.colorize("#FFFFFF", "Rate of fire: 1.0\n") ..core.colorize("#FFFFFF", "Reload time: 2.0\n") ..core.colorize("#FFFFFF", "Zoom: 12x\n") ..core.colorize("#be0d00", "Right-click to eject empty bullet shell\n") ..core.colorize("#FFFFFF", "Clip size: 10/10\n") ..core.colorize("#FFFFFF", "Enemy penetration:30%\n") ..core.colorize("#FFFFFF", "Block penetration:10%\n") ..core.colorize("#FFFFFF", "Gun type: Rifle\n") ..core.colorize("#FFFFFF", "Bullet velocity: 75"),
		groups = {not_in_creative_inventory = 1},
		inventory_image = "awp.png",
		weapon_zoom = 7.5,
		on_use = function(itemstack, user)
			rw.sound_play("empty", {pos = user:get_pos()})
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			eject_shell(itemstack,user,modname .. ":rw_awp_rld",1.0,modname .. "_rifle_reload_a",modname .. ":rw_empty_shell")
			return itemstack
		end,
	})
	
	
	rw.register_tool(modname .. ":rw_awp_r", {
		rw_next_reload = modname .. ":rw_awp_rr",
		load_sound = "rifle_clip_in",
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "awp_noclip.png",
	})
	rw.register_tool(modname .. ":rw_awp_rr", {
		rw_next_reload = modname .. ":rw_awp_rrr",
		load_sound = "rifle_reload_a",
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "awp.png",
	})
	rw.register_tool(modname .. ":rw_awp_rrr", {
		rw_next_reload = modname .. ":rw_awp",
		load_sound = "rifle_reload_b",
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "awp_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_awp_rld", {
		stack_max= 1,
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		loaded_gun = modname .. ":rw_awp",
		loaded_sound = "rifle_reload_b",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "awp_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_awp", {
		description = "" ..core.colorize("#35cdff","A.W.P. \n") ..core.colorize("#FFFFFF", "Ranged damage:18 + 35/sec of bullet lifetime\n")..core.colorize("#FFFFFF", "Accuracy: 100%\n") ..core.colorize("#FFFFFF", "knockback: 15\n") ..core.colorize("#FFFFFF", "Critical chance: 30%\n") ..core.colorize("#FFFFFF", "Critical efficiency: x3\n") ..core.colorize("#FFFFFF", "Ammunition: 7.62mm round/308.Winchester rounds\n") ..core.colorize("#FFFFFF", "Rate of fire: 1.0\n") ..core.colorize("#FFFFFF", "Reload time: 2.0\n") ..core.colorize("#FFFFFF", "Zoom: 12x\n") ..core.colorize("#27a600", "The gun is loaded!\n") ..core.colorize("#FFFFFF", "Clip size: 10/10\n") ..core.colorize("#FFFFFF", "Enemy penetration:30%\n") ..core.colorize("#FFFFFF", "Block penetration:10%\n") ..core.colorize("#FFFFFF", "Gun type: Rifle\n") ..core.colorize("#FFFFFF", "Bullet velocity: 75"),
		range = 0,
		weapon_zoom = 7.5,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		inventory_image = "awp.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=18,knockback=15},
			gun_crit = 30,
			gun_critEffc = 3.0,
			suitable_ammo = {{modname .. ":rw_762mm",10},{modname .. ":rw_308winchester",10}},
			gun_skill = {"rifle_skill",20},
			gun_magazine = modname .. ":rw_rifle_mag",
			gun_unloaded = modname .. ":rw_awp_r",
			gun_cooling = modname .. ":rw_awp_uld",
			gun_velocity = 75,
			gun_accuracy = 100,
			gun_cooldown = 1.0,
			gun_reload = 2.0/4,
			gun_projectiles = 1,
			has_shell = 0,
			gun_durability = 700,
			gun_smokeSize = 8,
			gun_dps = 35,
			gun_mob_penetration = 30,
			gun_node_penetration = 10,
			gun_unload_sound = "rifle_clip_out",
			gun_sound = "rifle_b",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	
	})
end)()

svd = (function()
	rw.register_tool(modname .. ":rw_svd_uld", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		range = 0,
		description = "" ..core.colorize("#35cdff","S.V.D. \n") ..core.colorize("#FFFFFF", "Ranged damage:17 + 30/sec of bullet lifetime\n")..core.colorize("#FFFFFF", "Accuracy: 100%\n") ..core.colorize("#FFFFFF", "knockback: 14\n") ..core.colorize("#FFFFFF", "Critical chance: 30%\n") ..core.colorize("#FFFFFF", "Critical efficiency: x3\n") ..core.colorize("#FFFFFF", "Ammunition: 7.62mm round\n") ..core.colorize("#FFFFFF", "Rate of fire: 1.0\n") ..core.colorize("#FFFFFF", "Reload time: 2.0\n") ..core.colorize("#FFFFFF", "Zoom: 10x\n") ..core.colorize("#be0d00", "Right-click to eject empty bullet shell\n") ..core.colorize("#FFFFFF", "Clip size: 10\n") ..core.colorize("#FFFFFF", "Enemy penetration:30%\n") ..core.colorize("#FFFFFF", "Block penetration:10%\n") ..core.colorize("#FFFFFF", "Gun type: Rifle\n") ..core.colorize("#FFFFFF", "Bullet velocity: 75"),
		groups = {not_in_creative_inventory = 1},
		inventory_image = "svd.png",
		weapon_zoom = 9,
		on_use = function(itemstack, user)
			rw.sound_play("empty", {pos = user:get_pos()})
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			eject_shell(itemstack,user,modname .. ":rw_svd_rld",1.0,modname .. "_rifle_reload_a",modname .. ":rw_empty_shell")
			return itemstack
		end,
	})
	
	
	rw.register_tool(modname .. ":rw_svd_r", {
		rw_next_reload = modname .. ":rw_svd_rr",
		load_sound = "rifle_clip_in",
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "svd_noclip.png",
	})
	rw.register_tool(modname .. ":rw_svd_rr", {
		rw_next_reload = modname .. ":rw_svd_rrr",
		load_sound = "rifle_reload_a",
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "svd.png",
	})
	rw.register_tool(modname .. ":rw_svd_rrr", {
		rw_next_reload = modname .. ":rw_svd",
		load_sound = "rifle_reload_b",
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "svd_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_svd_rld", {
		stack_max= 1,
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		loaded_gun = modname .. ":rw_svd",
		loaded_sound = "rifle_reload_b",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "svd_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_svd", {
		description = "" ..core.colorize("#35cdff","S.V.D. \n") ..core.colorize("#FFFFFF", "Ranged damage:17 + 30/sec of bullet lifetime\n")..core.colorize("#FFFFFF", "Accuracy: 100%\n") ..core.colorize("#FFFFFF", "knockback: 14\n") ..core.colorize("#FFFFFF", "Critical chance: 30%\n") ..core.colorize("#FFFFFF", "Critical efficiency: x3\n") ..core.colorize("#FFFFFF", "Ammunition: 7.62mm round\n") ..core.colorize("#FFFFFF", "Rate of fire: 1.0\n") ..core.colorize("#FFFFFF", "Reload time: 2.0\n") ..core.colorize("#FFFFFF", "Zoom: 10x\n") ..core.colorize("#27a600", "The gun is loaded!\n") ..core.colorize("#FFFFFF", "Clip size: 10\n") ..core.colorize("#FFFFFF", "Enemy penetration:30%\n") ..core.colorize("#FFFFFF", "Block penetration:10%\n") ..core.colorize("#FFFFFF", "Gun type: Rifle\n") ..core.colorize("#FFFFFF", "Bullet velocity: 75"),
		range = 0,
		weapon_zoom = 9,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		inventory_image = "svd.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=17,knockback=14},
			gun_crit = 30,
			gun_critEffc = 3.0,
			suitable_ammo = {{modname .. ":rw_762mm",10}},
			gun_skill = {"rifle_skill",20},
			gun_magazine = modname .. ":rw_rifle_mag",
			gun_unloaded = modname .. ":rw_svd_r",
			gun_cooling = modname .. ":rw_svd_uld",
			gun_velocity = 75,
			gun_accuracy = 100,
			gun_cooldown = 1.0,
			gun_reload = 2.0/4,
			gun_projectiles = 1,
			has_shell = 0,
			gun_durability = 700,
			gun_smokeSize = 8,
			gun_dps = 30,
			gun_mob_penetration = 30,
			gun_node_penetration = 10,
			gun_unload_sound = "rifle_clip_out",
			gun_sound = "rifle_b",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	
	})
end)()--]]

m200 = (function()
	rw.register_tool(modname .. ":rw_m200_uld", {
		stack_max= 1,
		wield_scale = {x=2.1,y=2.1,z=1.2},
		range = 0,
		description = "" ..core.colorize("#35cdff","m200 intervention \n") ..core.colorize("#FFFFFF", "Ranged damage:22 + 75/sec of bullet lifetime\n")..core.colorize("#FFFFFF", "Accuracy: 100%\n") ..core.colorize("#FFFFFF", "knockback: 20\n") ..core.colorize("#FFFFFF", "Critical chance: 33%\n") ..core.colorize("#FFFFFF", "Critical efficiency: x3.25\n") ..core.colorize("#FFFFFF", "Ammunition: .408 chey tac\n") ..core.colorize("#FFFFFF", "Rate of fire: 1.5\n") ..core.colorize("#FFFFFF", "Reload time: 2.5\n") ..core.colorize("#FFFFFF", "Zoom: 15x\n") ..core.colorize("#be0d00", "Right-click to eject empty bullet shell\n") ..core.colorize("#FFFFFF", "Clip size: 7\n") ..core.colorize("#FFFFFF", "Enemy penetration:45%\n") ..core.colorize("#FFFFFF", "Block penetration:15%\n") ..core.colorize("#FFFFFF", "Gun type: Rifle\n") ..core.colorize("#FFFFFF", "Bullet velocity: 80"),
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m200.png",
		weapon_zoom = 7.5,
		on_use = function(itemstack, user)
			rw.sound_play("empty", {pos = user:get_pos()})
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			eject_shell(itemstack,user,modname .. ":rw_m200_rld",1.0,modname .. "_rifle_reload_a",modname .. ":rw_empty_shell")
			return itemstack
		end,
	})
	
	
	rw.register_tool(modname .. ":rw_m200_r", {
		rw_next_reload = modname .. ":rw_m200_rr",
		load_sound = "rifle_clip_in",
		range = 0,
		wield_scale = {x=2.1,y=2.1,z=1.2},
		description = "",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m200_noclip.png",
	})
	rw.register_tool(modname .. ":rw_m200_rr", {
		rw_next_reload = modname .. ":rw_m200_rrr",
		load_sound = "rifle_reload_a",
		range = 0,
		wield_scale = {x=2.1,y=2.1,z=1.2},
		description = "",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m200.png",
	})
	rw.register_tool(modname .. ":rw_m200_rrr", {
		rw_next_reload = modname .. ":rw_m200",
		load_sound = "rifle_reload_b",
		range = 0,
		wield_scale = {x=2.1,y=2.1,z=1.2},
		description = "",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m200_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_m200_rld", {
		stack_max= 1,
		range = 0,
		wield_scale = {x=2.1,y=2.1,z=1.2},
		description = "",
		loaded_gun = modname .. ":rw_m200",
		loaded_sound = "rifle_reload_b",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m200_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_m200", {
		description = "" ..core.colorize("#35cdff","m200 intervention \n") ..core.colorize("#FFFFFF", "Ranged damage:22 + 75/sec of bullet lifetime\n")..core.colorize("#FFFFFF", "Accuracy: 100%\n") ..core.colorize("#FFFFFF", "knockback: 20\n") ..core.colorize("#FFFFFF", "Critical chance: 33%\n") ..core.colorize("#FFFFFF", "Critical efficiency: x3.25\n") ..core.colorize("#FFFFFF", "Ammunition: .408 chey tac\n") ..core.colorize("#FFFFFF", "Rate of fire: 1.5\n") ..core.colorize("#FFFFFF", "Reload time: 2.5\n") ..core.colorize("#FFFFFF", "Zoom: 15x\n") ..core.colorize("#27a600", "The gun is loaded!\n") ..core.colorize("#FFFFFF", "Clip size: 7\n") ..core.colorize("#FFFFFF", "Enemy penetration:45%\n") ..core.colorize("#FFFFFF", "Block penetration:15%\n") ..core.colorize("#FFFFFF", "Gun type: Rifle\n") ..core.colorize("#FFFFFF", "Bullet velocity: 80"),
		range = 0,
		weapon_zoom = 6,
		wield_scale = {x=2.1,y=2.1,z=1.2},
		inventory_image = "m200.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=22,knockback=20},
			gun_crit = 33,
			gun_critEffc = 3.25,
			suitable_ammo = {{modname .. ":rw_408cheytac",7}},
			gun_skill = {"rifle_skill",12},
			gun_magazine = modname .. ":rw_rifle_mag",
			gun_unloaded = modname .. ":rw_m200_r",
			gun_cooling = modname .. ":rw_m200_uld",
			gun_velocity = 80,
			gun_accuracy = 100,
			gun_cooldown = 1.5,
			gun_reload = 2.5/4,
			gun_projectiles = 1,
			has_shell = 0,
			gun_durability = 900,
			gun_smokeSize = 8,
			gun_dps = 75,
			gun_mob_penetration = 45,
			gun_node_penetration = 15,
			gun_unload_sound = "rifle_clip_out",
			gun_sound = "rifle_b",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	
	})
end)()

--end
--if minetest.settings:get_bool(modname .. "_heavy_machineguns", true) then
m60 = (function()
	rw.register_tool(modname .. ":rw_m60_r", {
		stack_max= 1,
		wield_scale = {x=2.0,y=2.0,z=1.4},
		description = "",
		rw_next_reload = modname .. ":rw_m60",
		load_sound = "rifle_clip_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m60_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_m60", {
		stack_max= 1,
		wield_scale = {x=2.0,y=2.0,z=1.4},
		description = "" ..core.colorize("#35cdff","m60\n") ..core.colorize("#FFFFFF", "Gun damage: 9\n") ..core.colorize("#FFFFFF", "accuracy: 65%\n") ..core.colorize("#FFFFFF", "Gun knockback: 7\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 13%\n")..core.colorize("#FFFFFF", "Critical efficiency: 3.0x\n")  ..core.colorize("#FFFFFF", "Reload delay: 1.0\n") ..core.colorize("#FFFFFF", "Clip size: 100\n")   ..core.colorize("#FFFFFF", "Ammunition: 7.62mm rounds\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.09(full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: heavy machinegun\n") ..core.colorize("#FFFFFF", "Block penetration: 12%\n")
		..core.colorize("#FFFFFF", "Enemy penetration: 27%\n") ..core.colorize("#FFFFFF", "Bullet velocity: 64"),
		range = 0,
		inventory_image = "m60.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=9,knockback=7},
			gun_crit = 13,
			gun_critEffc = 3.0,
			suitable_ammo = {{modname .. ":rw_762mm",100}},
			gun_skill = {"heavy_skill",60},
			gun_unloaded = modname .. ":rw_m60_r",
			gun_velocity = 64,
			gun_accuracy = 65,
			gun_cooldown = 0.09,
			gun_reload = 1.0,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 2750,
			gun_smokeSize = 5,
			gun_mob_penetration = 27,
			gun_node_penetration = 12,
			gun_unload_sound = "rifle_clip_out",
			gun_sound = "machinegun",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	
		inventory_image = "m60.png",
	})
end)()

--[[rpk = (function()
	rw.register_tool(modname .. ":rw_rpk_r", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_rpk_rr",
		load_sound = "rifle_clip_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "rpk_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_rpk_rr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_rpk_rrr",
		load_sound = "rifle_reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "rpk.png",
	})
	
	rw.register_tool(modname .. ":rw_rpk_rrr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_rpk",
		load_sound = "rifle_reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "rpk.png",
	})
	
	
	rw.register_tool(modname .. ":rw_rpk", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "" ..core.colorize("#35cdff","rpk\n") ..core.colorize("#FFFFFF", "Gun damage: 7\n") ..core.colorize("#FFFFFF", "accuracy: 60%\n") ..core.colorize("#FFFFFF", "Gun knockback: 6\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 12%\n")..core.colorize("#FFFFFF", "Critical efficiency: 3.0x\n")  ..core.colorize("#FFFFFF", "Reload delay: 2.0\n") ..core.colorize("#FFFFFF", "Clip size: 75\n")   ..core.colorize("#FFFFFF", "Ammunition: 7.62mm rounds\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.10(full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: heavy machinegun\n") ..core.colorize("#FFFFFF", "Block penetration: 10%\n")
		..core.colorize("#FFFFFF", "Enemy penetration: 25%\n") ..core.colorize("#FFFFFF", "Bullet velocity: 55"),
		range = 0,
		inventory_image = "rpk.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=7,knockback=6},
			gun_crit = 12,
			gun_critEffc = 3.0,
			suitable_ammo = {{modname .. ":rw_762mm",75}},
			gun_skill = {"heavy_skill",55},
			gun_magazine = modname .. ":rw_drum_mag",
			gun_unloaded = modname .. ":rw_rpk_r",
			gun_velocity = 55,
			gun_accuracy = 70,
			gun_cooldown = 0.1,
			gun_reload = 2.0/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 2250,
			gun_smokeSize = 5,
			gun_mob_penetration = 25,
			gun_node_penetration = 10,
			gun_unload_sound = "rifle_clip_out",
			gun_sound = "ak",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	
		inventory_image = "rpk.png",
	})
end)()--]]

minigun = (function()
	if minetest.settings:get_bool("minigun_aswell") or true then
	
		rw.register_tool(modname .. ":rw_minigun_r", {
			stack_max= 1,
			wield_scale = {x=3.0,y=3.0,z=3.0},
			description = "",
			rw_next_reload = modname .. ":rw_minigun",
			load_sound = "rifle_clip_in",
			range = 0,
			groups = {not_in_creative_inventory = 1},
			inventory_image = "minigun_rld.png",
		})
	
		rw.register_tool(modname .. ":rw_minigun", {
			stack_max= 1,
			wield_scale = {x=3.0,y=3.0,z=3.0},
			description = "" ..core.colorize("#35cdff","minigun\n") ..core.colorize("#FFFFFF", "Gun damage: 10\n") ..core.colorize("#FFFFFF", "accuracy: 50%\n") ..core.colorize("#FFFFFF", "Gun knockback: 8\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 14%\n")..core.colorize("#FFFFFF", "Critical efficiency: 3.0x\n")  ..core.colorize("#FFFFFF", "Reload delay: 2.0\n") ..core.colorize("#FFFFFF", "Clip size: 100\n")   ..core.colorize("#FFFFFF", "Ammunition: 7.62mm rounds\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.04(full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: heavy machinegun\n") ..core.colorize("#FFFFFF", "Block penetration: 15%\n")
			..core.colorize("#FFFFFF", "Enemy penetration: 33%\n") ..core.colorize("#FFFFFF", "Bullet velocity: 70"),
			range = 0,
			inventory_image = "minigun.png",
			RW_gun_capabilities = {
				automatic_gun = 1,
				gun_damage = {fleshy=10,knockback=8},
				gun_crit = 100,
				gun_critEffc = 10.0,
				suitable_ammo = {{modname .. ":rw_762mm",10000}},
				gun_skill = {"heavy_skill",100},
				gun_unloaded = modname .. ":rw_minigun_r",
				gun_velocity = 70,
				gun_accuracy = 100,
				gun_cooldown = 0.04,
				gun_reload = 0.5,
				gun_projectiles = 1,
				has_shell = 1,
				gun_gravity = 0,
				gun_durability = 4000,
				gun_smokeSize = 5,
				gun_mob_penetration = 33,
				gun_node_penetration = 15,
				gun_unload_sound = "rifle_clip_out",
				gun_sound = "machinegun",
			},
			on_secondary_use = function(itemstack, user, pointed_thing)
				rangedweapons_reload_gun(itemstack, user)
				return itemstack
			end,
	
			inventory_image = "minigun.png",
		})
	
	end
end)()
	
--end
--if minetest.settings:get_bool(modname .. "_revolvers", true) then
python = (function()
	--[[rw.register_tool(modname .. ":rw_remington_rld", {
		stack_max= 1,
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		description = "",
		loaded_gun = modname .. ":rw_remington",
		loaded_sound = "shotgun_reload_b",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "remington_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_remington", {
		description = "" ..core.colorize("#35cdff","Remington 870\n") ..core.colorize("#FFFFFF", "Ranged damage: 1\n") ..core.colorize("#FFFFFF", "projectiles: 4\n") ..core.colorize("#FFFFFF", "Gun gravity: 5\n") ..core.colorize("#FFFFFF", "Accuracy: 40%\n")..core.colorize("#FFFFFF", "knockback: 5\n") ..core.colorize("#FFFFFF", "Critical chance: 4%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n") ..core.colorize("#FFFFFF", "Ammunition: 12 gauge shells\n") ..core.colorize("#FFFFFF", "Pump delay: 0.8\n")..core.colorize("#FFFFFF", "Clip size: 4\n") ..core.colorize("#27a600", "Gun is ready to fire!\n") ..core.colorize("#fff21c", "Right-click to load in a bullet!\n")  ..core.colorize("#FFFFFF", "Gun type: shotgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 18"),
		range = 0,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		inventory_image = "remington.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=1,knockback=5},
			gun_crit = 4,
			gun_critEffc = 2.0,
			suitable_ammo = {{modname .. ":rw_shell",4}},
			gun_skill = {"shotgun_skill",20},
			gun_unloaded = modname .. ":rw_remington_rld",
			gun_cooling = modname .. ":rw_remington_uld",
			gun_velocity = 18,
			gun_accuracy = 40,
			gun_cooldown = 0.8,
			gun_gravity = 5,
			gun_reload = 0.25,
			gun_projectiles = 4,
			has_shell = 0,
			gun_durability = 275,
			gun_smokeSize = 14,
			gun_door_breaking = 1,
			gun_sound = "shotgun_shot",
			gun_unload_sound = "shell_insert",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_single_load_gun(itemstack, user, "")
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
	
	rw.register_tool(modname .. ":rw_remington_uld", {
		stack_max= 1,
		wield_scale = {x=1.9,y=1.9,z=1.1},
		range = 0,
		description = "" ..core.colorize("#35cdff","Remington 870\n") ..core.colorize("#FFFFFF", "Ranged damage: 1\n") ..core.colorize("#FFFFFF", "projectiles: 4\n") ..core.colorize("#FFFFFF", "Gun gravity: 5\n") ..core.colorize("#FFFFFF", "Accuracy: 40%\n")..core.colorize("#FFFFFF", "knockback: 5\n") ..core.colorize("#FFFFFF", "Critical chance: 4%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.0x\n") ..core.colorize("#FFFFFF", "Ammunition: 12 gauge shells\n") ..core.colorize("#FFFFFF", "Pump delay: 0.8\n")..core.colorize("#FFFFFF", "Clip size: 4\n") ..core.colorize("#be0d00", "Right-click, to eject the empty shell!\n") ..core.colorize("#fff21c", "Right-click to load in a bullet!\n")  ..core.colorize("#FFFFFF", "Gun type: shotgun\n") ..core.colorize("#FFFFFF", "Bullet velocity: 20"),
		inventory_image = "remington.png",
		groups = {not_in_creative_inventory = 1},
		on_use = function(user)
			rw.sound_play("empty", {user})
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			eject_shell(itemstack,user,modname .. ":rw_remington_rld",0.8,modname .. "_shotgun_reload_a",modname .. ":rw_empty_shell")
			return itemstack
		end,
	})--]]
	
	
	
	
	
	rw.register_tool(modname .. ":rw_python_rld", {
		stack_max= 1,
		range = 0,
		wield_scale = {x=1.25,y=1.25,z=1.1},
		description = "",
		loaded_gun = modname .. ":rw_python",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "python_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_python", {
		description = "" ..core.colorize("#35cdff","Colt Python \n") ..core.colorize("#FFFFFF", "Ranged damage: 15\n")..core.colorize("#FFFFFF", "Accuracy: 95%\n") ..core.colorize("#FFFFFF", "Gun knockback: 6\n") ..core.colorize("#FFFFFF", "Critical chance: 19%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.5x\n") ..core.colorize("#FFFFFF", "Ammunition: .357 Magnum rounds\n") ..core.colorize("#FFFFFF", "Reload time: 0.25\n") ..core.colorize("#FFFFFF", "Clip Size: 6\n")..core.colorize("#FFFFFF", "Gun type: Revolver\n")..core.colorize("#FFFFFF", "Block penetration: 5%\n")
		..core.colorize("#FFFFFF", "penetration: 15%\n") ..core.colorize("#FFFFFF", "Bullet velocity: 55"),
		range = 0,
		wield_scale = {x=1.25,y=1.25,z=1.1},
		inventory_image = "python.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=15,knockback=6},
			gun_crit = 19,
			gun_critEffc = 2.2,
			suitable_ammo = {{modname .. ":rw_357",6}},
			gun_skill = {"revolver_skill",40},
			gun_unloaded = modname .. ":rw_python_rld",
			gun_cooling = modname .. ":rw_python",
			gun_velocity = 55,
			gun_accuracy = 95,
			gun_cooldown = 0.2,
			gun_reload = 0.4,
			gun_projectiles = 1,
			gun_durability = 1000,
			gun_smokeSize = 7,
			gun_mob_penetration = 15,
			gun_node_penetration = 5,
			gun_unload_sound = "shell_insert",
			gun_sound = "deagle",
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_single_load_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

--[[taurus = (function()
	rw.register_tool(modname .. ":rw_taurus_rld", {
		stack_max= 1,
		range = 0,
		wield_scale = {x=1.25,y=1.25,z=1.1},
		description = "",
		loaded_gun = modname .. ":rw_taurus",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "taurus_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_taurus", {
		description = "" ..core.colorize("#35cdff","Taurus raging bull \n") ..core.colorize("#FFFFFF", "Ranged damage: 14\n")..core.colorize("#FFFFFF", "Accuracy: 97%\n") ..core.colorize("#FFFFFF", "Gun knockback: 8\n") ..core.colorize("#FFFFFF", "Critical chance: 22%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 3.1x\n") ..core.colorize("#FFFFFF", "Ammunition: .44 Magnum rounds\n") ..core.colorize("#FFFFFF", "Reload time: 0.25\n") ..core.colorize("#FFFFFF", "Clip Size: 6\n") ..core.colorize("#FFFFFF", "Block penetration: 8%\n")
		..core.colorize("#FFFFFF", "penetration: 24%\n") ..core.colorize("#FFFFFF", "Gun type: Revolver\n") ..core.colorize("#FFFFFF", "Bullet velocity: 64"),
		range = 0,
		wield_scale = {x=1.25,y=1.25,z=1.1},
		inventory_image = "taurus.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=14,knockback=8},
			gun_crit = 22,
			gun_critEffc = 3.1,
			suitable_ammo = {{modname .. ":rw_44",6}},
			gun_skill = {"revolver_skill",40},
			gun_unloaded = modname .. ":rw_taurus_rld",
			gun_cooling = modname .. ":rw_taurus",
			gun_velocity = 55,
			gun_accuracy = 97,
			gun_cooldown = 0.2,
			gun_reload = 0.4,
			gun_projectiles = 1,
			gun_durability = 1750,
			gun_smokeSize = 7,
			gun_mob_penetration = 24,
			gun_node_penetration = 8,
			gun_unload_sound = "shell_insert",
			gun_sound = "deagle",
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_single_load_gun(itemstack, user)
			return itemstack
		end,
	})
end)()--]]

--end
--if minetest.settings:get_bool(modname .. "_assault_rifles", true) then
--[[m16 = (function()
	rw.register_tool(modname .. ":rw_m16_r", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_m16_rr",
		load_sound = "handgun_mag_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m16_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_m16_rr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_m16_rrr",
		load_sound = "rifle_reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m16.png",
	})
	
	rw.register_tool(modname .. ":rw_m16_rrr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_m16",
		load_sound = "rifle_reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "m16.png",
	})
	
	
	rw.register_tool(modname .. ":rw_m16", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "" ..core.colorize("#35cdff","m16\n") ..core.colorize("#FFFFFF", "Gun damage: 6\n") ..core.colorize("#FFFFFF", "accuracy: 75%\n") ..core.colorize("#FFFFFF", "Gun knockback: 4\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 11%\n")..core.colorize("#FFFFFF", "Critical efficiency: 2.75x\n")  ..core.colorize("#FFFFFF", "Reload delay: 1.0\n") ..core.colorize("#FFFFFF", "Clip size: 20\n")   ..core.colorize("#FFFFFF", "Ammunition: 5.56mm rounds\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.067(full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: assault rifle\n")
		..core.colorize("#FFFFFF", "Enemy penetration: 10%\n") ..core.colorize("#FFFFFF", "Bullet velocity: 35"),
		range = 0,
		inventory_image = "m16.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=6,knockback=4},
			gun_crit = 11,
			gun_critEffc = 2.75,
			suitable_ammo = {{modname .. ":rw_556mm",20}},
			gun_skill = {"arifle_skill",55},
			gun_magazine = modname .. ":rw_assaultrifle_mag",
			gun_unloaded = modname .. ":rw_m16_r",
			gun_velocity = 35,
			gun_accuracy = 75,
			gun_cooldown = 0.067,
			gun_reload = 1.0/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1350,
			gun_smokeSize = 5,
			gun_mob_penetration = 10,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "smg",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	
		inventory_image = "m16.png",
	})
end)()

g36 = (function()
	rw.register_tool(modname .. ":rw_g36_r", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_g36_rr",
		load_sound = "handgun_mag_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "g36_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_g36_rr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_g36_rrr",
		load_sound = "rifle_reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "g36.png",
	})
	
	rw.register_tool(modname .. ":rw_g36_rrr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_g36",
		load_sound = "rifle_reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "g36.png",
	})
	
	
		rw.register_tool(modname .. ":rw_g36", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "" ..core.colorize("#35cdff","g36\n") ..core.colorize("#FFFFFF", "Gun damage: 7\n") ..core.colorize("#FFFFFF", "accuracy: 80%\n") ..core.colorize("#FFFFFF", "Gun knockback: 5\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 12%\n")..core.colorize("#FFFFFF", "Critical efficiency: 2.9x\n")  ..core.colorize("#FFFFFF", "Reload delay: 1.2\n") ..core.colorize("#FFFFFF", "Clip size: 30\n")   ..core.colorize("#FFFFFF", "Ammunition: 5.56mm rounds\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.08(full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: assault rifle\n") ..core.colorize("#FFFFFF", "Block penetration: 6%\n")
	..core.colorize("#FFFFFF", "Enemy penetration: 17%\n") ..core.colorize("#FFFFFF", "Bullet velocity: 40"),
		range = 0,
		inventory_image = "g36.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=7,knockback=5},
			gun_crit = 12,
			gun_critEffc = 2.9,
			suitable_ammo = {{modname .. ":rw_556mm",30}},
			gun_skill = {"arifle_skill",55},
			gun_magazine = modname .. ":rw_assaultrifle_mag",
			gun_unloaded = modname .. ":rw_g36_r",
			gun_velocity = 40,
			gun_accuracy = 80,
			gun_cooldown = 0.08,
			gun_reload = 1.2/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1500,
			gun_smokeSize = 5,
			gun_mob_penetration = 17,
			gun_node_penetration = 6,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "smg",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	
		inventory_image = "g36.png",
	})
end)()--]]

ak47 = (function()
	rw.register_tool(modname .. ":rw_ak47_r", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_ak47_rr",
		load_sound = "rifle_clip_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "ak47_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_ak47_rr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_ak47_rrr",
		load_sound = "rifle_reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "ak47.png",
	})
	
	rw.register_tool(modname .. ":rw_ak47_rrr", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "",
		rw_next_reload = modname .. ":rw_ak47",
		load_sound = "rifle_reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "ak47.png",
	})
	
	
	rw.register_tool(modname .. ":rw_ak47", {
		stack_max= 1,
		wield_scale = {x=1.75,y=1.75,z=1.3},
		description = "" ..core.colorize("#35cdff","AK-47\n") ..core.colorize("#FFFFFF", "Gun damage: 7\n") ..core.colorize("#FFFFFF", "accuracy: 77%\n") ..core.colorize("#FFFFFF", "Gun knockback: 5\n")  ..core.colorize("#FFFFFF", "Gun Critical chance: 12%\n")..core.colorize("#FFFFFF", "Critical efficiency: 2.9x\n")  ..core.colorize("#FFFFFF", "Reload delay: 1.4\n") ..core.colorize("#FFFFFF", "Clip size: 30\n")   ..core.colorize("#FFFFFF", "Ammunition: 7.62mm rounds\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.10(full-auto)\n") ..core.colorize("#FFFFFF", "Gun type: assault rifle\n") ..core.colorize("#FFFFFF", "Block penetration: 5%\n")
		..core.colorize("#FFFFFF", "Enemy penetration: 15%\n") ..core.colorize("#FFFFFF", "Bullet velocity: 40"),
		range = 0,
		inventory_image = "ak47.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=7,knockback=5},
			gun_crit = 12,
			gun_critEffc = 2.9,
			suitable_ammo = {{modname .. ":rw_762mm",30}},
			gun_skill = {"arifle_skill",50},
			gun_magazine = modname .. ":rw_assaultrifle_mag",
			gun_unloaded = modname .. ":rw_ak47_r",
			gun_velocity = 40,
			gun_accuracy = 77,
			gun_cooldown = 0.1,
			gun_reload = 1.4/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1200,
			gun_smokeSize = 5,
			gun_mob_penetration = 15,
			gun_node_penetration = 5,
			gun_unload_sound = "rifle_clip_out",
			gun_sound = "ak",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
	
		inventory_image = "ak47.png",
	})
end)()

--[[scar = (function()
	rw.register_tool(modname .. ":rw_scar_r", {
		stack_max= 1,
		wield_scale = {x=1.7,y=1.7,z=1.25},
		description = "",
		rw_next_reload = modname .. ":rw_scar_rr",
		load_sound = "rifle_clip_in",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "scar_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_scar_rr", {
		stack_max= 1,
		wield_scale = {x=1.7,y=1.7,z=1.25},
		description = "",
		rw_next_reload = modname .. ":rw_scar_rrr",
		load_sound = "rifle_reload_a",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "scar.png",
	})
	
	rw.register_tool(modname .. ":rw_scar_rrr", {
		stack_max= 1,
		wield_scale = {x=1.7,y=1.7,z=1.25},
		description = "",
		rw_next_reload = modname .. ":rw_scar",
		load_sound = "rifle_reload_b",
		range = 0,
		groups = {not_in_creative_inventory = 1},
		inventory_image = "scar.png",
	})
	
	rw.register_tool(modname .. ":rw_scar", {
		stack_max= 1,
		wield_scale = {x=1.7,y=1.7,z=1.25},
		description = "" ..core.colorize("#35cdff","FN SCAR 16\n") ..core.colorize("#FFFFFF", "Ranged damage: 9\n") ..core.colorize("#FFFFFF", "Accuracy: 85%\n") ..core.colorize("#FFFFFF", "Gun knockback: 6\n")..core.colorize("#FFFFFF", "Critical chance: 11%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 2.75x\n") ..core.colorize("#FFFFFF", "Ammunition: 7.62mm rounds/5.56mm rounds\n") ..core.colorize("#FFFFFF", "Reload delay: 1.2\n") ..core.colorize("#FFFFFF", "Clip size: 20/30\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.15\n") ..core.colorize("#FFFFFF", "Block penetration: 7%\n")
		..core.colorize("#FFFFFF", "penetration: 20%\n") ..core.colorize("#FFFFFF", "Gun type: Assault rifle\n") ..core.colorize("#FFFFFF", "Bullet velocity: 45"),
		range = 0,
		inventory_image = "scar.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_damage = {fleshy=9,knockback=6},
			gun_crit = 11,
			gun_critEffc = 2.75,
			suitable_ammo = {{modname .. ":rw_762mm",20},{modname .. ":rw_556mm",30}},
			gun_skill = {"arifle_skill",50},
			gun_magazine = modname .. ":rw_assaultrifle_mag",
			gun_unloaded = modname .. ":rw_scar_r",
			gun_velocity = 45,
			gun_accuracy = 85,
			gun_cooldown = 0.15,
			gun_reload = 1.2/4,
			gun_projectiles = 1,
			has_shell = 1,
			gun_gravity = 0,
			gun_durability = 1600,
			gun_smokeSize = 5,
			gun_mob_penetration = 20,
			gun_node_penetration = 7,
			gun_unload_sound = "rifle_clip_out",
			gun_sound = "ak",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		inventory_image = "scar.png",
	})
end)()--]]

--end

--if minetest.settings:get_bool(modname .. "_explosives", true) then
explosives = (function()
	-- mcl_explosions.explode(self.object:get_pos(), 4, {drop_chance=1.0}, self.object)
	
	local function he_boom (self)
		mcl_explosions.explode(self.object:get_pos(), 2, {drop_chance=1.0}, nil)
	end
	
	local function rocket_boom (self)
		mcl_explosions.explode(self.object:get_pos(), 3, {drop_chance=1.0}, nil)
	end
	
	local rangedweapons_rocket = {
		physical = false,
		timer = 0,
		visual = "sprite",
		visual_size = {x=0.0, y=0.0},
		textures = {"invisible.png"},
		_lastpos= {},
		collisionbox = {0, 0, 0, 0, 0, 0},
	}
	rangedweapons_rocket.on_step = function(self, dtime, pos)
		self.timer = self.timer + dtime
		local tiem = 0.002
		local pos = self.object:get_pos()
		local node = minetest.get_node(pos)
		if self.timer >= 0.002 then
			minetest.add_particle({
				pos = pos,
				velocity = 0,
				acceleration = {x=0, y=0, z=0},
				expirationtime = 0.04,
				size = 7,
				collisiondetection = false,
				vertical = false,
				texture = "rocket_fly.png",
				glow = 15,
			})
			minetest.add_particle({
				pos = pos,
				velocity = 0,
				acceleration = {x=0, y=6, z=0},
				expirationtime = 0.4,
				size = 4,
				collisiondetection = false,
				vertical = false,
				texture = "tnt_smoke.png",
				glow = 5,
			})
			tiem = tiem + 0.002
		end
		if self.timer >= 0.375 then
			local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 1.5)
			for k, obj in pairs(objs) do
				if obj:get_luaentity() ~= nil then
					if obj:get_luaentity().name ~= modname .. ":rw_rocket" and obj:get_luaentity().name ~= "__builtin:item" then
						rocket_boom(self)
						self.object:remove()
					end
				end
			end
		end
		if self._lastpos.x ~= nil then
			if minetest.registered_nodes[node.name].walkable then
				rocket_boom(self)
				self.object:remove()
			end
			if self.timer >= 7.5 then
				rocket_boom(self)
				self.object:remove()
			end
		end
		self._lastpos= {x = pos.x, y = pos.y, z = pos.z}
	end
	
	minetest.register_entity(modname .. ":rw_rocket", rangedweapons_rocket)
	
	
	local rangedweapons_he_grenade = {
		physical = false,
		timer = 0,
		visual = "sprite",
		visual_size = {x=0.0, y=0.0},
		textures = {"invisible.png"},
		_lastpos= {},
		collisionbox = {0, 0, 0, 0, 0, 0},
	}
	rangedweapons_he_grenade.on_step = function(self, dtime, pos)
		self.timer = self.timer + dtime
		local tiem = 0.002
		local pos = self.object:get_pos()
		local node = minetest.get_node(pos)
		if self.timer >= 0.002 then
			minetest.add_particle({
				pos = pos,
				velocity = 0,
				acceleration = {x=0, y=0, z=0},
				expirationtime = 0.04,
				size = 7,
				collisiondetection = false,
				vertical = false,
				texture = "rocket_fly.png",
				glow = 15,
			})
			minetest.add_particle({
				pos = pos,
				velocity = 0,
				acceleration = {x=0, y=16, z=0},
				expirationtime = 0.4,
				size = 4,
				collisiondetection = false,
				vertical = false,
				texture = "tnt_smoke.png",
				glow = 5,
			})
			tiem = tiem + 0.002
		end
		if self.timer >= 0.4 then
			local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 1.5)
			for k, obj in pairs(objs) do
				if obj:get_luaentity() ~= nil then
					if obj:get_luaentity().name ~= modname .. ":rw_he_grenade" and obj:get_luaentity().name ~= "__builtin:item" then
						rocket_boom(self)
						self.object:remove()
					end
				end
			end
		end
		if self._lastpos.x ~= nil then
			if minetest.registered_nodes[node.name].walkable then
				he_boom(self)
				self.object:remove()
			end
			if self.timer >= 7.5 then
				he_boom(self)
				self.object:remove()
			end
		end
		self._lastpos= {x = pos.x, y = pos.y, z = pos.z}
	end
	
	minetest.register_entity(modname .. ":rw_he_grenade", rangedweapons_he_grenade)
	
	
	
	rw.register_node(modname .. ":rw_barrel", {
		description = "" ..core.colorize("#35cdff","Explosive barrel\n")..core.colorize("#FFFFFF", "It will explode if shot by gun"),
		tiles = {
			"barrel_top.png",
			"barrel_top.png",
			"barrel_side.png",
			"barrel_side.png",
			"barrel_side.png",
			"barrel_side.png"
		},
		drawtype = "nodebox",
		paramtype = "light",
		groups = {choppy = 3, oddly_breakable_by_hand = 3},
		on_blast = function(pos)
			mcl_explosions.explode(pos, 3, {drop_chance=1.0}, nil)
		end,
		sounds = node_sound_wood_defaults(),
		node_box = {
			type = "fixed",
			fixed = {
				{-0.1875, -0.5, -0.5, 0.1875, 0.5, 0.5}, -- NodeBox1
				{-0.5, -0.5, -0.1875, 0.5, 0.5, 0.1875}, -- NodeBox2
				{-0.4375, -0.5, -0.3125, 0.4375, 0.5, 0.3125}, -- NodeBox3
				{-0.3125, -0.5, -0.4375, 0.3125, 0.5, 0.4375}, -- NodeBox4
				{-0.375, -0.5, -0.375, 0.375, 0.5, 0.375}, -- NodeBox5
			}
		}
	})
end)()

--[[m79 = (function()
	rw.register_tool(modname .. ":rw_m79_r", {
		stack_max= 1,
		wield_scale = {x=2.0,y=2.0,z=2.5},
		range = 0,
		description = "",
		groups = {not_in_creative_inventory = 1},
		rw_next_reload = modname .. ":rw_m79",
		load_sound = "reload_a",
		inventory_image = "m79_rld.png",
	})
	
	rw.register_tool(modname .. ":rw_m79", {
		description = "" ..core.colorize("#35cdff","m79\n") ..core.colorize("#FFFFFF", "Direct contact damage: 10\n")..core.colorize("#FFFFFF", "Accuracy: 92%\n")  ..core.colorize("#FFFFFF", "direct contact knockback: 25\n") ..core.colorize("#FFFFFF", "Gun crit chance: 8%\n")..core.colorize("#FFFFFF", "Critical efficiency: 3x\n") ..core.colorize("#FFFFFF", "Reload delay: 0.9\n")..core.colorize("#FFFFFF", "Clip size: 1\n") ..core.colorize("#FFFFFF", "Gun gravity: 5\n")..core.colorize("#FFFFFF", "Ammunition: 40mm grenades\n")..core.colorize("#FFFFFF", "Gun type: grenade launcher\n") ..core.colorize("#FFFFFF", "Bullet velocity: 20"),
		range = 0,
		wield_scale = {x=2.0,y=2.0,z=2.5},
		inventory_image = "m79.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=10,knockback=25},
			gun_crit = 8,
			gun_critEffc = 3.0,
			suitable_ammo = {{modname .. ":rw_40mm",1}},
			gun_skill = {"",1},
			gun_magazine = modname .. ":rw_shell_grenadedrop",
			gun_unloaded = modname .. ":rw_m79_r",
			gun_cooling = modname .. ":rw_m79",
			gun_velocity = 20,
			gun_accuracy = 92,
			gun_cooldown = 0.0,
			gun_reload = 0.9,
			gun_projectiles = 1,
			gun_smokeSize = 15,
			gun_durability = 100,
			gun_gravity = 5,
			gun_unload_sound = "handgun_mag_out",
			gun_sound = "rocket",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
end)()--]]

milkor = (function()
	rw.register_tool(modname .. ":rw_milkor_rld", {
		stack_max= 1,
		range = 0,
		wield_scale = {x=1.75,y=1.75,z=2.0},
		description = "",
		loaded_gun = modname .. ":rw_milkor",
		groups = {not_in_creative_inventory = 1},
		inventory_image = "milkor_rld.png",
	})
	
	
	rw.register_tool(modname .. ":rw_milkor", {
		description = "" ..core.colorize("#35cdff","Milkor MGL\n") ..core.colorize("#FFFFFF", "Direct contact damage: 15\n")..core.colorize("#FFFFFF", "Accuracy: 96%\n") ..core.colorize("#FFFFFF", "Direct contact knockback: 25\n") ..core.colorize("#FFFFFF", "Critical chance: 9%\n") ..core.colorize("#FFFFFF", "Critical efficiency: 3.0x\n") ..core.colorize("#FFFFFF", "Ammunition: 40mm grenades\n") ..core.colorize("#FFFFFF", "Reload time: 0.75\n") ..core.colorize("#FFFFFF", "Rate of fire: 0.35\n") ..core.colorize("#FFFFFF", "Gun gravity: 1\n") ..core.colorize("#FFFFFF", "Clip Size: 6\n")..core.colorize("#FFFFFF", "Gun type: grenade launcher\n") ..core.colorize("#FFFFFF", "Bullet velocity: 30"),
		range = 0,
		wield_scale = {x=1.75,y=1.75,z=2.0},
		inventory_image = "milkor.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=15,knockback=25},
			gun_crit = 9,
			gun_critEffc = 3.0,
			suitable_ammo = {{modname .. ":rw_40mm",6}},
			gun_skill = {"",1},
			gun_magazine = modname .. ":rw_shell_grenadedrop",
			gun_unloaded = modname .. ":rw_milkor_rld",
			gun_cooling = modname .. ":rw_milkor",
			gun_velocity = 30,
			gun_accuracy = 96,
			gun_cooldown = 0.35,
			gun_reload = 0.75,
			gun_projectiles = 1,
			gun_durability = 225,
			gun_smokeSize = 15,
			gun_gravity = 1,
			gun_unload_sound = "shell_insert",
			gun_sound = "rocket",
		},
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_single_load_gun(itemstack, user)
			return itemstack
		end,
	})
end)()

rpg = (function()
	rw.register_tool(modname .. ":rw_rpg_rld", {
		description = "" ..core.colorize("#35cdff","rpg7\n") ..core.colorize("#FFFFFF", "Direct contact damage: 20\n")..core.colorize("#FFFFFF", "Accuracy: 100%\n")  ..core.colorize("#FFFFFF", "direct contact knockback: 35\n") ..core.colorize("#FFFFFF", "Gun crit chance: 10%\n")..core.colorize("#FFFFFF", "Critical efficiency: 3x\n") ..core.colorize("#FFFFFF", "Reload delay: 1.0\n")..core.colorize("#FFFFFF", "Clip size: 1\n") ..core.colorize("#FFFFFF", "Gun gravity: 5\n")..core.colorize("#FFFFFF", "Ammunition: rockets\n")..core.colorize("#FFFFFF", "Gun type: rocket launcher\n") ..core.colorize("#FFFFFF", "Bullet velocity: 25"),
		range = 0,
		wield_scale = {x=2.5,y=2.5,z=3.75},
		groups = {not_in_creative_inventory = 1},
		inventory_image = "rpg_rld.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=20,knockback=35},
			gun_crit = 10,
			gun_critEffc = 3.0,
			suitable_ammo = {{modname .. ":rw_rocket",1}},
			gun_skill = {"",1},
			gun_unloaded = modname .. ":rw_rpg_rld",
			gun_cooling = modname .. ":rw_rpg",
			gun_velocity = 25,
			gun_accuracy = 100,
			gun_cooldown = 1.0,
			gun_reload = 1.0,
			gun_projectiles = 1,
			gun_smokeSize = 15,
			gun_durability = 150,
			gun_unload_sound = "",
			gun_sound = "rocket",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			rangedweapons_shoot_gun(itemstack, user)
			return itemstack
		end,
	})
	
	rw.register_tool(modname .. ":rw_rpg", {
		description = "" ..core.colorize("#35cdff","rpg7\n") ..core.colorize("#FFFFFF", "Direct contact damage: 20\n")..core.colorize("#FFFFFF", "Accuracy: 100%\n")  ..core.colorize("#FFFFFF", "direct contact knockback: 35\n") ..core.colorize("#FFFFFF", "Gun crit chance: 10%\n")..core.colorize("#FFFFFF", "Critical efficiency: 3x\n") ..core.colorize("#FFFFFF", "Reload delay: 1.0\n")..core.colorize("#FFFFFF", "Clip size: 1\n") ..core.colorize("#FFFFFF", "Gun gravity: 5\n")..core.colorize("#FFFFFF", "Ammunition: rockets\n")..core.colorize("#FFFFFF", "Gun type: rocket launcher\n") ..core.colorize("#FFFFFF", "Bullet velocity: 25"),
		range = 0,
		wield_scale = {x=2.5,y=2.5,z=3.75},
		inventory_image = "rpg.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=20,knockback=35},
			gun_crit = 10,
			gun_critEffc = 3.0,
			suitable_ammo = {{modname .. ":rw_rocket",1}},
			gun_skill = {"",1},
			gun_unloaded = modname .. ":rw_rpg_rld",
			gun_cooling = modname .. ":rw_rpg",
			gun_velocity = 25,
			gun_accuracy = 100,
			gun_cooldown = 1.0,
			gun_reload = 1.0,
			gun_projectiles = 1,
			gun_smokeSize = 15,
			gun_durability = 150,
			gun_unload_sound = "",
			gun_sound = "rocket",
			gun_unload_sound = "shell_insert",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		-- on_use = function(itemstack, user, pointed_thing)
		-- 	rangedweapons_shoot_gun(itemstack, user)
		-- 	return itemstack
		-- end,
	})
end)()

adminrpg = (function()
	rw.register_tool(modname .. ":rw_super_rpg_rld", {
		description = "" ..core.colorize("#35cdff","rpg7\n") ..core.colorize("#FFFFFF", "Direct contact damage: 20\n")..core.colorize("#FFFFFF", "Accuracy: 100%\n")  ..core.colorize("#FFFFFF", "direct contact knockback: 35\n") ..core.colorize("#FFFFFF", "Gun crit chance: 10%\n")..core.colorize("#FFFFFF", "Critical efficiency: 3x\n") ..core.colorize("#FFFFFF", "Reload delay: 1.0\n")..core.colorize("#FFFFFF", "Clip size: 1\n") ..core.colorize("#FFFFFF", "Gun gravity: 5\n")..core.colorize("#FFFFFF", "Ammunition: rockets\n")..core.colorize("#FFFFFF", "Gun type: rocket launcher\n") ..core.colorize("#FFFFFF", "Bullet velocity: 25"),
		range = 0,
		wield_scale = {x=2.5,y=2.5,z=3.75},
		groups = {not_in_creative_inventory = 1},
		inventory_image = "rpg_rld.png",
		RW_gun_capabilities = {
			gun_damage = {fleshy=100,knockback=35},
			gun_crit = 100,
			gun_critEffc = 100,
			suitable_ammo = {{modname .. ":rw_rocket",10000}},
			gun_skill = {"",1},
			gun_unloaded = modname .. ":rw_super_rpg_rld",
			gun_cooling = modname .. ":rw_super_rpg",
			gun_velocity = 50,
			gun_accuracy = 100,
			gun_cooldown = 0.04,
			gun_reload = 0.5,
			gun_projectiles = 1,
			gun_smokeSize = 5,
			gun_durability = 15000,
			gun_unload_sound = "",
			gun_sound = "rocket",

			automatic_gun = 1,
			gun_gravity = 0,
			gun_mob_penetration = 33,
			gun_node_penetration = 15,
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		-- on_use = function(itemstack, user, pointed_thing)
		-- 	rangedweapons_shoot_gun(itemstack, user)
		-- 	return itemstack
		-- end,
	})
	
	rw.register_tool(modname .. ":rw_super_rpg", {
		description = "" ..core.colorize("#35cdff","super rpg7\n") ..core.colorize("#FFFFFF", "Direct contact damage: 100\n")..core.colorize("#FFFFFF", "Accuracy: 100%\n")  ..core.colorize("#FFFFFF", "direct contact knockback: 35\n") ..core.colorize("#FFFFFF", "Gun crit chance: 100%\n")..core.colorize("#FFFFFF", "Critical efficiency: 100x\n") ..core.colorize("#FFFFFF", "Reload delay: 0.5\n")..core.colorize("#FFFFFF", "Clip size: 10000\n") ..core.colorize("#FFFFFF", "Gun gravity: 0\n")..core.colorize("#FFFFFF", "Ammunition: rockets\n")..core.colorize("#FFFFFF", "Gun type: rocket launcher\n") ..core.colorize("#FFFFFF", "Bullet velocity: 50"),
		range = 0,
		wield_scale = {x=2.5,y=2.5,z=3.75},
		inventory_image = "rpg.png",
		RW_gun_capabilities = {
			automatic_gun = 1,
			gun_gravity = 0,
			gun_mob_penetration = 33,
			gun_node_penetration = 15,


			gun_damage = {fleshy=100,knockback=35},
			gun_crit = 100,
			gun_critEffc = 100,
			suitable_ammo = {{modname .. ":rw_rocket",10000}},
			gun_skill = {"",1},
			gun_unloaded = modname .. ":rw_super_rpg_rld",
			gun_cooling = modname .. ":rw_super_rpg",
			gun_velocity = 50,
			gun_accuracy = 100,
			gun_cooldown = 0.04,
			gun_reload = 0.5,
			gun_projectiles = 1,
			gun_smokeSize = 5,
			gun_durability = 15000,
			gun_unload_sound = "",
			gun_sound = "rocket",
			gun_unload_sound = "shell_insert",
		},
		on_secondary_use = function(itemstack, user, pointed_thing)
			rangedweapons_reload_gun(itemstack, user)
			return itemstack
		end,
		-- on_use = function(itemstack, user, pointed_thing)
		-- 	rangedweapons_shoot_gun(itemstack, user)
		-- 	return itemstack
		-- end,
	})
end)()

hand_grenade = (function()
	rw.register_craftitem(modname .. ":rw_pin", {
		wield_scale = {x=2.5,y=2.5,z=1.0},
		inventory_image = "pin.png",
	})
	local rangedweapons_grenade_pin = {
		physical = false,
		timer = 0,
		visual = "wielditem",
		visual_size = {x=0.15, y=0.15},
		textures = {modname .. ":rw_pin"},
		_lastpos= {},
		collisionbox = {0, 0, 0, 0, 0, 0},
	}
	rangedweapons_grenade_pin.on_step = function(self, dtime, pos)
		self.timer = self.timer + dtime
		local pos = self.object:get_pos()
		local node = minetest.get_node(pos)
		if self._lastpos.x ~= nil then
			if minetest.registered_nodes[node.name].walkable then
			self.object:remove()
				rw.sound_play("bulletdrop", {pos = self._lastpos, gain = 0.8})
				end
		end
		self._lastpos= {x = pos.x, y = pos.y, z = pos.z}
	end
	
	
	
	minetest.register_entity(modname .. ":rw_grenade_pin", rangedweapons_grenade_pin)
	
	local function grenade_boom (self)
		local function test()
			mcl_explosions.explode(self.object:get_pos(), 3, {drop_chance=1.0}, nil)
		end
		
		if not pcall(test) then
			mcl_explosions.explode(self:get_pos(), 3, {drop_chance=1.0}, nil)
		end
	end
		local gtimer = 0
	rw.register_craftitem(modname .. ":rw_hand_grenade", {
		stack_max= 1,
		wield_scale = {x=1.1,y=1.1,z=1.05},
			description = "" ..core.colorize("#35cdff","Hand grenade\n") ..core.colorize("#FFFFFF", "Explosion radius: 3\n")..core.colorize("#FFFFFF", "Throw force: 12\n")  ..core.colorize("#FFFFFF", "Grenade gravitational pull: 6\n") ..core.colorize("#ffc000", "Right-click to unpin, Left click to throw after unpinning\n") ..core.colorize("#ffc000", "Thrown or not, it will explode after 3 secons from unpinning, be careful!"),
		range = 0,
		inventory_image = "hand_grenade.png",
		on_secondary_use = function(itemstack, user, pointed_thing)
	if minetest.find_node_near(user:get_pos(), 10,modname .. ":rw_antigun_block")
	then
		minetest.chat_send_player(user:get_player_name(), "" ..core.colorize("#ff0000","Grenades are prohibited in this area!"))
				return itemstack
			end
	
			gtimer = 0
		rw.sound_play("reload_a", {pos = user:get_pos()})
			itemstack = modname .. ":rw_hand_grenade_nopin"
	local pos = user:get_pos()
	pos.y = pos.y + 1.5
	local pinEnt = minetest.add_entity(pos, modname .. ":rw_grenade_pin")
	if pinEnt then
	local dir = user:get_look_dir()
	local yaw = user:get_look_horizontal()
	local svertical = user:get_look_vertical()
	pinEnt:set_velocity({x=dir.x * -10, y=dir.y * -10, z=dir.z * -10})
	pinEnt:set_acceleration({x=dir.x * -5, y= -10, z=dir.z * -5})
	pinEnt:set_rotation({x=0,y=yaw - math.pi/2,z=-svertical})
	end
		 return itemstack end,
	})
	
	
	rw.register_craftitem(modname .. ":rw_hand_grenade_nopin", {
		stack_max= 1,
		wield_scale = {x=1.1,y=1.1,z=1.05},
		description = "***HURRY UP AND THROW IT!!!***",
		range = 0,
		inventory_image = "hand_grenade_nopin.png",
		groups = {not_in_creative_inventory = 1},
	
		on_use = function(itemstack, user, pointed_thing)
			local playeriscreative = minetest.is_creative_enabled(user:get_player_name())
			
			local pos = user:get_pos()
			local dir = user:get_look_dir()
			local yaw = user:get_look_horizontal()
			if pos and dir and yaw then
				pos.y = pos.y + 1.6
				local obj = minetest.add_entity(pos, modname .. ":rw_grenade")
				if obj then
					obj:set_velocity({x=dir.x * 12, y=dir.y * 12, z=dir.z * 12})
					obj:set_acceleration({x=0, y=-6, z=0})
					obj:set_yaw(yaw - math.pi/2)
					btimer = gtimer
					local ent = obj:get_luaentity()
					if ent then
						ent.player = ent.player or user
						if not playeriscreative then
							itemstack = ""
						else
							itemstack = modname .. ":rw_hand_grenade"
						end
					end
				end
			end
			return itemstack
		end,
	})
	
	
	
	minetest.register_globalstep(function(dtime, player, pos)
		gtimer = gtimer + dtime;
		if gtimer >= 3.0 then
			for _, player in pairs(minetest.get_connected_players()) do
				local pos = player:get_pos()
				if player:get_wielded_item():get_name() == modname .. ":rw_hand_grenade_nopin" then
					player:set_wielded_item(modname .. ":rw_hand_grenade")
					gtimer = 0
					grenade_boom(player)
				end
			end
		end
	end)
	
	local rangedweapons_grenade = {
		physical = true,
		btimer = 0,
		timer = 0,
		hp_max = 420,
		visual = "sprite",
		visual_size = {x=0.5, y=0.5},
		textures = {"hand_grenade_nopin.png"},
		_lastpos= {},
		collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	}
	rangedweapons_grenade.on_step = function(self, dtime, pos)
		local pos = self.object:get_pos()
		local node = minetest.get_node(pos)
		local btimer = btimer or 0
		self.timer = self.timer + dtime
		if self.timer > (3.0 - btimer) then
			grenade_boom(self)
			self.object:remove()
		end
		self._lastpos= {x = pos.x, y = pos.y, z = pos.z}
	
	end
	
	
	
	minetest.register_entity(modname .. ":rw_grenade", rangedweapons_grenade)
end)()

--end

--if minetest.settings:get_bool(modname .. "_glass_breaking", true) then
--forcegun = (function()
--end)()

--	dofile(modpath .. "/glass_breaking.lua")
--[[ What is this good for?
minetest.register_abm({
	nodenames = {modname .. ":rw_broken_glass"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if minetest.get_node(pos).name == modname .. ":rw_broken_glass" then
			node.name = "default:glass"
			minetest.set_node(pos, node)
		end
	end
})
end
--]]
--end

local rangedweapons_empty_shell = {
	physical = false,
	timer = 0,
	visual = "wielditem",
	visual_size = {x = 0.3, y = 0.3},
	textures = {modname .. ":rw_shelldrop"},
	_lastpos = {},
	collisionbox = {0, 0, 0, 0, 0, 0}
}
rangedweapons_empty_shell.on_step = function(self, dtime, pos)
	self.timer = self.timer + dtime
	local pos = self.object:get_pos()
	local node = minetest.get_node(pos)
	if self._lastpos.y ~= nil then
		if minetest.registered_nodes[node.name] ~= nil then
			if minetest.registered_nodes[node.name].walkable then
				local vel = self.object:get_velocity()
				local acc = self.object:get_acceleration()
				self.object:set_velocity({x = vel.x * -0.3, y = vel.y * -0.75, z = vel.z * -0.3})
				rw.sound_play("shellhit", {pos = self._lastpos, gain = 0.8})
				self.object:set_acceleration({x = acc.x, y = acc.y, z = acc.z})
			end
		end
	end
	if self.timer > 1.69 then
		rw.sound_play("bulletdrop", {pos = self._lastpos, gain = 0.8})
		self.object:remove()
	end
	self._lastpos = {x = pos.x, y = pos.y, z = pos.z}
end

minetest.register_entity(modname .. ":rw_empty_shell", rangedweapons_empty_shell)

minetest.register_abm(
	{
		nodenames = {"doors:hidden"},
		interval = 1,
		chance = 1,
		action = function(pos, node)
			pos.y = pos.y - 1
			if minetest.get_node(pos).name == "air" then
				pos.y = pos.y + 1
				node.name = "air"
				minetest.set_node(pos, node)
			end
		end
	}
)

minetest.register_on_joinplayer(
	function(player)
		hit =
			player:hud_add(
			{
				hud_elem_type = "image",
				text = "empty_icon.png",
				scale = {x = 2, y = 2},
				position = {x = 0.5, y = 0.5},
				offset = {x = 0, y = 0},
				alignment = {x = 0, y = 0}
			}
		)
		scope_hud =
			player:hud_add(
			{
				hud_elem_type = "image",
				position = {x = 0.5, y = 0.5},
				scale = {x = -100, y = -100},
				text = "empty_icon.png"
			}
		)
	end
)

local timer = 0
minetest.register_globalstep(
	function(dtime)
		timer = timer + dtime
		if timer >= 1.0 then
			for _, player in pairs(minetest.get_connected_players()) do
				player:hud_change(hit, "text", "empty_icon.png")
				timer = 0
			end
		end
	end
)

