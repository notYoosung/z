local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname) .. "/automobiles"

--
-- constants
--
auto_beetle={}
auto_beetle.gravity = automobiles_lib.gravity

auto_beetle.S = nil

if(minetest.get_translator ~= nil) then
    auto_beetle.S = minetest.get_translator(minetest.get_current_modname())

else
    auto_beetle.S = function ( s ) return s end

end

local S = auto_beetle.S

dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "custom_physics.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "fuel_management.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "ground_detection.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "control.lua")
dofile(modpath .. "/automobiles_beetle" .. DIR_DELIM .. "entities.lua")
dofile(modpath .. "/automobiles_beetle" .. DIR_DELIM .. "crafts.lua")


