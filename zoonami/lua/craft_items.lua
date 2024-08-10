-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local monsters = dofile(mod_path .. "/lua/monsters.lua")

-- Berries and Jelly
local function register_berry(name, asset_name)
	minetest.register_craftitem(modname .. ":zoonami_"..asset_name.."_berry", {
		description = name.." Berry",
		inventory_image = "zoonami_"..asset_name.."_berry.png",
	})
	minetest.register_craftitem(modname .. ":zoonami_basic_"..asset_name.."_jelly", {
		description = "Basic "..name.." Jelly",
		inventory_image = "zoonami_basic_"..asset_name.."_jelly.png",
	})
	minetest.register_craftitem(modname .. ":zoonami_improved_"..asset_name.."_jelly", {
		description = "Improved "..name.." Jelly",
		inventory_image = "zoonami_improved_"..asset_name.."_jelly.png",
	})
	minetest.register_craftitem(modname .. ":zoonami_advanced_"..asset_name.."_jelly", {
		description = "Advanced "..name.." Jelly",
		inventory_image = "zoonami_advanced_"..asset_name.."_jelly.png",
	})
end

-- Berries
register_berry("Blue", "blue")
register_berry("Red", "red")
register_berry("Orange", "orange")
register_berry("Green", "green")

-- Golden Jelly
minetest.register_craftitem(modname .. ":zoonami_golden_jelly", {
	description = "Golden Jelly",
	inventory_image = "zoonami_golden_jelly.png",
})

-- Sanded Plank
minetest.register_craftitem(modname .. ":zoonami_sanded_plank", {
	description = "Sanded Plank",
	inventory_image = "zoonami_sanded_plank.png",
	groups = {flammable = 3},
})

-- Stick
minetest.register_craftitem(modname .. ":zoonami_stick", {
	description = "Stick",
	inventory_image = "zoonami_stick.png",
	groups = {stick = 1, flammable = 2},
})

-- Cloth
minetest.register_craftitem(modname .. ":zoonami_cloth", {
	description = "Cloth",
	inventory_image = "zoonami_cloth.png",
	groups = {flammable = 3},
})

-- Paper
minetest.register_craftitem(modname .. ":zoonami_paper", {
	description = "Paper",
	inventory_image = "zoonami_paper.png",
	groups = {flammable = 3},
})

-- Zeenite Lump
minetest.register_craftitem(modname .. ":zoonami_zeenite_lump", {
	description = "Zeenite Lump",
	inventory_image = "zoonami_zeenite_lump.png"
})

-- Zeenite Ingot
minetest.register_craftitem(modname .. ":zoonami_zeenite_ingot", {
	description = "Zeenite Ingot",
	inventory_image = "zoonami_zeenite_ingot.png"
})

-- Crystal Fragment
minetest.register_craftitem(modname .. ":zoonami_crystal_fragment", {
	description = "Crystal Fragment",
	inventory_image = "zoonami_crystal_fragment.png",
})

-- Empty Pail
minetest.register_craftitem(modname .. ":zoonami_pail_empty", {
	description = "Empty Pail",
	inventory_image = "zoonami_pail_empty.png",
	liquids_pointable = true,
	stack_max = 1,
	on_place = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)
		local player_name = user:get_player_name()
		local inv = user:get_inventory()
		local node = minetest.get_node_or_nil(pointed_thing.under)
		local def = node and minetest.registered_nodes[node.name] or {}
		if minetest.is_protected(pos, player_name) then
			return
		elseif def.on_rightclick then
			return def.on_rightclick(pointed_thing.under, node, user, itemstack)
		elseif node.name == modname .. ":zoonami_crystal_water_source" then
			minetest.sound_play("zoonami_water_footstep", {to_player = player_name, gain = 0.8}, true)
			minetest.set_node(pos, {name = "air"})
			return ItemStack(modname .. ":zoonami_pail_crystal_water")
		end
	end,
})

