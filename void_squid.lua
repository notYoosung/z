local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()

mcl_mobs.register_mob(modname .. ":void_squid", {
	description = "Void Squid",
  type = "animal",
  can_despawn = false,
  passive = true,
  hp_min = 10,
  hp_max = 10,
  xp_min = 1,
  xp_max = 3,
  armor = 100,
  collisionbox = {-0.4, 0.0, -0.4, 0.4, 0.9, 0.4},
  visual = "mesh",
  mesh = "mobs_mc_squid.b3d",
  textures = {
    {"z_void_squid_untamed.png"}
  },
  sounds = {
    damage = {name="mobs_mc_squid_hurt", gain=0.3},
    death = {name="mobs_mc_squid_death", gain=0.4},
    --flop = "mobs_mc_squid_flop",
    distance = 16,
  },
  animation = {
		stand_start = 1,
		stand_end = 60,
		walk_start = 1,
		walk_end = 60,
		run_start = 1,
		run_end = 60,
	},
  --[[drops = {
		{name = "mcl_mobitems:ink_sac",
		chance = 1,
		min = 1,
		max = 3,
		looting = "common",},
	},--]]
	stepheight = 1.1,
  visual_size = {x=3, y=3},
  makes_footstep_sound = false,
  fly = true,
  fly_in = { "air", "__airlike", "mcl_core:water_source", "mclx_core:river_water_source", modname .. ":pool_water_source" },
  breath_max = -1,
  jump = false,
  view_range = 16,
  runaway = true,
  fear_height = 4,
  lava_damage = 0,
  fire_damage = 0,
  water_damage = 0,
  fire_resistant = true,
})


-- spawn eggs
mcl_mobs.register_egg(modname .. ":void_squid", "Void Squid", "#223b4d", "#708999", 0)
