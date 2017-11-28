//
//  DBWeatherRecord+CoreDataProperties.swift
//  UUSwift
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import Foundation
import CoreData

extension WeatherRecord : UUObjectFactory
{
    static func uuObjectFromDictionary(dictionary : [AnyHashable:Any], context: Any?) -> Self?
    {
        return uuObjectFromDictionaryInternal(dictionary: dictionary, context: context)
    }
    
    private static func uuObjectFromDictionaryInternal<T>(dictionary : [AnyHashable:Any], context: Any?) -> T?
    {
        var obj : T? = nil
        
        if (context != nil && context is NSManagedObjectContext)
        {
            let moc = context as! NSManagedObjectContext
            moc.performAndWait
            {
                let predicate = primaryKeyPredicate(dictionary: dictionary)
                if (predicate != nil)
                {
                    let o = uuFetchOrCreate(predicate: predicate!, context: moc)
                    o.fillFromDictionary(dictionary)
                    obj = o as? T
                }
            }
        }
        
        return obj
    }
    
    private static func primaryKeyPredicate(dictionary: [AnyHashable:Any]) -> NSPredicate?
    {
        let primaryKeyValue = dictionary["id"] as? Int
        if (primaryKeyValue != nil)
        {
            return NSPredicate(format: "identifier = %@", NSNumber(value: primaryKeyValue!))
        }
        else
        {
            return nil
        }
    }

    private func fillFromDictionary(_ dictionary: [AnyHashable:Any])
    {
        if let coord = dictionary["coord"] as? [AnyHashable:Any]
        {
            latitude = coord["lat"] as! Double
            longitude = coord["lon"] as! Double
        }
        
        let weatherArray = dictionary["weather"] as? [[AnyHashable:Any]]
        if (weatherArray != nil && weatherArray!.count > 0)
        {
            let weather = weatherArray![0]
            weatherMain = weather["main"] as? String
            weatherDescription = weather["description"] as? String
            weatherIcon = weather["icon"] as? String
        }
        
        let main = dictionary["main"] as? [AnyHashable:Any]
        if (main != nil)
        {
            temperature = kelvinToCelsius(main!["temp"] as! Double)
            pressure = main!["pressure"] as! Double
            humidity = main!["humidity"] as! Double
            minTemperature = kelvinToCelsius(main!["temp_min"] as! Double)
            maxTemperature = kelvinToCelsius(main!["temp_max"] as! Double)
        }
        
        visibility = dictionary["visibility"] as! Double
        
        let wind = dictionary["wind"] as? [AnyHashable:Any]
        if (wind != nil)
        {
            windSpeed = wind!["speed"] as! Double
            windDirection = wind!["deg"] as! Double
        }
        
        let cloud = dictionary["cloud"] as? [AnyHashable:Any]
        if (cloud != nil)
        {
            cloudPercent = cloud!["all"] as! Double
        }
        
        timestamp = Date(timeIntervalSince1970: dictionary["dt"] as! Double)
        
        city = dictionary["name"] as? String
        
        let sys = dictionary["sys"] as? [AnyHashable:Any]
        if (sys != nil)
        {
            sunriseTime = Date(timeIntervalSince1970: sys!["sunrise"] as! Double)
            sunsetTime = Date(timeIntervalSince1970: sys!["sunset"] as! Double)
        }
        
        print("Filled from dictionary: \(self)")
    }

    override public var description: String
    {
        return "\(toDictionary().uuToJsonString())"
    }
    
    public func toDictionary() -> [String:Any]
    {
        var json : [String:Any] = [:]
        
        json["latitude"] = latitude
        json["longitude"] = longitude
        json["weatherMain"] = weatherMain
        json["weatherDescription"] = weatherDescription
        json["weatherIcon"] = weatherIcon
        json["temperature"] = temperature
        json["pressure"] = pressure
        json["humidity"] = humidity
        json["temp_min"] = minTemperature
        json["temp_max"] = maxTemperature
        json["visibility"] = visibility
        json["windSpeed"] = windSpeed
        json["windDirection"] = windDirection
        json["cloudPercent"] = cloudPercent
        json["timestamp"] = (timestamp as Date?)?.uuRfc3339String()
        json["city"] = city
        json["sunriseTime"] = (sunriseTime as Date?)?.uuRfc3339String()
        json["sunsetTime"] = (sunsetTime as Date?)?.uuRfc3339String()
        
        return json
    }
    
    private func kelvinToCelsius(_ kelvinTemp: Double) -> Double
    {
        return kelvinTemp - 273.15
    }
}
