goodtorch = {} -- Public API
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

goodtorch.modpath = modpath

goodtorch.player_lights = {}
goodtorch.nodes = { -- Replacement nodes (excluding our own nodes, as they don't change)
	-- Don't need air as air is always air. (That's a lot of air)
	water = {
		source = "",
		flowing = "" -- Uses param2
	},
	river = {
		source = "",
		flowing = "" -- Uses param2
	}
}
dofile(goodtorch.modpath .. "/api.lua")

if goodtorch.detect_gamemode() == "MTG" then
	goodtorch.default_nodeset()
elseif goodtorch.detect_gamemode() == "MCL" then
	goodtorch.mcl_nodeset()
else
	error("This game isn't supported, please go and leave an issue on the github repository with the game name.")
end
-- TODO: Finish implementing the battery drain. I took the code from the
-- headlamp mod. 

local player_lights = {}
local PLAYER_EYE_POS = 1.5 -- Move this possibly to code generation (rather than ugly hardcode)
local has_technic = minetest.get_modpath("technic")
local drain_inv = minetest.settings:get_bool("flashlight_drain_inventory", true)
local battery_life = tonumber(minetest.settings:get("flashlight_battery_life")) or 130
local battery_drain = math.floor(65535 / (battery_life * 60)) * 5
local dist = tonumber(minetest.settings:get("flashlight_strength")) or 16

local function use_battery(stack)
	if stack:get_wear() >= (65535 - battery_drain) then
		stack:set_name(modname .. ":flashlight_off")
		return false
	end

	local props = player:get_properties()
	--minetest.log("action", "[goodtorch] "..minetest.serialize(props))
	return props.eye_height
end

local function can_replace(pos)
	local n = minetest.get_node_or_nil(pos)
	if not n then -- Failed getting node!
		return ""
	end
	local nn = n.name
	local param2 = n.param2 -- Only used for flowing water sources (water, river water)
	if nn == "air" or string.match(nn, modname .. ":light_%d+$") then
		return "air"
	elseif nn == goodtorch.nodes.water.source or string.match(nn, modname .. ":light_water_%d+$") then
		return "aqua"
	elseif nn == goodtorch.nodes.water.flowing or string.match(nn, modname .. ":light_water_flowing_%d+$") then -- 0 to 7 (0 could be ignored and marked as air)
		return "aqua_flow_" .. param2
	-- These 2 below won't work in MineClone (it will be comparing node name to an empty string, so it's fine to leave it like this)
	elseif nn == goodtorch.nodes.river.source or string.match(nn, modname .. ":light_river_%d+$") then
		return "aqua_river"
	elseif nn == goodtorch.nodes.river.flowing or string.match(nn, modname .. ":light_river_flowing_%d+$") then -- 0 to 2 (0 could be ignored and marked as air)
		return "aqua_river_flow_" .. param2
	else -- Unknown node?
		return ""
	end
end
   
local function remove_light(pos)
	if not pos then -- no pos!?!
		return
	end
	local can_repl = can_replace(pos)
	if can_repl == "" then -- Can't replace
		return
	end
	if can_repl == "air" then
		minetest.set_node(pos, {name = "air"})
	elseif can_repl == "aqua" then
		minetest.set_node(pos, {name = goodtorch.nodes.water.source})
	elseif string.match(can_repl, "aqua_flow") then -- Needs param2, "aqua_flow_<param2>"
		local param2 = can_repl:gsub("aqua_flow_", "")
		minetest.set_node(pos, {name = goodtorch.nodes.water.flowing, param2=tonumber(param2)})
	-- These 2 below won't work in MineClone (this should crash as we try to set a node name an empty string into a position, but because the can_replace code shouldn't make use of aqua_river it should be fine/un noticed)
	elseif can_repl == "aqua_river" then
		minetest.set_node(pos, {name = goodtorch.nodes.river.source})
	elseif string.match(can_repl, "aqua_river_flow") then -- Needs param2, "aqua_river_flow_<param2>"
		local param2 = can_repl:gsub("aqua_river_flow_", "")
		minetest.set_node(pos, {name = goodtorch.nodes.river.flowing, param2=tonumber(param2)})
	else -- Emergency fallback (let someone know!)
		minetest.log("action", "[goodtorch] can_replace('" + tostring(pos) + "') => '" + can_repl + "', expected string in {'air', 'aqua', 'aqua_flow_*', 'aqua_river', 'aqua_river_*'}")
	end
end

