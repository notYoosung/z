local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()



minetest.register_tool(modname .. ":kill_hammer", {
	description = "Diamond Pickaxe",
	_doc_items_longdesc = pickaxe_longdesc,
	inventory_image = "default_tool_diamondpick.png",
	wield_scale = wield_scale,
	groups = { tool=1, pickaxe=1, dig_speed_class=5, enchantability=10 },
	tool_capabilities = {
		-- 1/1.2
		full_punch_interval = 0.83333333,
		max_drop_level=5,
		damage_groups = {fleshy=5},
		punch_attack_uses = 781,
	},
	sound = { breaks = "default_tool_breaks" },
	on_place = mcl_tools.tool_place_funcs.pick,
	on_use = function(itemstack, user, pointed_thing)
        -- local fall_distance = user:get_velocity().y
        -- mcl_tools.entity = pointed_thing.ref
        -- if pointed_thing.type == "object" then
        --     if mcl_tools.mace_cooldown[user] == nil then
        --         mcl_tools.mace_cooldown[user] = mcl_tools.mace_cooldown[user] or 0
        --     end
        --     local current_time = minetest.get_gametime()
        --     if current_time - mcl_tools.mace_cooldown[user] >= cooldown_time then
        --         mcl_tools.mace_cooldown[user] = current_time
        --         if fall_distance < 0 then
        --             if mcl_tools.entity:is_player() or mcl_tools.entity:get_luaentity() then
        --                 mcl_tools.entity:punch(user, 1.6, {
        --                 full_punch_interval = 1.6,
        --                 damage_groups = {fleshy = -6 * fall_distance / 5.5},
        --                 }, nil)
        --             end
        --         else
        --         if mcl_tools.entity:is_player() or mcl_tools.entity:get_luaentity() then
        --             mcl_tools.entity:punch(user, 1.6, {
        --             full_punch_interval = 1.6,
        --             damage_groups = {fleshy = 6},
        --             }, nil)
        --         end
        --     end
        -- end
        -- if not minetest.is_creative_enabled(user:get_player_name()) then
        --     itemstack:add_wear(65535 / 500)
        --     return itemstack
        -- end
    end,
    _repair_material = "mcl_core:diamond",
	_mcl_toollike_wield = true,
	_mcl_diggroups = {
		pickaxey = { speed = 8, level = 5, uses = 1562 }
	},
	_mcl_upgradable = true,
	_mcl_upgrade_item = "mcl_tools:pick_netherite"
})