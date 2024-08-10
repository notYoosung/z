local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

-- Guide Book

-- Local namespace
local guide_book = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local fs = dofile(mod_path .. "/lua/formspec.lua")

-- Craft Item
minetest.register_craftitem(modname .. ":zoonami_guide_book", {
	description = "Zoonami Guide Book",
	inventory_image = "zoonami_guide_book.png",
	groups = {book = 1},
	stack_max = 1,
	on_secondary_use = function (itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end
		guide_book.formspec(user)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		if not placer or not placer:is_player() then return end
		local node = minetest.get_node_or_nil(pointed_thing.under)
		local def = node and minetest.registered_nodes[node.name] or {}
		if def.on_rightclick then
			return def.on_rightclick(pointed_thing.under, node, placer, itemstack)
		else
			guide_book.formspec(placer)
		end
	end,
})

-- Callback from fsc mod
function guide_book.fsc_callback(player, fields, context)
	if not fields.quit then
		guide_book.formspec(player, fields)
	end
end

-- Shows formspec
function guide_book.formspec(player, fields)
	local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local introduction_items = player_meta:get_string("zoonami_introduction_items")
	local stack = player:get_wielded_item()
	local meta = minetest.deserialize(stack:get_meta():get_string("meta"))
	fields = fields or {}
	local field_key = next(fields) or ""
	
	-- Initialize metadata if nil or if section is non-existent
	if meta == nil or not guide_book[meta.section] then
		meta = {}
		meta.section = "index"
		meta.page = 1
	end
	
	-- Handle button presses
	if guide_book[field_key] then
		meta.section = field_key
		meta.page = meta.section == "index" and meta.previous_index_page or 1
		meta.previous_index_page = meta.section ~= "index" and meta.previous_index_page or nil
	elseif field_key == "next" then
		meta.page = meta.page + 1
	elseif field_key == "back" then
		meta.page = meta.page - 1
	end
	
	-- Handle current page
	if meta.page > guide_book[meta.section].pages then
		meta.page = 1
	elseif meta.page < 1 then
		meta.page = guide_book[meta.section].pages
	end
	
	-- Save previous index page number
	if meta.section == "index" then
		meta.previous_index_page = meta.page
	end
	
	-- Give starter items when introduction section is finished
	if introduction_items ~= "true" and meta.section == "introduction" and meta.page == guide_book.introduction.pages then
		local inv = player:get_inventory()
		local items = {modname .. ":zoonami_healer", modname .. ":zoonami_computer", modname .. ":zoonami_simple_berry_juice 5", modname .. ":zoonami_super_berry_juice 2"}
		for i = 1, #items do
			local leftover = inv:add_item("main", items[i])
			if leftover:get_count() > 0 then
				minetest.add_item(player:get_pos(), leftover)
			end
		end
		player_meta:set_string("zoonami_introduction_items", "true")
		minetest.sound_play("zoonami_level_up", {to_player = player_name, gain = 1}, true)
	end
	
	-- Play sound
	if field_key ~= "" then
		minetest.sound_play("zoonami_guide_book_page_turn", {to_player = player_name, gain = 1}, true)
	end
	
	-- Show formspec
	local formspec = fs.header(10, 10, "false", "#00000000")..
		fs.button_style(1, 8)..
		fs.background(0, 0, 10, 10, "zoonami_guide_book_blank_page.png")..
		fs.font_style("button,image_button,label", "mono,bold", "*1", "#000000")..
		fs.font_style("textarea", "mono", "*0.94", "#000000")..
		fs.image_button(0, 8.5, 10, 0.5, "zoonami_blank", "index", "Page "..meta.page.." of "..guide_book[meta.section].pages)..
		fs.box(0, 8.5, 10, 0.5, "#00000000")..
		guide_book[meta.section].navigation..
		guide_book[meta.section]["page_"..meta.page]
	
	stack:get_meta():set_string("meta", minetest.serialize(meta))
	player:set_wielded_item(stack)
	fsc.show(player_name, formspec, nil, guide_book.fsc_callback)
end

-- Guide Book Sections
guide_book.index = {}
guide_book.index.pages = 3
guide_book.index.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "index", "Index")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.index.page_1 = fs.box(0.6, 1.25, 8.75, 0.5, "#00CB8899")..
	fs.label(0.7, 1.5, "Basics")..
	fs.box(0.6, 1.75, 8.75, 2, "#00CB88FF")..
	fs.button(0.6, 1.875, 4.25, 0.75, "introduction", "Introduction")..
	fs.button(5.1, 1.875, 4.25, 0.75, "backpack", "Backpack")..
	fs.button(0.6, 2.875, 4.25, 0.75, "journals", "Journals")..
	fs.box(0.6, 4.25, 8.75, 0.5, "#FFA85099")..
	fs.label(0.7, 4.5, "Monsters")..
	fs.box(0.6, 4.75, 8.75, 3, "#FFA850FF")..
	fs.button(0.6, 4.875, 4.25, 0.75, "taming", "Taming")..
	fs.button(5.1, 4.875, 4.25, 0.75, "morphing", "Morphing")..
	fs.button(0.6, 5.875, 4.25, 0.75, "computer", "Computer")..
	fs.button(5.1, 5.875, 4.25, 0.75, "trading_machine", "Trading Machine")..
	fs.button(0.6, 6.875, 4.25, 0.75, "prisma_monsters", "Prisma Monsters")
guide_book.index.page_2 = fs.box(0.6, 1.25, 8.75, 0.5, "#FF635E99")..
	fs.label(0.7, 1.5, "Combat")..
	fs.box(0.6, 1.75, 8.75, 3, "#FF635EFF")..
	fs.button(0.6, 1.875, 4.25, 0.75, "battles", "Battles")..
	fs.button(5.1, 1.875, 4.25, 0.75, "training", "Training")..
	fs.button(0.6, 2.875, 4.25, 0.75, "moves", "Moves")..
	fs.button(5.1, 2.875, 4.25, 0.75, "type_chart", "Type Chart")..
	fs.button(0.6, 3.875, 4.25, 0.75, "personalities", "Personalities")..
	fs.box(0.6, 5.25, 8.75, 0.5, "#7B6DAB99")..
	fs.label(0.7, 5.5, "Exploration")..
	fs.box(0.6, 5.75, 8.75, 2, "#7B6DABFF")..
	fs.button(0.6, 5.875, 4.25, 0.75, "mining", "Mining")..
	fs.button(5.1, 5.875, 4.25, 0.75, "villages", "Villages")..
	fs.button(0.6, 6.875, 4.25, 0.75, "npcs", "NPCs")
