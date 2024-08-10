local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local S = roadster.S

--
-- items
--

-- body
minetest.register_craftitem(modname .. ":automobiles_roadster_roadster_body",{
	description = S("Roadster Body"),
	inventory_image = "roadster_body.png",
})
-- wheel
minetest.register_craftitem(modname .. ":automobiles_roadster_wheel",{
	description = S("Roadster Wheel"),
	inventory_image = "roadster_wheel.png",
})

-- roadster
minetest.register_tool(modname .. ":automobiles_roadster_roadster", {
	description = S("Roadster"),
	inventory_image = "automobiles_roadster.png",
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
		local car = minetest.add_entity(pointed_pos, modname .. ":automobiles_roadster_roadster", staticdata)
		if car and placer then
            local ent = car:get_luaentity()
            local owner = placer:get_player_name()
            if ent then
                ent.owner = owner
                ent.hp = 50 --reset hp
			    car:set_yaw(placer:get_look_horizontal())
			    itemstack:take_item()
                ent.object:set_acceleration({x=0,y=-automobiles_lib.gravity,z=0})
                automobiles_lib.setText(ent, S("Roadster"))
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
		output = modname .. ":automobiles_roadster_roadster",
		recipe = {
			{modname .. ":automobiles_roadster_wheel", modname .. ":automobiles_lib_engine", modname .. ":automobiles_roadster_wheel"},
			{modname .. ":automobiles_roadster_wheel",modname .. ":automobiles_roadster_roadster_body",  modname .. ":automobiles_roadster_wheel"},
		}
	})
	minetest.register_craft({
		output = modname .. ":automobiles_roadster_roadster_body",
		recipe = {
            {"default:glass" ,"","default:steel_ingot"},
			{"default:steel_ingot","default:steelblock","default:steel_ingot"},
			{"group:wood","group:wood", "group:wood"},
		}
	})
	minetest.register_craft({
		output = modname .. ":automobiles_roadster_wheel",
		recipe = {
			{"group:wood", "default:stick", "group:wood"},
			{"default:stick","group:wood",  "default:stick"},
            {"group:wood", "default:stick", "group:wood"},
		}
	})
end
