-- Compatability with mesesons

-- Find mods
local mesecons_mod = minetest.get_modpath("mesecons")
local mesecons_mvps_mod = minetest.get_modpath("mesecons_mvps")

-- Prevent nodes from beng pushed by pistons
if mesecons_mod and mesecons_mvps_mod then
	mesecon.register_mvps_stopper("zoonami:healer")
	mesecon.register_mvps_stopper("zoonami:computer")
	mesecon.register_mvps_stopper("zoonami:trading_machine")
	mesecon.register_mvps_stopper("zoonami:vending_machine")
	mesecon.register_mvps_stopper("zoonami:automatic_vending_machine")
	mesecon.register_mvps_stopper("zoonami:monster_spawner")
	mesecon.register_mvps_stopper("zoonami:vending_machine_top")
	mesecon.register_mvps_stopper("zoonami:classic_door")
	mesecon.register_mvps_stopper("zoonami:classic_door_open")
	mesecon.register_mvps_stopper("zoonami:door_top")
	mesecon.register_mvps_stopper("zoonami:crystal_fragment_block")
	mesecon.register_mvps_stopper("zoonami:crystal_light_off")
	mesecon.register_mvps_stopper("zoonami:crystal_light_on")
end
