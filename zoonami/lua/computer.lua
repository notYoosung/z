-- Computer node and formspec

-- Local namespace
local computer = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

local monsters = dofile(mod_path .. "/lua/monsters.lua")
local move_stats = dofile(mod_path .. "/lua/move_stats.lua")
local sounds = dofile(mod_path .. "/lua/sounds.lua")
local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Computer Formspec
function computer.formspec(player, fields, context)
	fields = fields or {}
	if fields.quit then
		return true
	end
	
	local meta = player:get_meta()
	local player_name = player:get_player_name() or ""
	context = context or {}
	
	-- Handle button presses
	local filtered_fields = table.copy(fields)
	filtered_fields.rename_field = nil
	filtered_fields.key_enter = nil
	filtered_fields.key_enter_field = nil
	local field_key = next(filtered_fields) or ""
	if field_key ~= "" then
		minetest.sound_play("zoonami_select2", {to_player = player_name, gain = 0.5}, true)
	end
	local folder = tonumber(string.match(field_key, "^folder#(%d?%d)$"))
	folder = folder and math.min(folder, 25)
	local box = tonumber(string.match(field_key, "^box#(%d?%d)$"))
	box = box and math.min(math.max(box, 1), 10)
	local monster = tonumber(string.match(field_key, "^monster#(%d?%d)$"))
	monster = monster and math.min(math.max(monster, 1), 25)
	local party_monster = tonumber(string.match(field_key, "^party_monster#([12345])$"))
	local select_box = fields.select_box
	local delete_monster_warning = fields.delete_monster_warning
	local cancel_monster_warning = fields.cancel_monster_warning
	local delete_monster = fields.delete_monster
	local rename_monster = fields.rename_monster
	local rename_field = fields.rename_field
	local clear_selection = fields.clear_selection
	
	-- Set metadata values
	if folder then
		meta:set_int("zoonami_computer_folder", folder)
		meta:set_int("zoonami_computer_box", 1)
	elseif box then
		meta:set_int("zoonami_computer_box", box)
	elseif clear_selection then
		context.selected_monster = nil
		context.selected_box = nil
	end
	
	-- Get metadata values
	folder = meta:get_int("zoonami_computer_folder")
	box = math.max(meta:get_int("zoonami_computer_box"), 1)
	
	-- Manage selected monster or box
	if monster then
		if not context.selected_monster and folder > 0 then
			context.selected_monster = "zoonami_computer_folder_"..folder.."_box_"..box.."_monster_"..monster
			monster = nil
		elseif folder > 0 then
			monster = "zoonami_computer_folder_"..folder.."_box_"..box.."_monster_"..monster
		end
		context.selected_box = nil
	elseif party_monster then
		if not context.selected_monster then
			context.selected_monster = "zoonami_monster_"..party_monster
			party_monster = nil
		else
			party_monster = "zoonami_monster_"..party_monster
		end
		context.selected_box = nil
	elseif select_box then
		if not context.selected_box and folder > 0 then
			context.selected_box = "zoonami_computer_folder_"..folder.."_box_"..box
			select_box = nil
		elseif folder > 0 then
			select_box = "zoonami_computer_folder_"..folder.."_box_"..box
		end
		context.selected_monster = nil
	end
	
	-- Formspec
	if rename_monster and context.selected_monster then
		local monster = meta:get_string(context.selected_monster or "")
		monster = minetest.deserialize(monster)
		if monster then
			rename_field = minetest.formspec_escape(rename_field or "")
			monster.nickname = rename_field ~= "" and string.sub(rename_field, 1, 9) or nil
			meta:set_string(context.selected_monster, minetest.serialize(monster))
		end
		computer.stats_page(player_name, meta, folder, box, context)
	elseif cancel_monster_warning and context.selected_monster then
		context.delete_monster_warning = nil
		computer.stats_page(player_name, meta, folder, box, context)
	elseif delete_monster_warning and context.selected_monster then
		context.delete_monster_warning = delete_monster_warning
		computer.stats_page(player_name, meta, folder, box, context)
	elseif delete_monster and context.selected_monster then
		local monster = meta:get_string(context.selected_monster or "")
		monster = minetest.deserialize(monster)
		if monster and not monster.starter_monster then
			meta:set_string(context.selected_monster, "")
			context.selected_monster = nil
			computer.main_page(player_name, meta, folder, box, context)
		end
	elseif select_box and context.selected_box then
		computer.move_box(meta, select_box, context)
		context.selected_box = nil
		computer.main_page(player_name, meta, folder, box, context)
	elseif context.stats_page == true or monster == context.selected_monster or party_monster == context.selected_monster then
		if meta:get_string(context.selected_monster or "") ~= "" then
			context.stats_page = true
			computer.stats_page(player_name, meta, folder, box, context)
		else
			context.stats_page = nil
			context.selected_monster = nil
			context.delete_monster_warning = nil
			computer.main_page(player_name, meta, folder, box, context)
		end
	elseif (monster or party_monster) and context.selected_monster then
		computer.move_monster(meta, monster or party_monster, context)
		context.selected_monster = nil
		computer.main_page(player_name, meta, folder, box, context)
	else
		computer.main_page(player_name, meta, folder, box, context)
	end
