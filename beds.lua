local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()

local rawitemstring = [[
textures/z_beds_bizop.png textures/z_beds_kraxis.png textures/z_beds_orange.png textures/z_beds_robin.png textures/z_beds_yellow.png
]]
local itemlist = string.split(string.gsub(string.gsub(rawitemstring, "textures/z_beds_", ""), ".png", ""), " ")


for i,v in ipairs(itemlist) do
    v = string.trim(v)

    mcl_beds.register_bed(modname .. ":beds_"..v, {
        description = v .. " bed",
        inventory_image = "z_beds_" .. v .. ".png",
        wield_image = "z_beds_" .. v .. ".png",

        tiles = {
            "z_beds_" .. v .. ".png"
        },
        --[[recipe = {
            {"mcl_wool:"..color, "mcl_wool:"..color, "mcl_wool:"..color},
            {"group:wood", "group:wood", "group:wood"}
        },--]]
    })
end

