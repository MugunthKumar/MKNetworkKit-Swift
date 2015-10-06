//
//  Request.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 15/6/15.
//  Copyright © 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation

public enum ParameterEncoding : String, CustomStringConvertible {

  case URL = "URL"
  case JSON = "JSON"

  public var description : String { return self.rawValue }
}

public enum State : String, CustomStringConvertible {

  case Ready = "Ready"
  case Started = "Started"
  case ResponseAvailableFromCache = "ResponseAvailableFromCache"
  case StaleResponseAvailableFromCache = "StaleResponseAvailableFromCache"
  case Cancelled = "Cancelled"
  case Completed = "Completed"
  case Error = "Error"

  public var description : String { return self.rawValue }
}

public enum HTTPMethod : String, CustomStringConvertible {

  case GET = "GET"
  case POST = "POST"
  case PUT = "PUT"
  case DELETE = "DELETE"
  case PATCH = "PATCH"
  case OPTIONS = "OPTIONS"
  case TRACE = "TRACE"
  case CONNECT = "CONNECT"

  public var description : String { return self.rawValue }
}

public class Request {

  public var url: String
  public var method: HTTPMethod = .GET
  public var parameters: [String:AnyObject]?
  public var headers: [String:String]?
  public var parameterEncoding : ParameterEncoding

  public var files: [String:String]?
  public var blobs: [String:NSData]?
  public var bodyData: NSData?

  public var task : NSURLSessionTask?

  public var username : NSString?
  public var password : NSString?

  public var downloadPath : NSString?
  public var requiresAuthentication : Bool = false
  public var isSSL : Bool = false

  public var doNotCache : Bool = false
  public var alwaysCache : Bool = false
  public var ignoreCache : Bool = false
  public var alwaysLoad : Bool = false


  public var state : State {

    didSet {

      switch (state) {

      case .Ready:
        break

      case .Started:
        task?.resume()

      case .Completed:
        fallthrough
      case .Error:
        for handler in completionHandlers {
          handler(self)
        }

      case .Cancelled:
        task?.cancel()

      default:
        break
      }
    }
  }

  var request : NSURLRequest? {
    var finalUrl : String
    switch(method) {
    case .GET, .DELETE, .CONNECT, .TRACE:
      finalUrl = url + (parameters?.URLEncodedString)!
    case .POST, .PUT, .PATCH, .OPTIONS:
      finalUrl = url
    }

    guard let nsurl = NSURL(string: finalUrl) else {return nil}

    let urlRequest = NSMutableURLRequest(URL: nsurl)
    urlRequest.HTTPMethod = method.description

    for (headerField, headerValue) in headers! {
      urlRequest.addValue(headerValue, forHTTPHeaderField: headerField)
    }

    if [.POST, .PUT, .PATCH, .OPTIONS].contains(method) {
      urlRequest.HTTPBody = parameters?.URLEncodedString.dataUsingEncoding(NSUTF8StringEncoding)
    }
    return urlRequest
  }

  var responseData : NSData?
  var response : NSHTTPURLResponse?
  var error : NSError?

  public var completionHandlers = Array<(Request) -> Void>()

  init(method: HTTPMethod = .GET,
    url: String,
    parameters: [String:AnyObject]? = [:],
    headers: [String:String]? = [:],
    files: [String:String]? = [:],
    blobs: [String:NSData]? = [:],
    bodyData: NSData? = nil) {

      parameterEncoding = .URL
      state = .Ready

      self.url = url
      self.method = method;
      self.parameters = parameters;
      self.headers = headers
      self.files = files
      self.blobs = blobs
      self.bodyData = bodyData
  }
  
  public var description : String {
    var displayString = "curl -X \(method) '\(self.url)' -H " +
      headers!.map {"'\($0):\($1)'"}.joinWithSeparator(" -H ")

    if [.POST, .PUT, .PATCH, .OPTIONS].contains(method) {
      if let actualData = request?.HTTPBody {
        displayString += "-d '\(String(data:actualData, encoding:NSUTF8StringEncoding))'"
      }
    }
    return displayString
  }

  public var responseAsJSON : AnyObject? {
    guard let responseData : NSData = responseData else { return nil }
    do {
      let jsonObject = try NSJSONSerialization.JSONObjectWithData(responseData, options: .MutableLeaves)
      return jsonObject
    } catch {
      print("Error parsing as JSON")
      return nil
    }
  }
}