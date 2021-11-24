--Roblox's default time-out queues should be avoided at all cost since they can pull out save/load requests and cause issues

local Package = script.Parent.Parent.Parent

local Promise = require(Package.Dependencies.Promise)
local Settings = require(Package.Constants.Settings)

local function WaitForRobloxCooldown(Key)
	return Promise.delay(
		math.clamp(os.clock() - Key._LastAction.Time, Settings.RobloxCallCooldown, math.huge)
			- (os.clock() - Key._LastAction.Time)
	)
end

return WaitForRobloxCooldown
