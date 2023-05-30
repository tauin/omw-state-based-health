local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local store = require("openmw.storage")
local conf = store.playerSection("omwStateBasedHealth")

local actor = types.Actor
local playerStats = actor.stats

local health = playerStats.dynamic.health(self)
local strength = playerStats.attributes.strength(self)
local endurance = playerStats.attributes.endurance(self)
local level = playerStats.level(self)

local strengthState = strength.modified
local enduranceState = endurance.modified
local levelState = level.current

-- Constants
local F_LEVEL_UP_HEALTH_END_MULT = core.getGMST("fLevelUpHealthEndMult")
local FORTIFY_HEALTH = core.magic.EFFECT_TYPE.FortifyHealth

local function setHealth()
   local previousBaseHealth = health.base
   local previousCurrentHealth = health.current
   print(string.format("Old max health: %f", previousBaseHealth))
   print(string.format("Old current health: %f", previousCurrentHealth))

   enduranceState = endurance.modified
   strengthState = strength.modified
   levelState = level.current

   print(string.format("Endurance: %f", enduranceState))
   print(string.format("Strength: %f", strengthState))
   print(string.format("Level: %d", levelState))

   local newBaseHealth = ((enduranceState + strengthState) / 2)
      + ((levelState - 1) * F_LEVEL_UP_HEALTH_END_MULT * enduranceState)
   print(string.format("fLevelUpHealthEndMult GMST: %f", F_LEVEL_UP_HEALTH_END_MULT))
   print(string.format("New max health (per formula): %f", newBaseHealth))

   -- In Base Morrowind, potions increase current health, while spells increase maximum health
   -- MCP adds the option to have potions also increase maximum health
   -- OpenMW changes both effects to fortify current health while leaving maximum health alone
   local fortifyHealthMag = actor.activeEffects(self):getEffect(FORTIFY_HEALTH)

   -- Goofy ahh nil handling
   if fortifyHealthMag == nil then
      fortifyHealthMag = 0
   else
      fortifyHealthMag = fortifyHealthMag.magnitude
      newBaseHealth = newBaseHealth + fortifyHealthMag
   end

   print(string.format("Fortify Health magnitude: %f", fortifyHealthMag))

   newBaseHealth = math.max(newBaseHealth, conf:get("minBaseHealth"))
   print(string.format("Minimum max health setting: %f", conf:get("minBaseHealth")))
   print(string.format("New max health (taking into account minimum max health setting): %f", newBaseHealth))

   local newCurrentHealth
   if conf:get("maintainAbsoluteDifference") then
      local HealthDifference = previousBaseHealth - previousCurrentHealth
      newCurrentHealth = newBaseHealth - HealthDifference

      print(string.format("Maintaining difference. Difference: %f", HealthDifference))
      print(string.format("New current health: %f", newCurrentHealth))
   else
      local HealthRatio = health.current / health.base
      newCurrentHealth = newBaseHealth * HealthRatio

      print(string.format("Maintaining ratio. Ratio: %f", HealthRatio))
      print(string.format("New current health: %f", newCurrentHealth))
   end

   if fortifyHealthMag > 0 and not conf:get("maintainAbsoluteDifference") then
      print("There is a Fortify Health magnitude, and we are maintaining ratio. Adjusting new current health to compensate.")
      local previousCurrentHealthSansFortify = previousCurrentHealth - fortifyHealthMag

      local ratioSansFortify = previousCurrentHealthSansFortify / previousBaseHealth

      local currentHealthSansFortify = newBaseHealth * ratioSansFortify

      if previousCurrentHealthSansFortify >= 0 then
         newCurrentHealth = currentHealthSansFortify + fortifyHealthMag
      end
      print(string.format("Old current health would be without Fortify Health: %f", previousCurrentHealthSansFortify))
      print(string.format("Health ratio would be without Fortify Health: %f", ratioSansFortify))
      print(string.format("Current health needs to be when Fortify Health expires: %f", currentHealthSansFortify))
      print(string.format("New current health, taking into account Fortify Health: %f", newCurrentHealth))
   end

   health.base = newBaseHealth
   health.current = newCurrentHealth

end

return {
   engineHandlers = {
      onFrame = function()
         if health.current <= 0 then
            return
         end

         if
            endurance.modified == enduranceState
            and strength.modified == strengthState
            and level.current == levelState
         then
            return
         end

         setHealth()
      end,
   },
   eventHandlers = {
      loaded = function()
         print("LOADED")
         setHealth()
      end,
   },
}
