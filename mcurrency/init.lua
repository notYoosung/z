local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

-- Define the bit items
local bits = {
    {name = "1_bit", description = "1 Bit", image = "1_bit.png"},
    {name = "5_bit", description = "5 Bit", image = "5_bit.png"},
    {name = "10_bit", description = "10 Bit", image = "10_bit.png"},
    {name = "50_bit", description = "50 Bit", image = "50_bit.png"},
    {name = "100_bit", description = "100 Bit", image = "100_bit.png"},
    {name = "1000_bit", description = "Bit Token", image = "1000_bit.png"}
}

for _, bit in ipairs(bits) do
    minetest.register_craftitem(modname .. ":" .. bit.name, {
        description = minetest.colorize("#0f0", bit.description .. "\nOfficial Arkacia Currency"),
        inventory_image = bit.image,
        stack_max = 64000
    })
end

-- Define the 3D weapon Scyth of Crypt
minetest.register_tool(modname .. ":scyth_of_crypt", {
    description = "Scyth of Crypt",
    inventory_image = "scyth_of_crypt.png",
    wield_scale = {x=2, y=2, z=2},
    tool_capabilities = {
        full_punch_interval = 0.5, -- Quick weapon
        max_drop_level = 1,
        groupcaps = {
            snappy = {
                times = {[1]=1.50, [2]=1.00, [3]=0.50},
                uses = 100,
                maxlevel = 1
            },
        },
        damage_groups = {fleshy=30},
    },
    wield_image = "scyth_of_crypt.png",
    node_placement_prediction = "",
    groups = {not_in_creative_inventory=1},
})

-- Define the 3D weapon Dracalaber
minetest.register_tool(modname .. ":dracalaber", {
    description = "Dracalaber",
    inventory_image = "dracalaber.png",
    wield_scale = {x=2, y=2, z=2},
    tool_capabilities = {
        full_punch_interval = 0.5, -- Quick weapon
        max_drop_level = 1,
        groupcaps = {
            snappy = {
                times = {[1]=1.50, [2]=1.00, [3]=0.50},
                uses = 100,
                maxlevel = 1
            },
        },
        damage_groups = {fleshy=40},
    },
    wield_image = "dracalaber.png",
    node_placement_prediction = "",
    groups = {not_in_creative_inventory=1},
})
