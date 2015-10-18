//
//  Host.swift
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

public class Host {

  var defaultSession : NSURLSession
  private var ephermeralSession : NSURLSession
  private var backgroundSession : NSURLSession
  private var defaultHeaders : [String:String]
  private var path : String?

  public var cache : Cache?
  public var secure : Bool = false
  public var name : String?

  public init(name: String? = nil,
    path: String? = nil,
    defaultHeaders: [String:String] = [:],
    session: NSURLSession? = nil) {
      if let s = session {
        defaultSession = s
      } else {
        defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
      }

      ephermeralSession = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
      backgroundSession = NSURLSession(configuration: NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("hello"))

      self.name = name
      self.defaultHeaders = defaultHeaders
      self.path = path
  }

  public func requestWithURLString(urlString: String) -> Request {
    let request = Request(url: urlString)
    request.host = self
    return request
  }

  public func requestWithPath(path: String,
    method: HTTPMethod = .GET,
    parameters: [String:AnyObject]? = [:],
    headers: [String:String]? = [:],
    files: [String:String]? = [:],
    blobs: [String:NSData]? = [:],
    bodyData: NSData? = nil) -> Request? {

      let httpProtocol = secure ? "https://"  : "http://"
      guard let hostName = name else {
        print("Host name is nil. To create a request with absolute URL use createRequestWithURLString")
        return nil
      }

      var finalUrl : String = httpProtocol + hostName
      if let actualPath = self.path {
        finalUrl += "/"
        finalUrl += actualPath
      }

      let request = Request(
        method: method,
        url: finalUrl,
        parameters: parameters,
        headers: headers,
        files: files,
        blobs: blobs,
        bodyData: bodyData)
      request.host = self
      return request
  }

  public func startRequest(request : Request) {
    guard let urlRequest = request.request else {
      print("Request is nil, check your URL and other parameters you use to build your request")
      return
    }

    request.task = defaultSession.dataTaskWithRequest(urlRequest) {
      (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
      request.responseData = data
      request.response = response as? NSHTTPURLResponse
      request.error = error

      var statusCode : Int = 0
      if request.response != nil {
        statusCode = request.response!.statusCode
      }

      switch (statusCode) {
      case 304:
        request.responseData = nil

      case 400..<600:
        var userInfo : [String:AnyObject] = [:]
        userInfo["response"] = response;
        userInfo["error"] = error;
        request.error = NSError(domain: "com.mknetworkkit.httperrordomain", code: statusCode, userInfo: userInfo);

      default:
        break
      }

      if request.error == nil {
        request.state = .Completed;
      } else {
        request.state = .Error;
      }
    }
    
    request.state = .Started
  }
}