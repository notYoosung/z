local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname) .. "/FumoPlushies"

local FUMOS = {
    "cirno", "reimu", "cirnowhatsapp", "mikuhatsune"
}

local SPECIALITEMS = {"mcl_core:snow", "mcl_core:gold_ingot", "mcl_wool:green", "mcl_wool:blue"}

minetest.register_craftitem(modname .. ":fumoplushies_plushie", {
	description = "A base for a fumo",
	inventory_image = "fumobaseitem.png"
})

for i = 1, #FUMOS do
    minetest.register_node(modname .. ":fumoplushies_" .. FUMOS[i] .. "plushie", {
        description = "she looks squishy",
        drawtype = "mesh",
        mesh = "fumo" .. FUMOS[i] .. ".obj",
        tiles = {"fumo" .. FUMOS[i] .. ".png"},
        paramtype2 = "facedir",
        paramtype = "light",
        sunlight_propagates = true,
        selection_box = {
            type= "fixed",
            fixed = {-0.3, -0.46, -0.4, 0.3, 0.3, 0.3}
        },
        collision_box = {
            type = "fixed",
            fixed = {-0.3, -0.46, -0.4, 0.3, 0.3, 0.3}
        },
        is_ground_content = false,
        groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 3,
        flammable = 3, wool = 1},
    })
end
-------------------------------------------------------------------------
minetest.register_craft({
    output =  modname .. ":fumoplushies_plushie 1",
    recipe = {
    	{"", "mcl_mobitems:string ", ""},
    	{"mcl_wool:white", "mcl_wool:white", "mcl_wool:white"},
    	{"", "mcl_wool:white", ""}
    }
})
for i = 1, #FUMOS do
    minetest.register_craft({
        type = "shapeless",
        output =  modname .. ":fumoplushies_" .. FUMOS[i] .. "plushie 1",
        recipe = {modname .. ":fumoplushies_plushie",SPECIALITEMS[i]}
    })
end

