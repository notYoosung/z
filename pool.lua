local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()

-- Liquids: Water and lava

--local WATER_ALPHA = 179
local WATER_VISC = 1
local LAVA_VISC = 7
local LIGHT_LAVA = minetest.LIGHT_MAX
local USE_TEXTURE_ALPHA = true

if minetest.features.use_texture_alpha_string_modes then
	USE_TEXTURE_ALPHA = "blend"
end
--z_pool_water_source_animated
minetest.register_node(modname .. ":pool_water_flowing", {
	description = "Flowing Pool Water",
	wield_image = "z_pool_water_source_animated.png^[verticalframe:64:0",
	drawtype = "flowingliquid",
	tiles = {"z_pool_water_source_animated.png^[verticalframe:64:0"},
	special_tiles = {
		{
			image="z_pool_water_source_animated.png",
			backface_culling=false,
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=4.0}
		},
		{
			image="z_pool_water_source_animated.png",
			backface_culling=false,
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=4.0}
		},
	},
	sounds = mcl_sounds.node_sound_water_defaults(),
	is_ground_content = false,
	use_texture_alpha = USE_TEXTURE_ALPHA,
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	drowning = 0,
	liquidtype = "flowing",
	liquid_alternative_flowing = modname .. ":pool_water_flowing",
	liquid_alternative_source = modname .. ":pool_water_source",
	liquid_viscosity = WATER_VISC,
	liquid_range = 0,
	waving = 3,
	post_effect_color = {a=60, r=0x03, g=0x3C, b=0x5C},
	groups = { water=3, liquid=3, puts_out_fire=1, not_in_creative_inventory=1, freezes=1, melt_around=1, dig_by_piston=1},
	_mcl_blast_resistance = 100,
	-- Hardness intentionally set to infinite instead of 100 (Minecraft value) to avoid problems in creative mode
	_mcl_hardness = -1,
    light_source = 1,
})

minetest.register_node(modname .. ":pool_water_source", {
	description = "Pool Water Source",
	drawtype = "liquid",
	waving = 3,
	tiles = {
		{name="z_pool_water_source_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=5.0}}
	},
	special_tiles = {
		-- New-style water source material (mostly unused)
		{
			name="z_pool_water_source_animated.png",
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=5.0},
			backface_culling = false,
		}
	},
	sounds = mcl_sounds.node_sound_water_defaults(),
	is_ground_content = false,
	use_texture_alpha = USE_TEXTURE_ALPHA,
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	drowning = 4,
	liquidtype = "source",
	liquid_alternative_flowing = modname .. ":pool_water_flowing",
	liquid_alternative_source = modname .. ":pool_water_source",
	liquid_viscosity = WATER_VISC,
	liquid_range = 0,
	post_effect_color = {a=60, r=0x03, g=0x3C, b=0x5C},
	groups = { water=3, liquid=3, puts_out_fire=1, freezes=1, not_in_creative_inventory=0, dig_by_piston=1},
	_mcl_blast_resistance = 100,
	-- Hardness intentionally set to infinite instead of 100 (Minecraft value) to avoid problems in creative mode
	_mcl_hardness = -1,
    light_source = 1,
})



minetest.register_node(modname .. ":tiles", {
    description = "Pool Tiles",
    tiles = {"z_pool_tiles.png"},
	is_ground_content = false,
    groups = {pickaxey=1, z_pool=1},
    sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 3,
    _mcl_hardness = 3,
})
