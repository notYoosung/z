local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

-- Contains all the moves that monsters can use

--Local namespace
local move_stats = {}

-- Text coloring for tooltip parameters and values
local color = function(parameter)
	return minetest.get_color_escape_sequence("#000")..
		   parameter..
		   minetest.get_color_escape_sequence("#444")
end

-- Generate Tooltip
function move_stats.tooltip(move_name, cooldown, quantity)
	local move = move_stats[move_name]
	local resistances = ""
	for k, v in pairs (move.resistance or {}) do
		resistances = resistances..color("\nResists: ")..(k:gsub("^%l", string.upper)).." "..(v*100).."%"
	end
	local tooltip = (move.type and color("Type: ")..move.type.."\n" or "")..
	(move.attack and color("Attack: ")..(move.attack*100).."%\n" or "")..
	(move.counter_min and color("Counter: ")..(move.counter_min*100).."% - "..(move.counter_max*100).."%\n" or "")..
	(move.range_min and color("Range: ")..(move.range_min*100).."% - "..(move.range_max*100).."%\n" or "")..
	(move.static and color("Static: ")..(move.static*100).."%\n" or "")..
	(move.shield and color("Shield: ")..(move.shield*100).."%\n" or "")..
	(move.heal and color("Heal: ")..(move.heal*100).."%\n" or "")..
	(move.recover and color("Recover: ")..move.recover.."\n" or "")..
	(move.energy and move.energy > 0 and color("Energy: ")..move.energy.."\n" or "")..
	(move.priority and color("Priority: ")..move.priority or "")..
	((move.counteract or move.resistance) and "\n────────────" or (move.cooldown or move.quantity) and "\n─────────" or "")..
	(move.cooldown and color("\nCooldown: ")..(cooldown or move.cooldown).."/"..move.cooldown or "")..
	(move.quantity and color("\nQuantity: ")..(quantity or move.quantity).."/"..move.quantity or "")..
	(move.counteract and color("\nCounteract: ")..move.counteract or "")..
	(move.resistance and resistances or "")
	return tooltip
end

--- Healing Moves ---

-- Refresh
move_stats.refresh = {
	name = "Refresh",
	asset_name = "refresh",
	heal = 0.3,
	energy = 1,
	priority = 0,
	cooldown = 1,
	quantity = 2,
	animation_frames = 3,
	frame_length = 190,
	sound = "zoonami_gear_shift",
	volume = 1
}

-- Restore
move_stats.restore = {
	name = "Restore",
	asset_name = "restore",
	heal = 0.5,
	energy = 1,
	priority = 0,
	quantity = 1,
	animation_frames = 3,
	frame_length = 190,
	sound = "zoonami_gear_shift",
	volume = 1
}

--- Recovery Moves ---

-- Rest
move_stats.rest = {
	name = "Rest",
	asset_name = "rest",
	recover = 3,
	energy = 0,
	priority = 0,
	quantity = 1,
	animation_frames = 3,
	frame_length = 190,
	sound = "zoonami_gear_shift",
	volume = 1
}

--- Shield Moves ---

-- Guard
move_stats.guard = {
	name = "Guard",
	asset_name = "guard",
	shield = 1.0,
	energy = 2,
	priority = 2,
	cooldown = 1,
	quantity = 2,
	animation_frames = 4,
	frame_length = 250,
	sound = "zoonami_guard",
	volume = 1
}

-- Barrier
move_stats.barrier = {
	name = "Barrier",
	asset_name = "barrier",
	shield = 1.0,
	energy = 1,
	priority = 1,
	quantity = 2,
	animation_frames = 2,
	frame_length = 160,
	sound = "zoonami_guard",
	volume = 1
}

-- Force Field
move_stats.force_field = {
	name = "Force Field",
	asset_name = "force_field",
	shield = 0.90,
	energy = 1,
	priority = 2,
	quantity = 2,
	animation_frames = 2,
	frame_length = 160,
	sound = "zoonami_guard",
	volume = 1
}

--- Static Moves ---

-- Diced
move_stats.diced = {
	name = "Diced",
	asset_name = "diced",
	static = 0.2,
	energy = 2,
	priority = 0,
	animation_frames = 4,
	frame_length = 190,
	sound = "zoonami_diced",
	volume = 1
}

