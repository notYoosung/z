-- LUALOCALS < ---------------------------------------------------------
local minetest, yaml, DIR_DELIM, nickname
    = minetest, yaml, DIR_DELIM, nickname
-- LUALOCALS > ---------------------------------------------------------

local S = nickname.get_translator
local DATA_PATH = nickname.DATA_PATH
local cache = {}

--[[
local function isFileExists(filename)
  local f = io.open(filename, 'r')
  if (f) then
    f:close()
    return true
  end
end
--]]

local function readNickFromConf(filename)
  filename = filename .. ".conf"
  local result = Settings(filename)
  if result:get('text') ~= nil then
    return result:to_table()
  end
end

local function readNickFromYaml(filename)
  filename = filename .. ".yml"
  return yaml.readFile(filename)
end

local function getNickInfo(playerName)
  local result = cache[playerName]
  if not result then
    local filename = DATA_PATH .. DIR_DELIM .. playerName
    result = readNickFromConf(filename)
    if (result == nil) then result = readNickFromYaml(filename) end
    cache[playerName] = result or {}
    if not result then
      local player = minetest.get_player_by_name(playerName)
      if player == nil then return false, S('No player named "@1" exists', playerName) end
      result = player:get_nametag_attributes()
      cache[playerName] = result
      if result and result.text then
        local v = result.text
        local pos = string.find(v, "[(]")
        if pos then
          v = v:sub(1, pos-1)
          result.text = v
        end
      end
    end
  end
  if result then
    local res = table.copy(result)
    local text = res.text
    if text and not string.find(text, playerName) then
      res.text = text .. "(" .. playerName .. ")"
    end
    return res
  end
end
nickname.getInfo = getNickInfo

local function getNickname(playerName)
  local result, msg = getNickInfo(playerName)
  if type(result) == "table" then result = result.text end
  return result, msg
end
nickname.get = getNickname

local function setNicknameInfo(playerName, info)
  if info == nil then return end
  local content = cache[playerName]
  if content then
    for k, v in pairs(info) do
      if k == 'text' or k == 'color' or k == 'bgcolor' then
        if k == 'bgcolor' and v == 'false' then v = false end
        content[k] = v
      end
    end
  else
    content = info
    cache[playerName] = content
  end

  if content.text and content.text ~= '' then
    local v = content.text
    local pos = string.find(v, "[(]")
    if pos then
      v = v:sub(1, pos-1)
      content.text = v
    end
  end

  -- can write offline player
  local filename = DATA_PATH .. DIR_DELIM .. playerName
  local vSettings = Settings(filename .. '.conf')
  local result
  for k,v in pairs(content) do
    if k == 'color' or k == 'bgcolor' then
      if type(v) ~= 'string' and v ~= false then v = minetest.colorspec_to_colorstring(v) end
    end
    if v then
      vSettings:set(k, v)
      result = true
    elseif v == false then
      -- bgcolor could be false
      vSettings:set_bool(k, v)
    else
      content[k] = nil
    end
  end
  if result then vSettings:write() end

  local player = minetest.get_player_by_name(playerName)
  if player ~= nil then
    local res = table.copy(content)
    if res.text then res.text = res.text .. "(" .. playerName .. ")" end
    player:set_nametag_attributes(res)
  end

  return result
end
nickname.set = setNicknameInfo -- deprecated
nickname.setInfo = setNicknameInfo

return {
  get = getNickname,
  getInfo = getNickInfo,
  set = getNickInfo, -- deprecated
  setInfo = setNicknameInfo,
}
