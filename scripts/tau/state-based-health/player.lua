local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")

local actor_stats = types.Actor.stats
local getEffect = types.ActorActiveEffects.getEffect()

local health = actor_stats.dynamic.health(self)
local strength = actor_stats.attributes.strength(self)
local endurance = actor_stats.attributes.endurance(self)
local level = actor_stats.level(self)

local fLevelUpHealthEndMult = require("openmw.core").getGMST("fLevelUpHealthEndMult")

local HealthState = health.current
local StrengthState = strength.modified
local EnduranceState = endurance.modified
local LevelState = level.current

local function setHealth()
	local oldBaseHealthState = health.base
	local oldCurrentHealthState = health.current

	EnduranceState = endurance.modified
	StrengthState = strength.modified
	LevelState = level.current

	local baseHealth = ((EnduranceState + StrengthState) / 2)
		+ ((LevelState - 1) * fLevelUpHealthEndMult * EnduranceState)


end

return {
	engineHandlers = {
		onFrame = function()
			if health.current <= 0 then
				return
			end

			if
				health.current == StrengthState
				and endurance.modified == EnduranceState
				and strength.modified == StrengthState
				and level.current == LevelState
			then
				return
			end

			setHealth()
		end,
	},
}
