local function SetProperty(self, Property: string, Value: any)
	local OldValue = self[Property]
	self[Property] = Value

	self._Signals.OnPropertyChanged:Fire(Property, Value, OldValue)
end

return SetProperty
