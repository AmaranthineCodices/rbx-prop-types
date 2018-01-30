local Rule = require(script.Rule)

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

local function valueMatches(value, rule)
	-- For non-table rules:
	-- string: match as typeof(value) == rule
	-- function: match as rule(value) == true
	if typeof(rule) == "string" then
		local valueType = typeof(value)

		if valueType ~= rule then
			return false, ("expected %s, got %s"):format(
				rule,
				valueType
			)
		end

		return true
	elseif typeof(rule) == "function" then
		return rule(value)
	elseif typeof(rule) ~= "table" then
		error(("Rules of type %s are not supported!"):format(typeof(rule)))
	end

	local ruleType = rule.type

	-- Explicitly compare to nil instead of using `not value` to avoid
	-- false-negatives when the value is false
	if value == nil and not rule.optional then
		return false, "value is not optional"
	end

	-- The "simple" rule type checks if typeof(value) == expectedType.
	-- This is a duplicate of the string rule match above; the sole difference
	-- is that this supports optional values.
	if ruleType == "simple" then
		local valueType = typeof(value)
		local matches = valueType == rule.expectedType

		if matches then
			return true
		else
			return false, ("expected %s, got %s"):format(rule.expectedType, valueType)
		end
	-- The "union" rule type checks if the value matches one of several rules.
	elseif ruleType == "union" then
		for _, subRule in ipairs(rule.rules) do
			if valueMatches(value, subRule) then
				return true
			end
		end

		return false, ("the %s %q did not match any rule"):format(typeof(value), tostring(value))
	-- The "composite" rule type checks if the value matches all rules.
	elseif ruleType == "composite" then
		for _, subRule in ipairs(rule.rules) do
			local success, failureReason = valueMatches(value, subRule)

			if not success then
				return false, failureReason
			end
		end

		return true
	-- The "shape" rule type checks if the value matches a defined 'shape'.
	elseif ruleType == "shape" then
		-- DO NOT check if typeof(value) == "table" to allow userdata types.
		for key, keyRule in pairs(rule.shape) do
			local keyValue = value[key]

			local success, failureReason = valueMatches(keyValue, keyRule)

			if not success then
				return false, ("the key %q with value %q failed the shape rule assigned to it\n%s"):format(
					tostring(key),
					tostring(keyValue),
					failureReason
				)
			end
		end

		return true
	-- The "custom" rule type checks if the value matches an arbitrary function.
	elseif ruleType == "custom" then
		return rule.validator(value)
	end
end

local PropTypes = {}

for _, typeName in ipairs(BUILTIN_TYPE_NAMES) do
	PropTypes[typeName] = Rule.fromTypeName(typeName)
end

function PropTypes.ofClass(className)
	return Rule.fromComposite(
		PropTypes.Instance,
		function(value)
			return value:IsA(className), ("expected an instance of %s, got %s"):format(
				className,
				value.ClassName
			)
		end
	)
end

PropTypes.func = Rule.fromTypeName("function")
PropTypes.matchesAll = Rule.fromComposite
PropTypes.matchesAny = Rule.fromMultiple
PropTypes.shape = Rule.fromShape

PropTypes.enumOf = function(enum)
	return Rule.fromComposite(
		PropTypes.EnumItem,
		Rule.fromFunction(function(value)
			return value.EnumType == enum, ("EnumItem %s is not a member of the %s Enum"):format(
				tostring(value),
				tostring(enum)
			)
		end)
	)
end

PropTypes.element = Rule.fromComposite(
	PropTypes.table,
	Rule.fromFunction(function(value)
		return value.isElement == true, "table is not a Roact element"
	end)
)

PropTypes.oneOf = function(possibilities)
	return Rule.fromFunction(function(value)
		for _, possibility in pairs(possibilities) do
			if possibility == value then
				return true
			end
		end

		return false, ("the %s %q was not any of the possible values"):format(
			typeof(value),
			tostring(value)
		)
	end)
end

PropTypes.tableOf = function(rule)
	return Rule.fromComposite(
		PropTypes.table,
		Rule.fromFunction(function(value)
			for key, subValue in pairs(value) do
				if not valueMatches(subValue, rule) then
					return false, ("the %s %q at key %q did not match the rule"):format(
						typeof(subValue),
						tostring(subValue),
						tostring(key)
					)
				end
			end
		end)
	)
end

function PropTypes.validate(props, propTypes, options)
	options = options or {}
	local strictMode = options.strict

	for key, value in pairs(props) do
		local rule = propTypes[key]

		if not rule and strictMode then
			return false, ("the key %q does not have a rule associated with it (strict mode is ON)"):format(
				tostring(key)
			)
		end

		if rule then
			local success, failureReason = valueMatches(value, rule)

			if not success then
				return false, ("the key %q failed for %s %q\n%s"):format(
					tostring(key),
					typeof(value),
					tostring(value),
					failureReason
				)
			end
		end
	end

	return true
end

function PropTypes.apply(component, rules, options)
	-- TODO: Do not wrap if Roact's debug mode is disabled.
	-- Currently impossible - Roact doesn't expose the debug status.

	-- Primitive components aren't supported by PropTypes.
	if typeof(component) == "string" then
		error("Primitive components are not supported!", 0)
	-- Functional components can be simply wrapped.
	elseif typeof(component) == "function" then
		return function(props)
			assert(PropTypes.validate(props, rules, options))
			return component(props)
		end
	-- Stateful components need to be mutated.
	-- TODO: investigate possibility of copying component?
	elseif typeof(component) == "table" then
		local originalInit = component.init
		local originalWillUpdate = component.willUpdate

		component.init = function(self, props)
			assert(PropTypes.validate(props, rules, options))
			originalInit(self, props)
		end

		component.willUpdate = function(self, props)
			assert(PropTypes.validate(props, rules, options))
			originalWillUpdate(self, props)
		end

		return component
	else
		error(("Components of type %s are not supported")):format(typeof(component), 0)
	end
end

return PropTypes
