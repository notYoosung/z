local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

--https://gist.github.com/2xlink/b61d953865126727cd26838c81edd102

local boat_visual_size = {x = 1, y = 1, z = 1}
local paddling_speed = 22
local boat_y_offset = 0.35
local boat_y_offset_ground = boat_y_offset + 0.6
local boat_side_offset = 1.001
local boat_max_hp = 4

local function is_group(pos, group)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, group) ~= 0
end

local function is_river_water(p)
	local n = minetest.get_node(p).name
	if n == "mclx_core:river_water_source" or n == "mclx_core:river_water_flowing" then
		return true
	end
end

local function is_ice(pos)
	return is_group(pos, "ice")
end

local function is_fire(pos)
	return is_group(pos, "set_on_fire")
end

local function get_sign(i)
	if i == 0 then
		return 0
	else
		return i / math.abs(i)
	end
end

local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end

local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

local function check_object(obj)
	return obj and (obj:is_player() or obj:get_luaentity()) and obj
end

local function get_visual_size(obj)
	return obj:is_player() and {x = 1, y = 1, z = 1} or obj:get_luaentity()._old_visual_size or obj:get_properties().visual_size
end

local function set_attach(boat)
	-- for k, v in pairs(boat) do
	-- 	minetest.log(tostring(k) .. " : " .. tostring(v))
	-- end
	boat._driver:set_attach(boat.object, "",
		{x = 0, y = 1.5, z = 1}, {x = 0, y = 0, z = 0})
end

local function set_double_attach(boat)
	boat._driver:set_attach(boat.object, "",
		{x = 0, y = 0.42, z = 0.8}, {x = 0, y = 0, z = 0})
	if boat._passenger:is_player() then
		boat._passenger:set_attach(boat.object, "",
			{x = 0, y = 0.42, z = -6.2}, {x = 0, y = 0, z = 0})
	else
		boat._passenger:set_attach(boat.object, "",
			{x = 0, y = 0.42, z = -4.5}, {x = 0, y = 270, z = 0})
	end
end
local function set_choat_attach(boat)
	boat._driver:set_attach(boat.object, "",
		{x = 0, y = 1.5, z = 1}, {x = 0, y = 0, z = 0})
end

local function attach_object(self, obj)
	if self == nil or obj == nil then minetest.log("z_snowball obj nil") return end
	if self._driver and not self._inv_id then
		if self._driver:is_player() then
			self._passenger = obj
		else
			self._passenger = self._driver
			self._driver = obj
		end
		set_double_attach(self)
	else
		self._driver = obj
		if self._inv_id then
			set_choat_attach(self)
		else
			-- minetest.log("attached")
			set_attach(self)
		end
	end

	local visual_size = get_visual_size(obj)
	-- local yaw = self.object:get_yaw()
	self._visual_size = visual_size
	obj:set_properties({visual_size = vector.divide(visual_size, boat_visual_size)})

	if obj:is_player() then
		local name = obj:get_player_name()
		mcl_player.players[obj].attached = true
		--obj:set_eye_offset({x=0, y=-5.5, z=0},{x=0, y=-4, z=0})
		minetest.after(0.2, function(name)
			local player = minetest.get_player_by_name(name)
			if player then
				mcl_player.player_set_animation(player, "sit" , 30)
			end
		end, name)
		-- obj:set_look_horizontal(yaw)
		-- mcl_title.set(obj, "actionbar", {text=S("Sneak to dismount"), color="white", stay=60})
	else
		obj:get_luaentity()._old_visual_size = visual_size
	end
end

local function detach_object(obj, change_pos)
	if change_pos then change_pos = vector.new(0, 0.0, 0) end
	return mcl_util.detach_object(obj, change_pos)
end



-- The snowball entity
local snowball_ENTITY={
	initial_properties = {
		physical = false,
		textures = {"mcl_throwing_snowball.png"},
		visual_size = {x=1, y=1},
		collisionbox = {0,0,0,0,0,0},
		pointable = false,
		should_drive = function (self)
			return true
		end,
	},

	timer=0,
	get_staticdata = mcl_throwing.get_staticdata,
	on_activate = mcl_throwing.on_activate,
	_thrower = nil,

	_lastpos={},



}


local function check_object_hit(self, pos, dmg)
	for _,object in pairs(minetest.get_objects_inside_radius(pos, 1.5)) do

		local entity = object:get_luaentity()

		if entity
		and entity.name ~= self.object:get_luaentity().name then

			if object:is_player() and self._thrower ~= object:get_player_name() then
				self.object:remove()
				return true
			elseif (entity.is_mob == true or entity._hittable_by_projectile) and (self._thrower ~= object) then
				local pl = self._thrower and self._thrower.is_player and self._thrower or type(self._thrower) == "string" and minetest.get_player_by_name(self._thrower)
				if pl then
					object:punch(pl, 1.0, {
						full_punch_interval = 1.0,
						damage_groups = dmg,
					}, nil)
					return true
				end
			end
		end
	end
	return false
end


