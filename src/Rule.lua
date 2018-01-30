local function copyTable(original)
    local new = {}

    for key, value in pairs(original) do
        new[key] = value
    end

    return new
end

local ruleMetatable = {}

ruleMetatable.__index = function(self, key)
    local value = ruleMetatable[key]

    if value then
        if typeof(value) == "function" then
            return ruleMetatable[key](self)
        else
            return value
        end
    end
end

ruleMetatable["optional"] = function(self)
    local copy = copyTable(self)
    copy._optional = true

    return setmetatable(copy, ruleMetatable)
end

local Rule = {}

function Rule.fromPrototype(prototype)
    return setmetatable(prototype, ruleMetatable)
end

function Rule.fromMultiple(...)
    return Rule.fromPrototype({
        type = "union",
        rules = { ... }
    })
end

function Rule.fromComposite(...)
    return Rule.fromPrototype({
        type = "composite",
        rules = { ... }
    })
end

function Rule.fromFunction(func)
    return Rule.fromPrototype({
        type = "custom",
        validator = func
    })
end

function Rule.fromTypeName(typeName)
    return Rule.fromPrototype({
        type = "simple",
        expectedType = typeName
    })
end

function Rule.fromShape(shape)
    return Rule.fromPrototype({
        type = "shape",
        shape = shape
    })
end

return Rule
