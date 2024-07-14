local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()


minetest.register_node(modname .. ":glow_glass", {
    description = "Glow Glass",
    tiles = {"z_glow_glass.png"},
	groups = {handy=1, glass=1, building_block=1, material_glass=1},
    drawtype = "glasslike_framed_optional",
    sounds = mcl_sounds.node_sound_glass_defaults(),
    light_source = 14,
	paramtype = "light",
	paramtype2 = "glasslikeliquidlevel",
	sunlight_propagates = true,
    _mcl_hardness = 1,
})
