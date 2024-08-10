-- Defines all stats for NPCs

-- Local namespace
local npc_stats = {}

-- NPC namespace
npc_stats.npc = {}

-- Import files
local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

local fs = dofile(mod_path .. "/lua/formspec.lua")
local group = dofile(mod_path .. "/lua/group.lua")
local monsters = dofile(mod_path .. "/lua/monsters.lua")

-- NPC stops and turns toward player
function npc_stats.look_at_player(self, player)
	local radians = player:get_look_horizontal()
	radians = (radians + math.pi) % (2 * math.pi)
	self.object:set_yaw(radians)
	self.object:set_velocity(vector.new())
	self:_set_movement_state("stop", "stand")
end

-- NPC only moves after player is more than 5 blocks away
function npc_stats.talking(self)
	local npc_pos = self.object:get_pos()
	local player_name = self._talking_to or ""
	local player = minetest.get_player_by_name(player_name)
	if npc_pos and player then
		local player_pos = player:get_pos()
		local x_distance = math.abs(npc_pos.x - player_pos.x)
		local y_distance = math.abs(npc_pos.y - player_pos.y)
		local z_distance = math.abs(npc_pos.z - player_pos.z)
		if x_distance <= 5 and y_distance <= 5 and z_distance <= 5 then
			minetest.after(4, npc_stats.talking, self)
		else
			self.object:set_velocity(vector.new())
			self:_set_movement_state("stand")
			self._talking_to = nil
		end
	end
end

-- Chatterbox NPC Message Pools
npc_stats.chat_morning = {
	"If a monster is low on energy, skipping a turn can recover energy.",
	"Note to self: Don't leave orange jelly out on the table. Rodent monsters will find it!",
	"Someone said they found some weird monsters in a cave, but I'm too afraid of the dark.",
	"Like my Grandpa always said, the early bird gets the worm.",
	"Don't mind me. I'm just doing some morning stretches.",
	"Today is going to be a good day. I can feel it.",
	"I should stock up on supplies before going on an adventure.",
	"The morning dew is making my feet wet.",
	"I'm rested and ready for a brand new day."
}

npc_stats.chat_day = {
	"If you want to use an item during battle, you have to move it to the item slots in your backpack.",
	"Some villages have shops with vending machines. The machines restock every day at midnight.",
	"Avian monsters are my favorite. That's why I always carry blue jelly with me wherever I go.",
	"The warm sun fills me with energy, but it also wears me out. Funny how that works.",
	"I like spending time at the beach, but watch out for Scallapods.",
	"Flowers not only make your garden beautiful, they can also attract special monsters.",
	"Cold water tastes best on a hot day.",
	"Have you found any interesting monsters lately?"
}

npc_stats.chat_evening = {
	"The secret to being a morning person is to go to bed early.",
	"Battling trainers can be tough, but the rewards can be great if you win.",
	"I heard a rumor that there's a special gold jelly that no monster can resist.",
	"A healer can't be picked up after being placed. Doing so will only break it. Choose wisely before placing.",
	"There are 13 different monster types. Some are harder to find than others.",
	"The sunset looks beautiful.",
	"*Yawn* The crickets are starting to sing me to sleep.",
	"What should I have for dinner?"
}

npc_stats.chat_night = {
	"Did you know you can combine four jars of jelly to make higher quality jelly?",
	"Automatic vending machines restock with different items each day. It's a good idea to check them often.",
	"Sometimes shops will have a healer that people can use for free. It helps attract more customers.",
	"I love seeing all of the Firefli come out at night.",
	"I think I heard a Howler off in the distance.",
	"The stars sure are bright. How many do you think there are?",
	"The cool crisp air is refreshing."
}

