import MonadicJSON
import SwiftXMLRPC

struct ResponseParseError: Error, CustomStringConvertible {
    let response: StructuredResponse
    let expected: Payload.StructuredResponse

    var description: String {
        String("Expected \(expected) but encountered \(response)")
    }
}

struct XMLResponseParseError: Error, CustomStringConvertible {
    let xml: XMLRPC.Response
    let expected: Payload.XMLRPC.Response

    var description: String {
        String("Expected \(expected) but encountered \(xml)")
    }
}

struct XMLRPCError: Error, CustomStringConvertible {
    let code: Int32
    let fault: String
    
    var description: String {
        """
        XMLRPC Error
        Code: \(code)
        Description: \(fault)
        """
    }
}