end

-- Move box
function computer.move_box(meta, select_box, context)
	for i = 1, 25 do
		local monster1 = meta:get_string(context.selected_box.."_monster_"..i)
		local monster2 = meta:get_string(select_box.."_monster_"..i)
		meta:set_string(context.selected_box.."_monster_"..i, monster2)
		meta:set_string(select_box.."_monster_"..i, monster1)
	end
end

-- Move monster
function computer.move_monster(meta, monster, context)
	local monster1 = meta:get_string(context.selected_monster or "")
	local monster2 = meta:get_string(monster)
	meta:set_string(context.selected_monster, monster2)
	meta:set_string(monster, monster1)
end

-- Main page
function computer.main_page(player_name, meta, folder, box, context)
	-- Formspec header
	local formspec = fs.header(11, 10, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
		fs.background9(0.1, 1.1, 1.8, 8.8, "zoonami_button_4.png", "false", 8)
	
	-- Selection Icon Button
	if context.selected_monster then
		formspec = formspec..
			fs.button_style(6, 8)..
			fs.button(10, 0.33, 0.5, 0.5, "clear_selection", "")..
			fs.tooltip("clear_selection", "Monster selected", "#ffffff", "#000000")
	elseif context.selected_box then
		formspec = formspec..
			fs.button_style(6, 8)..
			fs.button(10, 0.33, 0.5, 0.5, "clear_selection", "")..
			fs.tooltip("clear_selection", "Box selected", "#ffffff", "#000000")
	else
		formspec = formspec..
			fs.button_style(5, 8)..
			fs.button(10, 0.33, 0.5, 0.5, "clear_selection", "")..
			fs.tooltip("clear_selection", "Nothing selected", "#ffffff", "#000000")
	end
	
	-- Toolbar and Page Content
	if folder == 0 then
		formspec = formspec .. computer.folder_page_toolbar()
		formspec = formspec .. computer.folder_page()
	else
		formspec = formspec .. computer.box_page_toolbar(folder, box)
		formspec = formspec .. computer.box_page(meta, folder, box, context)
	end
	
	-- Monsters in party
	formspec = formspec..
		fs.button_style(3, 8)..
		fs.image_button_style(3, 8)
	for i = 1, 5 do
		local monster = meta:get_string("zoonami_monster_"..i)
		monster = minetest.deserialize(monster)
		monster = monster and monsters.load_stats(monster)
		local y_spacing = (i - 1) * 1.75
		if context.selected_monster == "zoonami_monster_"..i then
			formspec = formspec..
				fs.button_style(2, 8)..
				fs.image_button_style(2, 8)
		end
		if monster then
			formspec = formspec..
				fs.monster_button(0.25, 1.25+y_spacing, 1.5, 1.5, "zoonami_"..monster.asset_name.."_front"..(monster.prisma_id or ""), "party_monster#"..i)..
				fs.tooltip("party_monster#"..i, (monster.nickname or monster.name).."\nLevel: "..monster.level, "#ffffff", "#000000")
		else
			formspec = formspec..
				fs.button(0.25, 1.25+y_spacing, 1.5, 1.5, "party_monster#"..i, "")
		end
		if context.selected_monster == "zoonami_monster_"..i then
			formspec = formspec..
				fs.button_style(3, 8)..
				fs.image_button_style(3, 8)
		end
	end
	
	fsc.show(player_name, formspec, context, computer.formspec)
end

-- Folder page toolbar
function computer.folder_page_toolbar()
	local formspec = fs.font_style("button", "mono,bold", "*1", "#000000")..
		fs.font_style("image_button", "mono,bold", "*1.25", "#000000")..
		fs.button_style(2, 8)..
		fs.button(4, 0.33, 3, 0.75, "folder#0", "Home")..
		fs.box(4, 0.33, 3, 0.75, "#00000000")
	return formspec
end

-- Folder page
function computer.folder_page()
	local formspec = ""
	local width = 5
	local height = 5
	for i = 1, height do
		for ii = 1, width do
			local number = ((i - 1) * width) + ii
			local x_spacing = (ii - 1) * 1.75
			local y_spacing = (i - 1) * 1.75
			formspec = formspec..
				fs.folder_button(2.1+x_spacing, 1.25+y_spacing, 1.5, 1.5, "zoonami_folder", "folder#"..number, number)
		end
	end
	return formspec
end

-- Box page toolbar
function computer.box_page_toolbar(folder, box)
	local left_box = box - 1
	left_box = left_box >= 1 and left_box or 10
	local right_box = box + 1
	right_box = right_box <= 10 and right_box or 1
	local formspec = fs.font_style("button,image_button", "mono,bold", "*1", "#000000")..
		fs.button_style(1, 8)..
		fs.button(0.15, 0.33, 1.7, 0.75, "folder#0", "Home")..
		fs.button(4.045, 0.33, 0.755, 0.75, "box#"..left_box, "<")..
		fs.button(8.02, 0.33, 0.755, 0.75, "box#"..right_box, ">")..
		fs.button(4.9, 0.33, 3, 0.75, "select_box", "Box "..box)..
		fs.folder_button(2, 0.14, 1, 1, "zoonami_folder", "folder#"..folder, folder)..
		fs.box(2, 0.14, 1, 1, "#00000000")..
		fs.button_style(3, 8)..
		fs.image_button_style(3, 8)
	return formspec
end

-- Box page
function computer.box_page(meta, folder, box, context)
	local formspec = ""
	local width = 5
	local height = 5
	if context.selected_box == "zoonami_computer_folder_"..folder.."_box_"..box then
		formspec = formspec..
			fs.button_style(2, 8)..
			fs.image_button_style(2, 8)
	end
	for i = 1, height do
		for ii = 1, width do
			local number = ((i - 1) * width) + ii
			local monster = meta:get_string("zoonami_computer_folder_"..folder.."_box_"..box.."_monster_"..number)
			monster = minetest.deserialize(monster)
			monster = monster and monsters.load_stats(monster)
			local x_spacing = (ii - 1) * 1.75
			local y_spacing = (i - 1) * 1.75
			if context.selected_monster == "zoonami_computer_folder_"..folder.."_box_"..box.."_monster_"..number then
				formspec = formspec..
					fs.button_style(2, 8)..
					fs.image_button_style(2, 8)
			end
			if monster then
				formspec = formspec..
					fs.monster_button(2.1+x_spacing, 1.25+y_spacing, 1.5, 1.5, "zoonami_"..monster.asset_name.."_front"..(monster.prisma_id or ""), "monster#"..number)..
					fs.tooltip("monster#"..number, (monster.nickname or monster.name).."\nLevel: "..monster.level, "#ffffff", "#000000")
			else
				formspec = formspec..
					fs.button(2.1+x_spacing, 1.25+y_spacing, 1.5, 1.5, "monster#"..number, "")
			end
			if context.selected_monster == "zoonami_computer_folder_"..folder.."_box_"..box.."_monster_"..number then
				formspec = formspec..
					fs.button_style(3, 8)..
					fs.image_button_style(3, 8)
			end
		end
	end
	return formspec
end

-- Stats page
function computer.stats_page(player_name, meta, folder, box, context)
	-- Formspec header
	local formspec = fs.header(11, 10, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)
		
	-- Toolbar
	formspec = formspec..
		fs.font_style("button", "mono,bold", "*1", "#000000")..
		fs.button_style(1, 8)..
		fs.button(0.3, 0.33, 2, 0.75, "clear_selection", "Back")
		
	local monster = meta:get_string(context.selected_monster or "")
	monster = minetest.deserialize(monster)
	monster = monster and monsters.load_stats(monster)
	if monster then
		local next_level = monster.level + 1
		local next_exp_milestone = next_level * next_level * monster.base.exp_per_level
		local exp_needed_for_level_up = next_exp_milestone - monster.exp_total
		if monster.level >= 100 then
			exp_needed_for_level_up = 0
		end
		
		local monster_moves = ""
		for i = 1, #monster.move_pool do
			local move_name = monster.move_pool[i]
			monster_moves = monster_moves..
				(i > 1 and ", " or "")..move_stats[move_name].name
		end
		
		local textarea = "Name: "..monster.name..
			(monster.nickname and "\nNickname: "..monster.nickname or "")..
			"\nLevel: "..monster.level..
			"\nType: "..monster.type..
			"\n\nEnergy: "..monster.max_energy..
			"\n\nHealth: "..monster.max_health..
			"\nBoost: "..((monster.boost.health - 1) * 100).."%"..
			"\n\nAttack: "..monster.attack..
			"\nBoost: "..((monster.boost.attack - 1) * 100).."%"..
			"\n\nDefense: "..monster.defense..
			"\nBoost: "..((monster.boost.defense - 1) * 100).."%"..
			"\n\nAgility: "..monster.agility..
			"\nBoost: "..((monster.boost.agility - 1) * 100).."%"..
			"\n\nNext Level: "..exp_needed_for_level_up.." EXP"..
			"\nEXP Total: "..monster.exp_total.." EXP"..
			(monster.prisma_id and "\n\nPrisma Color: "..monster.prisma_id or "")..
			"\n\nPersonality: "..monster.personality..
			(monster.base.morph_level and "\n\nMorph Level: "..monster.base.morph_level or "")..
			(monster.base.morphs_into and "\nMorphs Into: "..monsters.stats[monster.base.morphs_into].name or "")..
			"\n\nMoves: "..monster_moves
			
		formspec = formspec..
			fs.font_style("textarea,field", "mono", "*0.94", "#FFFFFF")..
			fs.image(0.25, 1.3, 2.5, 2.5, "zoonami_"..monster.asset_name.."_front"..(monster.prisma_id or "")..".png")..
			fs.field(0.25, 4, 2.5, 0.6, "rename_field", "", "")..
			"field_close_on_enter[rename_field;false]"..
			fs.button(0.25, 4.6, 2.5, 0.75, "rename_monster", "Rename")..
			fs.textarea(3, 1.3, 7.9, 8.2, textarea)
			
		if not monster.starter_monster then
			formspec = formspec..
				fs.button(8.7, 0.33, 2, 0.75, "delete_monster_warning", "Delete")
			if context.delete_monster_warning then
				formspec = formspec..
					fs.box(0, 0, 11, 10, "#00000000")..
					fs.box(3, 3.5, 5, 3, "#222222EE")..
					fs.font_style("image_button", "mono,bold", "*1", "#FFFFFF")..
					fs.image_button(3, 3, 5, 3, "zoonami_blank", "label", "Delete monster?")..
					fs.box(3, 3, 5, 3, "#00000000")..
					fs.button(3.3, 5.5, 2, 0.75, "delete_monster", "Delete")..
					fs.button(5.7, 5.5, 2, 0.75, "cancel_monster_warning", "Cancel")
			end
		end
	end
	
	fsc.show(player_name, formspec, context, computer.formspec)
end

-- Computer
minetest.register_node(modname .. ":zoonami_computer", {
	description = "Zoonami Computer",
	drawtype = "mesh",
	mesh = "zoonami_computer.obj",
	tiles = {"zoonami_computer.png"},
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
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		if not player or not player:is_player() then return end
		computer.formspec(player)
	end,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})
minetest.register_alias(modname .. ":zoonami_computer", "zoonami:computer")
