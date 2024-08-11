local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local F = minetest.formspec_escape
local C = minetest.colorize


local open_boxes = {}

local drop_content = mcl_util.drop_items_from_meta_container({"main"})

local function on_blast(pos)
    local node = minetest.get_node(pos)
    drop_content(pos, node)
    minetest.remove_node(pos)
end

-- Simple protection checking functions
local function protection_check_move(pos, from_list, from_index, to_list, to_index, count, player)
    local name = player:get_player_name()
    if minetest.is_protected(pos, name) then
        minetest.record_protection_violation(pos, name)
        return 0
    else
        return count
    end
end

local function protection_check_put_take(pos, listname, index, stack, player)
    local name = player:get_player_name()
    if minetest.is_protected(pos, name) then
        minetest.record_protection_violation(pos, name)
        return 0
    else
        return stack:get_count()
    end
end

local function barrel_open(pos, node, clicker)
    local name = minetest.get_meta(pos):get_string("name")

    if name == "" then
        name = "Cardboard Box"
    end

    local playername = clicker:get_player_name()

    minetest.show_formspec(playername,
        modname .. ":box_chest_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z,
        table.concat({
            "formspec_version[4]",
            "size[11.75,10.425]",

            "label[0.375,0.375;" .. F(C(mcl_formspec.label_color, name)) .. "]",
            mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
            "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0.375,0.75;9,3;]",
            "label[0.375,4.7;" .. F(C(mcl_formspec.label_color, "Inventory")) .. "]",
            mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
            "list[current_player;main;0.375,5.1;9,3;9]",

            mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
            "list[current_player;main;0.375,9.05;9,1;]",
            "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]",
            "listring[current_player;main]",
        })
    )

    open_boxes[playername] = pos
    minetest.sound_play({ name = "mcl_armor_equip_leather" }, { pos = pos, gain = 0.5, max_hear_distance = 16 }, true)
end

local function close_forms(pos)
    local players = minetest.get_connected_players()
    local formname = modname .. ":box_chest_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
    for p = 1, #players do
        if vector.distance(players[p]:get_pos(), pos) <= 30 then
            minetest.close_formspec(players[p]:get_player_name(), formname)
        end
    end
end

local function update_after_close(pos)
    local node = minetest.get_node_or_nil(pos)
    if not node then return end
    --if node.name == modname .. ":box_chest" then
        minetest.sound_play({ name = "mcl_armor_unequip_leather" }, { pos = pos, gain = 0.5, max_hear_distance = 16 }, true)
    --end
end

local function close_barrel(player)
    local name = player:get_player_name()
    local open = open_boxes[name]
    if open == nil then
        return
    end

    update_after_close(open)

    open_boxes[name] = nil
end


-- Decorative Box
do
    minetest.register_node(modname .. ":box_decorative", {
        description = "Decorative Cardboard Box",
        tiles = { "z_box_top.png", "z_box_bottom.png", "z_box_bottom.png", "z_box_bottom.png", "z_box_side.png", "z_box_side_2.png" },
        is_ground_content = false,
        paramtype = "light",
        paramtype2 = "facedir",
        sounds = mcl_sounds.node_sound_wood_defaults(),
        groups = { handy = 1, axey = 1, container = 2, material_wood = 1, flammable = -1, deco_block = 1 },
        _mcl_blast_resistance = 2.5,
        _mcl_hardness = 2.5,
    })
end

