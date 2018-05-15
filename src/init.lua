local BUILTIN_TYPE_NAMES = {
	"string", "number", "table", "boolean",
	"coroutine", "userdata",
	"Axes", "BrickColor", "CFrame", "Color3",
	"ColorSequence", "ColorSequenceKeypoint",
	"Faces", "Instance", "NumberRange",
	"NumberSequence", "NumberSequenceKeypoint",
	"PhysicalProperties", "Ray", "Rect",
	"Region3", "Region3int16", "TweenInfo",
	"UDim", "UDim2", "Vector2", "Vector3",
	"Vector3int16", "Enum", "EnumItem"
}

local PropTypes = {}

for _, typeName in pairs(BUILTIN_TYPE_NAMES) do
	PropTypes[typeName] = function(value)
		local valueType = typeof(value)

		return valueType == typeName, ("expected type %q, got type %q"):format(typeName, valueType)
	end
end

function PropTypes.userdata(value)
	return type(value) == "userdata", ("expected type \"userdata\", got type %q"):format(typeof(value))
end

--[[
	Creates a validator that checks if all its supplied validator functions
	affirm the value.
]]
function PropTypes.all(...)
	local validators = { ... }

	return function(value)
		for _, validator in ipairs(validators) do
			local success, failureReason = validator(value)

			if not success then
				return false, failureReason
			end
		end

		return true
	end
end

--[[
	Creates a validator that checks if any of its supplied validator functions
	affirm the value.
]]
function PropTypes.any(...)
	local validators = { ... }

	return function(value)
		for _, validator in ipairs(validators) do
			local success, _ = validator(value)

			if success then
				return true
			end
		end

		return false, ("No validators affirmed the value %q"):format(tostring(value))
	end
end

--[[
	Returns a new validator function that behaves identically to the original,
	but allows `nil` to be passed through.
]]
function PropTypes.optional(inner)
	return function(value)
		-- Specifically check for nil to avoid cases where "false" is not allowed
		if value == nil then
			return true
		else
			return inner(value)
		end
	end
end

return PropTypes
