local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

--
-- constants
--
vespa={}
vespa.LONGIT_DRAG_FACTOR = 0.15*0.15
vespa.LATER_DRAG_FACTOR = 30.0
vespa.gravity = automobiles_lib.gravity
vespa.max_speed = 20
vespa.max_acc_factor = 6

vespa.front_wheel_xpos = 0
vespa.rear_wheel_xpos = 0

vespa.S = nil

if(minetest.get_translator ~= nil) then
    vespa.S = minetest.get_translator(minetest.get_current_modname())

else
    vespa.S = function ( s ) return s end

end

local S = vespa.S

dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "custom_physics.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "control.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "fuel_management.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "ground_detection.lua")
dofile(modpath .. "/automobiles_vespa" .. DIR_DELIM .. "vespa_forms.lua")
dofile(modpath .. "/automobiles_vespa" .. DIR_DELIM .. "vespa_player.lua")
dofile(modpath .. "/automobiles_vespa" .. DIR_DELIM .. "vespa_utilities.lua")
dofile(modpath .. "/automobiles_vespa" .. DIR_DELIM .. "vespa_entities.lua")
dofile(modpath .. "/automobiles_vespa" .. DIR_DELIM .. "vespa_crafts.lua")