-- Chest Box
do

    minetest.register_node(modname .. ":box_chest", {
        description = "Cardboard Box Chest",
        tiles = { "z_box_top.png", "z_box_bottom.png", "z_box_bottom.png", "z_box_bottom.png", "z_box_side.png", "z_box_side_2.png" },
        is_ground_content = false,
        paramtype = "light",
        paramtype2 = "facedir",
        on_place = function(itemstack, placer, pointed_thing)
            if  not placer or not placer:is_player() then
                return itemstack
            end
            minetest.rotate_and_place(itemstack, placer, pointed_thing,
                minetest.is_creative_enabled(placer and placer:get_player_name() or ""), {}
                , false)
            return itemstack
        end,
        sounds = mcl_sounds.node_sound_wood_defaults(),
        groups = { handy = 1, axey = 1, container = 2, material_wood = 1, flammable = -1, deco_block = 1 },
        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            inv:set_size("main", 9 * 3)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            minetest.get_meta(pos):set_string("name", itemstack:get_meta():get_string("name"))
        end,
        allow_metadata_inventory_move = protection_check_move,
        allow_metadata_inventory_take = protection_check_put_take,
        allow_metadata_inventory_put = protection_check_put_take,
        on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
            minetest.log("action", player:get_player_name() ..
                " moves stuff in box at " .. minetest.pos_to_string(pos))
        end,
        on_metadata_inventory_put = function(pos, listname, index, stack, player)
            minetest.log("action", player:get_player_name() ..
                " moves stuff to box at " .. minetest.pos_to_string(pos))
        end,
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
            minetest.log("action", player:get_player_name() ..
                " takes stuff from box at " .. minetest.pos_to_string(pos))
        end,
        after_dig_node = drop_content,
        on_blast = on_blast,
        on_rightclick = barrel_open,
        on_destruct = close_forms,
        _mcl_blast_resistance = 2.5,
        _mcl_hardness = 2.5,
    })


    minetest.register_on_player_receive_fields(function(player, formname, fields)
        if formname:find(modname .. ":") == 1 and fields.quit then
            close_barrel(player)
        end
    end)

    minetest.register_on_leaveplayer(function(player)
        close_barrel(player)
    end)

    --Minecraft Java Edition craft
    --[[minetest.register_craft({
        output = "mcl_barrels:barrel_closed",
        recipe = {
            { "group:wood", "group:wood_slab", "group:wood" },
            { "group:wood", "",                "group:wood" },
            { "group:wood", "group:wood_slab", "group:wood" },
        },
    })

    minetest.register_craft({
        type = "fuel",
        recipe = "mcl_barrels:barrel_closed",
        burntime = 15,
    })--]]
end

-- Trapped Chest Box
do
    local trapped_chest_mesecons_rules = mesecon.rules.pplate

    local function barrel_open(pos, node, clicker)
        local name = minetest.get_meta(pos):get_string("name")

        if name == "" then
            name = "Trapped Cardboard Box"
        end

        local playername = clicker:get_player_name()

        minetest.show_formspec(playername,
            modname .. ":box_chest_trapped_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z,
            table.concat({
                "formspec_version[4]",
                "size[11.75,10.425]",

                "label[0.375,0.375;" .. F(C(mcl_formspec.label_color, name)) .. "]",
                mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
                "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0.375,0.75;9,3;]",
                "label[0.375,4.7;" .. F(C(mcl_formspec.label_color, "Inventory")) .. "]",
                mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
                "list[current_player;main;0.375,5.1;9,3;9]",

                mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
                "list[current_player;main;0.375,9.05;9,1;]",
                "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]",
                "listring[current_player;main]",
            })
        )

        open_boxes[playername] = pos
        minetest.sound_play({ name = "mcl_armor_equip_leather" }, { pos = pos, gain = 0.5, max_hear_distance = 16 }, true)
		mesecon.receptor_on(pos, trapped_chest_mesecons_rules)
    end

    local function close_forms(pos)
        local players = minetest.get_connected_players()
        local formname = modname .. ":box_chest_trapped_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
        for p = 1, #players do
            if vector.distance(players[p]:get_pos(), pos) <= 30 then
                minetest.close_formspec(players[p]:get_player_name(), formname)
            end
        end
    end

    local function update_after_close(pos)
        local node = minetest.get_node_or_nil(pos)
        if not node then return end
        --if node.name == modname .. ":box_chest" then
            minetest.sound_play({ name = "mcl_armor_unequip_leather" }, { pos = pos, gain = 0.5, max_hear_distance = 16 }, true)
        --end
        mesecon.receptor_off(pos, trapped_chest_mesecons_rules)
    end

    local function close_barrel(player)
        local name = player:get_player_name()
        local open = open_boxes[name]
        if open == nil then
            return
        end

        update_after_close(open)

        open_boxes[name] = nil
    end

    minetest.register_node(modname .. ":box_chest_trapped", {
        description = "Trapped Cardboard Box Chest",
        tiles = { "z_box_top.png", "z_box_bottom.png", "z_box_bottom.png", "z_box_bottom.png", "z_box_side.png", "z_box_side_2.png" },
        is_ground_content = false,
        paramtype = "light",
        paramtype2 = "facedir",
        mesecons = {receptor = {
			state = mesecon.state.off,
			rules = trapped_chest_mesecons_rules,
		}},
        on_place = function(itemstack, placer, pointed_thing)
            if  not placer or not placer:is_player() then
                return itemstack
            end
            minetest.rotate_and_place(itemstack, placer, pointed_thing,
                minetest.is_creative_enabled(placer and placer:get_player_name() or ""), {}
                , false)
            return itemstack
        end,
        sounds = mcl_sounds.node_sound_wood_defaults(),
        groups = { handy = 1, axey = 1, container = 2, material_wood = 1, flammable = -1, deco_block = 1 },
        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            inv:set_size("main", 9 * 3)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            minetest.get_meta(pos):set_string("name", itemstack:get_meta():get_string("name"))
        end,
        allow_metadata_inventory_move = protection_check_move,
        allow_metadata_inventory_take = protection_check_put_take,
        allow_metadata_inventory_put = protection_check_put_take,
        on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
            minetest.log("action", player:get_player_name() ..
                " moves stuff in box at " .. minetest.pos_to_string(pos))
        end,
        on_metadata_inventory_put = function(pos, listname, index, stack, player)
            minetest.log("action", player:get_player_name() ..
                " moves stuff to box at " .. minetest.pos_to_string(pos))
        end,
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
            minetest.log("action", player:get_player_name() ..
                " takes stuff from box at " .. minetest.pos_to_string(pos))
        end,
        after_dig_node = drop_content,
        on_blast = on_blast,
        on_rightclick = function(pos, node, clicker, itemstack)
            barrel_open(pos, node, clicker, itemstack)
            mesecon.receptor_on(pos, trapped_chest_mesecons_rules)
        end,
        on_destruct = close_forms,
        _mcl_blast_resistance = 2.5,
        _mcl_hardness = 2.5,
    })


    minetest.register_on_player_receive_fields(function(player, formname, fields)
        if formname:find(modname .. ":") == 1 and fields.quit then
            close_barrel(player)
        end
    end)

    minetest.register_on_leaveplayer(function(player)
        close_barrel(player)
    end)

    --Minecraft Java Edition craft
    --[[minetest.register_craft({
        output = "mcl_barrels:barrel_closed",
        recipe = {
            { "group:wood", "group:wood_slab", "group:wood" },
            { "group:wood", "",                "group:wood" },
            { "group:wood", "group:wood_slab", "group:wood" },
        },
    })

    minetest.register_craft({
        type = "fuel",
        recipe = "mcl_barrels:barrel_closed",
        burntime = 15,
    })--]]
