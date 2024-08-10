local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

-- Handles giving players joining initial items and metadata values for Zoonami

minetest.register_on_newplayer(function(player)
	local inv = player:get_inventory()
	local meta = player:get_meta()
	inv:add_item("main", modname .. ":zoonami_guide_book")
	inv:add_item("main", modname .. ":zoonami_backpack")
	meta:set_int("zoonami_coins", 0)
	meta:set_float("zoonami_battle_music_volume", 1)
	meta:set_float("zoonami_battle_sfx_volume", 1)
    meta:set_string("zoonami_chose_starter", "false")
    meta:set_string("zoonami_introduction_items", "false")
end)

minetest.register_on_joinplayer(function(player)
	local inv = player:get_inventory()
	local meta = player:get_meta()
	inv:set_size("zoonami_backpack_items", 12)
	meta:set_string("zoonami_music_handler", "false")
	meta:set_string("zoonami_battle_session_id", "0")
	meta:set_string("zoonami_trade_session_id", "")
	meta:set_string("zoonami_pvp_id", "")
	meta:set_string("zoonami_battle_pvp_enemy", "")
	meta:set_string("zoonami_host_battle", "")
	meta:set_string("zoonami_join_battle", "")
	meta:set_string("zoonami_backpack_page", "monsters")
	if meta:get_float("zoonami_backpack_gui_zoom") == 0 then 
		meta:set_float("zoonami_backpack_gui_zoom", 1)
	end
	if meta:get_float("zoonami_battle_gui_zoom") == 0 then
		meta:set_float("zoonami_battle_gui_zoom", 1)
	end
end)

minetest.register_on_respawnplayer(function(player)
	local player_name = player:get_player_name()
	if not minetest.is_creative_enabled(player_name) then
		local inv = player:get_inventory()
		inv:add_item("main", modname .. ":zoonami_guide_book")
		inv:add_item("main", modname .. ":zoonami_backpack")
	end
end)
