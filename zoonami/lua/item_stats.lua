local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname)

-- The item stats for items used in battles

-- Local namespace
local item_stats = {}

-- Jelly
local function register_jelly(name, asset_name, color, effective_types)
	local tiers = {"Basic", "Improved", "Advanced"}
	local amounts = {25, 60, 140}
	for i = 1, 3 do
		item_stats[string.lower(tiers[i]).."_"..asset_name.."_jelly"] = {
			name = tiers[i].." "..name.." Jelly",
			asset_name = string.lower(tiers[i]).."_"..asset_name.."_jelly",
			description = "Tames wild monsters.",
			type = "taming",
			amount = amounts[i],
			color = color,
			effective_types = effective_types
		}
	end
end

-- Jelly
register_jelly("Blue", "blue", "#2F7DB5FF", {aquatic=true, avian=true, spirit=true})
register_jelly("Red", "red", "#FF3321FF", {beast=true, warrior=true, mutant=true, fire=true})
register_jelly("Orange", "orange", "#F29400FF", {rodent=true, robotic=true, rock=true})
register_jelly("Green", "green", "#00CC02FF", {plant=true, insect=true, reptile=true})

-- Golden Jelly
item_stats["golden_jelly"] = {
	name = "Golden Jelly",
	asset_name = "golden_jelly",
	description = "Tames wild monsters.",
	type = "taming",
	amount = 999999,
	color = "#F0EC38",
	effective_types = {}
}

return item_stats
