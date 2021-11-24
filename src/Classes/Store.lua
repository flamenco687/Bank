local Package = script.Parent.Parent

local Promise = require(Package.Dependencies.Promise)
local Signal = require(Package.Dependencies.Signal)
local Error = require(Package.Dependencies.Error)
local Maid = require(Package.Dependencies.Maid)
local Utility = require(Package.Utility)
local Global = require(Package.Global)
local LoadKeyWithUpdateAsync = require(Package.ServiceRequests.UpdateAsync.LoadKey)

local Key = require(Package.Classes.Key)

local Store = {
	--[[
        _Name = Name of the data Store
        _Scope = Scope of the data Store (optional)
        _Index = StoreName/StoreScope
        _DefaultData = Options.Template or {},

        _IsPending = false,
        _AutosaveEnabled = Options.AutosaveEnabled or true,

        _GlobalDataStore = nil,
        LoadedKeys = {}
    --]]
}
Store.__index = Store

function Store:_Set(Property: string, Value: any?)
	Utility.SetProperty(self, Property, Value)
end

function Store:ToggleAutosave(Autosave: boolean)
	if not Global.AutosaveEnabled then
		return "Autosave is globally disabled"
	end

	return Utility.Promise.List(
		self,
		Utility.Await.PropertyValue(self, "_IsPending", false):andThen(function()
			self:_Set("_IsPending", true)
			self:_Set("_AutosaveAllowed", Autosave)

			if Autosave then
				for _, LoadedKey in pairs(self._LoadedKeys) do
					if LoadedKey._ShouldAutosave then
						Global.KeysToAutosave[LoadedKey._Index] = LoadedKey
					end
				end
			else
				for _, LoadedKey in pairs(self._LoadedKeys) do
					Global.KeysToAutosave[LoadedKey._Index] = nil
				end
			end

			self:_Set("_IsPending", false)
		end)
	)
end

function Store:GetKey(Index: string)
	return self._LoadedKeys[Index]
end

function Store:LoadKey(Index: table | string, Options: table?)
	if Global.ServiceLocked then
		return nil, { ErrorMessage = "ServiceLocked" }
	end

	Options = Options or {}
	Options = type(Options) == "table" and Options or Error.new("Options must be a table")

	Index = (type(Index) == "string" and string.len(Index) > 0) and Index
		or Error.new("Index must be a string longer than 0")

	if self._LoadedKeys[Index] then -- No new data keys should be loaded if they already exist in a server
		Error.warn("Requested key was already loaded")
		return self._LoadedKeys[Index]
	end

	self = setmetatable({
		Loaded = Signal.new(),
		Released = Signal.new(),

		Data = {},
		Metadata = {},

		_Name = Index,
		_Index = Index .. "/" .. self._Index,
		_Store = self,

		_UserIds = {},

		_LastAction = {
			Time = 0,
			Log = {},
		},

		_IsPending = false,
		_ShouldAutosave = Options.ShouldAutosave or self._AutosaveAllowed,

		_Maid = Maid.new(),
		_Promises = {},
		_Signals = {
			OnPropertyChanged = Signal.new(),
		},
	}, Key)

	Promise.retry(LoadKeyWithUpdateAsync, math.huge, self, Options)

	return self
end

return Store