guide_book.index.page_3 = fs.box(0.6, 1.25, 8.75, 0.5, "#39C1DB99")..
	fs.label(0.7, 1.5, "Economy")..
	fs.box(0.6, 1.75, 8.75, 1, "#39C1DBFF")..
	fs.button(0.6, 1.875, 4.25, 0.75, "zoonami_coins", "Zoonami Coins")..
	fs.button(5.1, 1.875, 4.25, 0.75, "vending_machines", "Vending Machines")..
	fs.box(0.6, 3.25, 8.75, 0.5, "#BABABA99")..
	fs.label(0.7, 3.5, "Technical")..
	fs.box(0.6, 3.75, 8.75, 1, "#BABABAFF")..
	fs.button(0.6, 3.875, 4.25, 0.75, "chat_commands", "Chat Commands")..
	fs.button(5.1, 3.875, 4.25, 0.75, "creative", "Creative")

-- Introduction
guide_book.introduction = {}
guide_book.introduction.pages = 10
guide_book.introduction.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "introduction", "Introduction")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.introduction.page_1 = "textarea[0.5,1.25;9,7;;;Welcome! Zoonami is a mod that adds monsters that you can collect, train, and use in battles. This introduction will teach you everything you need to know to start playing.\n\nAt the end of the introduction, you will be gifted a healer, computer, and berry juice.]"
guide_book.introduction.page_2 = "textarea[0.5,1.25;9,7;;;To begin your journey, you'll need to choose a starter monster. To do this, right click while holding a Zoonami Backpack to open the backpack menu. On the monsters page you'll be able to choose between three starter monsters.]"
guide_book.introduction.page_3 = "textarea[0.5,1.25;9,7;;;After choosing your starter monster, the monsters page will change and become a place for managing the monsters in your party.\n\nTo learn more about the backpack menu, the guide book has a \"Backpack\" section with more details.]"
guide_book.introduction.page_4 = "textarea[0.5,1.25;9,7;;;To heal monsters in your party, right click on a Zoonami Healer. Healers drop no items when broken and can only be broken with a mid-tier or higher pickaxe. Only place a healer in a spot where you want it to stay!\n\nTo craft additional healers, you'll need to find Zeenite Ore and Crystals underground. To learn more about mining, the guide book has a \"Mining\" section with more details.]"
guide_book.introduction.page_5 = "textarea[0.5,1.25;9,7;;;Alternatively, monsters can be healed with berry juice. Simple berry juice can fully heal one monster. Super berry juice heals your entire party. Right click while holding either of these items to use them.\n\nBerry juice can't be crafted. It can only be obtained by purchasing it from merchants or vending machines.]"
guide_book.introduction.page_6 = "textarea[0.5,1.25;9,7;;;It's time for your first battle! To initiate a battle, right click on a wild monster. Wild monsters can be found roaming around almost anywhere. When the battle starts, the wild monster will vanish and appear in the battle formspec.\n\nIf all of the monsters in your party have zero health, you won't be able to start a battle.]"
guide_book.introduction.page_7 = "textarea[0.5,1.25;9,7;;;The battle formspec consists of four menus. The battle menu is for selecting a move to use. The party menu is for viewing and switching to other monsters in your party. The items menu is for using items in battle. The skip button skips your turn in case your monster needs to recover energy to use a move.]"
guide_book.introduction.page_8 = "textarea[0.5,1.25;9,7;;;During wild monster battles, exiting the battle formspec before a battle finishes is treated as running away. You can exit the formspec by pressing the ESC key or double clicking outside the formspec.\n\nThis can be useful if a wild monster is too strong to battle. However, during a PVP battle, exiting the battle formspec counts as a forfeit. PVP wins, loses, and forfeits are saved under player stats. These stats are visible to other players and may affect if another player wants to battle you.]"
guide_book.introduction.page_9 = "textarea[0.5,1.25;9,7;;;You may have noticed that unlike other formspecs, the backpack menu and battle formspecs will not automatically scale to your screen size. \n\nInstead, if either formspec is too small or too large, the size can be manually adjusted on the settings page in the backpack menu.]"
guide_book.introduction.page_10 = "textarea[0.5,1.25;9,7;;;Congratulations! You have finished the introduction! A few items have been gifted to you to help you get started. It is recommended that you read other sections of the guide book gradually as you progress through the game.]"

-- Backpack
guide_book.backpack = {}
guide_book.backpack.pages = 7
guide_book.backpack.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "backpack", "Backpack")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.backpack.page_1 = "textarea[0.5,1.25;9,7;;;The Zoonami Backpack functions as the main menu for the Zoonami mod. The menu is accessed by right clicking while holding a Zoonami Backpack. The menu consists of five pages. There's a page for monsters, items, PVP, player stats, and settings.]"
guide_book.backpack.page_2 = "textarea[0.5,1.25;9,7;;;The monsters page initially serves as a way for new players to choose a starter monster. After a starter is chosen, the page acts as a way to manage monsters in your party. Players can have up to five monsters in their party.\n\nThe monster order can be changed by pressing the up and down arrow buttons on each monster. The first monster in the party that has one or more health is the first monster sent out in battle.]"
guide_book.backpack.page_3 = "textarea[0.5,1.25;9,7;;;The heart button is for showcasing a monster. Showcase monsters are spawned in front of the player. They have a nametag with the player's name and will follow the player around. If the heart button is pressed again or the player is too far away, the showcase monster will despawn.\n\nThe three lines button is for viewing detailed stats about the monster.\n\nThe four blue move buttons are used for remapping moves. Pressing one of the buttons will cycle through the monster's move pool for that move slot.]"
guide_book.backpack.page_4 = "textarea[0.5,1.25;9,7;;;The items page has 12 item slots for holding items to be used in battle. It can also be used as extra storage. Any item that can't be used in battle will simply be ignored when accessing the items menu during battle.]"
guide_book.backpack.page_5 = "textarea[0.5,1.25;9,7;;;The PVP page allows two players to battle. One player hosts the battle and the other player joins the battle.\n\nTo learn more, the guide book has a \"Battles\" section with more details.]"
guide_book.backpack.page_6 = "textarea[0.5,1.25;9,7;;;The player stats page lists stats about you. The bank shows how many Zoonami Coins (ZC) you have. The PVP wins, loses, and forfeits keeps track of the results of all non-casual PVP battles. These PVP stats are visible to other players via a chat command.\n\nTo learn more, the guide book has a \"Zoonami Coins\" section and a \"Chat Commands\" section with more details.]"
guide_book.backpack.page_7 = "textarea[0.5,1.25;9,7;;;The settings pages has options for configuring the backpack formspec size, battle formspec size, battle music volume, and battle sound effects.]"

