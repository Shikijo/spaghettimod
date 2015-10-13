--[[

  Commands to set various attributes of a player.

]]--

local fp, L, commands, playermsg, spawnat, putf = require"utils.fp", require"utils.lambda", require"std.commands", require"std.playermsg", require"std.spawnat", require"std.putf"
local map = fp.map

local module = { cmdprivilege = server.PRIV_ADMIN }

local function makesetter(field)
  commands.add("set" .. field, function(info)
    if not module.cmdprivilege or info.ci.privilege < module.cmdprivilege then playermsg("Insufficient privilege.", info.ci) return end
    local ct, increment, score = info.args:match("^%s*(%d+)%s+([%-%+]?)(%d+)%s*$")
    if not ct then playermsg("Invalid format.", info.ci) return end
    ct = server.getinfo(tonumber(ct) or -1)
    if not ct then playermsg("Player not found.", info.ci) return end
    ct.state[field] = (increment ~= "" and ct.state[field] or 0) + (increment == "-" and -1 or 1) * score
    server.sendresume(ct)
    server.sendservmsg(server.colorname(info.ci, nil) .. " set " .. ct.state[field] .. " " .. field .. " to player " .. server.colorname(ct, nil))
  end, ("#set%s <cn> [+-]<%s>: set %s of player (+/- for increment)"):format(field, field, field))
end

makesetter("frags")
makesetter("flags")
makesetter("health")
makesetter("maxhealth")
makesetter("armour")

function module.syncammo(ci)
  if server.m_capture then
    ci.state.lifesequence = (ci.state.lifesequence + 1) % 0x80
    server.sendresume(ci)
    local p, st = { 20, r = 1}, ci.state
    for type = server.GUN_SG, server.GUN_PISTOL do p = putf(p, server.N_BASEREGEN, ci.clientnum, st.health, st.armour, type, st.ammo[type]) end
    engine.sendpacket(-1, 1, p:finalize(), -1)
  else spawnat(ci, ci.state.o, ci.extra.lastpos and ci.extra.lastpos.yaw or 0) end
end

local ammonames = map.mv(L"_, server['GUN_' .. _:upper()]", "sg", "cg", "rl", "rifle", "gl", "pistol")
ammonames.shotgun, ammonames.chaingun, ammonames.rockets, ammonames.rocket, ammonames.rocketlauncher, ammonames.grenades, ammonames.grenade, ammonames.grenadelauncher = ammonames.sg, ammonames.cg, ammonames.rl, ammonames.rl, ammonames.rl, ammonames.gl, ammonames.gl, ammonames.gl
commands.add("setammo", function(info)
  if not module.cmdprivilege or info.ci.privilege < module.cmdprivilege then playermsg("Insufficient privilege.", info.ci) return end
  local ct, ammoname, increment, ammo = info.args:match("^%s*(%d+)%s+(%S+)%s+([%-%+]?)(%d+)%s*$")
  if not ct then playermsg("Invalid format.", info.ci) return end
  ct = server.getinfo(tonumber(ct) or -1)
  if not ct then playermsg("Player not found.", info.ci) return end
  local ammoidx = ammonames[ammoname:lower()]
  if not ammoidx then playermsg("Ammo type not found.", info.ci) return end
  local st = ct.state
  st.ammo[ammoidx] = math.max((increment ~= "" and st.ammo[ammoidx] or 0) + (increment == "-" and -1 or 1) * ammo, 0)
  module.syncammo(ct)
  server.sendservmsg(server.colorname(info.ci, nil) .. " set " .. st.ammo[ammoidx] .. " " .. ammoname .. " to player " .. server.colorname(ct, nil))
end, "#setammo <cn> <ammoname> [+-]<ammo>: set ammo of player (+/- for increment)")

local armournames = map.mv(L"_, server['A_' .. _:upper()]", "blue", "green", "yellow")
armournames.ba, armournames.ga, armournames.ya = armournames.blue, armournames.green, armournames.yellow
commands.add("setarmourtype", function(info)
  if not module.cmdprivilege or info.ci.privilege < module.cmdprivilege then playermsg("Insufficient privilege.", info.ci) return end
  local ct, type, value = info.args:match("^%s*(%d+)%s+(%S+)%s*([%-%+]?)(%d*)%s*$")
  if not ct then playermsg("Invalid format.", info.ci) return end
  ct = server.getinfo(tonumber(ct) or -1)
  if not ct then playermsg("Player not found.", info.ci) return end
  local armouridx = armournames[type:lower()]
  if not armouridx then playermsg("Armour type not found.", info.ci) return end
  local st = ct.state
  if value == "" then
    if armouridx == server.A_BLUE then value = 50
    else value = server.itemstats[(armouridx == server.A_GREEN and server.I_GREENARMOUR or server.I_YELLOWARMOUR) - server.I_SHELLS].add end
  end
  st.armourtype, st.armour = armouridx, value
  server.sendresume(ct)
  server.sendservmsg(server.colorname(info.ci, nil) .. " set armour " .. type .. ":" .. st.armour .. " to player " .. server.colorname(ct, nil))
end, "#setammo <cn> <armourtype> [value]: set armour type of player (omitted armour value means default pickup value)")

commands.add("setquad", function(info)
  if not module.cmdprivilege or info.ci.privilege < module.cmdprivilege then playermsg("Insufficient privilege.", info.ci) return end
  local ct, increment, value = info.args:match("^%s*(%d+)%s*([%-%+]?)(%d*)%s*$")
  if not ct or (value == "" and increment ~= "") then playermsg("Invalid format.", info.ci) return end
  ct = server.getinfo(tonumber(ct) or -1)
  if not ct then playermsg("Player not found.", info.ci) return end
  value = value ~= "" and value * 1000 or server.itemstats[server.I_QUAD - server.I_SHELLS].add
  ct.state.quadmillis = math.max((increment ~= "" and ct.state.quadmillis or 0) + (increment == "-" and -1 or 1) * value, 0)
  server.sendresume(ct)
  server.sendservmsg(server.colorname(info.ci, nil) .. " set " .. math.floor(ct.state.quadmillis / 1000) .. " seconds of quad to player " .. server.colorname(ct, nil))
end, "#setquad <cn> [[+-]seconds]: set quad seconds of player (omitted seconds means default pickup seconds)")

return module
