local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local S = delorean.S

--
-- items
--

-- body
minetest.register_craftitem(modname .. ":automobiles_delorean_delorean_body",{
	description = S("Delorean Body"),
	inventory_image = "automobiles_delorean_body.png",
})

-- delorean
minetest.register_tool(modname .. ":automobiles_delorean_delorean", {
	description = S("Delorean"),
	inventory_image = "automobiles_delorean.png",
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
		local car = minetest.add_entity(pointed_pos, modname .. ":automobiles_delorean_delorean", staticdata)
		if car and placer then
            local ent = car:get_luaentity()
            local owner = placer:get_player_name()
            if ent then
                ent.owner = owner
                ent.hp = 50 --reset hp
                ent._car_type = ent._car_type or 0
                --minetest.chat_send_all("owner: " .. ent.owner)
		        car:set_yaw(placer:get_look_horizontal())
		        itemstack:take_item()
                ent.object:set_acceleration({x=0,y=-automobiles_lib.gravity,z=0})
                automobiles_lib.setText(ent, S("Delorean"))
                automobiles_lib.create_inventory(ent, ent._trunk_slots, owner)
            end
		end

		return itemstack
	end,
})

-- delorean
minetest.register_tool(modname .. ":automobiles_delorean_time_machine", {
	description = S("Time Machine"),
	inventory_image = "automobiles_delorean.png",
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
		local car = minetest.add_entity(pointed_pos, modname .. ":automobiles_delorean_delorean", staticdata)
		if car and placer then
            local ent = car:get_luaentity()
            local owner = placer:get_player_name()
            if ent then
                ent.owner = owner
                ent.hp = 50 --reset hp
                ent._car_type = ent._car_type or 1
                --minetest.chat_send_all("delorean: " .. ent._car_type)
                --minetest.chat_send_all("owner: " .. ent.owner)
		        car:set_yaw(placer:get_look_horizontal())
		        itemstack:take_item()
                ent.object:set_acceleration({x=0,y=-automobiles_lib.gravity,z=0})
                automobiles_lib.setText(ent, "Delorean")
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
		output = modname .. ":automobiles_delorean_delorean",
		recipe = {
			{modname .. ":automobiles_lib_wheel", modname .. ":automobiles_lib_engine", modname .. ":automobiles_lib_wheel"},
			{modname .. ":automobiles_lib_wheel",modname .. ":automobiles_delorean_delorean_body",  modname .. ":automobiles_lib_wheel"},
		}
	})
	minetest.register_craft({
		output = modname .. ":automobiles_delorean_delorean_body",
		recipe = {
            {"default:glass" ,"default:glass","default:steelblock"},
			{"default:steelblock","","default:steelblock"},
			{"default:steelblock","default:steelblock", "default:steelblock"},
		}
	})
end