-- Split
move_stats.split = {
	name = "Split",
	asset_name = "split",
	static = 0.25,
	energy = 3,
	priority = 0,
	animation_frames = 4,
	frame_length = 175,
	sound = "zoonami_illusion",
	volume = 1
}

-- Void
move_stats.void = {
	name = "Void",
	asset_name = "void",
	static = 0.34,
	energy = 4,
	priority = 0,
	animation_frames = 4,
	frame_length = 175,
	sound = "zoonami_shadow_orb",
	volume = 0.6
}

--- Counter Moves ---

-- Rage
move_stats.rage = {
	name = "Rage",
	asset_name = "rage",
	type = "Beast",
	counter_min = 1.3,
	counter_max = 1.95,
	energy = 4,
	priority = 0,
	animation_frames = 2,
	frame_length = 200,
	sound = "zoonami_razor_fang",
	volume = 1
}

-- Inferno
move_stats.inferno = {
	name = "Inferno",
	asset_name = "inferno",
	type = "Fire",
	counter_min = 1.3,
	counter_max = 1.95,
	energy = 4,
	priority = 0,
	animation_frames = 3,
	frame_length = 150,
	sound = "zoonami_man_melter",
	volume = 1
}

-- Slice
move_stats.slice = {
	name = "Slice",
	asset_name = "slice",
	type = "Insect",
	counter_min = 1.25,
	counter_max = 2.0,
	energy = 4,
	priority = 0,
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_slash",
	volume = 1
}

-- Swirl
move_stats.swirl = {
	name = "Swirl",
	asset_name = "swirl",
	type = "Aquatic",
	counter_min = 0.6,
	counter_max = 1.7,
	energy = 2,
	priority = 0,
	animation_frames = 4,
	frame_length = 160,
	sound = "zoonami_swirl",
	volume = 1
}

-- Whirlwind
move_stats.whirlwind = {
	name = "Whirlwind",
	asset_name = "whirlwind",
	type = "Avian",
	counter_min = 0.9,
	counter_max = 1.85,
	energy = 3,
	priority = 0,
	animation_frames = 3,
	frame_length = 160,
	sound = "zoonami_gust",
	volume = 1
}

-- Thorns
move_stats.thorns = {
	name = "Thorns",
	asset_name = "thorns",
	type = "Plant",
	counter_min = 1.25,
	counter_max = 2.0,
	energy = 4,
	priority = 0,
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_pincer",
	volume = 1
}

--- Blitz Moves ---

-- Boil
move_stats.boil = {
	name = "Boil",
	asset_name = "boil",
	type = "Aquatic",
	attack = 3.1,
	energy = 4,
	priority = 1,
	quantity = 1,
	animation_frames = 4,
	frame_length = 160,
	sound = "zoonami_boil",
	volume = 1
}

-- Flash Fire
move_stats.flash_fire = {
	name = "Flash Fire",
	asset_name = "flash_fire",
	type = "Fire",
	attack = 2.0,
	energy = 2,
	priority = 1,
	quantity = 1,
	animation_frames = 4,
	frame_length = 125,
	sound = "zoonami_fireball",
	volume = 1
}

-- Ground Pound
move_stats.ground_pound = {
	name = "Ground Pound",
	asset_name = "ground_pound",
	type = "Rock",
	attack = 2.5,
	energy = 3,
	priority = 1,
	quantity = 1,
	animation_frames = 4,
	frame_length = 125,
	sound = "zoonami_punch",
	volume = 1
}

-- Pinpoint
move_stats.pinpoint = {
	name = "Pinpoint",
	asset_name = "pinpoint",
	type = "Plant",
	attack = 2.5,
	energy = 3,
	priority = 1,
	quantity = 1,
	animation_frames = 2,
	frame_length = 250,
	sound = "zoonami_pierce",
	volume = 1
}

-- Toxin
move_stats.toxin = {
	name = "Toxin",
	asset_name = "toxin",
	type = "Mutant",
	attack = 2.0,
	energy = 2,
	priority = 1,
	quantity = 1,
	animation_frames = 3,
	frame_length = 125,
	sound = "zoonami_poison",
	volume = 1
}

-- Ultrasonic
move_stats.ultrasonic = {
	name = "Ultrasonic",
	asset_name = "ultrasonic",
	type = "Robotic",
	attack = 2.0,
	energy = 2,
	priority = 1,
	quantity = 1,
	animation_frames = 3,
	frame_length = 100,
	sound = "zoonami_illusion",
	volume = 1
}

--- Basic Moves ---

