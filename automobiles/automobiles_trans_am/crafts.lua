local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local S = trans_am.S

--
-- items
--

-- body
minetest.register_craftitem(modname .. ":automobiles_trans_am_trans_am_body",{
	description = S("Trans Am Body"),
	inventory_image = "automobiles_trans_am_body.png",
})

-- trans_am
minetest.register_tool(modname .. ":automobiles_trans_am_trans_am", {
	description = S("Trans Am"),
	inventory_image = "automobiles_trans_am.png",
    liquids_pointable = false,
    stack_max = 1,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

        local stack_meta = itemstack:get_meta()
        local staticdata = stack_meta:get_string("staticdata")

        local pointed_pos = pointed_thing.above
		--pointed_pos.y=pointed_pos.y+0.2
		local car = minetest.add_entity(pointed_pos, modname .. ":automobiles_trans_am_trans_am", staticdata)
		if car and placer then
            local ent = car:get_luaentity()
            local owner = placer:get_player_name()
            if ent then
                ent.owner = owner
                ent.hp = 50 --reset hp
                ent._trans_am_type = 0
                --minetest.chat_send_all("owner: " .. ent.owner)
		        car:set_yaw(placer:get_look_horizontal())
		        itemstack:take_item()
                ent.object:set_acceleration({x=0,y=-automobiles_lib.gravity,z=0})
                automobiles_lib.setText(ent, S("Trans Am"))
                automobiles_lib.create_inventory(ent, ent._trunk_slots, owner)
            end
		end

		return itemstack
	end,
})


--
-- crafting
--
if minetest.get_modpath("default") then
	minetest.register_craft({
		output = modname .. ":automobiles_trans_am_trans_am",
		recipe = {
			{modname .. ":automobiles_lib_wheel", modname .. ":automobiles_lib_engine", modname .. ":automobiles_lib_wheel"},
			{modname .. ":automobiles_lib_wheel",modname .. ":automobiles_trans_am_trans_am_body",  modname .. ":automobiles_lib_wheel"},
		}
	})
	minetest.register_craft({
		output = modname .. ":automobiles_trans_am_trans_am_body",
		recipe = {
            {"default:glass","default:mese","default:steel_ingot"},
			{"default:steel_ingot","default:steelblock","default:steel_ingot"},
			{"default:steelblock","default:steelblock", "default:steelblock"},
		}
	})
end
