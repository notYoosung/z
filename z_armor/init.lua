local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local hidden_players = {

}

minetest.register_on_chat_message(function(name, message)
	local inv = minetest.get_player_by_name(name):get_inventory()
	if inv:contains_item("armor", "z:helmet_void") or
	   inv:contains_item("armor", "z:chestplate_void") or
	   inv:contains_item("armor", "z:leggings_void") or
	   inv:contains_item("armor", "z:boots_void")
	then
		minetest.chat_send_all("«√ØÍ∂» " .. message)
		return true
	else
		-- return true
	end
end)


minetest.register_on_joinplayer(function(ObjectRef, last_login)
	local inv = ObjectRef:get_inventory()
	if inv:contains_item("armor", "z:helmet_void") or
	   inv:contains_item("armor", "z:chestplate_void") or
	   inv:contains_item("armor", "z:leggings_void") or
	   inv:contains_item("armor", "z:boots_void")
 	then
		hidename.hide(ObjectRef:get_player_name())
		hidden_players[ObjectRef:get_player_name()] = true
	else
		hidden_players[ObjectRef:get_player_name()] = hidename.hidden(ObjectRef:get_nametag_attributes())
	end
end)
minetest.register_on_leaveplayer(function(ObjectRef, timed_out)
	hidden_players[ObjectRef:get_player_name()] = nil
end)

local void_equip_callback = function(obj, itemstack)
	local inv = obj:get_inventory()
	if not hidename.hidden(obj:get_nametag_attributes()) then
		hidden_players[obj:get_player_name()] = false
		hidename.hide(obj:get_player_name())
	elseif not (inv:contains_item("armor", "z:helmet_void") or
		   inv:contains_item("armor", "z:chestplate_void") or
		   inv:contains_item("armor", "z:leggings_void") or
		   inv:contains_item("armor", "z:boots_void"))
	then
		hidden_players[obj:get_player_name()] = true
		minetest.chat_send_player(obj:get_player_name(), "Void armor equipped, but nametag is already hidden")
	else
		-- minetest.chat_send_player(obj:get_player_name(), "Void armor equipped, but nametag is already hidden")
	end
end

local void_unequip_callback = function(obj, itemstack)
	local inv = obj:get_inventory()
	-- minetest.log(tostring(inv:get_list("armor")))
	-- z:helmet_void
	if inv:contains_item("armor", "z:helmet_void") or
	   inv:contains_item("armor", "z:chestplate_void") or
	   inv:contains_item("armor", "z:leggings_void") or
	   inv:contains_item("armor", "z:boots_void")
	then
		minetest.chat_send_player(obj:get_player_name(), "Void armor is still equiped; nametag will stay hidden")
	else
		if hidden_players[obj:get_player_name()] == false then
			hidename.show(obj:get_player_name())
		else
			minetest.chat_send_player(obj:get_player_name(), "Nametag was previously hidden, so it will stay hidden")
		end
		
	end
end