-- Taming
guide_book.taming = {}
guide_book.taming.pages = 5
guide_book.taming.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "taming", "Taming")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.taming.page_1 = "textarea[0.5,1.25;9,7;;;Taming wild monsters is an essential part of Zoonami. To tame a monster, you need to collect special berries. There's red, blue, green, and orange berries.\n\nBerry bushes are the primary way to collect berries. They can be found growing in the wild. Right click on a berry bush that has berries to pick the berries. Breaking a berry bush will drop it as an item allowing it to be planted somewhere else.]"
guide_book.taming.page_2 = "textarea[0.5,1.25;9,7;;;Another option for obtaining berries is to defeat wild monsters and trainers. Most monsters have a chance of dropping berries as rewards. Different monsters drop different colored berries.\n\nA third option is to purchase berries from vending machines.]"
guide_book.taming.page_3 = "textarea[0.5,1.25;9,7;;;After you have collected four berries of the same color, place them in a 2x2 crafting grid to turn them into basic jelly jars. A 2x2 of basic jelly jars turns into improved jelly jars. A 2x2 of improved jelly jars turns into advanced jelly jars. Higher quality jelly has an increased chance of taming a monster.]"
guide_book.taming.page_4 = "textarea[0.5,1.25;9,7;;;Before you start battling, place your jelly jars in the items menu in your backpack. Only items in these 12 item slots are available to use during battle.\n\nDuring a battle, open the items menu to use the jelly. Monsters can be tamed with any jelly color. However, using a jelly color that the monster prefers and lowering the monsters health increases the chance of taming them.]"
guide_book.taming.page_5 = "textarea[0.5,1.25;9,7;;;Aquatic, avian, and spirit monsters prefer blue jelly.\n\nBeast, warrior, mutant, and fire monsters prefer red jelly.\n\nRodent, robotic, and rock monsters prefer orange jelly.\n\nPlant, insect, and reptile monsters prefer green jelly.]"
guide_book.taming.page_6 = "textarea[0.5,1.25;9,7;;;When a monster is tamed, the monster is placed in your party or folder 1 box 1 in your computer. If both locations are full, you will not be able to tame monsters.]"

-- Morphing
guide_book.morphing = {}
guide_book.morphing.pages = 4
guide_book.morphing.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "morphing", "Morphing")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.morphing.page_1 = "textarea[0.5,1.25;9,7;;;Some monsters are able to grow into a different monster once they reach a minimum level. This process is referred to as morphing. Each monster that can morph has a different minimum level. Once this level is reached, a special candy can be given to the monster to make it morph.]"
guide_book.morphing.page_2 = "textarea[0.5,1.25;9,7;;;The morph level and who the monster morphs into are listed on the monster stats in the backpack menu, computer, chat command, and monster journal.\n\nThe candies are crafted by placing four improved jelly jars around a berry. The jelly and berry must be the same color. This means there are red, blue, green, and orange candies.]"
guide_book.morphing.page_3 = "textarea[0.5,1.25;9,7;;;Aquatic, avian, and spirit monsters need blue candy.\n\nBeast, warrior, mutant, and fire monsters need red candy.\n\nRodent, robotic, and rock monsters need orange candy.\n\nPlant, insect, and reptile monsters need green candy.]"
guide_book.morphing.page_4 = "textarea[0.5,1.25;9,7;;;The prisma color and personality are the only stats that carry over to the new monster. All other stats and moves will not carry over. As a bonus, monsters that are morphed automatically learn one taught move (which would normally require a move book).]"

-- Mining
guide_book.mining = {}
guide_book.mining.pages = 4
guide_book.mining.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "mining", "Mining")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.mining.page_1 = "textarea[0.5,1.25;9,7;;;Zeenite ore, crystals, and excavation sites can be found underground.\n\nZeenite is a fairly common orange colored ore. It's used for many Zoonami crafting recipes such as computers, trading machines, and vending machines.]"
guide_book.mining.page_2 = "textarea[0.5,1.25;9,7;;;Crystals are a hollow structure containing a crystal fragment. Before the fragment can be broken, the light puzzle on the floor of the crystal must be solved.\n\nAll lights need to be turned off. Right clicking on any light, both on or off, inverts the light and the four adjacent lights. Once the lights are off, the crystal fragment can be collected. If it still can't be collected, check for other nearby crystals and solve those puzzles as well.]"
guide_book.mining.page_3 = "textarea[0.5,1.25;9,7;;;Excavation sites consist of a core node surrounded by debris nodes. The core node looks like a small circular fossil. Debris nodes look like normal fossils. Do not mine the debris nodes! Instead, mine around the debris nodes so that nothing is above them except air, liquids, torches, or other debris nodes. After everything is cleared, mine the core node.\n\nIf done correctly, you'll have a chance of receiving random loot. If done incorrectly or you're unlucky, no loot will drop.]"
guide_book.mining.page_4 = "textarea[0.5,1.25;9,7;;;One of the loot items that can be obtained from excavation sites is a mystery egg. Mystery eggs can be hatched by placing the egg and right clicking on it. Each egg needs an environment with a suitable light level to hatch. When the egg hatches, a wild monster will spawn.\n\nThere are currently three monsters that can hatch from mystery eggs. Monsters will be around level 25 to level 40. Plan accordingly if you want to tame these monsters.]"

