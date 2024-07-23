local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

-- Monster Repellent
minetest.register_tool(modname .. ":zoonami_monster_repellent", {
	description = "Monster Repellent",
	inventory_image = "zoonami_monster_repellent.png",
	tool_capabilities = {
		full_punch_interval = 1.5,
		max_drop_level = 0,
		groupcaps = {},
		damage_groups = {},
	},
	sound = {},
	groups = {},
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "object" then
			if not pointed_thing.ref:is_player() then
				local luaent = pointed_thing.ref:get_luaentity()
				if luaent and luaent.name:find('zoonami:') then
					if luaent._type == "monster" and not luaent._showcase_id then
						luaent.object:remove()
						itemstack:add_wear(1000)
						local player_name = user:get_player_name() or ""
						minetest.sound_play("zoonami_monster_repellent", {to_player = player_name, gain = 0.5}, true)
						return itemstack
					end
				end
			end
		end
	end
})
