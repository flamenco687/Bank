local Signal = require(script.Parent.Signal)

--[=[
    @class Proxy

    Simple class designed to work as a proxy for tables. The proxy also
    fires signals when something new is being added to the table or in
    case a table's value is being indexed.
    ```lua
    local proxy = Proxy.new()

    proxy.Changed:Connect(function(key, value)
        print(key, value)
    end)

    proxy.test = 10 -- This would print out: test 10
    ```
]=]
local Proxy = {}
Proxy.__index = Proxy

--- @prop Proxy table
--- @within Proxy

--- @prop Indexed Signal
--- @within Proxy

--- @prop Changed Signal
--- @within Proxy

--[=[
    Creates a new Proxy class.

    @param origin table -- The table which the proxy will be created for
    @return Proxy
]=]
function Proxy.new(origin: table): table
	local proxy = {
        Proxy = origin or {},
        Indexed = Signal.new(),
        Changed = Signal.new(),
    }

	return setmetatable(proxy, Proxy)
end

--[=[
    Kill the proxy and disconnect all connections.

    @return nil
]=]
function Proxy:Kill()
    self.Indexed:DisconnectAll()
    self.Changed:DisconnectAll()

    self = nil
end

--[=[
    Fires an internal signal when a value is indexed

    @private
    @return any
]=]
function Proxy:__index(key: string): any
    local value = self.Proxy[key]

    self.Indexed:Fire(key, value)

	return value
end

--[=[
    Fires an internal signal when a new value is indexed

    @private
    @return nil
]=]
function Proxy:__newindex(key: string, value: any)
	local currentValue = self.Proxy[key]

	if currentValue ~= value then
		self.Proxy[key] = value
	end

    self.Changed:Fire(key, value)
end

return Proxy