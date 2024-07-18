local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname) .. "/ctf"

mhud = {}

function mhud.init()
	return dofile(modpath .. "/mhud.lua")
end
