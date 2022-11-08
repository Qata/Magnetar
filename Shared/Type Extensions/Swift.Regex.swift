public extension Regex where Output == (Substring, Substring) {
    static var url: Regex { #/((?:http(?:s)?)://(?:www\.)?[a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,63}\b(?:[-a-zA-Z0-9@:%_\+.~#?&//=]*))/#
    }
}
