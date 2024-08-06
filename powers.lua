local modpath = minetest.get_modpath(minetest.get_current_modname())
local modname = minetest.get_current_modname()

local S = minetest.get_translator(minetest.get_current_modname())
local F = minetest.formspec_escape
local C = minetest.colorize

local max_text_length = 4500 -- TODO: Increase to 12800 when scroll bar was added to written book
local max_title_length = 64


-- local powers = {

-- }


local header = ""
if minetest.get_modpath("mcl_init") then
	header = "no_prepend[]" .. mcl_vars.gui_nonbg .. mcl_vars.gui_bg_color ..
		"style_type[button;border=false;bgimg=mcl_books_button9.png;bgimg_pressed=mcl_books_button9_pressed.png;bgimg_middle=2,2]"
end

-- Book
minetest.register_craftitem(modname .. ":book", {
	description = S("Book"),
	inventory_image = "default_book.png",
	groups = { book = 1, craftitem = 1, enchantability = 1 },
	_mcl_enchanting_enchanted_tool = modname .. ":book_selected",
})


local function make_description(title, author, generation)
	local desc
	if generation == 0 then
		desc = S("“@1”", title)
	elseif generation == 1 then
		desc = S("Copy of “@1”", title)
	elseif generation == 2 then
		desc = S("Copy of Copy of “@1”", title)
	else
		desc = S("Tattered Book")
	end
	desc = desc .. "\n" .. minetest.colorize(mcl_colors.GRAY, S("by @1", author))
	return desc
end

local function cap_text_length(text, max_length)
	return string.sub(text, 1, max_length)
end

local function write(itemstack, user, pointed_thing)
	local rc = mcl_util.call_on_rightclick(itemstack, user, pointed_thing)
	if rc then return rc end
    --.25/6
    -- 73x90
	local text = itemstack:get_meta():get_string("text")
	local formspec = table.concat({
        "formspec_version[4]",
        "size[14.6,9]",
		header,
		"background[-0.5,-0.5;9,10;z_powers_page_left.png]",
		"background[7.5,-0.5;9,10;z_powers_page_right.png]",
		"background[7.5,-0.5;9,10;z_powers_page_button_yes.png]",
		"background[7.5,-0.5;9,10;z_powers_page_button_no.png]",
		--"textarea[0.75,0.1;7.25,9;text;;" .. minetest.formspec_escape(text) .. "]",
		--"button[0.75,7.95;3,1;sign;" .. minetest.formspec_escape(S("Sign")) .. "]",
		--"button_exit[4.25,7.95;3,1;ok;" .. minetest.formspec_escape(S("Done")) .. "]",
		"button_exit[08.45,1.5;3.178,1.7;yes;" .. minetest.formspec_escape(" ") .. "]",
		"button_exit[12.054,1.8;3.178,1.7;no;" .. minetest.formspec_escape(" ") .. "]",
    })
    minetest.show_formspec(user:get_player_name(), modname .. ":writable_book", formspec)
end

local function read(itemstack, user, pointed_thing)
	local rc = mcl_util.call_on_rightclick(itemstack, user, pointed_thing)
	if rc then return rc end

	local text = itemstack:get_meta():get_string("text")
	local formspec = "size[8,9]" ..
		header ..
		"background[-0.5,-0.5;9,10;mcl_books_book_bg.png]" ..
		"textarea[0.75,0.1;7.25,9;;" .. minetest.formspec_escape(text) .. ";]" ..
		"button_exit[2.25,7.95;3,1;ok;" .. minetest.formspec_escape(S("Done")) .. "]"
	minetest.show_formspec(user:get_player_name(), modname .. ":written_book", formspec)
end

