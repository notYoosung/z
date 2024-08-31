local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)


local scp_173_peanut_scale = 5

mcl_mobs.register_mob(modname .. ":scp_173_peanut", {
	description = "SCP 173 [Peanut]",
	type = "monster",
	spawn_class = "hostile",
	persist_in_peaceful = true,
	pathfinding = 1,
	hp_min = 100,
	hp_max = 100,
	xp_min = 100,
	xp_max = 100,
	collisionbox = {
		-0.1 * scp_173_peanut_scale,
		-0.01 * scp_173_peanut_scale,
		-0.1 * scp_173_peanut_scale,
		0.1 * scp_173_peanut_scale,
		0.1 * scp_173_peanut_scale,
		0.1 * scp_173_peanut_scale
	},
	visual = "mesh",
	mesh = "scp_173_peanut.obj",
	-- head_swivel = "head.control",
	-- bone_eye_height = 2.2,
	-- head_eye_height = 2.2,
	curiosity = 10,
	textures = {
		{
			"173texture_diffuse.png",
			"173texture_specularGlossiness.png",
		},
	},
	visual_size = {
		x = scp_173_peanut_scale,
		y = scp_173_peanut_scale,
		z = scp_173_peanut_scale
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

	pushable = false,
	mob_pushable = false,
	walk_chance = 0,
	knock_back = false,
	jump = false,
	can_despawn = false,
	fall_speed = 0,
	does_not_prevent_sleep = true,
	noyaw = true,
})

mcl_mobs.register_egg(modname .. ":scp_173_peanut", "SCP 173 [Peanut]", "#959b9b", "#275e61", 0)





local t = {
	"drawnmesh0_baseColor.png",
	"drawnmesh0_normal.png",
	"drawnmesh1_baseColor.png",
	"drawnmesh2_baseColor.png",
	"drawnmesh3_baseColor.png",
	"drawnmesh3_normal.png",
	"drawnmesh4_baseColor.png",
	"drawnmesh5_baseColor.png",
	"drawnmesh6_baseColor.png",
	"drawnmesh7_baseColor.png",
	"drawnmesh7_emissive.png",
	"drawnmesh8_baseColor.png",
	"drawnmesh10_baseColor.png",
	"drawnmesh11_baseColor.png",
	"drawnmesh12_baseColor.png",
	"drawnmesh12_normal.png",
	"drawnmesh13_baseColor.png",
	"drawnmesh14_baseColor.png",
	"drawnmesh15_baseColor.png",
	"drawnmesh16_baseColor.png",
	"drawnmesh16_normal.png",
	"drawnmesh18_baseColor.png",
	"drawnmesh19_baseColor.png",
}

local tiles = {}
for i, v in ipairs(t) do
	tiles[#t-i] = v
end


minetest.register_node(modname .. ":scp_173_containment_chamber", {
   	description = "SCP 173 Containment Chamber",
--    inventory_image = ".png",
	drawtype = "mesh",
	mesh = "scp_173_containment_chamber.obj",
   	tiles = tiles,
	visual_size = {x = 2, y = 2, z = 2},
})




--[[
		"drawnmesh0_baseColor.png",
		"drawnmesh0_normal.png",
		"drawnmesh1_baseColor.png",
		"drawnmesh2_baseColor.png",
		"drawnmesh3_baseColor.png",
		"drawnmesh3_normal.png",
		"drawnmesh4_baseColor.png",
		"drawnmesh5_baseColor.png",
		"drawnmesh6_baseColor.png",
		"drawnmesh7_baseColor.png",
		"drawnmesh7_emissive.png",
		"drawnmesh8_baseColor.png",
		"drawnmesh10_baseColor.png",
		"drawnmesh11_baseColor.png",
		"drawnmesh12_baseColor.png",
		"drawnmesh12_normal.png",
		"drawnmesh13_baseColor.png",
		"drawnmesh14_baseColor.png",
		"drawnmesh15_baseColor.png",
		"drawnmesh16_baseColor.png",
		"drawnmesh16_normal.png",
		"drawnmesh18_baseColor.png",
		"drawnmesh19_baseColor.png",
]]