end












local fovdef = {
    name = modname .. ":boxeffect",
    fov_factor = 0.5,
    time = 1,
    reset_time = 1,
    is_multiplier = true,
    exclusive = false,
    --on_start = on_start,
    --on_end = on_end,
}
--mcl_fovapi.register_modifier(fovdef)



mcl_mobs.register_mob(modname .. ":box_entity", {
	description = "Box Entity",
	type = "monster",
	spawn_class = "hostile",
	persist_in_peaceful = true,
	attack_type = "shoot",
	shoot_interval = 5.5,
	arrow = modname .. ":boxbullet",
	shoot_offset = 0.5,
	passive = false,
	hp_min = 30,
	hp_max = 30,
	xp_min = 5,
	xp_max = 5,
	armor = 20,
	collisionbox = {-0.5, -0.01, -0.5, 0.5, 0.99, 0.5},
	visual = "mesh",
	mesh = "mobs_mc_shulker.b3d",
	textures = { "z_box_entity.png", },
	visual_size = {x=3, y=3},
	walk_chance = 10,
	knock_back = false,
	jump = false,
	can_despawn = false,
	fall_speed = 0,
	does_not_prevent_sleep = true,
	drops = {
		{name = modname .. ":box_decorative",
		chance = 2,
		min = 1,
		max = 1,
		looting = "rare",
		looting_factor = 0.0625},
	},
	animation = {
		stand_speed = 25, walk_speed = 25, run_speed = 50, punch_speed = 25,
		speed_normal = 25,		speed_run = 50,
		stand_start = 0,		stand_end = 25,
		walk_start = 45,		walk_end = 65,
		walk_loop = false,
		run_start = 65,		run_end = 85,
		run_loop = false,
        punch_start = 80,  punch_end = 100,
	},
	view_range = 16,
	fear_height = 0,
	walk_velocity = 0,
	run_velocity = 0,
	noyaw = true,
	_mcl_fishing_hookable = true,
	_mcl_fishing_reelable = false,
	--[[on_rightclick = function(self,clicker)
		if clicker:is_player() then
			local wstack = clicker:get_wielded_item()
			if minetest.get_item_group(wstack:get_name(),"dye") > 0 then
				local color = minetest.registered_items[wstack:get_name()]._color
				local tx = "mobs_mc_shulker_"..color..".png"
				if messy_textures[color] then tx = messy_textures[color] end
				self.object:set_properties({
					textures = { tx },
				})
				if not minetest.is_creative_enabled(clicker:get_player_name()) then
					wstack:take_item()
					clicker:set_wielded_item(wstack)
				end
			end
		end
	end,--]]
	do_custom = function(self,dtime)
		local pos = self.object:get_pos()
		if math.floor(self.object:get_yaw()) ~=0 then
			self.object:set_yaw(0)
			mcl_mobs.yaw(self, 0, 0, dtime)
		end
		if self.state == "attack" then
			self:set_animation("run")
			self.armor = 0
		elseif self.state == "walk" or self.state == "run" then
			self.armor = 0
		else
			self.armor = 20
		end
		self.path.way = false
		self.look_at_players = false
		-- if not check_spot(pos) then
		-- 	self:teleport(nil)
		-- end
	end,
	do_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
		--self:teleport(puncher)
	end,
	do_teleport = function(self, target)
		if target ~= nil then
			local target_pos = target:get_pos()
			-- Find all solid nodes below air in a 10×10×10 cuboid centered on the target
			local nodes = minetest.find_nodes_in_area_under_air(vector.subtract(target_pos, 5), vector.add(target_pos, 5), {"group:solid", "group:cracky", "group:crumbly"})
			local telepos
			if nodes ~= nil then
				if #nodes > 0 then
					-- Up to 64 attempts to teleport
					for n=1, math.min(64, #nodes) do
						local r = pr:next(1, #nodes)
						local nodepos = nodes[r]
						local tg = vector.offset(nodepos,0,1,0)
						if check_spot(tg) then
							telepos = tg
						end
					end
					if telepos then
						self.object:set_pos(telepos)
					end
				end
			end
		else
			local pos = self.object:get_pos()
			-- Up to 8 top-level attempts to teleport
			for n=1, 8 do
				local node_ok = false
				-- We need to add (or subtract) different random numbers to each vector component, so it couldn't be done with a nice single vector.add() or .subtract():
				local randomCube = vector.new( pos.x + 8*(pr:next(0,16)-8), pos.y + 8*(pr:next(0,16)-8), pos.z + 8*(pr:next(0,16)-8) )
				local nodes = minetest.find_nodes_in_area_under_air(vector.subtract(randomCube, 4), vector.add(randomCube, 4), {"group:solid", "group:cracky", "group:crumbly"})
				if nodes ~= nil then
					if #nodes > 0 then
						-- Up to 8 low-level (in total up to 8*8 = 64) attempts to teleport
						for n=1, math.min(8, #nodes) do
							local r = pr:next(1, #nodes)
							local nodepos = nodes[r]
							local tg = vector.offset(nodepos,0,0.5,0)
							if check_spot(tg) then
								self.object:set_pos(tg)
								node_ok = true
								break
							end
						end
					end
				end
				if node_ok then
					 break
				end
			end
		end
	end,
	on_attack = function(self, dtime)
		self.shoot_interval = 1 + (math.random() * 4.5)
	end,
})

-- bullet arrow (weapon)
mcl_mobs.register_arrow(modname .. ":boxbullet", {
	visual = "sprite",
	visual_size = {x = 0.25, y = 0.25},
	textures = {"mobs_mc_shulkerbullet.png"},
	velocity = 5,
	homing = true,
	_mcl_fishing_hookable = true,
	_mcl_fishing_reelable = true,
	hit_player = function(self, player)
        mcl_mobs.get_arrow_damage_func(4)(self, player)
        -- mcl_fovapi.apply_modifier(player, modname .. ":boxeffect")
        --mcl_potions.give_effect_by_level("slowness", player, 3, 10, false)
        mcl_potions.swiftness_func(player, 0.5, 10)
        -- minetest.after(5, function()
        --     mcl_fovapi.remove_modifier(player, modname .. ":boxeffect")
        -- end)

    end,
	hit_mob = mcl_mobs.get_arrow_damage_func(4),
	hit_node = function(self, _)
		self.object:remove()
	end
})

mcl_mobs.register_egg(modname .. ":box_entity", "Box Entity", "#C1956E", "#8E6C4D", 0)
