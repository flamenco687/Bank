local Package = script

local DataStoreService = game:GetService("DataStoreService")

local TableUtil = require(Package.Dependencies.TableUtil)
local Promise = require(Package.Dependencies.Promise)
local Signal = require(Package.Dependencies.Signal)
local Error = require(Package.Dependencies.Error)
local Maid = require(Package.Dependencies.Maid)
local DefaultMetadata = require(Package.Constants.Metadata)
local Settings = require(Package.Constants.Settings)
local Utility = require(Package.Utility)
local Global = require(Package.Global)
local SaveKeyWithUpdateAsync = require(Package.ServiceRequests.UpdateAsync.SaveKey)

local Store = require(script.Classes.Store)

local ServiceLocked = Global.ServiceLocked
local AutosaveEnabled = Global.AutosaveEnabled

local Bank = {}

function Bank.GetStore(LoadedStore: string)
    return Global.LoadedStores[LoadedStore]
end

function Bank.LoadStore(LoadedStore: string | table, Options: table?)
    if ServiceLocked then
        Error.warn("Tried to load store while service was locked")

        return "ServiceLocked"
    end

    LoadedStore = (type(LoadedStore) == "string" or type(LoadedStore) == "table") and LoadedStore or Error.new("LoadedStore must be a string or table")

    local StoreName = LoadedStore
    local StoreScope

    Options = Options or {}
    Options = type(Options) == "table" and Options or Error.new("Options must be a table")

    if type(LoadedStore) == "table" then
        StoreName = LoadedStore[1]
        StoreScope = LoadedStore[2]
    end

    if StoreName == nil or type(StoreName) ~= "string" or string.len(StoreName) <= 0 then
        Error.new("StoreName must be a string longer than 0")
    end
    if StoreScope ~= nil and (type(StoreScope) ~= "string" or string.len(StoreScope) <= 0) then
        Error.new("StoreScope must be a string longer than 0")
    end

    if not AutosaveEnabled and Options.AutosaveAllowed then
        Options.AutosaveAllowed = false
    end

    local self = setmetatable({
        _Name = StoreName,
        _Scope = StoreScope,
        _Index = StoreName.."/nil",

        _DataTemplate = Options.DataTemplate or {},
        _MetadataTemplate = TableUtil.Reconcile(DefaultMetadata, Options.MetadataTemplate or {}),

        _IsPending = false,
        _AutosaveAllowed = Options.AutosaveAllowed or AutosaveEnabled,

        _Maid = Maid.new(),
        _Promises = {},
        _Signals = {
            OnPropertyChanged = Signal.new(),

            OnKeyLoaded = Signal.new(),
            OnKeyReleased = Signal.new(),
            OnKeyPropertyChanged = Signal.new()
        },

        _GlobalDataStore = nil,
        _LoadedKeys = {},
    }, Store)

    if StoreScope then
        self._Index = StoreName.."/"..StoreScope
    end

    if Global.LoadedStores[self._Index] then
        Error.warn("Requested Store already exists", StoreName, StoreScope)

        LoadedStore = self._Index

        setmetatable(self, nil)
        self = nil

        return Global.LoadedStores[LoadedStore]
    end

    self._GlobalDataStore = DataStoreService:GetDataStore(StoreName, StoreScope)
    Global.LoadedStores[self._Index] = self

    return self
end

local function AutosaveKeys()
    for _, LoadedStore in pairs(Global.LoadedStores) do
        Promise.new(function(Resolve)
            Utility.Await.PropertyValue(LoadedStore, "_IsPending", false):await()
            LoadedStore:_Set("_IsPending", true)

            for _, Key in pairs(Global.KeysToAutosave) do
                Key._Core.LastLockRefreshTime = os.time()

                Promise.retry(SaveKeyWithUpdateAsync, 100, Key)
            end

            LoadedStore:_Set("_IsPending", false)

            Resolve(#Global.KeysToAutosave)
        end)
    end

    Global.LastAutosave = os.time()
end

local function RefreshLocks()
    for _, Key in pairs(Global.LoadedKeys) do
        Key._Core.LastLockRefreshTime = os.time()

        Promise.retry(SaveKeyWithUpdateAsync, 100, Key, {DontSaveData = true})
    end

    Global.LastLockRefresh = os.time()
end

do
    task.spawn(function()
        while true do
            AutosaveKeys()
            task.wait(Settings.AutosaveCooldown)
        end
    end)

    Global.AutosaveRefreshLocks = Settings.AutosaveCooldown <= (Settings.AssumeDeadSessionLock * .9)

    if not Global.AutosaveRefreshLocks then
        task.spawn(function()
            RefreshLocks()
            task.wait(Settings.AssumeDeadSessionLock * .9)
        end)
    end
end

local function GameClosing()
    --TODO: better handling of the keys and stores when game closes
    ServiceLocked = true
end

game:BindToClose(GameClosing)

return Bank