-- Skip
move_stats.skip = {
	name = "Skip",
	asset_name = "skip",
	type = "skip",
	attack = 0,
	energy = 0,
	priority = 0,
	animation_frames = 0,
	frame_length = 0,
	sound = "zoonami_skip",
	volume = 1
}

-- Aquatic
move_stats.bubble_stream = {
	name = "Bubble Stream",
	asset_name = "bubble_stream",
	type = "Aquatic",
	attack = 0.9,
	energy = 2,
	priority = 0,
	animation_frames = 6,
	frame_length = 150,
	sound = "zoonami_bubble_stream",
	volume = 1
}

move_stats.high_tide = {
	name = "High Tide",
	asset_name = "high_tide",
	type = "Aquatic",
	attack = 1.0,
	energy = 2,
	priority = 0,
	animation_frames = 2,
	frame_length = 450,
	sound = "zoonami_high_tide",
	volume = 0.8
}

move_stats.aqua_jet = {
	name = "Aqua Jet",
	asset_name = "aqua_jet",
	type = "Aquatic",
	attack = 1.1,
	energy = 2,
	priority = 0,
	resistance = {fire = 0.10},
	animation_frames = 2,
	frame_length = 100,
	sound = "zoonami_high_tide",
	volume = 0.8
}

move_stats.geyser = {
	name = "Geyser",
	asset_name = "geyser",
	type = "Aquatic",
	attack = 1.6,
	energy = 4,
	priority = 0,
	counteract = "Defense",
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_high_tide",
	volume = 0.8
}

move_stats.vortex = {
	name = "Vortex",
	asset_name = "vortex",
	type = "Aquatic",
	attack = 2.1,
	energy = 6,
	priority = 0,
	animation_frames = 4,
	frame_length = 100,
	sound = "zoonami_spore_storm",
	volume = 1
}

move_stats.downpour = {
	name = "Downpour",
	asset_name = "downpour",
	type = "Aquatic",
	attack = 1.45,
	energy = 4,
	priority = 1,
	resistance = {robotic = 0.15},
	animation_frames = 3,
	frame_length = 150,
	sound = "zoonami_downpour",
	volume = 0.5
}

-- Avian
move_stats.gust = {
	name = "Gust",
	asset_name = "gust",
	type = "Avian",
	attack = 0.9,
	energy = 2,
	priority = 0,
	resistance = {aquatic = 0.10},
	animation_frames = 4,
	frame_length = 190,
	sound = "zoonami_gust",
	volume = 1
}

move_stats.swoop = {
	name = "Swoop",
	asset_name = "swoop",
	type = "Avian",
	attack = 1.0,
	energy = 2,
	priority = 0,
	animation_frames = 4,
	frame_length = 175,
	sound = "zoonami_swoop",
	volume = 1
}

move_stats.peck = {
	name = "Peck",
	asset_name = "peck",
	type = "Avian",
	attack = 1.1,
	energy = 2,
	priority = 0,
	resistance = {plant = 0.10},
	animation_frames = 2,
	frame_length = 160,
	sound = "zoonami_peck",
	volume = 1
}

move_stats.quill_drill = {
	name = "Quill Drill",
	asset_name = "quill_drill",
	type = "Avian",
	attack = 1.6,
	energy = 4,
	priority = 0,
	animation_frames = 3,
	frame_length = 160,
	sound = "zoonami_quill_drill",
	volume = 1
}

move_stats.twister = {
	name = "Twister",
	asset_name = "twister",
	type = "Avian",
	attack = 2.1,
	energy = 6,
	priority = 0,
	counteract = "Agility",
	animation_frames = 4,
	frame_length = 125,
	sound = "zoonami_spore_storm",
	volume = 1
}

-- Beast
move_stats.roar = {
	name = "Roar",
	asset_name = "roar",
	type = "Beast",
	attack = 0.90,
	energy = 2,
	priority = 0,
	resistance = {mutant = 0.10},
	animation_frames = 4,
	frame_length = 200,
	sound = "zoonami_roar",
	volume = 0.8
}

move_stats.pierce = {
	name = "Pierce",
	asset_name = "pierce",
	type = "Beast",
	attack = 1.0,
	energy = 2,
	priority = 0,
	counteract = "Defense",
	animation_frames = 3,
	frame_length = 170,
	sound = "zoonami_pierce",
	volume = 1
}