local function light_name(pos, factor)
	if not pos then -- no pos!?!
		return nil
	end
	local can_repl = can_replace(pos)
	if can_repl == "" then -- Can't replace
		return nil
	end
	if can_repl == "air" then
		return {name = modname .. ":light_".. factor}
	elseif can_repl == "aqua" then
		return {name = modname .. ":light_water_"..factor}
	elseif string.match(can_repl, "aqua_flow") then -- Needs param2, "aqua_flow_<param2>"
		local param2 = can_repl:gsub("aqua_flow_", "")
		return {name = modname .. ":light_water_flowing_" .. factor, param2 = param2}
	elseif can_repl == "aqua_river" then
		return {name = modname .. ":light_river_" .. factor}
	elseif string.match(can_repl, "aqua_river_flow_") then -- Needs param2, "aqua_river_flow_<param2>"
		local param2 = can_repl:gsub("aqua_river_flow_", "")
		return {name = modname .. ":river_flowing_" .. factor, param2 = param2}
	else -- Emergency fallback (let someone know!)
		minetest.log("action", "[goodtorch] light_name('" + tostring(pos) + "', " .. factor .. ") using can_replace() => '" .. can_repl .. "', expected string in {'air', 'aqua', 'aqua_flow_*', 'aqua_river', 'aqua_river_*'}")
		return nil
	end
end

--[[
local function update_inv(player)
	for i=1, inv:get_size("main") do
		local stack = inv:get_stack("main", i)
		if stack:get_name() == modname .. ":flashlight_on" then
			local success = use_battery(stack)
			inv:set_stack("main", i, stack)
			if not success then
					return
			end
		end	
	end
end
]]

-- I have to go to sleep because I'll go to university tomorrow, and this 
-- function doesn't really do much yet, so I'll
-- comment unfinished battery-related stuff out. The flashlight will still
-- work as intended, anyways.

