local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

-- Namespace
zoonami = {}

-- Mod path
-- local mod_path = modpath

-- Chat Commands
dofile(mod_path .. "/lua/chat_commands.lua")

-- Craft Items
dofile(mod_path .. "/lua/craft_items.lua")

-- Nodes
dofile(mod_path .. "/lua/nodes.lua")

-- Tools
dofile(mod_path .. "/lua/tools.lua")

-- Vending Machines
dofile(mod_path .. "/lua/vending_machines.lua")

-- Computer
dofile(mod_path .. "/lua/computer.lua")

-- Trading Machine
dofile(mod_path .. "/lua/trading_machine.lua")

-- Monster Spawner
dofile(mod_path .. "/lua/monster_spawner.lua")

-- Crafting
dofile(mod_path .. "/lua/crafting.lua")

-- Mobs
dofile(mod_path .. "/lua/mobs.lua")

-- Battle
dofile(mod_path .. "/lua/battle.lua")

-- Backpack
dofile(mod_path .. "/lua/backpack.lua")

-- Guide Book
dofile(mod_path .. "/lua/guide_book.lua")

-- Monster Journal
dofile(mod_path .. "/lua/monster_journal.lua")

-- Move Journal
dofile(mod_path .. "/lua/move_journal.lua")

-- Move Books
dofile(mod_path .. "/lua/move_books.lua")

-- Berry Juice
dofile(mod_path .. "/lua/berry_juice.lua")

-- Candy
dofile(mod_path .. "/lua/candy.lua")

-- Give Initial Stuff
dofile(mod_path .. "/lua/give_initial_stuff.lua")

-- Mesecons
dofile(mod_path .. "/lua/mesecons.lua")

-- Mapgen
minetest.register_on_mods_loaded(function()
    dofile(mod_path .. "/lua/mapgen.lua")
end)