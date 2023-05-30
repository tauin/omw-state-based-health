local store = require("openmw.storage")
local I = require("openmw.interfaces")

local conf = store.playerSection("omwStateBasedHealth")

if conf:get("maintainAbsoluteDifference") == nil then
   conf:set("maintainAbsoluteDifference", false)
end
if conf:get("minBaseHealth") == nil then
   conf:set("minBaseHealth", 0)
end

I.Settings.registerPage({
   key = "StateBasedHealth",
   l10n = "state_based_health",
   name = "State Based Health",
})

I.Settings.registerGroup({
   key = "omwStateBasedHealth",
   page = "StateBasedHealth",
   l10n = "state_based_health",
   name = "Settings",
   permanentStorage = true,
   settings = {
      {
         key = "maintainAbsoluteDifference",
         renderer = "checkbox",
         name = "Maintain health differences?",
      },
      {
         key = "minBaseHealth",
         renderer = "number",
         default = 0,
         name = "Minimum Max Health",
      },
   },
})
I.Settings.updateRendererArgument("omwStateBasedHealth", "number", {min = 0, max = 20, integer = true})
