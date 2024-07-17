local modname = minetest.get_current_modname()
local path = minetest.get_modpath(modname) .. "/animalia"

--------------------------------------
-- Convert Better Fauna to Animalia --
--------------------------------------

for i = 1, #animalia.mobs do
    local new_mob = animalia.mobs[i]
    local old_mob = "better_fauna:" .. new_mob:split(":")[2]
    minetest.register_entity(":" .. old_mob, {
        on_activate = mob_core.on_activate
    })
    minetest.register_alias_force("better_fauna:spawn_" .. new_mob:split(":")[2],
		modname .. ":animalia_spawn_" .. new_mob:split(":")[2])
end

minetest.register_globalstep(function(dtime)
    local mobs = minetest.luaentities
    for _, mob in pairs(mobs) do
        if mob
        and mob.name:match("better_fauna:") then
			local pos = mob.object:get_pos()
			if not pos then return end
            if mob.name:find("lasso_fence_ent") then
                if pos then
                    minetest.add_entity(pos, modname .. ":animalia_lasso_fence_ent")
                end
                mob.object:remove()
            elseif mob.name:find("lasso_visual") then
                if pos then
                    minetest.add_entity(pos, modname .. ":animalia_lasso_visual")
                end
                mob.object:remove()
            end
            for i = 1, #animalia.mobs do
                local ent = animalia.mobs[i]
                local new_name = ent:split(":")[2]
                local old_name = mob.name:split(":")[2]
                if new_name == old_name then
                    if pos then
                        local new_mob = minetest.add_entity(pos, ent)
                        local mem = nil
                        if mob.memory then
                            mem = mob.memory
                        end
                        minetest.after(0.1, function()
                            if mem then
                                new_mob:get_luaentity().memory = mem
                                new_mob:get_luaentity():on_activate(new_mob, nil, dtime)
                            end
                        end)
                    end
                    mob.object:remove()
                end
            end
        end
    end
end)


-- Tools

minetest.register_alias_force("better_fauna:net", modname .. ":animalia_net")
minetest.register_alias_force("better_fauna:lasso", modname .. ":animalia_lasso")
minetest.register_alias_force("better_fauna:cat_toy", modname .. ":animalia_cat_toy")
minetest.register_alias_force("better_fauna:saddle", modname .. ":animalia_saddle")
minetest.register_alias_force("better_fauna:shears", modname .. ":animalia_shears")

-- Drops

minetest.register_alias_force("better_fauna:beef_raw", modname .. ":animalia_beef_raw")
minetest.register_alias_force("better_fauna:beef_cooked", modname .. ":animalia_beef_cooked")
minetest.register_alias_force("better_fauna:bucket_milk", modname .. ":animalia_bucket_milk")
minetest.register_alias_force("better_fauna:leather", modname .. ":animalia_leather")
minetest.register_alias_force("better_fauna:chicken_egg", modname .. ":animalia_chicken_egg")
minetest.register_alias_force("better_fauna:chicken_raw", modname .. ":animalia_poultry_raw")
minetest.register_alias_force("better_fauna:chicken_cooked", modname .. ":animalia_poultry_cooked")
minetest.register_alias_force("better_fauna:feather", modname .. ":animalia_feather")
minetest.register_alias_force("better_fauna:mutton_raw", modname .. ":animalia_mutton_raw")
minetest.register_alias_force("better_fauna:mutton_cooked", modname .. ":animalia_mutton_cooked")
minetest.register_alias_force("better_fauna:porkchop_raw", modname .. ":animalia_porkchop_raw")
minetest.register_alias_force("better_fauna:porkchop_cooked", modname .. ":animalia_porkchop_cooked")
minetest.register_alias_force("better_fauna:turkey_raw", modname .. ":animalia_poultry_raw")
minetest.register_alias_force("better_fauna:turkey_cooked", modname .. ":animalia_poultry_cooked")