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

--[[
	A validator function that checks if you can index into the value.
	Does not check if you can *successfully* index into the value with a
	specific key, but does make sure that you're not going to try to index into
	a number or string!
]]
local indexable = PropTypes.any(
	PropTypes.table,
	PropTypes.userdata
)

--[[
	Creates a validator function that checks if a value matches a given shape.
]]
function PropTypes.object(shape)
	return PropTypes.all(
		indexable,
		function(value)
			for key, keyValidator in pairs(shape) do
				local subValue = value[key]
				local success, failureReason = keyValidator(subValue)

				if not success then
					return false, ("the key %q failed:\n\t%s"):format(failureReason)
				end
			end

			return true
		end
	)
end

--[[
	Creates a validator that checks if a value is an EnumItem of a particular
	Enum.
]]
function PropTypes.enumOf(enum)
	return PropTypes.all(
		PropTypes.EnumItem,
		function(value)
			return value.EnumType == enum, ("the EnumItem %q belongs to the %q Enum, not the %q Enum"):format(
				tostring(value),
				tostring(value.EnumType),
				tostring(enum)
			)
		end
	)
end

function PropTypes.ofClass(className)
	return PropTypes.all(
		PropTypes.Instance,
		function(value)
			return value:IsA(className)
		end
	)
end

return PropTypes
