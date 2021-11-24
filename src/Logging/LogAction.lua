local function LogAction(Key: table, Options: table?)
	local Log = {
		FunctionName = debug.info(2, "n"),
		FunctionTime = os.time(),

		Key = Key._Name,
		Store = Key._Store._Index,
		Options = Options or {},

		Success = false,
		IsSessionLocked = false,
	}

	return Log
end

return LogAction
