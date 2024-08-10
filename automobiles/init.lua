local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local folders = {
    "lib",
    "beetle",
    "buggy",
    "catrelle",
    "coupe",
    "delorean",
    "motorcycle",
    "roadster",
    "trans_am",
    "vespa",
}

for _, v in ipairs(folders) do
    dofile(modpath .. "/automobiles_" .. v .. "/init.lua")
end