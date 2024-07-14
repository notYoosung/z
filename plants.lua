local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()

local rawitemstring = [[
textures/z_plants_bamboo_endcap.png textures/z_plants_birch_sapling.png textures/z_plants_blue_mushroom_1.png textures/z_plants_chrysanthemum_green.png textures/z_plants_dandelion_white.png textures/z_plants_dandelion_yellow.png textures/z_plants_ethereal_crystal_spike.png textures/z_plants_ethereal_fern.png textures/z_plants_geranium.png textures/z_plants_moss_1.png textures/z_plants_moss_2.png textures/z_plants_mushroom_brown.png textures/z_plants_mushroom_red.png textures/z_plants_orange_mushroom_1.png textures/z_plants_orange_mushroom_2.png textures/z_plants_plant_1.png textures/z_plants_plant_2.png textures/z_plants_rose.png textures/z_plants_shrub_1.png textures/z_plants_shrub_2.png textures/z_plants_shrub_3_4_bottom.png textures/z_plants_shrub_3.png textures/z_plants_shrub_4.png textures/z_plants_strawberry_1.png textures/z_plants_strawberry_2.png textures/z_plants_strawberry_3.png textures/z_plants_strawberry_4.png textures/z_plants_tulip_black.png textures/z_plants_tulip.png textures/z_plants_viola.png textures/z_plants_wheat_6.png textures/z_plants_wild_onion_5.png textures/z_plants_willow_twig.png
]]
local itemlist = string.split(string.gsub(string.gsub(rawitemstring, "textures/z_plants_", ""), ".png", ""), " ")


local fbox = {
    type = "fixed",
    fixed = {{ -6/16, -8/16, -6/16, 6/16, 4/16, 6/16 }},
}


local plantsdef = {
	drawtype = "plantlike",
	use_texture_alpha = "clip",
	node_box = fbox,
	collision_box = fbox,
	groups = {oddly_breakable_by_hand=1, z_item=1,
		handy = 1, shearsy = 1, deco_block = 1,
		plant = 1, place_flowerlike = 2, non_mycelium_plant = 1,
		flammable = 3, fire_encouragement = 60, fire_flammability = 10, dig_by_piston = 1,
		dig_by_water = 1, destroy_by_lava_flow = 1, compostability = 30, grass_palette = 1
	},
	selection_box = fbox,

	paramtype = "light",
	-- paramtype2 = "wallmounted",
	sunlight_propagates = true,
	node_placement_prediction = "",
	--inventory_image = "z_items_" .. v .. ".png"
	walkable = false,
	buildable_to = true,
	sounds = mcl_sounds.node_sound_leaves_defaults(),


	_mcl_blast_resistance = 0,
	_mcl_hardness = 0,
}

for i,v in ipairs(itemlist) do
    v = string.trim(v)

    minetest.register_node(modname .. ":plants_" .. v, table.merge(plantsdef, {
		description = v,
		tiles = {"z_plants_" .. v .. ".png"},	
	}))

	mcl_flowerpots.register_potted_flower(modname .. ":plants_" .. v, {
		name = v,
		desc = v,
		image = "z_plants_" .. v .. ".png",
	})
end




--flat nodes
itemlist = {
	"moss_1",
	"moss_2",
}
local fbox = {type = "fixed", fixed = {-8/16, -1/2, -8/16, 8/16, -7.5/16, 8/16}}

for i,v in ipairs(itemlist) do
    v = string.trim(v)
	minetest.register_node(modname .. ":plants_" .. v, table.merge(plantsdef, {
		description = v,
		tiles = {"z_plants_" .. v .. ".png"},
		node_box = fbox,
		collision_box = fbox,
		selection_box = fbox,
		drawtype = "nodebox",
		

		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		node_placement_prediction = "",
	}))
	mcl_flowerpots.register_potted_flower(modname .. ":plants_" .. v, {
		name = v,
		desc = v,
		image = "z_plants_" .. v .. ".png",
	})
end



--pillarable nodes
itemlist = {
	"bamboo_1",
	"standing_tree_bottom",
	"vine",
}
fbox = {
    type = "fixed",
    fixed = {{ -6/16, -8/16, -6/16, 6/16, 8/16, 6/16 }},
}

