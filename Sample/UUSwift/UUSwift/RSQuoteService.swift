//
//  RSQuoteService.swift
//  UUSwift
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit
import UUToolbox

//
// Credit for this API:
// https://github.com/jamesseanwright/ron-swanson-quotes#ron-swanson-quotes-api
//
class RSQuoteService: NSObject
{
    public static let shared = RSQuoteService()
    
    private var baseUrl : String = "http://ron-swanson-quotes.herokuapp.com/v2/quotes"
    
    public func fetchQuotes(count: Int = 1, completion: @escaping (Error?) -> Void)
    {
        let endpoint = "\(baseUrl)/\(count)"
        
        UUHttpSession.get(endpoint, [:])
        { (response: UUHttpResponse) in
            
            if (response.httpError != nil)
            {
                completion(response.httpError)
            }
            else
            {
                let context = UUCoreData.workerThreadContext()!
                context.perform
                {
                    let list = response.parsedResponse as? [String]
                    
                    if (list != nil)
                    {
                        for quote in list!
                        {
                            // Hack a dictionary together for parsing examples
                            
                            var d : [String:Any] = [:]
                            d["quote"] = quote
                            d["downloadedAt"] = (NSDate() as Date).uuRfc3339String()
                            d["identifier"] = quote.hashValue
                            
                            _ = RSQuote.uuObjectFromDictionary(dictionary: d, context: context)
                        }
                    }
                    
                    _ = context.uuSubmitChanges()
                    
                    completion(nil)
                }
            }
        }
    }
}

