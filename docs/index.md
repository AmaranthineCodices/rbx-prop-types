rbx-prop-types is a Roblox version of React's [prop-types](github.com/facebook/prop-types) library. It allows for robust type checking across a table. Here's a quick example:

```lua
local rules = {
    requiredString = PropTypes.string,
    optionalString = PropTypes.string.optional,
    shaped = PropTypes.shape {
        num = PropTypes.number,
        udim = PropTypes.UDim,
        sub = PropTypes.shape {
            a = PropTypes.string,
            b = PropTypes.boolean
        }
    }
}

local data = {
    requiredString = "hello, world!",
    -- optionalString not specified - it's optional!
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
assert(PropTypes.validate(data, rules))
```

rbx-prop-types was built for validating [Roact](https://github.com/Roblox/roact) property tables, and with that in mind, it's super easy to plug into a Roact component. Just call `PropTypes.apply` with your component and rules, and it'll give you a wrapped component.