move_stats.stomp = {
	name = "Stomp",
	asset_name = "stomp",
	type = "Beast",
	attack = 1.1,
	energy = 2,
	priority = 0,
	resistance = {rodent = 0.10},
	animation_frames = 4,
	frame_length = 235,
	sound = "zoonami_stomp",
	volume = 1
}

move_stats.slash = {
	name = "Slash",
	asset_name = "slash",
	type = "Beast",
	attack = 1.6,
	energy = 4,
	priority = 0,
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_slash",
	volume = 1
}

move_stats.bulldoze = {
	name = "Bulldoze",
	asset_name = "bulldoze",
	type = "Beast",
	attack = 2.1,
	energy = 6,
	priority = 0,
	resistance = {robotic = 0.20},
	animation_frames = 3,
	frame_length = 150,
	sound = "zoonami_bulldoze",
	volume = 0.6
}

-- Fire
move_stats.embers = {
	name = "Embers",
	asset_name = "embers",
	type = "Fire",
	attack = 0.90,
	energy = 2,
	priority = 0,
	resistance = {plant = 0.10},
	animation_frames = 4,
	frame_length = 160,
	sound = "zoonami_embers",
	volume = 1
}

move_stats.scorch = {
	name = "Scorch",
	asset_name = "scorch",
	type = "Fire",
	attack = 1.0,
	energy = 2,
	priority = 0,
	animation_frames = 2,
	frame_length = 150,
	sound = "zoonami_scorch",
	volume = 0.6
}

move_stats.fireball = {
	name = "Fireball",
	asset_name = "fireball",
	type = "Fire",
	attack = 1.1,
	energy = 2,
	priority = 0,
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_fireball",
	volume = 1
}

move_stats.burnout = {
	name = "Burnout",
	asset_name = "burnout",
	type = "Fire",
	attack = 1.6,
	energy = 4,
	priority = 0,
	resistance = {spirit = 0.15},
	animation_frames = 4,
	frame_length = 160,
	sound = "zoonami_scorch",
	volume = 0.6
}

move_stats.man_melter = {
	name = "Man Melter",
	asset_name = "man_melter",
	type = "Fire",
	attack = 2.1,
	energy = 6,
	priority = 0,
	resistance = {warrior = 0.20},
	animation_frames = 2,
	frame_length = 150,
	sound = "zoonami_man_melter",
	volume = 0.8
}

move_stats.afterburn = {
	name = "Afterburn",
	asset_name = "afterburn",
	type = "Fire",
	attack = 1.25,
	energy = 2,
	priority = -1,
	counteract = "Health",
	animation_frames = 3,
	frame_length = 200,
	sound = "zoonami_embers",
	volume = 1.0
}

-- Insect
move_stats.pincer = {
	name = "Pincer",
	asset_name = "pincer",
	type = "Insect",
	attack = 0.9,
	energy = 2,
	priority = 0,
	animation_frames = 2,
	frame_length = 250,
	sound = "zoonami_pincer",
	volume = 1
}

move_stats.poison_sting = {
	name = "Poison Sting",
	asset_name = "poison_sting",
	type = "Insect",
	attack = 1.0,
	energy = 2,
	priority = 0,
	animation_frames = 4,
	frame_length = 125,
	sound = "zoonami_thissle_missle",
	volume = 0.7
}

move_stats.infestation = {
	name = "Infestation",
	asset_name = "infestation",
	type = "Insect",
	attack = 1.1,
	energy = 2,
	priority = 0,
	resistance = {warrior = 0.15},
	animation_frames = 3,
	frame_length = 100,
	sound = "zoonami_infestation",
	volume = 0.8
}

move_stats.life_drain = {
	name = "Life Drain",
	asset_name = "life_drain",
	type = "Insect",
	attack = 1.6,
	heal = 0.05,
	energy = 4,
	priority = 0,
	resistance = {spirit = 0.10},
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_life_drain",
	volume = 1
}

move_stats.bug_bite = {
	name = "Bug Bite",
	asset_name = "bug_bite",
	type = "Insect",
	attack = 2.1,
	energy = 6,
	priority = 0,
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_bug_bite",
	volume = 1
}

-- Mutant
move_stats.illusion = {
	name = "Illusion",
	asset_name = "illusion",
	type = "Mutant",
	attack = 0.90,
	counteract = "Attack",
	energy = 2,
	priority = 0,
	resistance = {warrior = 0.10},
	animation_frames = 4,
	frame_length = 175,
	sound = "zoonami_illusion",
	volume = 1.0
}

