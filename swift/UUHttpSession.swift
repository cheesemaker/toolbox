//
//  UUHttpSession.swift
//  Useful Utilities - URLSession wrapper
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit

public enum UUHttpMethod : String
{
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
    case patch = "PATCH"
}

public enum UUHttpSessionError : Int
{
    // Returned when URLSession returns a non-nil error and the underlying
    // error domain is NSURLErrorDomain and the underlying error code is
    // NSURLErrorNotConnectedToInternet
    case noInternet = 0x1000
    
    // Returned when URLSession returns a non-nil error and the underlying
    // error domain is NSURLErrorDomain and the underlying error code is
    // NSURLErrorCannotFindHost
    case cannotFindHost = 0x1001
    
    // Returned when URLSession completion block returns a non-nil Error, and
    // that error is not specifically mapped to a more common UUHttpSessionError
    // In this case, the underlying NSError is wrapped in the user info block
    // using the NSUnderlyingError key
    case httpFailure = 0x2000
    
    // Returned when the URLSession completion block returns with a nil Error
    // and an HTTP return code that is not 2xx
    case httpError = 0x2001
    
    // Returned when a user cancels an operation
    case userCancelled = 0x2002
    
    // The request URL and/or query string parameters resulted in an invalid
    // URL.
    case invalidRequest = 0x2003
}

let UUHttpSessionErrorDomain           = "UUHttpSessionErrorDomain"
let UUHttpSessionHttpErrorCodeKey      = "UUHttpSessionHttpErrorCodeKey"
let UUHttpSessionHttpErrorMessageKey   = "UUHttpSessionHttpErrorMessageKey"
let UUHttpSessionAppResponseKey        = "UUHttpSessionAppResponseKey"

let kUUHttpDefaultTimeout : TimeInterval = 60.0

struct UUContentType
{
    static let applicationJson  = "application/json"
    static let textJson         = "text/json"
    static let textHtml         = "text/html"
    static let textPlain        = "text/plain"
    static let binary           = "application/octet-stream"
    static let imagePng         = "image/png"
    static let imageJpeg        = "image/jpeg"
}

struct UUHeader
{
    static let contentLength = "Content-Length"
    static let contentType = "Content-Type"
}

public class UUHttpRequest: NSObject
{
    public var url : String = ""
    public var httpMethod : UUHttpMethod = .get
    public var queryArguments : [String:String] = [:]
    public var headerFields : [String:String] = [:]
    public var body : Data? = nil
    public var bodyContentType : String? = nil
    public var timeout : TimeInterval = kUUHttpDefaultTimeout
    public var credentials : URLCredential? = nil
    public var processMimeTypes : Bool = true
    
    var startTime : TimeInterval = 0
    var httpRequest : URLRequest? = nil
    
    init(_ url : String)
    {
        super.init()
        
        self.url = url
    }
    
    static func getRequest(_ url : String, _ queryArguments : [String:String]) -> UUHttpRequest
    {
        let req = UUHttpRequest.init(url)
        req.httpMethod = .get
        req.queryArguments = queryArguments
        return req
    }
    
    static func deleteRequest(_ url : String, _ queryArguments : [String:String]) -> UUHttpRequest
    {
        let req = UUHttpRequest.init(url)
        req.httpMethod = .delete
        req.queryArguments = queryArguments
        return req
    }
    
    static func putRequest(_ url : String, _ queryArguments : [String:String], _ body : Data?, _ contentType : String?) -> UUHttpRequest
    {
        let req = UUHttpRequest.init(url)
        req.httpMethod = .put
        req.queryArguments = queryArguments
        req.body = body
        req.bodyContentType = contentType
        return req
    }
    
    static func postRequest(_ url : String, _ queryArguments : [String:String], _ body : Data?, _ contentType : String?) -> UUHttpRequest
    {
        let req = UUHttpRequest.init(url)
        req.httpMethod = .post
        req.queryArguments = queryArguments
        req.body = body
        req.bodyContentType = contentType
        return req
    }
    
