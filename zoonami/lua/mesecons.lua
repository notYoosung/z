local modname = minetest.get_current_modname() or "z"
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

-- Compatability with mesesons

-- Find mods
local mesecons_mod = minetest.get_modpath("mesecons")
local mesecons_mvps_mod = minetest.get_modpath("mesecons_mvps")

-- Prevent nodes from beng pushed by pistons
if mesecons_mod and mesecons_mvps_mod then
	mesecon.register_mvps_stopper(modname .. ":zoonami_healer")
	mesecon.register_mvps_stopper(modname .. ":zoonami_computer")
	mesecon.register_mvps_stopper(modname .. ":zoonami_trading_machine")
	mesecon.register_mvps_stopper(modname .. ":zoonami_vending_machine")
	mesecon.register_mvps_stopper(modname .. ":zoonami_automatic_vending_machine")
	mesecon.register_mvps_stopper(modname .. ":zoonami_monster_spawner")
	mesecon.register_mvps_stopper(modname .. ":zoonami_vending_machine_top")
	mesecon.register_mvps_stopper(modname .. ":zoonami_classic_door")
	mesecon.register_mvps_stopper(modname .. ":zoonami_classic_door_open")
	mesecon.register_mvps_stopper(modname .. ":zoonami_door_top")
	mesecon.register_mvps_stopper(modname .. ":zoonami_crystal_fragment_block")
	mesecon.register_mvps_stopper(modname .. ":zoonami_crystal_light_off")
	mesecon.register_mvps_stopper(modname .. ":zoonami_crystal_light_on")
end
