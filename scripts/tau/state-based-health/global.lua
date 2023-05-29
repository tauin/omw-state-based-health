local store = require("openmw.storage")
local conf = store.globalSection('omwStateBasedHealth')

if conf:get("maintainDifference") == nil then
   conf:set("maintainDifference", false)
end
if conf:get("minBaseHealth") == nil then
   conf:set("minBaseHealth", 0)
end

return {
  engineHandlers = {
    onPlayerAdded = function (player)
      player:sendEvent("loaded", nil)
    end
}
}
