--[[
    Adds passed promise to a list containing all active promises of a Key or Store.
    When a promise finishes, it is removed from the list. Mainly used for cancellations.
]]

local function List(self, PromiseToList)
    local Index = tostring(debug.info(2, "n"))

    if not self._Promises[Index] then
        self._Promises[Index] = {}
    end

    self._Promises[Index][PromiseToList] = {Promise = PromiseToList, Time = os.time()}

    PromiseToList:finallyCall(function()
        self._Promises[Index][PromiseToList] = nil

        if #self._Promises[Index] <= 0 then
            self._Promises[Index] = nil
        end
    end)

    return PromiseToList
end

return List