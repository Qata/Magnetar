/// The type used to build expressions from if/else and switch statements. You should rarely, if at all, have to interact with this type, unless you are creating your own function/type which takes a closure tagged with `@ExpressionBuilder<Value>`.
/// The generic `Value` type is the one returned by the tagged closure.
/// See the documentation for `expression(_:)` for an example on turning if/else and switch statements into expressions.
@resultBuilder public enum ExpressionBuilder<Value> {
    public static func buildBlock(_ components: Value...) -> Value {
        return components.first!
    }

    public static func buildEither(first component: Value) -> Value {
        return component
    }

    public static func buildEither(second component: Value) -> Value {
        return component
    }
}

/// Turns an if/else or switch statement into an expression
/// - Parameter value: A closure which contains an if/else or switch statement
///
/// There is no need to put a "return" before the value.
/// For example:
/// ```
/// let number = 10
///
/// let fizzBuzz = expression {
///     switch (number % 3 == 0, number % 5 == 0) {
///     case (true, false): "Fizz"
///     case (false, true): "Buzz"
///     case (true, true): "FizzBuzz"
///     case (false, false): String(number)
///     }
/// }
/// ```
public func expression<Value>(@ExpressionBuilder<Value> _ value: () -> Value) -> Value {
    return value()
}

public func expression<Value>(_: Value.Type, @ExpressionBuilder<Value> _ value: () -> Value) -> Value {
    return value()
}
