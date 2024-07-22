local zoomfov
local default=true
local xbows=false
local creative_mod=minetest.get_modpath("creative")
local creative_mode=minetest.settings:get_bool('creative_mode')
if(minetest.settings:get("justzoom.zoomfov")~=nil)then
	zoomfov=minetest.settings:get("justzoom.zoomfov")
	default=false
else
	zoomfov=50
	default=true
end
if(minetest.get_modpath("x_bows"))then
	xbows=true
end
local function cyclic_update()
	for _,player in ipairs(minetest.get_connected_players())do
		local creative_priv=minetest.check_player_privs(player,{creative=true})
		local stack=player:get_wielded_item()
		local item=stack:get_name()
		if(item~="binoculars:binoculars" --[[and creative_mod~=true and creative_mode~=true and creative_priv~=true]])then
			player:set_properties({zoom_fov=zoomfov})
		end
		if(xbows==true and item~="x_bows:bow_wood_charged")then
			player:set_fov(0,false,0)--fixes x_bows disabling zooming by having player:set_fov(1, true, 0.4) in it's code and not setting it to zeroes/false afterwards like it's done here. This also creates a bug that makes your fov insanely high for a whole cyclic_update if you switch too fast from the bow after shooting or are just spam shooting the bow
		end
	end
	minetest.after(1.175,cyclic_update)--a frame or so can be seen of binoculars code taking over and disallowing zoom, also time is binoculars' cycle_update time /4
end
minetest.after(1.175,cyclic_update)