local function snowball_particles(pos, vel)
	local vel = vector.normalize(vector.multiply(vel, -1))
	minetest.add_particlespawner({
		amount = 20,
		time = 0.001,
		minpos = pos,
		maxpos = pos,
		minvel = vector.add({x=-2, y=3, z=-2}, vel),
		maxvel = vector.add({x=2, y=5, z=2}, vel),
		minacc = {x=0, y=-9.81, z=0},
		maxacc = {x=0, y=-9.81, z=0},
		minexptime = 1,
		maxexptime = 3,
		minsize = 0.7,
		maxsize = 0.7,
		collisiondetection = true,
		collision_removal = true,
		object_collision = false,
		texture = "weather_pack_snow_snowflake"..math.random(1,2)..".png",
	})
end


local function attach_driver(self, clicker)
	-- mcl_title.set(clicker, "actionbar", {text=S("Sneak to dismount"), color="white", stay=60})
	-- self.object:set_properties({stepheight = 1.1})
	-- self.object:set_properties({selectionbox = {0,0,0,0,0,0}})
	self:attach(clicker)
end

local function detach_driver(self)
	-- self.object:set_properties({stepheight = 0.6})
	-- self.object:set_properties({selectionbox = self.object:get_properties().collisionbox})
	if self.driver then
		-- if extended_pet_control and self.order ~= "sit" then self:toggle_sit(self.driver) end
		mcl_mobs.detach(self.driver, {x=0, y=0, z=0})
	end
end




-- Snowball on_step()--> called when snowball is moving.
local function snowball_on_step(self, dtime)
	if not self.object then return end
	self.timer = self.timer + dtime
	local pos = self.object:get_pos()
	local vel = self.object:get_velocity()
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]

	-- Destroy when hitting a solid node
	if self._lastpos.x~=nil then
		if (def and def.walkable) or not def then
			minetest.sound_play("mcl_throwing_snowball_impact_hard", { pos = pos, max_hear_distance=16, gain=0.7 }, true)
			snowball_particles(self._lastpos, vel)
			local obj = self._driver or self._passenger
			if obj then
				if obj:is_player() then
					local name = obj:get_player_name()
					mcl_player.players[obj].attached = false
					--obj:set_eye_offset({ x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
					minetest.after(0.2, function(name)
						local player = minetest.get_player_by_name(name)
						if player then
							mcl_player.player_set_animation(player, "stand", 30)
						end
					end, name)
					-- obj:set_velocity(self.object:get_velocity())
				else
					obj:get_luaentity().visual_size = obj._old_visual_size
				end
			end
			detach_object(self.object)
			self.object:remove()
			if mod_target and node.name == "mcl_target:target_off" then
				mcl_target.hit(vector.round(pos), 0.4) --4 redstone ticks
			end
			return
		end
	end
	if check_object_hit(self, pos, {snowball_vulnerable = 3}) then
		minetest.sound_play("mcl_throwing_snowball_impact_soft", { pos = pos, max_hear_distance=16, gain=0.7 }, true)
		snowball_particles(pos, vel)
		detach_object(self.object)
		local obj = self._driver or self._passenger
		if obj then
			if obj:is_player() then
				local name = obj:get_player_name()
				mcl_player.players[obj].attached = false
				--obj:set_eye_offset({ x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
				minetest.after(0.2, function(name)
					local player = minetest.get_player_by_name(name)
					if player then
						mcl_player.player_set_animation(player, "stand", 30)
					end
				end, name)
				-- obj:set_velocity(self.object:get_velocity())
			else
				obj:get_luaentity().visual_size = obj._old_visual_size
			end
		end
		self.object:remove()
		return
	end
	self._lastpos={x=pos.x, y=pos.y, z=pos.z} -- Set _lastpos-->Node will be added at last pos outside the node
end


snowball_ENTITY.on_step = snowball_on_step


minetest.register_entity(modname .. ":snowball_entity", snowball_ENTITY)
-- mcl_mobs.register_mob(modname .. ":snowball_entity", snowball_ENTITY)


local how_to_throw = S("Use the punch key to throw.")



local function get_player_throw_function(_, velocity)
	local function func(item, player, _)
		local playerpos = player:get_pos()
		local dir = player:get_look_dir()
		-- minetest.log(tostring(item))
		local obj = mcl_throwing.throw(item, {x=playerpos.x, y=playerpos.y+0, z=playerpos.z}, dir, velocity, player:get_player_name())
		attach_object(obj:get_luaentity(), player)
		if not minetest.is_creative_enabled(player:get_player_name()) then
			item:take_item()
		end
		return item
	end
	return func
end
local function on_use(item, player, _)
	get_player_throw_function(modname .. ":snowball_entity")(item, player, _)
end

-- Snowball
minetest.register_craftitem(modname .. ":snowball", {
	description = S("Ridable Snowball"),
	_tt_help = S("Throwable"),
	_doc_items_longdesc = S("Snowballs can be thrown or launched from a dispenser for fun. Hitting something with a snowball does nothing."),
	_doc_items_usagehelp = how_to_throw,
	inventory_image = "mcl_throwing_snowball.png",
	stack_max = 16,
	groups = { weapon_ranged = 1 },
	on_use = on_use,
	_on_dispense = mcl_throwing.dispense_function,
})

mcl_throwing.register_throwable_object(modname .. ":snowball", modname .. ":snowball_entity", 22)


--apple slices from crafting w/ axe
-- param2 screw