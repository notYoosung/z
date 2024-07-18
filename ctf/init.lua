local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname) .. "/ctf"


dofile(modpath .. "/coreinit.lua")
dofile(modpath .. "/mhudinit.lua")
dofile(modpath .. "/rawfinit.lua")
dofile(modpath .. "/ranged.lua")

