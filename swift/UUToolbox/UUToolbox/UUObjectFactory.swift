//  UUObjectFactory
//  Useful Utilities - Helpful methods for Converting Objects
//  to and from dictionaries
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit

public protocol UUObjectFactory
{
    static func uuObjectFromDictionary(dictionary : [AnyHashable:Any], context: Any?) -> Self?
}
