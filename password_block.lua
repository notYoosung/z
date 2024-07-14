local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()

-- Define the node names for the password block and temporary replacement
local password_block_name = modname .. ":password_block"
local temp_node_name = modname .. ":temp_password_block"

-- Register the password block node
minetest.register_node(password_block_name, {
    description = "Password Block",
    tiles = {"password_block.png"},
    groups = {cracky = 3, stone = 1, oddly_breakable_by_hand = 1},
    after_place_node = function(pos, placer)
        local meta = minetest.get_meta(pos)
        local player_name = placer:get_player_name()
        meta:set_string("owner", player_name)
        meta:set_string("infotext", "Password not set. Right-click to set.")
        minetest.show_formspec(player_name, modname .. ":setup_form_"..minetest.pos_to_string(pos), "field[password;Set Password;]")
    end,
    on_rightclick = function(pos, node, player, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        if meta:get_string("password") == "" then
            minetest.show_formspec(player:get_player_name(), modname .. ":setup_form_"..minetest.pos_to_string(pos), "field[password;Set Password;]")
        else
            minetest.show_formspec(player:get_player_name(), modname .. ":password_form_"..minetest.pos_to_string(pos), "field[password;Enter Password;]")
        end
    end,
    mcl_redstone = {
        power = 0,
        power_last = 0,
    },
    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local active = meta:get_int("active")
        if active == 1 then
            meta:set_int("active", 0)
            meta:set_int("power", 0) -- Reset power after 1 second
            minetest.get_node_timer(pos):start(1.0) -- Change state for 1 second
            return true
        end
        return false
    end,
})

-- Register the temporary password block node
minetest.register_node(temp_node_name, {
    description = "Temporary Password Block",
    tiles = {"temp_password_block.png"},
    groups = {cracky = 3, stone = 1, oddly_breakable_by_hand = 1},
    drop = password_block_name, -- Drop the original password block when broken
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(4.0) -- Change back to password block after 4 seconds
    end,
    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        minetest.set_node(pos, {name = password_block_name}) -- Change back to password block
    end,
})

-- Handle the password setup form submission
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local prefix = modname .. ":setup_form_"
    if formname:sub(1, #prefix) == prefix and fields.password then
        local pos = minetest.string_to_pos(formname:sub(#prefix + 1))
        local meta = minetest.get_meta(pos)
        meta:set_string("password", fields.password)
        meta:set_string("infotext", "Password set. Right-click to enter password.")
        minetest.chat_send_player(player:get_player_name(), "Password set successfully.")
        return true
    end
end)

-- Handle the password form submission
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local prefix = modname .. ":password_form_"
    if formname:sub(1, #prefix) == prefix and fields.password then
        local pos = minetest.string_to_pos(formname:sub(#prefix + 1))
        local meta = minetest.get_meta(pos)
        if fields.password == meta:get_string("password") then
            -- Change to temporary node for 4 seconds
            minetest.set_node(pos, {name = temp_node_name})
            minetest.chat_send_player(player:get_player_name(), "Password correct! Block changed for 4 seconds.")
        else
            minetest.chat_send_player(player:get_player_name(), "Incorrect password.")
        end
        return true
    end
end)

-- Ensure the block provides power for the redstone system
minetest.register_abm({
    label = "Redstone Power Provider",
    nodenames = {password_block_name, temp_node_name},
    interval = 1,
    chance = 1,
    action = function(pos, node)
        local meta = minetest.get_meta(pos)
        if node.name == temp_node_name then
            -- Handle behavior of temporary node if needed
        end
        if meta:get_int("active") == 1 then
            meta:set_int("power", 15)
            minetest.get_node_timer(pos):start(1.0) -- Change state for 1 second
        else
            meta:set_int("power", 0)
        end
    end
})
