local Package = script.Parent.Parent

local TableUtil = require(Package.Dependencies.TableUtil)
local Promise = require(Package.Dependencies.Promise)
local Error = require(Package.Dependencies.Error)
local Settings = require(Package.Constants.Settings)
local Utility = require(Package.Utility)
local Global = require(Package.Global)
local SaveKeyWithUpdateAsync = require(Package.ServiceRequests.UpdateAsync.SaveKey)

local Key = {
	--[[
        _Name = Key,
        _UserIds = {},
        Metadata = {},
        _Store = self,

        _LastActionTime = 0,
        _LastActionLog = {},
        _IsPending = false,

        _ShouldAutosave = Options.AutosaveEnabled or true,

        Data = {}
    --]]
}
Key.__index = Key

function Key:_Set(Property: string, Value: any?)
	Utility.SetProperty(self, Property, Value)
end

function Key:RemoveUserIds(UserIds: table)
	UserIds = type(UserIds) == "table" and UserIds or Error.new("UserIds must be a table")

	Utility.Await.PropertyValue(self, "_IsPending", false)

	for Index = 1, #UserIds do
		for Number = 1, #self._UserIds do
			if self._UserIds[Number] == UserIds[Index] then
				table.remove(self._UserIds, Number)
			end
		end
	end
end

function Key:AddUserIds(UserIds: table)
	UserIds = type(UserIds) == "table" and UserIds or Error.new("UserIds must be a table")

	return Utility.Promise.List(
		self,
		Utility.Await.PropertyValue(self, "_IsPending", false):andThen(function(Resolve)
			self:_Set("_IsPending", true)

			for Index = 1, #UserIds do
				table.insert(self._UserIds, UserIds[Index])
			end

			self:_Set("_IsPending", false)

			Resolve()
		end)
	)
end

function Key:Toggleautosave(Autosave: boolean)
	if not Global.AutosaveEnabled then
		return "Autosave is globally disabled"
	end

	if self._Store._AutosaveEnabled == false then
		return "Autosave is disabled for Key's Store"
	end

	Autosave = type(Autosave) == "boolean" and Autosave or Error.new("Autosave must be a boolean")

	if self._ShouldAutosave == Autosave then
		return "Nothing changed"
	end

	return Utility.Promise.List(
		self,
		Promise.new(function(Resolve, _, OnCancel)
			if Autosave == true then
				Global.KeysToAutosave[self._Index] = self
				self._ShouldAutosave = true
			else
				Global.KeysToAutosave[self._Index] = nil
				self._ShouldAutosave = false
			end

			Resolve("Autosave state succesfully changed")

			OnCancel(function()
				Global.KeysToAutosave[self._Index] = nil
				self._ShouldAutosave = false
			end)
		end)
	)
end

function Key:Release(Options: table?)
	Options = Options or {}
	Options = type(Options) and Options or Error.new("Options must be a table")

	local Store = self._Store
	local MaxRetries = Options.MaxRetries or math.clamp((Settings.AssumeDeadSessionLock / 100), 50, 10 ^ 3)

	if not Global.LoadedKeys[self._Index] then
		return Promise.resolve(true)
	end

	Global.KeysToAutosave[self._Index] = nil
	Global.LoadedKeys[self._Index] = nil
	Store._LoadedKeys[self._Index] = nil

	return Promise.retry(SaveKeyWithUpdateAsync, MaxRetries, self, Options, true)
end

function Key:Save(Options: table?)
	Options = Options or {}
	Options = type(Options) and Options or Error.new("Options must be a table")

	return Promise.retry(SaveKeyWithUpdateAsync, Options.MaxRetries or math.huge, self, Options)
end

function Key:Reconcile()
	return TableUtil.Reconcile(self.Data.Proxy, self._Store._DataTemplate)
end

return Key
