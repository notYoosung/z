local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local S = mcl_deepslate.translator





local function register_variants(name, defs)
	-- assert(name, "[mcl_deepslate] register_variants called without a valid name, refer to API.md in mcl_deepslate.")
	-- assert(defs.basename, "[mcl_deepslate] register_variants needs a basename field to work, refer to API.md in mcl_deepslate.")
	-- assert(defs.basetiles, "[mcl_deepslate] register_variants needs a basetiles field to work, refer to API.md in mcl_deepslate.")

	local main_itemstring = "z:tuff_"..defs.basename.."_"..name
	local main_def = table.merge({
		_doc_items_hidden = false,
		tiles = { defs.basetiles.."_"..name..".png" },
		is_ground_content = false,
		groups = { pickaxey = 1, building_block = 1, material_stone = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
		_mcl_blast_resistance = 6,
		_mcl_hardness = 3.5,
		_mcl_silk_touch_drop = true,
	}, defs.basedef or {})
	if defs.node then
		defs.node.groups = table.merge(main_def.groups, defs.node.groups)
		minetest.register_node(main_itemstring, table.merge(main_def, defs.node))
	end

	if defs.cracked then
		minetest.register_node(main_itemstring.."_cracked", table.merge(main_def, {
			_doc_items_longdesc = S("@1 are a cracked variant.", defs.cracked.description),
			tiles = { defs.basetiles.."_"..name.."_cracked.png" },
		}, defs.cracked))
	end
	if defs.node and defs.stair then
		mcl_stairs.register_stair(defs.basename.."_"..name, {
			description = defs.stair.description,
			baseitem = main_itemstring,
			overrides = defs.stair
		})
	end
	if defs.node and defs.slab then
		mcl_stairs.register_slab(defs.basename.."_"..name, {
			description = defs.slab.description,
			baseitem = main_itemstring,
			overrides = defs.slab
		})
	end

	if defs.node and defs.wall then
		mcl_walls.register_wall("z:tuff_"..defs.basename..name.."wall", defs.wall.description, main_itemstring, nil, nil, nil, nil, defs.wall)
	end
end



local function register_tuff_variant(name, defs)
	register_variants(name,table.update({
		basename = "tuff",
		basetiles = "mcl_deepslate_tuff",
		basedef = {
			_mcl_hardness = 1.5,
		},
	}, defs))
end

minetest.register_node(modname .. ":tuff", {
	description = S("Tuff"),
	_doc_items_longdesc = S("Tuff is an ornamental rock formed from volcanic ash, occurring in underground blobs below Y=16."),
	_doc_items_hidden = false,
	tiles = { "mcl_deepslate_tuff.png" },
	groups = { pickaxey = 1, building_block = 1, converts_to_moss = 1 },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})

minetest.register_node(modname .. ":tuff_chiseled", {
    description = S("Chiseled Tuff"),
    _doc_items_longdesc = S("Chiseled tuff is a chiseled variant of tuff."),
    _doc_items_hidden = false,
    tiles = { "mcl_deepslate_tuff_chiseled_top.png", "mcl_deepslate_tuff_chiseled_top.png", "mcl_deepslate_tuff_chiseled.png" },
    groups = { pickaxey = 1, building_block = 1 },
    sounds = mcl_sounds.node_sound_stone_defaults(),
    _mcl_blast_resistance = 6,
    _mcl_hardness = 1.5,
    _mcl_stonecutter_recipes = { modname .. ":tuff", },
})

minetest.register_node(modname .. ":tuff_chiseled_bricks", {
    description = S("Chiseled Tuff Bricks"),
    _doc_items_longdesc = S("Chiseled tuff bricks are a variant of tuff bricks, featuring a large brick in the center of the block, with geometric design above and below."),
    _doc_items_hidden = false,
    tiles = { "mcl_deepslate_tuff_chiseled_bricks_top.png", "mcl_deepslate_tuff_chiseled_bricks_top.png", "mcl_deepslate_tuff_chiseled_bricks.png"},
    groups = { pickaxey = 1, building_block = 1 },
    sounds = mcl_sounds.node_sound_stone_defaults(),
    _mcl_blast_resistance = 6,
    _mcl_hardness = 1.5,
    _mcl_stonecutter_recipes = { modname .. ":tuff", modname .. ":tuff_polished", modname .. ":tuff_bricks", },
})

register_tuff_variant("", {
    stair = {
        description = S("Tuff Stairs"),
        _mcl_stonecutter_recipes = { modname .. ":tuff", },
    },
    slab = {
        description = S("Tuff Slab"),
        _mcl_stonecutter_recipes = { modname .. ":tuff", },
    },
    wall = {
        description = S("Tuff Wall"),
        _mcl_stonecutter_recipes = { modname .. ":tuff", },
    },
})

register_tuff_variant("polished", {
    node = {
        description = S("Polished Tuff"),
        _doc_items_longdesc = S("Polished tuff is a polished variant of the tuff block."),
        groups = { stonecuttable = 1 },
        _mcl_stonecutter_recipes = { modname .. ":tuff", },
    },
    stair = {
        description = S("Polished Tuff Stairs"),
        _mcl_stonecutter_recipes = { modname .. ":tuff", modname .. ":tuff_polished", },
    },
    slab = {
        description = S("Polished Tuff Slab"),
        _mcl_stonecutter_recipes = { modname .. ":tuff", modname .. ":tuff_polished", },
    },
    wall = {
        description = S("Polished Tuff Wall"),
        _mcl_stonecutter_recipes = { modname .. ":tuff", modname .. ":tuff_polished", },
    },
})

register_tuff_variant("bricks", {
    node = {
        description = S("Tuff Bricks"),
        _doc_items_longdesc = S("Tuff bricks are a brick variant of tuff."),
        groups = { stonecuttable = 1 },
        _mcl_stonecutter_recipes = { modname .. ":tuff_polished", },
    },
    stair = {
        description = S("Tuff Bricks Stairs"),
        _mcl_stonecutter_recipes = { modname .. ":tuff", modname .. ":tuff_polished", modname .. ":tuff_polished", },
    },
    slab = {
        description = S("Tuff Bricks Slab"),
        _mcl_stonecutter_recipes = { modname .. ":tuff", modname .. ":tuff_polished", modname .. ":tuff_polished", },
    },
    wall = {
        description = S("Tuff Bricks Wall"),
        _mcl_stonecutter_recipes = { modname .. ":tuff", modname .. ":tuff_polished", modname .. ":tuff_polished", },
    },
})

minetest.register_craft({
	output = modname .. ":tuff_polished 4",
	recipe = { { modname .. ":tuff", modname .. ":tuff" }, { modname .. ":tuff", modname .. ":tuff" } }
})

minetest.register_craft({
	output = modname .. ":tuff_bricks 4",
	recipe = { { modname .. ":tuff_polished", modname .. ":tuff_polished" }, { modname .. ":tuff_polished", modname .. ":tuff_polished" } }
})

minetest.register_craft({
	output = modname .. ":tuff_chiseled",
	recipe = {
		{ "mcl_stairs:slab_tuff_polished" },
		{ "mcl_stairs:slab_tuff_polished" },
	},
})

minetest.register_craft({
	output = modname .. ":tuff_chiseled_bricks",
	recipe = {
		{ "mcl_stairs:slab_tuff_bricks" },
		{ "mcl_stairs:slab_tuff_bricks" },
	},
})