mcl_armor.register_set({
	--name of the armor material (used for generating itemstrings)
	name = "void",

	--localized description of each armor piece
	descriptions = {
		head = "Void Helmet",
		torso = "Void Chestplate",
		legs = "Void Leggings",
		feet = "Void Boots",
	},

	--The following MCL2 compatible legacy behavior is still supported, but
	--deprecated, because it interferes with proper localization
	--it is triggered when description is non nil
	--[[
	--description of the armor material
	--do NOT translate this string, it will be concatenated will each piece of armor's description and result will be automatically fetched from your mod's translation files
	description = "Dummy Armor",

	--overide description of each armor piece
	--do NOT localize this string
	descriptions = {
		head = "Cap",    --default: "Helmet"
		torso = "Tunic", --default: "Chestplate"
		legs = "Pants",  --default: "Leggings"
		feet = "Shoes",  --default: "Boots"
	},
	]]

	--this is used to calculate each armor piece durability with the minecraft algorithm
	--head durability = durability * 0.6857 + 1
	--torso durability = durability * 1.0 + 1
	--legs durability = durability * 0.9375 + 1
	--feet durability = durability * 0.8125 + 1
	durability = -1,

	--this is used then you need to specify the durability of each piece of armor
	--this field have the priority over the durability one
	--if the durability of some pieces of armor isn't specified in this field, the durability field will be used insteed
	durabilities = {
		head = -1,
		torso = -1,
		legs = -1,
		feet = -1,
	},

	--this define how good enchants you will get then enchanting one piece of the armor in an enchanting table
	--if set to zero or nil, the armor will not be enchantable
	enchantability = 65535,

	--this define how much each piece of armor protect the player
	--these points will be shown in the HUD (chestplate bar above the health bar)
	points = {
		head = 1000,
		torso = 1000,
		legs = 1000,
		feet = 1000,
	},

	--this attribute reduce strong damage even more
	--See https://minecraft.fandom.com/wiki/Armor#Armor_toughness for more explanations
	--default: 0
	toughness = 100,

	--this field is used to specify some items groups that will be added to each piece of armor
	--please note that some groups do NOT need to be added by hand, because they are already handeled by the register function:
	--(armor, combat_armor, armor_<element>, combat_armor_<element>, mcl_armor_points, mcl_armor_toughness, mcl_armor_uses, enchantability)
	groups = {metal_armor = 1},

	--specify textures that will be overlayed on the entity wearing the armor
	--these fields have default values and its recommanded to keep the code clean by just using the default name for your textures
	-- textures = {
	-- 	head = "z_armor_helmet_void.png",  --default: "<modname>_helmet_<material>.png"
	-- 	torso = "z_armor_chestplate_void.png", --default: "<modname>_chestplate_<material>.png"
	-- 	legs = "z_armor_leggings_void.png",  --default: "<modname>_leggings_<material>.png"
	-- 	feet = "z_armor_boots_void.png",  --default: "<modname>_boots_<material>.png"
	-- },
	--you can also define these fields as functions, that will be called each time the API function mcl_armor.update(obj) is called (every time you equip/unequip some armor piece, take damage, and more)
	--note that the enchanting overlay will not appear unless you implement it in the function
	--this allow to make armors where the textures change whitout needing to register many other armors with different textures
	textures = {
		head = function(obj, itemstack)
			if mcl_enchanting.is_enchanted(itemstack) then
				return "z_armor_helmet_void.png^"..mcl_enchanting.overlay
			else
				return "z_armor_helmet_void.png"
			end
		end,
		torso = function(obj, itemstack)
			if mcl_enchanting.is_enchanted(itemstack) then
				return "z_armor_chestplate_void.png^"..mcl_enchanting.overlay
			else
				return "z_armor_chestplate_void.png"
			end
		end,
		legs = function(obj, itemstack)
			if mcl_enchanting.is_enchanted(itemstack) then
				return "z_armor_leggings_void.png^"..mcl_enchanting.overlay
			else
				return "z_armor_leggings_void.png"
			end
		end,
		feet = function(obj, itemstack)
			if mcl_enchanting.is_enchanted(itemstack) then
				return "z_armor_boots_void.png^"..mcl_enchanting.overlay
			else
				return "z_armor_boots_void.png"
			end
		end,
	},

	--inventory textures aren't definable using a table similar to textures or previews
	--you are forced to use the default texture names which are:
	--head: "<modname>_inv_helmet_<material>.png
	--torso: "<modname>_inv_chestplate_<material>.png
	--legs: "<modname>_inv_leggings_<material>.png
	--feet: "<modname>_inv_boots_<material>.png

	--this callback table allow you to define functions that will be called each time an entity equip an armor piece or the mcl_armor.on_equip() function is called
	--the functions accept two arguments: obj and itemstack
	on_equip_callbacks = {
		head = void_equip_callback,
		torso = void_equip_callback,
		legs = void_equip_callback,
		feet = void_equip_callback,
	},

	--this callback table allow you to define functions that will be called each time an entity unequip an armor piece or the mcl_armor.on_unequip() function is called
	--the functions accept two arguments: obj and itemstack
	on_unequip_callbacks = {
		head = void_unequip_callback,
		torso = void_unequip_callback,
		legs = void_unequip_callback,
		feet = void_unequip_callback,
	},

	--this callback table allow you to define functions that will be called then an armor piece break
	--the functions accept one arguments: obj
	--the itemstack isn't sended due to how minetest handle items which have a zero durability
	on_break_callbacks = {
		head = function(obj)
			--do stuff
		end,
	},

	--this is used to generate automaticaly armor crafts based on each element type folowing the regular minecraft pattern
	--if set to nil no craft will be added
	craft_material = "z_metal:metal_ingot",

	--this is used to generate cooking crafts for each piece of armor
	--if set to nil no craft will be added
	cook_material = "z_metal:metal_lump", --cooking any piece of this armor will output a gold nugged

	--this is used for allowing each piece of the armor to be repaired by using an anvil with repair_material as aditionnal material
	--it basicaly set the _repair_material item field of each piece of the armor
	--if set to nil no repair material will be added
	repair_material = "z_metal:metal_ingot",
})

