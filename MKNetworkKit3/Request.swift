//
//  Request.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 15/6/15.
//  Copyright © 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation

enum ParameterEncoding : String, CustomStringConvertible {

  case URL = "URL"
  case JSON = "JSON"

  var description : String { return self.rawValue }
}


enum State : String, CustomStringConvertible {

  case Ready = "Ready"
  case Started = "Started"
  case ResponseAvailableFromCache = "ResponseAvailableFromCache"
  case StaleResponseAvailableFromCache = "StaleResponseAvailableFromCache"
  case Cancelled = "Cancelled"
  case Completed = "Completed"
  case Error = "Error"

  var description : String { return self.rawValue }
}

enum HTTPMethod : String, CustomStringConvertible {

  case GET = "GET"
  case POST = "POST"
  case PUT = "PUT"
  case DELETE = "DELETE"
  case PATCH = "PATCH"
  case OPTIONS = "OPTIONS"
  case TRACE = "TRACE"
  case CONNECT = "CONNECT"

  var description : String { return self.rawValue }
}

class Request {

  var url: String
  var method: HTTPMethod = .GET
  var parameters: [String:AnyObject]?
  var headers: [String:String]?
  var parameterEncoding : ParameterEncoding

  var files: [String:String]?
  var blobs: [String:NSData]?
  var bodyData: NSData?

  var task : NSURLSessionTask?

  var username : NSString?
  var password : NSString?

  var downloadPath : NSString?
  var requiresAuthentication : Bool = false
  var isSSL : Bool = false

  var doNotCache : Bool = false
  var alwaysCache : Bool = false
  var ignoreCache : Bool = false
  var alwaysLoad : Bool = false


  var state : State {

    didSet {

      switch (state) {

      case .Ready:
        break

      case .Started:
        task?.resume()

      case .Completed:
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

    for (headerValue, headerField) in headers! {

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

  var completionHandlers = Array<(Request) -> Void>()

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
  
  var description : String {
    
    return url
  }

  var responseAsJSON : AnyObject? {

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