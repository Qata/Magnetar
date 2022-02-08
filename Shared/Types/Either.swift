enum Either<Left, Right> {
    case left(Left)
    case right(Right)
    
    var left: Left? {
        switch self {
        case let .left(value):
            return value
        case .right:
            return nil
        }
    }

    var right: Right? {
        switch self {
        case let .right(value):
            return value
        case .left:
            return nil
        }
    }
}

extension Either: Codable where Left: Codable, Right: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let id = try? container.decode(Left.self) {
            self = .left(id)
        } else {
            self = try .right(container.decode(Right.self))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .left(value):
            try container.encode(value)
        case let .right(value):
            try container.encode(value)
        }
    }
}

extension Either {
    func mapLeft<NewLeft>(_ transform: (Left) -> NewLeft) -> Either<NewLeft, Right> {
        switch self {
        case let .left(value):
            return .left(transform(value))
        case let .right(value):
            return .right(value)
        }
    }

    func mapRight<NewRight>(_ transform: (Right) -> NewRight) -> Either<Left, NewRight> {
        switch self {
        case let .left(value):
            return .left(value)
        case let .right(value):
            return .right(transform(value))
        }
    }
}

extension Either where Left == Right {
    var value: Right {
        switch self {
        case let .left(value):
            return value
        case let .right(value):
            return value
        }
    }
}
