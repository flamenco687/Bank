local Settings = {
    AssumeDeadSessionLock = 60, --Time [seconds] at which a Session Lock is considered dead even if it shows as active

    AutosaveCooldown = 60, --Time in seconds between autosaves
    RobloxCallCooldown = 7, --Time in seconds that have to pass between successive calls to the DataStoreService API
    RequestBudgetRefreshRate = 2, --Time in seconds that have to pass between GetRequestBudget calls

    IssueCountForCriticalState = 5, --Number of active issue reports needed to consider the service status as critical
    CorruptionCountForWarning = 10, --Number of recent corruption reports needed to warn about a serious problem
    CorruptionCountRefreshRate = 120, --Time in seconds at which the service state refreshes
}

return Settings