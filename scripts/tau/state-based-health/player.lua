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

   enduranceState = endurance.modified
   strengthState = strength.modified
   levelState = level.current

   local newBaseHealth = ((enduranceState + strengthState) / 2)
      + ((levelState - 1) * F_LEVEL_UP_HEALTH_END_MULT * enduranceState)

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

   newBaseHealth = math.max(newBaseHealth, conf:get("minBaseHealth"))

   local newCurrentHealth
   if conf:get("maintainAbsoluteDifference") then
      local HealthDifference = previousBaseHealth - previousCurrentHealth
      newCurrentHealth = newBaseHealth - HealthDifference
   else
      local HealthRatio = health.current / health.base
      newCurrentHealth = newBaseHealth * HealthRatio
   end

   if fortifyHealthMag > 0 and not conf:get("maintainAbsoluteDifference") then
      local previousCurrentHealthSansFortify = previousCurrentHealth - fortifyHealthMag

      local ratioSansFortify = previousCurrentHealthSansFortify / previousBaseHealth

      local currentHealthWithFortify = newBaseHealth * ratioSansFortify

      if previousCurrentHealthSansFortify >= 0 then
         newCurrentHealth = currentHealthWithFortify + fortifyHealthMag
      end
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
