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

local function round(number, digit_position)
   local pow = 10 ^ digit_position
   return math.floor(number * pow + 0.5) / pow
end

local function setHealth()
   local priorBaseHealth = health.base
   local priorCurrentHealth = health.current

   enduranceState = endurance.modified
   strengthState = strength.modified
   levelState = level.current

   local newBaseHealth = ((enduranceState + strengthState) / 2)
      + ((levelState - 1) * F_LEVEL_UP_HEALTH_END_MULT * enduranceState)

   local fortifyHealthMagnitude = actor.activeEffects(self):getEffect(FORTIFY_HEALTH)

   -- Goofy ahh nil handling
   if fortifyHealthMagnitude == nil then
      fortifyHealthMagnitude = 0
   else
      fortifyHealthMagnitude = fortifyHealthMagnitude.magnitude
   end

   newBaseHealth = math.max(newBaseHealth, conf:get("minBaseHealth"))

   local newCurrentHealth
   if conf:get("maintainAbsoluteDifference") then
      local HealthDifference = priorBaseHealth - priorCurrentHealth
      newCurrentHealth = newBaseHealth - HealthDifference
   else
      local HealthRatio = round((health.current / health.base), 2)
      newCurrentHealth = newBaseHealth * HealthRatio
   end

   if fortifyHealthMagnitude > 0 and not conf:get("maintainAbsoluteDifference") then
      local priorCurrentHealthSansFortify = priorCurrentHealth - fortifyHealthMagnitude

      local ratioSansFortify = priorCurrentHealthSansFortify / priorBaseHealth
      local currentHealthSansFortify = newBaseHealth * ratioSansFortify

      if priorCurrentHealthSansFortify >= 0 then
         newCurrentHealth = currentHealthSansFortify + fortifyHealthMagnitude
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
         setHealth()
      end,
   },
}