    static func patchRequest(_ url : String, _ queryArguments : [String:String], _ body : Data?, _ contentType : String?) -> UUHttpRequest
    {
        let req = UUHttpRequest.init(url)
        req.httpMethod = .patch
        req.queryArguments = queryArguments
        req.body = body
        req.bodyContentType = contentType
        return req
    }
}

public class UUHttpResponse : NSObject
{
    public var httpError : Error? = nil
    public var httpRequest : UUHttpRequest? = nil
    public var httpResponse : HTTPURLResponse? = nil
    public var parsedResponse : Any?
    public var rawResponse : Data? = nil
    public var rawResponsePath : String = ""
    public var downloadTime : TimeInterval = 0
    
    init(_ request : UUHttpRequest, _ response : HTTPURLResponse?)
    {
        httpRequest = request
        httpResponse = response
    }
}

public protocol UUHttpResponseHandler
{
    var supportedMimeTypes : [String] { get }
    func parseResponse(_ data : Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
}

class UUTextResponseHandler : NSObject, UUHttpResponseHandler
{
    public var supportedMimeTypes: [String]
    {
        return [UUContentType.textHtml, UUContentType.textPlain]
    }
    
    public func parseResponse(_ data: Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
    {
        var parsed : Any? = nil
        
        var responseEncoding : String.Encoding = .utf8
        
        if (response.textEncodingName != nil)
        {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(response.textEncodingName as CFString!)
            responseEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
        }
        
        let stringResult : String? = String.init(data: data, encoding: responseEncoding)
        if (stringResult != nil)
        {
            parsed = stringResult
        }
        
        return parsed
    }
}

class UUBinaryResponseHandler : NSObject, UUHttpResponseHandler
{
    public var supportedMimeTypes: [String]
    {
        return [UUContentType.binary]
    }
    
    public func parseResponse(_ data: Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
    {
        return data
    }
}

class UUJsonResponseHandler : NSObject, UUHttpResponseHandler
{
    public var supportedMimeTypes: [String]
    {
        return [UUContentType.applicationJson, UUContentType.textJson]
    }
    
    public func parseResponse(_ data: Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
    {
        do
        {
            return try JSONSerialization.jsonObject(with: data, options: [])
        }
        catch (let err)
        {
            UUDebugLog("Error deserializing JSON: %@", String(describing: err))
        }
        
        return nil
    }
}

class UUImageResponseHandler : NSObject, UUHttpResponseHandler
{
    public var supportedMimeTypes: [String]
    {
        return [UUContentType.imagePng, UUContentType.imageJpeg]
    }
    
    public func parseResponse(_ data: Data, _ response: HTTPURLResponse, _ request: URLRequest) -> Any?
    {
        return UIImage.init(data: data)
    }
}

public class UUHttpSession: NSObject
{
    private var urlSession : URLSession? = nil
    private var sessionConfiguration : URLSessionConfiguration? = nil
    private var activeTasks : [URLSessionTask] = []
    private var responseHandlers : [String:UUHttpResponseHandler] = [:]
    
    public static let shared = UUHttpSession()
    
    required override public init()
    {
        super.init()
        
        sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration?.timeoutIntervalForRequest = kUUHttpDefaultTimeout
        
        urlSession = URLSession.init(configuration: sessionConfiguration!)
        
        installDefaultResponseHandlers()
    }
    
    private func installDefaultResponseHandlers()
    {
        registerResponseHandler(UUJsonResponseHandler())
        registerResponseHandler(UUTextResponseHandler())
        registerResponseHandler(UUBinaryResponseHandler())
        registerResponseHandler(UUImageResponseHandler())
    }
    
    private func registerResponseHandler(_ handler : UUHttpResponseHandler)
    {
        for mimeType in handler.supportedMimeTypes
        {
            responseHandlers[mimeType] = handler
        }
    }
    
