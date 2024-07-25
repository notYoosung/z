local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()

local rawitemstring = [[
textures/z_items_A_Very_Fine_Item.png textures/z_items_adventure_crystal_common.png textures/z_items_adventure_crystal_epic.png textures/z_items_adventure_crystal_legendary.png textures/z_items_adventure_crystal_rare.png textures/z_items_adventure_crystal_uncommon.png textures/z_items_arrow_inv.png textures/z_items_arrow_overlay.png textures/z_items_arrow.png textures/z_items_balloon_black.png textures/z_items_balloon_blue.png textures/z_items_balloon_brown.png textures/z_items_balloon_cyan.png textures/z_items_balloon_gray.png textures/z_items_balloon_green.png textures/z_items_balloon_light_blue.png textures/z_items_balloon_lime.png textures/z_items_balloon_magenta.png textures/z_items_balloon_orange.png textures/z_items_balloon_pink.png textures/z_items_balloon_purple.png textures/z_items_balloon_red.png textures/z_items_balloon_silver.png textures/z_items_balloon_white.png textures/z_items_balloon_yellow.png textures/z_items_bananaonkers.png textures/z_items_barrier.png textures/z_items_batcat.png textures/z_items_beacon.png textures/z_items_bearandme.png textures/z_items_bee_nest_top.png textures/z_items_bee.png textures/z_items_bell_side.png textures/z_items_bobber.png textures/z_items_bubble.png textures/z_items_camera.png textures/z_items_cerulean_robin.png textures/z_items_cerulean_robins.png textures/z_items_cloud.png textures/z_items_composter_top.png textures/z_items_craftguide_book.png textures/z_items_crouton.png textures/z_items_crystallized_honey.png textures/z_items_dakcat.png textures/z_items_death_heart.png textures/z_items_death_particle.png textures/z_items_death.png textures/z_items_dice.png textures/z_items_doge.png textures/z_items_dragonfly.png textures/z_items_droplet_bottle.png textures/z_items_earth_ruby.png textures/z_items_effect_bad_omen.png textures/z_items_effect_fire_proof.png textures/z_items_effect_invisible.png textures/z_items_effect_leaping.png textures/z_items_effect_night_vision.png textures/z_items_effect_poisoned.png textures/z_items_effect_regenerating.png textures/z_items_effect_slow.png textures/z_items_effect_strong.png textures/z_items_effect_swift.png textures/z_items_effect_water_breathing.png textures/z_items_effect_weak.png textures/z_items_effect_withering.png textures/z_items_fancy_feather.png textures/z_items_firework_blue.png textures/z_items_firework_green.png textures/z_items_firework_red.png textures/z_items_firework_white.png textures/z_items_firework_yellow.png textures/z_items_flame.png textures/z_items_frame.png textures/z_items_garbage.png textures/z_items_glow_squid_glint1.png textures/z_items_glow_squid_glint2.png textures/z_items_glow_squid_glint3.png textures/z_items_glow_squid_glint4.png textures/z_items_glyph_2.png textures/z_items_glyph_3.png textures/z_items_glyph_8.png textures/z_items_hammer.png textures/z_items_heart_poison.png textures/z_items_heart_regen_wither.png textures/z_items_heart_regenerate.png textures/z_items_heart_wither.png textures/z_items_heart.png textures/z_items_heavy_core.png textures/z_items_horn.png textures/z_items_ice_bomb.png textures/z_items_instant_effect.png textures/z_items_iron_cat1.png textures/z_items_iron_cat2.png textures/z_items_kitty_pixart.png textures/z_items_leaf.png textures/z_items_lingering_bottle.png textures/z_items_locked_map.png textures/z_items_moon_phase_1.png textures/z_items_moon_phase_2.png textures/z_items_moon_phase_3.png textures/z_items_moon_phase_4.png textures/z_items_moon_phase_5.png textures/z_items_next_icon.png textures/z_items_note.png textures/z_items_nutella_pusheen.png textures/z_items_orb.png textures/z_items_OXf8zn.png textures/z_items_panel_blue.png textures/z_items_panel_cyan.png textures/z_items_panel_dark_green.png textures/z_items_panel_green.png textures/z_items_panel_grey.png textures/z_items_panel_lime.png textures/z_items_panel_magenta.png textures/z_items_panel_orange.png textures/z_items_panel_purple.png textures/z_items_panel_red.png textures/z_items_panel_white.png textures/z_items_panel_yellow.png textures/z_items_particles_effect.png textures/z_items_particles_nether_portal_t.png textures/z_items_particles_nether_portal.png textures/z_items_photo.png textures/z_items_pink_petals.png textures/z_items_portals_particle3.png textures/z_items_portals_particle4.png textures/z_items_portals_particle5.png textures/z_items_portfolio.png textures/z_items_potion_overlay.png textures/z_items_prev_icon.png textures/z_items_riptide.png textures/z_items_rocket_particle.png textures/z_items_ruby.png textures/z_items_salt.png textures/z_items_smoke.png textures/z_items_snowball.png textures/z_items_snowflake1.png textures/z_items_snowflake2.png textures/z_items_stickbug.png textures/z_items_troll_face.png textures/z_items_warning.png textures/z_items_wheatley.png textures/z_items_wheatley2.png textures/z_items_wind_charge.png
]]
local itemlist = string.split(string.gsub(string.gsub(rawitemstring, "textures/z_items_", ""), ".png", ""), " ")