move_stats.smog = {
	name = "Smog",
	asset_name = "smog",
	type = "Mutant",
	attack = 1.0,
	energy = 2,
	priority = 0,
	animation_frames = 4,
	frame_length = 175,
	sound = "zoonami_smog",
	volume = 0.8
}

move_stats.acid_bath = {
	name = "Acid Bath",
	asset_name = "acid_bath",
	type = "Mutant",
	attack = 1.1,
	energy = 2,
	priority = 0,
	resistance = {aquatic = 0.10},
	animation_frames = 2,
	frame_length = 300,
	sound = "zoonami_smog",
	volume = 0.8
}

move_stats.shadow_orb = {
	name = "Shadow Orb",
	asset_name = "shadow_orb",
	type = "Mutant",
	attack = 1.6,
	energy = 4,
	priority = 0,
	animation_frames = 4,
	frame_length = 125,
	sound = "zoonami_shadow_orb",
	volume = 0.6
}

move_stats.nightmare = {
	name = "Nightmare",
	asset_name = "nightmare",
	type = "Mutant",
	attack = 2.1,
	energy = 6,
	priority = 0,
	resistance = {reptile = 0.20},
	animation_frames = 2,
	frame_length = 150,
	sound = "zoonami_shadow_orb",
	volume = 0.6
}

-- Plant
move_stats.prickle = {
	name = "Prickle",
	asset_name = "prickle",
	type = "Plant",
	attack = 0.90,
	energy = 2,
	priority = 0,
	resistance = {avian = 0.10},
	animation_frames = 4,
	frame_length = 125,
	sound = "zoonami_slash",
	volume = 1
}

move_stats.vine_wrap = {
	name = "Vine Wrap",
	asset_name = "vine_wrap",
	type = "Plant",
	attack = 1.0,
	energy = 2,
	priority = 0,
	counteract = "Agility",
	animation_frames = 2,
	frame_length = 250,
	sound = "zoonami_pincer",
	volume = 1
}

move_stats.spore_storm = {
	name = "Spore Storm",
	asset_name = "spore_storm",
	type = "Plant",
	attack = 1.1,
	energy = 2,
	priority = 0,
	animation_frames = 4,
	frame_length = 125,
	sound = "zoonami_spore_storm",
	volume = 1
}

move_stats.grass_blade = {
	name = "Grass Blade",
	asset_name = "grass_blade",
	type = "Plant",
	attack = 1.6,
	energy = 4,
	priority = 0,
	resistance = {rock = 0.15},
	animation_frames = 4,
	frame_length = 175,
	sound = "zoonami_slash",
	volume = 1
}

move_stats.thissle_missle = {
	name = "Thissle Missle",
	asset_name = "thissle_missle",
	type = "Plant",
	attack = 2.1,
	energy = 6,
	priority = 0,
	animation_frames = 5,
	frame_length = 125,
	sound = "zoonami_thissle_missle",
	volume = 0.7
}

move_stats.snare = {
	name = "Snare",
	asset_name = "snare",
	type = "Plant",
	attack = 1.25,
	energy = 2,
	priority = -1,
	animation_frames = 2,
	frame_length = 300,
	sound = "zoonami_pincer",
	volume = 1
}

-- Reptile
move_stats.constrict = {
	name = "Constrict",
	asset_name = "constrict",
	type = "Reptile",
	attack = 0.90,
	energy = 2,
	priority = 0,
	resistance = {rodent = 0.10},
	animation_frames = 2,
	frame_length = 250,
	sound = "zoonami_pincer",
	volume = 1
}

move_stats.tail_swipe = {
	name = "Tail Swipe",
	asset_name = "tail_swipe",
	type = "Reptile",
	attack = 1.0,
	energy = 2,
	priority = 0,
	resistance = {rock = 0.10},
	animation_frames = 3,
	frame_length = 150,
	sound = "zoonami_slash",
	volume = 1
}

move_stats.poison = {
	name = "Poison",
	asset_name = "poison",
	type = "Reptile",
	attack = 1.1,
	energy = 2,
	priority = 0,
	counteract = "Health",
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_poison",
	volume = 1
}

move_stats.spikes = {
	name = "Spikes",
	asset_name = "spikes",
	type = "Reptile",
	attack = 1.6,
	energy = 4,
	priority = 0,
	animation_frames = 4,
	frame_length = 130,
	sound = "zoonami_thissle_missle",
	volume = 0.7
}

