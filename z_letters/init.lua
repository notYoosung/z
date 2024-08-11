local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local rawitemstring = [[
textures/z_letters_0.png textures/z_letters_1.png textures/z_letters_2.png textures/z_letters_3.png textures/z_letters_4.png textures/z_letters_5.png textures/z_letters_6.png textures/z_letters_7.png textures/z_letters_8.png textures/z_letters_9.png textures/z_letters_A.png textures/z_letters_ampersand.png textures/z_letters_asterisk.png textures/z_letters_B.png textures/z_letters_C.png textures/z_letters_D.png textures/z_letters_dash.png textures/z_letters_E.png textures/z_letters_equals.png textures/z_letters_exclamation.png textures/z_letters_F.png textures/z_letters_G.png textures/z_letters_H.png textures/z_letters_I.png textures/z_letters_J.png textures/z_letters_K.png textures/z_letters_L.png textures/z_letters_M.png textures/z_letters_N.png textures/z_letters_O.png textures/z_letters_P.png textures/z_letters_plus.png textures/z_letters_Q.png textures/z_letters_question.png textures/z_letters_R.png textures/z_letters_S.png textures/z_letters_T.png textures/z_letters_U.png textures/z_letters_underscore.png textures/z_letters_V.png textures/z_letters_W.png textures/z_letters_X.png textures/z_letters_Y.png textures/z_letters_Z.png
]]
local itemlist = string.split(string.gsub(string.gsub(rawitemstring, "textures/z_letters_", ""), ".png", ""), " ")


local fbox = {type = "fixed", fixed = {-8/16, -1/2, -8/16, 8/16, -7.5/16, 8/16}}


for i,v in ipairs(itemlist) do
    v = string.trim(v)
    minetest.register_node(modname .. ":letters_" .. v, {
        description = v,
        drawtype = "nodebox",
        tiles = {"z_letters_" .. string.trim(v) .. ".png"},
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
