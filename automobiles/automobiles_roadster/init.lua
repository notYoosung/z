local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname) .. "/automobiles"

--
-- constants
--
roadster={}
roadster.LONGIT_DRAG_FACTOR = 0.16*0.16
roadster.LATER_DRAG_FACTOR = 30.0
roadster.gravity = automobiles_lib.gravity
roadster.max_speed = 12
roadster.max_acc_factor = 5

roadster.S = nil

if(minetest.get_translator ~= nil) then
    roadster.S = minetest.get_translator(minetest.get_current_modname())

else
    roadster.S = function ( s ) return s end

end

local S = roadster.S

dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "custom_physics.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "control.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "fuel_management.lua")
dofile(modpath .. "/automobiles_lib" .. DIR_DELIM .. "ground_detection.lua")
dofile(modpath .. "/automobiles_roadster" .. DIR_DELIM .. "roadster_forms.lua")
dofile(modpath .. "/automobiles_roadster" .. DIR_DELIM .. "roadster_entities.lua")
dofile(modpath .. "/automobiles_roadster" .. DIR_DELIM .. "roadster_crafts.lua")


--    --minetest.add_entity(e_pos, modname .. ":automobiles_roadster_target")
minetest.register_node(modname .. ":automobiles_roadster_display_target", {
	tiles = {"automobiles_red.png"},
	use_texture_alpha = true,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-.05,-.05,-.05, .05,.05,.05},
		},
	},
	selection_box = {
		type = "regular",
	},
	paramtype = "light",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "",
})

minetest.register_entity(modname .. ":automobiles_roadster_target", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	-- wielditem seems to be scaled to 1.5 times original node size
	visual_size = {x = 0.67, y = 0.67},
	textures = {modname .. ":automobiles_roadster_display_target"},
	timer = 0,
	glow = 10,

	on_step = function(self, dtime)

		self.timer = self.timer + dtime

		-- remove after set number of seconds
		if self.timer > 1 then
			self.object:remove()
		end
	end,
})
