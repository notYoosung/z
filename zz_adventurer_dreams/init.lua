local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

minetest.register_node(modname .. ":adventurer_task", {
   description = "Adventurer Task",
--    inventory_image = ".png",
	on_rightclick = function()
		
	end,
	on_construct = function()

	end,
	on_destroy = function()

	end,
})