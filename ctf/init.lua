local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)


dofile(modpath .. "/coreinit.lua")
dofile(modpath .. "/physicsinit.lua")
dofile(modpath .. "/mhudinit.lua")
dofile(modpath .. "/rawfinit.lua")
dofile(modpath .. "/ranged.lua")
-- dofile(modpath .. "/grenades/init.lua")