    private func executeRequest(_ request : UUHttpRequest, _ completion: @escaping (UUHttpResponse) -> Void) -> UUHttpRequest
    {
        let httpRequest : URLRequest? = buildRequest(request)
        if (httpRequest == nil)
        {
            let uuResponse : UUHttpResponse = UUHttpResponse(request, nil)
            uuResponse.httpError = NSError.init(domain: UUHttpSessionErrorDomain, code: UUHttpSessionError.invalidRequest.rawValue, userInfo: nil)
            completion(uuResponse)
            return request
        }
        
        request.httpRequest = httpRequest!
        
        request.startTime = Date.timeIntervalSinceReferenceDate
        
        UUDebugLog("Begin Request\n\nMethod: %@\nURL: %@\nHeaders: %@)",
            String(describing: request.httpRequest?.httpMethod),
            String(describing: request.httpRequest?.url),
            String(describing: request.httpRequest?.allHTTPHeaderFields))
        
        if (request.body != nil)
        {
            if (UUContentType.applicationJson == request.bodyContentType)
            {
                UUDebugLog("JSON Body: %@", request.body!.uuToJsonString())
            }
            else
            {
                UUDebugLog("Raw Body: %@", request.body!.uuToHexString())
            }
        }
        
        let task = urlSession!.dataTask(with: request.httpRequest!)
        { (data : Data?, response: URLResponse?, error : Error?) in
            
            self.handleResponse(request, data, response, error, completion)
        }
        
        activeTasks.append(task)
        task.resume()
        return request
    }
    
    private func buildRequest(_ request : UUHttpRequest) -> URLRequest?
    {
        var fullUrl = request.url;
        if (request.queryArguments.count > 0)
        {
            fullUrl = "\(request.url)\(request.queryArguments.uuBuildQueryString())"
        }
        
        let url = URL.init(string: fullUrl)
        if (url == nil)
        {
            return nil
        }
        
        var req : URLRequest = URLRequest.init(url: url!)
        req.httpMethod = request.httpMethod.rawValue
        req.timeoutInterval = request.timeout
        
        for key in request.headerFields.keys
        {
            let val = request.headerFields[key]
            if (val != nil)
            {
                req.addValue(val!, forHTTPHeaderField: key)
            }
        }
        
        if (request.body != nil)
        {
            req.setValue(String.init(format: "%lu", request.body!.count), forHTTPHeaderField: UUHeader.contentLength)
            req.httpBody = request.body
            
            if (request.bodyContentType != nil && request.bodyContentType!.characters.count > 0)
            {
                req.addValue(request.bodyContentType!, forHTTPHeaderField: UUHeader.contentType)
            }
        }
        
        return req
    }
    