-- Battles
guide_book.battles = {}
guide_book.battles.pages = 12
guide_book.battles.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "battles", "Battles")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.battles.page_1 = "textarea[0.5,1.25;9,7;;;This section explains the battle formspec along with wild battles, trainer battles, and PVP battles.]"
guide_book.battles.page_2 = "textarea[0.5,1.25;9,7;;;The battle formspec consists of four menus. The battle menu is for selecting a move to use. Hovering your mouse over a move will show a tooltip with more details about the move such as the type, priority, etc.\n\nThe party menu allows you to view the monsters in your party. It also allows you to switch monsters. Switching monsters counts as a move with a priority of zero. To learn more about move priority, refer to the \"Moves\" section in the guide book.]"
guide_book.battles.page_3 = "textarea[0.5,1.25;9,7;;;The items menu allows you to view and use items during battle. To use an item in battle, it must be stored in one of the 12 item slots on the items page in the backpack menu. Currently jelly jars are the only item that can be used in battle. All other items stored in the item slots are ignored during battle.\n\nThe skip button allows a player to skip their turn. This is primarily used to allow a monster to recover energy.]"
guide_book.battles.page_4 = "textarea[0.5,1.25;9,7;;;There are three types of battles in Zoonami. Wild battles are the most common. This battle type occurs when a player right clicks on a wild monster. The monster will vanish from the world and appear in the battle formspec. This means players only have one chance to battle a wild monster.\n\nDefeating the monster will earn EXP, ZC, and a chance for item rewards. Wild monsters can also be tamed by using jelly in the items menu.]"
guide_book.battles.page_5 = "textarea[0.5,1.25;9,7;;;Trainer battles occur when a player battles an NPC. NPCs will only battle one player per Minetest day. This refreshes every day at midnight.\n\nThe amount of monsters a trainer has is represented by circles below the opponent's monster stats. A filled circle is a monster with at least one health. An unfilled circle is a monster with zero health. Defeating a monster will earn EXP, ZC, and a chance for item rewards. To earn the ZC and items, all of the opponent's monsters must be defeated. Trainers give 1.5 times more ZC than wild battles. Items cannot be used.]"
guide_book.battles.page_6 = "textarea[0.5,1.25;9,7;;;PVP battles occur when two players battle. The amount of monsters a player has is represented by circles below the opponent's monster stats. A filled circle is a monster with at least one health. An unfilled circle is a monster with zero health. No EXP, ZC, or items are earned. Items cannot be used.\n\nTo start a PVP battle, open the backpack menu and navigate to the PVP page. One player will need to host the battle and the other player will need to join the battle.]"
guide_book.battles.page_7 = "textarea[0.5,1.25;9,7;;;The hosting player is responsible for configuring the battle rules. After the rules are configured, the host needs to type the opponent's player name in the host text field and press enter. If successful, the status should mention that it's waiting for the opponent.\n\nWhen the host is ready, the joining player can type the opponent's player name in the join field and press enter. If successful, the status should mention you joined the other player. Review the rules the host has proposed and either accept to start the battle or reject to leave.]"
guide_book.battles.page_8 = "textarea[0.5,1.25;9,7;;;There are six battle rules.\n\nCasual if enabled makes the battle not count towards the player's wins, loses, and forfeits stats.\n\nAuto level if enabled automatically levels up or levels down all monsters to the max level. If leveled down, moves that are learned at a level higher than the max level are removed.\n\nThe max level rule determines the maximum level monsters can be.]"
guide_book.battles.page_9 = "textarea[0.5,1.25;9,7;;;Turn time is the amount of seconds players have for selecting moves.\n\nMax monsters is the maximum number of monsters each player can take into battle.\n\nMax tier is the highest tier that monsters can be. Tier 1 would allow any monster, including legendaries. Tier 5 would only allow the weakest monsters. Tiers are listed in the monster journal or monster stats chat command.\n\nAny monster that does not meet all the rules is excluded from battle.]"
guide_book.battles.page_10 = "textarea[0.5,1.25;9,7;;;Unlike wild battles and NPC battles, PVP battles automatically heal all monsters before battle and do not save changes to stats after the battle. This means you need to be careful about the order of your monsters in your party. Any monster with no health in your party that meets all of the battle rules will be fully healed and in the battle.]"
guide_book.battles.page_11 = "textarea[0.5,1.25;9,7;;;After the joining player accepts the rules, the battle will attempt to start. Both players will need to have at least one monster that meets all of the battle rules and must be within 25 nodes of each other. If either of these conditions are not met, the joining player will be notified via the status about what needs to be resolved.]"
guide_book.battles.page_12 = "textarea[0.5,1.25;9,7;;;When all conditions are met, the battle will begin. The battle interface is exactly the same except for the turn timer HUD at the top of the screen. The turn time will count down in increments of 5 seconds. When it reaches 0, the game will automatically select 'skip' for the player. If you leave a battle that does not have casual enabled, it will count as a forfeit for you! Avoid doing this when possible.]"

