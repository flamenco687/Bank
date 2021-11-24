local Package = script.Parent.Parent.Parent

local TableUtil = require(Package.Dependencies.TableUtil)
local Promise = require(Package.Dependencies.Promise)
local Error = require(Package.Dependencies.Error)
local Core = require(Package.Constants.Core)
local LogAction = require(Package.Logging.LogAction)
local Utility = require(Package.Utility)

local function SaveKeyWithUpdateAsync(Key: table, Options: table?, ShouldRelease: boolean?)
	ShouldRelease = ShouldRelease or false

	if type(ShouldRelease) ~= "boolean" then
		Error.error("ShouldRelease must be a boolean")
	end

	Options = Options or {}
	Options = type(Options) == "table" and Options or Error.new("Options must be a table")

	local Store = Key._Store
	local Action = LogAction(Key, Options)

	local Success, KeyData, KeyInfo

	return Utility.Promise.List(
		Key,
		Promise.new(function(Resolve, Reject)
			Options = Options or {}

			if type(Key) ~= "table" or Key._Name == nil then
				error("[Bank]: SaveKeyWithUpdateAsync(), Key must be a Key")
			end
			if type(Options) ~= "table" then
				error("[Bank]: SaveKeyWithUpdateAsync(), Options must be a table")
			end

			Utility.Await.PropertyValue(Key, "_IsPending", false):await()

			Utility.SetProperty(Key, "_IsPending", true)

			local function UpdateAsyncCallback(OldKeyData)
				local NewKeyData, NewKeyMetadata, NewKeyUserIds

				NewKeyData = { Data = Key.Data.Proxy, Core = OldKeyData.Core or Core }
				NewKeyMetadata = Key.Metadata
				NewKeyUserIds = Key._UserIds

				local CorruptionLog

				CorruptionLog, NewKeyData, NewKeyUserIds, NewKeyMetadata = Utility.Corruption.Find(
					Key,
					NewKeyData,
					NewKeyUserIds,
					NewKeyMetadata
				)
				Action = TableUtil.Reconcile(Action, CorruptionLog)

				if ShouldRelease then
					NewKeyData.Core.LastLockRefreshTime = 0
				else
					NewKeyData.Core.LastLockRefreshTime = os.time()
				end

				if Options.DontSaveData then
					NewKeyData = nil
				end

				return NewKeyData, NewKeyUserIds, NewKeyMetadata
			end

			Utility.Await.RobloxCooldown(Key):await()
			Utility.Await.RequestBudget(Enum.DataStoreRequestType.UpdateAsync)

			Success, KeyData, KeyInfo = pcall(function()
				return Store._GlobalDataStore:UpdateAsync(Key._Name, UpdateAsyncCallback)
			end)

			Action.Success = Success

			Key._LastAction.Time = os.clock()
			Key._LastAction.Log = Action

			if not Success then
				Action.ErrorMessage = KeyData
				Reject(Action)
			end

			if ShouldRelease then --Key should not be accesible during its release
				Key.Released:Fire(Key)
			else
				Utility.SetProperty(Key, "_IsPending", false)
			end

			Resolve(Action, KeyData, KeyInfo)
		end)
	)
end

return SaveKeyWithUpdateAsync
