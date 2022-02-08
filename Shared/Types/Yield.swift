func yield<T>(_ closure: () throws -> T) rethrows -> T {
    try closure()
}