-- Training
guide_book.training = {}
guide_book.training.pages = 10
guide_book.training.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "training", "Training")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.training.page_1 = "textarea[0.5,1.25;9,7;;;This section will cover leveling up, learning new moves, monster stats, and damage calculation."
guide_book.training.page_2 = "textarea[0.5,1.25;9,7;;;To level up, monsters will need to earn EXP (experience). EXP is earned after defeating a monster. Only wild battles and trainer battles give EXP. PVP battles do not give EXP.\n\nThe monster that defeats the opposing monster earns all of the EXP. If a monster only weakens the opposing monster but doesn't defeat it, it won't earn EXP."
guide_book.training.page_3 = "textarea[0.5,1.25;9,7;;;Every monster has an EXP per level value. Monsters that are the same, such as two Chickadees, will always have the same value. This value ranges from 75 to 125.\n\nMonsters with a higher value require more EXP to level up and give out more EXP when defeated. This means some monsters require more training than others to level up. It also means some monsters are better to train against than others."
guide_book.training.page_4 = "textarea[0.5,1.25;9,7;;;Understanding exactly how EXP is earned is not necessary to have fun playing Zoonami. However, for those who do want to know, the formulas are below. Both are rounded down to the nearest whole number.\n\nA Monster's Level:\n√(EXP Total / EXP Per Level)\n\nEXP Earned:\nEnemy Level * Enemy EXP Per Level / 1.5"
guide_book.training.page_5 = "textarea[0.5,1.25;9,7;;;Leveling up is one of the ways a monster can learn new moves. Some moves can only be learned using special move books. To use a move book, right click while holding the book and choose a monster from the list. Only monsters in your party that can learn the move via a move book will appear in the list."
guide_book.training.page_6 = "textarea[0.5,1.25;9,7;;;Once a monster learns a new move, the move needs to be mapped to one of the monster's four move slots before it can be used. To remap moves, go to the monsters page in the backpack menu, find the monster, and click on one the blue move buttons. This will cycle through the monster's move pool for that move slot."
guide_book.training.page_7 = "textarea[0.5,1.25;9,7;;;Every monster has five main stats. There's health, energy, attack, defense, and agility.\n\nHealth, attack, defense, and agility have an initial value and a per level value. The initial value is what the stat would be if a monster was level 0. The per level value is then added to this initial value for each level. For example, a level 5 monster with an initial value of 10 and a per level value of 2 for the health stat would have 20 health."
guide_book.training.page_8 = "textarea[0.5,1.25;9,7;;;Monsters that are the same, such as two Chickadees, will always have the same initial and per level values. This means two Chickadees at the same level will have the same stats. However, monsters can have different personalities. These personalities boost stats by different amounts. One might boost attack by 10% while another boosts health and defense by 6%. Thus two Chickadees at the same level will only have the same stats if both have the same personality.\n\nTo learn more, the guide book has a \"Personalities\" section with more details."
guide_book.training.page_9 = "textarea[0.5,1.25;9,7;;;The energy stat works differently than other stats. Rather than having a per level value, monsters have a maximum energy cap. All monsters start with 2 energy and gain an additional 2 energy for every 10 levels until the monster reaches it's maximum energy cap. For example, a monster with a maximum energy cap of 5 will have 2 energy at levels 0 to 9, 4 energy at levels 10 to 19, and 5 energy at levels 20 to 100 as it has reached it's max value. Monsters that are the same, such as two Chickadees, will always have the same maximum energy cap."
guide_book.training.page_10 = "textarea[0.5,1.25;9,7;;;Now that you know how stats are determined, the last step is damage calculation. If an attacker's attack stat is equal to the defender's defense stat, the base damage will be 1/5 of the attack stat. The base damage is then multiplied by the move power, the move effectiveness, and the same type move bonus.\n\nDamage = Atk / (5 * √(Def / Atk))\n\nTotal Damage = Damage * Move Power * Effectiveness * Same Type Move Bonus"

-- Type Chart
guide_book.type_chart = {}
guide_book.type_chart.pages = 2
guide_book.type_chart.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "type_chart", "Type Chart")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.type_chart.page_1 = "textarea[0.5,1.25;9,7;;;Monsters and most monster moves have 13 different types. Each type has strengths and weaknesses against other types. For example, an aquatic move against a fire monster will do increased damage. Additionally, if the monster attacking uses a move that matches it's own type, such as an aquatic monster using an aquatic move, it will also do increased damage. The 13 types are plant, rodent, beast, warrior, insect, aquatic, robotic, reptile, avian, spirit, mutant, rock, and fire. The next page has a chart that shows all the strengths and weaknesses.]"
guide_book.type_chart.page_2 = fs.image(0.85, 0.5, 8, 8, "zoonami_type_chart.png")

-- Personalities
guide_book.personalities = {}
guide_book.personalities.pages = 2
guide_book.personalities.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "personalities", "Personalities")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.personalities.page_1 = "textarea[0.5,1.25;9,7;;;One factor that makes monsters a bit more unique are personalities. Personalities determine which stats are boosted and by how much.\n\nThere are 11 different personalities.]"
guide_book.personalities.page_2 = "textarea[0.5,1.25;9,7;;;Bulky: Health 10%\nFierce: Attack 10%\nSturdy: Defense 10%\nHasty: Agility 10%\n\nNoble: Health and Attack 6%\nRobost: Health and Defense 6%\nJoyful: Health and Agility 6%\nMighty: Attack and Defense 6%\nNimble: Attack and Agility 6%\nStealthy: Defense and Agility 6%\n\nBalanced: Health, Attack, Defense, and Agility 4%]"

