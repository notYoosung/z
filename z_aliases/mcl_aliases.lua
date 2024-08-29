minetest.register_on_mods_loaded(function()
    for k, v in pairs(minetest.registered_nodes) do
        if v:gmatch("^mcl_") then
            minetest.register_alias("mcl:" .. v:match("mcl_.*:(.*)"), v)
            minetest.register_alias(v:match("mcl_.*:(.*)"), v)
        end
    end
end)