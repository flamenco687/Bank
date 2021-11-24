local Modules = {}

for _, Collection in pairs(script:GetChildren()) do
	Modules[Collection.Name] = require(Collection)
end

return Modules