-- Book and Quill
minetest.register_craftitem(modname .. ":writable_book", {
	description = S("Book and Quill"),
	_tt_help = S("Write down some notes"),
	_doc_items_longdesc = S("This item can be used to write down some notes."),
	_doc_items_usagehelp = S(
			"Hold it in the hand, then rightclick to read the current notes and edit then. You can edit the text as often as you like. You can also sign the book which turns it into a written book which you can stack, but it can't be edited anymore.")
		.. "\n" ..
		S("A book can hold up to 4500 characters. The title length is limited to 64 characters."),
	inventory_image = "mcl_books_book_writable.png",
	groups = { book = 1 },
	stack_max = 1,
	on_place = write,
	on_secondary_use = write,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if ((formname == modname .. ":writable_book") and fields and fields.text) then
		local stack = player:get_wielded_item()
		if (stack:get_name() and (stack:get_name() == modname .. ":writable_book")) then
			local meta = stack:get_meta()
			local text = cap_text_length(fields.text, max_text_length)
			if fields.ok then
				meta:set_string("text", text)
				player:set_wielded_item(stack)
			elseif fields.sign then
				meta:set_string("text", text)
				player:set_wielded_item(stack)

				local name = player:get_player_name()
				local formspec = "size[8,9]" ..
					header ..
					"background[-0.5,-0.5;9,10;mcl_books_book_bg.png]" ..
					"field[0.75,1;7.25,1;title;" ..
					minetest.formspec_escape(minetest.colorize("#000000", S("Enter book title:"))) .. ";]" ..
					"label[0.75,1.5;" ..
					minetest.formspec_escape(minetest.colorize("#404040", S("by @1", name))) .. "]" ..
					"button_exit[0.75,7.95;3,1;sign;" .. minetest.formspec_escape(S("Sign and Close")) .. "]" ..
					"tooltip[sign;" ..
					minetest.formspec_escape(S("Note: The book will no longer be editable after signing")) .. "]" ..
					"button[4.25,7.95;3,1;cancel;" .. minetest.formspec_escape(S("Cancel")) .. "]"
				minetest.show_formspec(player:get_player_name(), modname .. ":signing", formspec)
			elseif fields.yes then
				meta:set_string("text", text)
				player:set_wielded_item(stack)

			elseif fields.no then
				meta:set_string("text", text)
				player:set_wielded_item(stack)

			end
		end
	elseif ((formname == modname .. ":signing") and fields and fields.sign and fields.title) then
		local newbook = ItemStack(modname .. ":written_book")
		local book = player:get_wielded_item()
		local name = player:get_player_name()
		if book:get_name() == modname .. ":writable_book" then
			local title = fields.title
			if string.len(title) == 0 then
				title = S("Nameless Book")
			end
			title = cap_text_length(title, max_title_length)
			local meta = newbook:get_meta()
			local text = cap_text_length(book:get_meta():get_string("text"), max_text_length)
			meta:set_string("title", title)
			meta:set_string("author", name)
			meta:set_int("date", os.time())
			meta:set_string("text", text)
			meta:set_string("description", make_description(title, name, 0))

			-- The book copy counter. 0 = original, 1 = copy of original, 2 = copy of copy of original, …
			meta:set_int("generation", 0)

			player:set_wielded_item(newbook)
		else
			minetest.log("error", "[mcl_books] " .. name .. " failed to sign a book!")
		end
	elseif ((formname == modname .. ":signing") and fields and fields.cancel) then
		local book = player:get_wielded_item()
		if book:get_name() == modname .. ":writable_book" then
			write(book, player, { type = "nothing" })
		end
	end
end)

minetest.register_craft({
	type = "shapeless",
	output = modname .. ":writable_book",
	recipe = { modname .. ":bookbook", "mcl_mobitems:ink_sac", "mcl_mobitems:feather" },
})

-- Written Book
minetest.register_craftitem(modname .. ":written_book", {
	description = S("Written Book"),
	_doc_items_longdesc = S(
		"Written books contain some text written by someone. They can be read and copied, but not edited."
	),
	_doc_items_usagehelp = S("Hold it in your hand, then rightclick to read the book.") ..
		"\n\n" ..
		S(
			"To copy the text of the written book, place it into the crafting grid together with a book and quill (or multiple of those) and craft. The written book will not be consumed. Copies of copies can not be copied."
		),
	inventory_image = "mcl_books_book_written.png",
	groups = { not_in_creative_inventory = 1, book = 1, no_rename = 1 },
	stack_max = 16,
	on_place = read,
	on_secondary_use = read
})

--This adds 8 recipes containing 1 written book and 1-8 writeable book
for i = 1, 8 do
	local rc = {}
	table.insert(rc, modname .. ":written_book")
	for j = 1, i do	table.insert(rc, modname .. ":writable_book") end

	minetest.register_craft({
		type = "shapeless",
		output = modname .. ":written_book " .. i,
		recipe = rc,
	})
end

local function craft_copy_book(itemstack, player, old_craft_grid, craft_inv)
	if itemstack:get_name() ~= modname .. ":written_book" then
		return
	end

	local original
	local index
	for i = 1, player:get_inventory():get_size("craft") do
		if old_craft_grid[i]:get_name() == modname .. ":written_book" then
			original = old_craft_grid[i]
			index = i
		end
	end
	if not original then
		return
	end

	local ometa = original:get_meta()
	local generation = ometa:get_int("generation")

	-- No copy of copy of copy of book allowed
	if generation >= 2 then
		return ItemStack("")
	end

	-- Copy metadata
	local imeta = itemstack:get_meta()
	imeta:from_table(ometa:to_table())
	imeta:set_string("title", cap_text_length(ometa:get_string("title"), max_title_length))
	imeta:set_string("text", cap_text_length(ometa:get_string("text"), max_text_length))

	-- Increase book generation and update description
	generation = generation + 1
	if generation < 1 then
		generation = 1
	end

	imeta:set_string("description", make_description(ometa:get_string("title"), ometa:get_string("author"), generation))
	imeta:set_int("generation", generation)
	return itemstack, original, index
end
minetest.register_craft_predict(craft_copy_book)

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	local _, original, index = craft_copy_book(itemstack, player, old_craft_grid, craft_inv)
	if original and index then craft_inv:set_stack("craft", index, original) end
end)