local fbox = {type = "fixed", fixed = {-8/16, -1/2, -8/16, 8/16, -7.5/16, 8/16}}


for i,v in ipairs(itemlist) do
    v = string.trim(v)
    minetest.register_node(modname .. ":items_" .. v, {
        description = v,
        drawtype = "nodebox",
        tiles = {
            {name = "z_items_" .. v .. ".png"},
            {name = "z_items_" .. v .. ".png"},
            {name = "blank.png"},
            {name = "blank.png"},
            {name = "blank.png"},
            {name = "blank.png"},
        },
        use_texture_alpha = "clip",
        node_box = fbox,
        collision_box = fbox,
        groups = {oddly_breakable_by_hand=1, z_item=1},
        selection_box = fbox,

        paramtype = "light",
        paramtype2 = "wallmounted",
	    sunlight_propagates = true,
    	node_placement_prediction = "",
        
        --inventory_image = "z_items_" .. v .. ".png"
    })

end


itemlist = {"flag", "random_paper"}

for i,v in ipairs(itemlist) do
    v = string.trim(v)
    minetest.register_node(modname .. ":items_" .. v, {
        description = v,
        drawtype = "nodebox",
        tiles = {
            {name = "z_arkacia_" .. v .. ".png"},
            {name = "z_arkacia_" .. v .. ".png"},
            {name = "blank.png"},
            {name = "blank.png"},
            {name = "blank.png"},
            {name = "blank.png"},
        },
        use_texture_alpha = "clip",
        node_box = fbox,
        collision_box = fbox,
        groups = {oddly_breakable_by_hand=1, z_item=1},
        selection_box = fbox,

        paramtype = "light",
        paramtype2 = "wallmounted",
	    sunlight_propagates = true,
    	node_placement_prediction = "",
        
        --inventory_image = "z_items_" .. v .. ".png"
    })

end


local panelcolors = {
    "blue",
    "cyan",
    "dark_green",
    "green",
    "grey",
    "lime",
    "magenta",
    "orange",
    "purple",
    "red",
    "white",
    "yellow"
}
for i, v in ipairs(panelcolors) do
    v = string.trim(v)
    minetest.register_node(modname .. ":panel_block_" .. v, {
        description = v .. " Panel Block",
        tiles = {"z_items_panel_" .. v .. ".png"},
        is_ground_content = false,
        groups = {pickaxey=1, z_panel=1},
        sounds = mcl_sounds.node_sound_metal_defaults(),
        _mcl_blast_resistance = 6,
        _mcl_hardness = 5,
    })
end


local light = minetest.LIGHT_MAX


local fireworkcolors = {
    "blue",
    "green",
    "red",
    "white",
    "yellow"
}
local function firework_block_activate(pos, node, puncher, pointed_thing)
	--local nodedef = minetest.registered_nodes[minetest.get_node(pos).name]
	minetest.swap_node(pos, {name=string.gsub(minetest.get_node(pos).name, "_off", "_on")})
end
local function firework_block_deactivate(pos, node, puncher, pointed_thing)
	--local nodedef = minetest.registered_nodes[minetest.get_node(pos).name]
	minetest.swap_node(pos, {name=string.gsub(minetest.get_node(pos).name, "_on", "_off")})