-- Why is this public? (makes no sense for it do be, it's internally used, and calls outside could be bad)
-- lissobone: cuz i was testing

local function get_light_node(player)
	local inv = player:get_inventory()
	local lfactor = 0 -- Light level, closer is brighter, farther is darker (possibly not existent)
	-- local item = player:get_wielded_item():get_name()
	local player_pos = player:get_pos()
	local look_dir = player:get_look_dir()

	-- Check the player has a flashlight on in their inventory (anywhere, except crafting grid)
	-- I made it so the flashlight always works when it's in the player's
	-- inventory and switched on. Very cozy!

	if inv:contains_item("main", modname .. ":flashlight_on") then

		local ps = {}
		for i = 0, dist do
			table.insert(ps, {l = light_name({
				x = player_pos.x + look_dir.x*i,
				y = (player_pos.y + PLAYER_EYE_POS)+look_dir.y*i,
				z = player_pos.z + look_dir.z*i
			}, 14), pos = vector.round(player_pos)})
		end

		local p = vector.zero() -- current node we are checking out
		local nn = "" -- node name for the light node to replace the target with
		local node = nil -- The node we are checking out, if it's not possible we need to stop
		local best = nil -- Closest position that's ok to replace/light up
		local done = false -- Stop it, I want to get off!
		for i = 0, dist, 1 do
			player_pos = player:get_pos()
			look_dir = player:get_look_dir()
			p = {
				x = player_pos.x + look_dir.x*i,
				y = (player_pos.y + PLAYER_EYE_POS)+look_dir.y*i,
				z = player_pos.z + look_dir.z*i
			}

			lfactor = 14--math.floor((-(100/dist))*(i/(7 + 1/7))+14)

			node = minetest.get_node_or_nil(p)
			if node == nil or lfactor < 0 or lfactor > 14 then
				return
			end
			-- This check might break from checking node.name == "" from river water in a MineClone environment
			if node.name ~= "air" and node.name ~= goodtorch.nodes.water.source and node.name ~= goodtorch.nodes.water.flowing and node.name ~= goodtorch.nodes.river.source and node.name ~= goodtorch.nodes.river.flowing and not string.match(node.name, modname .. ":light_") then
				--minetest.log("action", "[goodtorch] i=" .. i .. " node='" .. node.name .. "' dist=" .. vector.distance(player_pos, p))
				done = true
			end
			if can_replace(p) ~= "" then -- If it's valid let's continue with valid choices
				p = {
					x = player_pos.x + (math.sin(look_dir.x)*(i-1)),
					y = player_pos.y + PLAYER_EYE_POS+(math.sin(look_dir.y)*(i-1)),
					z = player_pos.z + (math.sin(look_dir.z)*(i-1))
				}
				nn = light_name(p, lfactor)
				if nn ~= nil then -- Ok we have a nodename let's use it!
					-- Try for the closest
					best = {l = nn, pos = vector.round(p)}

					ps[i] = best
					-- table.insert(ps, best)
					if done then
						-- minetest.log(i)
						return ps
					end
				else
					if done then
						--minetest.log("action", "[goodtorch] Done?")
						-- minetest.log(i)
						return ps
					end
				end
			else
				if done then
					--minetest.log("action", "[goodtorch] Done? Can replace?")
					-- hits node
					-- minetest.log(#ps)
					return ps
				end
			end
		end
		-- hits nothing
		-- minetest.log(#ps)
		return ps
	end
	-- If/Else fallback
	return nil
end

local function update_illumination(player)
	local name = player:get_player_name()

	if not goodtorch.player_lights[name] then
		return  -- Player has just joined/left
	end
	local new_lights = get_light_node(player)
	if not new_lights then return end
	-- for i, v in ipairs(new_lights) do
	-- 	minetest.log(tostring(v.pos))
	-- end
	minetest.log(#goodtorch.player_lights[name])
	local player_pos = player:get_pos()
	for player_lights_pos_indx, player_lights_pos_val in ipairs(goodtorch.player_lights[name]) do
		local old_pos = player_lights_pos_val
		if not new_lights[player_lights_pos_indx] then -- player might not have the light in their hand or on, so let's clear old positions
			-- No illumination
			remove_light(old_pos)
			goodtorch.player_lights[name][player_lights_pos_indx] = nil
			return -- Done for now
		end
		local pos = new_lights[player_lights_pos_indx].pos
		local node = new_lights[player_lights_pos_indx].l

		-- Check if illumination needs updating
		if old_pos and pos then
			if vector.equals(pos, old_pos) then
				return  -- Already has illumination
			end
		end
		-- Update illumination
		if node then
			local dist = vector.distance(player_pos, pos)
			if pos and dist < 100 then -- Only replace if the distance isn't past 100 (99 or less)
				minetest.set_node(pos, node)
				if old_pos and not vector.equals(old_pos, pos) then
					remove_light(old_pos)
				end
				goodtorch.player_lights[name][player_lights_pos_indx] = pos
				return
			end
		end
		-- No illumination
		remove_light(old_pos)
		goodtorch.player_lights[name][player_lights_pos_indx] = nil
	end
end

-- local timer = 0

--[[
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 5 then return end
	timer = 0
	for _, player in pairs(minetest.get_connected_players()) do
		if not minetest.is_creative_enabled(player:get_player_name()) then
			update_inv(player)
		end
	end
end)
]]

minetest.register_globalstep(function()
	for _, player in pairs(minetest.get_connected_players()) do
		update_illumination(player)
	end
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if not goodtorch.player_lights[name] then
		goodtorch.player_lights[name] = {}
		for i = 0, dist, 1 do
			table.insert(goodtorch.player_lights[name], vector.zero())
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	for i = 0, dist, 1 do
		if goodtorch.player_lights[name][i] then
			remove_light(goodtorch.player_lights[name][i].pos)
		end
		goodtorch.player_lights[name][i] = nil
	end
end)

local water_sound = nil
if goodtorch.detect_gamemode() == "MTG" then
	water_sounds = default.node_sound_water_defaults()
elseif goodtorch.detect_gamemode() == "MCL" then
	water_sound = mcl_sounds.node_sound_water_defaults()
end

for n = 0, 14 do
	-- air
	minetest.register_node(modname .. ":light_"..n, {
		drawtype = "airlike",
		paramtype = "light",
		light_source = n,
		sunlight_propagates = true,
		walkable = false,
		pointable = false,
		buildable_to = true,
		air_equivalent = true,
		groups = {
			--not_in_creative_inventory = 1,
			not_blocking_trains = 1,
			flash_light = 1,
		},
		drop = "",
	})

	-- aqua
	minetest.register_node(modname .. ":light_water_"..n, {
		drawtype = "liquid",
		waving = 3,
		tiles = {
			{
				name = "default_water_source_animated.png",
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 5,
				},
			},
			{
				name = "default_water_source_animated.png",
				backface_culling = true,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 5,
				},
			},
		},
		use_texture_alpha = "blend",
		paramtype = "light",
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		light_source = n,
		drop = "",
		drowning = 1,
		liquidtype = "source",
		liquid_alternative_flowing = modname .. ":light_water_flowing_"..n,
		liquid_alternative_source = modname .. ":light_water_"..n,
		liquid_viscosity = 1,
		post_effect_color = {a = 103, r = 30, g = 60, b = 90},
		groups = {water = 3, liquid = 3, cools_lava = 1, flash_light = 1},
		sounds = water_sound,
	})
	-- aqua_flow_<param2>
	minetest.register_node(modname .. ":light_water_flowing_"..n, {
		drawtype = "flowingliquid",
		waving = 3,
		tiles = {"default_water_flowing_animated.png^[verticalframe:64:0"},
		special_tiles = {
			{
				name = "default_water_flowing_animated.png",
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 4,
				},
			},
			{
				name = "default_water_flowing_animated.png",
				backface_culling = true,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 4,
				},
			},
		},
		use_texture_alpha = "blend",
		paramtype = "light",
		paramtype2 = "flowingliquid",
		light_source = n,
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "flowing",
		liquid_alternative_flowing = modname .. ":light_water_flowing_"..n,
		liquid_alternative_source = modname .. ":light_water_"..n,
		liquid_viscosity = 1,
		post_effect_color = {a = 103, r = 30, g = 60, b = 90},
		groups = {water = 3, liquid = 3, not_in_creative_inventory = 1,
			cools_lava = 1, flash_light = 1},
		sounds = water_sound,
	})
	-- aqua_river
	minetest.register_node(modname .. ":light_river_"..n, {
		drawtype = "liquid",
		tiles = {
			{
				name = "z_pool_water_source_animated.png",
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 4.0,
				},
			},
			{
				name = "z_pool_water_source_animated.png",
				backface_culling = true,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 4.0,
				},
			},
		},
		use_texture_alpha = "blend",
		paramtype = "light",
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		light_source = n,
		drop = "",
		drowning = 1,
		liquidtype = "source",
		liquid_alternative_flowing = modname .. ":light_river_flowing_"..n,
		liquid_alternative_source = modname .. ":light_river_"..n,
		liquid_viscosity = 1,
		-- Not renewable to avoid horizontal spread of water sources in sloping
		-- rivers that can cause water to overflow riverbanks and cause floods.
		-- River water source is instead made renewable by the 'force renew'
		-- option used in the 'bucket' mod by the river water bucket.
		liquid_renewable = false,
		liquid_range = 2,
		post_effect_color = {a = 103, r = 30, g = 76, b = 90},
		groups = {water = 3, liquid = 3, cools_lava = 1, flash_light = 1},
		sounds = water_sound,
	})
	-- aqua_river_flow_<param2>
	minetest.register_node(modname .. ":light_river_flowing_"..n, {
		drawtype = "flowingliquid",
		tiles = {"z_pool_water_source_animated.png^[verticalframe:64:0"},
		special_tiles = {
			{
				name = "z_pool_water_source_animated.png",
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 0.5,
				},
			},
			{
				name = "z_pool_water_source_animated.png",
				backface_culling = true,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 0.5,
				},
			},
		},
		use_texture_alpha = "blend",
		paramtype = "light",
		paramtype2 = "flowingliquid",
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		light_source = n,
		drop = "",
		drowning = 1,
		liquidtype = "flowing",
		liquid_alternative_flowing = modname .. ":light_river_flowing_"..n,
		liquid_alternative_source = modname .. ":light_river_"..n,
		liquid_viscosity = 1,
		liquid_renewable = false,
		liquid_range = 2,
		post_effect_color = {a = 103, r = 30, g = 76, b = 90},
		groups = {water = 3, liquid = 3, not_in_creative_inventory = 1,
			cools_lava = 1, flash_light = 1},
		sounds = water_sound,
	})