move_stats.venom_fangs = {
	name = "Venom Fangs",
	asset_name = "venom_fangs",
	type = "Reptile",
	attack = 2.1,
	energy = 6,
	priority = 0,
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_bite",
	volume = 1
}

-- Robotic
move_stats.electrocute = {
	name = "Electrocute",
	asset_name = "electrocute",
	type = "Robotic",
	attack = 0.90,
	energy = 2,
	priority = 0,
	animation_frames = 3,
	frame_length = 100,
	sound = "zoonami_electrocute",
	volume = 1
}

move_stats.crusher = {
	name = "Crusher",
	asset_name = "crusher",
	type = "Robotic",
	attack = 1.0,
	energy = 2,
	priority = 0,
	resistance = {insect = 0.10},
	animation_frames = 2,
	frame_length = 150,
	sound = "zoonami_crusher",
	volume = 1
}

move_stats.vice_grip = {
	name = "Vice Grip",
	asset_name = "vice_grip",
	type = "Robotic",
	attack = 1.1,
	energy = 2,
	priority = 0,
	counteract = "Attack",
	animation_frames = 2,
	frame_length = 200,
	sound = "zoonami_crusher",
	volume = 1
}

move_stats.power_surge = {
	name = "Power Surge",
	asset_name = "power_surge",
	type = "Robotic",
	attack = 1.6,
	energy = 4,
	priority = 0,
	resistance = {avian = 0.15},
	animation_frames = 3,
	frame_length = 100,
	sound = "zoonami_electrocute",
	volume = 1
}

move_stats.laser_beam = {
	name = "Laser Beam",
	asset_name = "laser_beam",
	type = "Robotic",
	attack = 2.1,
	energy = 6,
	priority = 0,
	animation_frames = 2,
	frame_length = 75,
	sound = "zoonami_laser_beam",
	volume = 0.4
}

move_stats.iron_fist = {
	name = "Iron Fist",
	asset_name = "iron_fist",
	type = "Robotic",
	attack = 1.75,
	energy = 4,
	priority = -1,
	animation_frames = 6,
	frame_length = 100,
	sound = "zoonami_punch",
	volume = 1
}

move_stats.gear_shift = {
	name = "Gear Shift",
	asset_name = "gear_shift",
	type = "Robotic",
	attack = 1.45,
	heal = 0.05,
	energy = 4,
	priority = 1,
	animation_frames = 3,
	frame_length = 70,
	sound = "zoonami_gear_shift",
	volume = 0.8
}

-- Rock
move_stats.pellet = {
	name = "Pellet",
	asset_name = "pellet",
	type = "Rock",
	attack = 0.90,
	energy = 2,
	priority = 0,
	animation_frames = 4,
	frame_length = 200,
	sound = "zoonami_pellet",
	volume = 1
}

move_stats.boulder_roll = {
	name = "Boulder Roll",
	asset_name = "boulder_roll",
	type = "Rock",
	attack = 1.0,
	energy = 2,
	priority = 0,
	animation_frames = 3,
	frame_length = 170,
	sound = "zoonami_boulder_roll",
	volume = 1
}

move_stats.rockburst = {
	name = "Rockburst",
	asset_name = "rockburst",
	type = "Rock",
	attack = 1.1,
	energy = 2,
	priority = 0,
	counteract = "Defense",
	animation_frames = 3,
	frame_length = 200,
	sound = "zoonami_rockburst",
	volume = 1
}

move_stats.mudslide = {
	name = "Mudslide",
	asset_name = "mudslide",
	type = "Rock",
	attack = 1.6,
	energy = 4,
	priority = 0,
	resistance = {fire = 0.15},
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_stomp",
	volume = 1
}

move_stats.fissure = {
	name = "Fissure",
	asset_name = "fissure",
	type = "Rock",
	attack = 2.1,
	energy = 6,
	priority = 0,
	resistance = {beast = 0.20},
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_fissure",
	volume = 0.9
}

-- Rodent
move_stats.swipe = {
	name = "Swipe",
	asset_name = "swipe",
	type = "Rodent",
	attack = 0.9,
	energy = 2,
	priority = 0,
	resistance = {insect = 0.10},
	animation_frames = 6,
	frame_length = 100,
	sound = "zoonami_slash",
	volume = 1
}

