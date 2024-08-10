local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

entity_modifier = {}

--original dis
entity_modifier.player_original_disguise_properties = {}

-- local mp = minetest.get_modpath(minetest.get_current_modname())..'/'

dofile(modpath .. "/resize.lua")

dofile(modpath .. "/disguise.lua")

minetest.register_on_leaveplayer(function(player)
	entity_modifier.player_original_disguise_properties[player:get_player_name()] = nil
end)