-- Chatterbox
npc_stats.npc.chatterbox = {
	name = "Chatterbox",
	asset_name = "chatterbox",
	texture_list = {{"zoonami_npc_chatterbox_1.png"}, {"zoonami_npc_chatterbox_2.png"}, {"zoonami_npc_chatterbox_3.png"},},
	armor_groups = {fleshy = 100, choppy = 50},
	spawn_walk_velocity = 1.5,
	spawn_float = true,
	spawn_burn = true,
	stay_near = {"group:zoonami_path", "group:zoonami_floor"},
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then return end
		local player_name = clicker:get_player_name()
		if not self._talking_to then
			self._talking_to = player_name
			npc_stats.look_at_player(self, clicker)
			npc_stats.talking(self)
		end
		local assigned_messages = self._assigned_messages
		local previous_day = self._previous_day
		local current_day = minetest.get_day_count()
		if not assigned_messages or previous_day ~= current_day then
			assigned_messages = {
				morning_message = npc_stats.chat_morning[math.random(#npc_stats.chat_morning)],
				day_message = npc_stats.chat_day[math.random(#npc_stats.chat_day)],
				evening_message = npc_stats.chat_evening[math.random(#npc_stats.chat_evening)],
				night_message = npc_stats.chat_night[math.random(#npc_stats.chat_night)],
			}
			previous_day = current_day
			self._previous_day = current_day
			self._assigned_messages = assigned_messages
		end
		local current_time = minetest.get_timeofday()
		local message_type = nil
		if current_time >= 0.25 and current_time < 0.4 then
			message_type = "morning"
		elseif current_time >= 0.4 and current_time < 0.65 then
			message_type = "day"
		elseif current_time >= 0.65 and current_time < 0.8 then
			message_type = "evening"
		else
			message_type = "night"
		end
		local message = assigned_messages[message_type.."_message"]
		local formspec = fs.header(8, 4.5, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
		fs.background9(0.4, 0.4, 7.2, 3.7, "zoonami_button_4.png", "false", 8)..
		fs.font_style("textarea", "mono,bold", "*1.25", "#FFFFFF")..
		fs.textarea(0.5, 0.5, 7, 3.5, message)
		fsc.show(player_name, formspec, nil, function() end)
	end,
}

-- Trainer Monsters
function npc_stats.assign_monsters(self, average_player_level)
	local average_difficulty = math.min(math.max(math.floor((average_player_level / 10) + 0.5), 1), 5)
	local weighted_difficulty = math.random(1, 100) <= 40 and average_difficulty or math.random(1, 5)
	self._difficulty = weighted_difficulty
	local level = self._difficulty * 10
	local rarity = {common = 1, uncommon = 2, rare = 3, mythical = 99, legendary = 99}
	local number_of_monsters = math.random(math.ceil(self._difficulty / 2) + 2)
	local monster_pool = {}
	for k, v in pairs(monsters.stats) do
		if rarity[v.spawn_chance] <= self._difficulty then
			table.insert(monster_pool, v.asset_name)
		end
	end
	self._assigned_monsters = {}
	for i = 1, number_of_monsters do
		local chosen_monster = monster_pool[math.random(#monster_pool)]
		local monster_level = math.ceil(math.random(level - 5, level + 5))
		local presets = {taught_moves = true}
		local generated_monster = monsters.generate(chosen_monster, monster_level, presets)
		self._assigned_monsters["monster#"..i] = generated_monster
	end
end

-- Trainer Formspec
function npc_stats.trainer_formspec(clicker, fields, self)
	fields = fields or {}
	if fields.quit or not clicker or not clicker:is_player() then
		return true
	end
	local player_name = clicker:get_player_name()
	if not self._talking_to then
		self._talking_to = player_name
		npc_stats.look_at_player(self, clicker)
		npc_stats.talking(self)
	end
	-- Check if clicker has any Zoonami monsters and if any have more than 0 health before starting battle
	local meta = clicker:get_meta()
	local player_monsters = {}
	local able_to_battle = false
	local no_monsters = true
	local average_player_level = 0
	local zoonami_chose_starter = meta:get_string("zoonami_chose_starter")
	for i = 1, 5 do
		local monster = meta:get_string("zoonami_monster_"..i)
		monster = minetest.deserialize(monster)
		if monster then
			no_monsters = false
			player_monsters["monster#"..i] = monster
			average_player_level = average_player_level == 0 and monster.level or (average_player_level + monster.level) / 2
			if monster.health > 0 then
				able_to_battle = true
			end
		end
	end
	if not self._assigned_monsters then
		npc_stats.assign_monsters(self, average_player_level)
	end
	-- Heal NPC monsters
	for i = 1, 5 do
		local monster = self._assigned_monsters["monster#"..i]
		monster = monster and monsters.load_stats(monster)
		if monster then
			monster.health = monster.max_health
			monster.energy = monster.max_energy
		end
	end
	local message = ""
	if self._previous_day ~= minetest.get_day_count() and able_to_battle and fields.battle then
			self._previous_day = minetest.get_day_count()
			zoonami.start_battle(player_name, player_monsters, self._assigned_monsters, "trainer")
			return
	elseif self._previous_day ~= minetest.get_day_count() and able_to_battle then
		message = "Want to battle?"
	elseif able_to_battle then
		message = "My monsters need to rest. Ask again later."
	elseif zoonami_chose_starter ~= "true" then
		message = "You need to choose a starter monster before battling."
	elseif no_monsters then
		message = "You can't battle with no monsters."
	elseif not able_to_battle then
		message = "Your monsters look too tired to battle."
	end
	local stars = ""
	for i = 1, 5 do
		local color = self._difficulty >= i and "yellow" or "gray"
		stars = stars..fs.image(0.5+i, 2.5, 1, 1, "zoonami_star_"..color..".png")
	end
	local formspec = fs.header(8, 4.5, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
		fs.background9(0.4, 0.4, 7.2, 2.2, "zoonami_button_4.png", "false", 8)..
		fs.font_style("textarea", "mono,bold", "*1.25", "#FFFFFF")..
		fs.font_style("button", "mono,bold", "*1", "#000000")..
		fs.button_style(1, 8)..
		fs.textarea(0.5, 0.5, 7, 2, message)..
		stars..
		fs.button(2, 3.7, 4, 0.6, "battle", "Battle")
		
	fsc.show(player_name, formspec, self, npc_stats.trainer_formspec)
end

-- Trainer
npc_stats.npc.trainer = {
	name = "Trainer",
	asset_name = "trainer",
	texture_list = {{"zoonami_npc_trainer_1.png"}, {"zoonami_npc_trainer_2.png"}, {"zoonami_npc_trainer_3.png"}, {"zoonami_npc_trainer_4.png"},},
	armor_groups = {fleshy = 100, choppy = 50},
	spawn_on = {group.choppy, group.cracky, group.crumbly, group.grass},
	spawn_chance = "rare",
	spawn_time = {"day"},
	spawn_light = {"bright", "medium", "dark"},
	spawn_height = {"aboveground"},
	spawn_walk_velocity = 1.5,
	spawn_float = true,
	spawn_burn = true,
	stay_near = {"group:zoonami_path", "group:zoonami_floor"},
	on_rightclick = function(self, clicker)
		npc_stats.trainer_formspec(clicker, nil, self)
	end,
}

-- Merchant Formspec
function npc_stats.merchant_formspec(clicker, fields, self)
	fields = fields or {}
	if fields.quit or not clicker or not clicker:is_player() then
		return true
	end
	
	local player_meta = clicker:get_meta()
	local player_name = clicker:get_player_name() or ""
	local player_inv = clicker:get_inventory()
	local player_zc = player_meta:get_int("zoonami_coins")
	
	if not self._talking_to then
		self._talking_to = player_name
		npc_stats.look_at_player(self, clicker)
		npc_stats.talking(self)
	end
	
	if not self._assigned_items then
		local item_pool = {}
		item_pool[1] = {name = modname .. ":zoonami_cloth", count = math.random(10, 20), price = math.random(3, 6)}
		item_pool[2] = {name = modname .. ":zoonami_paper", count = math.random(10, 20), price = math.random(3, 6)}
		item_pool[3] = {name = modname .. ":zoonami_sanded_plank", count = math.random(10, 20), price = math.random(3, 6)}
		item_pool[4] = {name = modname .. ":zoonami_crystal_glass", count = math.random(10, 15), price = math.random(5, 8)}
		item_pool[5] = {name = modname .. ":zoonami_zeenite_ingot", count = math.random(3, 7), price = math.random(15, 25)}
		item_pool[6] = {name = modname .. ":zoonami_simple_berry_juice", count = math.random(15, 20), price = math.random(28, 38)}
		item_pool[7] = {name = modname .. ":zoonami_super_berry_juice", count = math.random(10, 15), price = math.random(95, 105)}
		item_pool[8] = {name = modname .. ":zoonami_mystery_move_book", count = math.random(3, 6), price = math.random(190, 205)}
		local new_item = item_pool[math.random(#item_pool)]
		self._assigned_items = {{name = new_item.name, count = new_item.count, price = new_item.price}}
	end
	
	local stack_1 = self._assigned_items[1]
	
	if fields and fields.buy_stack_1 then
		if stack_1.count > 0 and player_zc >= stack_1.price then
			player_zc = player_zc - stack_1.price
			player_meta:set_int("zoonami_coins", player_zc)
			stack_1.count = stack_1.count - 1
			self._life_timer = stack_1.count > 0 and self._life_timer or 0
			minetest.sound_play("zoonami_vending_machine", {to_player = player_name, gain = 0.9}, true)
			local items = ItemStack(stack_1.name)
			minetest.after(0, function()
				local leftover = player_inv:add_item("main", items)
				if leftover:get_count() > 0 then
					minetest.add_item(clicker:get_pos(), leftover)
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
		fs.item_image_button(3, 1, 1, 1, stack_1.name, "image")..
		fs.image_button(0, 2, 7, 1, "zoonami_blank", "label", "Stock: "..stack_1.count)..
		fs.box(0, 2, 7, 1, "#00000000")..
		fs.image_button(0, 2.5, 7, 1, "zoonami_blank", "label", stack_1.price.." ZC")..
		fs.box(0, 2.5, 7, 1, "#00000000")..
		fs.button(2.9, 3.5, 1.2, 0.7, "buy_stack_1", "Buy")
		
	fsc.show(player_name, formspec, self, npc_stats.merchant_formspec)
end

-- Merchant
npc_stats.npc.merchant = {
	name = "Merchant",
	asset_name = "merchant",
	texture_list = {{"zoonami_npc_merchant_1.png"}, {"zoonami_npc_merchant_2.png"}},
	armor_groups = {fleshy = 100, choppy = 50},
	spawn_walk_velocity = 1.5,
	spawn_float = true,
	spawn_burn = true,
	stay_near = {"group:zoonami_path", "group:zoonami_floor"},
	on_rightclick = function(self, clicker)
		npc_stats.merchant_formspec(clicker, nil, self)
	end,
}

-- Infobox Formspec
function npc_stats.infobox_formspec(clicker, fields, context)
	fields = fields or {}
	if fields.quit or not clicker or not clicker:is_player() then
		return true
	end
	local player_name = clicker:get_player_name()
	local self = context.self
	self._assigned_messages = self._assigned_messages or {}
	if not self._talking_to then
		self._talking_to = player_name
		npc_stats.look_at_player(self, clicker)
		npc_stats.talking(self)
	end
	if minetest.is_creative_enabled(player_name) then
		if fields.delete_npc then
			self.object:remove()
			return true
		end
		context.current_message = context.current_message or math.random(#self._assigned_messages)
		if fields.new_message and fields.new_message ~= "" then
			table.insert(self._assigned_messages, minetest.formspec_escape(fields.new_message))
			context.current_message = #self._assigned_messages
		elseif fields.clear_message then
			table.remove(self._assigned_messages, context.current_message)
			context.current_message = math.min(context.current_message, #self._assigned_messages)
		end
		if fields.next then
			context.current_message = context.current_message + 1
		elseif fields.back then
			context.current_message = context.current_message - 1
		end
		if #self._assigned_messages == 0 then
			context.current_message = 0
		elseif context.current_message > #self._assigned_messages then
			context.current_message = 1
		elseif context.current_message < 1 then
			context.current_message = #self._assigned_messages
		end
		local message = self._assigned_messages and self._assigned_messages[context.current_message] or ""
		local formspec = fs.header(8, 6, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
		fs.background9(0.4, 0.4, 7.2, 3.7, "zoonami_button_4.png", "false", 8)..
		fs.font_style("textarea", "mono,bold", "*1.25", "#FFFFFF")..
		fs.font_style("button", "mono,bold", "*1", "#000000")..
		fs.textarea(0.5, 0.5, 7, 3.5, message)..
		fs.button_style(1, 8)..
		fs.button(7.4, 0, 0.6, 0.6, "delete_npc", "X")..
		fs.tooltip("delete_npc", "Delete NPC", "#ffffff", "#000000")..
		fs.image_button(0, 3.9, 8, 0.5, "zoonami_blank", "", "Message "..context.current_message.." of "..#self._assigned_messages)..
		fs.field(0.5, 4.4, 7, 0.6, "new_message", "", "")..
		"field_close_on_enter[new_message;false]"..
		fs.button(0.5, 5.1, 0.8, 0.8, "back", "◄")..
		fs.button(2, 5.1, 4, 0.8, "clear_message", "Clear Message")..
		fs.button(6.7, 5.1, 0.8, 0.8, "next", "►")
		fsc.show(player_name, formspec, context, npc_stats.infobox_formspec)
	else
		local message = self._assigned_messages[math.random(#self._assigned_messages)] or ""
		local formspec = fs.header(8, 4.5, "false", "#00000000")..
		fs.background9(0, 0, 1, 1, "zoonami_gray_background.png", "true", 88)..
		fs.background9(0.4, 0.4, 7.2, 3.7, "zoonami_button_4.png", "false", 8)..
		fs.font_style("textarea", "mono,bold", "*1.25", "#FFFFFF")..
		fs.textarea(0.5, 0.5, 7, 3.5, message)
		fsc.show(player_name, formspec, context, npc_stats.infobox_formspec)
	end
end

-- Infobox
npc_stats.npc.infobox = {
	name = "Infobox",
	asset_name = "infobox",
	texture_list = {{"zoonami_npc_chatterbox_1.png"}, {"zoonami_npc_chatterbox_2.png"}, {"zoonami_npc_chatterbox_3.png"},},
	armor_groups = {},
	spawn_walk_velocity = 0,
	spawn_float = true,
	spawn_burn = false,
	stay_near = {"group:zoonami_path", "group:zoonami_floor"},
	prevent_despawn = true,
	on_rightclick = function(self, clicker)
		local context = {self = self}
		npc_stats.infobox_formspec(clicker, nil, context)
	end,
}

return npc_stats
