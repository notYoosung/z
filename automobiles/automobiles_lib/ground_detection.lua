function automobiles_lib.putAngleOnRange(angle)
    local n_angle = angle/360
    n_angle = (n_angle - math.floor(n_angle))*360
    if n_angle < -180 then n_angle = n_angle + 360 end
    if n_angle > 180 then n_angle = n_angle - 360 end
    return n_angle
end

function automobiles_lib.pid_controller(current_value, setpoint, last_error, delta_t, kp, ki, kd)
    kp = kp or 0
    ki = ki or 0.00000000000001
    kd = kd or 0.05
    delta_t = delta_t or 0.100;

    ti = kp/ki
    td = kd/kp

    local _error = setpoint - current_value
    local derivative = _error - last_error
    --local output = kpv*erro + (kpv/Tiv)*I + kpv*Tdv*((erro - erro_passado)/delta_t);
    if integrative == nil then integrative = 0 end
    integrative = integrative + (((_error + last_error)/delta_t)/2);
    local output = kp*_error + (kp/ti)*integrative + kp * td*((_error - last_error)/delta_t)
    last_error = _error
    return output, last_error

end

--lets assume that the rear axis is at object center, so we will use the distance only for front wheels
function automobiles_lib.ground_get_distances(self, radius, axis_distance)
    --local mid_axis = (axis_length / 2)/10
    local hip = axis_distance
    --minetest.chat_send_all("entre-eixo "..hip)
    local pitch = self._pitch --+90 for the calculations

    local yaw = self.object:get_yaw()
    local deg_yaw = math.deg(yaw)
    local yaw_turns = math.floor(deg_yaw / 360)
    deg_yaw = deg_yaw - (yaw_turns * 360)
    yaw = math.rad(deg_yaw)
    
    local pos = self.object:get_pos()

    local r_x, r_z = automobiles_lib.get_xz_from_hipotenuse(pos.x, pos.z, yaw, 0)
    local r_y = pos.y
    local rear_axis = {x=r_x, y=r_y, z=r_z}

    local rear_obstacle_level = automobiles_lib.get_obstacle(rear_axis)
    --minetest.chat_send_all("rear"..dump(rear_obstacle_level))

    if not self._last_front_detection then
        self._last_front_detection = rear_obstacle_level.y
    end
    if not self._last_pitch then
        self._last_pitch = 0
    end

    local f_x, f_z = automobiles_lib.get_xz_from_hipotenuse(pos.x, pos.z, yaw, hip)
    local f_y = pos.y
    --local x, f_y = automobiles_lib.get_xz_from_hipotenuse(f_x, r_y, pitch - math.rad(90), hip) --the x is only a mock
    --minetest.chat_send_all("r: "..r_y.." f: "..f_y .." - "..math.deg(pitch))
    local front_axis = {x=f_x, y=f_y, z=f_z}
    local front_obstacle_level = automobiles_lib.get_obstacle(front_axis)
    --minetest.chat_send_all("front"..dump(front_obstacle_level))

    --lets try to get the pitch
    if front_obstacle_level.y ~= nil and rear_obstacle_level.y ~= nil then
        local deltaX = axis_distance;
        local deltaY = front_obstacle_level.y - rear_obstacle_level.y;
        --minetest.chat_send_all("deutaY "..deltaY)
        local m = (deltaY/deltaX)
        local new_pitch = math.atan(m) --math.atan2(deltaY, deltaX);
        --local deg_angle = math.deg(new_pitch)

        --first test front wheels before
        if (front_obstacle_level.y-self._last_front_detection) <= self.initial_properties.stepheight then
            pitch = new_pitch --math.atan2(deltaY, deltaX);
            self._last_pitch = new_pitch
            self._last_front_detection = front_obstacle_level.y
        else
            --until 20 deg, climb
            if math.deg(new_pitch - self._last_pitch) <= 20 then

                --[[if self._last_error == nil then self._last_error = 0 end -- Último erro registrado
                -- Estado atual do sistema
                local output, last_error = automobiles_lib.pid_controller(self._last_pitch, new_pitch, self._last_error, self.dtime/2, 0.5)
                self._last_error = last_error 
                new_pitch = output
                local conversion = automobiles_lib.putAngleOnRange(math.deg(new_pitch))
                new_pitch = math.rad(conversion)
                minetest.chat_send_all("last: "..self._last_pitch.." - new: "..new_pitch)]]--

                pitch = new_pitch
                self._last_pitch = new_pitch
                self._last_front_detection = front_obstacle_level.y
            else
                --no climb here
                self._last_front_detection = rear_obstacle_level.y
                --here we need to set the collision effect
                self.object:set_acceleration({x=0,y=0,z=0})
		local oldvel = self.object:get_velocity()
                self.object:add_velocity(vector.subtract(vector.new(), oldvel))
            end
        end

    else
        pitch = math.rad(0)
    end

    self._pitch = pitch

end

function automobiles_lib.get_obstacle(ref_pos)
    --lets clone the table
    local retval = {x=ref_pos.x, y=ref_pos.y, z=ref_pos.z}
    --minetest.chat_send_all("aa y: " .. dump(retval.y))
    local i_pos = {x=ref_pos.x, y=ref_pos.y + 1, z=ref_pos.z}
    --minetest.chat_send_all("bb y: " .. dump(i_pos.y))

    local y = automobiles_lib.eval_interception(i_pos, {x=i_pos.x, y=i_pos.y - 4, z=i_pos.z})
    retval.y = y

    --minetest.chat_send_all("y: " .. dump(ref_pos.y) .. " ye: ".. dump(retval.y))
    return retval    
end

local function get_nodedef_field(nodename, fieldname)
    if not minetest.registered_nodes[nodename] then
        return nil
    end
    return minetest.registered_nodes[nodename][fieldname]
end

function automobiles_lib.eval_interception(initial_pos, end_pos)
    local ret_y = nil
	local cast = minetest.raycast(initial_pos, end_pos, true, false)
	local thing = cast:next()
	while thing do
		if thing.type == "node" then
            local pos = thing.intersection_point
            if pos then
                local nodename = minetest.get_node(thing.under).name
                local drawtype = get_nodedef_field(nodename, "drawtype")

                if drawtype ~= "plantlike" then
                    if initial_pos.y >= pos.y then 
                        ret_y = pos.y
                        --minetest.chat_send_all("ray intercection: " .. dump(pos.y) .. " -- " .. nodename)
                    end
                    break
                end
            end
        end
        thing = cast:next()
    end
    return ret_y
end

function automobiles_lib.get_node_below(pos, dist)
    local node = minetest.get_node(pos)
    local pos_below = pos
    pos_below.y = pos_below.y - (dist + 0.1)
    local node_below = minetest.get_node(pos_below)
    return node_below
end


