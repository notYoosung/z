-- LUALOCALS < ---------------------------------------------------------
local minetest, type, DIR_DELIM
    = minetest, type, DIR_DELIM
-- LUALOCALS > ---------------------------------------------------------

local MOD_NAME = minetest.get_current_modname()

if rawget(_G, MOD_NAME) then return end

nickname = {}
minetest.log("info", "Loading nickname Mod")

-- Handle mod security if needed
local ie, req_ie = _G, minetest.request_insecure_environment
if req_ie then ie = req_ie() end
nickname.trusted = not not ie

local MOD_PATH = minetest.get_modpath(MOD_NAME) .. "/"
local WORLD_PATH = minetest.get_worldpath() .. "/"
local DATA_PATH = WORLD_PATH .. MOD_NAME .. "/"

local function isWritenModDir()
  local modName = minetest.get_current_modname()
  return not not modName
end

if type(minetest.get_mod_data_path) == "function" then
  DATA_PATH = minetest.get_mod_data_path() .. DIR_DELIM
elseif isWritenModDir() then
  if ie then
    -- "(.*/)worlds/.*/"
    local pattern = "(.*" .. DIR_DELIM .. ")worlds" .. DIR_DELIM .. ".*" .. DIR_DELIM
    DATA_PATH = string.match(WORLD_PATH, pattern) .. "mod_data" .. DIR_DELIM .. MOD_NAME .. DIR_DELIM
  else
    DATA_PATH = MOD_PATH .. "data" .. DIR_DELIM
  end
end

nickname.DATA_PATH = DATA_PATH

-- Load support for MT game translation.
local S = minetest.get_translator(MOD_NAME)
nickname.get_translator = S

local data = dofile(MOD_PATH .. "data.lua")
dofile(MOD_PATH .. "chat_cmds.lua")

minetest.register_on_joinplayer(function(player)
  local name = player:get_player_name()
  local content = data.getInfo(name)
  if content then
    player:set_nametag_attributes(content)
  end
end)
