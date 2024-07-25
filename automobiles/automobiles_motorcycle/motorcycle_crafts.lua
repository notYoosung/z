local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname) .. "/automobiles"

local S = motorcycle.S
--
-- items
--

-- body
minetest.register_craftitem(modname .. ":automobiles_motorcycle_body",{
	description = S("Motorcycle Body"),
	inventory_image = "automobiles_motorcycle_body.png",
})
-- wheel
minetest.register_craftitem(modname .. ":automobiles_motorcycle_wheel",{
	description = S("Motorcycle Wheel"),
	inventory_image = "automobiles_motorcycle_wheel_icon.png",
})

-- motorcycle
minetest.register_tool(modname .. ":automobiles_motorcycle_motorcycle", {
	description = S("Motorcycle"),
	inventory_image = "automobiles_motorcycle.png",
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
		local car = minetest.add_entity(pointed_pos, modname .. ":automobiles_motorcycle_motorcycle", staticdata)
		if car and placer then
            local ent = car:get_luaentity()
            local owner = placer:get_player_name()
            if ent then
                ent.owner = owner
                ent.hp = 50 --reset hp
			    car:set_yaw(placer:get_look_horizontal())
			    itemstack:take_item()
                ent.object:set_acceleration({x=0,y=-automobiles_lib.gravity,z=0})
                automobiles_lib.setText(ent, S("Motorcycle"))
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
		output = modname .. ":automobiles_motorcycle_motorcycle",
		recipe = {
			{modname .. ":automobiles_motorcycle_wheel", modname .. ":automobiles_motorcycle_body", modname .. ":automobiles_motorcycle_wheel"},
		}
	})
	minetest.register_craft({
		output = modname .. ":automobiles_motorcycle_body",
		recipe = {
            {"default:glass" ,"","default:steel_ingot"},
			{"default:steel_ingot","","default:steel_ingot"},
			{"default:steel_ingot",modname .. ":automobiles_lib_engine", "default:steel_ingot"},
		}
	})
	minetest.register_craft({
		output = modname .. ":automobiles_motorcycle_wheel",
		recipe = {
			{"default:steel_ingot", "default:tin_ingot", "default:steel_ingot"},
			{"default:steel_ingot","default:steelblock",  "default:steel_ingot"},
            {"default:steel_ingot", "default:tin_ingot", "default:steel_ingot"},
		}
	})
end