-- minetest.register_craft({
-- 	type = "fuel",
-- 	recipe = modname .. ":bookbookshelf",
-- 	burntime = 15,
-- })


--


--SPINNI


local magic_circle_entity = {
	physical = false,
	collisionbox = {-0.125,-0.125,-0.125, 0.125,0.125,0.125},
	visual = "wielditem",
	textures = {"wield3d:hand"},
	wielder = nil,
	timer = 0,
	static_save = false,
}

minetest.register_entity(modname .. ":powers_magic_circle", {

})



local location = {
	"Arm_Right",          -- default bone
	{x=0, y=5.5, z=3},    -- default position
	{x=-90, y=225, z=90}, -- default rotation
	{x=wield_scale, y=wield_scale},
}


local bone = "Arm_Right"
local pos = {x=0, y=5.5, z=3}
local scale = {x=0.25, y=0.25}
local rx = -90
local rz = 90

wield3d.location = {
	["default:torch"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["default:sapling"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:dandelion_white"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:dandelion_yellow"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:geranium"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:rose"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:tulip"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:viola"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["default:shovel_wood"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["default:shovel_stone"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["default:shovel_steel"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["default:shovel_bronze"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["default:shovel_mese"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["default:shovel_diamond"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["bucket:bucket_empty"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["bucket:bucket_water"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["bucket:bucket_lava"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["screwdriver:screwdriver"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["screwdriver:screwdriver1"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["screwdriver:screwdriver2"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["screwdriver:screwdriver3"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["screwdriver:screwdriver4"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["vessels:glass_bottle"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["vessels:drinking_glass"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["vessels:steel_bottle"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
}

function magic_circle_entity:on_step(dtime)
	if self.wielder == nil then return end
	self.timer = self.timer + dtime
	if self.timer < update_time then return end
	local player = minetest.get_player_by_name(self.wielder)
	if player == nil or not player:is_player() or sq_dist(player:get_pos(), self.object:get_pos()) > 3 then
		self.object:remove()
		return
	end
	local wield = player_wielding[self.wielder]
	local stack = player:get_wielded_item()
	local item = stack:get_name() or ""
	if wield and item ~= wield.item then
		if has_wieldview then
			local def = minetest.registered_items[item] or {}
			if def.inventory_image ~= "" then item = "" end
		end
		wield.item = item
		if item == "" then item = "wield3d:hand" end
		local loc = wield3d.location[item] or location
		if loc[1] ~= wield.location[1] or not vector.equals(loc[2], wield.location[2]) or not vector.equals(loc[3], wield.location[3]) then
			self.object:set_attach(player, loc[1], loc[2], loc[3])
			wield.location = {loc[1], loc[2], loc[3]}
		end
		self.object:set_properties({
			textures = {item},
			visual_size = loc[4]
		})
	end
	self.timer = 0
end


minetest.register_on_joinplayer(function(ObjectRef, last_login)
	minetest.add_entity(ObjectRef:get_pos(), modname .. ":powers_magic_circle", {

	})
end)



