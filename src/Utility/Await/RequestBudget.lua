local Package = script.Parent.Parent.Parent

local DataStoreService = game:GetService("DataStoreService")

local Settings = require(Package.Constants.Settings)

local function WaitForRequestBudget(RequestType)
	local CurrentBudget = DataStoreService:GetRequestBudgetForRequestType(RequestType)

	while CurrentBudget < 1 do
		task.wait(Settings.RequestBudgetRefreshRate)
		CurrentBudget = DataStoreService:GetRequestBudgetForRequestType(RequestType)
	end

	CurrentBudget = nil
end

return WaitForRequestBudget
