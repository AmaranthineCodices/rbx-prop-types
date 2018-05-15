local PropTypes = require(game.ReplicatedStorage.PropTypes)

local validator = PropTypes.object {
    requiredString = PropTypes.string,
    optionalString = PropTypes.optional(PropTypes.string),
    shaped = PropTypes.object {
        num = PropTypes.number,
        udim = PropTypes.UDim,
        sub = PropTypes.object {
            a = PropTypes.string,
            b = PropTypes.boolean
        }
    }
}

local someData = {
    requiredString = "hello, world!",
    -- optionalString not specified - it's optional!
    -- this shouldn't be here and will cause validation to fail in strict mode!
    unknown = 1,

    shaped = {
        num = 1,
        udim = UDim.new(0, 1),
        sub = {
            a = "hi",
            b = 1,
        }
    },
}

-- you can use `assert` to throw errors when validation fails
assert(validator(someData))
