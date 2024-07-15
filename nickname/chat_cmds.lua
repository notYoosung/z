local minetest, nickname = minetest, nickname

local S = nickname.get_translator

local function trim(s)
  return string.gsub(s, "^%s*(.-)%s*$", "%1") --trim spaces
end

local displayNames = {text=S('nickname'), color=S('color'), bgcolor=S('bgcolor')}

local function do_nickInfo(playerName, name, value)
  local msg
  local displayName = displayNames[name]
  if value == '?' then
    value, msg = nickname.getInfo(playerName)
    if value and value[name] then msg = S("@1's @2 is @3", playerName, displayName, dump(value[name])) end
    if value == false then msg = msg end
    return value ~= false, msg
  end
  local info = {}
  info[name] = value
  local result = nickname.setInfo(playerName, info)
  if result then
    msg = S("Set @1's @2 to @3 successfully.", playerName, displayName, value)
  else
    msg = S("Set @1's @2 to @3 failed.", playerName, displayName, value)
  end
  return result, msg
end

minetest.register_privilege("nickname", {
  description = S("allow to change nickname"),
  -- give_to_singleplayer = false, --< DO NOT defaults to singleplayer
  give_to_admin = true,
})

minetest.register_chatcommand("nickname", {
  description = S("get/set the nickname <newNickName> [,playerName]"),
  privs = {
    nickname = true,
  },
  func = function(name, param)
    local parts = param:split(",")
    local len = #parts
    local msg = S("No nickname provided.")
    if len == 0 then
      name = nickname.get(name)
      if name then msg = S("Your nickname is @1", name) end
      return true, msg
    end
    local vNickname = trim(parts[1])
    if #vNickname == 0 then return false, msg end
    local player = minetest.get_player_by_name(name)
    if len >= 2 and name ~= parts[2] then
      if minetest.check_player_privs(player, "server") then
        name = parts[2]
      else
        return false, S("This requires the \"server\" privilege.")
      end
    end
    return do_nickInfo(name, 'text', vNickname)
  end,
})

minetest.register_chatcommand("nickname_color", {
  description = S("get/set the nickname color <newColor> [,playerName]"),
  privs = {
    nickname = true,
  },
  func = function(name, param)
    local parts = param:split(",")
    local len = #parts
    local msg = S("No color provided.")
    if len == 0 then
      local nametag = nickname.getInfo(name)
      if nametag and nametag.color then msg = S("Your nickname color is @1", dump(nametag.color)) end
      return true, msg
    end

    local color = trim(parts[1])
    if #color == 0 then return false, msg end

    local player = minetest.get_player_by_name(name)
    if len >= 2 and name ~= parts[2] then
      if minetest.check_player_privs(player, "server") then
        name = parts[2]
      else
        return false, S("This requires the \"server\" privilege.")
      end
    end
    return do_nickInfo(name, 'color', color)
  end,
})

minetest.register_chatcommand("nickname_bgcolor", {
  description = S("get/set the nickname background color <newColor> [,playerName]"),
  privs = {
    nickname = true,
  },
  func = function(name, param)
    local parts = param:split(",")
    local len = #parts
    local msg = S("No bgcolor provided.")
    if len == 0 then
      local nametag = nickname.getInfo(name)
      if nametag and nametag.bgcolor then msg = S("Your nickname bgcolor is @1", dump(nametag.bgcolor)) end
      return true, msg
    end
    local color = trim(parts[1])
    if #color == 0 then return false, msg end

    local player = minetest.get_player_by_name(name)
    if len >= 2 and name ~= parts[2] then
      if minetest.check_player_privs(player, "server") then
        name = parts[2]
      else
        return false, S("This requires the \"server\" privilege.")
      end
    end
    return do_nickInfo(name, 'bgcolor', color)
  end,
})
