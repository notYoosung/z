local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname) .. "/automobiles"

--
-- constants
--
coupe={}
coupe.gravity = automobiles_lib.gravity

coupe.S = nil

if(minetest.get_translator ~= nil) then
    coupe.S = minetest.get_translator(minetest.get_current_modname())

else
    coupe.S = function ( s ) return s end

end

local S = coupe.S

dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "custom_physics.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "control.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "fuel_management.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "ground_detection.lua")
dofile(modpath .. "/automobiles_coupe" .. DIR_DELIM .. "coupe_entities.lua")
dofile(modpath .. "/automobiles_coupe" .. DIR_DELIM .. "coupe_crafts.lua")


