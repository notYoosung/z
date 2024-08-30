local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)


local phoenix_scale = 1

mcl_mobs.register_mob(modname .. ":phoenix", {
	description = "Phoenix",
	type = "animal",
	spawn_class = "passive",
	passive = true,
	pathfinding = 1,
	hp_min = 100,
	hp_max = 100,
	xp_min = 100,
	xp_max = 100,
	collisionbox = {
		-0.3 * phoenix_scale,
		-0.01 * phoenix_scale,
		-0.3 * phoenix_scale,
		0.3 * phoenix_scale,
		1.94 * phoenix_scale,
		0.3 * phoenix_scale
	},
	visual = "mesh",
	mesh = "phoenix.obj",
	-- head_swivel = "head.control",
	-- bone_eye_height = 2.2,
	-- head_eye_height = 2.2,
	curiosity = 10,
	textures = {
		{
			"MatI_Ride_FengHuang_01a_baseColor.png",
			"MatI_Ride_FengHuang_01a_emissive.png",
			"MatI_Ride_FengHuang_01b_baseColor.png",
			"MatI_Ride_FengHuang_01b_emissive.png",
		},
	},
	visual_size = {
		x = phoenix_scale,
		y = phoenix_scale,
		z = phoenix_scale
	},
	makes_footstep_sound = true,
	damage = 13,
	reach = 2,
	walk_velocity = 1.2,
	run_velocity = 1.6,
	fear_height = 0,
	-- drops = {
	-- 	{
	-- 		name = "mcl_core:emerald",
	-- 		chance = 1,
	-- 		min = 0,
	-- 		max = 1,
	-- 		looting = "common",
	-- 	},
	-- 	{
	-- 		name = "mcl_tools:axe_iron",
	-- 		chance = 100 / 8.5,
	-- 		min = 1,
	-- 		max = 1,
	-- 		looting = "rare",
	-- 	},
	-- },
	-- TODO: sounds
	-- animation = {
	-- 	stand_start = 0,
	-- 	stand_end = 80,
	-- 	stand_speed = 30,
	-- 	walk_start = 0,
	-- 	walk_end = 80,
	-- 	walk_speed = 50,
	-- 	punch_start = 0,
	-- 	punch_end = 80,
	-- 	punch_speed = 25,
	-- 	die_start = 0,
	-- 	die_end = 80,
	-- 	die_speed = 15,
	-- 	die_loop = false,
	-- },
	view_range = 16,
})

mcl_mobs.register_egg(modname .. ":phoenix", "Phoenix", "#959b9b", "#275e61", 0)





local toilet_scale = 10

mcl_mobs.register_mob(modname .. ":toilet", {
	description = "Toilet",
	type = "animal",
	spawn_class = "passive",
	passive = true,
	pathfinding = 1,
	hp_min = 100,
	hp_max = 100,
	xp_min = 100,
	xp_max = 100,
	collisionbox = {
		-0.3 * toilet_scale,
		-0.01 * toilet_scale,
		-0.3 * toilet_scale,
		0.3 * toilet_scale,
		0.3 * toilet_scale,
		0.3 * toilet_scale
	},
	visual = "mesh",
	mesh = "toilet.obj",
	-- head_swivel = "head.control",
	-- bone_eye_height = 2.2,
	-- head_eye_height = 2.2,
	curiosity = 10,
	textures = {
		{
			"Material_10_baseColor.png",--1
			"Cannon_014_baseColor.png",--2?
			-- "Cannon_014_baseColor.png", --2?
			"Mesheseye1Mtl_baseColor.png",--?
			"Ono230071Mtl_baseColor.png",
			"Material_11_001_baseColor.png",--- 
			"base_mouth_baseColor.png",--6
		},
	},
	visual_size = {
		x = toilet_scale,
		y = toilet_scale,
		z = toilet_scale
	},
	makes_footstep_sound = true,
	damage = 13,
	reach = 2,
	walk_velocity = 1.2,
	run_velocity = 1.6,
	fear_height = 0,
	-- drops = {
	-- 	{
	-- 		name = "mcl_core:emerald",
	-- 		chance = 1,
	-- 		min = 0,
	-- 		max = 1,
	-- 		looting = "common",
	-- 	},
	-- 	{
	-- 		name = "mcl_tools:axe_iron",
	-- 		chance = 100 / 8.5,
	-- 		min = 1,
	-- 		max = 1,
	-- 		looting = "rare",
	-- 	},
	-- },
	-- TODO: sounds
	-- animation = {
	-- 	stand_start = 0,
	-- 	stand_end = 80,
	-- 	stand_speed = 30,
	-- 	walk_start = 0,
	-- 	walk_end = 80,
	-- 	walk_speed = 50,
	-- 	punch_start = 0,
	-- 	punch_end = 80,
	-- 	punch_speed = 25,
	-- 	die_start = 0,
	-- 	die_end = 80,
	-- 	die_speed = 15,
	-- 	die_loop = false,
	-- },
	view_range = 16,
})

mcl_mobs.register_egg(modname .. ":toilet", "Toilet", "#959b9b", "#275e61", 0)
