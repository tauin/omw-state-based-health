-- Copyright (c) 2023 Johannes Richard Levi Dickenson
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

local I = require("openmw.interfaces")
I.Settings.registerGroup({
	key = "omwStateBasedHealth",
	page = "StateBasedHealth",
	l10n = "state_based_health",
	name = "My Group Name",
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
			name = "Minimum Max Health",
		},
	},
})
