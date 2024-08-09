local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()



minetest.register_tool(modname .. ":kill_hammer", {
	description = "Kill Hammer",
	-- _doc_items_longdesc = pickaxe_longdesc,
	inventory_image = "z_tools_kill_hammer.png",
	-- wield_scale = wield_scale,
	groups = { tool=1, dig_speed_class=7, enchantability=100 },
	tool_capabilities = {
		-- 1/1.2
		full_punch_interval = 0.1,
		max_drop_level=0,
		-- damage_groups = {fleshy=5},
		punch_attack_uses = -1,
	},
	sound = { breaks = "default_tool_breaks" },
	on_place = mcl_tools.tool_place_funcs.pick,
	on_use = function(itemstack, user, pointed_thing)
        -- local fall_distance = user:get_velocity().y
        mcl_tools.entity = pointed_thing.ref
        local playerref = mcl_tools.entity
        if pointed_thing.type == "object" then
            -- if mcl_tools.mace_cooldown[user] == nil then
            --     mcl_tools.mace_cooldown[user] = mcl_tools.mace_cooldown[user] or 0
            -- end
            -- local current_time = minetest.get_gametime()
            -- if current_time - mcl_tools.mace_cooldown[user] >= cooldown_time then
                -- mcl_tools.mace_cooldown[user] = current_time
                -- if fall_distance < 0 then
                    -- if mcl_tools.entity:is_player() or mcl_tools.entity:get_luaentity() then
                    --     mcl_tools.entity:punch(user, 1.6, {
                    --     full_punch_interval = 1.6,
                    --     damage_groups = {fleshy = -6 * fall_distance / 5.5},
                    --     }, nil)
                    -- end
                -- else
            if mcl_tools.entity:is_player() and mcl_tools.entity:get_player_name() then
                playerref = minetest.get_player_by_name(mcl_tools.entity:get_player_name())
            end
            if mcl_tools.entity:is_player() or mcl_tools.entity:get_luaentity() then
                -- mcl_tools.entity:punch(user, 1.6, {
                -- full_punch_interval = 1.6,
                -- damage_groups = {fleshy = 6},
                -- }, nil)
                mcl_tools.entity:set_hp(0)
                minetest.sound_play("tnt_explode", {
                    pitch = 0.1,
                    -- max_hear_distance = 128,
                    -- pos = mcl_tools.entity:getpos()
                })
                minetest.sound_play("lightning_thunder", {
                    -- pitch = 0.1,
                    -- max_hear_distance = 128,
                    -- pos = mcl_tools.entity:getpos()
                })
                minetest.sound_play("iphone_notif_pingding", {
                    -- max_hear_distance = 128,
                    -- pos = mcl_tools.entity:getpos()
                })
            end
            -- end
        end
        -- if not minetest.is_creative_enabled(user:get_player_name()) then
        --     itemstack:add_wear(65535 / 500)
        --     return itemstack
        -- end
    end,
	_mcl_toollike_wield = true,
	-- _mcl_diggroups = {
	-- 	pickaxey = { speed = 8, level = 5, uses = 1562 }
	-- },
	-- _mcl_upgradable = true,
	-- _mcl_upgrade_item = "mcl_tools:pick_netherite"
})