-- Moves
guide_book.moves = {}
guide_book.moves.pages = 16
guide_book.moves.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "moves", "Moves")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.moves.page_1 = "textarea[0.5,1.25;9,7;;;Moves are defined by attributes such as attack, shield, and heal. There are 14 different attributes, but most moves will only have a few of these.]"
guide_book.moves.page_2 = "textarea[0.5,1.25;9,7;;;The attack, counter, range, and static attributes all have one thing common. They deal damage to the opponent.\n\nAttack is the most common form of dealing damage. The attack percentage is one of many factors that determine how much of the user's attack stat is dealt as damage.]"
guide_book.moves.page_3 = "textarea[0.5,1.25;9,7;;;The counter attribute is similar to the attack attribute except it has a minimum and maximum amount of damage. The amount of damage is determined by the user's remaining health. The minimum damage is dealt at full health and the maximum damage is dealt at zero health. \n\nExample: An attacker with 25% health remaining using a move with a min 100% to max 120% would deal 115% damage."
guide_book.moves.page_4 = "textarea[0.5,1.25;9,7;;;The range attribute is nearly identical to the counter attribute. It has a minimum and maximum amount of damage. However, the damage dealt is randomly chosen between the two values. \n\nExample: A move with a min 100% to max 120% could deal any amount between those two values, such as 105%, 120%, or 112%, each time the move is used."
guide_book.moves.page_5 = "textarea[0.5,1.25;9,7;;;The static attribute is unique in that it always deals a set amount of damage. The percentage is the amount of the opponent's max health that will be dealt as damage. The damage is rounded up to the nearest integer. \n\nExample: A static move with a value of 20% against an enemy with 100 max health will always deal 20 damage.]"
guide_book.moves.page_6 = "textarea[0.5,1.25;9,7;;;The type attribute determines the strengths and weaknesses against monsters when dealing damage. \n\nTo learn more about move types, the guide book has a \"Type Chart\" section with more details.]"
guide_book.moves.page_7 = "textarea[0.5,1.25;9,7;;;The shield attribute is a percentage that reduces the amount of damage taken from an opponent's attack during that turn. However, the shield move must be used before the opponent's attack or it won't reduce any damage. \n\nExample: A shield with a value of 90% would reduce the opponent's damage by 90% if used before the opponent attacked that turn."
guide_book.moves.page_8 = "textarea[0.5,1.25;9,7;;;The resistance attribute is the same as the shield attribute, but it only reduces damage depending on the type attribute of the opponent's move. Like shields, resistance moves must be used before the opponents attack or it won't reduce any damage. \n\nExample: A 20% fire resistance would reduce the opponent's damage by 20% if used before the opponent attacked that turn and if the opponent's move was a fire type move."
guide_book.moves.page_9 = "textarea[0.5,1.25;9,7;;;The heal attribute is a percentage of the user's max health that will be restored when the move is used. \n\nExample: If the user's max health was 100, a 5% heal move would restore 5 health."
guide_book.moves.page_10 = "textarea[0.5,1.25;9,7;;;The recover attribute is the amount of energy the user will restore when used. This amount is in addition to the 2 energy that is always restored at the end of each turn."
guide_book.moves.page_11 = "textarea[0.5,1.25;9,7;;;The energy attribute is the amount of energy it costs to use the move. If a move costs 0 energy, the energy attribute won't be displayed on the move tooltip."
guide_book.moves.page_12 = "textarea[0.5,1.25;9,7;;;The cooldown attribute is the amount of turns that must pass before the move can be used again. A monster must be in battle at the end of the turn for the cooldown to recharge."
guide_book.moves.page_13 = "textarea[0.5,1.25;9,7;;;The quantity attribute is the amount of times that a move can be used during a battle. This resets each time a player enters a new battle."
guide_book.moves.page_14 = "textarea[0.5,1.25;9,7;;;The counteract attribute increases or decreases damage depending on the stats of the user and opponent. The stat specified can be health, attack, defense, or agility. If the user's stat is lower than opponent's stat, damage is increased and vice versa. This increase/decrease depends on how much of a difference there is between the two monster stats."
guide_book.moves.page_15 = "textarea[0.5,1.25;9,7;;;The priority attribute is used when determining which monster attacks first.\n\nWhen monsters attack, the first value checked is the move priority. The move with the highest priority always goes first. If both moves have the same priority, the monster with the highest agility goes first. If both monsters have the same agility, one of the monsters is randomly selected to go first.]"
guide_book.moves.page_16 = "textarea[0.5,1.25;9,7;;;Most moves have a neutral priority of 0. This includes switching monsters and using items. This means a monster with a higher agility has a better chance of switching out or using an item before the opponent's move. Some moves have a priority of -1 and 1. A move with a -1 priority will usually go last and a move with a 1 priority will usually go first.]"

-- Journals
guide_book.journals = {}
guide_book.journals.pages = 4
guide_book.journals.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "journals", "Journals")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.journals.page_1 = "textarea[0.5,1.25;9,7;;;The amount of monsters and moves in Zoonami can be overwhelming. To help keep track of all of this, players have access to a Zoonami Monster Journal and a Zoonami Move Journal.]"
guide_book.journals.page_2 = "textarea[0.5,1.25;9,7;;;The Zoonami Guide Book, Zoonami Monster Journal, and the Zoonami Move Journal share a crafting loop. Place one of these books in a crafting grid to craft a different book. Repeat this process until you have the book you want.\n\nThis means players have access to all three books while only taking up one inventory slot.]"
guide_book.journals.page_3 = "textarea[0.5,1.25;9,7;;;By default, the monster journal will only show monsters that the player has tamed or traded for. However, this progression mode can be turned off in the mod settings. The move journal does not have a progression mode.]"
guide_book.journals.page_4 = "textarea[0.5,1.25;9,7;;;The journals have two arrow buttons for changing pages and a search bar in between the two arrow buttons. Type the full name of a move or monster in the search bar, press the enter key, and it will bring you directly to that page.]"

-- Computer
guide_book.computer = {}
guide_book.computer.pages = 7
guide_book.computer.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "computer", "Computer")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.computer.page_1 = "textarea[0.5,1.25;9,7;;;Each player has their own storage system for storing extra monsters. This storage is accessed by right clicking on a Zoonami Computer. Be very careful! A computer drops no items when broken. Choose wisely before placing a computer down. If it's necessary to remove a computer, it can only be broken with a mid-tier or higher pickaxe.]"
guide_book.computer.page_2 = "textarea[0.5,1.25;9,7;;;The computer storage consists of 25 folders with 10 boxes in each folder. Each box can store 25 monsters. This means a total of 6,250 monsters can be stored.]"
guide_book.computer.page_3 = "textarea[0.5,1.25;9,7;;;The home page displays all 25 folders. Click on a folder to access the boxes that are in it.\n\nThe box page consists of a folder icon to let you know what folder you are in and arrow buttons to change boxes.\n\nMonsters in your party are always shown on the left sidebar.]"
guide_book.computer.page_4 = "textarea[0.5,1.25;9,7;;;To move a monster, click on a monster or empty space to highlight it. Click on a different monster or empty space and the two spaces will be swapped. If you would like to move an entire box, click on the button that shows the box number (in between the two arrow buttons). This highlights the entire box. Click on a different box button and the two boxes will be swapped.]"
guide_book.computer.page_5 = "textarea[0.5,1.25;9,7;;;Notice that the small button in the upper right corner changes its tooltip and color depending on if something is highlighted. Clicking this button will deselect all highlighted spaces. This is very useful to prevent accidentally swapping a monster.]"
guide_book.computer.page_6 = "textarea[0.5,1.25;9,7;;;To view more info about a monster, click on it once to highlight it and then click on it again. This will show the stats page.\n\nIn addition to showing the monster stats, this page also has a delete button to delete a monster. To ensure a player always has access to at least one monster, starter monsters can't be deleted.]"
guide_book.computer.page_7 = "textarea[0.5,1.25;9,7;;;When a player tames a monster and their party is full, the monster is placed in folder 1 box 1. If this box also fills up, no monsters can be tamed. Thus, it's best to not use folder 1 box 1 for long term monster storage.]"

