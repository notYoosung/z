local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)



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
    mcl_player.players[player].is_crawling = false
    mcl_player.player_set_animation(player, "stand")
    mcl_util.set_properties(player, player_props_normal)
    mcl_util.set_bone_position(player,"Head_Control", nil, vector.new(pitch, player_vel_yaw - yaw, 0))
    mcl_util.set_bone_position(player,"Body_Control", nil, vector.new(0, -player_vel_yaw + yaw, 0))
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
    if mcl_player_player.is_crawling
		and (node_head ~= nil and not collisionbox_intersect(table_add(player_pos_offset_collbox, player_props.collisionbox), node_head.collisionbox))
		and (node_head_top ~= nil and not collisionbox_intersect(table_add(player_pos_offset_collbox, player_props.collisionbox), node_head_top.collisionbox)) then --nothing obstructing
        set_standing(player)
	elseif not (
		mcl_player_player.is_swimming or
		elytra
	) then
		set_crawling(player)
    end

end)

minetest.register_chatcommand("crawl", {
	func = function(name, param)
		set_crawl(minetest.get_player_by_name(name))
	end
})


------------------------------------------------------------
--snowball
