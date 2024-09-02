local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)







local function player_collision(player)
	local pos = player:get_pos()
	--local vel = player:get_velocity()
	local x = 0
	local z = 0
	local width = .75

	for _, object in pairs(minetest.get_objects_inside_radius(pos, width)) do
		local ent = object:get_luaentity()
		if (object:is_player() or (ent and ent.is_mob and object ~= player)) then
			local pos2  = object:get_pos()
			local vec   = { x = pos.x - pos2.x, z = pos.z - pos2.z }
			local force = (width + 0.5) - vector.distance(
				{ x = pos.x, y = 0, z = pos.z },
				{ x = pos2.x, y = 0, z = pos2.z })

			x           = x + (vec.x * force)
			z           = z + (vec.z * force)
		end
	end
	return { x, z }
end

local function dir_to_pitch(dir)
	local xz = math.abs(dir.x) + math.abs(dir.z)
	return -math.atan2(-dir.y, xz)
end

local function limit_vel_yaw(player_vel_yaw, yaw)
	if player_vel_yaw < 0 then
		player_vel_yaw = player_vel_yaw + 360
	end

	if yaw < 0 then
		yaw = yaw + 360
	end

	if math.abs(player_vel_yaw - yaw) > 40 then
		local player_vel_yaw_nm, yaw_nm = player_vel_yaw, yaw
		if player_vel_yaw > yaw then
			player_vel_yaw_nm = player_vel_yaw - 360
		else
			yaw_nm = yaw - 360
		end
		if math.abs(player_vel_yaw_nm - yaw_nm) > 40 then
			local diff = math.abs(player_vel_yaw - yaw)
			if diff > 180 and diff < 185 or diff < 180 and diff > 175 then
				player_vel_yaw = yaw
			elseif diff < 180 then
				if player_vel_yaw < yaw then
					player_vel_yaw = yaw - 40
				else
					player_vel_yaw = yaw + 40
				end
			else
				if player_vel_yaw < yaw then
					player_vel_yaw = yaw + 40
				else
					player_vel_yaw = yaw - 40
				end
			end
		end
	end

	if player_vel_yaw < 0 then
		player_vel_yaw = player_vel_yaw + 360
	elseif player_vel_yaw > 360 then
		player_vel_yaw = player_vel_yaw - 360
	end

	return player_vel_yaw
end







minetest.register_on_joinplayer(function(player)
    -- mcl_player.players[player].
end)

local player_props_crawling = {
	collisionbox = { -0.312, 0, -0.312, 0.312, 0.8, 0.312 },
	eye_height = 0.6,
	nametag_color = { r = 225, b = 225, a = 225, g = 225 }
}

local player_props_normal = {
	collisionbox = { -0.312, 0, -0.312, 0.312, 1.8, 0.312 },
	eye_height = 1.6,
	nametag_color = { r = 225, b = 225, a = 225, g = 225 }
}


local function collisionbox_intersect(a, b)
	if a == nil or b == nil then return false end
    return (
        a[1] <= b[2] and
        a[2] >= b[1] and
        a[3] <= b[4] and
        a[4] >= b[3] and
        a[5] <= b[6] and
        a[6] >= b[5]
    )
end


local function set_crawling(player, anim, anim_speed)
	if not player then return end
	local pitch = - math.deg(player:get_look_vertical())
	local yaw = math.deg(player:get_look_horizontal())
	local vel = player:get_velocity()
	mcl_player.players[player].is_crawling = true
	-- anim = anim or "swim_stand"
	-- mcl_player.player_set_animation(player, anim, anim_speed)
	mcl_util.set_bone_position(player, "Head_Control", nil, vector.new(pitch - math.deg(dir_to_pitch(vel)) + 20, mcl_player.players[player].vel_yaw - yaw, 0))
	mcl_util.set_bone_position(player,"Body_Control", nil, vector.new((75 + math.deg(dir_to_pitch(vel))), mcl_player.players[player].vel_yaw - yaw, 180))
	mcl_util.set_properties(player, player_props_crawling)
end


local function set_standing(player, anim, anim_speed)
	if not player then return end
	local pitch = -math.deg(player:get_look_vertical())
	local yaw = math.deg(player:get_look_horizontal())
    mcl_player.players[player].is_crawling = false
    mcl_player.player_set_animation(player, "stand")
    mcl_util.set_properties(player, player_props_normal)
	mcl_util.set_bone_position(player, "Head_Control", nil,
	vector.new(pitch, mcl_player.players[player].vel_yaw - yaw, 0))
	mcl_util.set_bone_position(player, "Body_Control", nil, vector.new(0, -mcl_player.players[player].vel_yaw + yaw, 0))
end


local function table_add(a, b)
	local new_table = {}
	for k, v in ipairs(a) do
		new_table[k] = a[k] + (b[k] or 0)
	end
	return new_table
end


mcl_player.register_globalstep(function(player)
	if not player then return end
	local mcl_player_player = mcl_player.players[player]
	local name = player:get_player_name()
	local model_name = mcl_player_player.model
	local model = model_name and mcl_player.registered_player_models[model_name]
	local control = player:get_player_control()
	local parent = player:get_attach()
	local wielded = player:get_wielded_item()
	local wielded_def = wielded:get_definition()
	local wielded_itemname = player:get_wielded_item():get_name()
	local player_velocity = player:get_velocity()
	local elytra = mcl_player_player.elytra and mcl_player_player.elytra.active
    local player_pos = player:get_pos()
    local player_props = player:get_properties()


    local player_pos_offset = vector.subtract(player_pos, vector.round(player_pos))
	local player_pos_offset_collbox = table_add(player_props.collisionbox, {
		player_pos_offset[1],
		player_pos_offset[2],
		player_pos_offset[3],
		player_pos_offset[1],
		player_pos_offset[2],
		player_pos_offset[3],
	})
	local node_head = minetest.registered_nodes[mcl_player_player.nodes.head]
	local node_head_top = minetest.registered_nodes[mcl_player_player.nodes.head_top]
    if node_head ~= nil and node_head_top ~= nil and
	(collisionbox_intersect(table_add(player_pos_offset_collbox, player_props.collisionbox), node_head.collisionbox) or 
	collisionbox_intersect(table_add(player_pos_offset_collbox, player_props.collisionbox), node_head_top.collisionbox)) and
	not (mcl_player_player.is_swimming or elytra)
	then
		set_crawling(player)

	elseif mcl_player_player.is_crawling then
        set_standing(player)
    end

end)

minetest.register_chatcommand("crawl", {
	func = function(name, param)
		set_crawling(minetest.get_player_by_name(name))
	end
})


------------------------------------------------------------
--snowball