-- Trading Machine
guide_book.trading_machine = {}
guide_book.trading_machine.pages = 5
guide_book.trading_machine.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "trading_machine", "Trading Machine")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.trading_machine.page_1 = "textarea[0.5,1.25;9,7;;;For many, trying to tame every monster in Zoonami is common goal. However, some monsters might be too hard to find or you might have duplicates. If you are playing with other players, this is where trading comes in.]"
guide_book.trading_machine.page_2 = "textarea[0.5,1.25;9,7;;;A trading machine allows trading monsters with other players. Unlike most other Zoonami machines, the trading machine can be picked up after being placed as long as no one is using it.\n\nTo begin, both players will need to right click on the same trading machine.]"
guide_book.trading_machine.page_3 = "textarea[0.5,1.25;9,7;;;The trading interface consists of two sides. Players will always see themselves on the left side. The person they are trading with will always appear on the right side.\n\nPlayers will see a list of monsters in their party. When a player selects a monster, both players can see the stats of the monster. If you want to change the monster you selected, click the cancel button.]"
guide_book.trading_machine.page_4 = "textarea[0.5,1.25;9,7;;;After both players have selected a monster, the trade button is now active. When one player clicks the trade button, both players can see that the player's status says ready.\n\nOnce the second player clicks trade, the trade will immediately take place and the interface will close. If either player clicks cancel, the ready status is removed.]"
guide_book.trading_machine.page_5 = "textarea[0.5,1.25;9,7;;;One thing to note with trading is that starter monsters can't be traded. If you try to select a starter monster, you will instead see a message that says it can't be traded.\n\nThat's everything you need to know to get started with trading. Trading can be a great way for players to work together. Just make sure to double check both monsters are correct before clicking the trade button.]"

-- Zoonami Coins
guide_book.zoonami_coins = {}
guide_book.zoonami_coins.pages = 4
guide_book.zoonami_coins.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "zoonami_coins", "Zoonami Coins")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.zoonami_coins.page_1 = "textarea[0.5,1.25;9,7;;;Zoonami coins, often referred to as ZC, is a form of in-game currency. Each player can view how many ZC they have on the player stats page in the backpack menu.]"
guide_book.zoonami_coins.page_2 = "textarea[0.5,1.25;9,7;;;ZC can be obtained by battling wild monsters, battling trainers, selling items, or direct transfers. Vending machines allow players to sell items to other players for ZC. Players can also directly transfer ZC to another player using a chat command.\n\nTo learn more, the guide book has a \"Vending Machine\" section and \"Chat Command\" section with more details.]"
guide_book.zoonami_coins.page_3 = "textarea[0.5,1.25;9,7;;;ZC can also be withdrawn from your bank using a chat command. Withdrawn ZC will be added as an item to your inventory.\n\nCoins come in four denominations of 1, 10, 100, and 1000. Right clicking while holding a stack of coins will deposit the stack into your bank. These coins can be useful for compatibility with other trading and currency mods, gifting ZC to an offline player, event prizes, adventure maps, etc."
guide_book.zoonami_coins.page_4 = "textarea[0.5,1.25;9,7;;;Withdrawn ZC can be crafted into lower denominations. However, due to the coins being base 10 and most crafting grids only having 9 slots, crafting higher denomination coins is not possible. Instead, deposit the coins into your bank and withdraw them to get higher denomination coins."

-- Vending Machines
guide_book.vending_machines = {}
guide_book.vending_machines.pages = 2
guide_book.vending_machines.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "vending_machines", "Vending Machines")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.vending_machines.page_1 = "textarea[0.5,1.25;9,7;;;Vending machines allow players to buy and sell items for ZC. There are two types of vending machines.\n\nThe first type is just called \"Vending Machine\" and it's a craftable item. This vending machine allows players to sell up to three items to other players. To set the prices, type the price in and press the enter key. Any item priced at 0 will not be available for other players to purchase. Prices are for inidividual items and not the entire stack of items.]"
guide_book.vending_machines.page_2 = "textarea[0.5,1.25;9,7;;;The second type of vending machine is an \"Automatic Vending Machine.\" These vending machines are not craftable. They can only be found in naturally generated villages in shops. They drop no items when broken and can't be moved.\n\nUnlike player vending machines, there's only one item slot. The item, quantity, and price changes every Minetest day at midnight.]"

