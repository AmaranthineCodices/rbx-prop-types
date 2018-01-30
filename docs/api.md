# API Reference

## PropTypes functions

### validate
    boolean, string? PropTypes.validate(props, propTypes, options)

Validates `props` against the rules in `propTypes`, with options specified by `options`.

* `props`: A table of values to validate.
* `propTypes`: A table of rules to validate the values in `props` against.
* `options`: A table of options to use when validating.
    * `options.strict`: Whether to error if a key in `props` has no rule associated with it.

Returns `true` if validation succeeded. Returns `false` plus a string explaining why if validation failed. This function will never throw errors; if it does, please report the bug.

You can use `validate` in `assert` to error if the validation fails; the message supplied will be automatically thrown with the error.

### apply
    [function|table] PropTypes.apply(component, propTypes, options)

Returns a wrapped component that validates its props against `propTypes` whenever they change.

* `component`: A Roact stateful or functional component.
* `propTypes`: A table of rules to validate the `props` table against.
* `options`: A table of options to use when validating. Has the same structure as `options` in `validate` above.

!!! caution
    This function does not support primitive components (TextLabel, ImageLabel, ...) and will throw an error when supplied with one. Wrap the primitive component in another component instead.

!!! danger
    This function currently performs type checking *all the time*. This will change when Roact's debug status becomes visible. In the meantime, please refrain from using this in high-performance code like animations.

## Rules
PropTypes supplies a large assortment of rules by default.

### Primitive types
PropTypes allows you to check if a value's type is equal to any primitive type, including Roblox-specific ones:

```lua
{
    -- Checks if the value is a string.
    Value = PropTypes.string,
    -- Checks if the value is a Vector3.
    Value2 = PropTypes.Vector3,
}
```

!!! note
    Because `function` is a Lua keyword, you need to use `PropTypes.func` to check if a value is a function.

### Optional rules
By default, all rules are **required**. To make them optional you must index their `optional` property, like so:

```lua
{
    -- Checks if the value is a string, while allowing it to be nil.
    Value = PropTypes.string.optional,
}
```

### enumOf
To check if a value is an EnumItem of a specific Enum, you can use `PropTypes.enumOf`:

```lua
{
    -- Checks if the value is an EnumItem of the Font enum.
    Value = PropTypes.enumOf(Enum.Font),
}
```

### ofClass
If you're expecting an Instance, it can be useful to specify the instance's class name. You can do this with `PropTypes.ofClass`:

```lua
{
    -- Checks if the value is an instance descended from GuiObject.
    Value = PropTypes.ofClass("GuiObject"),
}
```

### tableOf
If you want to guarantee that all the values in the table match the rule, you can use `PropTypes.tableOf`:

```lua
{
    -- Checks if the value is a table composed solely of numbers.
    Value = PropTypes.tableOf(PropTypes.number)
}
```

### shape
Checking if a value is a table is useful in and of itself, but for more complex tables you might want to check that its *shape* is correct, too. This can be done with `PropTypes.shape`:

```lua
{
    Value = PropTypes.shape({
        -- Check that the value contains a Key1 key with a number...
        Key1 = PropTypes.number,
        -- ...and a Key2 key with a string...
        Key2 = PropTypes.string,
        -- ...and a Key3 key with a BasePart.
        Key3 = PropTypes.ofClass("BasePart"),
    })
}
```

### oneOf
If you make your own enums, `enumOf` may not be too useful. You can validate that a value is one of several possibilities with `PropTypes.oneOf`:

```lua
{
    -- Checks if the value is either SomeValue or SomeOtherValue.
    Value = PropTypes.oneOf({ "SomeValue", "SomeOtherValue" })
}
```

### element
If you want to make sure that a value is a Roact element as returned by `Roact.createElement`, you can use `PropTypes.element`:

```lua
{
    -- Checks if the value is a Roact element.
    Value = PropTypes.element,
}
```

### Custom rules
You can create a custom rule by just using a function as a rule. The function should return true or false, and if it returns false it should return a reason for the failure:

```lua
{
    -- Checks if the value is even.
    -- This assumes it's a number. Check out 'chaining rules' below!
    Value = function(value)
        return value % 2 == 0, ("%d was not even"):format(value)
    end,
}
```

### Union rules
You can say that a value can be one of many types by using `PropTypes.matchesAny`:

```lua
{
    -- Checks if the value is a string or a number.
    Value = PropTypes.matchesAny(
        PropTypes.string,
        PropTypes.number
    )
}
```

This function is more general than its React contemporary `oneOfType`. It allows matching on *any* arbitrary rule, making constructs like this possible:

```lua
{
    -- Checks if the value is either a function or an EnumItem of SortOrder.
    Value = PropTypes.matchesAny(
        PropTypes.func,
        PropTypes.enumOf(Enum.SortOrder)
    )
}
```

### Chaining rules
PropTypes allows you to combine rules together with `PropTypes.matchesAll`. The returned rule will only validate if the value passes *all* the rules:

```lua
{
    -- Checks if the value is both a number *and* an even number.
    Value = PropTypes.matchesAll(
        PropTypes.number,
        function(value)
            return value % 2 == 0, ("%d was not even"):format(value)
        end
    )
}
```