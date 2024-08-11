local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local rawitemstring = [[
]]
local itemlist = string.split(string.gsub(string.gsub(rawitemstring, "textures/z_food_", ""), ".png", ""), " ")


--[[
local gapple_hunger_restore = minetest.item_eat(4)

local function eat_gapple(itemstack, placer, pointed_thing)
	local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
	if rc then return rc end

	if pointed_thing.type == "object" then
		return itemstack
	end

	if itemstack:get_name() == "mcl_core:apple_gold_enchanted" then
		mcl_potions.fire_resistance_func(placer, 1, 300)
		mcl_potions.leaping_func(placer, 1.15, 300)
		mcl_potions.swiftness_func(placer, 1.2, 300)
		mcl_potions.regeneration_func(placer, 0.15, 30)
	else
		mcl_potions.regeneration_func(placer, 2.5, 30)
	end
	return gapple_hunger_restore(itemstack, placer, pointed_thing)
end

        on_place = eat_gapple,

--]]

local function register_food(def)
    minetest.register_craftitem(modname .. ":food_" .. def.itemname, {
        description = def.name,
        wield_image = "z_food_" .. def.itemname .. ".png",
        inventory_image = "z_food_" .. def.itemname .. ".png",
        on_place = minetest.item_eat(def.hunger_points),
        on_secondary_use = minetest.item_eat(def.hunger_points),
        groups = { food = 2, eatable = def.hunger_points--[[, can_eat_when_full = 1 --]]},
        _mcl_saturation = def.saturation,
    })

end


--donuts
local rawitemstring = [[
textures/z_food_donut_chocolate.png textures/z_food_donut_mint.png textures/z_food_donut_strawberry.png
]]
local itemlist = string.split(string.gsub(string.gsub(rawitemstring, "textures/z_food_donut_", ""), ".png", ""), " ")
for i,v in ipairs(itemlist) do
    v = string.trim(v)

    register_food({
        name = v .. " donut",
        itemname = "donut_" .. v,
        hunger_points = 1,
        saturation = 1,
    })
end


--oreo
register_food({
    name = "oreo",
    itemname = "oreo",
    hunger_points = 1,
    saturation = 1,
})


--oranges
register_food({
    name = "orange",
    itemname = "orange",
    hunger_points = 10,
    saturation = 5,
})
register_food({
    name = "orange juice",
    itemname = "orange_juice",
    hunger_points = 1,
    saturation = 1,
})
register_food({
    name = "orange slice",
    itemname = "orange_slice",
    hunger_points = 1,
    saturation = 1,
})

minetest.register_craft({
    output = modname .. ":food_orange",
    groups = {shapeless=1},
    recipe = {
        {modname .. ":food_orange_slice", modname .. ":food_orange_slice", modname .. ":food_orange_slice"},
        {modname .. ":food_orange_slice", modname .. ":food_orange_slice", modname .. ":food_orange_slice"},
        {modname .. ":food_orange_slice", modname .. ":food_orange_slice", ""},
    },
})

minetest.register_craft({
    output = modname .. ":food_orange_juice",
    groups = {shapeless=1},
    recipe = {
        {modname .. ":food_orange_slice", "mcl_potions:glass_bottle"},
    },
})











