local Package = script.Parent.Parent.Parent

local Promise = require(Package.Dependencies.Promise)

local function WaitForPropertyValue(self, DesiredProperty: string, DesiredValue: any)
	return Promise.new(function(Resolve, _, OnCancel)
		if self[DesiredProperty] == DesiredValue then
			Resolve()
		end

		local Connection

		Connection = self._Maid:Add(self._Signals.OnPropertyChanged:Connect(function(Property, NewValue)
			if Property == DesiredProperty and NewValue == DesiredValue then
				self._Maid:End(Connection)
				Resolve()
			end
		end))

		OnCancel(function()
			self._Maid:End(Connection)
		end)
	end)
end

return WaitForPropertyValue