-- Crystal Water Pail
minetest.register_craftitem(modname .. ":zoonami_pail_crystal_water", {
	description = "Crystal Water Pail",
	inventory_image = "zoonami_pail_crystal_water.png",
	liquids_pointable = true,
	stack_max = 1,
	on_place = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end
		local player_name = user:get_player_name()
		local inv = user:get_inventory()
		local node = minetest.get_node_or_nil(pointed_thing.under)
		local def = node and minetest.registered_nodes[node.name] or {}
		local pos = def.buildable_to and pointed_thing.under or pointed_thing.above
		if minetest.is_protected(pos, player_name) then
			return
		elseif def.on_rightclick and not user:get_player_control().sneak then
			return def.on_rightclick(pointed_thing.under, node, user, itemstack)
		elseif pointed_thing.type == "node" then
			minetest.sound_play("zoonami_water_footstep", {to_player = player_name, gain = 0.8}, true)
			minetest.set_node(pos, {name = modname .. ":zoonami_crystal_water_source"})
			return ItemStack(modname .. ":zoonami_pail_empty")
		end
	end,
})

-- Prism
minetest.register_craftitem(modname .. ":zoonami_prism", {
	description = "Prism",
	inventory_image = "zoonami_prism.png",
	on_use = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() or pointed_thing.type ~= "object" then return end
		local player_name = user:get_player_name()
		local obj = pointed_thing.ref
		local self = obj and obj:get_luaentity() or {}
		if self.name:find('zoonami_') and self._type == "monster" and self._prisma_id then
			minetest.chat_send_player(player_name, "Prisma Monster")
		elseif self.name:find('zoonami_') and self._type == "monster" then
			minetest.chat_send_player(player_name, "Normal Monster")
		end
	end,
})

-- Coins
local function register_coin(name, asset_name, value)
	minetest.register_craftitem(modname .. ":zoonami_"..asset_name, {
		description = name,
		inventory_image = "zoonami_"..asset_name..".png",
		on_secondary_use = function (itemstack, user, pointed_thing)
			if not user or not user:is_player() then return end
			local name = user:get_player_name()
			local meta = user:get_meta()
			local current_zc = meta:get_int("zoonami_coins")
			local deposit_zc = itemstack:get_count() * value
			meta:set_int("zoonami_coins", current_zc + deposit_zc)
			minetest.sound_play("zoonami_coins", {to_player = name, gain = 0.9}, true)
			minetest.log("action", name.." deposited "..deposit_zc.." ZC into their bank.")
			minetest.chat_send_player(name, deposit_zc.." ZC has been added to your bank.")
			return ItemStack()
		end,
		on_place = function(itemstack, placer, pointed_thing)
			if not placer or not placer:is_player() then return end
			local node = minetest.get_node_or_nil(pointed_thing.under)
			local def = node and minetest.registered_nodes[node.name] or {}
			if def.on_rightclick then
				return def.on_rightclick(pointed_thing.under, node, placer, itemstack)
			else
				local name = placer:get_player_name()
				local meta = placer:get_meta()
				local current_zc = meta:get_int("zoonami_coins")
				local deposit_zc = itemstack:get_count() * value
				meta:set_int("zoonami_coins", current_zc + deposit_zc)
				minetest.sound_play("zoonami_coins", {to_player = name, gain = 0.9}, true)
				minetest.log("action", name.." deposited "..deposit_zc.." ZC into their bank.")
				minetest.chat_send_player(name, deposit_zc.." ZC has been added to your bank.")
				return ItemStack()
			end
		end,
	})
end

-- Coins
register_coin("1 ZC Coin", "1_zc_coin", 1)
register_coin("10 ZC Coin", "10_zc_coin", 10)
register_coin("100 ZC Coin", "100_zc_coin", 100)
register_coin("1000 ZC Coin", "1000_zc_coin", 1000)
