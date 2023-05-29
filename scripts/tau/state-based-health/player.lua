local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local store = require("openmw.storage")
local conf = store.playerSection('omwStateBasedHealth')

if conf:get("maintainDifference") == nil then
   conf:set("maintainDifference", false)
end
if conf:get("minBaseHealth") == nil then
   conf:set("minBaseHealth", 0)
end

local playerStats = types.Actor.stats

local health = playerStats.dynamic.health(self)
local strength = playerStats.attributes.strength(self)
local endurance = playerStats.attributes.endurance(self)
local level = playerStats.level(self)

local fLevelUpHealthEndMult = core.getGMST("fLevelUpHealthEndMult")

local strengthState = strength.modified
local enduranceState = endurance.modified
local levelState = level.current

local function setHealth()
	local oldBaseHealthState = health.base
	local oldCurrentHealthState = health.current

	enduranceState = endurance.modified
	strengthState = strength.modified
	levelState = level.current

	local newBaseHealth = ((enduranceState + strengthState) / 2)
		+ ((levelState - 1) * fLevelUpHealthEndMult * enduranceState)

   local fortifyHealthMag = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.FortifyHealth)

   newBaseHealth = newBaseHealth + fortifyHealthMag

   local newCurrentHealth
   if conf:get("maintainDifference") then
      local diff = oldBaseHealthState - oldCurrentHealthState
      newCurrentHealth = newBaseHealth - diff
   else
      local ratio = health.current / health.base
      newCurrentHealth = newBaseHealth * ratio
   end

   if fortifyHealthMag > 0 and not conf:get("maintainDifference") then
      local currentHealthWouldBe = oldCurrentHealthState - fortifyHealthMag

      local ratioWouldBe = currentHealthWouldBe / oldBaseHealthState

      local currentHealthWillbe = newBaseHealth * ratioWouldBe

      if currentHealthWouldBe >= 0 then
         newCurrentHealth = currentHealthWillbe + fortifyHealthMag
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

			if endurance.modified == enduranceState
				and strength.modified == strengthState
				and level.current == levelState
			then
				return
			end

			setHealth()
		end,
	},
}
