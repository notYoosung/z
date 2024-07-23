local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

-- Uses default mod sounds if they are installed otherwise falls back to Zoonami sounds

-- Local namespace
local sounds = {}

-- Default sounds
sounds.default = {}
sounds.default.footstep = {name = ""}
sounds.default.dug = {name = "zoonami_wood_footstep"}
sounds.default.place = {name = "zoonami_place_node"}

sounds.leaves = {}
sounds.leaves.footstep = {name = "zoonami_grass_footstep", gain = 0.6}
sounds.leaves.dig = {name = "zoonami_grass_footstep"}
sounds.leaves.dug = {name = "zoonami_grass_footstep"}
sounds.leaves.place = {name = "zoonami_place_node"}

sounds.glass = {}
sounds.glass.footstep = {name = "zoonami_glass_footstep", gain = 0.2}
sounds.glass.dig = {name = "zoonami_glass_footstep", gain = 0.5}
sounds.glass.dug = {name = "zoonami_glass_dug", gain = 0.4}
sounds.glass.place = {name = "zoonami_place_node_hard"}

sounds.gravel = {}
sounds.gravel.footstep = {name = "zoonami_gravel_footstep", gain = 0.6}
sounds.gravel.dig = {name = "zoonami_gravel_dig"}
sounds.gravel.dug = {name = "zoonami_gravel_footstep"}
sounds.gravel.place = {name = "zoonami_place_node"}

sounds.stone = {}
sounds.stone.footstep = {name = "zoonami_hard_footstep"}
sounds.stone.dig = {name = "zoonami_hard_footstep"}
sounds.stone.dug = {name = "zoonami_hard_footstep"}
sounds.stone.place = {name = "zoonami_place_node_hard"}

sounds.water = {}
sounds.water.footstep = {name = "zoonami_water_footstep", gain = 0.35}
sounds.water.place = {name = "zoonami_place_node"}

sounds.wood = {}
sounds.wood.footstep = {name = "zoonami_wood_footstep", gain = 0.6}
sounds.wood.dig = {name = "zoonami_wood_footstep"}
sounds.wood.dug = {name = "zoonami_hard_footstep"}
sounds.wood.place = {name = "zoonami_place_node_hard"}

-- Mod support
if minetest.get_modpath("default") and default then
	if default.node_sound_defaults then
		sounds.default = default.node_sound_defaults()
	end
	if default.node_sound_leaves_defaults then
		sounds.leaves = default.node_sound_leaves_defaults()
	end
	if default.node_sound_glass_defaults then
		sounds.glass = default.node_sound_glass_defaults()
	end
	if default.node_sound_gravel_defaults then
		sounds.gravel = default.node_sound_gravel_defaults()
	end
	if default.node_sound_stone_defaults then
		sounds.stone = default.node_sound_stone_defaults()
	end
	if default.node_sound_water_defaults then
		sounds.water = default.node_sound_water_defaults()
	end
	if default.node_sound_wood_defaults then
		sounds.wood = default.node_sound_wood_defaults()
	end
elseif minetest.get_modpath("mcl_sounds") and mcl_sounds then
	if mcl_sounds.node_sound_defaults then
		sounds.default = mcl_sounds.node_sound_defaults()
	end
	if mcl_sounds.node_sound_leaves_defaults then
		sounds.leaves = mcl_sounds.node_sound_leaves_defaults()
	end
	if mcl_sounds.node_sound_glass_defaults then
		sounds.glass = mcl_sounds.node_sound_glass_defaults()
	end
	if mcl_sounds.node_sound_dirt_defaults then
		sounds.gravel = mcl_sounds.node_sound_dirt_defaults({
			footstep = {name = "default_gravel_footstep", gain = 0.45},
		})
	end
	if mcl_sounds.node_sound_stone_defaults then
		sounds.stone = mcl_sounds.node_sound_stone_defaults()
	end
	if mcl_sounds.node_sound_water_defaults then
		sounds.water = mcl_sounds.node_sound_water_defaults()
	end
	if mcl_sounds.node_sound_wood_defaults then
		sounds.wood = mcl_sounds.node_sound_wood_defaults()
	end
end

return sounds
