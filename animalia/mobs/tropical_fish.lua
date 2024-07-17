local modname = minetest.get_current_modname()
local path = minetest.get_modpath(modname) .. "/animalia"

----------
-- Fish --
----------

creatura.register_mob(modname .. ":animalia_tropical_fish", {
	-- Engine Props
	visual_size = {x = 10, y = 10},
	meshes = {
		"animalia_clownfish.b3d",
		"animalia_angelfish.b3d"
	},
	mesh_textures = {
		{
			"animalia_clownfish.png",
			"animalia_blue_tang.png"
		},
		{
			"animalia_angelfish.png"
		}
	},

	-- Creatura Props
	max_health = 5,
	armor_groups = {fleshy = 150},
	damage = 0,
	max_breath = 0,
	speed = 2,
	tracking_range = 6,
	max_boids = 6,
	boid_seperation = 0.3,
	despawn_after = 200,
	max_fall = 0,
	stepheight = 1.1,
	hitbox = {
		width = 0.15,
		height = 0.3
	},
	animations = {
		swim = {range = {x = 1, y = 20}, speed = 20, frame_blend = 0.3, loop = true},
		flop = {range = {x = 30, y = 40}, speed = 20, frame_blend = 0.3, loop = true},
	},
	liquid_submergence = 1,
	liquid_drag = 0,

	-- Animalia Behaviors
	is_aquatic_mob = true,

	-- Animalia Props
	flee_puncher = false,
	catch_with_net = true,
	catch_with_lasso = false,

	-- Functions
	utility_stack = {
		animalia.mob_ai.swim_wander
	},

	activate_func = function(self)
		animalia.initialize_api(self)
		animalia.initialize_lasso(self)
	end,

	step_func = function(self)
		animalia.step_timers(self)
		animalia.do_growth(self, 60)
		animalia.update_lasso_effects(self)
	end,

	death_func = function(self)
		if self:get_utility() ~= modname .. ":animalia_die" then
			self:initiate_utility(modname .. ":animalia_die", self)
		end
	end,

	on_rightclick = function(self, clicker)
		if animalia.set_nametag(self, clicker) then
			return
		end
	end,

	on_punch = animalia.punch
})

creatura.register_spawn_item(modname .. ":animalia_tropical_fish", {
	col1 = "e28821",
	col2 = "f6e5d2"
})

animalia.alias_mob(modname .. ":animalia_clownfish", modname .. ":animalia_tropical_fish")
animalia.alias_mob(modname .. ":animalia_blue_tang", modname .. ":animalia_tropical_fish")
animalia.alias_mob(modname .. ":animalia_angelfish", modname .. ":animalia_tropical_fish")