for i,v in ipairs(itemlist) do
    v = string.trim(v)
	minetest.register_node(modname .. ":plants_" .. v, table.merge(plantsdef, {
		description = v,
		tiles = {"z_plants_" .. v .. ".png"},
		node_box = fbox,
		collision_box = fbox,
		selection_box = fbox,
		drawtype = "plantlike",
		
		groups = {oddly_breakable_by_hand=1,
			handy = 1, shearsy = 1, deco_block = 1,
			plant = 1, non_mycelium_plant = 1,
			flammable = 3, fire_encouragement = 60, fire_flammability = 10, dig_by_piston = 1,
			dig_by_water = 1, destroy_by_lava_flow = 1, compostability = 30, grass_palette = 1
		},

		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		node_placement_prediction = "",
		buildable_to = false,
		climbable = true,
	}))
	mcl_flowerpots.register_potted_flower(modname .. ":plants_" .. v, {
		name = v,
		desc = v,
		image = "z_plants_" .. v .. ".png",
	})
end







local def_tallgrass = {
	description = "Tall Grass",
	drawtype = "plantlike",
	waving = 1,
	tiles = {"mcl_flowers_tallgrass.png"},
	inventory_image = "mcl_flowers_tallgrass_inv.png",
	wield_image = "mcl_flowers_tallgrass_inv.png",
	selection_box = {
		type = "fixed",
		fixed = {{ -6/16, -8/16, -6/16, 6/16, 4/16, 6/16 }},
	},
	paramtype = "light",
	paramtype2 = "color",
	palette = "mcl_core_palette_grass.png",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	is_ground_content = true,
	groups = {
		handy = 1, shearsy = 1, attached_node = 1, deco_block = 1,
		plant = 1, place_flowerlike = 2, non_mycelium_plant = 1,
		flammable = 3, fire_encouragement = 60, fire_flammability = 10, dig_by_piston = 1,
		dig_by_water = 1, destroy_by_lava_flow = 1, compostability = 30, grass_palette = 1
	},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	drop = wheat_seed_drop,
	_mcl_shears_drop = true,
	_mcl_fortune_drop = fortune_wheat_seed_drop,
	node_placement_prediction = "",
	on_place = on_place_flower,
	_mcl_blast_resistance = 0,
	_mcl_hardness = 0,
}

local def_clover = table.copy(def_tallgrass)
def_clover.description = "Clover"
def_clover.drawtype = "mesh"
def_clover.mesh = "mcl_clover_3leaf.obj"
def_clover.tiles = { "mcl_flowers_clover.png" }
def_clover.inventory_image = "mcl_flowers_clover_inv.png"
def_clover.wield_image = "mcl_flowers_clover_inv.png"
def_clover.use_texture_alpha = "clip"
def_clover.drop = "z:plants_clover"
def_clover.selection_box = {
	type = "fixed",
	fixed = { -4/16, -0.5, -4/16, 4/16, 0, 4/16 },
}
def_clover.groups.compostability = 30

minetest.register_node(modname .. ":plants_clover", def_clover)

local def_4l_clover = table.copy(def_clover)
def_4l_clover.description = "Four-leaf Clover"
def_4l_clover.mesh = "mcl_clover_4leaf.obj"
def_4l_clover.tiles = { "mcl_flowers_fourleaf_clover.png" }
def_4l_clover.inventory_image = "mcl_flowers_fourleaf_clover_inv.png"
def_4l_clover.wield_image = "mcl_flowers_fourleaf_clover_inv.png"
def_4l_clover.use_texture_alpha = "clip"
def_4l_clover.drop = "z:fourleaf_clover"

minetest.register_node(modname .. ":plants_fourleaf_clover", def_4l_clover)



local def_clover_large = table.copy(def_clover)
def_clover_large.description = "Large Clover"
def_clover_large.mesh = "mcl_clover_3leaf_large.obj"
def_clover_large.drop = "z:plants_clover_large"
def_clover_large.selection_box = {
	type = "fixed",
	fixed = { -40/16, -0.5, -40/16, 40/16, 5, 40/16 },
}
minetest.register_node(modname .. ":plants_clover_large", def_clover_large)


local def_4l_clover_large = table.copy(def_4l_clover)
def_4l_clover_large.description = "Large Four-leaf Clover"
def_4l_clover_large.mesh = "mcl_clover_4leaf_large.obj"
def_4l_clover_large.drop = "z:plants_fourleaf_clover_large"
def_4l_clover_large.selection_box = {
    type = "fixed",
	fixed = { -40/16, -0.5, -40/16, 40/16, 5, 40/16 },
}
minetest.register_node(modname .. ":plants_fourleaf_clover_large", def_4l_clover_large)


itemlist = {
	"clover",
	"fourleaf_clover",
	"clover_large",
	"fourleaf_clover_large",
}
for i, v in ipairs(itemlist) do
	v = string.trim(v)
	mcl_flowerpots.register_potted_flower(modname .. ":plants_" .. v, {
		name = v,
		desc = v,
		image = "z_plants_" .. v .. ".png",
	})
end