end

local function flashlight_toggle(stack)
	if stack:get_name() == modname .. ":flashlight_off" then
		minetest.sound_play("goodtorch_on")
		stack:set_name(modname .. ":flashlight_on")
	else
		minetest.sound_play("goodtorch_off")
		stack:set_name(modname .. ":flashlight_off")
	end
	return stack
end

minetest.register_craftitem(modname .. ":flashlight_off", {
	description = "Flashlight (off)",
	inventory_image = "goodtorch_flashlight_off.png",
	on_place = flashlight_toggle,
	on_use = flashlight_toggle,
	on_secondary_use = flashlight_toggle,
	groups = {
		flash_light = 1,
	},
})

minetest.register_craftitem(modname .. ":flashlight_on", {
	description = "Flashlight (on)",
	inventory_image = "goodtorch_flashlight_on.png",
	on_place = flashlight_toggle,
	on_use = flashlight_toggle,
	on_secondary_use = flashlight_toggle,
	groups = {
		flash_light = 1,
	},
})

-- Chance the recipe based on gamemode (assume Minetest Game first)
local mese_crystal_fragment = "default:mese_crystal_fragment"
local mese_crystal = "default:mese_crystal"
local steel_ingot = "default:steel_ingot"
if goodtorch.detect_gamemode() == "MCL" then
	steel_ingot = "mcl_core:iron_ingot"
	-- Because MineClone doesn't have mese I'll just use the redstone stuff
	mese_crystal = "mesecons_lightstone:lightstone_off" -- Don't forget to change the lightbulb :P
	mese_crystal_fragment = "mesecons_walllever:wall_lever_off" -- Since it makes more sense to be a switch than a button
end
minetest.register_craft({
	output = modname .. ":flashlight_off",
	recipe = {
		{"", mese_crystal_fragment, ""},
		{mese_crystal, steel_ingot, steel_ingot},
		{"", "", ""},
	}
})
