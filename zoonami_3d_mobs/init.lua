local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

-- Namespace
zoonami_3d_mobs = {}

-- Return mob data
function zoonami_3d_mobs.mobs()
	return dofile(modpath .. "/lua/mobs.lua")
end
