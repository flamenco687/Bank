local Modules = {}

for _, Module in pairs(script:GetChildren()) do
    Modules[Module.Name] = require(Module)
end

return Modules