    private func handleResponse(
        _ request : UUHttpRequest,
        _ data : Data?,
        _ response : URLResponse?,
        _ error : Error?,
        _ completion: @escaping (UUHttpResponse) -> Void)
    {
        let httpResponse : HTTPURLResponse? = response as? HTTPURLResponse
        
        let uuResponse : UUHttpResponse = UUHttpResponse(request, httpResponse)
        uuResponse.rawResponse = data
        
        var err : Error? = nil
        var parsedResponse : Any? = nil
        
        var httpResponseCode : Int = 0
        
        if (httpResponse != nil)
        {
            httpResponseCode = httpResponse!.statusCode
        }
        
        UUDebugLog("Http Response Code: %d", httpResponseCode)
        
        if (error != nil)
        {
            UUDebugLog("Got an error: %@", String(describing: error!))
            
            var errCode : UUHttpSessionError = UUHttpSessionError.httpFailure
            
            let nsError = error! as NSError
            if (nsError.domain == NSURLErrorDomain as String)
            {
                switch (nsError.code)
                {
                    case NSURLErrorCannotFindHost:
                        errCode = .cannotFindHost
                    
                    case NSURLErrorNotConnectedToInternet:
                        errCode = .noInternet
                    
                    default:
                        errCode = UUHttpSessionError.httpFailure
                }
            }
            
            var userInfo : [AnyHashable : Any]  = [:]
            userInfo[NSUnderlyingErrorKey] = error
            err = NSError.init(domain: UUHttpSessionErrorDomain, code: errCode.rawValue, userInfo: userInfo)
        }
        else
        {
            if (request.processMimeTypes)
            {
                parsedResponse = parseResponse(request, httpResponse, data)
                if (parsedResponse is Error)
                {
                    err = (parsedResponse as! Error)
                    parsedResponse = nil
                }
            }
            
            if (!isHttpSuccessResponseCode(httpResponseCode))
            {
                var d : [AnyHashable:Any] = [:]
                d[UUHttpSessionHttpErrorCodeKey] = NSNumber(value: httpResponseCode)
                d[UUHttpSessionHttpErrorMessageKey] = HTTPURLResponse.localizedString(forStatusCode: httpResponseCode)
                d[UUHttpSessionAppResponseKey] = parsedResponse
                
                err = NSError.init(domain:UUHttpSessionErrorDomain, code:UUHttpSessionError.httpError.rawValue, userInfo:d)
            }
        }
        
        uuResponse.httpError = err;
        uuResponse.parsedResponse = parsedResponse;
        uuResponse.downloadTime = Date.timeIntervalSinceReferenceDate - request.startTime
        
        completion(uuResponse)
    }
    
    private func parseResponse(_ request : UUHttpRequest, _ httpResponse : HTTPURLResponse?, _ data : Data?) -> Any?
    {
        if (httpResponse != nil)
        {
            let httpRequest = request.httpRequest
            
            let mimeType = httpResponse!.mimeType
            
            UUDebugLog("Parsing response,\n%@ %@", String(describing: httpRequest?.httpMethod), String(describing: httpRequest?.url))
            UUDebugLog("Response Mime: %@", String(describing: mimeType))
            UUDebugLog("Raw Response: %@", String(describing: String.init(data: data!, encoding: .utf8)))
            
            if (mimeType != nil)
            {
                let handler : UUHttpResponseHandler? = responseHandlers[mimeType!]
                if (handler != nil && data != nil && httpRequest != nil)
                {
                    let parsedResponse = handler!.parseResponse(data!, httpResponse!, httpRequest!)
                    return parsedResponse
                }
            }
        }
        
        return nil
    }
    
    private func isHttpSuccessResponseCode(_ responseCode : Int) -> Bool
    {
        return (responseCode >= 200 && responseCode < 300)
    }
    
    public static func executeRequest(_ request : UUHttpRequest, _ completion: @escaping (UUHttpResponse) -> Void)
    {
        _ = shared.executeRequest(request, completion)
    }
    
    public static func get(_ url : String, _ queryArguments : [String:String], _ completion: @escaping (UUHttpResponse) -> Void)
    {
        let req = UUHttpRequest.getRequest(url, queryArguments)
        executeRequest(req, completion)
    }
    
    public static func delete(_ url : String, _ queryArguments : [String:String], _ completion: @escaping (UUHttpResponse) -> Void)
    {
        let req = UUHttpRequest.deleteRequest(url, queryArguments)
        executeRequest(req, completion)
    }
    
    public static func put(_ url : String, _ queryArguments : [String:String], _ body: Data?, _ contentType : String?, _ completion: @escaping (UUHttpResponse) -> Void)
    {
        let req = UUHttpRequest.putRequest(url, queryArguments, body, contentType)
        executeRequest(req, completion)
    }
    
    public static func post(_ url : String, _ queryArguments : [String:String], _ body: Data?, _ contentType : String?, _ completion: @escaping (UUHttpResponse) -> Void)
    {
        let req = UUHttpRequest.postRequest(url, queryArguments, body, contentType)
        executeRequest(req, completion)
    }
    
    public static func registerResponseHandler(_ handler : UUHttpResponseHandler)
    {
        shared.registerResponseHandler(handler)
    }
}
