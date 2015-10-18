//
//  Request.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar
//  Copyright © 2015 - 2020 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//
//  MIT LICENSE (REQUIRES ATTRIBUTION)
//	ATTRIBUTION FREE LICENSING AVAILBLE (for a license fee)
//  Email mugunth.kumar@gmail.com for details
//
//  Created by Mugunth Kumar (@mugunthkumar)
//  Copyright (C) 2015-2025 by Steinlogic Consulting And Training Pte Ltd.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
  
  static private var runningRequestsSynchronizingQueue =
  dispatch_queue_create("com.mknetworkkit.tasks.queue", DISPATCH_QUEUE_SERIAL)
  static private var runningRequests = [Request]()
  static internal var runningRequestsUpdatedHandler: ((Int) -> Void)?

  public var url: String
  public var method: HTTPMethod = .GET
  public var parameters: [String:AnyObject]?
  public var headers: [String:String]?
  public var parameterEncoding : ParameterEncoding

  public var files: [String:String]?
  public var blobs: [String:NSData]?
  public var bodyData: NSData?

  public var task : NSURLSessionTask?
  public var host: Host!

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

      if (state == .Started) {
        dispatch_async(Request.runningRequestsSynchronizingQueue) {
          Request.runningRequests.append(self)
          Request.runningRequestsUpdatedHandler?(Request.runningRequests.count)
        }
      }
      if (state == .Completed || state == .Error || state == .Cancelled) {
        dispatch_async(Request.runningRequestsSynchronizingQueue) {
          Request.runningRequests = Request.runningRequests.filter {$0 !== self}
          Request.runningRequestsUpdatedHandler?(Request.runningRequests.count)
        }
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

  private var completionHandlers = Array<(Request) -> Void>()

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

  public func completion (handler: (Request) -> Void) -> Request {
    completionHandlers.append(handler)
    return self
  }
  
  public func run() -> Request {
    host.startRequest(self)
    return self
  }
}