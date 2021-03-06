--[[

  Use N_HITPUSH to give a thrust to players. Postulates that the push of chainsaw is 80 and weight of player is 100.

]]--

local putf = require"std.putf"

return function(ci, vel, p)
  local ret = p
  p = putf(p or { 20, r = 1}, server.N_HITPUSH, ci.clientnum, 0, 1, vel.x * 100 / 80 * server.DNF, vel.y * 100 / 80 * server.DNF, vel.z * 100 / 80 * server.DNF)
  if ret then return p end
  engine.sendpacket(ci.state.health <= 0 and -1 or ci.ownernum, 1, p:finalize(), -1)
  ci:setpushed()
end
