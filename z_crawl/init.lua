local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)



minetest.register_on_joinplayer(function(player)
    mcl_player.players[player].
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


local function collisionbox_intersect(cb1, cb2) {
    return (
        a[1] <= b[2] &&
        a[2] >= b[1] &&
        a[3] <= b[4] &&
        a[4] >= b[3] &&
        a[5] <= b[6] &&
        a[6] >= b[5]
    )
}


local function set_crawling(player, anim, anim_speed)
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
    mcl_player.players[player].is_crawling = false
    mcl_player.player_set_animation(player, "stand")
    mcl_util.set_properties(player, player_props_normal)
    mcl_util.set_bone_position(player,"Head_Control", nil, vector.new(pitch, player_vel_yaw - yaw, 0))
    mcl_util.set_bone_position(player,"Body_Control", nil, vector.new(0, -player_vel_yaw + yaw, 0))
end



mcl_player.register_globalstep(function(player)
	local name = player:get_player_name()
	local model_name = mcl_player.players[player].model
	local model = model_name and mcl_player.registered_player_models[model_name]
	local control = player:get_player_control()
	local parent = player:get_attach()
	local wielded = player:get_wielded_item()
	local wielded_def = wielded:get_definition()
	local wielded_itemname = player:get_wielded_item():get_name()
	local player_velocity = player:get_velocity()
	local elytra = mcl_player.players[player].elytra and mcl_player.players[player].elytra.active
    local player_pos = player:get_pos()
    local player_props = player_get_properties()


    local player_pos_offset = vector.sub(player_pos, vector.round(player_pos))
    if mcl_player.players[player].is_crawling
    and not collisionbox_intersect(vector.add(player_pos_offset, player_props.collisionbox), minetest.get_node_def(mcl_player.players[player].nodes.head).collisionbox)
    and not collisionbox_intersect(vector.add(player_pos_offset, player_props.collisionbox), minetest.get_node_def(mcl_player.players[player].nodes.head_top).collisionbox) then --nothing obstructing
        set_standing(player)
    end

end)




------------------------------------------------------------
--snowball
