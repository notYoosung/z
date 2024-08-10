local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

-- Returns the effectiveness multiplier for one type vs another type

-- Local namespace
local types = {}

types.index = {
	plant = 2,
	rodent = 3,
	beast = 4,
	warrior = 5,
	insect = 6,
	aquatic = 7,
	robotic = 8,
	reptile = 9,
	avian = 10,
	spirit = 11,
	mutant = 12,
	rock = 13,
	fire = 14
}

-- Attacker move type left column vs defender monster type top row
types.chart = {
	{"------", "Plant","Rodent","Beast","Warrior","Insect","Aquatic","Robotic","Reptile","Avian","Spirit","Mutant","Rock","Fire"},
	{"Plant",   1.00,   0.75,    1.00,   1.00,     0.75,    1.25,     0.75,     1.25,     1.00,   1.25,    1.00,    1.25,  0.75},
	{"Rodent",  1.25,   1.00,    0.75,   1.00,     1.25,    1.00,     1.25,     0.75,     0.75,   1.00,    0.75,    1.25,  1.00},
	{"Beast",   1.00,   1.25,    1.00,   0.75,     0.75,    1.00,     1.25,     1.25,     1.00,   0.75,    1.25,    1.00,  0.75},
	{"Warrior", 1.25,   0.75,    1.25,   1.00,     0.75,    1.00,     0.75,     1.25,     1.25,   1.00,    1.00,    0.75,  1.25},
	{"Insect",  1.25,   1.00,    1.25,   1.00,     1.00,    0.75,     0.75,     0.75,     0.75,   1.25,    1.25,    1.00,  1.00},
	{"Aquatic", 0.75,   1.00,    1.00,   1.00,     1.25,    1.00,     1.25,     0.75,     0.75,   0.75,    1.00,    1.25,  1.25},
	{"Robotic", 1.00,   0.75,    0.75,   1.25,     1.00,    0.75,     1.00,     1.00,     1.25,   1.25,    1.00,    0.75,  1.25},
	{"Reptile", 0.75,   1.25,    1.00,   0.75,     1.25,    1.25,     1.00,     1.00,     0.75,   1.00,    0.75,    1.25,  1.00},
	{"Avian",   1.00,   1.25,    0.75,   0.75,     1.25,    1.25,     1.00,     1.25,     1.00,   1.00,    0.75,    0.75,  1.00},
	{"Spirit",  0.75,   1.00,    1.25,   1.25,     0.75,    1.00,     0.75,     1.00,     1.25,   0.75,    1.25,    1.00,  1.00},
	{"Mutant",  1.00,   1.25,    0.75,   1.25,     1.00,    1.25,     1.00,     1.25,     1.00,   0.75,    0.75,    1.00,  0.75},
	{"Rock",    0.75,   0.75,    1.25,   1.25,     1.00,    0.75,     1.25,     0.75,     1.00,   1.00,    1.00,    1.00,  1.25},
	{"Fire",    1.25,   1.00,    1.00,   0.75,     1.00,    0.75,     1.00,     1.00,     1.25,   1.25,    1.25,    0.75,  0.75}
}

function types.effectiveness(attack_type, defender_type)
	return types.chart[types.index[attack_type]][types.index[defender_type]] or 1
end

return types