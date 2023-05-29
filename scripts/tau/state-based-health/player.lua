local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")

local playerStats = types.Actor.stats

local health = playerStats.dynamic.health(self)
local strength = playerStats.attributes.strength(self)
local endurance = playerStats.attributes.endurance(self)
local level = playerStats.level(self)

local fLevelUpHealthEndMult = core.getGMST("fLevelUpHealthEndMult")

local healthState = health.current
local strengthState = strength.modified
local enduranceState = endurance.modified
local levelState = level.current

local function setHealth()
	local oldBaseHealthState = health.base
	local oldCurrentHealthState = health.current

	enduranceState = endurance.modified
	strengthState = strength.modified
	levelState = level.current

	local baseHealth = ((enduranceState + strengthState) / 2)
		+ ((levelState - 1) * fLevelUpHealthEndMult * enduranceState)


end

return {
	engineHandlers = {
		onFrame = function()
			if health.current <= 0 then
				return
			end

			if
				health.current == strengthState
				and endurance.modified == enduranceState
				and strength.modified == strengthState
				and level.current == levelState
			then
				return
			end

			setHealth()
		end,
	},
}
