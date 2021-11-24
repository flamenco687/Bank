return {
	LastLockRefreshTime = 0, --Time [seconds] from last SessionLock refresh, 0 means that no SessionLock is active. Some keys can ignore SessionLock

	RecentlyCorrupted = false, --Was the latest release corrupted?
	RecentlyWiped = false, --Is the Key loading for the first time after a wipe?
	EverWiped = false, --Was the Key ever wiped?
}
