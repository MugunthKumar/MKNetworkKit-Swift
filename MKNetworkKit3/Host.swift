//
//  Host.swift
//  MKNetworkKitDemo
//
//  Created by Mugunth Kumar on 15/6/15.
//  Copyright © 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import Foundation

class Host {

  private var defaultSession : NSURLSession
  private var ephermeralSession : NSURLSession
  private var defaultHeaders : [String:String]
  private var path : String?

  var secure : Bool = false
  var name : String?

  init(name : String, path: String? = nil, defaultHeaders : [String:String] = [:]) {

    defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    ephermeralSession = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
    self.name = name
    self.defaultHeaders = defaultHeaders
    self.path = path
  }

  func createRequestWithURLString(urlString : String) -> Request {

    return Request(url: urlString)
  }

  func createRequestWithPath(path : String,
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

      return Request(
        method: method,
        url: httpProtocol + hostName + path,
        parameters: parameters,
        headers: headers,
        files: files,
        blobs: blobs,
        bodyData: bodyData)
  }

  func startRequest(request : Request) {

    guard let urlRequest = request.request else {

      print("Request is nil, check your URL and other parameters you use to build your request")
      return
    }

    request.task = defaultSession.dataTaskWithRequest(urlRequest) {
      (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in


      request.bodyData = data
      request.response = response as? NSHTTPURLResponse
      request.error = error

      let statusCode = request.response?.statusCode as Int!

      switch (statusCode) {

      case 304:
        request.bodyData = nil

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