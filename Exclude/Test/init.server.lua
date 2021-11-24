--[[
	This script is used for testing purposes as a way to try out and execute
	module methods or debugging
]]

local Module = require(script.Bank)

local function Released(Key)
	print("Key: Released", Key)
end

local function Loaded(Key, IsSessionLocked)
	if IsSessionLocked then
		print("Key: Session is locked", Key)
		return
	end

	if type(Key) == "table" then
		print("Key: Successfully loaded", Key)

		Key:Reconcile()

		if Key.Data.Test ~= nil then
			Key.Data.Test += 10
		else
			Key.Data.Test = 0
		end
	end
end

local Store = Module.LoadStore("test_data_store", {DataTemplate = {Test = 1}})
print("Store:", Store)

local Key = Store:LoadKey("test_Key_37", {ForceLoad = true})

Key.Loaded:Connect(Loaded)
Key.Released:Connect(Released)