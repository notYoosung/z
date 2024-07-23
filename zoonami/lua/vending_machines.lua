-- Vending machine nodes and formspecs

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

local sounds = dofile(mod_path .. "/lua/sounds.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Vending Machine Hidden Top Node
minetest.register_node(modname .. ":zoonami_vending_machine_top", {
	description = "Vending Machine Top",
	drawtype = "airlike",
	paramtype = "light",
	paramtype2 = "facedir",
	buildable_to = false,
	diggable = false,
	floodable = false,
	pointable = false,
	sunlight_propagates = true,
	walkable = true,
	on_blast = function() end,
	drop = "",
	groups = {not_in_creative_inventory = 1},
	collision_box = {
		type = "fixed",
		fixed = {-0.5, 0.5, -0.5, -0.5, 0.5, -0.5},
	},
})

-- Automatic Vending Machine Formspec
local function automatic_vending_machine_formspec(player, fields, context)
	if fields and fields.quit then
		return true
	end
	
	local node_meta = minetest.get_meta(context.node_pos)
	local node_inv = node_meta:get_inventory()
	node_inv:set_size("stock", 1)
	local stack_1 = node_inv:get_stack("stock", 1)
	local stack_1_price = node_meta:get_int("zoonami_stack_price_1")
	local previous_day = node_meta:get_int("zoonami_previous_day")
	local current_day = minetest.get_day_count()
	local player_meta = player:get_meta()
	local player_name = player:get_player_name() or ""
	local player_inv = player:get_inventory()
	local player_zc = player_meta:get_int("zoonami_coins")
	
	if previous_day ~= current_day or node_meta:get_int("zoonami_stack_price_1") == 0 then
		previous_day = minetest.get_day_count()
		node_meta:set_int("zoonami_previous_day", previous_day)
		local item_pool = {}
		item_pool[1] = {name = modname .. ":zoonami_blue_berry", count = math.random(10, 30), price = math.random(14, 22)}
		item_pool[2] = {name = modname .. ":zoonami_red_berry", count = math.random(10, 30), price = math.random(14, 22)}
		item_pool[3] = {name = modname .. ":zoonami_orange_berry", count = math.random(10, 30), price = math.random(14, 22)}
		item_pool[4] = {name = modname .. ":zoonami_green_berry", count = math.random(10, 30), price = math.random(14, 22)}
		item_pool[5] = {name = modname .. ":zoonami_daisy", count = math.random(10, 30), price = math.random(12, 20)}
		item_pool[6] = {name = modname .. ":zoonami_blue_tulip", count = math.random(10, 30), price = math.random(12, 20)}
		item_pool[7] = {name = modname .. ":zoonami_sunflower", count = math.random(10, 30), price = math.random(12, 20)}
		item_pool[8] = {name = modname .. ":zoonami_tiger_lily", count = math.random(10, 30), price = math.random(12, 20)}
		item_pool[9] = {name = modname .. ":zoonami_simple_berry_juice", count = math.random(15, 20), price = math.random(28, 38)}
		item_pool[10] = {name = modname .. ":zoonami_super_berry_juice", count = math.random(10, 15), price = math.random(95, 105)}
		local new_item = item_pool[math.random(#item_pool)]
		node_inv:set_stack("stock", 1, new_item.name.." "..new_item.count)
		node_meta:set_int("zoonami_stack_price_1", new_item.price)
		stack_1 = node_inv:get_stack("stock", 1)
		stack_1_price = new_item.price
	elseif fields and fields.buy_stack_1 then
		if stack_1:get_count() > 0 and player_zc >= stack_1_price then
			player_meta:set_int("zoonami_coins", player_zc - stack_1_price)
			player_zc = player_zc - stack_1_price
			local items = stack_1:take_item(1)
			node_inv:set_stack("stock", 1, stack_1)
			minetest.sound_play("zoonami_vending_machine", {to_player = player_name, gain = 0.9}, true)
			minetest.after(0, function()
				local leftover = player_inv:add_item("main", items)
				if leftover:get_count() > 0 then
					minetest.add_item(player:get_pos(), leftover)
				end
			end)
		end
	end
	
	local formspec = fs.header(7, 4.5, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
		fs.button_style(1, 8)..
		fs.font_style("button", "mono,bold", "*0.94", "#000000")..
		fs.font_style("image_button", "mono,bold", "*0.94", "#FFFFFF")..
		fs.image_button(0, 0, 7, 1, "zoonami_blank", "label", "Your Bank: "..player_zc.." ZC")..
		fs.box(0, 0, 7, 1, "#00000000")..
		fs.item_image_button(3, 1, 1, 1, stack_1:get_name(), "image1")..
		fs.image_button(0, 2, 7, 1, "zoonami_blank", "label", "Stock: "..stack_1:get_count())..
		fs.box(0, 2, 7, 1, "#00000000")..
		fs.image_button(0, 2.5, 7, 1, "zoonami_blank", "label", stack_1_price.." ZC")..
		fs.box(0, 2.5, 7, 1, "#00000000")..
		fs.button(2.9, 3.5, 1.2, 0.7, "buy_stack_1", "Buy")
		
	fsc.show(player_name, formspec, context, automatic_vending_machine_formspec)
end

-- Automatic Vending Machine
minetest.register_node(modname .. ":zoonami_automatic_vending_machine", {
	description = "Automatic Vending Machine",
	drawtype = "mesh",
	mesh = "zoonami_vending_machine.obj",
	tiles = {"zoonami_vending_machine.png"},
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {
		cracky = 1,
		dig_stone = 2,
		pickaxey = 4,
	},
	sounds = sounds.stone,
	on_blast = function() end,
	drop = "",
	collision_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
	},
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		local top_pos = vector.offset(pos, 0, 1, 0)
		local top_node = minetest.get_node_or_nil(top_pos)
		local top_def = top_node and minetest.registered_nodes[top_node.name]
		local player_name = placer:get_player_name() or ""
		if not top_def or not top_def.buildable_to then
			return itemstack
		elseif minetest.is_protected(pos, player_name) or minetest.is_protected(top_pos, player_name) then
			return itemstack
		elseif not minetest.is_creative_enabled(player_name) then
			itemstack:take_item()
		end
		local dir = placer and minetest.dir_to_facedir(placer:get_look_dir()) or 0
		minetest.set_node(pos, {name = modname .. ":zoonami_automatic_vending_machine", param2 = dir})
		minetest.set_node(top_pos, {name = modname .. ":zoonami_vending_machine_top"})
		return itemstack
	end,
	after_dig_node = function(pos, node, meta, digger)
		local top_node = vector.offset(pos, 0, 1, 0)
		minetest.remove_node(top_node)
		minetest.check_for_falling(top_node)
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if player and player:is_player() then
			automatic_vending_machine_formspec(player, {}, {node_pos = pos})
		end
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return 0
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return 0
	end,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})

-- Vending Machine Formspec
local function vending_machine_formspec(player, fields, context)
	if fields and fields.quit then
		return true
	end
	
	local node_meta = minetest.get_meta(context.node_pos)
	local owner = node_meta:get_string("owner")
	local node_inv = node_meta:get_inventory()
	local node_zc = node_meta:get_int("zoonami_coins")
	local player_meta = player:get_meta()
	local player_name = player:get_player_name() or ""
	local player_inv = player:get_inventory()
	local player_zc = player_meta:get_int("zoonami_coins")
	local pos_string = context.node_pos.x..","..context.node_pos.y..","..context.node_pos.z
	
	local field_key = fields and next(fields) or ""
	local buy_stack_field = tonumber(string.match(field_key, "^buy_stack_([123])$"))
	
	if owner == player_name then
		if fields and fields.collect_zc then
			if node_zc > 0 then
				node_meta:set_int("zoonami_coins", 0)
				player_meta:set_int("zoonami_coins", player_zc + node_zc)
				minetest.log("action", player_name.." collected "..node_zc.." ZC from their vending machine at ("..pos_string..").")
				minetest.sound_play("zoonami_coins", {to_player = player_name, gain = 0.9}, true)
			end
		elseif fields and fields.set_prices then
			node_meta:set_int("zoonami_stack_price_1", tonumber(fields.stack_price_1) or 0)
			node_meta:set_int("zoonami_stack_price_2", tonumber(fields.stack_price_2) or 0)
			node_meta:set_int("zoonami_stack_price_3", tonumber(fields.stack_price_3) or 0)
			minetest.sound_play("zoonami_select2", {to_player = player_name, gain = 0.5}, true)
		end
	else
		if buy_stack_field then
			local stack = node_inv:get_stack("stock", buy_stack_field)
			local stack_count = stack:get_count()
			if stack_count > 0 then
				local stack_price = node_meta:get_int("zoonami_stack_price_"..buy_stack_field)
				if player_zc >= stack_price and stack_price > 0 then
					player_meta:set_int("zoonami_coins", player_zc - stack_price)
					node_meta:set_int("zoonami_coins", node_zc + stack_price)
					local items = stack:take_item(1)
					node_inv:set_stack("stock", buy_stack_field, stack)
					minetest.sound_play("zoonami_vending_machine", {to_player = player_name, gain = 0.9}, true)
					minetest.after(0, function()
						local leftover = player_inv:add_item("main", items)
						if leftover:get_count() > 0 then
							minetest.add_item(player:get_pos(), leftover)
						end
					end)
				end
			end
		end
	end
	
	local stack_1 = node_inv:get_stack("stock", 1)
	local stack_1_price = node_meta:get_int("zoonami_stack_price_1")
	local stack_2 = node_inv:get_stack("stock", 2)
	local stack_2_price = node_meta:get_int("zoonami_stack_price_2")
	local stack_3 = node_inv:get_stack("stock", 3)
	local stack_3_price = node_meta:get_int("zoonami_stack_price_3")
	player_zc = player_meta:get_int("zoonami_coins")
	node_zc = node_meta:get_int("zoonami_coins")
	local formspec = ""
	
	if owner == player_name then
		formspec = fs.header(11, 11, "false", "#00000000")..
			fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
			fs.button_style(1, 8)..
			fs.font_style("button", "mono,bold", "*0.94", "#000000")..
			fs.font_style("image_button,label", "mono,bold", "*0.94", "#FFFFFF")..
			fs.list_colors("#777", "#5A5A5A", "#141318", "#30434C", "#FFF")..
			fs.image_button(0, 0.5, 11, 0.5, "zoonami_blank", "label", "Your Bank: "..player_zc.." ZC")..
			fs.box(0, 0.5, 11, 0.5, "#00000000")..
			fs.list_style("false", 1, 2.5)..
			fs.list("nodemeta:"..pos_string, "stock", 1.55, 1.25, 3, 1, 0)..
			fs.field(1.25, 2.85, 1.5, 0.5, "stack_price_1", "Price", stack_1_price.."")..
			fs.field(4.75, 2.85, 1.5, 0.5, "stack_price_2", "Price", stack_2_price.."")..
			fs.field(8.25, 2.85, 1.5, 0.5, "stack_price_3", "Price", stack_3_price.."")..
			"field_close_on_enter[stack_price_1;false]"..
			"field_close_on_enter[stack_price_2;false]"..
			"field_close_on_enter[stack_price_3;false]"..
			fs.label(1.25, 4, "*Prices are per item, not per stack.")..
			fs.button(1, 4.5, 4.5, 0.75, "set_prices", "Set Prices")..
			fs.button(5.5, 4.5, 4.5, 0.75, "collect_zc", "Collect "..node_zc.." ZC")..
			fs.list_style("false", 1, 0.2)..
			fs.list("current_player", "main", 0.85, 5.7, 8, 1, 0)..
			fs.list("current_player", "main", 0.85, 7.1, 8, 3, 8)
	else
		formspec = fs.header(8, 4.5, "false", "#00000000")..
			fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
			fs.button_style(1, 8)..
			fs.font_style("button", "mono,bold", "*0.94", "#000000")..
			fs.font_style("image_button,label", "mono,bold", "*0.94", "#FFFFFF")..
			fs.image_button(0, 0, 8, 1, "zoonami_blank", "label", "Your Bank: "..player_zc.." ZC")..
			fs.box(0, 0, 8, 1, "#00000000")..
			fs.item_image_button(1, 1, 1, 1, stack_1:get_name(), "image1")..
			fs.label(0.7, 2.5, "Stock: "..stack_1:get_count())..
			fs.label(0.7, 3, stack_1_price.." ZC")..
			fs.item_image_button(3.5, 1, 1, 1, stack_2:get_name(), "image2")..
			fs.label(3.2, 2.5, "Stock: "..stack_2:get_count())..
			fs.label(3.2, 3, stack_2_price.." ZC")..
			fs.item_image_button(6, 1, 1, 1, stack_3:get_name(), "image3")..
			fs.label(5.7, 2.5, "Stock: "..stack_3:get_count())..
			fs.label(5.7, 3, stack_3_price.." ZC")..
			fs.button(0.9, 3.5, 1.2, 0.7, "buy_stack_1", "Buy")..
			fs.button(3.4, 3.5, 1.2, 0.7, "buy_stack_2", "Buy")..
			fs.button(5.9, 3.5, 1.2, 0.7, "buy_stack_3", "Buy")
	end
	
	fsc.show(player_name, formspec, context, vending_machine_formspec)
end

-- Vending Machine
minetest.register_node(modname .. ":zoonami_vending_machine", {
	description = "Vending Machine",
	drawtype = "mesh",
	mesh = "zoonami_vending_machine.obj",
	tiles = {"zoonami_vending_machine.png"},
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {
		cracky = 3,
		dig_stone = 2,
		pickaxey = 4,
	},
	sounds = sounds.stone,
	on_blast = function() end,
	collision_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
	},
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		local top_pos = vector.offset(pos, 0, 1, 0)
		local top_node = minetest.get_node_or_nil(top_pos)
		local top_def = top_node and minetest.registered_nodes[top_node.name]
		local player_name = placer:get_player_name() or ""
		if not top_def or not top_def.buildable_to then
			return itemstack
		elseif minetest.is_protected(pos, player_name) or minetest.is_protected(top_pos, player_name) then
			return itemstack
		elseif not minetest.is_creative_enabled(player_name) then
			itemstack:take_item()
		end
		local dir = placer and minetest.dir_to_facedir(placer:get_look_dir()) or 0
		minetest.set_node(pos, {name = modname .. ":zoonami_vending_machine", param2 = dir})
		minetest.set_node(top_pos, {name = modname .. ":zoonami_vending_machine_top"})
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", player_name)
		meta:set_string("infotext", "Owner: "..player_name)
		local node_inv = meta:get_inventory()
		node_inv:set_size("stock", 3)
		return itemstack
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local inv = meta:get_inventory()
		local protection_bypass = minetest.check_player_privs(player, "protection_bypass")
		local player_name = player:get_player_name() or ""
		if player_name == owner then
			return inv:is_empty("stock")
		elseif protection_bypass then
			return true
		end
	end,
	after_dig_node = function(pos, node, meta, digger)
		local top_node = vector.offset(pos, 0, 1, 0)
		minetest.remove_node(top_node)
		minetest.check_for_falling(top_node)
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if player and player:is_player() then
			vending_machine_formspec(player, {}, {node_pos = pos})
		end
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(from_list, from_index)
		local owner = meta:get_string("owner")
		local protection_bypass = minetest.check_player_privs(player, "protection_bypass")
		local player_name = player:get_player_name() or ""
		if player_name == owner or protection_bypass then
			return stack:get_count()
		else
			return 0
		end
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local protection_bypass = minetest.check_player_privs(player, "protection_bypass")
		local player_name = player:get_player_name() or ""
		if player_name == owner or protection_bypass then
			return stack:get_count()
		else
			return 0
		end
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local protection_bypass = minetest.check_player_privs(player, "protection_bypass")
		local player_name = player:get_player_name() or ""
		if player_name == owner or protection_bypass then
			return stack:get_count()
		else
			return 0
		end
	end,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})