-- NPCs
guide_book.npcs = {}
guide_book.npcs.pages = 5
guide_book.npcs.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "npcs", "NPCs")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.npcs.page_1 = "textarea[0.5,1.25;9,7;;;There many different types of NPCs. Some are only interested in chatting while some are only interested in battling. Most NPCs will be found roaming around villages, but some can be found out in the wild.]"
guide_book.npcs.page_2 = "textarea[0.5,1.25;9,7;;;Chatterbox NPCs only care about talking. They occasionally change messages depending on the time of day in Minetest. The messages can range from useful advice to random dialogue.]"
guide_book.npcs.page_3 = "textarea[0.5,1.25;9,7;;;Trainer NPCs are only interested in battling. All trainers carry a Zoonami Backpack on their back making them easy to spot. Trainer difficulty is represented by a five star system. More gold stars means the trainer will usually have more monsters and the average level will be higher. New players will generally need two or three monsters around level 10 to win against a one star trainer.]"
guide_book.npcs.page_4 = "textarea[0.5,1.25;9,7;;;Merchant NPCs only sell items. Each merchant only has one item slot. Unlike automatic vending machines, merchants will not restock after selling all of their items. They will instead despawn. Merchants will usually have items that automatic vending machines don't sell.]"
guide_book.npcs.page_5 = "textarea[0.5,1.25;9,7;;;Infobox NPCs are a special NPC for creative mode players. They function similarly to chatterbox NPCs except the messages can be configured by creative mode players. They are also immune to damage and do not walk around.]"

-- Villages
guide_book.villages = {}
guide_book.villages.pages = 4
guide_book.villages.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "villages", "Villages")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.villages.page_1 = "textarea[0.5,1.25;9,7;;;Villages can be naturally generated or created by players. Naturally generated villages will usually have a few houses and a few shops. Each shop will always have an automatic vending machine and will sometimes have a healer.]"
guide_book.villages.page_2 = "textarea[0.5,1.25;9,7;;;To create your own village, you will need to craft an NPC Wood Chair to attract NPCs. However, you can't just place this chair anywhere. The node above a chair needs to have a natural light level between 1 and 13 and an artificial light level of 3 or higher.\n\nIn other words, the chair needs indirect sunlight via a roof above it, and a torch or other light emitting node nearby.]"
guide_book.villages.page_3 = "textarea[0.5,1.25;9,7;;;Right clicking on a chair will let you know if it's active or inactive. An active chair will attract NPCs and an inactive chair will not. An active chair will periodically check if the conditions are still being met.\n\nIn order to make an inactive chair active again, you'll need to break it and place it in a spot that meets the light level conditions.]"
guide_book.villages.page_4 = "textarea[0.5,1.25;9,7;;;Once you have a village made, you can help NPCs stay near areas of interest by using Gravel Path, Dirt Path, Plank Floor, or Cube Floor nodes. When NPCs see these nodes nearby, they will stay near them.]"

-- Prisma Monsters
guide_book.prisma_monsters = {}
guide_book.prisma_monsters.pages = 3
guide_book.prisma_monsters.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "prisma_monsters", "Prisma Monsters")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.prisma_monsters.page_1 = "textarea[0.5,1.25;9,7;;;Each time a wild monster spawns, there is a small chance that it will be a prisma monster. Prisma monsters are the exact same as normal monsters except the colors are different. Despite not having any advantages, prisma monsters are usually highly sought after due to their rarity.]"
guide_book.prisma_monsters.page_2 = "textarea[0.5,1.25;9,7;;;To aid with identifying prisma monsters, players can craft a Prism. Left click on a wild monster while holding the Prism and it will tell you if the monster is normal or a prisma.]"
guide_book.prisma_monsters.page_3 = "textarea[0.5,1.25;9,7;;;The Prism also has a second use for creative mode players. While holding a Prism in your inventory, any monsters spawned with spawn eggs will be prisma monsters.]"

-- Chat Commands
guide_book.chat_commands = {}
guide_book.chat_commands.pages = 4
guide_book.chat_commands.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "chat_commands", "Chat Commands")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.chat_commands.page_1 = "textarea[0.5,1.25;9,7;;;Shows detailed monster stats of a monster in your party. The number corresponds to the slot number.\n\nSyntax:\n/monster-stats (1-5)\n\nExample:\n/monster-stats 1]"
guide_book.chat_commands.page_2 = "textarea[0.5,1.25;9,7;;;View PVP stats of another player.\n\nSyntax:\n/pvp-stats (player name)\n\nExample:\n/pvp-stats playername]"
guide_book.chat_commands.page_3 = "textarea[0.5,1.25;9,7;;;Transfers Zoonami Coins (ZC) to another player.\n\nSyntax:\n/transfer-zc (player name) (amount of ZC)\n\nExample:\n/transfer-zc playername 100]"
guide_book.chat_commands.page_4 = "textarea[0.5,1.25;9,7;;;Withdraws Zoonami Coins (ZC) from your bank. Withdrawn coins are added as items to your inventory.\n\nSyntax:\n/withdraw-zc (amount of ZC)\n\nExample:\n/withdraw-zc 100]"

-- Creative
guide_book.creative = {}
guide_book.creative.pages = 3
guide_book.creative.navigation = fs.image_button(0, 0.5, 10, 0.5, "zoonami_blank", "creative", "Creative")..
	fs.box(0, 0.5, 10, 0.5, "#00000000")..
	fs.button(1, 9.2, 0.8, 0.8, "back", "◄")..
	fs.button(4, 9.2, 2, 0.8, "index", "Index")..
	fs.button(8.2, 9.2, 0.8, 0.8, "next", "►")
guide_book.creative.page_1 = "textarea[0.5,1.25;9,7;;;Some features of Zoonami are only available in creative mode. These features are meant for server owners and adventure map creators to control different aspects of Zoonami, such as monster spawning and NPCs.]"
guide_book.creative.page_2 = "textarea[0.5,1.25;9,7;;;The Zoonami Monster Spawner is a node that can be configured to spawn monsters nearby. Players with creative mode can right click on the spawner to access the configuration formspec.\n\nThe width and height determine the area around the spawner that monsters can spawn. The width applies to all 4 adjacent sides. The height applies to the top and bottom. Thus a width of 2 and height of 5 would equal a 5x5x11 area with the spawner being in the center.]"
guide_book.creative.page_3 = "textarea[0.5,1.25;9,7;;;The interval is the amount of seconds between spawn attempts. Lower numbers mean more monster spawns.\n\nLastly, up to 7 monsters can be defined to spawn from a single spawner. Rarity helps control how often a monster will spawn per spawn attempt. However, other factors such as what node(s) it spawns on and how many are nearby also play a factor. The min level and max level determine the level range that the monster will be when a player battles it.]"
