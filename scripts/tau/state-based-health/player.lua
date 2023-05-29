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
local StrengthState = strength.current
local EnduranceState = endurance.current
local LevelState = level.current

local function setHealth()
	local oldBaseHealthState = health.base
	local oldCurrentHealthState = health.current

	EnduranceState = endurance.current
	StrengthState = strength.current
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
				and endurance.current == EnduranceState
				and strength.current == StrengthState
				and level.current == LevelState
			then
				return
			end

			setHealth()
		end,
	},
}