end
for i, v in ipairs(fireworkcolors) do
    v = string.trim(v)
    minetest.register_node(modname .. ":firework_block_" .. v .. "_off", {
        description = v .. " Firework Block",
        tiles = {"z_items_firework_" .. v .. ".png"},
        is_ground_content = false,
        groups = {handy=1, z_firework=1, mesecon_effector_off = 1, mesecon = 2},
        sounds = mcl_sounds.node_sound_glass_defaults(),
        _mcl_blast_resistance = 0.3,
        _mcl_hardness = 0.3,
        on_rightclick = firework_block_activate,
        mesecons = {effector = {
            action_on = function(pos, node)
                minetest.swap_node(pos, {name = modname .. ":firework_block_" .. v .. "_on", param2 = node.param2})
            end,
            rules = mesecon.rules.alldirs,
        }},
    })
    
    minetest.register_node(modname .. ":firework_block_" .. v .. "_on", {
        tiles = {"z_items_firework_" .. v .. ".png"},
        groups = {handy=1, not_in_creative_inventory=1, mesecon = 2, opaque = 1},
        drop = "node " .. modname .. ":firework_block_" .. v .. "_off",
        is_ground_content = false,
        paramtype = "light",
        light_source = light,
        sounds = mcl_sounds.node_sound_glass_defaults(),
        mesecons = {effector = {
            action_off = function(pos)
                local timer = minetest.get_node_timer(pos)
                timer:start(0.2)
            end,
            rules = mesecon.rules.alldirs,
        }},
        on_timer = function (pos)
            minetest.swap_node(pos, { name = modname .. ":firework_block_" .. v .. "_off", param2 = minetest.get_node(pos).param2 })
            return false
        end,
        on_rightclick = firework_block_deactivate,
        _mcl_blast_resistance = 0.3,
        _mcl_hardness = 0.3,
    })
end        





itemlist = {
    {"robin_dance", 256, 20*0.03},
    {"iso", 64, 91/30},
    {"blob", 128, 15/30},
    {"deal_with_it", 512, 24*0.1},
    {"arnott_eye", 64, 125*0.03},
    {"liang_wind", 64, 16*0.2},
    {"spinning_bear", 128, 21*0.08},

    {"you_didnt_have_to_cut_me_off", 128, 324*0.03},
    {"uno_reverse", 128, 38*0.05},
    {"skeleton_berserk", 128, 223*.03},
    {"legendary_uno_reverse", 128, 23*0.06},
    {"honk", 256, 27*0.05},
    {"happy_happy_cat", 128, 120*0.04},
    {"duck", 128, 12*0.05},
    {"duck_dance", 128, 95*0.05},
    {"dance_dance_blob", 128, 8*0.07},
    {"do_the_goos", 256, 5*0.05},
    {"bfdi_factory_top", 256, 49*0.05},
    {"bfdi_factory_bottom", 256, 49*0.05},
}

for i, v in ipairs(itemlist) do
    minetest.register_node(modname .. ":gif_items_" .. v[1], {
        description = v[1],
        drawtype = "nodebox",
        tiles = {
            {
                name = "z_items_" .. v[1] .. ".png",
                animation = {
                    type = "vertical_frames",
                    aspect_w = v[2],
                    aspect_h = v[2],
                    length = v[3]
                }
            },
            {
                name = "z_items_" .. v[1] .. ".png",
                animation = {
                    type = "vertical_frames",
                    aspect_w = v[2],
                    aspect_h = v[2],
                    length = v[3]
                }
            },
            {name = "blank.png"},
            {name = "blank.png"},
            {name = "blank.png"},
            {name = "blank.png"},
        },
        use_texture_alpha = "clip",
        node_box = fbox,
        collision_box = fbox,
        groups = {oddly_breakable_by_hand=1, z_item=1},
        selection_box = fbox,

        paramtype = "light",
        paramtype2 = "wallmounted",
        sunlight_propagates = true,
        node_placement_prediction = "",
    })
end



mcl_stairs.register_stair_and_slab("BEDROCK", {
	baseitem = "mcl_core:bedrock",
	description_stair = minetest.colorize("#FF0000", "OMG BEDROCK STAIRS"),
	description_slab = minetest.colorize("#FF0000", "OMG BEDROCK SLABS"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_core:bedrock"}},
})





minetest.registered_nodes["mcl_core:ice"].drawtype = "normal"
minetest.registered_nodes["mcl_core:ice"].use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "opaque" or false