move_stats.gnaw = {
	name = "Gnaw",
	asset_name = "gnaw",
	type = "Rodent",
	attack = 1.0,
	energy = 2,
	priority = 0,
	resistance = {plant = 0.10},
	animation_frames = 2,
	frame_length = 300,
	sound = "zoonami_bite",
	volume = 1
}

move_stats.bite = {
	name = "Bite",
	asset_name = "bite",
	type = "Rodent",
	attack = 1.1,
	energy = 2,
	priority = 0,
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_bite",
	volume = 1
}

move_stats.claw = {
	name = "Claw",
	asset_name = "claw",
	type = "Rodent",
	attack = 1.6,
	energy = 4,
	priority = 0,
	animation_frames = 4,
	frame_length = 150,
	sound = "zoonami_slash",
	volume = 1
}

move_stats.razor_fang = {
	name = "Razor Fang",
	asset_name = "razor_fang",
	type = "Rodent",
	attack = 2.1,
	energy = 6,
	priority = 0,
	counteract = "Defense",
	resistance = {robotic = 0.20},
	animation_frames = 2,
	frame_length = 150,
	sound = "zoonami_razor_fang",
	volume = 0.7
}

-- Spirit
move_stats.sing = {
	name = "Sing",
	asset_name = "sing",
	type = "Spirit",
	attack = 0.90,
	energy = 2,
	priority = 0,
	counteract = "Attack",
	animation_frames = 3,
	frame_length = 500,
	sound = "zoonami_sing",
	volume = 0.5
}

move_stats.purify = {
	name = "Purify",
	asset_name = "purify",
	type = "Spirit",
	attack = 1.0,
	energy = 2,
	priority = 0,
	resistance = {beast = 0.10},
	animation_frames = 3,
	frame_length = 170,
	sound = "zoonami_purify",
	volume = 0.9
}

move_stats.shine = {
	name = "Shine",
	asset_name = "shine",
	type = "Spirit",
	attack = 1.1,
	energy = 2,
	priority = 0,
	resistance = {mutant = 0.10},
	animation_frames = 4,
	frame_length = 170,
	sound = "zoonami_shine",
	volume = 0.9
}

move_stats.cleanse = {
	name = "Cleanse",
	asset_name = "cleanse",
	type = "Spirit",
	attack = 1.6,
	heal = 0.05,
	energy = 4,
	priority = 0,
	animation_frames = 4,
	frame_length = 170,
	sound = "zoonami_cleanse",
	volume = 0.9
}

move_stats.harmony = {
	name = "Harmony",
	asset_name = "harmony",
	type = "Spirit",
	attack = 2.1,
	energy = 6,
	priority = 0,
	animation_frames = 4,
	frame_length = 200,
	sound = "zoonami_harmony",
	volume = 0.5
}

-- Warrior
move_stats.strike = {
	name = "Strike",
	asset_name = "strike",
	type = "Warrior",
	attack = 0.90,
	energy = 2,
	priority = 0,
	resistance = {reptile = 0.10},
	animation_frames = 5,
	frame_length = 100,
	sound = "zoonami_slash",
	volume = 1
}

move_stats.punch = {
	name = "Punch",
	asset_name = "punch",
	type = "Warrior",
	attack = 1.0,
	energy = 2,
	priority = 0,
	counteract = "Health",
	animation_frames = 6,
	frame_length = 100,
	sound = "zoonami_punch",
	volume = 1
}

move_stats.chop = {
	name = "Chop",
	asset_name = "chop",
	type = "Warrior",
	attack = 1.1,
	energy = 2,
	priority = 0,
	animation_frames = 2,
	frame_length = 250,
	sound = "zoonami_chop",
	volume = 1
}

move_stats.dropkick = {
	name = "Dropkick",
	asset_name = "dropkick",
	type = "Warrior",
	attack = 1.6,
	energy = 4,
	priority = 0,
	counteract = "Attack",
	animation_frames = 3,
	frame_length = 200,
	sound = "zoonami_stomp",
	volume = 1
}

move_stats.sword_swipe = {
	name = "Sword Swipe",
	asset_name = "sword_swipe",
	type = "Warrior",
	attack = 2.1,
	energy = 6,
	priority = 0,
	resistance = {beast = 0.20},
	animation_frames = 4,
	frame_length = 175,
	sound = "zoonami_slash",
	volume = 1
}

return move_stats
