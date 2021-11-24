--[[
	Roblox library to quickly throw out clean & detailed errors
]]

function GetMainSource(Source) -- Hacky way to get the main source name using debug.info's option "s". Helps making logs cleaner
    local LastFoundDot

    for Index = 1, string.len(Source) do
        local PossibleDot = string.sub(Source, Index, Index)

        if PossibleDot == "." then
            LastFoundDot = Index
        end
    end

    return string.sub(Source, LastFoundDot + 1, string.len(Source))
end

function LogUsingString(Message, LogType)
    LogType = type(LogType) == "string" and LogType or LogUsingString("LogType must be a string", "error")
    Message = type(Message) == "string" and Message or LogUsingString("Message must be a string", "error")

    local Level = 3 -- Level at which functions should run, primarly used to exclude this module from the traceback

    Message = "\n\n[%s]: "..Message.."\n%s\nCPU Time: %s"

    local Traceback = debug.traceback("", Level)
    local Clock = tostring(os.clock())

    local Source = GetMainSource(debug.info(Level, "s"))

    if LogType == "error" then
        error(Message.format(Message, Source, Traceback, Clock), Level)
    elseif LogType == "warn" then
        warn(Message.format(Message, Source, Traceback, Clock), Level)
    else
        LogUsingString("LogType is not a valid log type", "warn")
    end
end

local Error = {}

function Error.new(ErrorMessage)
    LogUsingString(ErrorMessage, "error")
end

function Error.warn(WarnMessage)
    LogUsingString(WarnMessage, "warn")
end

return Error