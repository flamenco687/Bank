--[[
    Looks for missing or corrupted Key's data values and corrects them
]]

local Package = script.Parent.Parent.Parent

local Error = require(Package.Dependencies.Error)
local Core = require(Package.Constants.Core)

local function Find(Key: table, KeyData: table, KeyUserIds: table, KeyMetadata: table)
    --To consider a key as corrupted the key's data, userids or metadata must be from a different type
    --than the intended one or core values must be missing (they're essential for running the module)

    --i.e.: type(KeyData) should always return "table", no matter if it is empty or not.

    local CorruptionLog = {
        IsKeyCorrupted = false,
        CorruptedData = {}
    }

    local MetadataTemplate = Key._Store._MetadataTemplate or {}
    local DataTemplate = Key._Store._DataTemplate or {}

    local function MarkAsCorrupted(CorruptedKey, Value, NewValue, ArgumentToReplace)
        CorruptionLog.CorruptedData[CorruptedKey] = Value or "[nil]"

        if not NewValue then
            return -- Function was called only to mark something as corrupted, correcting values is already being handled by other function
        end

        if ArgumentToReplace then
            ArgumentToReplace = NewValue
        else
            Value = NewValue
        end
    end

    if type(KeyData) ~= "table" then
        MarkAsCorrupted("Data", KeyData, {Data = Key._Store._DefaultData, Core = Core})
    else
        if type(KeyData.Data) ~= "table" then
            MarkAsCorrupted("Data", KeyData, KeyData.Data, DataTemplate)
        end

        if type(KeyData.Core) ~= "table" then
            MarkAsCorrupted("Data", KeyData, KeyData.Core, Core)
        else
            local NoPreviousCorruption = true

            for CoreKey, CoreValue in pairs(Core) do
                local ValueToCheck = KeyData.Core[CoreKey]

                if type(ValueToCheck) ~= type(CoreValue) then
                    if NoPreviousCorruption then
                        MarkAsCorrupted("Data", KeyData)
                        NoPreviousCorruption = false
                    end

                    KeyData.Core[CoreKey] = CoreValue
                end
            end
        end
    end

    if type(KeyUserIds) ~= "table" then
        MarkAsCorrupted("UserIds", KeyUserIds, {})
    end

    if type(KeyMetadata) ~= "table" then
        MarkAsCorrupted("Metadata", KeyMetadata, MetadataTemplate)
    else
        local NoPreviousCorruption = true

        for TemplateKey, TemplateValue in pairs(MetadataTemplate) do
            local ValueToCheck = KeyMetadata[TemplateKey]

            if type(ValueToCheck) ~= type(TemplateValue) then
                if NoPreviousCorruption then
                    MarkAsCorrupted("Metadata", KeyMetadata)
                    NoPreviousCorruption = false
                end

                KeyMetadata[TemplateKey] = TemplateValue
            end
        end
    end

    for _, Value in pairs(CorruptionLog.CorruptedData) do
        if Value then -- Keys will only be added to the dic when a corrupted value is found
            CorruptionLog.IsKeyCorrupted = true

            Error.warn("Found corrupt or missing data for a key", Key, CorruptionLog)
            break
        end
    end

    return CorruptionLog, KeyData, KeyUserIds, KeyMetadata
end

return Find