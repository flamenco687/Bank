local SharedInfo = {
	LoadedStores = {}, --List of all loaded DataStores. Loaded stores cannot be unloaded
	LoadedKeys = {}, --List of all DataStores' loaded keys

	ServiceLocked = false,

	KeysToAutosave = {}, --List of keys to automatically save
	AutosaveEnabled = true,
	AutosaveRefreshLocks = false,

	LastAutosave = os.clock(),
	LastLockRefresh = os.clock(),

	IssueQueue = {},

	--When a Key fails to save or load due to an API Error it is added to a low priority queue
	--which will retry the request later when no other keys are trying to be saved to avoid
	--overbooking and keys taking long to save for no reason.
}

return SharedInfo
