local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

--
-- constants
--
motorcycle={}
motorcycle.LONGIT_DRAG_FACTOR = 0.14*0.14
motorcycle.LATER_DRAG_FACTOR = 25.0
motorcycle.gravity = automobiles_lib.gravity
motorcycle.max_speed = 20
motorcycle.max_acc_factor = 8

motorcycle.front_wheel_xpos = 0
motorcycle.rear_wheel_xpos = 0

if(minetest.get_translator ~= nil) then
    motorcycle.S = minetest.get_translator(minetest.get_current_modname())

else
    motorcycle.S = function ( s ) return s end

end

local S = motorcycle.S

dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "custom_physics.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "control.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "fuel_management.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "ground_detection.lua")
dofile(modpath .. "/automobiles_motorcycle" .. DIR_DELIM .. "motorcycle_forms.lua")
dofile(modpath .. "/automobiles_motorcycle" .. DIR_DELIM .. "motorcycle_player.lua")
dofile(modpath .. "/automobiles_motorcycle" .. DIR_DELIM .. "motorcycle_utilities.lua")
dofile(modpath .. "/automobiles_motorcycle" .. DIR_DELIM .. "motorcycle_entities.lua")
dofile(modpath .. "/automobiles_motorcycle" .. DIR_DELIM .. "motorcycle_crafts.lua")


