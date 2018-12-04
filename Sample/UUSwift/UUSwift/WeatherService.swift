//
//  WeatherService.swift
//  UUSwift
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit
import UUToolbox

class WeatherService: NSObject
{
    public static let shared = WeatherService()

    private var apiKey : String = "6a747114c9cf80cf4d2908053cb4f8c2"
    private var baseUrl : String = "http://api.openweathermap.org/data/2.5"
    
    public func fetchWeather(city: String, country: String, completion: @escaping (Error?) -> Void)
    {
        var queryArgs : [String:String] = [:]
        queryArgs["q"] = "\(city),\(country)"
        queryArgs["APPID"] = apiKey
        
        let endpoint = "\(baseUrl)/weather"
        
        UUHttpSession.get(endpoint, queryArgs)
        { (response: UUHttpResponse) in
        
            let context = UUCoreData.workerThreadContext()!
            context.perform
            {
                let parsed = WeatherRecord.uuObjectFromDictionary(
                    dictionary: (response.parsedResponse as? [AnyHashable:Any])!, context: context)
                
                print("Parsed object: \(String(describing: parsed))")
                
                _ = context.uuSubmitChanges()
                
                completion(nil)
            }
        }
    }
}
