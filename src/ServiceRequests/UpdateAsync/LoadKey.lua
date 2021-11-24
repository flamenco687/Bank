local Package = script.Parent.Parent.Parent

local TableUtil = require(Package.Dependencies.TableUtil)
local Promise = require(Package.Dependencies.Promise)
local Proxy = require(Package.Dependencies.Proxy)
local Error = require(Package.Dependencies.Error)
local Settings = require(Package.Constants.Settings)
local Core = require(Package.Constants.Core)
local LogAction = require(Package.Logging.LogAction)
local Utility = require(Package.Utility)
local Global = require(Package.Global)

local function LoadKeyWithUpdateAsync(Key: table, Options: table?)
    Options = Options or {}
    Options = type(Options) == "table" and Options or Error.new("Options should be a table")

    local Store = Key._Store
    local Action = LogAction(Key, Options)

    local Success, KeyData, KeyInfo

    return Utility.Promise.List(Key, Promise.new(function(Resolve, Reject, OnCancel)
        local function UpdateAsyncCallback(OldKeyData, OldKeyInfo)
            local NewKeyData, NewKeyInfo, NewKeyUserIds, NewKeyMetadata

            NewKeyData = OldKeyData or {Data = Store._DataTemplate, Core = Core}
            NewKeyInfo = OldKeyInfo

            if NewKeyInfo == nil then -- Newly created keys won't have a DataStoreKeyInfo
                NewKeyMetadata = Store._MetadataTemplate
                NewKeyUserIds = {}
            else
                NewKeyMetadata = NewKeyInfo:GetMetadata() or Store._MetadataTemplate
                NewKeyUserIds = NewKeyInfo:GetUserIds() or {}
            end

            local CorruptionLog

            CorruptionLog, NewKeyData, NewKeyUserIds, NewKeyMetadata = Utility.Corruption.Find(Key, NewKeyData, NewKeyUserIds, NewKeyMetadata)
            Action = TableUtil.Reconcile(Action, CorruptionLog)

            if not Options.ForceLoad and NewKeyData.Core.LastLockRefreshTime > 0 then
                local IsDeadLock = (os.time() - NewKeyData.Core.LastLockRefreshTime) >= Settings.AssumeDeadSessionLock

                if IsDeadLock then
                    NewKeyData.Core.LastLockRefreshTime = os.time()
                else
                    Action.IsSessionLocked = true

                    return nil, NewKeyUserIds, NewKeyMetadata --Returning nil for UpdateAsync will make the Key data stay the same as before
                end
            else
                NewKeyData.Core.LastLockRefreshTime = os.time() --The Key LastLockRefreshTime will always be refreshed even if it was ForceLoaded
            end

            if typeof(Options.UserIds) == "table" then
                for Index, _ in ipairs(Options.UserIds) do
                    for _, UserIds in ipairs(NewKeyUserIds) do
                        if Options.UserIds[Index] == UserIds then
                            table.remove(Options.UserIds, Index)
                        end
                    end
                end

                for _, UserIds in ipairs(Options.UserIds) do
                    table.insert(NewKeyUserIds, UserIds)
                end
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

        if Action.IsSessionLocked then --There's no need to check if the call succeded if there's an active session lock
            Key.Loaded:Fire(Key, true)

            setmetatable(Key, nil)
            Key = nil

            Resolve(Action, KeyData, KeyInfo)
        end

        Key.Data = Proxy.new(KeyData.Data)
        Key.Metadata = KeyInfo:GetMetadata()
        Key._UserIds = KeyInfo:GetUserIds()
        Key._Core = KeyData.Core

        if Key._ShouldAutosave and Key._Store._AutosaveAllowed then
            Global.KeysToAutosave[Key._Index] = Key
        end

        Key._Store._LoadedKeys[Key._Name] = Key
        Global.LoadedKeys[Key._Index] = Key

        Key.Loaded:Fire(Key, false)
        Key.Loaded:Destroy()
        Key.Loaded = true

        Resolve(Action, KeyData, KeyInfo)
    end))
end

return LoadKeyWithUpdateAsync